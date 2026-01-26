# 凝集パターン詳細ガイド

## 目次

1. [凝集度の概念](#凝集度の概念)
2. [凝集度の段階的分類](#凝集度の段階的分類)
3. [機能的凝集の実現方法](#機能的凝集の実現方法)
4. [実践的なリファクタリング例](#実践的なリファクタリング例)
5. [アンチパターンと解決策](#アンチパターンと解決策)

## 凝集度の概念

**凝集度（Cohesion）** は、モジュール内の要素がどれだけ密接に関連しているかを示す指標。1970年代に確立された概念だが、現代のフロントエンド開発でも変更耐性と保守性の向上に直結する。

### 判断基準

「このファイルは何をするものですか？」と問いかけて、**一文で答えられるかどうか**が凝集度の判断基準。

- **答えやすい** → 凝集度が高い（良い設計）
- **答えにくい** → 凝集度が低い（改善の余地あり）

## 凝集度の段階的分類

低い順に4段階で分類：

### 1. 偶発的凝集（Coincidental Cohesion）

**特徴：** 関連性のないユーティリティがたまたま同じファイルに存在する状態。「ここに置いとくか」型。

**問題点：**
- ファイルの目的が不明確
- 変更の影響範囲が予測困難
- テストが困難

**例：**

```tsx
// app/routes/profile+/edit+/route.tsx
// 改善前：プロフィール編集ページに日付フォーマット関数が混在
export const formatDate = (d: Date) => d.toLocaleDateString("ja-JP")
export const slugify = (s: string) => s.toLowerCase().replace(/\s+/g, "-")
export const calculateAge = (birthDate: Date) => {
  const today = new Date()
  return today.getFullYear() - birthDate.getFullYear()
}

export async function loader({ params }: Route.LoaderArgs) {
  const profile = await getProfile(params.userId)
  return { profile }
}

export default function ProfileEdit({ loaderData }: Route.ComponentProps) {
  return <ProfileForm profile={loaderData.profile} />
}
```

**改善後：**

```tsx
// utils/format.ts に移動
export const formatDate = (d: Date) => d.toLocaleDateString("ja-JP")
export const slugify = (s: string) => s.toLowerCase().replace(/\s+/g, "-")
export const calculateAge = (birthDate: Date) => {
  const today = new Date()
  return today.getFullYear() - birthDate.getFullYear()
}

// app/routes/profile+/edit+/route.tsx
import { formatDate, calculateAge } from '~/utils/format'

export async function loader({ params }: Route.LoaderArgs) {
  const profile = await getProfile(params.userId)
  return { profile }
}

export default function ProfileEdit({ loaderData }: Route.ComponentProps) {
  return <ProfileForm profile={loaderData.profile} />
}
```

### 2. 時間的凝集（Temporal Cohesion）

**特徴：** 同じタイミングで実行されるが目的が異なる処理が混在。「同時にやるから」型。

**問題点：**
- 責務の境界が不明確
- 一部の処理だけ再利用できない
- テスト時に無関係な処理もセットアップが必要

**例：**

```tsx
// 改善前：ページ表示時のデータ取得とアナリティクス送信が混在
export async function loader({ params }: Route.LoaderArgs) {
  // データ取得
  const profile = await fetch(`/api/profile/${params.userId}`).then(r => r.json())

  // アナリティクス送信（目的が異なる）
  await fetch("/api/analytics", {
    method: "POST",
    body: JSON.stringify({
      event: "profile_view",
      userId: params.userId,
      timestamp: new Date().toISOString()
    }),
  })

  // 訪問者数カウント（これも目的が異なる）
  await fetch(`/api/profile/${params.userId}/increment-view`, {
    method: "POST",
  })

  return { profile }
}
```

**改善後：**

```tsx
// app/routes/profile+/$userId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  // データ取得のみに集中
  const profile = await getProfile(params.userId)
  return { profile }
}

// アナリティクスは親レイアウトまたはミドルウェアで管理
// app/routes/profile+/route.tsx
export default function ProfileLayout() {
  const location = useLocation()

  useEffect(() => {
    // クライアントサイドでアナリティクス送信
    trackPageView(location.pathname)
  }, [location])

  return <Outlet />
}
```

### 3. 手続き的凝集（Procedural Cohesion）

**特徴：** 複数の目的を持つ処理が順序で連鎖している状態。「一連の流れだから」型。

**問題点：**
- 一つの関数が複数の責務を持つ
- 部分的な再利用が困難
- テストが複雑になる

**例：**

```tsx
// 改善前：バリデーション→保存→監査ログ→キャッシュクリアが同じactionに詰め込まれる
export async function action({ request, params }: Route.ActionArgs) {
  const form = await request.formData()
  const name = form.get("name") as string
  const email = form.get("email") as string

  // バリデーション
  if (!name.trim()) {
    return { error: "名前は必須です" }
  }
  if (!email.includes("@")) {
    return { error: "メールアドレスが不正です" }
  }

  // 保存
  const response = await fetch(`/api/profile/${params.userId}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, email }),
  })

  if (!response.ok) {
    return { error: "保存に失敗しました" }
  }

  // 監査ログ
  await fetch("/api/audit", {
    method: "POST",
    body: JSON.stringify({
      action: "profile_update",
      userId: params.userId,
      timestamp: new Date().toISOString(),
    }),
  })

  // キャッシュクリア
  await fetch("/api/cache/clear", {
    method: "POST",
    body: JSON.stringify({ key: `profile:${params.userId}` }),
  })

  return redirect(`/profile/${params.userId}`)
}
```

**改善後：**

```tsx
// features/profile/validation.ts
export function validateProfile(name: string, email: string) {
  if (!name.trim()) return { error: "名前は必須です" }
  if (!email.includes("@")) return { error: "メールアドレスが不正です" }
  return null
}

// features/profile/mutations.ts
export async function updateProfile(userId: string, data: { name: string; email: string }) {
  const response = await fetch(`/api/profile/${userId}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  })

  if (!response.ok) {
    throw new Error("保存に失敗しました")
  }

  return response.json()
}

// app/routes/profile+/$userId+/edit+/route.tsx
import { validateProfile } from '~/features/profile/validation'
import { updateProfile } from '~/features/profile/mutations'

export async function action({ request, params }: Route.ActionArgs) {
  const form = await request.formData()
  const name = form.get("name") as string
  const email = form.get("email") as string

  // バリデーション
  const error = validateProfile(name, email)
  if (error) return error

  // 保存（監査ログとキャッシュクリアはAPIサーバー側で処理）
  try {
    await updateProfile(params.userId, { name, email })
  } catch (e) {
    return { error: e.message }
  }

  return redirect(`/profile/${params.userId}`)
}
```

### 4. 機能的凝集（Functional Cohesion）

**特徴：** 単一の明確な役割に集中している理想的な状態。「これだけやる」型。

**利点：**
- 責務が明確
- 再利用しやすい
- テストが容易
- 変更の影響範囲が限定的

**例：**

```tsx
// app/routes/products+/$productId+/reviews+/route.tsx
// レビュー表示のみに集中
export async function loader({ params }: Route.LoaderArgs) {
  const reviews = await getProductReviews(params.productId)
  return { reviews }
}

export default function ProductReviews({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h2>レビュー</h2>
      {loaderData.reviews.map(review => (
        <ReviewCard key={review.id} review={review} />
      ))}
    </div>
  )
}

// app/routes/products+/$productId+/reviews+/new+/route.tsx
// レビュー投稿のみに集中
export async function action({ request, params }: Route.ActionArgs) {
  const form = await request.formData()
  const rating = Number(form.get("rating"))
  const comment = form.get("comment") as string

  await createReview(params.productId, { rating, comment })
  return redirect(`/products/${params.productId}/reviews`)
}

export default function NewReview() {
  return <ReviewForm />
}
```

## 機能的凝集の実現方法

### ロール別ルート分離

同じリソースでもロールによって責務が異なる場合は、ルートを分離する。

```tsx
// 購入者向け: app/routes/_buyer+/products+/$productId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  return {
    product: await getProductForBuyer(params.productId),
    purchaseHistory: await getPurchaseHistory(params.productId),
  }
}

export default function BuyerProductPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <ProductInfo product={loaderData.product} />
      <PurchaseButton />
      <PurchaseHistory history={loaderData.purchaseHistory} />
      <ReviewSection />
    </div>
  )
}

// 出品者向け: app/routes/_seller+/products+/$productId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  return {
    product: await getProductForSeller(params.productId),
    salesAnalytics: await getSalesAnalytics(params.productId),
    inventory: await getInventory(params.productId),
  }
}

export async function action({ request, params }: Route.ActionArgs) {
  const form = await request.formData()
  await updateStock(params.productId, form)
  return redirect('.')
}

export default function SellerProductPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <ProductInfo product={loaderData.product} />
      <StockManagement inventory={loaderData.inventory} />
      <SalesAnalytics data={loaderData.salesAnalytics} />
      <OrderManagement />
    </div>
  )
}
```

**利点：**
- 購入者向け機能修正が出品者機能に影響しない
- 各ロールに必要なデータだけを取得
- action の有無など、責務の違いが明確

### 作成・編集ルートの分離

同じフォームコンポーネントでも、ルートは分ける。

```
app/routes/products+/
├── _shared/components/product-form.tsx  # フォームコンポーネント（共通）
├── new+/route.tsx                        # 作成用（loaderなし、actionのみ）
└── $productId+/edit+/route.tsx           # 編集用（loader + action）
```

```tsx
// app/routes/products+/new+/route.tsx
export async function action({ request }: Route.ActionArgs) {
  const form = await request.formData()
  const product = await createProduct(form)
  return redirect(`/products/${product.id}`)
}

export default function NewProduct() {
  return <ProductForm mode="create" />
}

// app/routes/products+/$productId+/edit+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  const product = await getProduct(params.productId)
  return { product }
}

export async function action({ request, params }: Route.ActionArgs) {
  const form = await request.formData()
  await updateProduct(params.productId, form)
  return redirect(`/products/${params.productId}`)
}

export default function EditProduct({ loaderData }: Route.ComponentProps) {
  return <ProductForm mode="edit" defaultValues={loaderData.product} />
}
```

## 実践的なリファクタリング例

### Before: 論理的凝集（条件分岐が散乱）

```tsx
// app/routes/products+/$productId+/route.tsx
function ProductDetailPage({ role }: { role: "buyer" | "seller" | "admin" }) {
  const { product } = useLoaderData<typeof loader>()

  return (
    <div>
      <h1>{product.name}</h1>

      {role === "buyer" && (
        <>
          <PurchaseButton productId={product.id} />
          <ReviewSection productId={product.id} />
        </>
      )}

      {role === "seller" && (
        <>
          <EditButton productId={product.id} />
          <StockManagement productId={product.id} />
        </>
      )}

      {role === "admin" && (
        <>
          <DeleteButton productId={product.id} />
          <AuditLog productId={product.id} />
        </>
      )}
    </div>
  )
}
```

**問題点：**
- 購入者向け機能修正が出品者機能に影響する可能性
- 条件分岐が散乱し、コードが複雑
- テストが困難（全ロールのパターンをテストする必要）

### After: 機能的凝集（ロール別分離）

```tsx
// app/routes/_buyer+/products+/$productId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  return { product: await getProductForBuyer(params.productId) }
}

export default function BuyerProductPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h1>{loaderData.product.name}</h1>
      <PurchaseButton productId={loaderData.product.id} />
      <ReviewSection productId={loaderData.product.id} />
    </div>
  )
}

// app/routes/_seller+/products+/$productId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  return { product: await getProductForSeller(params.productId) }
}

export default function SellerProductPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h1>{loaderData.product.name}</h1>
      <EditButton productId={loaderData.product.id} />
      <StockManagement productId={loaderData.product.id} />
    </div>
  )
}

// app/routes/_admin+/products+/$productId+/route.tsx
export async function loader({ params }: Route.LoaderArgs) {
  return { product: await getProductForAdmin(params.productId) }
}

export default function AdminProductPage({ loaderData }: Route.ComponentProps) {
  return (
    <div>
      <h1>{loaderData.product.name}</h1>
      <DeleteButton productId={loaderData.product.id} />
      <AuditLog productId={loaderData.product.id} />
    </div>
  )
}
```

**改善点：**
- 各ロールの機能が完全に分離
- 条件分岐がゼロ
- 変更の影響範囲が明確
- テストが容易（各ロール独立してテスト可能）

## アンチパターンと解決策

### アンチパターン1: 神ルート（God Route）

一つのルートファイルに全ての機能を詰め込む。

```tsx
// app/routes/dashboard+/route.tsx (1000行以上)
export async function loader() {
  // 20個以上のデータソースから取得
  const [users, products, orders, analytics, ...] = await Promise.all([...])
  return { users, products, orders, analytics, ... }
}

export async function action() {
  // 10個以上のアクションを処理
  switch (action) {
    case "update-user": ...
    case "delete-product": ...
    // ...
  }
}

export default function Dashboard() {
  // 複雑なコンポーネントロジック
}
```

**解決策：** ネストルートで責務を分割する。

```
app/routes/dashboard+/
├── route.tsx                  # レイアウトのみ
├── index.tsx                  # 概要表示
├── users+/route.tsx           # ユーザー管理
├── products+/route.tsx        # 商品管理
└── analytics+/route.tsx       # 分析
```

### アンチパターン2: 早すぎる共通化

2つのルートで似たコードがあるからといって、すぐに共通化する。

```tsx
// app/components/user-list.tsx
export function UserList({ mode }: { mode: "admin" | "buyer" }) {
  if (mode === "admin") {
    // 管理者向けロジック
  } else {
    // 購入者向けロジック
  }
}
```

**解決策：** 3回使われるまで待つ。

```tsx
// app/routes/_admin+/users+/route.tsx
export default function AdminUserList() {
  // 管理者向けロジックのみ
}

// app/routes/_buyer+/users+/route.tsx
export default function BuyerUserList() {
  // 購入者向けロジックのみ
}
```

### アンチパターン3: 条件分岐の連鎖

型安全性がなく、新しいケース追加時に漏れが発生しやすい。

```tsx
function NotificationItem({ notification }: { notification: any }) {
  if (notification.type === "order") {
    return <OrderNotification {...notification} />
  } else if (notification.type === "review") {
    return <ReviewNotification {...notification} />
  } else if (notification.type === "stock") {
    return <StockNotification {...notification} />
  }
  // 新しいタイプ追加時に漏れる可能性
}
```

**解決策：** ts-pattern で型安全に。

```tsx
import { match } from "ts-pattern"

type Notification =
  | { type: "order"; orderId: string }
  | { type: "review"; reviewId: string }
  | { type: "stock"; productId: string }

function NotificationItem({ notification }: { notification: Notification }) {
  return match(notification)
    .with({ type: "order" }, (n) => <OrderNotification orderId={n.orderId} />)
    .with({ type: "review" }, (n) => <ReviewNotification reviewId={n.reviewId} />)
    .with({ type: "stock" }, (n) => <StockNotification productId={n.productId} />)
    .exhaustive()  // 新しいタイプ追加時にコンパイルエラー
}
```

## まとめ

機能的凝集を実現するための原則：

1. **単一責任の原則** - 一つのモジュールは一つのことだけをする
2. **ロール別分離** - 同じリソースでもロールによって責務が異なる場合は分離
3. **作成・編集の分離** - 同じフォームでもルートは分ける
4. **共通化は慎重に** - 3回使われるまで待つ
5. **型安全なパターンマッチング** - 条件分岐より ts-pattern を使う

これらの原則により、「変更の影響範囲が明確で、テストが容易で、長期的に保守しやすい」コードベースを実現できる。
