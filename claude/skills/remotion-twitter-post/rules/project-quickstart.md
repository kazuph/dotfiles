---
name: project-quickstart
description: Remotionプロジェクトの最速セットアップ
metadata:
  tags: remotion, setup, quickstart
---

# Remotionプロジェクト クイックスタート

## 手動セットアップ（推奨）

TTY問題を避けるため、手動セットアップを推奨。

### 1. ディレクトリ作成

```bash
cd /tmp && mkdir my-video && cd my-video
```

### 2. 依存関係インストール

```bash
npm init -y
npm install remotion @remotion/cli react react-dom
npm install -D typescript @types/react
```

### 3. ファイル作成

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

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="MyVideo"
      component={MyVideo}
      durationInFrames={1800} // 60秒 at 30fps
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
```

**src/MyVideo.tsx:**
```tsx
import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring, Sequence } from "remotion";

export const MyVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: "clamp" });
  const scale = spring({ frame, fps, config: { damping: 15 } });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: "#0a0a1a",
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <div
        style={{
          color: "#ffffff",
          fontSize: 80,
          fontWeight: "bold",
          opacity,
          transform: `scale(${scale})`,
        }}
      >
        Hello World
      </div>
    </AbsoluteFill>
  );
};
```

**package.json に追加:**
```json
{
  "scripts": {
    "start": "remotion studio",
    "build": "remotion render src/index.ts MyVideo out/video.mp4 --codec h264"
  }
}
```

### 4. プレビュー

```bash
npm start
# → http://localhost:3000 でプレビュー
```

### 5. レンダリング

```bash
mkdir -p out
npm run build
```

## ディレクトリ構造

```
my-video/
├── src/
│   ├── index.ts          # エントリポイント
│   ├── Root.tsx          # Compositionの定義
│   ├── MyVideo.tsx       # メインの動画コンポーネント
│   ├── components/       # 再利用可能なコンポーネント
│   │   ├── AnimatedText.tsx
│   │   └── ...
│   └── scenes/           # シーンごとのコンポーネント
│       ├── IntroScene.tsx
│       └── ...
├── out/                  # 出力先
│   └── video.mp4
├── package.json
└── tsconfig.json
```

## 複数Compositionの例

```tsx
import { Composition } from "remotion";
import { FullVideo } from "./FullVideo";
import { DigestVideo } from "./DigestVideo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* フル版 */}
      <Composition
        id="FullVideo"
        component={FullVideo}
        durationInFrames={8100} // 4分30秒
        fps={30}
        width={1920}
        height={1080}
      />

      {/* Twitter用ダイジェスト版 */}
      <Composition
        id="DigestVideo"
        component={DigestVideo}
        durationInFrames={1800} // 60秒
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
```

## 特定のCompositionをレンダリング

```bash
npx remotion render src/index.ts DigestVideo out/digest.mp4 --codec h264
```
