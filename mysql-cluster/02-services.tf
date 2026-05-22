


# LoadBalancer to expose the first instance to your Host
resource "kubernetes_service_v1" "mysql_internal" {
  for_each = local.namespaces

  metadata {
    name      = each.value.service_name
    namespace = each.key
  }

# Consistency: Most production-ready manifests (like those from the MySQL Operator) define all three key ports: 
# 3306 (MySQL), 33060 (X-Protocol), and 33061 (Group Replication)

  spec {
    selector = { "app" = "mysql" }
    port {
      name = "classic"
      port        = 3306
      target_port = 3306
    }
    port {
      name = "x-protocol"
      port        = 33060
      target_port = 33060
    }
    port {
      name = "group-replication"
      port        = 33061
      target_port = 33061
    }
    cluster_ip = "None"
  }
}


# Target: External routes to each mysql instance
resource "kubernetes_service_v1" "mysql_external" {
  for_each = local.instances
  metadata {
    name      = "mysql-${each.value.index}-lb"
    namespace = each.value.namespace
  }
  spec {
    type     = "LoadBalancer"
    selector = { "statefulset.kubernetes.io/pod-name" = "mysql-${each.value.index}" }
    port {
      port        = each.value.port
      target_port = 3306
    }
  }
}


# TODO
# Front-end Service ({cluster-name}):
# Type: ClusterIP (Default) or LoadBalancer.
# Ports:
# 3306 & 6446: Read-Write traffic (Primary).
# 33060 & 6448: X-Protocol Read-Write.
# 6447: Read-Only traffic (to Secondaries).
# 6449: X-Protocol Read-Only.


# Target: Routes to the MySQL Router pods, which then perform the actual health-aware routing to the correct MySQL instance.
# LoadBalancer to expose the first instance to your Host
resource "kubernetes_service_v1" "mysql_router" {
  for_each = local.namespaces
  metadata {
    name      = "mysql-router-service"
    namespace = each.key
  }
  spec {
    type     = "LoadBalancer"
    selector = { 
      "app" = "mysql-router" 
    }
    port {
      name = "mysql-rw"
      protocol = "TCP"
      port        = 6446
      target_port = 6446
    }
    port {
      name = "mysql-ro"
      protocol = "TCP"
      port        = 6446
      target_port = 6446
    }
  }
}
