
resource "mysql_user" "main" {
  user               = var.user_name
  host               = var.user_host
  auth_plugin        = var.user_auth_plugin
  plaintext_password = var.user_password
}

# Grant global replication privileges
resource "mysql_grant" "main" {
  user       = mysql_user.main.user
  host       = mysql_user.main.host
  database   = "*"  # Required for global (administrative) privileges
  privileges = ["REPLICATION SLAVE", "REPLICATION CLIENT"]
}

