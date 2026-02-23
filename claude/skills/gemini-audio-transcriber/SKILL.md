---
name: gemini-audio-transcriber
description: Gemini 2.0 Flash APIを使用して音声ファイル（m4a, mp3, wav等）を日本語で文字起こしするスキル。講義録音や音声メモの書き起こしに使用。
---

# スキルの目的
- Gemini 2.0 Flash APIで音声ファイルを文字起こし
- 日本語音声の高精度なトランスクリプション
- 講義録音・音声メモの書き起こし

# 使用するスクリプト
- `scripts/transcribe_audio.py` - 音声文字起こしスクリプト

# 実行例

```bash
# 基本的な文字起こし
uv run --with google-genai \
  .claude/skills/gemini-audio-transcriber/scripts/transcribe_audio.py \
  "/path/to/audio.m4a" \
  --output transcript.md

# 出力形式を指定（text/md）
uv run --with google-genai \
  .claude/skills/gemini-audio-transcriber/scripts/transcribe_audio.py \
  "/path/to/audio.m4a" \
  --output transcript.md \
  --format md
```

# 対応フォーマット
- m4a, mp3, wav, aac, flac, ogg, webm

# 依存関係
- Python 3.9+
- uv (推奨)
- google-genai
- 環境変数: `GEMINI_API_KEY`（`.claude/skills/gemini-icon-creator/.env` または環境変数）

# Claude への指示
- ユーザーが「文字起こし」「トランスクリプション」「音声ファイルを書き起こし」に関する依頼をした場合、このスキルを適用する
- **API課金が発生する**ため、実行前に確認すること
- 文字起こし後はマークダウン形式で構造化すると可読性が上がる
