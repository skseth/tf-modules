resource "kubernetes_persistent_volume_claim_v1" "main" {
    for_each = local.instances
    metadata {
        name      = each.value.pvc
        namespace = each.value.namespace
    }
    spec {
        access_modes = ["ReadWriteOnce"]
        resources {
            requests = {
                storage = "5Gi"
            }
        }
    }

    wait_until_bound = false

}

resource "terraform_data" "pvc_seeding" {
    for_each = local.namespaces

    lifecycle {
      replace_triggered_by = [ kubernetes_persistent_volume_claim_v1.main ]
    }

    provisioner "local-exec" {
      command = "bash ${path.module}/scripts/initialize-data-pvcs.sh ${each.key} ${join(",", each.value.pvcs)} scripts/mysql-seed.tar.gz"
    }

    depends_on = [ kubernetes_persistent_volume_claim_v1.main ]
}
