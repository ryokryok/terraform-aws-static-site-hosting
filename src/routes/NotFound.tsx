import { Link } from "react-router";

export default function NotFound() {
  return (
    <section className="page">
      <h1>404</h1>
      <p>お探しのページは見つかりませんでした。</p>
      <Link to="/">トップへ戻る</Link>
    </section>
  );
}
