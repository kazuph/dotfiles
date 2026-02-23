# フレーム計算の完全ガイド

## 基本概念

Remotion + Qwen-TTSでは、音声を1.2倍速で再生することで自然な会話スピードを実現する。この「playbackRate」の扱いを間違えると、以下の問題が発生する：

- 末尾に長い無音（10秒以上）
- セリフが途中で切れる
- 音声と映像がずれる

## 計算式

### 正しい計算（generate-voices-qwen.py）

```python
# 音声の長さ（秒）
duration = len(audio) / sample_rate  # 例: 7.2秒

# 動画上での再生時間
video_time = duration / PLAYBACK_RATE  # 7.2 / 1.2 = 6秒

# フレーム数
frames = int(video_time * FPS)  # 6 * 30 = 180フレーム

# まとめると
frames = int(duration / PLAYBACK_RATE * FPS)
```

### durationInFramesの意味

`script.ts`の`durationInFrames`は「**playbackRate考慮済みの動画フレーム数**」：

```typescript
{
  id: 1,
  durationInFrames: 180,  // 7.2秒の音声を1.2倍速で再生 = 6秒 = 180フレーム
}
```

## よくある間違い

### 間違い1: playbackRate調整忘れ（末尾に無音）

```python
# NG: playbackRateを考慮していない
frames = int(duration * FPS)  # 7.2 * 30 = 216フレーム

# → durationInFrames = 216
# → 実際の再生は180フレームで終わる
# → 36フレーム（1.2秒）の無音が発生
```

### 間違い2: 二重調整（セリフ切れ）

generate-voices-qwen.pyで正しく計算したのに、Main.tsx/Root.tsxでまた調整：

```typescript
// generate-voices-qwen.py: frames = 180（正しい）

// Main.tsx（NG）
const getAdjustedFrames = (frames) => Math.ceil(frames / playbackRate);
// 180 / 1.2 = 150フレーム → セリフが途中で切れる！

// Main.tsx（OK）
const getAdjustedFrames = (frames) => frames;
// 180フレームそのまま使用
```

### 間違い3: Root.tsxとMain.tsxの不整合

```typescript
// Root.tsx
const calculateTotalFrames = () => {
  // NG: playbackRateで割っていない
  total += line.durationInFrames + line.pauseAfter;
  // → 動画の箱が大きすぎて末尾に無音
};

// Main.tsx
const getAdjustedFrames = (frames) => Math.ceil(frames / playbackRate);
// → セリフが切れる

// 結果: 両方の問題が同時に発生
```

## 正しい実装パターン

### パターン1: 音声生成時に調整済み（推奨）

```
┌─ generate-voices-qwen.py ─────────────────────────┐
│ frames = int(duration / PLAYBACK_RATE * FPS)      │
│ → durationInFramesはplaybackRate考慮済み          │
└───────────────────────────────────────────────────┘
         ↓
┌─ script.ts ───────────────────────────────────────┐
│ durationInFrames: 180  // そのまま使用            │
└───────────────────────────────────────────────────┘
         ↓
┌─ Main.tsx / Root.tsx ─────────────────────────────┐
│ そのまま使用！ 二度割りしない！                   │
│ const getAdjustedFrames = (frames) => frames;     │
└───────────────────────────────────────────────────┘
```

### パターン2: 動画側で調整（非推奨）

```
┌─ generate-voices-qwen.py ─────────────────────────┐
│ frames = int(duration * FPS)                      │
│ → durationInFramesは元の音声長ベース              │
└───────────────────────────────────────────────────┘
         ↓
┌─ Main.tsx / Root.tsx ─────────────────────────────┐
│ const getAdjustedFrames = (frames) =>             │
│   Math.ceil(frames / playbackRate);               │
│ → すべての箇所で一貫して調整する必要あり          │
└───────────────────────────────────────────────────┘
```

パターン2は「すべての箇所で一貫して調整」が難しく、ミスしやすい。パターン1を推奨。

## デバッグ方法

### 症状から原因を特定

| 症状 | 原因 | 確認箇所 |
|------|------|----------|
| 末尾に10秒以上の無音 | Root.tsxでplaybackRate未調整 | calculateTotalFrames() |
| 末尾に3-5秒の無音 | pauseAfterまたは余白が大きい | script.ts, Root.tsx |
| セリフが途中で切れる | 二重playbackRate調整 | Main.tsx getAdjustedFrames |
| 音声と映像がずれる | 計算式の間違い | generate-voices-qwen.py |

### 計算の検証

```python
# 検証用スクリプト
duration = 7.2  # 音声長（秒）
playback_rate = 1.2
fps = 30

# 正しい計算
video_time = duration / playback_rate  # 6秒
frames = int(video_time * fps)  # 180フレーム

print(f"音声長: {duration}秒")
print(f"動画上の再生時間: {video_time}秒")
print(f"フレーム数: {frames}")

# 実際のdurationInFramesと比較
actual_frames = 180  # script.tsから
if frames == actual_frames:
    print("✅ 計算が一致")
else:
    print(f"❌ 不一致: 期待値{frames} != 実際{actual_frames}")
```

## pauseAfterについて

`pauseAfter`は「セリフ後の間」をフレーム数で指定：

```typescript
{
  durationInFrames: 180,  // 6秒の音声
  pauseAfter: 15,         // 0.5秒の間（15フレーム）
}
```

### 注意点

- `pauseAfter`は動画上のフレーム数
- playbackRateの影響を受けない（音声ではないため）
- 大きすぎると無音区間が目立つ

### 推奨値

| 場面 | pauseAfter |
|------|------------|
| 通常の会話 | 10-15 |
| 文の区切り | 15-20 |
| シーン転換 | 20-30 |
| 最後のセリフ | 5-10 |
