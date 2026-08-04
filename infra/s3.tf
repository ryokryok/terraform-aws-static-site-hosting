# バケット名は全AWSアカウントで共有のグローバル名前空間。
# アカウントIDを混ぜることで他人との衝突を原理的に回避する。
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "frontend" {
  bucket = "aws-static-site-${data.aws_caller_identity.current.account_id}"
}

# パブリックアクセスは全面ブロック（CloudFront からのみ読ませる）
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}