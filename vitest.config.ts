import { defineConfig } from "vitest/config";

// vite.config.ts とは別に用意している。ビルドには React Compiler の babel
// プラグインが要るが、テストでは変換を挟まないほうが挙動を追いやすい。
// vitest.config.ts があると vitest は vite.config.ts を読まないため、
// プラグインの二重適用も起きない
export default defineConfig({
  test: {
    // renderHook が DOM を必要とするため
    environment: "jsdom",
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
  },
});
