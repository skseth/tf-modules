


resource "kubernetes_deployment_v1" "mysql_router" {
  for_each = local.namespaces
  metadata {
    name      = "mysql-router"
    namespace = each.key # Or a dedicated management namespace
  }

  spec {
    replicas = 1
    selector { match_labels = { app = "mysql-router" } }

    template {
      metadata { labels = { app = "mysql-router" } }
      spec {
        # Init Container to bootstrap configuration
        init_container {
          name    = "bootstrap"
          image   = "mysql/mysql-router:8.0"
          command = ["bash", "-c"]
          args = [
            <<-EOT
                    mysqlrouter --bootstrap ${each.value.safe_uris[0]} \
                    --user=mysqlrouter \
                    --force
                    EOT
          ]
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.main[each.key].metadata[0].name
                key  = "password"
              }
            }
          }
        }

        container {
          name  = "router"
          image = "mysql/mysql-router:8.0"
          port {
            container_port = 6446
          } # Read/Write port
          port {
            container_port = 6447
          } # Read-Only port
        }
      }
    }
  }
}
