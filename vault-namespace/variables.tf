

variable "name" {
  type = string
  nullable = false

  validation {
    condition = length(var.name) > 0
    error_message = "a non-empty name must be provided"
  }
}
