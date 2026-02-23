# 口パク（リップシンク）完全ガイド

## 概要

音声波形からフレーム単位で口の開閉を判定し、キャラクターの口パクを同期させる。

## 重要な計算式

### 動画フレームと音声の対応

```
動画フレームi（0-indexed）に対応する音声の時間範囲:
  開始時間 = i / video_fps * playback_rate
  終了時間 = (i + 1) / video_fps * playback_rate
```

**例**: 動画FPS=30, playbackRate=1.2の場合
- フレーム0 → 音声 0.00秒 〜 0.04秒
- フレーム1 → 音声 0.04秒 〜 0.08秒
- フレーム30 → 音声 1.20秒 〜 1.24秒

### 正しい実装

```python
def extract_mouth_data_for_video(
    audio: np.ndarray,
    sample_rate: int,
    video_fps: int,
    playback_rate: float,
    threshold: float = 0.015
) -> list[bool]:
    audio_duration = len(audio) / sample_rate
    video_duration = audio_duration / playback_rate
    video_frames = int(video_duration * video_fps)

    abs_audio = np.abs(audio)
    mouth_data = []

    for frame in range(video_frames):
        # 動画フレームに対応する音声の時間範囲
        audio_start_time = frame / video_fps * playback_rate
        audio_end_time = (frame + 1) / video_fps * playback_rate

        # サンプルインデックスに変換
        start_sample = int(audio_start_time * sample_rate)
        end_sample = int(audio_end_time * sample_rate)

        chunk = abs_audio[start_sample:min(end_sample, len(abs_audio))]
        if len(chunk) > 0:
            rms = np.sqrt(np.mean(chunk ** 2))
            mouth_data.append(bool(rms > threshold))
        else:
            mouth_data.append(False)

    return mouth_data
```

## よくある間違い

### 間違い1: 音声FPSでサンプリング

```python
# NG: 音声のタイミングでサンプリング
mouth_fps = 30 * 1.2  # 36FPS
samples_per_frame = sample_rate // mouth_fps
for i in range(0, len(audio), samples_per_frame):
    chunk = audio[i:i + samples_per_frame]
    # ...
```

**問題**: 動画フレームとのマッピングがずれる
- 動画フレーム0〜179でmouthData[0〜179]を参照
- 音声の0〜4.97秒分のデータしか使わない（7.2秒中）

### 間違い2: frameInLineの計算ミス

```typescript
// Main.tsx
const frameInLine = frame - accumulatedFrames;
// Character.tsxで使用
const mouthOpen = mouthData[frameInLine] ?? false;
```

**確認ポイント**:
- `frameInLine`は0から始まるインデックス
- `mouthData.length`は`durationInFrames`と一致すべき

## 閾値の調整

| 閾値 | 効果 |
|------|------|
| 0.01 | 口パク多い（小さな音でも反応） |
| 0.015 | 推奨（自然な口パク） |
| 0.02 | 口パク少なめ |
| 0.03 | 口パク少ない（大きな音のみ反応） |

### 調整方法

```python
# 閾値を動的に調整する場合
def calculate_adaptive_threshold(audio):
    """音声の平均音量に基づいて閾値を計算"""
    rms_values = []
    chunk_size = 1600  # 100ms @ 16kHz
    for i in range(0, len(audio), chunk_size):
        chunk = audio[i:i + chunk_size]
        if len(chunk) > 0:
            rms = np.sqrt(np.mean(chunk ** 2))
            rms_values.append(rms)

    mean_rms = np.mean(rms_values)
    return mean_rms * 0.5  # 平均の50%を閾値に
```

## TypeScriptでの使用

### Character.tsx

```typescript
interface CharacterProps {
  characterId: CharacterId;
  isSpeaking: boolean;
  mouthData?: boolean[];  // 各フレームで口を開けるか
  frameInLine?: number;   // セリフ内での現在フレーム
}

const mouthOpen = isSpeaking
  ? mouthData.length > 0
    ? mouthData[frameInLine] ?? false
    : Math.floor(frame / 5) % 2 === 0  // フォールバック
  : false;
```

### Main.tsx

```typescript
// 現在のセリフ内フレーム位置を計算
let frameInLine = 0;
for (const line of scriptData) {
  const lineEndFrame = accumulatedFrames + line.durationInFrames + line.pauseAfter;
  if (frame >= accumulatedFrames && frame < lineEndFrame) {
    frameInLine = frame - accumulatedFrames;
    break;
  }
  accumulatedFrames = lineEndFrame;
}

// 口パクデータを取得
const currentMouthData = currentLine
  ? MOUTH_DATA[currentLine.voiceFile] ?? []
  : [];
```

## デバッグ方法

### 口パクデータの確認

```python
# mouth-data.jsonを読み込んで確認
import json

with open("public/voices/mouth-data.json") as f:
    data = json.load(f)

for file, mouth_data in data.items():
    open_count = sum(mouth_data)
    total = len(mouth_data)
    ratio = open_count / total if total > 0 else 0
    print(f"{file}: {open_count}/{total} ({ratio:.1%})")
```

### 期待される結果

- 口を開けている割合: 40-70%が自然
- 20%未満: 閾値が高すぎる
- 80%以上: 閾値が低すぎる

## チェックリスト

- [ ] `extract_mouth_data_for_video`で動画フレームベースで計算
- [ ] 閾値は0.015前後（調整可能）
- [ ] `mouthData.length`が`durationInFrames`と一致
- [ ] `frameInLine`が0から始まるインデックス
- [ ] 口パク割合が40-70%程度
