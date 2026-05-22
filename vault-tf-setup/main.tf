

resource "vault_mount" "secrets" {
  path    = var.secret_vault_name
  type    = "kv"
  options = { version = "2" }
}

resource "vault_mount" "drswitch" {
  path    = var.drswitch_vault_name
  type    = "kv"
  options = { version = "2" }
}

module "secrets_writer_token" {
  source = "../vault-kv-token"

  name = "secret-writer"
  mount_name = vault_mount.secrets.path
}


module "secrets_reader_token" {
  source = "../vault-kv-token"

  name = "secret-reader"
  mount_name = vault_mount.secrets.path
  read_only = true
}


module "drswitch_writer_token" {
  source = "../vault-kv-token"

  name = "drswitch-writer"
  mount_name = vault_mount.secrets.path
  read_only = true
}


module "drswitch_reader_token" {
  source = "../vault-kv-token"

  name = "drswitch-reader"
  mount_name = vault_mount.secrets.path
  read_only = true
}

output "secrets_writer_token" {
  value     = module.secrets_writer_token.client_token
  sensitive = true
}

output "secrets_reader_token" {
  value     = module.secrets_reader_token.client_token
  sensitive = true
}


output "drswitch_writer_token" {
  value     = module.drswitch_writer_token.client_token
  sensitive = true
}

output "drswitch_reader_token" {
  value     = module.drswitch_reader_token.client_token
  sensitive = true
}
