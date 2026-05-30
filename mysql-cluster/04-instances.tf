

# StatefulSet with 2 Instances
resource "kubernetes_stateful_set_v1" "mysql" {
  for_each = local.namespaces

  metadata {
    name      = "mysql"
    namespace = each.key
  }
  spec {
    service_name = each.value.service_name
    replicas     = length(var.lb_ports)
    selector { match_labels = { app = "mysql" } }
    template {
      metadata { labels = { app = "mysql" } }
      spec {
        # This directory will eventually hold the mysql config files, both global and pod-specific
        # Empty Dir means it is created at the pod level and shared between the init container and the main mysql container. 
        # It is not persisted across pod restarts, but it does survive container crashes, which is what we want for this use case.
        volume {
            name = "mysql-config-empty-volume"
            empty_dir {}
        }

        # source files for configuring mysql from ConfigMaps, and mysqlsh python scripts
        volume {
          name = "mysql-config-volume"
          config_map {
            name = kubernetes_config_map_v1.mysql_config[each.key].metadata[0].name
          }
        }    

        # source files specifically for the init container
        volume {
          name = "init-scripts-volume"
          config_map {
            name = kubernetes_config_map_v1.mysql_init_scripts[each.key].metadata[0].name
            # NOTE: make .sh files executable
            default_mode = "0755"
          }
        }

        # Init container to generate config using the pod's hostname
        init_container {
          name  = "mysql-pod-config"
          image = "busybox:1.36"
          
          command = [
            "/bin/sh",
            "/scripts/generate-pod-config.sh",
            each.value.dns_suffix,
            each.value.server_id_offset,
            "/etc/mysql/conf.d"
          ]
          
          # pod-specific conf is mounted in an emptyDir volume that the init container writes to and the main container reads from
          # This survives container crashes, but not pod restarts, which is fine for us.
          # The init container will create the config files here
          volume_mount {
            name       = "mysql-config-empty-volume"
            mount_path = "/etc/mysql/conf.d"
          }
        
          volume_mount {
            name       = "mysql-config-volume"
            mount_path = "/config"
          }          

          volume_mount {
            name       = "init-scripts-volume"
            mount_path = "/scripts"
          }          
          
        }

        container {
          name  = "mysql"
          image = "samirkseth/mysql-cluster:1.0.0"

          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_name
          }

          env {
            name  = "CLUSTER_URIS"
            value = join(",", local.namespaces[var.namespace].uris)
          }

          env {
            name  = "REPLICA_CLUSTER_NAME"
            value = var.replica_cluster_name
          }

          env {
            name  = "REPLICA_CLUSTER_URIS"
            value = join(",", local.namespaces[var.replica_namespace].uris)
          }

          env {
            name  = "NAMESPACE"
            value = each.key
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.main[each.key].metadata[0].name
                key  = "password"
              }
            }
          }


          

          port { container_port = 3306 }

          # Empty, but filled by init container
          volume_mount {
            name       = "mysql-config-empty-volume"
            mount_path = "/etc/mysql/conf.d"
          }

          # Empty, but filled by init container
          # NOTE The path works because of 
          volume_mount {
            name       = "mysql-config-volume"
            mount_path = "/mysqlsh/init.d/setup_cluster.py"
            sub_path = "setup_cluster.py"
          }

          # data directory
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }

          resources {
            requests = {
              cpu = "200m"
              memory = "512Mi"
            }

            limits = {
              cpu = "500m"
              memory = "1Gi"
            }

          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }

  depends_on = [ terraform_data.pvc_seeding ]

}

