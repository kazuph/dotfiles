---
name: remotion-qwen-tts
description: Remotion + Qwen-TTS（MLX）で動画を生成する際の完全ガイド。音声生成、口パク同期、フレーム計算、そして必須の検証フェーズまでカバー。動画生成時に使用。
metadata:
  tags: remotion, qwen-tts, mlx, tts, video, apple-silicon, verification
---

# Remotion + Qwen-TTS 完全ガイド

Apple Silicon Mac上でQwen3-TTSを使用してRemotionで動画を生成するための完全ワークフロー。

**重要**: このスキルの核心は**検証フェーズ**。生成物を自分で確認せずに「完了」と報告してはならない。

## 目次

- [ワークフロー全体図](#ワークフロー全体図)
- [環境構築](#環境構築)
- [音声生成](#音声生成)
- [フレーム計算の罠](#フレーム計算の罠)
- [口パク同期](#口パク同期)
- [検証フェーズ（必須）](#検証フェーズ必須)
- [トラブルシューティング](#トラブルシューティング)

## 詳細ルール

より詳細な情報は以下のルールファイルを参照:

- [rules/frame-calculation.md](rules/frame-calculation.md) - フレーム計算の完全ガイド
- [rules/lip-sync.md](rules/lip-sync.md) - 口パク（リップシンク）完全ガイド
- [rules/verification-workflow.md](rules/verification-workflow.md) - 検証ワークフロー完全ガイド

---

## ワークフロー全体図

```
┌─────────────────────────────────────────────────────────────────┐
│                    動画生成ワークフロー                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. スクリプト作成                                                │
│     └─ src/data/script.ts にセリフを記述                         │
│                                                                  │
│  2. 音声生成 ───────────────────────────────────────────────────│
│     └─ scripts/generate-voices-qwen.py                          │
│        ├─ Qwen3-TTSで音声生成                                   │
│        ├─ 音声波形から口パクデータ抽出                           │
│        └─ durations.json, mouth-data.generated.ts 出力           │
│                                                                  │
│  3. 【検証1】個別音声検証 ─────────────────────────────────────│
│     └─ scripts/verify-voices.py (Whisper)                       │
│        ├─ 各音声を文字起こし                                     │
│        ├─ 元テキストと類似度比較                                 │
│        └─ 70%未満は警告 → 再生成検討                            │
│                                                                  │
│  4. 動画ビルド                                                   │
│     └─ npm run build                                            │
│                                                                  │
│  5. 【検証2】動画音声検証 ─────────────────────────────────────│
│     └─ scripts/analyze-video-audio.py                           │
│        ├─ 動画から音声抽出                                       │
│        ├─ 無音区間検出                                          │
│        ├─ 末尾無音チェック（3秒以上は問題）                      │
│        └─ セリフ途切れ検出                                       │
│                                                                  │
│  6. 目視確認                                                     │
│     └─ open out/video.mp4 で実際に視聴                          │
│                                                                  │
│  7. 完了報告（検証パスした場合のみ）                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 環境構築

### 必要なもの

- Apple Silicon Mac (M1/M2/M3/M4)
- Python 3.10+
- Node.js 18+

### セットアップ

```bash
# Python仮想環境
python3 -m venv .venv
source .venv/bin/activate

# MLX関連
pip install git+https://github.com/Blaizzy/mlx-audio.git soundfile numpy

# 検証用（Whisper）
pip install mlx-whisper

# Node依存
npm install
```

---

## 音声生成

### 基本コマンド

```bash
.venv/bin/python scripts/generate-voices-qwen.py
```

### 重要な設定

```python
# config.ts
export const VIDEO_CONFIG = {
  fps: 30,
  playbackRate: 1.2,  # 音声を1.2倍速で再生
};
```

### キャラクター音声設定

キャラクター設定は `characters.yaml` から動的に読み込まれます：

```yaml
# characters.yaml
characters:
  zundamon:
    name: ずんだもん
    voice_instruct: "元気で明るく可愛らしい若い女の子の声。語尾に特徴があり、ハキハキとした話し方"
  metan:
    name: 四国めたん
    voice_instruct: "落ち着いた大人っぽい女性の声。上品で穏やかな話し方"
  # 新しいキャラクターを追加するにはここに定義
```

`characters.yaml` がない場合はデフォルト設定（zundamon/metan）が使用されます。

---

## フレーム計算の罠

### 最重要ポイント: 二重調整問題

**絶対に避けるべき罠**: `durationInFrames`を複数箇所でplaybackRateで調整してしまう

#### 正しい設計

```
┌─────────────────────────────────────────────────────────────────┐
│ generate-voices-qwen.py                                          │
│   frames = int(duration / PLAYBACK_RATE * FPS)                  │
│   → durationInFramesは「playbackRate考慮済み」の値              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ script.ts                                                        │
│   durationInFrames: 180  // すでに1.2倍速考慮済み               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Main.tsx / Root.tsx                                              │
│   そのまま使用！ 二度割りしない！                                │
│   const getAdjustedFrames = (frames) => frames;  // OK           │
│   const getAdjustedFrames = (frames) => frames / playbackRate; // NG!
└─────────────────────────────────────────────────────────────────┘
```

#### 症状と原因

| 症状 | 原因 |
|------|------|
| 末尾に長い無音（10秒以上） | Root.tsxでplaybackRate調整してない |
| セリフが途中で切れる | Main.tsx/Root.tsxで二重にplaybackRate調整してる |
| 音声と映像がずれる | durationInFramesの計算式が間違ってる |

#### 計算例

```
音声長: 7.2秒
playbackRate: 1.2
FPS: 30

正しい計算:
  動画上の再生時間 = 7.2 / 1.2 = 6秒
  フレーム数 = 6 * 30 = 180フレーム
  durationInFrames = 180

間違い1（調整忘れ）:
  frames = 7.2 * 30 = 216フレーム → 末尾に無音

間違い2（二重調整）:
  durationInFrames = 180（正しい）
  Main.tsx: 180 / 1.2 = 150フレーム → セリフ切れ
```

---

## 口パク同期

### 音声波形からの口パクデータ抽出（改善版）

動画フレームに正確に対応する口パクデータを抽出します。
playbackRateを考慮した時間範囲でRMSを計算することで、ズレを解消します。

```python
def extract_mouth_data_for_video(
    audio: np.ndarray,
    sample_rate: int,
    video_fps: int,
    playback_rate: float,
    threshold: float = 0.015  # 低めで口パク多め
) -> list[bool]:
    """
    動画フレームに正確に対応する口パクデータを抽出

    重要: 動画の各フレームに対応する音声範囲を計算し、そのRMSで口パクを判定
    これにより、playbackRateによるズレを完全に解消する
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
            mouth_data.append(bool(rms > threshold))  # Python boolに変換！
        else:
            mouth_data.append(False)

    return mouth_data
```

### 注意点

1. **numpy.bool_ → Python bool変換**: JSONシリアライズ時にエラーになる
2. **playbackRate考慮**: 動画フレームごとに対応する音声範囲を計算
3. **threshold=0.015**: 低めに設定して口パクを自然に多く

---

## 検証フェーズ（必須）

### 検証1: 個別音声検証（Whisper）

```bash
.venv/bin/python ~/.claude/skills/remotion-qwen-tts/scripts/verify-voices.py
```

#### Whisperの限界（重要）

**Whisperは完璧ではない。** 書き起こし精度には限界があり、以下を理解して使用すること：

| 検出できること | 検出できないこと |
|---------------|----------------|
| 音声が途中で切れている（無音区間が長い） | 細かい誤字脱字 |
| 完全に別の内容が話されている | 固有名詞の表記揺れ（例：ずんだもん→すんだもん） |
| 大幅な発音ミス | 句読点の有無 |
| | カタカナ英語の表記差（例：ギットハブ→キッドハブ） |

**検証の目的**: 音声が**最後まで正しく生成されているか**（途中で切れていないか）を確認すること。
類似度スコアが低くても、音声を実際に聴いて問題なければOK。

#### 判断基準

| 類似度 | 判定 | アクション |
|--------|------|-----------|
| 70%+ | 許容 | 実際に聴いて確認、問題なければOK |
| 50-70% | 要確認 | 音声を聴いて途切れがないか確認 |
| 50%未満 | 要注意 | 音声が途中で切れている可能性大。再生して確認 |

**注意**: 類似度が低い＝壊れている、ではない。Whisperの誤認識の可能性もある。
最終判断は**実際に音声を聴くこと**で行う。

#### 将来の改善: TTS発音問題の自動修正（未実装）

より高精度な音声認識モデルを使用すれば、TTSの発音問題も検出可能。
検出した場合の修正手法：

1. **漢字を開く**: 難読漢字や固有名詞をひらがなに変換
   - 例: `生成` → `せいせい`（「先生」と誤認識される場合）

2. **アルファベットをカタカナ化**: 英語表記を発音に近いカタカナに
   - 例: `GitHub` → `ギットハブ`
   - 例: `Claude Code` → `クロードコード`

これを自動化するには、Whisper検証で発音ミスを検出 → script.tsの`text`フィールドを自動修正 → 再生成、というループが必要。

### 検証2: 動画音声検証

```bash
.venv/bin/python ~/.claude/skills/remotion-qwen-tts/scripts/analyze-video-audio.py out/video.mp4
```

#### 検証内容

- 動画から音声抽出（モノラル）
- 無音区間検出（RMSベース）
- 末尾無音の長さチェック

#### 判断基準

| 末尾無音 | 判定 | アクション |
|----------|------|-----------|
| 2秒未満 | OK | 問題なし |
| 2-3秒 | 許容 | 許容範囲 |
| 3秒以上 | 問題 | Root.tsx/script.ts確認 |
| 10秒以上 | 重大 | playbackRate二重調整疑い |

### 検証3: 目視確認

```bash
open out/video.mp4
```

#### 確認項目

- [ ] セリフが最後まで再生される
- [ ] 口パクが音声と同期している
- [ ] 末尾に不自然な無音がない
- [ ] 字幕とキャラクターが正しく表示される

---

## トラブルシューティング

### 音声が途切れる

**原因**: max_tokensが短すぎる

```python
# NG: 固定値や小さめの計算
max_tokens = 300
# or
estimated_duration = max(len(text) * 0.4, 3.0)
max_tokens = int(estimated_duration * 12.5) + 100

# OK: 大きく余裕を持たせた計算（推奨）
estimated_duration = max(len(text) * 1.0, 5.0)  # 最低5秒、1文字1.0秒
max_tokens = int(estimated_duration * 15) + 300  # 大きめの余裕
```

**ポイント**: 日本語は話し方によって長さが大きく変動する（特にゆっくり話すキャラ）。
短すぎると途切れるので、余裕を大きく持たせる。

### 末尾に長い無音

**原因**: playbackRate調整の不整合

1. generate-voices-qwen.py: `frames = duration / PLAYBACK_RATE * FPS`
2. Root.tsx: そのまま`durationInFrames + pauseAfter`を使用
3. Main.tsx: そのまま使用（二度割りしない）

### セリフが切れる

**原因**: 二重playbackRate調整

Main.tsxの`getAdjustedFrames`を確認:

```typescript
// NG: 二重調整
const getAdjustedFrames = (frames) => Math.ceil(frames / playbackRate);

// OK: そのまま使用
const getAdjustedFrames = (frames) => frames;
```

### numpy.bool_のJSONエラー

```python
# NG
mouth_data.append(rms > threshold)

# OK
mouth_data.append(bool(rms > threshold))
```

---

## スクリプト一覧

| スクリプト | 用途 |
|-----------|------|
| [scripts/generate-voices-qwen.py](scripts/generate-voices-qwen.py) | 音声生成テンプレート |
| [scripts/verify-voices.py](scripts/verify-voices.py) | Whisper検証 |
| [scripts/analyze-video-audio.py](scripts/analyze-video-audio.py) | 動画音声解析 |

---

## チェックリスト

動画生成完了前に必ず確認:

- [ ] `verify-voices.py` で平均類似度70%以上
- [ ] `analyze-video-audio.py` で末尾無音3秒未満
- [ ] `open out/video.mp4` で目視確認
- [ ] セリフが途切れていない
- [ ] 口パクが自然

**すべてパスするまで「完了」と報告してはならない。**
