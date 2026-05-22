import pytest
import unittest.mock
import socket
from mysqlpy.setup_cluster import Cluster, ClusterUnavailableError, InternalError, MYSQLConnectStatus, NetworkStatus

def test_cluster_new():
    cluster = Cluster.new("testCluster", "user:pass@host1:3306,user:pass@host2:3306")
    assert cluster.name == "testCluster"
    assert len(cluster.instances) == 2
    assert cluster.instances[0].host == "host1"
    assert cluster.instances[1].host == "host2"

def test_cluster_new_invalid():
    with pytest.raises(ValueError):
        Cluster.new("testCluster", [])

@pytest.mark.parametrize("uris, net_fail, mysql_fail, expected_up", [
    # All success scenario
    ("u:p@h1:3306,u:p@h2:3306", [], [], True),
    # Partial network failure
    ("u:p@h1:3306,u:p@h2:3306", ["h2"], [], False),
    # Partial MySQL connection failure
    ("u:p@h1:3306,u:p@h2:3306", [], ["h1"], False),
    # Mixed failures across different hosts
    ("u:p@h1:3306,u:p@h2:3306", ["h1"], ["h2"], False),
])
def test_cluster_is_up_data_driven(mock_socket, mock_mysql_connector, uris, net_fail, mysql_fail, expected_up):
    # 1. Setup selective network failure side effect
    def socket_connect_side_effect(address):
        if address[0] in net_fail:
            raise socket.timeout("Timed out")
        return None
    mock_socket.connect.side_effect = socket_connect_side_effect

    # 2. Setup selective MySQL failure using the mock_mysql_connector fixture
    def mysql_connect_mock(**kwargs):
        host = kwargs.get('host')
        if host in mysql_fail:
            # errno 2003 corresponds to CR_CONN_HOST_ERROR -> CONNECTION_REFUSED status
            raise mysql.connector.Error(errno=2003)
        
        # Return the default mock connection object for successful cases
        return mock_mysql_connector.return_value

    mock_mysql_connector.side_effect = mysql_connect_mock

    cluster = Cluster.new("testCluster", uris)
    cluster.wait_for_instances()

    assert cluster.is_up() == expected_up
    
    for inst in cluster.instances:
        if inst.host in net_fail:
            assert inst.last_net_status == NetworkStatus.TIMEOUT
            assert inst.last_mysql_status == MYSQLConnectStatus.UNKNOWN
        elif inst.host in mysql_fail:
            assert inst.last_net_status == NetworkStatus.SUCCESS
            assert inst.last_mysql_status == MYSQLConnectStatus.CONNECTION_REFUSED
        else:
            assert inst.is_up()

@pytest.mark.parametrize("uris, is_replica, all_up, expected_err, expected_add_calls", [
    # Happy path: Primary cluster, 2 nodes, all up
    ("u:p@h1:3306,u:p@h2:3306", False, True, None, 1),
    # Happy path: Single node cluster
    ("u:p@h1:3306", False, True, None, 0),
    # Error: Not all instances are up
    ("u:p@h1:3306", False, False, ClusterUnavailableError, 0),
    # Error: Attempting to call create_cluster on a replica-designated object
    ("u:p@h1:3306", True, True, InternalError, 0),
])
def test_cluster_create_cluster_data_driven(mock_dba, uris, is_replica, all_up, expected_err, expected_add_calls):
    cluster = Cluster.new("testCluster", uris, is_replica=is_replica)
    
    if all_up:
        for instance in cluster.instances:
            instance.set_mysql_status(MYSQLConnectStatus.SUCCESS, "")
    
    if expected_err:
        with pytest.raises(expected_err):
            cluster.create_cluster()
    else:
        cluster.create_cluster()
        
        # Verify the primary creation call
        mock_dba.create_cluster.assert_called_with("testCluster", cluster.instances[0].uri)
        
        # Verify the subsequent 'add_instance' calls on the returned shell object
        assert cluster.shell_cluster.add_instance.call_count == expected_add_calls
        if expected_add_calls > 0:
            cluster.shell_cluster.add_instance.assert_called_with(cluster.instances[1].uri, {'recoveryMethod': 'clone'})

@pytest.mark.parametrize("p_uris, r_uris, expected_p_adds, expected_r_adds", [
    # Scenario 1: Minimum cluster set (1 node each)
    ("u:p@h1:3306", "u:p@h2:3306", 0, 0),
    # Scenario 2: Large primary cluster, 1 node replica
    ("u:p@h1:3306,u:p@h2:3306,u:p@h3:3306", "u:p@h4:3306", 2, 0),
    # Scenario 3: 1 node primary cluster, large replica cluster
    ("u:p@h1:3306", "u:p@h2:3306,u:p@h3:3306,u:p@h4:3306", 0, 2),
    # Scenario 4: Asymmetric large clusters (2 nodes primary, 3 nodes replica)
    ("u:p@h1:3306,u:p@h2:3306", "u:p@h3:3306,u:p@h4:3306,u:p@h5:3306", 1, 2),
])
def test_cluster_create_cluster_set_data_driven(mock_dba, p_uris, r_uris, expected_p_adds, expected_r_adds):
    primary = Cluster.new("primary", p_uris)
    replica = Cluster.new("replica", r_uris, is_replica=True)

    # Mark all instances as successfully connected to allow the cluster creation logic to proceed
    for cluster in [primary, replica]:
        for inst in cluster.instances:
            inst.set_mysql_status(MYSQLConnectStatus.SUCCESS, "")

    # 1. Create the primary InnoDB Cluster
    primary.create_cluster()

    # Verify primary creation and subsequent instance additions
    mock_dba.create_cluster.assert_called_with("primary", primary.instances[0].uri)
    assert primary.shell_cluster.add_instance.call_count == expected_p_adds

    # 2. Setup mock for ClusterSet return and the resulting replica shell cluster
    mock_clusterset = primary.shell_cluster.create_cluster_set.return_value
    mock_replica_shell_cluster = unittest.mock.MagicMock()
    mock_clusterset.create_replica_cluster.return_value = mock_replica_shell_cluster

    # 3. Create the ClusterSet and join the replica cluster
    primary.create_cluster_set(replica)

    # Verify ClusterSet was initialized correctly on the primary shell cluster
    primary.shell_cluster.create_cluster_set.assert_called_with("primary")

    # Verify replica cluster creation on the ClusterSet object
    mock_clusterset.create_replica_cluster.assert_called_with(replica.instances[0].uri, "replica")

    # Verify replica instances were added to the correct replica shell cluster object
    assert replica.shell_cluster == mock_replica_shell_cluster
    assert mock_replica_shell_cluster.add_instance.call_count == expected_r_adds
    if expected_r_adds > 0:
        mock_replica_shell_cluster.add_instance.assert_called_with(
            replica.instances[-1].uri, {'recoveryMethod': 'clone'}
        )

def test_cluster_create_replica_as_primary_error():
    cluster = Cluster.new("test", "u:p@h:3306", is_replica=False)
    with pytest.raises(InternalError):
        cluster.create_cluster_as_replica(None)

def test_cluster_add_instances_partial(mock_dba):
    cluster = Cluster.new("testCluster", "u:p@h1:3306,u:p@h2:3306")
    cluster.instances_added.append(cluster.instances[0].uri)
    
    mock_cluster_obj = unittest.mock.MagicMock()
    cluster.add_instances(mock_cluster_obj)
    
    mock_cluster_obj.add_instance.assert_called_once_with(cluster.instances[1].uri, {'recoveryMethod': 'clone'})
