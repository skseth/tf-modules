

module "namespace-exists" {
  source = "../namespace-exists"
  namespaces = [var.namespace]
}


data "kustomization_overlay" "minio" {

  # Path to your existing kustomization base
  resources = ["${path.module}/kustomize/overlays/${var.env}"]

  secret_generator {
    name = "minio-secrets"
    # 'behavior' can be 'create', 'replace', or 'merge' 
    # Use 'replace' to override a secret defined in your base files
    behavior = "replace"

    literals = [
      "MINIO_ROOT_PASSWORD=${var.minio_root_password}"
    ]
  }
}


# Apply the generated manifests using the 'kustomization_resource'
resource "kustomization_resource" "minio" {
  # Use for_each to manage each individual resource
  for_each = data.kustomization_overlay.minio.ids
  manifest = data.kustomization_overlay.minio.manifests[each.value]

  depends_on = [module.namespace-exists]
}


module "minio_up" {
  source = "../wait-for-port"

  target = var.wait_for_port
}
