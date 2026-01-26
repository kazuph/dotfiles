# Cloudflare Workers Deployment for Hono SSR

`create-cloudflare` (C3) や `create-hono` のデフォルトテンプレートは Cloudflare Pages を想定している場合がありますが、Cloudflare Workers の Assets Binding を活用することで、単一の Worker としてデプロイ可能です。

## 構成の変更点 (Pages -> Workers)

### 1. Vite 設定 (`vite.config.ts`)

Pages 用のアダプタを削除し、Workers 用のビルド設定を追加します。

```typescript
import { defineConfig } from 'vite'
import devServer from '@hono/vite-dev-server'
import ssrBuild from 'vite-ssr-components/plugin' // 注意: デフォルトエクスポート

export default defineConfig(({ mode }) => {
  if (mode === 'client') {
    return {
      build: {
        rollupOptions: {
          input: ['./src/client.tsx'],
          // ハッシュ付きファイル名を避ける場合は固定名を指定
          output: { dir: './dist/static', entryFileNames: '[name].js' },
        },
      },
    }
  }
  return {
    server: { port: 25174 },
    plugins: [
      devServer({ entry: 'src/index.tsx' }),
      ssrBuild(),
    ],
    // Workers用のビルド設定
    build: {
      target: 'esnext',
      emptyOutDir: false, // クライアントビルド(dist/static)を消さない
      ssr: 'src/index.tsx', // SSRエントリーポイント
      rollupOptions: {
        output: {
          entryFileNames: '_worker.js', // Workersのエントリーポイント
          dir: 'dist',
          format: 'esm',
        }
      }
    }
  }
})
```

### 2. Wrangler 設定 (`wrangler.jsonc`)

`pages_build_output_dir` を削除し、`main` と `assets` を設定します。

```jsonc
{
  "name": "hono-todo",
  "main": "./dist/_worker.js",
  "compatibility_date": "2025-04-03",
  "assets": {
    "binding": "ASSETS",
    "directory": "./dist/static"
  },
  // ...
}
```

### 3. 静的アセット配信ミドルウェア (`src/index.tsx`)

Workers 環境では、静的ファイルへのリクエストも Worker がハンドリングするため、明示的に `env.ASSETS` を呼び出す必要があります。
**重要**: `POST` 等のリクエストでボディを消費しないよう、メソッドチェックや `clone()` を行うこと。

```typescript
app.use('*', async (c, next) => {
  // GET/HEAD 以外はスキップ (POSTボディ消費回避)
  if (c.req.method !== 'GET' && c.req.method !== 'HEAD') {
    return await next()
  }
  
  // @ts-ignore
  if (c.env.ASSETS) {
    // リクエストを clone して渡すのが安全
    // @ts-ignore
    const res = await c.env.ASSETS.fetch(c.req.raw.clone())
    if (res.status < 400) {
      return res
    }
  }
  await next()
})
```

### 4. クライアントスクリプトの読み込み

`vite-ssr-components` の `<Script />` は便利ですが、Workers 環境でのパス解決が難しい場合、Vite の出力に合わせて手動で `<script>` タグを書く方が確実な場合があります。

```tsx
<head>
  {import.meta.env.PROD ? (
    <script type="module" src="/client.js"></script>
  ) : (
    <>
      <ViteClient />
      <Script src="/src/client.tsx" />
    </>
  )}
</head>
```

## 型安全なAPI通信 (`hono-typed-rest`)

クライアントサイド (`src/client.tsx`) からサーバー (`src/index.tsx` または `src/api.ts`) の API を呼び出す際は、`hono-typed-rest` を利用して型安全性を確保します。

### API 定義 (`src/api.ts`)

```typescript
const api = new Hono()
  .get('/todos', ...)
  .post('/todos', ...)

export default api
export type AppType = typeof api
```

### クライアント実装 (`src/client.tsx`)

```typescript
import { createRestClient } from 'hono-typed-rest'
import type { AppType } from './api'

const client = createRestClient<AppType>({
  baseUrl: window.location.origin + '/api'
})

// 使用例
const todos = await client.get('/todos')
```

## デプロイコマンド

```bash
npm run build
npx wrangler deploy # pages deploy ではない
```
