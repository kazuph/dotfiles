---
name: remotion-twitter-post
description: Remotionで動画を作成し、X(Twitter)に投稿する完全ワークフロー。プロジェクト作成→レンダリング→Chrome拡張でX投稿までを自動化。動画投稿時やRemotionプロジェクト作成時に使用。
metadata:
  tags: remotion, twitter, x, video, social-media, chrome-extension
---

# Remotion → X(Twitter) 投稿ワークフロー

## When to use

- Remotionで動画を作成してX(Twitter)に投稿したい時
- 教育系・解説系の動画をプログラマブルに作成したい時
- テキスト+図形アニメーションで動画を作りたい時

## Twitter動画制限（重要！）

| 項目 | 無料アカウント | Premium |
|------|---------------|---------|
| 長さ | **最大140秒** | 最大60分 |
| サイズ | 最大512MB | 最大8GB |
| 形式 | MP4 (H.264) | MP4 (H.264) |
| 解像度 | 1920x1080推奨 | 1920x1080推奨 |

**推奨設定（無料アカウント向け）:**
- **60秒以内** のダイジェスト版を作成
- 30fps、1920x1080
- H.264コーデック

## Quick Start（最速パス）

### 1. プロジェクト作成

```bash
cd /tmp && mkdir my-video && cd my-video
npm init -y
npm install remotion @remotion/cli react react-dom
```

### 2. 最小構成ファイル作成

**src/index.ts:**
```typescript
import { registerRoot } from "remotion";
import { RemotionRoot } from "./Root";
registerRoot(RemotionRoot);
```

**src/Root.tsx:**
```tsx
import { Composition } from "remotion";
import { MyVideo } from "./MyVideo";

export const RemotionRoot: React.FC = () => (
  <Composition
    id="MyVideo"
    component={MyVideo}
    durationInFrames={1800} // 60秒 at 30fps
    fps={30}
    width={1920}
    height={1080}
  />
);
```

**src/MyVideo.tsx:**
```tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";

export const MyVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ backgroundColor: "#0a0a1a", justifyContent: "center", alignItems: "center" }}>
      <div style={{ color: "#fff", fontSize: 80, opacity }}>Hello World</div>
    </AbsoluteFill>
  );
};
```

### 3. レンダリング

```bash
mkdir -p out
npx remotion render src/index.ts MyVideo out/video.mp4 --codec h264
```

### 4. X投稿（Chrome拡張使用）

```
1. ToolSearch: select:mcp__claude-in-chrome__tabs_context_mcp
2. tabs_context_mcp で現在のタブ取得
3. navigate で https://x.com/home へ移動
4. read_page (filter: interactive) でフォーム要素取得
5. computer (left_click, ref: textbox要素) でフォーカス
6. computer (type) でテキスト入力
7. クリップボードに動画/画像をコピー:
   osascript -e 'set the clipboard to (read (POSIX file "/path/to/file.mp4") as «class furl»)'
   または画像: osascript -e 'set the clipboard to (read (POSIX file "/path/to/image.png") as «class PNGf»)'
8. computer (key: cmd+v) でペースト
9. screenshot で確認
```

## アニメーション基本パターン

### フェードイン
```tsx
const frame = useCurrentFrame();
const { fps } = useVideoConfig();
const opacity = interpolate(frame, [0, fps], [0, 1], { extrapolateRight: "clamp" });
```

### スプリングアニメーション
```tsx
import { spring } from "remotion";
const scale = spring({ frame, fps, config: { damping: 15 } });
```

### シーケンス（シーン切り替え）
```tsx
import { Sequence } from "remotion";
<Sequence from={0} durationInFrames={150}>
  <Scene1 />
</Sequence>
<Sequence from={150} durationInFrames={150}>
  <Scene2 />
</Sequence>
```

## 禁止事項

- ❌ CSSトランジション/アニメーション（レンダリングされない）
- ❌ Tailwindのアニメーションクラス
- ❌ setInterval/setTimeout
- ❌ Math.random()（フレームごとに変わってしまう）

## Chrome拡張操作の詳細手順

### ツール読み込み順序
```
1. ToolSearch: select:mcp__claude-in-chrome__tabs_context_mcp
2. ToolSearch: select:mcp__claude-in-chrome__navigate
3. ToolSearch: select:mcp__claude-in-chrome__read_page
4. ToolSearch: select:mcp__claude-in-chrome__computer
```

### X投稿フォーム操作
```
# タブ情報取得
tabs_context_mcp(createIfEmpty: true)

# Xホームへ移動
navigate(url: "https://x.com/home", tabId: <取得したtabId>)

# インタラクティブ要素取得
read_page(tabId: <tabId>, filter: "interactive", depth: 10)

# textbox "ポスト本文" の ref を探す（例: ref_27）

# クリックしてフォーカス
computer(action: "left_click", tabId: <tabId>, ref: "ref_XX")

# テキスト入力
computer(action: "type", tabId: <tabId>, text: "投稿内容")

# 画像/動画ペースト（事前にクリップボードにコピー）
computer(action: "key", tabId: <tabId>, text: "cmd+v")

# 確認スクショ
computer(action: "screenshot", tabId: <tabId>)
```

## トラブルシューティング

### レンダリングが遅い
- フレーム数を減らす（60秒 = 1800フレーム推奨）
- 複雑なコンポーネントを簡素化

### X投稿フォームがDIV要素
- form_input ではなく computer(left_click) → computer(type) を使用

### 動画がTwitterにアップできない
- 140秒以内か確認
- H.264コーデックでエンコードされているか確認
- ファイルサイズが512MB以内か確認
