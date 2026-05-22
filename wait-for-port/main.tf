resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "while ! nc -z ${var.target.host} ${var.target.port}; do sleep 5; done"
  }

  lifecycle {
    enabled = var.target != null && var.target.host != null
  }
}