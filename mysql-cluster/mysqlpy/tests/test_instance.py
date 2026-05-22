import pytest

import mysqlpy.setup_cluster


def test_instance_net_connection(mock_socket):
    instance = mysqlpy.setup_cluster.Instance("root:password@localhost:3306")
    instance.check_network_connect(timeout=5)
    assert instance.last_net_status == mysqlpy.setup_cluster.NetworkStatus.SUCCESS


def test_instance_net_connection_failure(mock_socket):
    mock_socket.connect.side_effect = Exception("Connection failed")
    instance = mysqlpy.setup_cluster.Instance("root:password@localhost:3306")
    instance.check_network_connect(timeout=5)
    assert instance.last_net_status == mysqlpy.setup_cluster.NetworkStatus.UNEXPECTED_ERROR
    assert isinstance(instance.last_net_error, Exception)


def test_instancedb_connection(mock_mysql_connector):
    instance = mysqlpy.setup_cluster.Instance("root:password@localhost:3306")
    instance.check_mysql_connect()
    assert instance.last_mysql_status == mysqlpy.setup_cluster.MYSQLConnectStatus.SUCCESS
    assert mock_mysql_connector.called


def test_instance_db_connection_failure(mock_mysql_connector):
    # Access the return_value (the instance) to set side effects on methods like ping()
    mock_mysql_connector.return_value.ping.side_effect = Exception("Connection failed")
    instance = mysqlpy.setup_cluster.Instance("root:password@localhost:3306")
    instance.check_mysql_connect()
    assert instance.last_mysql_status == mysqlpy.setup_cluster.MYSQLConnectStatus.PING_UNEXPECTED_ERROR
    assert isinstance(instance.last_mysql_error, Exception)
