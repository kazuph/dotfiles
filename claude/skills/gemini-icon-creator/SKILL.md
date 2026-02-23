---
name: gemini-icon-creator
description: Gemini APIで画像を生成するシンプルなCLIツール。プロンプトを渡して1枚の画像を生成。
---

# スキルの目的
- Gemini APIでプロンプトから画像を生成
- シンプルなCLIインターフェース

# 使用するスクリプト
- `scripts/gen_image.py` - 画像生成CLI

# 実行例

```bash
# 基本的な使い方
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "a cute robot icon, flat design" \
  -o robot.png

# 高品質モデル（nanobananapro）を使用
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "modern logo design, minimalist" \
  -m nanobananapro \
  -o logo.png

# アスペクト比を指定
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "wide landscape photo" \
  --aspect 16:9 \
  -o landscape.png
```

# オプション

| オプション | 必須 | 説明 |
|-----------|------|------|
| `-p`, `--prompt` | Yes | 生成プロンプト |
| `-o`, `--output` | Yes | 出力ファイルパス |
| `-m`, `--model` | No | モデル名（default: nanobanana） |
| `--aspect` | No | アスペクト比（default: 1:1） |

# モデル

| エイリアス | 正式名 | 特徴 |
|-----------|--------|------|
| `nanobanana` | gemini-2.5-flash-preview-05-20 | 安価・高速（デフォルト） |
| `nanobananapro` | gemini-2.0-flash-preview-image-generation | 高品質 |

正式なモデル名を直接指定することも可能。

# アスペクト比
- 1:1（デフォルト）, 4:3, 3:2, 16:9, 21:9, 9:16

# 依存関係
- Python 3.9+
- uv (推奨)
- google-genai
- 環境変数: `GEMINI_API_KEY`（`~/.claude/skills/gemini-icon-creator/.env` に配置）

# 背景に関する注意（重要）

**「transparent background」は使用禁止**：AIが透過表現としてチェッカーボード（市松模様）を描いてしまう。

| NG | OK |
|:---|:---|
| `transparent background` | `plain white background` |
| `transparent gradient` | `soft gradient from white to light gray` |

推奨する背景指定：
```
plain white background, soft gradient from white to very light gray,
studio lighting, no patterns, seamless background
```

# Claude への指示
- ユーザーが「画像生成」「Geminiで画像」「アイコン生成」に関する依頼をした場合、このスキルを適用
- **API課金が発生する**ため、実行前に確認
- 生成後は必要に応じてWebPに変換（`cwebp -q 95 input.png -o output.webp`）
- **背景を透明にしたい場合でも「transparent」は使わない**（上記「背景に関する注意」参照）
