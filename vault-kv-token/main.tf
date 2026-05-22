locals {
  read_policy = <<EOT
path "${var.mount_name}/data/*" {
  capabilities = ["read"]
}
EOT

  write_policy = <<EOT
path "${var.mount_name}/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}


# (Optional) Metadata access for KV v2 (required for UI browsing)
path "${var.mount_name}/metadata/*" {
  capabilities = ["list", "read"]
}

# (Optional) List available mounts in the admin console
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# Basic permissions for the token to renew itself
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Permission to check the token's own capabilities (required for UI login)
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/create" {  
  capabilities = ["create", "update", "sudo"]  
}
EOT

}

resource "vault_policy" "main" {
  name      = "${var.name}-policy"
  policy    = var.read_only ? local.read_policy : local.write_policy
}

resource "vault_token" "main" {

  policies = ["default", vault_policy.main.name]
  
  # Optional configurations
  ttl       = var.ttl
  renewable = true
}

output "client_token" {
  value     = vault_token.main.client_token
  sensitive = true
}

