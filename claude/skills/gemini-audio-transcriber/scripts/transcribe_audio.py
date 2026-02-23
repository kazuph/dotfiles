#!/usr/bin/env python3
# Dependencies (uv):
#   google-genai
# Run (uv):
#   uv run --with google-genai .claude/skills/gemini-audio-transcriber/scripts/transcribe_audio.py audio.m4a --output transcript.md
"""
Gemini 2.0 Flash を使用して音声ファイルを文字起こしするスクリプト。

このスクリプトは .claude/skills/gemini-icon-creator/.env（または環境変数）
から API キーを読み込み、Gemini 2.0 Flash で音声を文字起こしします。
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from google import genai
from google.genai import types


MODEL_NAME = "gemini-2.0-flash"


def load_env_from_skill() -> None:
    """スキルディレクトリや ~/.claude/skills/ から環境変数を読み込む"""
    script_path = Path(__file__).resolve()
    skills_dir = script_path.parent.parent.parent  # ~/.claude/skills/
    candidates = [
        script_path.with_name(".env"),
        script_path.parent.parent / ".env",  # gemini-audio-transcriber/.env
        skills_dir / "gemini-icon-creator" / ".env",  # gemini-icon-creator/.env を共有
        Path.home() / ".claude" / "skills" / "gemini-icon-creator" / ".env",  # グローバル明示
    ]

    for env_path in candidates:
        if not env_path.exists():
            continue
        for raw_line in env_path.read_text().splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if key and value:
                os.environ.setdefault(key, value)


def get_api_key() -> str:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print(
            "GEMINI_API_KEY not set. Export your key or place it in .env, e.g.:\n"
            "  GEMINI_API_KEY=YOUR_API_KEY",
            file=sys.stderr,
        )
        sys.exit(2)
    return api_key


def get_mime_type(file_path: Path) -> str:
    """ファイル拡張子からMIMEタイプを推定"""
    suffix = file_path.suffix.lower()
    mime_types = {
        ".m4a": "audio/mp4",
        ".mp3": "audio/mpeg",
        ".wav": "audio/wav",
        ".aac": "audio/aac",
        ".flac": "audio/flac",
        ".ogg": "audio/ogg",
        ".webm": "audio/webm",
    }
    return mime_types.get(suffix, "audio/mp4")


def transcribe_audio(client: genai.Client, audio_path: Path) -> str:
    """音声ファイルを文字起こしする"""

    # 音声ファイルを読み込む
    audio_data = audio_path.read_bytes()
    mime_type = get_mime_type(audio_path)

    print(f"音声ファイル読み込み完了: {audio_path.name} ({len(audio_data) / 1024 / 1024:.1f} MB)", file=sys.stderr)
    print(f"MIMEタイプ: {mime_type}", file=sys.stderr)
    print(f"モデル: {MODEL_NAME}", file=sys.stderr)
    print("文字起こし中...", file=sys.stderr)

    # Gemini APIで文字起こし
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=[
            types.Content(
                role="user",
                parts=[
                    types.Part.from_bytes(data=audio_data, mime_type=mime_type),
                    types.Part.from_text(
                        text="この音声を日本語で文字起こししてください。"
                        "話者の発言を忠実に書き起こし、句読点を適切に入れてください。"
                        "フィラー（えー、あのー等）も含めて忠実に書き起こしてください。"
                        "段落分けは話題の区切りで行ってください。"
                    ),
                ],
            )
        ],
    )

    return response.text


def format_as_markdown(transcript: str, source_file: str) -> str:
    """文字起こし結果をマークダウン形式でフォーマット"""
    return f"""# 文字起こし: {source_file}

{transcript}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gemini 2.0 Flash で音声ファイルを文字起こし"
    )
    parser.add_argument(
        "audio_file",
        type=str,
        help="文字起こしする音声ファイルのパス",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=None,
        help="出力ファイルパス（未指定時は標準出力）",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "md"],
        default="text",
        help="出力形式（text: プレーンテキスト, md: マークダウン）",
    )
    return parser.parse_args()


def main() -> None:
    load_env_from_skill()
    args = parse_args()
    api_key = get_api_key()

    audio_path = Path(args.audio_file).resolve()
    if not audio_path.exists():
        print(f"ファイルが見つかりません: {audio_path}", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    transcript = transcribe_audio(client, audio_path)

    # 出力形式に応じてフォーマット
    if args.format == "md":
        output = format_as_markdown(transcript, audio_path.name)
    else:
        output = transcript

    # 出力
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output, encoding="utf-8")
        print(f"保存完了: {output_path}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
