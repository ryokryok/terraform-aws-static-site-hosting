import { useCallback } from "react";
import { Link, useParams } from "react-router";
import { fetchPost, fetchUser, type Post as PostType, type User } from "../api/posts";
import { useAsync } from "../hooks/useAsync";

type PostWithAuthor = { post: PostType; author: User };

export default function Post() {
  const { id } = useParams<{ id: string }>();

  const fetcher = useCallback(
    async (signal: AbortSignal): Promise<PostWithAuthor> => {
      const post = await fetchPost(id!, signal);
      const author = await fetchUser(post.userId, signal);
      return { post, author };
    },
    [id],
  );

  const state = useAsync(fetcher);

  if (state.status === "loading") {
    return (
      <section className="page">
        <p className="status">読み込み中...</p>
      </section>
    );
  }

  if (state.status === "error") {
    return (
      <section className="page">
        <h1>記事が見つかりません</h1>
        <p className="status error">{state.error.message}</p>
        <Link to="/posts">一覧に戻る</Link>
      </section>
    );
  }

  const { post, author } = state.data;

  return (
    <section className="page">
      <p className="breadcrumb">
        <Link to="/posts">← 一覧に戻る</Link>
      </p>

      <article>
        <h1>{post.title}</h1>
        <p className="meta">
          #{post.id} · {author.name}（@{author.username}）
        </p>
        <p className="body">{post.body}</p>
      </article>
    </section>
  );
}
