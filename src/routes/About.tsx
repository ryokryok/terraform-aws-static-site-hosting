export default function About() {
  return (
    <section className="page">
      <h1>About</h1>
      <p>
        Terraform で AWS 上に静的サイトをホスティングする構成の学習用リポジトリです。
        インフラの変更もアプリのデプロイも GitHub Actions から自動で行われます。
      </p>

      <h2>配信</h2>
      <ul className="plain">
        <li>S3 はパブリックアクセスを全面ブロックし、CloudFront から OAC 経由でのみ読み取ります</li>
        <li>ハッシュ付きアセットは 1 年間、HTML は毎回再検証するキャッシュ設定です</li>
        <li>gzip / brotli による圧縮と、HSTS や CSP などのセキュリティヘッダを付与しています</li>
      </ul>

      <h2>デプロイ</h2>
      <ul className="plain">
        <li>OIDC で一時認証情報を取得するため、アクセスキーは保存していません</li>
        <li>Terraform は plan と apply でロールを分離しています</li>
        <li>PR の時点で plan の差分がコメントされます</li>
      </ul>

      <h2>このページについて</h2>
      <p>
        クライアントサイドルーティングで表示しています。CloudFront Function が拡張子を持たない
        パスを <code>/index.html</code>{" "}
        に書き換えるため、直接アクセスしてもリロードしても動作します。
      </p>
    </section>
  );
}
