terraform {
  required_version = ">= 1.9"

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
