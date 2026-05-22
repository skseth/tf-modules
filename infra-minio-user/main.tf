
data "minio_s3_bucket" "main" {
  bucket         = var.bucket_name
}

locals {
  bucket_arn = "arn:aws:s3:::${data.minio_s3_bucket.main.bucket}"
}

# User resource
resource "minio_iam_user" "main" {
  name          = var.user_name
  force_destroy = true
}

data "minio_iam_policy_document" "main" {
  statement {
    sid = "AllowBucketListing"
    effect = "Allow"
    actions   = [ "s3:GetBucketLocation", "s3:ListBucket"]
    resources = [local.bucket_arn]
  }
  statement {
    sid = "AllowObjectActions"
    effect = "Allow"
    actions   = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ]
    resources = ["${local.bucket_arn}/*"]
  }
  statement {
    sid = "AllowTopLevelList"
    effect = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "minio_iam_policy" "main" {
  name   = "${var.user_name}_policy"
  policy = data.minio_iam_policy_document.main.json
}

resource "minio_iam_user_policy_attachment" "main" {
  user_name   = minio_iam_user.main.id
  policy_name = minio_iam_policy.main.id    
}

resource "minio_iam_service_account" "main" {
  target_user = minio_iam_user.main.name
    depends_on = [ minio_iam_user.main ]
}


output "user" {
  value     = minio_iam_user.main.name
}

output "sa_access_key" {
  value     = minio_iam_service_account.main.access_key
}

output "sa_secret_key" {
  value     = minio_iam_service_account.main.secret_key
  sensitive = true
}



