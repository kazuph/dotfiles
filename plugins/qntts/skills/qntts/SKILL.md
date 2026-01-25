---
name: qntts
description: Qwen3-TTS (VoiceDesign mode) をMac MLXで効率的に実行するためのガイド。パラメータ最適化、RTFチューニング、Web UI構築、Remotion連携に使用
---

# Qwen3-TTS MLX ガイド

Mac M2+（MLX）でQwen3-TTS VoiceDesignモードを効率的に実行するためのベストプラクティス。

## 最重要ポイント

**警告**: デフォルト `max_tokens=4096` は **327秒の音声** を生成してしまう！

**推奨設定**:
```python
max_tokens=150  # 約12秒の音声
```

## RTF（Real-Time Factor）早見表

| 意味 | RTF値 | ステータス |
|------|------|----------|
| リアルタイムより速い | < 1 | 配信可能 |
| 等速 | = 1 | ギリギリ可能 |
| リアルタイムより遅い | > 1 | 事前生成向け |

**計算式**: `RTF = 生成時間 ÷ 音声の長さ`

### 環境別パフォーマンス

| 環境 | 設定 | RTF | リアルタイム |
|------|-----|-----|------------|
| **Mac M2 MLX** | max_tokens=150 | **0.955** | ほぼ可能 |
| Mac M2 MLX | max_tokens=4096 | 7.0 | 不可 |
| RTX 3090 | バッチ3 | 0.63 | 可能 |
| RTX 3090 | バッチ1 | 1.9 | 不可 |

## クイックスタート

### インストール

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install mlx-audio soundfile
```

### 最小コード（安定版）

```python
from mlx_audio.tts import load

model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')

result = next(model.generate_voice_design(
    text="こんにちは、私はクエンTTSです。",
    instruct="明るく元気な若い女性の声",
    language="Japanese",
    max_tokens=150,           # 重要: 約12秒
    temperature=0.65,         # 安定性向上
    repetition_penalty=1.15,  # 繰り返し防止
    top_k=35,
    top_p=0.92,
))

# result.audio: 音声データ (numpy array)
# result.sample_rate: 24000Hz
```

### 音声ファイル保存

```python
import soundfile as sf
sf.write("output.wav", result.audio, result.sample_rate)
```

## max_tokens と音声長

**計算式**: `音声長（秒）≈ max_tokens / 12.5`

| max_tokens | 想定音声長 | 用途 |
|------------|----------|------|
| 50 | ~4秒 | 短い挨拶 |
| 100 | ~8秒 | ショートフレーズ |
| **150** | **~12秒** | **標準（推奨）** |
| 200 | ~16秒 | 長めの説明 |
| 500 | ~40秒 | ナレーション |
| 2000 | ~160秒 | 長文読み上げ |
| 4096 | ~327秒 | 使用非推奨 |

## パラメータリファレンス

詳細は [PARAMETERS.md](PARAMETERS.md) を参照。

| パラメータ | デフォルト | 推奨 | 効果 |
|-----------|-----------|------|------|
| max_tokens | 4096 | 150 | 音声長制御 |
| temperature | 0.9 | 0.65 | 安定性向上 |
| repetition_penalty | 1.05 | 1.15 | 繰り返し防止 |
| top_k | 50 | 35 | 選択肢制限 |
| top_p | 1.0 | 0.92 | 確率カットオフ |

## 声質プリセット例

VoiceDesignモードは `instruct` パラメータでテキスト指定：

```python
# 女性声
"落ち着いた女性の声"
"明るく元気な若い女性の声"
"優しく穏やかな女性の声"
"知的でクールな女性の声"

# 男性声
"落ち着いた男性の声"
"明るく元気な若い男性の声"
"低く渋い男性の声"
"穏やかで優しい男性の声"
```

**注意**: `instruct` で「早口」「ゆっくり」を指定しても話速は変わらない。再生速度で調整。

## Web UI

ブラウザでパラメータ調整できるWeb UIの構築方法は [WEB-UI.md](WEB-UI.md) を参照。

### 主な機能
- スライダーでリアルタイムパラメータ調整
- 声質プリセット（8種類）
- キューベース処理（複数リクエスト対応）
- 再生速度調整（0.5x〜2x）
- 履歴保存・永続化

## Remotion連携

動画制作ワークフローは [REMOTION.md](REMOTION.md) を参照。

### 実測時間（Mac M2）

| フェーズ | 時間 |
|---------|------|
| モデルロード | 3.65秒 |
| 音声生成 (3ファイル) | 22.31秒 |
| 動画レンダリング (3動画) | ~30秒 |
| **合計** | **約70秒** |

## トラブルシューティング

### 音声が長すぎる
→ `max_tokens` を下げる（150推奨）

### 繰り返しが発生する
→ `repetition_penalty` を1.15以上に

### 声質が安定しない
→ `temperature` を0.65以下に

### 話速を変えたい
→ `instruct` では変わらない。再生時に `audio.playbackRate` で調整

## 関連ドキュメント

- [PARAMETERS.md](PARAMETERS.md) - パラメータ詳細リファレンス
- [WEB-UI.md](WEB-UI.md) - FastAPI + HTML Web UI構築
- [REMOTION.md](REMOTION.md) - Remotion動画制作連携
- [EXAMPLES.md](EXAMPLES.md) - コード例集

## 外部リソース

- [Qwen3-TTS 公式](https://github.com/QwenLM/Qwen3-TTS)
- [mlx-audio](https://github.com/Blaizzy/mlx-audio)
- [MLX Community Model](https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit)
