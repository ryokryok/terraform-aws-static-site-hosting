import { Link } from "react-router";
import { fetchPosts } from "../api/posts";
import { useAsync } from "../hooks/useAsync";

export default function Posts() {
  const state = useAsync(fetchPosts);

  if (state.status === "loading") {
    return (
      <section className="page">
        <h1>Posts</h1>
        <p className="status">読み込み中...</p>
      </section>
    );
  }

  if (state.status === "error") {
    return (
      <section className="page">
        <h1>Posts</h1>
        <p className="status error">読み込みに失敗しました: {state.error.message}</p>
      </section>
    );
  }

  return (
    <section className="page">
      <h1>Posts</h1>
      <p>JSONPlaceholder から取得した {state.data.length} 件の記事です。</p>

      <ul className="post-list">
        {state.data.map((post) => (
          <li key={post.id}>
            <Link to={`/posts/${post.id}`}>
              <span className="post-id">#{post.id}</span>
              <span className="post-title">{post.title}</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
