locals {
  primary_instances = { for i, port in var.lb_ports: "${var.namespace}-${i}" => {
      index = i
      port = port
      fqdn = "mysql-${i}.${var.service_name}.${var.namespace}"
      uri = "root:${var.root_password}@mysql-${i}.${var.service_name}.${var.namespace}"
      safe_uri = "root@mysql-${i}.${var.service_name}.${var.namespace}"
      namespace = var.namespace
      pvc = "data-mysql-${i}"
    }
  }

  replica_instances = { for i, port in var.replica_lb_ports: "${var.replica_namespace}-${i}" => {
      index = i
      port = port
      fqdn = "mysql-${i}.${var.service_name}.${var.replica_namespace}"
      uri = "root:${var.root_password}@mysql-${i}.${var.replica_service_name}.${var.replica_namespace}"
      safe_uri = "root@mysql-${i}.${var.replica_service_name}.${var.replica_namespace}"
      namespace = var.replica_namespace
      pvc = "data-mysql-${i}"
    }
  }

  instances = merge(local.primary_instances, local.replica_instances)

  namespaces = {
    "${var.namespace}" = {
      name = var.namespace
      replicas = length(var.lb_ports)
      dns_suffix = "${var.service_name}.${var.namespace}"
      service_name = var.service_name
      cluster_name = var.cluster_name
      uris = [for instance in local.primary_instances: instance.uri]
      safe_uris = [for instance in local.primary_instances: instance.safe_uri]
      pvcs = toset([for instance in local.primary_instances: instance.pvc])
      server_id_offset = 1
    },
    "${var.replica_namespace}" = {
      name = var.replica_namespace
      replicas = length(var.replica_lb_ports)
      dns_suffix = "${var.replica_service_name}.${var.replica_namespace}"
      service_name = var.replica_service_name
      cluster_name = var.replica_cluster_name
      uris = [for instance in local.replica_instances: instance.uri]
      safe_uris = [for instance in local.primary_instances: instance.safe_uri]
      pvcs = toset([for instance in local.replica_instances: instance.pvc])
      server_id_offset = length(local.primary_instances) + 1
    }
  }
}

module "namespaces-exists" {
  source = "../namespace-exists"
  namespaces = [var.namespace, var.replica_namespace]
}

resource "kubernetes_secret_v1" "main" {
  for_each = local.namespaces
  metadata {
    name = "${each.value.service_name}-secret"
    namespace = each.key
  }

  data = {
    user = "root"
    host = "%"
    password = var.root_password
  }

  type = "Opaque"

  depends_on = [ module.namespaces-exists ]
}


resource "kubernetes_config_map_v1" "mysql_config" {
  for_each = local.namespaces
  metadata {
    name      = "mysql-config"
    namespace = each.key
  }
  data = {
    "01-global-config.cnf" = file("${path.module}/config/01-global-config.cnf")
    "setup_cluster.py" = file("${path.module}/mysqlpy/mysqlpy/setup_cluster.py")
  }

  depends_on = [ module.namespaces-exists ]

}


resource "kubernetes_config_map_v1" "mysql_init_scripts" {
  for_each = local.namespaces
  metadata {
    name      = "mysql-init-scripts"
    namespace = each.key
  }
  data = {
    "generate-pod-config.sh" = file("${path.module}/config/generate-pod-config.sh")
  }

  depends_on = [ module.namespaces-exists ]

}


