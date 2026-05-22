

module "namespace-exists" {
  source = "../namespace-exists"
  namespaces = [var.namespace]
}

data "kustomization_overlay" "main" {
  # Path to your existing kustomization base
  resources = ["${path.module}/kustomize/overlays/${var.env}"]

  secret_generator {
    name = "mysql-secret"
    # 'behavior' can be 'create', 'replace', or 'merge' 
    # Use 'replace' to override a secret defined in your base files
    behavior = "replace"
    
    literals = [
      "MYSQL_ROOT_PASSWORD=${var.root_password}",
      "MYSQL_PASSWORD=${var.app_password}}"
    ]
  }  
}

# Apply the generated manifests using the 'kustomization_resource'
resource "kustomization_resource" "main" {
  # Use for_each to manage each individual resource
  for_each = data.kustomization_overlay.main.ids
  manifest = data.kustomization_overlay.main.manifests[each.value]

  depends_on = [ module.namespace-exists ]
}


module "mysql_up" {
  source = "../wait-for-port"

  target = var.wait_for_port
}
