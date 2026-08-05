terraform {
  # use_lockfile による S3 ネイティブロックは 1.10 以降
  required_version = ">= 1.10"

  # バケット名は backend ブロックでは変数展開できないためリテラル。
  # 変更する場合は backend.tf 側と揃えること
  backend "s3" {
    bucket       = "tfstate-871157256598"
    key          = "static-site/prod/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# profile は指定しない。ローカルは mise が設定する AWS_PROFILE、
# CI は OIDC で発行された環境変数の認証情報がそれぞれ使われる。
# ここに profile を書くと CI 側で "failed to get shared config profile" になる
# 全リソースに共通タグを付ける。コスト配分と、手動で作られたものとの区別に使う
locals {
  default_tags = {
    Project   = "terraform-aws-static-site-hosting"
    ManagedBy = "terraform"
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = local.default_tags
  }
}

# 独自ドメイン用の ACM 証明書は us-east-1 でしか発行できない
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}
