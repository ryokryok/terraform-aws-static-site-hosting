# CloudFront のアクセスログ（標準ログ v2）。
#
# CloudFront はグローバルサービスのため、配信元は us-east-1 に置く必要がある。
# main.tf で用意していた us_east_1 エイリアスをここで使う。
#
# 旧来の logging_config（S3 直書き）は対象バケットで ACL を有効にする必要があり、
# 現在の S3 の既定（ACL 無効）と噛み合わない。v2 の CloudWatch Logs 配信を使う

resource "aws_cloudwatch_log_group" "cloudfront" {
  provider = aws.us_east_1

  name              = "/aws/cloudfront/frontend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_delivery_source" "cloudfront" {
  provider = aws.us_east_1

  name         = "frontend-access-logs"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.frontend.arn
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront" {
  provider = aws.us_east_1

  name          = "frontend-access-logs"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.cloudfront.arn
  }
}

resource "aws_cloudwatch_log_delivery" "cloudfront" {
  provider = aws.us_east_1

  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront.arn
}
