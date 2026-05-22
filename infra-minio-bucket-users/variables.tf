variable "bucket_users" {
  type = map(string)
}

variable "wait_for_port" {
  type = object({
    host = string
    port = string
  })

  default = null
}