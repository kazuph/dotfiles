#!/usr/bin/env python3
# Dependencies (uv):
#   google-genai
# Run (uv):
#   uv run --with google-genai ~/.claude/skills/gemini-icon-creator/scripts/gen_image.py -p "a cute cat" -o cat.png
"""
Gemini で画像を生成するシンプルなCLIツール。

使用例:
  gen_image.py -p "a cute robot icon" -o robot.png
  gen_image.py -p "modern logo design" -m nanobananapro -o logo.png
  gen_image.py -p "landscape photo" --aspect 16:9 -o landscape.png
"""

from __future__ import annotations

import argparse
import base64
import mimetypes
import os
import sys
from pathlib import Path

from google import genai
from google.genai import types


# モデル名のエイリアス
MODEL_ALIASES = {
    "flash": "gemini-2.5-flash-image-preview",      # 高速・安価
    "pro": "gemini-3-pro-image-preview",            # 高品質（推奨）
    "imagen": "imagen-4.0-generate-001",            # Imagen 4.0
    "imagen-ultra": "imagen-4.0-ultra-generate-001", # Imagen 4.0 Ultra
    "imagen-fast": "imagen-4.0-fast-generate-001",  # Imagen 4.0 Fast
    # 旧エイリアス（互換性維持）
    "nanobanana": "gemini-2.5-flash-image-preview",
    "nanobananapro": "gemini-3-pro-image-preview",
}

DEFAULT_MODEL = "pro"
ALLOWED_ASPECTS = ["1:1", "4:3", "3:2", "16:9", "21:9", "9:16"]


def list_available_models(client: genai.Client) -> list[str]:
    """画像生成対応モデルをAPIから取得"""
    image_models = []
    for m in client.models.list():
        name = m.name.replace("models/", "")
        # 画像生成対応モデルをフィルタ
        if any(kw in name.lower() for kw in ["image", "imagen"]):
            image_models.append(name)
    return sorted(image_models)


def load_env() -> None:
    """環境変数を読み込む"""
    candidates = [
        Path(__file__).parent.parent / ".env",  # スキルディレクトリ
        Path.home() / ".claude" / "skills" / "gemini-icon-creator" / ".env",
    ]

    for env_path in candidates:
        if not env_path.exists():
            continue
        for raw_line in env_path.read_text().splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


def get_api_key() -> str:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY not set. Export or add to .env", file=sys.stderr)
        sys.exit(2)
    return api_key


def resolve_model(model_arg: str) -> str:
    """エイリアスを正式なモデル名に変換"""
    return MODEL_ALIASES.get(model_arg.lower(), model_arg)


def generate_image(
    client: genai.Client,
    model: str,
    prompt: str,
    aspect_ratio: str,
) -> tuple[str | None, bytes] | None:
    """画像を生成して (mime_type, bytes) を返す"""
    contents = [
        types.Content(
            role="user",
            parts=[types.Part.from_text(text=prompt)],
        )
    ]
    config = types.GenerateContentConfig(
        response_modalities=["IMAGE", "TEXT"],
        image_config=types.ImageConfig(aspect_ratio=aspect_ratio),
    )

    response = client.models.generate_content(
        model=model, contents=contents, config=config
    )

    # レスポンスから画像を抽出
    for candidate in getattr(response, "candidates", []):
        content = getattr(candidate, "content", None)
        if not content:
            continue
        for part in getattr(content, "parts", []):
            inline = getattr(part, "inline_data", None)
            if inline and getattr(inline, "data", None):
                mime = getattr(inline, "mime_type", None)
                data = inline.data
                if isinstance(data, str):
                    data = base64.b64decode(data)
                return (mime, data)

    # テキストレスポンスがあれば表示
    if hasattr(response, "text") and response.text:
        print(f"Model response: {response.text}", file=sys.stderr)

    return None


def determine_extension(output_path: Path, mime: str | None) -> Path:
    """出力パスに拡張子がなければMIMEタイプから推定"""
    if output_path.suffix:
        return output_path
    if mime:
        ext = mimetypes.guess_extension(mime) or ".png"
        return output_path.with_suffix(ext)
    return output_path.with_suffix(".png")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gemini で画像を生成",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
  %(prog)s -p "a cute cat icon" -o cat.png
  %(prog)s -p "modern logo" -m pro -o logo.png
  %(prog)s -p "wide landscape" --aspect 16:9 -o bg.png
  %(prog)s --list-models  # 利用可能なモデル一覧

エイリアス:
  pro          Gemini 3 Pro Image (デフォルト、高品質・推奨)
  flash        Gemini 2.5 Flash Image (高速・安価)
  imagen       Imagen 4.0
  imagen-ultra Imagen 4.0 Ultra (最高品質)
  imagen-fast  Imagen 4.0 Fast (最速)

⚠️ 背景指定の注意:
  NG: "transparent background" → 市松模様になる
  OK: "plain white background, soft gradient, studio lighting, no patterns"
""",
    )
    parser.add_argument(
        "-p", "--prompt",
        required=False,
        help="生成プロンプト",
    )
    parser.add_argument(
        "-o", "--output",
        required=False,
        help="出力ファイルパス",
    )
    parser.add_argument(
        "-m", "--model",
        default=DEFAULT_MODEL,
        help=f"モデル名またはエイリアス (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--aspect",
        choices=ALLOWED_ASPECTS,
        default="1:1",
        help="アスペクト比 (default: 1:1)",
    )
    parser.add_argument(
        "--list-models",
        action="store_true",
        help="利用可能なモデル一覧を表示",
    )
    return parser.parse_args()


def main() -> None:
    load_env()
    args = parse_args()
    api_key = get_api_key()
    client = genai.Client(api_key=api_key)

    # モデル一覧表示モード
    if args.list_models:
        print("利用可能な画像生成モデル:", file=sys.stderr)
        print("-" * 50, file=sys.stderr)
        print("\n【エイリアス】", file=sys.stderr)
        for alias, full_name in MODEL_ALIASES.items():
            if alias not in ("nanobanana", "nanobananapro"):  # 旧エイリアスは非表示
                marker = " (default)" if alias == DEFAULT_MODEL else ""
                print(f"  {alias:14} → {full_name}{marker}", file=sys.stderr)
        print("\n【APIで利用可能なモデル】", file=sys.stderr)
        for model_name in list_available_models(client):
            print(f"  {model_name}", file=sys.stderr)
        return

    # 通常の画像生成モード
    if not args.prompt or not args.output:
        print("Error: -p/--prompt と -o/--output は必須です", file=sys.stderr)
        print("使用方法: gen_image.py --help", file=sys.stderr)
        sys.exit(2)

    model = resolve_model(args.model)
    output_path = Path(args.output)

    print(f"Model: {model}", file=sys.stderr)
    print(f"Prompt: {args.prompt}", file=sys.stderr)
    print(f"Aspect: {args.aspect}", file=sys.stderr)
    print("Generating...", file=sys.stderr)

    result = generate_image(
        client,
        model=model,
        prompt=args.prompt,
        aspect_ratio=args.aspect,
    )

    if not result:
        print("Error: No image generated", file=sys.stderr)
        sys.exit(1)

    mime, data = result
    output_path = determine_extension(output_path, mime)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(data)

    print(f"Saved: {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
