---
name: hono-vite-ssr
description: Hono + Vite SSR開発のテンプレートとガイド。サーバー/クライアント2ファイル構成でTypeScript JSXを使用。vite-ssr-componentsでScript/Link/ViteClientを提供。Cloudflare Workers対応。Webアプリ作成時やHono SSRプロジェクト立ち上げ時に使用。
---

# Hono + Vite SSR Development

Hono + Viteの組み合わせで、最小限のファイル構成でSSR対応のWebアプリを構築するパターン。

## 特徴

- サーバー/クライアントの2ファイル構成（+ style.css）
- サーバー側からScriptタグでクライアントファイルを指定
- クライアントファイルでJSXが書ける（hono/jsx/dom）
- 起動は `vite` (dev) / `vite build` (prod)
- Cloudflare Workers環境を再現可能

## Cloudflare Workers 対応
`vite-ssr-components` は Pages をデフォルトとしていますが、単一 Worker としてのデプロイも可能です。
詳細は [Cloudflare Workers Deployment](references/workers-deployment.md) を参照してください。

## プロジェクト構造

```
my-app/
├── src/
│   ├── index.tsx      # サーバーコード
│   ├── client.tsx     # クライアントコード
│   └── style.css      # スタイル
├── public/            # 静的ファイル
├── package.json
├── tsconfig.json
├── vite.config.ts
└── wrangler.jsonc     # Cloudflare Workers設定（オプション）
```

## 依存関係

```json
{
  "dependencies": {
    "hono": "^4.x"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.x",
    "@hono/vite-cloudflare-pages": "^0.x",
    "@hono/vite-dev-server": "^0.x",
    "vite": "^6.x",
    "vite-ssr-components": "^0.x",
    "wrangler": "^4.x"
  }
}
```

## サーバーコード（src/index.tsx）

```tsx
import { Hono } from 'hono'
import { Link, Script, ViteClient } from 'vite-ssr-components/hono'

const app = new Hono()

app.get('/', (c) => {
  return c.html(
    <html>
      <head>
        <ViteClient />
        <Script src="/src/client" />
        <Link href="/src/style.css" rel="stylesheet" />
      </head>
      <body>
        <div id="app"></div>
      </body>
    </html>
  )
})

// API例
app.get('/api/data', (c) => {
  return c.json({ message: 'Hello from API' })
})

export default app
```

### 重要ポイント

- `ViteClient`: Vite HMR用のクライアントスクリプトを注入
- `Script src="/src/client"`: クライアントエントリーポイント（拡張子不要）
- `Link href="/src/style.css"`: CSSファイルの読み込み
- `export default app`: Cloudflare Workers / Vite dev server用

## クライアントコード（src/client.tsx）

```tsx
import { render } from 'hono/jsx/dom'

function App() {
  return <h1>Hello World</h1>
}

render(<App />, document.getElementById('app')!)
```

### より実用的な例

```tsx
import { render } from 'hono/jsx/dom'
import { useState, useEffect } from 'hono/jsx'

function App() {
  const [count, setCount] = useState(0)
  const [data, setData] = useState<{ message: string } | null>(null)

  useEffect(() => {
    fetch('/api/data')
      .then(res => res.json())
      .then(setData)
  }, [])

  return (
    <div>
      <h1>Hono + Vite SSR</h1>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
      {data && <p>API Response: {data.message}</p>}
    </div>
  )
}

render(<App />, document.getElementById('app')!)
```

## Vite設定（vite.config.ts）

```ts
import { defineConfig } from 'vite'
import devServer from '@hono/vite-dev-server'
import cloudflareAdapter from '@hono/vite-cloudflare-pages'

export default defineConfig({
  plugins: [
    devServer({
      entry: 'src/index.tsx',
    }),
    cloudflareAdapter(),
  ],
})
```

### ビルド分離設定（本番用）

```ts
import { defineConfig } from 'vite'
import devServer from '@hono/vite-dev-server'
import cloudflareAdapter from '@hono/vite-cloudflare-pages'
import { ssrBuild } from 'vite-ssr-components'

export default defineConfig(({ mode }) => {
  if (mode === 'client') {
    return {
      build: {
        rollupOptions: {
          input: ['./src/client.tsx', './src/style.css'],
          output: { dir: './dist/static', entryFileNames: 'static/[name].js' },
        },
      },
    }
  }
  return {
    plugins: [
      devServer({ entry: 'src/index.tsx' }),
      cloudflareAdapter(),
      ssrBuild(),
    ],
  }
})
```

## TypeScript設定（tsconfig.json）

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "react-jsx",
    "jsxImportSource": "hono/jsx",
    "types": ["vite/client", "@cloudflare/workers-types"],
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
```

## Cloudflare設定（wrangler.jsonc）

```jsonc
{
  "name": "my-app",
  "compatibility_date": "2025-01-01",
  "pages_build_output_dir": "./dist"
}
```

## npm scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build --mode client && vite build",
    "preview": "wrangler pages dev dist",
    "deploy": "wrangler pages deploy dist"
  }
}
```

## プロジェクト作成手順

```bash
# 1. ディレクトリ作成
mkdir my-app && cd my-app

# 2. package.json初期化
npm init -y

# 3. 依存関係インストール
npm install hono
npm install -D vite @hono/vite-dev-server @hono/vite-cloudflare-pages \
  vite-ssr-components wrangler @cloudflare/workers-types

# 4. srcディレクトリ作成
mkdir src

# 5. ファイル作成（上記のindex.tsx, client.tsx, style.css）

# 6. 開発サーバー起動
npm run dev
```

## 開発フロー

1. `npm run dev` で開発サーバー起動（http://localhost:5173）
2. サーバーコード変更 → 自動リロード
3. クライアントコード変更 → HMR
4. `npm run build` でビルド
5. `npm run preview` でローカルプレビュー
6. `npm run deploy` でCloudflare Pagesにデプロイ

## ベストプラクティス

### サーバー/クライアント分離

- サーバー側（index.tsx）: ルーティング、API、HTMLシェル
- クライアント側（client.tsx）: インタラクティブUI、状態管理

### 型共有

```tsx
// src/types.ts
export interface User {
  id: string
  name: string
}

// サーバー・クライアント両方でimport可能
```

### 環境変数

```tsx
// サーバー側（Cloudflare Bindings）
app.get('/api/secret', (c) => {
  const secret = c.env.SECRET_KEY
  return c.json({ hasSecret: !!secret })
})

// クライアント側（Vite環境変数）
const apiUrl = import.meta.env.VITE_API_URL
```

## トラブルシューティング

### HMRが効かない

- `ViteClient` コンポーネントがhead内にあるか確認
- vite.config.ts の `entry` パスが正しいか確認

### クライアントJSが読み込まれない

- `Script src` のパスが `/src/client` （拡張子なし）か確認
- ブラウザのネットワークタブでエラーを確認

### Cloudflareデプロイ後に動かない

- `pages_build_output_dir` が `./dist` を指しているか確認
- ビルドコマンドが正しく実行されているか確認
