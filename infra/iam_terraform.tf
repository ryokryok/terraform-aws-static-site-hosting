locals {
  # PR では plan だけを流す。main への push でもデプロイ先の取得と plan が
  # 必要なため、plan ロールは両方の sub を信頼する
  github_sub_pull_request = "${local.github_sub_prefix}:pull_request"

  # apply は GitHub Environment の保護ルール（承認者・ブランチ制限）を
  # 通過しないとトークン自体が発行されない。ブランチ参照より強い制御
  github_sub_environment = "${local.github_sub_prefix}:environment:production"
}

# ---------------------------------------------------------------------------
# plan 用（読み取り専用）
# ---------------------------------------------------------------------------

resource "aws_iam_role" "terraform_plan" {
  name = "github-actions-terraform-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        # 値をリストにすると OR 判定になる
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = [
            local.github_sub_pull_request,
            local.github_sub_main,
          ]
        }
      }
    }]
  })
}

# plan は -lock=false で実行するため state への書き込みは不要
resource "aws_iam_role_policy" "terraform_plan" {
  name = "terraform-plan-policy"
  role = aws_iam_role.terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Read"
        Effect = "Allow"
        Action = ["s3:Get*", "s3:List*"]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },
      {
        Sid      = "CloudFrontRead"
        Effect   = "Allow"
        Action   = ["cloudfront:Get*", "cloudfront:List*"]
        Resource = "*"
      },
      {
        Sid      = "IAMRead"
        Effect   = "Allow"
        Action   = ["iam:Get*", "iam:List*"]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-*"
      },
      {
        Sid      = "IAMOIDCRead"
        Effect   = "Allow"
        Action   = ["iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviders"]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# apply 用（書き込み。Environment の承認ゲート内でのみ Assume 可能）
# ---------------------------------------------------------------------------

resource "aws_iam_role" "terraform_apply" {
  name = "github-actions-terraform-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.github_sub_environment
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform_apply" {
  name = "terraform-apply-policy"
  role = aws_iam_role.terraform_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # プロバイダは refresh のたびにバケット設定を細かく読み出すため、
      # 個別アクションの列挙は現実的でない。対象バケットを2つに限定して s3:* を許可する
      {
        Sid    = "S3Buckets"
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },
      # CloudFront は CreateDistribution などがリソース単位の指定に対応しないため "*"
      {
        Sid      = "CloudFront"
        Effect   = "Allow"
        Action   = "cloudfront:*"
        Resource = "*"
      },
      {
        Sid    = "IAMRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-*"
      },
      {
        Sid    = "IAMOIDCProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ]
        Resource = aws_iam_openid_connect_provider.github.arn
      },
      # 権限昇格の遮断。IAMRoles は github-actions-* を対象にしており、
      # このロール自身も含まれてしまう。自分の信頼ポリシーを書き換えられると
      # 任意の sub から Assume できるようになるため、明示的に拒否する。
      # 明示 Deny は Allow より常に優先される。
      #
      # この結果、apply ロール自体の変更は CI から行えない。
      # 変更する場合はローカルの管理者権限で apply する（意図的な制約）
      {
        Sid    = "DenySelfModification"
        Effect = "Deny"
        Action = [
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRole",
          "iam:PutRolePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-terraform-apply"
      }
    ]
  })
}

output "terraform_plan_role_arn" {
  value = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  value = aws_iam_role.terraform_apply.arn
}
