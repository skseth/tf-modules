

module "namespace-exists" {
  source = "../namespace-exists"

  namespaces = [var.namespace]
}


data "kustomization_overlay" "openbao" {
  # Path to your existing kustomization base
  resources = ["${path.module}/kustomize/overlays/${var.env}"]

  secret_generator {
    name = "openbao-secrets"
    behavior = "replace"
    
    literals = [
      "BAO_DEV_ROOT_TOKEN_ID=${ var.vault_admin_token_id}",
    ]
  }
}


# Apply the generated manifests using the 'kustomization_resource'
resource "kustomization_resource" "openbao" {
  # Use for_each to manage each individual resource
  for_each = data.kustomization_overlay.openbao.ids
  manifest = data.kustomization_overlay.openbao.manifests[each.value]

  depends_on = [ module.namespace-exists ]
}

module "openbao_up" {
  source = "../wait-for-port"

  target = var.wait_for_port
}
