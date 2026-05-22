from typing import Any, Dict, List, Optional, Union

# Global instance of the Shell
class Shell:
    def connect(self, connection: Union[str, Dict[str, Any]], password: Optional[str] = ...) -> Any:
        raise AssertionError("Unexpected call")
    def exit(self, code: int = 0) -> None:
        raise AssertionError("Unexpected call")

# def disconnect(self) -> None: ...
# def status(self) -> None: ...
# def use(self, schema_name: str) -> None: ...
# @property
# def options(self) -> Dict[str, Any]: ...

class MysqlshCluster:
    def add(self, instance: str, options: Optional[Dict[str, Any]] = ...) -> Any:
        raise AssertionError("Unexpected call")
    def add_instances(self, instances: List[str], options: Optional[Dict[str, Any]] = ...) -> Any:
        raise AssertionError("Unexpected call")
    def create_replica_cluster(self, instance: str, name: Optional[str] = ...) -> 'MysqlshCluster':
        raise AssertionError("Unexpected call")
    def create_cluster_set(self, name: Optional[str] = ...) -> 'MysqlshCluster':
        raise AssertionError("Unexpected call")
    def status(self, options: Optional[Dict[str, Any]] = ...) -> Any:
        raise AssertionError("Unexpected call")

# AdminAPI for InnoDB Cluster/ReplicaSet management
class Dba:
    def create_cluster(self, name: str, options: Optional[Dict[str, Any]] = ...) -> MysqlshCluster:
        raise AssertionError("Unexpected call")

    # def get_cluster(self, name: Optional[str] = ...) -> Any: ...
    # def configure_instance(self, instance: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...
    # def check_instance_configuration(self, instance: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...
    # def deploy_sandbox_instance(self, port: int, options: Optional[Dict[str, Any]] = ...) -> Any: ...

# Utility functions for dumping, loading, and reporting
# class Util:
#     def dump_schemas(self, schemas: List[str], path: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...
#     def dump_tables(self, schema: str, tables: List[str], path: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...
#     def load_dump(self, path: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...
#     def import_table(self, file: str, options: Optional[Dict[str, Any]] = ...) -> Any: ...

# These represent the global objects injected by mysqlsh

# util: Util
