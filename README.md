# Study for Terraform of static site deployment

S3 + CloudFront による静的サイトホスティング。インフラは Terraform、デプロイは GitHub Actions（OIDC）で管理している。

## 必要なもの

- [mise](https://mise.jdx.dev/)（`AWS_PROFILE=learn` などの環境変数を設定する）
- Terraform 1.10 以降（`use_lockfile` による S3 ネイティブロックに必要）
- Node.js 24 / pnpm 10
- `learn` プロファイルの AWS SSO 設定（state バケットへのアクセス権が必要）

## セットアップ

```sh
git clone https://github.com/ryokryok/terraform-aws-static-site-hosting.git
cd terraform-aws-static-site-hosting

pnpm install
mise run aws:login    # aws sso login
mise run aws:check    # 認証確認

cd infra
terraform init        # S3 backend への接続を初期化
```

`terraform init` は必須。state は S3 にあり（接続先は `infra/main.tf` の backend ブロック）、接続情報は gitignore された `.terraform/` に書かれるため、クローン直後は `plan` が実行できない。

## 開発

```sh
pnpm dev              # 開発サーバー
pnpm build            # dist/ にビルド
pnpm lint             # oxlint
pnpm fmt              # oxfmt
```

## インフラ変更

```sh
mise run terraform:check   # fmt -recursive && validate

cd infra
terraform plan
terraform apply
```

state は S3 で共有されており、ローカルと CI が同じものを参照する。`use_lockfile = true` により、CI の apply 中にローカルで実行すると解放まで待たされる。

## デプロイ

`main` への push で `.github/workflows/deploy.yml` が動く。`infra/**` に差分があれば Terraform を、フロントエンドに差分があればビルドと S3 同期・CloudFront 無効化を実行する。

手動実行のトリガーは持たせていない。再デプロイしたい場合は Actions 画面から過去のランを re-run する（`gh run rerun <run-id>` でも可）。差分判定はそのランのコミットに対して再計算されるため、デプロイまで到達したランを選べば同じ内容が再度反映される。

ロール ARN はリポジトリ変数 `TF_ROLE_ARN` / `DEPLOY_ROLE_ARN` で設定する。

## 補足

```sh
mise run aws:open     # 公開中のサイトを開く
```
