
resource "terraform_data" "clusterset" {

    lifecycle {
      replace_triggered_by = [ kubernetes_stateful_set_v1.mysql ]
    }

    provisioner "local-exec" {
      command = "bash ${path.module}/scripts/initialize-clusterset.sh ${var.namespace} mysql-0 root:${var.root_password}"
    }

    depends_on = [ kubernetes_stateful_set_v1.mysql ]
}

