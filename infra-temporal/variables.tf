



variable "wait_for_port" {
  type = object({
    host = string
    port = string
  })

  default = null
}