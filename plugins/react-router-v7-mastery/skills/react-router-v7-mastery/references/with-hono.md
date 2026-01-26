# Hono + React Router v7 Integration Guide

React Router v7 (旧 Remix) と Hono を組み合わせ、Cloudflare Workers 上で動作させるためのアーキテクチャパターン。

## アーキテクチャ概要

### 構成図

```mermaid
graph TD
    Request[Client Request] --> Hono[Hono App (server/index.ts)]
    Hono -->|Path: /api/*| API[Hono API Routes (server/api.ts)]
    Hono -->|Path: *| RR[React Router Handler]
    
    subgraph Hono Context
        Env[Cloudflare Env]
    end
    
    subgraph React Router Loader/Action
        Client[API Client (app/lib/api.server.ts)]
    end
    
    RR --> Client
    Client -.->|Direct Call (app.request)| API
    API --> Env
```

### 核心原則

1.  **Server Entry Point**: Hono をサーバーの唯一のエントリーポイントとする。
2.  **Logic Separation**: ビジネスロジックとデータアクセスは Hono API (`server/api.ts`) に集約する。React Router は UI とルーティングに専念する。
3.  **RPC over Network**: Loader/Action からのデータ取得は、`hono-typed-rest` を用いた RPC パターンで行う。Worker 内部では `app.request` を注入してネットワークオーバーヘッドを回避する。

## 実装ステップ

### 1. プロジェクト構造

```
app/
  ├── lib/
  │   └── api.server.ts # サーバー内部通信用クライアント
server/
  ├── index.ts          # エントリーポイント
  ├── api.ts            # Hono API 定義 (ビジネスロジック)
  └── load-context.ts   # コンテキスト定義
vite.config.ts
wrangler.toml
```

### 2. Hono API 定義 (`server/api.ts`)

データアクセスロジックはここに記述します。

```typescript
import { Hono } from "hono";
import { drizzle } from "drizzle-orm/d1";
import { todos } from "../app/db/schema";
import type { Env } from "./load-context";

const app = new Hono<{ Bindings: Env }>()
  .get("/todos", async (c) => {
    const db = drizzle(c.env.DB);
    const result = await db.select().from(todos);
    return c.json({ todos: result });
  })
  // ... other routes
export default app;
```

### 3. サーバーエントリーポイント (`server/index.ts`)

静的アセット配信とルーティングの統合を行います。

```typescript
import { Hono } from "hono";
import { createRequestHandler } from "react-router";
// @ts-ignore
import * as build from "../build/server/index.js";
import { getLoadContext, type Env } from "./load-context";
import apiRoutes from "./api";

const app = new Hono<{ Bindings: Env }>();

// 静的アセット配信 (Workers必須)
// POST等のボディ消費を防ぐためメソッドチェックを行う
app.use("*", async (c, next) => {
  if (c.req.method !== 'GET' && c.req.method !== 'HEAD') {
    return await next();
  }
  // @ts-ignore
  if (c.env.ASSETS) {
    // @ts-ignore
    const res = await c.env.ASSETS.fetch(c.req.raw.clone());
    if (res.status < 400) return res;
  }
  await next();
});

// API マウント
const routes = app.route("/api", apiRoutes);
export type AppType = typeof routes;

// React Router ハンドラ
app.all("*", async (c) => {
  const requestHandler = createRequestHandler(build);
  const loadContext = getLoadContext({
    request: c.req.raw,
    context: {
      cloudflare: {
        env: c.env,
        cf: c.req.raw.cf,
        ctx: c.executionCtx,
        caches: caches,
      }
    }
  });
  return await requestHandler(c.req.raw, loadContext);
});

export default app;
```

### 4. 内部通信用クライアント (`app/lib/api.server.ts`)

Loader/Action から呼び出すためのクライアントです。`app.fetch` または `app.request` を注入します。

```typescript
import { createRestClient } from 'hono-typed-rest';
import app, { type AppType } from '../../server/index';

// Env を受け取ってクライアントを生成するファクトリ関数
export const getServerClient = (env: any) => createRestClient<AppType>({
  fetch: async (input, init) => {
    // app.fetch に env を渡すことで Bindings を利用可能にする
    if (input instanceof Request) {
        return app.fetch(input, env);
    }
    return app.request(input.toString(), init, env);
  },
  baseUrl: 'http://localhost' 
});
```

### 5. Loader での利用 (`app/routes/home.tsx`)

```typescript
import { getServerClient } from "../lib/api.server";

export async function loader({ context }: Route.LoaderArgs) {
  // コンテキストから Env を取得してクライアント生成
  const client = getServerClient(context.cloudflare.env);
  
  // 型安全な呼び出し
  const { todos } = await client.get("/api/todos");
  return { todos };
}
```

## ビルドとデプロイ設定

### Vite設定 (`vite.config.ts`)
Workers 環境向けに `react-dom/server` のエイリアスを設定します。

```typescript
export default defineConfig({
  resolve: {
    alias: {
      "react-dom/server": "react-dom/server.edge",
    },
  },
  // ...
});
```

### ビルドスクリプト (`package.json`)
`react-router build` の後に `esbuild` で `server/index.ts` をバンドルします。

```json
"scripts": {
  "build": "react-router build && esbuild server/index.ts --bundle --platform=neutral --target=es2022 --format=esm --outfile=dist/worker.js --main-fields=module,main --conditions=worker --alias:react-dom/server=react-dom/server.edge",
  "deploy": "wrangler deploy"
}
```

### Wrangler設定 (`wrangler.toml`)
`main` にはバンドル後のファイルを指定します。

```toml
main = "./dist/worker.js"
assets = { binding = "ASSETS", directory = "./build/client" }
```
