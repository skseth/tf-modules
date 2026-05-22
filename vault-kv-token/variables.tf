variable "name" {
  type = string
}

variable "mount_name" {
  type = string
}

variable "read_only" {
    type = bool
    default = false
}

variable "ttl" {
    type = string
    default = "24h"
}