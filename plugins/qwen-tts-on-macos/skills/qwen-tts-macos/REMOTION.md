# Remotion連携ガイド

Qwen3-TTSとRemotionを組み合わせた動画制作ワークフロー。

## 概要

```
[テキスト] → [Qwen3-TTS] → [WAVファイル] → [Remotion] → [MP4動画]
```

## プロジェクト構成

```
project/
├── remotion-videos/
│   ├── public/
│   │   ├── audio1.wav
│   │   ├── audio2.wav
│   │   └── audio3.wav
│   ├── src/
│   │   ├── Composition.tsx
│   │   ├── Root.tsx
│   │   └── components/
│   │       └── TalkingCharacter.tsx
│   ├── out/
│   │   └── *.mp4
│   ├── package.json
│   └── remotion.config.ts
└── scripts/
    └── generate_audio.py
```

## 音声生成スクリプト

### generate_audio.py

```python
#!/usr/bin/env python3
"""Remotion用音声一括生成"""

import time
from pathlib import Path
import soundfile as sf
from mlx_audio.tts import load

# 設定
OUTPUT_DIR = Path("remotion-videos/public")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 生成する音声データ
VOICES = [
    {
        "filename": "intro.wav",
        "text": "こんにちは！今日は素晴らしい天気ですね。",
        "instruct": "明るく元気な若い女性の声",
    },
    {
        "filename": "main.wav",
        "text": "それでは、本日のトピックについて説明していきます。",
        "instruct": "落ち着いた男性の声",
    },
    {
        "filename": "outro.wav",
        "text": "ご視聴ありがとうございました。また次回お会いしましょう！",
        "instruct": "優しく穏やかな女性の声",
    },
]

# モデルロード
print("Loading Qwen3-TTS model...")
start = time.time()
model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')
print(f"Model loaded in {time.time() - start:.2f}s")

# 音声生成
for voice in VOICES:
    print(f"Generating {voice['filename']}...")
    gen_start = time.time()

    result = next(model.generate_voice_design(
        text=voice["text"],
        instruct=voice["instruct"],
        language="Japanese",
        max_tokens=150,
        temperature=0.65,
        repetition_penalty=1.15,
        top_k=35,
        top_p=0.92,
    ))

    duration = len(result.audio) / result.sample_rate
    gen_time = time.time() - gen_start
    rtf = gen_time / duration

    output_path = OUTPUT_DIR / voice["filename"]
    sf.write(str(output_path), result.audio, result.sample_rate)

    print(f"  Duration: {duration:.2f}s, Gen time: {gen_time:.2f}s, RTF: {rtf:.3f}")

print(f"\nTotal time: {time.time() - start:.2f}s")
```

## Remotion設定

### package.json

```json
{
  "name": "tts-videos",
  "scripts": {
    "start": "remotion studio",
    "render": "remotion render src/Root.tsx Composition out/video.mp4",
    "render:all": "node scripts/render-all.js"
  },
  "dependencies": {
    "@remotion/player": "^4.0.0",
    "react": "^18.0.0",
    "remotion": "^4.0.0"
  }
}
```

### remotion.config.ts

```typescript
import { Config } from '@remotion/cli/config';

Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
Config.setConcurrency(1);
```

### src/Root.tsx

```tsx
import { Composition } from 'remotion';
import { TalkingVideo } from './Composition';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="TalkingVideo"
        component={TalkingVideo}
        durationInFrames={300}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{
          audioFile: 'intro.wav',
        }}
      />
    </>
  );
};
```

### src/Composition.tsx

```tsx
import { Audio, useCurrentFrame, useVideoConfig, staticFile } from 'remotion';

interface Props {
  audioFile: string;
}

export const TalkingVideo: React.FC<Props> = ({ audioFile }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{
      flex: 1,
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <Audio src={staticFile(audioFile)} />

      {/* キャラクターやテキスト表示 */}
      <div style={{ color: 'white', fontSize: 48 }}>
        Speaking...
      </div>
    </div>
  );
};
```

## 実行ワークフロー

### 1. 音声生成

```bash
source .venv/bin/activate
python scripts/generate_audio.py
```

出力:
```
Loading Qwen3-TTS model...
Model loaded in 3.65s
Generating intro.wav...
  Duration: 5.32s, Gen time: 6.21s, RTF: 1.167
Generating main.wav...
  Duration: 8.45s, Gen time: 9.12s, RTF: 1.079
Generating outro.wav...
  Duration: 6.78s, Gen time: 7.34s, RTF: 1.083

Total time: 26.32s
```

### 2. 動画レンダリング

```bash
cd remotion-videos
npm run render
```

### 3. 一括レンダリング

```bash
npm run render:all
```

## 実測パフォーマンス（Mac M2）

| フェーズ | 時間 |
|---------|------|
| モデルロード | 3.65秒 |
| 音声3ファイル生成 | 22.31秒 |
| Remotion初回ビルド | ~15秒 |
| 動画3本レンダリング | ~30秒 |
| **合計** | **約70秒** |

## Tips

### 音声長からフレーム数計算

```typescript
import { getAudioDurationInSeconds } from '@remotion/media-utils';

const duration = await getAudioDurationInSeconds(staticFile('audio.wav'));
const frames = Math.ceil(duration * fps);
```

### 口パク同期

```tsx
import { interpolate, useCurrentFrame } from 'remotion';

const mouthOpen = interpolate(
  frame % 10,
  [0, 5, 10],
  [0, 1, 0],
  { extrapolateRight: 'clamp' }
);
```

### 字幕表示

```tsx
const subtitles = [
  { start: 0, end: 3, text: 'こんにちは！' },
  { start: 3, end: 6, text: '今日は素晴らしい天気ですね。' },
];

const currentSubtitle = subtitles.find(
  s => frame >= s.start * fps && frame < s.end * fps
);
```

## トラブルシューティング

### 音声が見つからない

→ `public/` ディレクトリにWAVファイルがあるか確認

### レンダリングが遅い

→ `Config.setConcurrency(1)` で並列数を制限（メモリ節約）

### 音声と映像がずれる

→ フレームレートとサンプルレートの計算を確認
