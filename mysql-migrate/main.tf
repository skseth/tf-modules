
locals {
  json_val = jsondecode(file("${path.module}/dev.auto.json"))
  uri      = local.json_val.uri
  schemas  = local.json_val.schemas

  # schema = local.schemas["master-32"]
}


resource "atlas_schema" "main" {
  for_each = local.schemas

  url = "mysql://${local.uri}/${each.value.name}"
  hcl = file(each.value.hcl)
}
