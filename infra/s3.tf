data "aws_caller_identity" "current" {}

# バケット名はグローバル名前空間。アカウントIDを混ぜて衝突を避ける
resource "aws_s3_bucket" "frontend" {
  bucket = "aws-static-site-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
