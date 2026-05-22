variable "name" {
  type = string
}

variable "mndc_db" {
    type = object({
        host           = string
        port       = number
        username           = string
        password = string
        default_source_host = string
        default_source_port = number
        replica_user = string
        replica_password = string
        repl_host = string
    })
}

variable "hdc_db" {
    type = object({
        host           = string
        port       = number
        username           = string
        password = string
        default_source_host = string
        default_source_port = number
        replica_user = string
        replica_password = string
        repl_host = string
    })
}

variable "target_primary_location" {
  type = string
}

variable "current_location" {
  type = string
}

variable "locations_disconnected" {
  type = bool
  default = false
}

variable "do_switch" {
  type = bool
  default = false
}
