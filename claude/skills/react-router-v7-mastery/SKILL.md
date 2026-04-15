---
name: react-router-v7-mastery
description: React Router v7のモダンな開発手法を提供するスキル。ファイルベースルーティング(auto-routes)、機能的凝集とコロケーション、Hono統合(Cloudflare Workers)、型安全なパターンマッチング等のベストプラクティスを含む。
---

# React Router v7 Mastery

React Router v7のモダンな開発手法とベストプラクティスを提供するスキル。

## 核心原則

### 1. 機能的凝集（Functional Cohesion）
単一の明確な役割に集中したモジュール設計により、変更耐性と保守性を向上させる。

### 2. コロケーション（Colocation）
関連コードを同じ場所に配置し、人為的な関心の分離を排除する。

### 3. 規約優先設定（Convention over Configuration）
ファイル構造がルート定義を自動的に決定し、ゼロコンフィグで動作する。

## Hono + React Router 統合 (Cloudflare Workers)

Hono をサーバーエントリーポイントとし、API は Hono、UI は React Router で処理するハイブリッド構成。
詳細は [references/with-hono.md](references/with-hono.md) を参照。

### 構成概要
- **Entry**: `server/index.ts` で Hono インスタンスを作成。
- **API**: `/api/*` は Hono の `app.route()` で処理。
- **UI**: `*` を React Router の `createRequestHandler` に委譲。
- **Context**: `AppLoadContext` を通じて Cloudflare Bindings (`env`, `cf`, `ctx`) を Loader/Action に注入。

```typescript
// server/index.ts
import { Hono } from "hono";
import { createRequestHandler } from "react-router";

const app = new Hono();
app.route("/api", apiRoutes); // APIはHonoで
app.all("*", (c) => requestHandler(c.req.raw, getLoadContext(c))); // UIはReact Routerで
export default app;
```

## 自動ルート生成（react-router-auto-routes）

詳細は [references/auto-routes-guide.md](references/auto-routes-guide.md) を参照。

### 基本設定
```typescript
// app/routes.ts
import { autoRoutes } from 'react-router-auto-routes'

export default autoRoutes({
  routesDir: 'routes',
  routeRegex: /\.(ts|tsx|js|jsx)$/,
})
```

## 実装パターン

### ロール別ルート分離
同じリソースでもロールによって責務が異なる場合は、ルートを分離する（例: `_buyer+/products` vs `_seller+/products`）。

### + プレフィックス（コロケーション）
`+` で始まるファイル・フォルダはルート処理から除外され、ヘルパーやテストを共存させられる。

```
routes/
├── dashboard/
│   ├── route.tsx           → /dashboard
│   ├── +helpers.ts         # 除外
│   └── +components/        # 除外
```

### ts-pattern による型安全な出し分け
ルート分岐できない場合、`ts-pattern` で各ケースを独立させる。

## ディレクトリ構造規約
```
app/routes/
├── _buyer+/                    # 購入者向け
├── _seller+/                   # 出品者向け
└── _shared/                    # 共有コンポーネント
```

## 参考資料
- [Hono統合ガイド](references/with-hono.md) - Cloudflare WorkersでのHono + RRv7構成
- [凝集パターン詳細](references/cohesion-patterns.md)
- [自動ルート生成ガイド](references/auto-routes-guide.md)
