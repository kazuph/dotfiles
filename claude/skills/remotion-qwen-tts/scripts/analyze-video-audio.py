#!/usr/bin/env python3
"""
動画音声解析スクリプト - 無音区間を検出して問題を特定

使用方法:
  .venv/bin/python ~/.claude/skills/remotion-qwen-tts/scripts/analyze-video-audio.py out/video.mp4

前提条件:
  - ffmpegがインストールされていること
  - numpyがインストールされていること
"""

import sys
import subprocess
import tempfile
from pathlib import Path

try:
    import numpy as np
    import wave
except ImportError:
    print("numpy がインストールされていません。")
    print("pip install numpy でインストールしてください。")
    sys.exit(1)


def extract_audio(video_path: Path, output_path: Path) -> bool:
    """動画から音声をモノラルWAVとして抽出"""
    cmd = [
        "ffmpeg", "-y",
        "-i", str(video_path),
        "-vn",
        "-acodec", "pcm_s16le",
        "-ar", "16000",
        "-ac", "1",  # モノラル
        str(output_path)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0


def analyze_audio(wav_path: Path) -> dict:
    """音声を解析して無音区間を検出"""
    with wave.open(str(wav_path), "rb") as wav:
        sample_rate = wav.getframerate()
        n_frames = wav.getnframes()
        audio_data = wav.readframes(n_frames)
        audio = np.frombuffer(audio_data, dtype=np.int16).astype(np.float32) / 32768.0

    duration = len(audio) / sample_rate

    # 無音区間を検出（RMSベース）
    chunk_size = int(sample_rate * 0.1)  # 100ms単位
    threshold = 0.02
    silence_start = None
    silences = []
    last_sound_time = 0

    for i in range(0, len(audio), chunk_size):
        chunk = audio[i:i + chunk_size]
        if len(chunk) > 0:
            rms = np.sqrt(np.mean(chunk ** 2))
            time_pos = i / sample_rate

            if rms >= threshold:
                last_sound_time = (i + len(chunk)) / sample_rate
                if silence_start is not None:
                    silence_end = time_pos
                    silence_duration = silence_end - silence_start
                    if silence_duration >= 0.5:  # 0.5秒以上の無音
                        silences.append((silence_start, silence_end, silence_duration))
                    silence_start = None
            else:
                if silence_start is None:
                    silence_start = time_pos

    # 末尾の無音をチェック
    tail_silence = duration - last_sound_time
    if tail_silence >= 0.5:
        silences.append((last_sound_time, duration, tail_silence))

    return {
        "duration": duration,
        "last_sound_time": last_sound_time,
        "tail_silence": tail_silence,
        "silences": silences,
    }


def main():
    if len(sys.argv) < 2:
        print("使用方法: python analyze-video-audio.py <video_path>")
        print("例: python analyze-video-audio.py out/video.mp4")
        sys.exit(1)

    video_path = Path(sys.argv[1])
    if not video_path.exists():
        print(f"エラー: {video_path} が見つかりません")
        sys.exit(1)

    print("=" * 60)
    print("動画音声解析スクリプト")
    print("=" * 60)
    print(f"\n対象: {video_path}")

    # 一時ファイルに音声を抽出
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = Path(tmp.name)

    print("\n音声を抽出しています...")
    if not extract_audio(video_path, tmp_path):
        print("エラー: 音声抽出に失敗しました")
        print("ffmpegがインストールされているか確認してください")
        sys.exit(1)

    print("音声を解析しています...")
    result = analyze_audio(tmp_path)

    # 一時ファイル削除
    tmp_path.unlink()

    # 結果表示
    print("\n" + "-" * 60)
    print("解析結果")
    print("-" * 60)
    print(f"  動画の長さ: {result['duration']:.2f}秒")
    print(f"  最後の音声: {result['last_sound_time']:.2f}秒")
    print(f"  末尾の無音: {result['tail_silence']:.2f}秒")

    # 無音区間
    silences = result["silences"]
    long_silences = [s for s in silences if s[2] >= 3.0]

    print(f"\n検出された無音区間（0.5秒以上）: {len(silences)}箇所")

    if silences:
        for start, end, dur in silences:
            if dur >= 3.0:
                print(f"  ⚠️ {start:.1f}秒 〜 {end:.1f}秒 ({dur:.1f}秒) ← 長い無音！")
            else:
                print(f"  📍 {start:.1f}秒 〜 {end:.1f}秒 ({dur:.1f}秒)")

    # 判定
    print("\n" + "=" * 60)
    print("診断結果")
    print("=" * 60)

    issues = []

    # 末尾無音チェック
    if result["tail_silence"] >= 10:
        issues.append(f"❌ 末尾に{result['tail_silence']:.1f}秒の無音があります！")
        issues.append("   → Root.tsxでplaybackRate調整が行われていない可能性")
    elif result["tail_silence"] >= 3:
        issues.append(f"⚠️ 末尾に{result['tail_silence']:.1f}秒の無音があります")
        issues.append("   → pauseAfterまたはエンディング余白が大きすぎる可能性")

    # 長い無音区間チェック
    if len(long_silences) > 0:
        mid_silences = [s for s in long_silences if s[1] < result["duration"] - 1]
        if mid_silences:
            issues.append(f"⚠️ 動画中盤に3秒以上の無音が{len(mid_silences)}箇所あります")
            issues.append("   → セリフ間のpauseAfterが大きすぎる可能性")

    if issues:
        for issue in issues:
            print(issue)
        print("\n対処方法:")
        print("  1. Root.tsx/Main.tsxのplaybackRate調整を確認")
        print("  2. script.tsのpauseAfter値を確認")
        print("  3. generate-voices-qwen.pyのフレーム計算を確認")
        return 1
    else:
        print("✅ 問題は検出されませんでした！")
        print(f"   末尾無音: {result['tail_silence']:.2f}秒（許容範囲）")
        return 0


if __name__ == "__main__":
    sys.exit(main())
