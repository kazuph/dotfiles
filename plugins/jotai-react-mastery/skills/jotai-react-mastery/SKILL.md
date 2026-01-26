---
name: jotai-react-mastery
description: JotaiとReact Suspense/Transitionを組み合わせたモダンな状態管理・非同期処理のベストプラクティス集。uhyo氏の「jotaiによるReact再入門」に基づく。
allowed-tools:
  - Shell
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Jotai React Mastery Skill

## 概要
Jotaiを用いたReactアプリケーション設計、特にSuspense、Concurrent features（Transition）、非同期処理、エラーハンドリングに関するベストプラクティスを提供するスキルです。
「jotaiによるReact再入門」の内容をベースに、宣言的UIの原則に従った実装パターンを提示します。

## 利用シーン
- Jotaiを用いた状態管理の設計時
- React Suspenseを利用した非同期データ取得の実装時
- `useTransition` を用いたUX改善（ちらつき防止、ペンディング表示）
- 非同期処理のエラーハンドリングとリトライ機構の実装
- `jotai-eager` を用いたパフォーマンス最適化

## ベストプラクティス & パターン

### 1. Jotaiの基本原則
- **定義と利用の分離**: `atom`でステートを定義し、`useAtom`で利用する。`useState`の役割を分割・拡張する。
- **派生atomによるカプセル化**: 生のatom（Primitive Atom）を隠蔽し、読み取り専用またはアクション用（書き込み専用）の派生atom（Derived Atom）のみを公開することで、意図しないステート変更を防ぐ。
- **最小限のAPI**: 複雑な操作はカスタムフックではなく、書き込み可能な派生atom（Action Atom）として実装する。引数を取る書き込み関数を活用する。

### 2. Suspenseと非同期処理 (Render-as-You-Fetch)
Suspenseを正しく動作させるため、Promiseはコンポーネント内（useEffectやuseMemo内）ではなく、**コンポーネントの外（Atom）**で管理する。

#### 基本パターン
```ts
// コンポーネント外でPromiseを保持する
const userAtom = atom(async () => {
  const user = await fetchUser();
  return user;
});

// コンポーネント内
const UserProfile = () => {
  // atomの値がPromiseの場合、解決するまで自動的にサスペンドする
  const user = useAtomValue(userAtom); 
  return <div>{user.name}</div>;
};
```

#### パラメータ付きクエリ
IDごとのデータ取得には以下の2パターンを使い分ける。

1. **パラメータ依存atom**（単一のパラメータのみ扱う場合）
   ```ts
   const userIdAtom = atom<string | null>(null);
   const userAtom = atom(async (get) => {
     const id = get(userIdAtom);
     if (!id) return null;
     return fetchUser(id);
   });
   ```

2. **Atom Family**（複数のパラメータを同時に扱う、キャッシュが必要な場合）
   ```ts
   import { atomFamily } from 'jotai/utils';

   const userAtomFamily = atomFamily((id: string) =>
     atom(async () => fetchUser(id))
   );

   const UserProfile = ({ id }) => {
     const user = useAtomValue(userAtomFamily(id));
     // ...
   };
   ```

### 3. 再読み込みとUIバージョニング
データの再取得（Refetch）は「手続き的な再実行」ではなく、「UIバージョン（キー）の更新によるステートの再評価」として実装する。これは「データ取得もUIの計算の一部」という宣言的UIの思想に基づく。

#### createReloadableAtom パターン
```ts
import { atom, type Getter } from "jotai";

function createReloadableAtom<T>(getter: (get: Getter) => T) {
  const refetchKeyAtom = atom(0);
  return atom(
    (get) => {
      get(refetchKeyAtom); // 依存を作成
      return getter(get);
    },
    (get, set) => {
      // バージョンを更新して再評価をトリガー
      set(refetchKeyAtom, (c) => c + 1);
    }
  );
}

// 使用例
const userListAtom = createReloadableAtom(async () => fetchUsers());

// コンポーネント内での使用
const UserList = () => {
  const users = useAtomValue(userListAtom);
  const reload = useSetAtom(userListAtom); // 実行すると再取得
  // ...
};
```

### 4. トランジション (Transitions)
Suspenseによるフォールバック表示（ローディング）のちらつきを防ぎ、「古いUI」を維持しつつ裏で読み込む。

- **`useTransition` / `startTransition`**: ステート更新をラップして「優先度の低い更新」とする。
- **2つの世界の並存**: トランジション中は「新しいステートの世界（裏でレンダリング中）」と「古いステートの世界（表示中）」が同時に存在する。
- **ペンディング状態**: `isPending` を利用して、古いUIが表示されている間に「読み込み中...」などのフィードバックを即座に返す。

```ts
const [isPending, startTransition] = useTransition();

const handleChange = (nextId) => {
  startTransition(() => {
    setUserId(nextId); // この更新によるサスペンドはフォールバックを表示せず、古いUIを維持する
  });
};

// UI側: isPendingを用いて応答性を確保
<div style={{ opacity: isPending ? 0.5 : 1 }}>
  <Suspense fallback={<Spinner />}>
    <UserProfile id={userId} />
  </Suspense>
</div>
```

#### 注意点
- **制御コンポーネント**: inputのonChangeなど、即座にDOMに反映させる必要がある更新はトランジションにしてはいけない。
- **オプトアウト**: 古いUIを維持したくない場合（画面遷移など）は、`Suspense` に `key` を与えるか、条件付きレンダリングで新しい `Suspense` インスタンスを生成することで、強制的にフォールバックを表示させる。

### 5. パフォーマンス最適化 (jotai-eager)
初期ロード時は非同期（Promise）だが、キャッシュがある場合は同期的に値を返したい場合に `jotai-eager` を使用する。無駄なサスペンド（一瞬のLoading表示）を防ぐ。

```ts
import { eagerAtom } from 'jotai-eager';

// 内部状態がnull（初期状態）のときだけ非同期、それ以外は同期
const valueAtom = eagerAtom((get) => {
  const internalVal = get(internalAtom);
  if (internalVal !== null) {
    return internalVal; // 同期的に返す
  }
  // 非同期読み込み
  const data = get(asyncDataAtom); 
  return data; // Promiseになる可能性がある
});
```
`eagerAtom` は、`get`でPromiseを取得したときのみ自身もPromiseを返し、それ以外は値をそのまま返す（同期）。

### 6. エラーハンドリング (Error Boundary)
非同期atomのPromiseがrejectされた場合、コンポーネントでエラーがスローされる。

- **Error Boundary**: サスペンドと同様、エラー境界を設けて捕捉する。`react-error-boundary` の利用を推奨。
- **リトライの実装**: Error Boundaryのリセット (`resetErrorBoundary`) と、Atomの再読み込み (`reloadAtom`) をトランジション内で同時に行う。

#### リトライ実装例
```tsx
const UserListErrorFallback = ({ error, resetErrorBoundary }) => {
  const reloadUserList = useSetAtom(userListAtom); // createReloadableAtomで作成したもの
  
  const handleRetry = () => {
    startTransition(() => {
      resetErrorBoundary(); // Error Boundaryの状態リセット
      reloadUserList();    // Atomの再評価トリガー
    });
  };

  return (
    <div>
      <p>Error: {error.message}</p>
      <button onClick={handleRetry}>Retry</button>
    </div>
  );
};
```

### 7. 参考リソース
- 書籍: [jotaiによるReact再入門](https://zenn.dev/uhyo/books/learn-react-with-jotai)
- 公式: [Jotai Docs](https://jotai.org/)
