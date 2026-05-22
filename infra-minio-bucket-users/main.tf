
module "minio_up" {
  source = "../wait-for-port"

  target = var.wait_for_port
}

module "buckets" {
    for_each = var.bucket_users
    source = "../infra-minio-bucket"
    bucket_name = each.key

    depends_on = [ module.minio_up ]
}

module "users" {
    for_each = var.bucket_users
    source = "../infra-minio-user"
    user_name = each.value
    bucket_name = each.key

    depends_on = [ module.buckets ]
}

output "buckets" {
 value = {
    for k in setunion(keys(module.buckets), keys(module.users)) :
    k => merge(
      lookup(module.buckets, k, {}), 
      lookup(module.users, k, {})
    )
  }

  sensitive = true
}
