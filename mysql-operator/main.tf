
resource "helm_release" "mysql_operator" {
  name             = "mysql-operator"
  repository       = "https://mysql.github.io/mysql-operator/"
  chart            = "mysql-operator"
  namespace        = var.namespace
  create_namespace = var.create_namespace

  set = [{
    name  = "operator.resources.requests.cpu"
    value = "100m"
  }, {
    name  = "operator.resources.requests.memory"
    value = "128Mi"
  }]
}
