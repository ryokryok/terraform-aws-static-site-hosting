terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 学習初期は local backend でOK。tfstate がカレントに落ちる。
  # チーム運用や PC 買い替えに備えるなら S3 backend に移行（本書末尾参照）
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "learn"
}

# CloudFront + ACM 証明書は us-east-1 必須なので、独自ドメインを使う場合に備えてエイリアスを用意
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "learn"
}