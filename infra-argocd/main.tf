

module "namespace-exists" {
  source = "../namespace-exists"
  namespaces = ["argocd"]
}


resource "terraform_data" "hashed_password" {

  input = bcrypt(var.admin_password)

  lifecycle {
    # Ignore changes to 'input' so that the random salt 
    # doesn't trigger an update on every single 'apply'.
    ignore_changes = [input]
  }

  # This triggers a replacement (and a fresh bcrypt call) 
  # only when the cleartext password changes.
  triggers_replace = [
    var.admin_password
  ]  
}

# Set the admin password via a Kubernetes secret
resource "kubernetes_secret_v1" "argocd_admin" {
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"

    labels = {
      "app.kubernetes.io/name"    = "argocd-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    "admin.password"      = terraform_data.hashed_password.output,
    "admin.passwordMtime" = timestamp()
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [
      data
    ]
  }
}

resource "kubernetes_secret_v1" "repo" {
  metadata {
    name      = var.repo_name
    namespace = "argocd"

    labels = {
      "argocd.argoproj.io/secret-type"    = "repository"
    }
  }

  type = "Opaque"

  data = {
    type = "git"
    url = var.repo_url
    username = var.repo_username
    password = var.repo_password
  }

  lifecycle {
    enabled = length(var.repo_password) > 0
  }

  depends_on = [module.namespace-exists]

}

data "kustomization_build" "main" {
  path = "${path.module}/kustomize/overlays/${var.env}"
}

# Apply the generated manifests using the 'kustomization_resource'
resource "kustomization_resource" "main" {
  # Use for_each to manage each individual resource
  for_each = data.kustomization_build.main.ids
  manifest = data.kustomization_build.main.manifests[each.value]

  depends_on = [ module.namespace-exists, kubernetes_secret_v1.argocd_admin ]
}

