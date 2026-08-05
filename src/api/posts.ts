const BASE_URL = "https://jsonplaceholder.typicode.com";

export type Post = {
  id: number;
  userId: number;
  title: string;
  body: string;
};

export type User = {
  id: number;
  name: string;
  username: string;
  email: string;
};

async function getJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${BASE_URL}${path}`, { signal });

  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  return response.json() as Promise<T>;
}

export function fetchPosts(signal?: AbortSignal) {
  return getJson<Post[]>("/posts", signal);
}

export function fetchPost(id: string, signal?: AbortSignal) {
  return getJson<Post>(`/posts/${id}`, signal);
}

export function fetchUser(id: number, signal?: AbortSignal) {
  return getJson<User>(`/users/${id}`, signal);
}
