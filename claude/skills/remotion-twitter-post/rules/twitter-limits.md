---
name: twitter-limits
description: Twitter/X動画投稿の制限と推奨設定
metadata:
  tags: twitter, x, video, limits
---

# Twitter/X 動画投稿制限

## 無料アカウント

| 項目 | 制限値 |
|------|--------|
| 最大長さ | **140秒（2分20秒）** |
| 最大サイズ | 512MB |
| 解像度 | 最大1920x1200 |
| フレームレート | 最大40fps |
| ビットレート | 最大25Mbps |

## Premium アカウント

| 項目 | 制限値 |
|------|--------|
| 最大長さ | 60分 |
| 最大サイズ | 8GB |

## 推奨Remotion設定（無料アカウント向け）

```tsx
<Composition
  id="TwitterVideo"
  component={MyVideo}
  durationInFrames={1800} // 60秒（余裕を持って）
  fps={30}
  width={1920}
  height={1080}
/>
```

## レンダリングコマンド

```bash
npx remotion render src/index.ts MyVideo out/video.mp4 --codec h264
```

## ファイルサイズを小さくするには

```bash
# CRF値を上げる（18-28、大きいほど品質低下・サイズ縮小）
npx remotion render src/index.ts MyVideo out/video.mp4 --codec h264 --crf 23
```
