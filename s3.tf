resource "aws_s3_bucket" "wordpress" {
  bucket        = local.name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "wordpress" {
  bucket = aws_s3_bucket.wordpress.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_object" "efs_add_storage_sh" {
  bucket = aws_s3_bucket.wordpress.bucket
  key    = "scripts/efs-add-storage.sh"
  source = "${path.module}/external/efs-add-storage.sh"
}
