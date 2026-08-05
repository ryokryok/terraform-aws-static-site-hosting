resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# SPA のルーティング用。拡張子を持たないパスだけを index.html に寄せる。
#
# 以前は 403 を index.html に差し替えていたが、これは全ての 403 に適用されるため
# 存在しないアセットまで 200 + HTML を返していた。JS として読み込まれると
# "Unexpected token '<'" になり原因が追いにくい。書き換え対象を絞ることで、
# 実ファイルが無い場合は素直に 404 を返す
resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite extensionless paths to /index.html"
  publish = true

  code = <<-JS
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      var last = uri.substring(uri.lastIndexOf('/') + 1);

      // 最後のセグメントに拡張子がなければ SPA のルートとみなす
      if (last.indexOf('.') === -1) {
        request.uri = '/index.html';
      }
      return request;
    }
  JS
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "frontend-security-headers"
  comment = "HSTS, nosniff, frame options, referrer policy, CSP"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      # preload は独自ドメインを持ってから。*.cloudfront.net には申請できない
      preload  = false
      override = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    # Vite のビルド成果物は外部ファイル参照なので 'self' で足りる。
    # style-src の unsafe-inline は動的に注入されるスタイル用。
    # connect-src はアプリが叩く外部 API を明示的に許可する
    content_security_policy {
      content_security_policy = join("; ", [
        "default-src 'self'",
        "img-src 'self' data:",
        "style-src 'self' 'unsafe-inline'",
        "font-src 'self'",
        "connect-src 'self' https://jsonplaceholder.typicode.com",
        "object-src 'none'",
        "base-uri 'self'",
        "frame-ancestors 'none'",
      ])
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # 日本を含むエッジロケーション

  # Terraform のデフォルトは false（コンソールは true）
  is_ipv6_enabled = true

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS 管理の CachingOptimized

    # Terraform のデフォルトは false。有効にしないと gzip/brotli で配信されない
    compress = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      },
      # ListBucket がないと存在しないキーで 403 が返る。404 を返させるために付与する。
      # バケット一覧が公開されるわけではない（CloudFront 経由の GET しか通らない）
      {
        Sid       = "AllowCloudFrontOACList"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.frontend.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
