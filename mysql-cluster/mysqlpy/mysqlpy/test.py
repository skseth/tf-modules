print(globals())

import sys
import os
import socket
from typing import Tuple, List
from enum import StrEnum, auto
from contextlib import contextmanager
from datetime import datetime, time, timedelta

print(f"LOADING setup_cluster.py")

# if "mysqlx" not in globals():
#     import mysqlx
#     from mysqlx import errorcode as xerrorcode
#     import mysql
#     from mysql import errorcode as errorcode

# if "shell" not in globals():
#     from .mock_mysqlsh import Dba, Shell
#     dba = Dba()
#     shell = Shell()


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


class MyContextManager:
    
    def __init__(self):
        pass
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        pass
    
    # def enter(self, exc_type, exc_val, exc_tb):
    #     print(f"--- Starting {self.action} ---")
    #     return self
    
    # def exit(self, exc_type, exc_val, exc_tb):
    #     if exc_type:
    #         print(f"--- Failed {self.action}: {exc_val} ---")  # After message error
    #     else:
    #         print(f"--- Completed {self.action} ---")  # After message success
    #     return False


def log_action(action: str):
    return LogAction(action)
