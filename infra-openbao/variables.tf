
variable "namespace" {
  type = string
}

variable "vault_admin_token_id" {
  type = string
  sensitive = true
}


variable "env" {
  type = string
}


variable "wait_for_port" {
  type = object({
    host = string
    port = string
  })

  default = null
}