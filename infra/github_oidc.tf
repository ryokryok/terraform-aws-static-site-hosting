variable "github_owner" {
  description = "GitHub のオーナー名"
  default     = "ryokryok"
}

variable "github_repo" {
  description = "GitHub のリポジトリ名"
  default     = "terraform-aws-static-site-hosting"
}

# 以下の数値 ID は GitHub 側で固定的に採番されたもの。次のコマンドで確認できる:
#   gh api /users/<owner> --jq .id
#   gh api /repos/<owner>/<repo> --jq .id
variable "github_owner_id" {
  description = "GitHub オーナーの数値 ID"
  default     = "31591832"
}

variable "github_repo_id" {
  description = "GitHub リポジトリの数値 ID"
  default     = "1323184306"
}

locals {
  # GitHub Actions の OIDC トークンに入る sub クレーム。
  #
  # ネット上のサンプルの多くは "repo:owner/repo:ref:refs/heads/main" という
  # 名前ベースの形式だが、GitHub は immutable subject claims を導入しており、
  # 実際には オーナー名@オーナーID / リポジトリ名@リポジトリID という形になる。
  # 名前は変更も再取得もできてしまうため、削除されたリポジトリ名を第三者が
  # 取得して信頼関係を乗っ取る攻撃を防ぐ目的で数値 ID が埋め込まれている。
  #
  # 信頼ポリシーは StringEquals（完全一致）なので、旧形式で書くと
  # sts:AssumeRoleWithWebIdentity が "Not authorized" で拒否される。
  # 実際に発行される値は次で確認できる:
  #   gh api /repos/<owner>/<repo>/actions/oidc/customization/sub --jq .sub_claim_prefix
  github_sub_prefix = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"

  # main への push で発行されるトークンの sub
  github_sub_main = "${local.github_sub_prefix}:ref:refs/heads/main"
}

# thumbprint_list は省略。AWS が GitHub の証明書を自前の CA ストアで検証するため不要
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name                 = "github-actions-deploy"
  permissions_boundary = aws_iam_policy.boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        # sub は完全一致。main への push 以外からは Assume させない
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.github_sub_main
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Sync"
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
