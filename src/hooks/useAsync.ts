import { useEffect, useState } from "react";

type State<T> =
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "success"; data: T };

/**
 * 取得処理を loading / error / success の3状態にまとめる。
 * アンマウントや fetcher の変更時は AbortController でリクエストを打ち切る。
 *
 * fetcher は呼び出し側で安定させること（モジュールレベルの関数か useCallback）。
 * 毎レンダリングで新しい関数を渡すと取得が繰り返される。
 */
export function useAsync<T>(fetcher: (signal: AbortSignal) => Promise<T>): State<T> {
  const [state, setState] = useState<State<T>>({ status: "loading" });

  useEffect(() => {
    const controller = new AbortController();
    setState({ status: "loading" });

    fetcher(controller.signal)
      .then((data) => setState({ status: "success", data }))
      .catch((error: unknown) => {
        // 中断は失敗ではないので状態を更新しない
        if (controller.signal.aborted) return;
        setState({
          status: "error",
          error: error instanceof Error ? error : new Error(String(error)),
        });
      });

    return () => controller.abort();
  }, [fetcher]);

  return state;
}
