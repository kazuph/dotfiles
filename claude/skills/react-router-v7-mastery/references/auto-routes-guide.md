# React Router Auto Routes 詳細ガイド

## 目次

1. [概要](#概要)
2. [インストールと設定](#インストールと設定)
3. [ルーティング規約](#ルーティング規約)
4. [コロケーション機構](#コロケーション機構)
5. [モノレポ対応](#モノレポ対応)
6. [重要な移行上の留意点](#重要な移行上の留意点)
7. [実践パターン](#実践パターン)

## 概要

**React Router Auto Routes** は、React Router v7+ 向けの自動ファイルベース ルーティング ライブラリ。

### 設計思想

1. **規約優先設定（Convention over Configuration）**
   - ファイル構造がルート定義を自動的に決定
   - ゼロコンフィグで動作し、スケーラビリティを実現

2. **コロケーション**
   - "Place code as close to where it's relevant as possible" — Kent C. Dodds
   - 関連コードを同じ場所に配置し、人為的な関心の分離を排除

### 主要機能

| 機能 | 説明 |
|------|------|
| **柔軟なファイル構成** | フォルダベースとドット区切り記法を混用可能 |
| **+ プレフィックス** | `+` で始まるファイルはルーターが無視（ヘルパー、テスト共存） |
| **モノレポ対応** | 複数フォルダからルートをマウント可能 |
| **ESM限定** | 最新ツールチェーン向けに最適化 |

### 要件

- Node.js ≥ 20
- React Router v7+

## インストールと設定

### インストール

```bash
npm install -D react-router-auto-routes
```

### 基本設定

```typescript
// app/routes.ts
import { autoRoutes } from 'react-router-auto-routes'

export default autoRoutes()
```

### カスタム設定

```typescript
// app/routes.ts
import { autoRoutes } from 'react-router-auto-routes'

export default autoRoutes({
  routesDir: 'routes',              // スキャン対象フォルダ（デフォルト: 'routes'）
  ignoredRouteFiles: ['**/*.*'],     // 無視するファイルパターン
  paramChar: '$',                    // 動的セグメント記号（デフォルト: '$'）
  colocationChar: '+',               // コロケーション記号（デフォルト: '+'）
  routeRegex: /\.(ts|tsx|js|jsx)$/,  // ルートファイル判定（デフォルト: TS/JS拡張子）
})
```

## ルーティング規約

### 基本的なファイルパターン

```
routes/
├── index.tsx               → /
├── about.tsx               → /about
├── contact.tsx             → /contact
└── blog.tsx                → /blog
```

### 動的セグメント

`$` プレフィックスで動的セグメントを定義。

```
routes/
├── users/
│   ├── index.tsx           → /users
│   └── $id.tsx             → /users/:id
└── posts/
    └── $slug.tsx           → /posts/:slug
```

```tsx
// routes/users/$id.tsx
export async function loader({ params }: Route.LoaderArgs) {
  const user = await getUser(params.id)  // params.id にアクセス
  return { user }
}
```

### キャッチオールルート

`$.tsx` でキャッチオールを定義。

```
routes/
├── index.tsx               → /
└── $.tsx                   → /* (404またはCMS動的ページ)
```

```tsx
// routes/$.tsx
export async function loader({ params }: Route.LoaderArgs) {
  const page = await getCMSPage(params['*'])  // params['*'] にマッチしたパス
  if (!page) throw new Response("Not Found", { status: 404 })
  return { page }
}

export default function CMSPage({ loaderData }: Route.ComponentProps) {
  return <div dangerouslySetInnerHTML={{ __html: loaderData.page.content }} />
}
```

### オプショナルセグメント

`(segment)` でオプショナルセグメントを定義。

```
routes/
└── (lang)/
    └── about.tsx           → /about または /lang/about
```

### リテラルドット

`[.]` でリテラルドットを含むファイル名を定義。

```
routes/
├── robots[.]txt.ts         → /robots.txt
└── sitemap[.]xml.ts        → /sitemap.xml
```

```tsx
// routes/robots[.]txt.ts
export function loader() {
  return new Response(
    `User-agent: *\nAllow: /`,
    { headers: { "Content-Type": "text/plain" } }
  )
}
```

### レイアウトルート

`_layout.tsx` でレイアウトを定義（URLに現れない）。

```
routes/
├── _layout.tsx             → レイアウト（Outlet必須）
├── index.tsx               → /
└── about.tsx               → /about
```

```tsx
// routes/_layout.tsx
import { Outlet } from 'react-router'

export default function Layout() {
  return (
    <div>
      <header>共通ヘッダー</header>
      <main>
        <Outlet />  {/* 子ルートがここにレンダリング */}
      </main>
      <footer>共通フッター</footer>
    </div>
  )
}
```

### ネストルート

フォルダ構造でネストを表現。

```
routes/
├── dashboard/
│   ├── index.tsx           → /dashboard
│   ├── settings.tsx        → /dashboard/settings
│   └── users/
│       ├── index.tsx       → /dashboard/users
│       └── $id.tsx         → /dashboard/users/:id
```

## コロケーション機構

### + プレフィックスの使い方

`+` で始まるファイル・フォルダはルート処理から除外され、ヘルパーやテストを共存させられる。

```
routes/
├── dashboard/
│   ├── index.tsx           → /dashboard（ルート）
│   ├── +helpers.ts         # ルーターが無視
│   ├── +types.ts           # ルーターが無視
│   ├── +components/        # ルーターが無視
│   │   ├── chart.tsx
│   │   └── data-table.tsx
│   └── +__tests__/         # ルーターが無視
│       └── index.test.tsx
```

### 相対インポート

同一ディレクトリ内の `+` ファイルは相対パスでインポート。

```tsx
// routes/dashboard/index.tsx
import { formatNumber } from './+helpers'
import { DashboardData } from './+types'
import { Chart } from './+components/chart'

export async function loader() {
  const data: DashboardData = await getDashboardData()
  return { data }
}

export default function Dashboard({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h1>ダッシュボード</h1>
      <Chart data={loaderData.data} />
      <p>合計: {formatNumber(loaderData.data.total)}</p>
    </div>
  )
}
```

### 重要な制約

**ルール：** `+` で始まるファイル・フォルダはトップレベル（`routes/` 直下）には置けない。

```
routes/
├── +helpers.ts             ❌ 許可されない
└── _top/
    └── +helpers.ts         ✅ OK
```

**理由：** トップレベルの `+` ファイルはルート構造に影響を与える可能性があるため。

## モノレポ対応

### 複数フォルダからルートをマウント

```typescript
// app/routes.ts
import { autoRoutes } from 'react-router-auto-routes'

export default autoRoutes({
  routesDir: {
    '/': 'app/routes',              // メインアプリ
    '/api': 'api/routes',            // API
    '/docs': 'packages/docs/routes', // ドキュメント
    '/shop': 'packages/shop/routes', // ショップ
  },
})
```

### 各パッケージの独立性

各マウントは独立してルート解決されますが、最終的には統合されます。

```
app/routes/
└── index.tsx               → /

api/routes/
├── users/
│   └── index.ts            → /api/users
└── products/
    └── index.ts            → /api/products

packages/docs/routes/
├── index.tsx               → /docs
└── getting-started.tsx     → /docs/getting-started

packages/shop/routes/
├── index.tsx               → /shop
└── products/
    └── $id.tsx             → /shop/products/:id
```

## 重要な移行上の留意点

### ネスティング vs. シブリング

React Router v7 では、共通パスプレフィックスを持つルートは**デフォルトでネストされる**（Remix とは異なる）。

#### 問題のあるパターン

```typescript
routes/
├── users.$id.tsx           → /users/:id（親）
└── users.$id.edit.tsx      → /users/:id/edit（子、users.$id の中にネスト）
```

このパターンでは、`users.$id.edit` が `users.$id` の子としてレンダリングされる。`users.$id` に `<Outlet />` がない場合、`users.$id.edit` は表示されない。

#### 解決策：フォルダ構造でシブリング化

```typescript
routes/users/$id/
├── index.tsx               → /users/:id（独立）
└── edit.tsx                → /users/:id/edit（独立）
```

このパターンでは、両方のルートが同じ階層（シブリング）として扱われる。

### ネストが必要な場合

親ルートで共通データを取得し、子ルートで機能を実装する場合は、ネストを活用する。

```typescript
routes/products/$id/
├── route.tsx               → /products/:id（親、レイアウト）
├── index.tsx               → /products/:id（詳細）
├── reviews.tsx             → /products/:id/reviews（レビュー）
└── specs.tsx               → /products/:id/specs（仕様）
```

```tsx
// routes/products/$id/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  const product = await getProduct(params.id)
  return { product }
}

export default function ProductLayout({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h1>{loaderData.product.name}</h1>
      <nav>
        <Link to=".">詳細</Link>
        <Link to="reviews">レビュー</Link>
        <Link to="specs">仕様</Link>
      </nav>
      <Outlet />  {/* 子ルートがここにレンダリング */}
    </div>
  )
}

// routes/products/$id/index.tsx
export default function ProductDetail() {
  const { product } = useLoaderData()  // 親から継承
  return <div>{product.description}</div>
}
```

## 実践パターン

### CMS/キャッチオールパターン

ホームページとキャッチオールを分離する。

```typescript
routes/
├── index.tsx               → / （ホームページ）
└── $.tsx                   → /* （404またはCMS動的ページ）
```

**理由：** React Router v7 ではオプショナル splat（`($)`）で予期しないエラーバウンダリ動作が生じるため。

```tsx
// routes/index.tsx
export default function Home() {
  return <h1>ホームページ</h1>
}

// routes/$.tsx
export async function loader({ params }: Route.LoaderArgs) {
  const slug = params['*']
  const page = await getCMSPage(slug)

  if (!page) {
    throw new Response("Not Found", { status: 404 })
  }

  return { page }
}

export default function CMSPage({ loaderData }: Route.ComponentProps) {
  return (
    <article>
      <h1>{loaderData.page.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: loaderData.page.content }} />
    </article>
  )
}
```

### 認証ルートパターン

認証が必要なルートと不要なルートを分離する。

```typescript
routes/
├── _public+/               # 認証不要
│   ├── index.tsx           → /
│   ├── login.tsx           → /login
│   └── register.tsx        → /register
└── _auth+/                 # 認証必須
    ├── dashboard/
    │   └── index.tsx       → /dashboard
    └── settings/
        └── index.tsx       → /settings
```

```tsx
// routes/_auth+/route.tsx（レイアウト）
export async function loader({ request }: Route.LoaderArgs) {
  const user = await requireAuth(request)
  return { user }
}

export default function AuthLayout({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <header>
        <p>ようこそ、{loaderData.user.name}さん</p>
      </header>
      <Outlet />
    </div>
  )
}
```

### 機能別ルート構成

機能単位でルートを整理する。

```typescript
routes/
├── _buyer+/                # 購入者向け機能
│   ├── products+/
│   │   └── $id+/
│   │       ├── route.tsx
│   │       └── +components/
│   └── orders+/
│       └── index.tsx
├── _seller+/               # 出品者向け機能
│   ├── products+/
│   │   └── $id+/
│   │       ├── route.tsx
│   │       └── +components/
│   └── analytics+/
│       └── index.tsx
└── _admin+/                # 管理者向け機能
    ├── users+/
    │   └── index.tsx
    └── settings+/
        └── index.tsx
```

### API ルートパターン

フロントエンドとAPIを同じプロジェクトで管理する。

```typescript
routes/
├── api/
│   ├── users/
│   │   ├── index.ts        → /api/users
│   │   └── $id.ts          → /api/users/:id
│   └── products/
│       ├── index.ts        → /api/products
│       └── $id.ts          → /api/products/:id
└── (ui)/
    ├── index.tsx           → /
    └── about.tsx           → /about
```

```tsx
// routes/api/users/index.ts
export async function loader() {
  const users = await getUsers()
  return Response.json({ users })
}

export async function action({ request }: Route.ActionArgs) {
  const data = await request.json()
  const user = await createUser(data)
  return Response.json({ user }, { status: 201 })
}
```

### マルチテナントパターン

テナントごとにルートを分離する。

```typescript
routes/
├── $tenant/                # テナント動的セグメント
│   ├── index.tsx           → /:tenant
│   ├── dashboard/
│   │   └── index.tsx       → /:tenant/dashboard
│   └── settings/
│       └── index.tsx       → /:tenant/settings
```

```tsx
// routes/$tenant/route.tsx（レイアウト）
export async function loader({ params }: Route.LoaderArgs) {
  const tenant = await getTenant(params.tenant)
  if (!tenant) throw new Response("Not Found", { status: 404 })
  return { tenant }
}

export default function TenantLayout({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <header>
        <h1>{loaderData.tenant.name}</h1>
      </header>
      <Outlet />
    </div>
  )
}
```

## まとめ

React Router Auto Routes により：

1. **ゼロコンフィグ** - ファイル構造がルート定義を自動生成
2. **コロケーション** - `+` プレフィックスで関連コードを近くに配置
3. **型安全** - TypeScript との統合で型推論が効く
4. **スケーラブル** - モノレポや大規模プロジェクトに対応
5. **柔軟** - ネスト、シブリング、キャッチオールなど多様なパターンをサポート

これらの機能により、「設定ファイルを書かず、ディレクトリ構造から自然にルートが生成され、変更影響範囲が明確」なプロジェクト構成を実現できる。
