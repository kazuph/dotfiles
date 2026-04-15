# Qwen3-TTS コード例集

## 基本的な使い方

### 最小コード

```python
from mlx_audio.tts import load

model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')

result = next(model.generate_voice_design(
    text="こんにちは",
    instruct="落ち着いた女性の声",
    language="Japanese",
    max_tokens=150,
))

# result.audio: numpy array
# result.sample_rate: 24000
```

### 音声ファイル保存

```python
import soundfile as sf

sf.write("output.wav", result.audio, result.sample_rate)
```

### MP3変換

```python
import subprocess
import tempfile
import soundfile as sf

# まずWAVで保存
with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
    wav_path = f.name
    sf.write(wav_path, result.audio, result.sample_rate)

# ffmpegでMP3変換
mp3_path = "output.mp3"
subprocess.run([
    "ffmpeg", "-y", "-i", wav_path,
    "-codec:a", "libmp3lame", "-qscale:a", "2",
    mp3_path
])
```

## 安定した生成設定

### 推奨パラメータ

```python
result = next(model.generate_voice_design(
    text="テキスト",
    instruct="声質の説明",
    language="Japanese",
    max_tokens=150,           # 約12秒
    temperature=0.65,         # 安定性重視
    repetition_penalty=1.15,  # 繰り返し防止
    top_k=35,                 # 選択肢制限
    top_p=0.92,               # 確率カットオフ
))
```

### 長文用設定

```python
# 40秒程度の音声を生成
result = next(model.generate_voice_design(
    text="長いテキスト...",
    instruct="落ち着いた女性の声",
    language="Japanese",
    max_tokens=500,           # 約40秒
    temperature=0.65,
    repetition_penalty=1.15,
    top_k=35,
    top_p=0.92,
))
```

## 声質バリエーション

### 女性声

```python
# 落ち着いた女性
next(model.generate_voice_design(
    text="本日のニュースをお伝えします。",
    instruct="落ち着いた女性の声",
    language="Japanese",
    max_tokens=150,
))

# 明るい若い女性
next(model.generate_voice_design(
    text="やったー！今日は楽しいね！",
    instruct="明るく元気な若い女性の声",
    language="Japanese",
    max_tokens=150,
))

# 優しい女性
next(model.generate_voice_design(
    text="大丈夫ですよ、ゆっくり休んでくださいね。",
    instruct="優しく穏やかな女性の声",
    language="Japanese",
    max_tokens=150,
))

# クールな女性
next(model.generate_voice_design(
    text="報告書は明日までに提出してください。",
    instruct="知的でクールな女性の声",
    language="Japanese",
    max_tokens=150,
))
```

### 男性声

```python
# 落ち着いた男性
next(model.generate_voice_design(
    text="それでは、説明を始めます。",
    instruct="落ち着いた男性の声",
    language="Japanese",
    max_tokens=150,
))

# 明るい若い男性
next(model.generate_voice_design(
    text="よろしくお願いします！頑張ります！",
    instruct="明るく元気な若い男性の声",
    language="Japanese",
    max_tokens=150,
))

# 渋い男性
next(model.generate_voice_design(
    text="この件については、慎重に検討する必要がある。",
    instruct="低く渋い男性の声",
    language="Japanese",
    max_tokens=150,
))

# 優しい男性
next(model.generate_voice_design(
    text="困ったことがあれば、いつでも相談してください。",
    instruct="穏やかで優しい男性の声",
    language="Japanese",
    max_tokens=150,
))
```

## バッチ処理

### 複数テキストを順次生成

```python
from pathlib import Path
import soundfile as sf

texts = [
    {"id": "intro", "text": "こんにちは", "instruct": "明るい女性の声"},
    {"id": "main", "text": "本題に入ります", "instruct": "落ち着いた男性の声"},
    {"id": "outro", "text": "ありがとうございました", "instruct": "優しい女性の声"},
]

output_dir = Path("outputs")
output_dir.mkdir(exist_ok=True)

for item in texts:
    result = next(model.generate_voice_design(
        text=item["text"],
        instruct=item["instruct"],
        language="Japanese",
        max_tokens=150,
        temperature=0.65,
        repetition_penalty=1.15,
        top_k=35,
        top_p=0.92,
    ))

    output_path = output_dir / f"{item['id']}.wav"
    sf.write(str(output_path), result.audio, result.sample_rate)
    print(f"Generated: {output_path}")
```

## パフォーマンス計測

### RTF計測

```python
import time

start = time.time()

result = next(model.generate_voice_design(
    text="パフォーマンステスト用のテキストです。",
    instruct="落ち着いた女性の声",
    language="Japanese",
    max_tokens=150,
))

generation_time = time.time() - start
duration = len(result.audio) / result.sample_rate
rtf = generation_time / duration

print(f"生成時間: {generation_time:.2f}秒")
print(f"音声長: {duration:.2f}秒")
print(f"RTF: {rtf:.3f}")
print(f"リアルタイム: {'可能' if rtf <= 1.0 else '不可'}")
```

### モデルロード時間計測

```python
import time

start = time.time()
model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')
load_time = time.time() - start

print(f"モデルロード時間: {load_time:.2f}秒")
```

## 再生速度調整（再生時）

TTSの話速パラメータはないため、再生時に調整。

### Pythonでの再生速度変更

```python
from scipy import signal
import numpy as np

def change_speed(audio, sample_rate, speed=1.5):
    """再生速度を変更（ピッチも変わる）"""
    new_length = int(len(audio) / speed)
    return signal.resample(audio, new_length)

# 1.5倍速
fast_audio = change_speed(result.audio, result.sample_rate, speed=1.5)
sf.write("fast.wav", fast_audio, result.sample_rate)
```

### ffmpegでの速度変更（ピッチ維持）

```bash
# 1.5倍速（ピッチ維持）
ffmpeg -i input.wav -filter:a "atempo=1.5" output.wav

# 2倍速（ピッチ維持）
ffmpeg -i input.wav -filter:a "atempo=2.0" output.wav

# 0.5倍速（ピッチ維持）
ffmpeg -i input.wav -filter:a "atempo=0.5" output.wav
```

## RTX 3090（CUDA）

### Gradio API経由

```python
from gradio_client import Client

client = Client("http://192.168.1.64:8000")

# 単一生成
result = client.predict(
    text="こんにちは",
    voice_description="明るい女性の声",
    language="Japanese",
    api_name="/generate_voice_design"
)

# バッチ生成（サイズ3推奨）
batch_texts = """テキスト1
テキスト2
テキスト3"""

result = client.predict(
    batch_input=batch_texts,
    voice_description="落ち着いた女性の声",
    language="Japanese",
    api_name="/generate_batch_ui"
)
```

## エラーハンドリング

### 生成失敗時のリトライ

```python
import time

def generate_with_retry(model, text, instruct, max_retries=3):
    for attempt in range(max_retries):
        try:
            result = next(model.generate_voice_design(
                text=text,
                instruct=instruct,
                language="Japanese",
                max_tokens=150,
                temperature=0.65,
                repetition_penalty=1.15,
                top_k=35,
                top_p=0.92,
            ))
            return result
        except Exception as e:
            print(f"Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(1)
            else:
                raise

result = generate_with_retry(model, "テキスト", "声質説明")
```

### 音声長チェック

```python
result = next(model.generate_voice_design(...))

duration = len(result.audio) / result.sample_rate

if duration < 1.0:
    print("警告: 音声が短すぎます。max_tokensを増やしてください。")
elif duration > 60.0:
    print("警告: 音声が長すぎます。max_tokensを減らしてください。")
else:
    print(f"音声長: {duration:.2f}秒 (適切)")
```
