variable "namespace" {
  type = string
  default = "infra"
}

variable "cluster_name" {
  type = string
  default= "mysql-hdc"
}

variable "service_name" {
  type = string
  default = "mysql-hdc"
}


variable "lb_ports" {
    type = list(number)
    default = [3310, 3320]
}

variable "root_password" {
    type = string
    default = "rootpassword"
}

variable "replica_namespace" {
  type = string
  default = "infra-repl"
}

variable "replica_service_name" {
  type = string
  default = "mysql-mndc"
}

variable "replica_cluster_name" {
  type = string
  default= "mysql-mndc"
}

variable "replica_lb_ports" {
    type = list(number)
    default = [4410, 4420]
}
