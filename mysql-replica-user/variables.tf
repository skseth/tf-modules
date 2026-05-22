variable "user_name" {
  type = string
}

variable "user_host" {
  type = string
}

variable "user_auth_plugin" {
  type = string
  default = "caching_sha2_password"
  nullable = false
}

variable "user_password" {
  type = string
}