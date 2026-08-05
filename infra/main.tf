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

provider "aws" {
  region  = "ap-northeast-1"
  profile = "learn"
}

# 独自ドメイン用の ACM 証明書は us-east-1 でしか発行できない
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "learn"
}
