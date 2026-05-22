variable "namespace" {
  type = string
}

variable "env" {
    type = string  
}

variable "root_password" {
    type = string  
}

variable "app_password" {
    type = string  
}

variable "wait_for_port" {
  type = object({
    host = string
    port = string
  })

  default = null
}