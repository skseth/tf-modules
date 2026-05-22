
resource "vault_kv_secret_v2" "secrets" {
  for_each = var.secrets

  mount     = var.mount_name
  name      = each.key
  data_json = each.value
}
