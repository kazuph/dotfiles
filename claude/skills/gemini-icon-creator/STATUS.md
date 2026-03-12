# Gemini Icon Creator Skill - Current Status

## 最終更新日時: 2026-03-12

## 設定サマリー

### デフォルトモデル
- **エイリアス**: `nanobananav2`
- **正式名称**: `gemini-3.1-flash-image-preview`
- **説明**: 最新・高速・高品質（Nano Banana 2）

### 利用可能なモデルエイリアス
| エイリアス | 正式名 | 説明 |
|-----------|--------|------|
| `nanobanana` | `gemini-2.5-flash-image-preview` | 生バナナ（高速・安価） |
| `nanobananapro` | `gemini-3-pro-image-preview` | ナノバナナプロ（高品質） |
| `nanobananav2` | `gemini-3.1-flash-image-preview` | ナノバナナ2（最新・高速・高品質・デフォルト） |

### スクリプト設定
- **スクリプトパス**: `~/.claude/skills/gemini-icon-creator/scripts/gen_image.py`
- **デフォルトモデル**: `nanobananav2` (行36)
- **MODEL_ALIASES**: 
  - `nanobananav2`: `gemini-3.1-flash-image-preview` (行30)
  - `nanobanana`: `gemini-2.5-flash-image-preview` (行32)
  - `nanobananapro`: `gemini-3-pro-image-preview` (行33)

### 削除済みコンポーネント
- Imagen系モデル (`imagen`, `imagen-ultra`, `imagen-fast`) 
- 旧エイリアス (`flash`, `pro`) - モデルは保持だがエイリアスとしては非表示
- モデル一覧取得関数: APIからの動的取得を廃止し、エイリアスで定義されたモデルのみを返すように変更

### 使用方法例
```bash
# デフォルトモデル（ナノバナナ2）で画像生成
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "a cute robot icon, flat design" \
  -o robot.png

# ナノバナナプロを明示的に指定
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "modern logo design, minimalist" \
  -m nanobananapro \
  -o logo.png

# ナノバナナ（生バナナ）を明示的に指定
uv run --with google-genai \
  ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py \
  -p "wide landscape photo" \
  -m nanobanana \
  --aspect 16:9 \
  -o landscape.png
```

### 依存関係
- Python 3.9+
- uv (推奨)
- google-genai
- 環境変数: `GEMINI_API_KEY`（`~/.claude/skills/gemini-icon-creator/.env` に配置）

### 注意事項
- 「transparent background」は使用禁止（チェッカーボードになるため）
- 推奨背景: `plain white background, soft gradient from white to very light gray, studio lighting, no patterns, seamless background`
- API課金が発生するため実行前に確認が必要