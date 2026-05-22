locals {
  json_val = jsondecode(file("${path.module}/dev.auto.json"))
  uri      = local.json_val.uri
  schemas  = local.json_val.schemas
}

resource "mysql_database" "main" {
  for_each = local.schemas
  name     = each.value.name
}