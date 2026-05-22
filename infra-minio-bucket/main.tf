
resource "minio_s3_bucket" "main" {
  bucket         = var.bucket_name
  acl            = "private" # Options: private, public-read, public-read-write, public
  object_locking = false     # Set to true for WORM support
}

output "domain_name" {
  value     = minio_s3_bucket.main.bucket_domain_name
}

output "bucket" {
  value     = minio_s3_bucket.main.bucket
}

output "url" {
  value     = replace(minio_s3_bucket.main.bucket_domain_name, "//[^/]*$/", "")
}

output "arn" {
  value     = minio_s3_bucket.main.arn
}


