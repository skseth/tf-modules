

resource "kubernetes_namespace_v1" "main" {
  for_each = var.namespaces
  metadata {
    name = each.key
  }
}

