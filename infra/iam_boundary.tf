# apply ロールが管理するロールが持てる権限の上限。
#
# 実効権限は「ロールのポリシー ∩ boundary」になる。ここに IAM の書き込みを
# 含めないことで、apply ロールが乗っ取られても新たな管理者ロールを作れない。
# apply ロール自身には付与しない（IAM 操作が必要なため）。自己変更の明示 Deny
# で保護している。
#
# このポリシー自体は apply ロールから変更できない（読み取り権限のみ付与）。
# 変更する場合はローカルの管理者権限で apply する
resource "aws_iam_policy" "boundary" {
  name        = "github-actions-boundary"
  description = "Maximum permissions for roles managed by github-actions-terraform-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "MaxPermissions"
      Effect = "Allow"
      Action = [
        "s3:*",
        "cloudfront:*",
        # refresh のための読み取りのみ。IAM とログの書き込みは意図的に含めない
        "iam:Get*",
        "iam:List*",
        "logs:Get*",
        "logs:List*",
        "logs:Describe*",
      ]
      Resource = "*"
    }]
  })
}
