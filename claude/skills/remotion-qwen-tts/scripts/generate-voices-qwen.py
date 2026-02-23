#!/usr/bin/env python3
"""
Qwen3-TTS音声一括生成スクリプト

使用方法:
  .venv/bin/python scripts/generate-voices-qwen.py

前提条件:
  - Apple Silicon Mac（MLX使用）
  - .venvにmlx-audio>=0.3.0, soundfile, numpy, pyyaml がインストールされていること
    pip install git+https://github.com/Blaizzy/mlx-audio.git soundfile numpy pyyaml

重要な注意点:
  1. フレーム計算: frames = duration / PLAYBACK_RATE * FPS
     → durationInFramesは「playbackRate考慮済み」の値として出力
     → Main.tsx/Root.tsxで二度割りしないこと！

  2. max_tokens: セリフ長に応じて動的に設定
     → 短すぎると音声が途切れる
     → 12.5トークン/秒 + 大きめの余裕を持たせる

  3. 口パクデータ: 動画フレームに正確に対応するよう計算
     → playbackRateを考慮した時間範囲でRMSを計算

  4. キャラクター設定: characters.yamlから動的に読み込み
     → ハードコードしない
"""

import re
import time
import json
import warnings
from pathlib import Path

import numpy as np
import soundfile as sf
import yaml
from mlx_audio.tts import load

# Suppress tokenizer warning
warnings.filterwarnings("ignore", message=".*incorrect regex pattern.*")

# ルートディレクトリ
ROOT_DIR = Path(__file__).parent.parent
SCRIPT_PATH = ROOT_DIR / "src" / "data" / "script.ts"
OUTPUT_DIR = ROOT_DIR / "public" / "voices"
CHARACTERS_YAML_PATH = ROOT_DIR / "characters.yaml"

# 動画設定（config.tsと合わせる）
FPS = 30
PLAYBACK_RATE = 1.2


def load_character_instructs() -> dict[str, str]:
    """characters.yamlからvoice_instructを読み込む"""
    if not CHARACTERS_YAML_PATH.exists():
        print(f"  警告: {CHARACTERS_YAML_PATH} が見つかりません。デフォルト設定を使用します。")
        return {
            "zundamon": "元気で明るく可愛らしい若い女の子の声。語尾に特徴があり、ハキハキとした話し方",
            "metan": "落ち着いた大人っぽい女性の声。上品で穏やかな話し方",
        }

    with open(CHARACTERS_YAML_PATH, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    instructs = {}
    for char_id, char_data in config.get("characters", {}).items():
        instructs[char_id] = char_data.get("voice_instruct", "普通の声")

    return instructs


# キャラクター設定（characters.yamlから動的生成）
CHARACTER_INSTRUCTS = load_character_instructs()


def parse_script_ts(script_path: Path) -> list[dict]:
    """script.tsからセリフデータをパース"""
    content = script_path.read_text(encoding="utf-8")

    # scriptData配列を抽出
    match = re.search(r'export const scriptData[^=]*=\s*\[([\s\S]*?)\];', content)
    if not match:
        raise ValueError("scriptData not found in script.ts")

    data_str = match.group(1)
    lines = []

    # 各セリフオブジェクトをパース
    # id, character, text, voiceFileを抽出
    pattern = r'\{\s*id:\s*(\d+),\s*character:\s*"([^"]+)",\s*text:\s*"([^"]+)"[^}]*voiceFile:\s*"([^"]+)"'
    for m in re.finditer(pattern, data_str):
        lines.append({
            "id": int(m.group(1)),
            "character": m.group(2),
            "text": m.group(3),
            "voiceFile": m.group(4),
        })

    return lines


def extract_mouth_data_for_video(
    audio: np.ndarray,
    sample_rate: int,
    video_fps: int,
    playback_rate: float,
    threshold: float = 0.015
) -> list[bool]:
    """
    動画フレームに正確に対応する口パクデータを抽出

    重要: 動画の各フレームに対応する音声範囲を計算し、そのRMSで口パクを判定
    これにより、playbackRateによるズレを完全に解消する

    Args:
        audio: 音声データ（numpy配列）
        sample_rate: サンプルレート
        video_fps: 動画のFPS（通常30）
        playback_rate: 再生速度（通常1.2）
        threshold: 口を開ける閾値（低いほど口パクが多い）

    Returns:
        動画の各フレームで口を開けるか(True)閉じるか(False)のリスト
    """
    audio_duration = len(audio) / sample_rate  # 音声の長さ（秒）
    video_duration = audio_duration / playback_rate  # 動画上の再生時間（秒）
    video_frames = int(video_duration * video_fps)  # 動画のフレーム数

    abs_audio = np.abs(audio)
    mouth_data = []

    for frame in range(video_frames):
        # 動画フレームに対応する音声の時間範囲
        # 動画のフレームi → 音声時間 = i / video_fps * playback_rate
        audio_start_time = frame / video_fps * playback_rate
        audio_end_time = (frame + 1) / video_fps * playback_rate

        # サンプルインデックスに変換
        start_sample = int(audio_start_time * sample_rate)
        end_sample = int(audio_end_time * sample_rate)

        chunk = abs_audio[start_sample:min(end_sample, len(abs_audio))]
        if len(chunk) > 0:
            rms = np.sqrt(np.mean(chunk ** 2))
            # numpy.bool_をPython boolに変換
            mouth_data.append(bool(rms > threshold))
        else:
            mouth_data.append(False)

    return mouth_data


def main():
    print("=" * 50)
    print("Qwen3-TTS 音声生成スクリプト")
    print("=" * 50)

    # 出力ディレクトリ作成
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # スクリプトデータ読み込み
    print("\nスクリプトデータを読み込んでいます...")
    script_data = parse_script_ts(SCRIPT_PATH)
    print(f"  {len(script_data)}件のセリフを検出")

    # モデルロード
    print("\nQwen3-TTSモデルをロードしています...")
    start_time = time.time()
    model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')
    load_time = time.time() - start_time
    print(f"  モデルロード完了: {load_time:.2f}秒")

    # 音声生成
    print("\n音声を生成しています...")
    durations = []
    mouth_data_all = {}
    total_gen_time = 0

    for line in script_data:
        character = line["character"]
        text = line["text"]
        voice_file = line["voiceFile"]

        instruct = CHARACTER_INSTRUCTS.get(character, "普通の声")
        output_path = OUTPUT_DIR / voice_file

        print(f"\n  [{line['id']:02d}] {character}: \"{text[:30]}{'...' if len(text) > 30 else ''}\"")

        gen_start = time.time()

        # 音声生成
        # max_tokensの計算: 1秒あたり約12.5トークン
        # 日本語は話し方によって長さが大きく変動する（特にゆっくり話すキャラ）
        # max_tokensはセリフが収まる十分な長さを確保（短すぎると途切れる）
        # ユーザーからのフィードバック: 現在の計算では成功率が低いので大幅に余裕を持たせる
        estimated_duration = max(len(text) * 1.0, 5.0)  # 最低5秒、1文字1.0秒で大きく余裕
        max_tokens = int(estimated_duration * 15) + 300  # さらに余裕を持たせたトークン数

        result = next(model.generate_voice_design(
            text=text,
            instruct=instruct,
            language="Japanese",
            max_tokens=max_tokens,
            temperature=0.65,
            repetition_penalty=1.15,
            top_k=35,
            top_p=0.92,
        ))

        # WAV保存
        sf.write(str(output_path), result.audio, result.sample_rate)

        # 長さ計算
        duration = len(result.audio) / result.sample_rate
        gen_time = time.time() - gen_start
        total_gen_time += gen_time
        rtf = gen_time / duration if duration > 0 else 0

        # フレーム数計算（playbackRateを考慮）
        # playbackRate=1.2なら1.2倍速再生なので、動画上の時間は duration/1.2
        frames = int(duration / PLAYBACK_RATE * FPS)

        # 口パクデータ抽出（動画フレームに正確に対応）
        # 動画の各フレームに対応する音声範囲でRMSを計算
        mouth_data = extract_mouth_data_for_video(
            result.audio,
            result.sample_rate,
            FPS,
            PLAYBACK_RATE,
            threshold=0.015  # 低めに設定して口パクを多めに
        )
        mouth_data_all[voice_file] = mouth_data

        durations.append({
            "id": line["id"],
            "file": voice_file,
            "duration": round(duration, 2),
            "frames": frames,
        })

        print(f"      → {duration:.2f}秒, {frames}フレーム (生成: {gen_time:.2f}秒, RTF: {rtf:.3f})")

    # 結果保存
    durations_path = OUTPUT_DIR / "durations.json"
    with open(durations_path, "w", encoding="utf-8") as f:
        json.dump(durations, f, indent=2, ensure_ascii=False)

    # 口パクデータ保存（JSON形式）
    mouth_data_path = OUTPUT_DIR / "mouth-data.json"
    with open(mouth_data_path, "w", encoding="utf-8") as f:
        json.dump(mouth_data_all, f, ensure_ascii=False)

    # 口パクデータ保存（TypeScript形式 - Remotion用）
    mouth_ts_path = ROOT_DIR / "src" / "data" / "mouth-data.generated.ts"
    with open(mouth_ts_path, "w", encoding="utf-8") as f:
        f.write("// このファイルは自動生成されます\n")
        f.write("// npm run voices で再生成されます\n\n")
        f.write("// 各フレームで口を開ける(true)か閉じる(false)かのデータ\n")
        f.write("// playbackRateを考慮済み\n")
        f.write("export const MOUTH_DATA: Record<string, boolean[]> = ")
        f.write(json.dumps(mouth_data_all, ensure_ascii=False))
        f.write(";\n")

    print("\n" + "=" * 50)
    print("完了！")
    print(f"  モデルロード: {load_time:.2f}秒")
    print(f"  音声生成合計: {total_gen_time:.2f}秒")
    print(f"  合計時間: {time.time() - start_time:.2f}秒")
    print(f"\n  出力: {OUTPUT_DIR}")
    print(f"  durations.json: {durations_path}")
    print(f"  mouth-data.json: {mouth_data_path}")

    # script.ts更新用の情報を出力
    print("\n=== script.ts更新用 ===")
    for d in durations:
        print(f"ID {d['id']}: durationInFrames: {d['frames']}, // {d['duration']}s")


if __name__ == "__main__":
    main()
