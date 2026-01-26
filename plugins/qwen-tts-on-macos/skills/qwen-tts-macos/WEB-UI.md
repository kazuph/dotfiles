# TTS Web UI 構築ガイド

ブラウザでQwen3-TTSのパラメータを調整できるWeb UIの構築方法。

## アーキテクチャ

```
┌─────────────────┐     HTTP/JSON     ┌──────────────────┐
│  Frontend       │ ◄───────────────► │  Backend         │
│  (HTML/JS)      │                   │  (FastAPI)       │
│                 │                   │                  │
│  - スライダー   │  POST /generate   │  - キュー処理    │
│  - プリセット   │  GET /task/{id}   │  - TTS生成       │
│  - 履歴表示     │  GET /history     │  - 履歴保存      │
└─────────────────┘                   └──────────────────┘
```

## ディレクトリ構成

```
project/
├── backend/
│   ├── main.py           # FastAPI サーバー
│   └── requirements.txt
├── frontend/
│   └── index.html        # シングルファイルUI
└── audio_history/        # 生成音声保存（自動作成）
    ├── metadata.json
    └── *.wav
```

## バックエンド（FastAPI）

### requirements.txt

```
fastapi>=0.100.0
uvicorn[standard]>=0.20.0
soundfile>=0.12.0
mlx-audio>=0.1.0
```

### main.py 基本構造

```python
"""TTS Web API Server with Queue"""

import asyncio
import json
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional

import soundfile as sf
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel, Field

# ディレクトリ設定
BASE_DIR = Path(__file__).parent.parent
FRONTEND_DIR = BASE_DIR / "frontend"
AUDIO_DIR = BASE_DIR / "audio_history"
METADATA_FILE = AUDIO_DIR / "metadata.json"

AUDIO_DIR.mkdir(exist_ok=True)

# グローバルモデル
tts_model = None


class TaskStatus(str, Enum):
    QUEUED = "queued"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class TTSTask:
    id: str
    text: str
    instruct: str
    max_tokens: int
    temperature: float
    repetition_penalty: float
    top_k: int
    top_p: float
    status: TaskStatus = TaskStatus.QUEUED
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    duration: Optional[float] = None
    generation_time: Optional[float] = None
    rtf: Optional[float] = None
    error: Optional[str] = None
    queue_position: int = 0


# タスクキュー
task_queue: asyncio.Queue = None
tasks: Dict[str, TTSTask] = {}
processing_lock = asyncio.Lock()


async def process_queue():
    """バックグラウンドキュー処理"""
    global tts_model
    while True:
        task_id = await task_queue.get()
        task = tasks.get(task_id)

        if not task or task.status != TaskStatus.QUEUED:
            task_queue.task_done()
            continue

        async with processing_lock:
            task.status = TaskStatus.PROCESSING

            try:
                start_time = time.time()

                # TTS実行（イベントループをブロックしない）
                loop = asyncio.get_event_loop()
                result = await loop.run_in_executor(
                    None,
                    lambda: next(tts_model.generate_voice_design(
                        text=task.text,
                        instruct=task.instruct,
                        language="Japanese",
                        max_tokens=task.max_tokens,
                        temperature=task.temperature,
                        repetition_penalty=task.repetition_penalty,
                        top_k=task.top_k,
                        top_p=task.top_p,
                    ))
                )

                generation_time = time.time() - start_time
                duration = len(result.audio) / result.sample_rate
                rtf = generation_time / duration if duration > 0 else 0

                # 音声保存
                audio_path = AUDIO_DIR / f"{task.id}.wav"
                sf.write(str(audio_path), result.audio, result.sample_rate)

                task.status = TaskStatus.COMPLETED
                task.duration = round(duration, 2)
                task.generation_time = round(generation_time, 2)
                task.rtf = round(rtf, 3)

            except Exception as e:
                task.status = TaskStatus.FAILED
                task.error = str(e)

            task_queue.task_done()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """起動時にモデルロード"""
    global tts_model, task_queue

    print("Loading Qwen3-TTS model...")
    from mlx_audio.tts import load
    tts_model = load('mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit')
    print("Model loaded!")

    task_queue = asyncio.Queue()
    processor = asyncio.create_task(process_queue())

    yield

    processor.cancel()
    tts_model = None


app = FastAPI(title="TTS Web API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    instruct: str = Field(default="落ち着いた女性の声", max_length=200)
    max_tokens: int = Field(default=500, ge=300, le=2000)
    temperature: float = Field(default=0.65, ge=0.1, le=1.0)
    repetition_penalty: float = Field(default=1.15, ge=1.0, le=2.0)
    top_k: int = Field(default=35, ge=10, le=100)
    top_p: float = Field(default=0.92, ge=0.5, le=1.0)


@app.get("/", response_class=HTMLResponse)
async def serve_frontend():
    html_path = FRONTEND_DIR / "index.html"
    return html_path.read_text()


@app.post("/api/generate")
async def generate_tts(request: TTSRequest):
    task_id = str(uuid.uuid4())[:8]
    task = TTSTask(
        id=task_id,
        text=request.text,
        instruct=request.instruct,
        max_tokens=request.max_tokens,
        temperature=request.temperature,
        repetition_penalty=request.repetition_penalty,
        top_k=request.top_k,
        top_p=request.top_p,
        queue_position=task_queue.qsize() + 1
    )
    tasks[task_id] = task
    await task_queue.put(task_id)
    return {"id": task_id, "status": task.status.value}


@app.get("/api/task/{task_id}")
async def get_task_status(task_id: str):
    task = tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return {
        "id": task.id,
        "status": task.status.value,
        "duration": task.duration,
        "generation_time": task.generation_time,
        "rtf": task.rtf,
        "error": task.error,
    }


@app.get("/api/audio/{audio_id}")
async def get_audio(audio_id: str):
    audio_path = AUDIO_DIR / f"{audio_id}.wav"
    if not audio_path.exists():
        raise HTTPException(status_code=404, detail="Audio not found")
    return FileResponse(audio_path, media_type="audio/wav")
```

### 起動方法

```bash
cd backend
source ../.venv/bin/activate
uvicorn main:app --reload --port 8000
```

## フロントエンド（HTML/JS）

### 主要機能

1. **パラメータスライダー**
   - max_tokens (300-2000)
   - temperature (0.1-1.0)
   - repetition_penalty (1.0-2.0)
   - top_k (10-100)
   - top_p (0.5-1.0)

2. **声質プリセット**
   - 落ち着いた女性/男性
   - 明るく元気な女性/男性
   - 優しく穏やかな女性/男性
   - 知的でクールな女性/男性

3. **再生速度調整**
   - 0.5x, 0.7x, 1x, 1.2x, 1.5x, 2x
   - `audio.playbackRate` で実装

4. **キュー状態表示**
   - 待機中/処理中/完了/失敗
   - プログレスバー（推定完了時間）

5. **履歴永続化**
   - LocalStorageではなくサーバー側で保存
   - リロードしても履歴が残る

### レイアウト構成

```
┌──────────────────────────────────────────────────────┐
│                     TTS Web UI                        │
├──────────────────┬───────────────────────────────────┤
│                  │                                    │
│  [Controls]      │  [Timeline]                        │
│                  │                                    │
│  Text Input      │  ┌────────────────────────────┐   │
│  Voice Preset    │  │ 音声カード 1               │   │
│  Sliders         │  │ ▶ [──●─────────] 0:12      │   │
│                  │  │ 0.5x 1x 1.5x | RTF: 0.95   │   │
│  [Generate ▶]    │  └────────────────────────────┘   │
│  (sticky top)    │                                    │
│                  │  ┌────────────────────────────┐   │
│                  │  │ 音声カード 2               │   │
│                  │  │ ...                        │   │
│                  │  └────────────────────────────┘   │
│                  │                                    │
│  (scrollable)    │  (scrollable independently)        │
└──────────────────┴───────────────────────────────────┘
```

### 独立スクロールCSS

```css
.app {
    display: flex;
    height: 100vh;
    overflow: hidden;
}

.controls-panel {
    width: 380px;
    height: 100vh;
    overflow-y: auto;
    flex-shrink: 0;
}

.timeline-panel {
    flex: 1;
    height: 100vh;
    overflow-y: auto;
}
```

### プログレスバー推定

```javascript
// 推定生成時間 = (max_tokens / 12.5) * RTF
const estimatedDuration = (maxTokens / 12.5) * 1.5; // RTF 1.5想定

// ポーリングで進捗更新
async function pollTaskStatus(taskId, maxTokens) {
    const startTime = Date.now();
    const estimated = (maxTokens / 12.5) * 1.5 * 1000; // ms

    while (true) {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(95, (elapsed / estimated) * 100);

        // プログレスバー更新
        progressBar.style.width = `${progress}%`;

        const response = await fetch(`/api/task/${taskId}`);
        const task = await response.json();

        if (task.status === 'completed') {
            progressBar.style.width = '100%';
            break;
        }
        if (task.status === 'failed') {
            throw new Error(task.error);
        }

        await new Promise(r => setTimeout(r, 500));
    }
}
```

### 再生速度ボタン

```javascript
function setPlaybackRate(audio, rate) {
    audio.playbackRate = rate;

    // ボタンのアクティブ状態更新
    document.querySelectorAll('.speed-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.rate === String(rate));
    });
}
```

## APIエンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/` | フロントエンドHTML |
| GET | `/api/health` | ヘルスチェック |
| POST | `/api/generate` | TTS生成開始 |
| GET | `/api/task/{id}` | タスク状態取得 |
| GET | `/api/audio/{id}` | 音声ファイル取得 |
| GET | `/api/history` | 履歴一覧 |
| DELETE | `/api/history/{id}` | 履歴削除 |
| GET | `/api/queue` | キュー状態 |

## 実装のポイント

### 1. 非同期キュー処理

TTS生成はCPU/GPU集中処理のため、`run_in_executor` でイベントループをブロックしない。

```python
loop = asyncio.get_event_loop()
result = await loop.run_in_executor(None, lambda: ...)
```

### 2. 履歴永続化

`audio_history/metadata.json` に保存。LocalStorageではなくサーバー側で管理。

### 3. Generateボタン固定

左パネルのトップに固定配置し、スクロールしても常にアクセス可能に。

### 4. 左右独立スクロール

操作パネルと履歴パネルを個別にスクロール可能に。
