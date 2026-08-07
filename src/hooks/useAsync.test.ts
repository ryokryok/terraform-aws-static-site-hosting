import { renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useAsync } from "./useAsync";

describe("useAsync", () => {
  it("解決した値を success として返す", async () => {
    const fetcher = () => Promise.resolve("ok");
    const { result } = renderHook(() => useAsync(fetcher));

    expect(result.current.status).toBe("loading");

    await waitFor(() => {
      expect(result.current).toEqual({ status: "success", data: "ok" });
    });
  });

  it("拒否された理由を error として返す", async () => {
    const boom = new Error("boom");
    const fetcher = () => Promise.reject(boom);
    const { result } = renderHook(() => useAsync(fetcher));

    await waitFor(() => {
      expect(result.current).toEqual({ status: "error", error: boom });
    });
  });

  it("Error 以外が投げられても Error に包む", async () => {
    const fetcher = () => Promise.reject("壊れた");
    const { result } = renderHook(() => useAsync(fetcher));

    await waitFor(() => {
      expect(result.current.status).toBe("error");
    });
    // 呼び出し側が error.message を読めることを保証する
    expect(result.current).toEqual({ status: "error", error: new Error("壊れた") });
  });

  it("アンマウント時に signal を abort する", () => {
    let captured: AbortSignal | undefined;
    const fetcher = (signal: AbortSignal) => {
      captured = signal;
      return new Promise<string>(() => {});
    };

    const { unmount } = renderHook(() => useAsync(fetcher));
    expect(captured?.aborted).toBe(false);

    unmount();
    expect(captured?.aborted).toBe(true);
  });

  // このフックの肝。中断は失敗ではないため、打ち切られたリクエストの reject が
  // 後から届いても、新しいリクエストの結果を error で上書きしてはいけない
  it("中断されたリクエストの失敗は状態に反映しない", async () => {
    const first = (signal: AbortSignal) =>
      new Promise<string>((_, reject) => {
        signal.addEventListener("abort", () => reject(new Error("中断された")));
      });
    const second = () => Promise.resolve("second");

    const { result, rerender } = renderHook(({ fetcher }) => useAsync(fetcher), {
      initialProps: { fetcher: first },
    });

    // fetcher を差し替えると、前のリクエストは cleanup で abort される
    rerender({ fetcher: second });

    await waitFor(() => {
      expect(result.current).toEqual({ status: "success", data: "second" });
    });
  });
});
