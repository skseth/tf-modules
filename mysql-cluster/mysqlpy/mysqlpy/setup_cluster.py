# THIS FILE IS SUPPOSED TO RUN IN MYSQLSH
# SOME RESTRICTIONS APPLY
# mysqlsh makes the following globals available
#   dba
#   shell
#   utils
# Also if we import this file using \source in mysqlsh
#   indentation needs to be maintained even for blank lines
#   annotations seem not to work

import sys
import os
import socket
from typing import Tuple, List
from enum import StrEnum, auto
from contextlib import contextmanager
import time
from datetime import datetime, timedelta


print(f"LOADING setup_cluster.py")

if "mysqlx" not in globals():
    import mysqlx
    from mysqlx import errorcode as xerrorcode
    import mysql
    from mysql import errorcode as errorcode
    from mysqlsh import DBError

if "shell" not in globals():
    from .mock_mysqlsh import Dba, Shell
    dba = Dba()
    shell = Shell()

class InstanceUnavailableError(Exception):
    pass


class ClusterUnavailableError(Exception):
    pass


class InternalError(Exception):
    pass


class ShellConnectionError(Exception):
    pass


class NetworkStatus(StrEnum):
    UNKNOWN = auto()
    TIMEOUT = auto()
    ADDRESS_RELATED_ERROR = auto()
    CONNECTION_REFUSED = auto()
    COMPLETED = auto()
    OSERROR = auto()
    UNEXPECTED_ERROR = auto()
    SUCCESS = auto()


class MYSQLConnectStatus(StrEnum):
    UNKNOWN = auto()
    CONNECTION_REFUSED = auto()
    CONNECT_ACCESS_DENIED = auto()
    CONNECT_SERVER_LOST = auto()
    CONNECT_HOST_NOT_PRIVILEGED = auto()
    CONNECT_UNEXPECTED_ERROR = auto()
    PING_SERVER_LOST = auto()
    PING_UNEXPECTED_ERROR = auto()
    SUCCESS = auto()

class LogAction:
    
    def __init__(self, action):
        self.action = action
    
    def __enter__(self):
        print(f"--- Starting {self.action} ---")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            print(f"--- Failed {self.action}: {exc_val} ---"
                  )  # After message error
        else:
            print(f"--- Completed {self.action} ---")  # After message success
        return False


def log_action(action: str):
    return LogAction(action)

class Instance:
    
    def __init__(self, uri: str):
        self.uri = uri
        print(f"\tInstance initializing - {uri}")
        creds, address = uri.split("@")
        host, *rest = address.split(":")
        user, password = creds.split(":")
        self.host = host
        self.port = int(rest[0]) if len(rest) > 0 else 33060
        self.user = user
        self.password = password
        self.last_net_status = NetworkStatus.UNKNOWN
        self.last_net_error = None
        self.last_mysql_status = MYSQLConnectStatus.UNKNOWN
        self.last_mysql_error = None
        self.group_replication_local_address = f"{host}:3306"
    
    def safe_uri(self):
        return f"{self.user}:******@{self.host}:{self.port}"
    
    def is_up(self):
        return self.last_mysql_status == MYSQLConnectStatus.SUCCESS

    def configure(self):
        dba.configure_instance(self.uri)
    
    def set_mysql_status(self, status: MYSQLConnectStatus, error: str):
        self.last_mysql_status = status
        self.last_mysql_error = error
    
    def set_network_status(self, status: NetworkStatus, error: str):
        self.last_net_status = status
        self.last_net_error = error
    
    def check_network_connect(self, timeout):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(timeout)
                s.connect((self.host, self.port))
                return self.set_network_status(NetworkStatus.SUCCESS, "")
        except socket.timeout as err:
            self.set_network_status(NetworkStatus.TIMEOUT, err)
        except ConnectionRefusedError as err:
            self.set_network_status(NetworkStatus.CONNECTION_REFUSED, err)
        except socket.gaierror as err:
            self.set_network_status(NetworkStatus.ADDRESS_RELATED_ERROR, err)
        except TimeoutError as err:
            self.set_network_status(NetworkStatus.TIMEOUT, err)
        except OSError as err:
            self.set_network_status(NetworkStatus.OSERROR, err)
        except Exception as err:
            self.set_network_status(NetworkStatus.UNEXPECTED_ERROR, err)
    
    def check_mysql_connect(self):
        if self.port == 33060:
            self.check_mysqlx_connect()
            return
        
        try:
            conn = mysql.get_session({
                    'host': self.host,
                    'port': self.port,
                    'user': self.user,
                    'password': self.password
            })

            try:
                conn.ping(reconnect=False, attempts=1)
                self.set_mysql_status(MYSQLConnectStatus.SUCCESS, "")
            except mysql.Error as err:
                if err.errno == errorcode.CR_SERVER_LOST:
                    self.set_mysql_status(
                        MYSQLConnectStatus.PING_SERVER_LOST, err)
                else:
                    print(f"Unexpected MySQL ping error: {err}")
                    self.set_mysql_status(
                        MYSQLConnectStatus.PING_UNEXPECTED_ERROR, err)
            except Exception as err:
                print(f"Unexpected error during MySQL ping: {err}")
                self.set_mysql_status(
                    MYSQLConnectStatus.PING_UNEXPECTED_ERROR, err)
        except mysql.Error as err:
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                self.set_mysql_status(MYSQLConnectStatus.CONNECT_ACCESS_DENIED,
                                      err)
            elif err.errno == errorcode.CR_CONN_HOST_ERROR:
                self.set_mysql_status(MYSQLConnectStatus.CONNECTION_REFUSED,
                                      err)
            elif err.errno == errorcode.CR_SERVER_LOST:
                self.set_mysql_status(MYSQLConnectStatus.CONNECT_SERVER_LOST,
                                      err)
            elif err.errno == errorcode.ER_HOST_NOT_PRIVILEGED:
                self.set_mysql_status(
                    MYSQLConnectStatus.CONNECT_HOST_NOT_PRIVILEGED, err)
            else:
                print(f"Unexpected MySQL connection error: {err}")
                self.set_mysql_status(
                    MYSQLConnectStatus.CONNECT_UNEXPECTED_ERROR, err)
        except Exception as err:
            print(f"Unexpected error during MySQL connection: {err}")
            self.set_mysql_status(MYSQLConnectStatus.CONNECT_UNEXPECTED_ERROR,
                                  err)
        finally:
            if conn is not None:
                conn.close()
    
    def check_mysqlx_connect(self):
        try:
            conn = mysqlx.get_session({
                    'host': self.host,
                    'port': self.port,
                    'user': self.user,
                    'password': self.password
            })

            try:
                schema_list = conn.get_schemas()
                if len(schema_list) == 0:
                    raise InstanceUnavailableError(f"No schemas found at {self.safe_uri()}")
                self.set_mysql_status(MYSQLConnectStatus.SUCCESS, "")
            except Exception as err:
                self.set_mysql_status(
                    MYSQLConnectStatus.PING_UNEXPECTED_ERROR, err)
        except Exception as err:
            self.set_mysql_status(
                MYSQLConnectStatus.CONNECT_UNEXPECTED_ERROR, err)
        finally:
            if "conn" in locals() and conn is not None:
                conn.close()

class Cluster:
    
    def __init__(self, name: str, uris: List[str], is_replica=False):
        print(f"\tCluster {name} initializing - {",".join(uris)}")

        self.name = name
        self.instances = [Instance(uri) for uri in uris]
        self.shell_cluster = None
        self.is_replica = is_replica
        self.instances_added: List[str] = []
        self.cluster_set = None
    
    @classmethod
    def new(cls,
            name: str,
            uris: str | List[str],
            is_replica=False) -> 'Cluster':
        uris = uris.split(",") if isinstance(uris, str) else uris
        if len(uris) == 0:
            raise ValueError(
                f"Error parsing instance uris for cluster {name} : At least one URI must be provided"
            )
        cluster = cls(name, uris, is_replica)
        return cluster
    
    def is_up(self):
        for instance in self.instances:
            if not instance.is_up():
                return False
        return True
    
    def configure(self):
        for instance in self.instances:
            instance.configure()

    def wait_for_instances(self):
        if not self.is_up():
            for instance in self.instances:
                if not instance.is_up():
                    instance.check_network_connect(timeout=5)
                    if instance.last_net_status == NetworkStatus.SUCCESS:
                        instance.check_mysql_connect()
    
    def create_cluster(self):
        if self.is_replica:
            raise InternalError(
                "Cannot create a replica cluster as a primary cluster")
        
        if not self.is_up():
            raise ClusterUnavailableError(
                f"Cannot create cluster {self.name} as instances may not be up..."
            )
        
        with log_action(
                f"Creating cluster {self.name} with instance {self.instances[0].uri}"
        ):
            self.shell_cluster = dba.create_cluster(self.name, {
                'localAddress': self.instances[0].group_replication_local_address, 
            })
        
        self.instances_added.append(self.instances[0].uri)
        self.add_instances(self.shell_cluster)
    
    def add_instances(self, cluster, recovery_method='incremental'):
        for instance in self.instances:
            if instance.uri not in self.instances_added:
                with log_action(
                        f"Adding instance {instance.uri} to cluster {self.name}"
                ):
                    cluster.add_instance(instance.uri, {
                                            'localAddress': instance.group_replication_local_address,
                                            'recoveryMethod': recovery_method
                                        })
                self.instances_added.append(instance.uri)
    
    def create_cluster_as_replica(self, clusterset):
        if not self.is_replica:
            raise InternalError(
                "Cannot create a primary cluster as a replica cluster")
        
        if not self.is_up():
            raise ClusterUnavailableError(
                f"Cannot create cluster {self.name} as instances may not be up..."
            )
        
        with log_action(
                f"Creating replica cluster {self.name} with instance {self.instances[0].uri}"
        ):
            self.shell_cluster = clusterset.create_replica_cluster(
                self.instances[0].uri, self.name, {
                                            'localAddress': self.instances[0].group_replication_local_address,
                                            'recoveryMethod': 'incremental'
                                        })
        self.instances_added.append(self.instances[0].uri)
        self.add_instances(self.shell_cluster)
    
    def create_cluster_set(self, replica_cluster: 'Cluster'):
        with log_action(
                f"Creating ClusterSet with primary cluster {self.name}"):
            self.cluster_set = self.shell_cluster.create_cluster_set(self.name)
        replica_cluster.create_cluster_as_replica(self.cluster_set)


def shell_connect(instance: Instance):
    try:
        print(f"\nTrying to connect to {instance.uri} as root")
        shell.connect(instance.uri)
        print(f"\nConnected to {instance.uri} as root")
    except Exception as err:
        # Convert error to string to check for specific codes
        err_msg = str(err)
        
        if "1045" in err_msg:
            print(
                "Error: Access Denied (1045). Check your username or password."
            )
        elif "2003" in err_msg or "Timed out" in err_msg:
            print(
                "Error: Instance Unreachable (possibly 2003). Check host, port, or firewall."
            )
        else:
            print(f"An unexpected connection error occurred: {err}")
        raise ShellConnectionError(
            f"Error trying to shell.connect to {instance.safe_uri()} : {err_msg}"
        )


def wait_for_cluster_instances(cluster: Cluster,
                               replica_cluster: Cluster,
                               timeout_seconds=300):
    end_time = datetime.now() + timedelta(seconds=timeout_seconds)
    
    while datetime.now() < end_time and (not cluster.is_up()
                                         or not replica_cluster.is_up()):
        cluster.wait_for_instances()
        replica_cluster.wait_for_instances()
        time.sleep(5)


def setup_cluster_set(cluster_name: str, primary_uris: str,
                      replica_cluster_name: str, replica_uris: str):
    cluster = Cluster.new(cluster_name, primary_uris)
    replica_cluster = Cluster.new(replica_cluster_name,
                                  replica_uris,
                                  is_replica=True)
    
    wait_for_cluster_instances(cluster, replica_cluster)
    
    shell_connect(cluster.instances[0])
    
    cluster.create_cluster()
    cluster.create_cluster_set(replica_cluster)


def instance_up(uri):
    instance = Instance(uri)
    instance.check_network_connect(timeout=5)
    
    instance.check_mysql_connect()
    if not instance.is_up():
        return instance.last_mysql_error
    else:
        return True

clusters = {}
cluster_name = ""
replica_cluster_name = ""

def cluster_new(name, uris):
    cluster = Cluster.new(name, uris)
    clusters[name] = cluster
    return f"Cluster {name} created"

def cluster_status(name):
    up = clusters[name].is_up()
    print(f"Cluster {name} is {'up' if up else 'down'}")

    for instance in clusters[name].instances:
        print(f"\tinstance {instance.safe_uri()} is {'up' if instance.is_up() else 'down'}")
        print(f"\t\tnet status is : {instance.last_net_status}")
        if instance.last_net_status != NetworkStatus.SUCCESS:
            print(f"\t\tnet error is : {instance.last_net_error}")
        print(f"\t\tmysql status is : {instance.last_mysql_status}")
        if instance.last_mysql_status != MYSQLConnectStatus.SUCCESS:
            print(f"\t\tmysql error is : {instance.last_mysql_error}")


def clusterset_initialize():
    global cluster_name, replica_cluster_name, clusters

    cluster_name = os.getenv("CLUSTER_NAME")
    cluster_uris = os.getenv("CLUSTER_URIS")
    replica_cluster_name = os.getenv("REPLICA_CLUSTER_NAME")
    replica_cluster_uris = os.getenv("REPLICA_CLUSTER_URIS")

    cluster = Cluster.new(cluster_name, cluster_uris)
    clusters[cluster_name] = cluster
    replica_cluster = Cluster.new(replica_cluster_name, replica_cluster_uris, is_replica=True)
    clusters[replica_cluster_name] = replica_cluster

    wait_for_cluster_instances(cluster, replica_cluster)

    cluster_status(cluster_name)
    cluster_status(replica_cluster_name)

def clusterset_configure():
    clusterset_initialize()
    cluster = clusters[cluster_name]
    cluster.configure()
    replica_cluster = clusters[replica_cluster_name]
    replica_cluster.configure()


def clusterset_create():
    clusterset_initialize()
    clusterset_configure()
    cluster = clusters[cluster_name]
    replica_cluster = clusters[replica_cluster_name]
    shell_connect(cluster.instances[0])
    cluster.create_cluster()
    cluster.create_cluster_set(replica_cluster)


ext_obj = shell.create_extension_object()
shell.add_extension_object_member(ext_obj, "instance_up", instance_up, parameters = [{"name": "uri", "type": "string"}])
shell.add_extension_object_member(ext_obj, "cluster_new", cluster_new, parameters = [{"name": "name", "type": "string"}, {"name": "uris", "type": "string"}])
shell.add_extension_object_member(ext_obj, "cluster_status", cluster_status, parameters = [{"name": "name", "type": "string"}])
shell.add_extension_object_member(ext_obj, "clusterset_initialize", clusterset_initialize)
shell.add_extension_object_member(ext_obj, "clusterset_create", clusterset_create)
shell.add_extension_object_member(ext_obj, "clusterset_configure", clusterset_configure)
shell.register_global("tools", ext_obj)


