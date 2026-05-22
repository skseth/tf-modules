

module "namespace-exists" {
  source = "../namespace-exists"
  namespaces = [var.namespace]
}

data "kustomization_overlay" "mail" {
  # Path to your existing kustomization base
  resources = ["${path.module}/kustomize/overlays/${var.env}"]
}

# Apply the generated manifests using the 'kustomization_resource'
resource "kustomization_resource" "mail" {
  # Use for_each to manage each individual resource
  for_each = data.kustomization_overlay.mail.ids
  manifest = data.kustomization_overlay.mail.manifests[each.value]

  depends_on = [ module.namespace-exists ]
}
