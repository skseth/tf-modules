import sys
from unittest import mock
import pytest


@pytest.fixture
def mock_dba(monkeypatch):
    import unittest.mock
    mock_dba_instance = unittest.mock.MagicMock()
    
    # Patch the dba CLASS inside the imported package
    monkeypatch.setattr("mysqlpy.setup_cluster.dba", mock_dba_instance)
    
    # Configure methods on the instance mock
    mock_dba_instance.create_cluster.return_value = unittest.mock.MagicMock()
    mock_dba_instance.create_cluster_set.return_value = unittest.mock.MagicMock()
    
    return mock_dba_instance

@pytest.fixture
def mock_socket():
    # We patch the socket class in the module where it is USED ('app')
    with mock.patch('mysqlpy.setup_cluster.socket.socket') as mock_class:
        # 1. The 'instance' is what socket.socket() returns when called
        mock_instance = mock.MagicMock()
        mock_class.return_value = mock_instance
        
        # 2. Configure __enter__ to return the same instance (standard socket behavior)
        mock_instance.__enter__.return_value = mock_instance
        mock_instance.connect.return_value = None  # Simulate successful connection
        mock_instance.settimeout.return_value = None  # Simulate settimeout working
        
        # 3. Yield the instance so tests can set return values and check assertions
        yield mock_instance

@pytest.fixture
def mock_mysql_connector():
    # We patch the connect function directly
    with mock.patch('mysqlpy.setup_cluster.mysql.connector.connect') as mock_connect:
        # Configure a default successful connection instance
        mock_instance = mock.MagicMock()
        mock_instance.__enter__.return_value = mock_instance
        mock_instance.ping.return_value = None
        mock_connect.return_value = mock_instance

        # Yield the mock function so tests can control return values or side effects
        yield mock_connect

def mock_sys_argv_two_instance(monkeypatch):
    # Mock sys.argv: ['script_name', 'arg1', 'arg2']
    monkeypatch.setattr(sys, "argv", [])
    
