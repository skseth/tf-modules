from mysqlpy.setup_cluster import MYSQLConnectStatus, check_mysql_connect, check_network_connect, NetworkStatus, extract_host_port_creds

host = "192.168.205.4"
port = 3310

def test_connection():
    try:
        status, err = check_network_connect(host, port, 5)
        if status == NetworkStatus.SUCCESS:
            print("SUCCESS: Connection test passed: Network is reachable.")
        else:
            print(f"ERROR: Connection test failed: {status.name} - {err}")
    except Exception as err:
        print(f"ERROR: Connection test failed: {err}")

def test_invalid_connection():
    try:
        status, err = check_network_connect("1.2.3.4", port, 5)
        if status == NetworkStatus.SUCCESS:
            print("ERROR: Invalid connection test passed unexpectedly.")
        else:
            print(f"SUCCESS: Invalid Connection test failed: {status.name} - {err}")
    except Exception as err:
        print(f"ERROR: Connection test failed: {err}")


def test_invalid_address():
    try:
        status, err = check_network_connect("some-random-address.local", port, 5)
        if status == NetworkStatus.SUCCESS:
            print("ERROR: Invalid connection test passed unexpectedly.")
        else:
            print(f"SUCCESS: Invalid Connection test failed: {status.name} - {err}")
    except Exception as err:
        print(f"ERROR: EXCEPTION: Connection test failed: {err}")


def test_mysql_connection():
    try:
        status, err = check_mysql_connect(f"root:rootpassword@{host}:{port}")
        if status == MYSQLConnectStatus.SUCCESS:
            print("SUCCESS: Connection test passed: Network is reachable.")
        else:
            print(f"ERROR: Connection test failed: {status.name} - {err}")
    except Exception as err:
        print(f"ERROR: EXCEPTION: Connection test failed: {err}")


# test_connection()
# test_invalid_connection()
# test_invalid_address()
test_mysql_connection()
