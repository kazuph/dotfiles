---
name: codex
description: Codex CLI を使って、ユーザーが明示的に望んだ調査・実装・レビューだけを補助的に実行する。Claude Code の主導権は維持し、乗っ取り的な委譲や危険な自動化は行わない。
argument-hint: "[investigate|implement|review] [prompt or options]"
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
user-invocable: true
context: fork
---

# Codex Skill

Codex CLI を Claude Code の補助として安全に使うためのスキル。

## 基本姿勢

- この skill は Claude Code の代替ではなく補助。ユーザーが `codex で` と明示した時だけ使う。
- Codex への丸投げや自動乗っ取りはしない。明示依頼なしで委譲しない。
- Stop hook、review gate、常駐フック、自動 install などの侵襲的な仕組みは持ち込まない。
- `--dangerously-bypass-approvals-and-sandbox` は禁止しない。ただし必要性と影響範囲を理解した上で、明示的に使う。
- 調査とレビューは必ず read-only。実装だけを明示依頼時に write で走らせる。
- 破壊的な git コマンドは提案しない。`git checkout -- .` や `git reset --hard` は禁止。
- Codex の出力はそのまま鵜呑みにせず、事実・推測・未確認点を分けて扱う。

## モード

### 1. 調査 `investigate`

コードベースの読取り調査、原因分析、設計確認、仕様確認に使う。

### コマンド

```bash
outfile=$(mktemp -t codex)
codex exec \
  --sandbox read-only \
  -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ディレクトリ指定あり

```bash
outfile=$(mktemp -t codex)
codex exec \
  --sandbox read-only \
  -C /path/to/dir \
  -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ポイント

- ファイル変更を許可しない。
- 調査プロンプトには「ファイル変更禁止」を明記する。
- 調査結果は「観測事実」「推測」「未確認点」を分けて返す。

### 2. 実装 `implement`

コード修正、最小安全パッチ、明示された実装作業にだけ使う。

### コマンド

```bash
outfile=$(mktemp -t codex)
codex exec \
  --full-auto \
  -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ディレクトリ指定あり

```bash
outfile=$(mktemp -t codex)
codex exec \
  --full-auto \
  -C /path/to/dir \
  -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ポイント

- 実装はユーザーが明示した時だけ。
- 巨大なリファクタや無関係変更は避け、「最小安全パッチ」を優先する。
- 実行後は必ず `git diff` で変更範囲を確認する。
- Codex が失敗したら、Claude 側で成功したふりをせず失敗として返す。

### 3. レビュー `review`

コードレビュー専用。レビュー結果から勝手に修正へ進まない。

### 未コミット変更のレビュー

```bash
codex review --uncommitted
```

### ブランチ差分のレビュー

```bash
codex review --base main
```

### 特定コミットのレビュー

```bash
codex review --commit <SHA>
```

### カスタム観点でレビュー

```bash
codex review --uncommitted \
  "セキュリティ観点でレビュー。XSS、権限漏れ、データ破壊リスクを重点確認"
```

### ディレクトリ指定あり

```bash
codex \
  -C /path/to/dir \
  review --base main
```

### ポイント

- レビュー結果は findings first で扱う。
- 重大度順、ファイルパス・行番号つきで返す。
- 推測なら推測と明示し、証拠境界を崩さない。
- レビュー後に自動修正へ進まない。直すなら別途 `implement` を明示実行する。

## 共通の実行方針

- モデルは固定しない。未指定なら Codex の既定を尊重する。
- モデルを明示する時だけ `-m <model>` を付ける。
- 作業ディレクトリを変える時だけ `-C /path/to/dir` を付ける。
- セッション永続化が不要なら `--ephemeral` を検討する。
- JSON Schema で出力形を縛りたい時だけ `--output-schema <file>` を使う。
- `tcgetattr` などの TTY 問題が出る環境では `script -q /dev/null ...` でラップする。

## Prompt の組み方

OpenAI 版から採る価値があるのは、プロンプトを短く構造化する考え方だけ。以下は採用してよい。

- 1回の Codex 実行には 1つの仕事だけ渡す。
- 「何をやるか」より先に「何が done か」を書く。
- 曖昧な長文より、短いブロック構造を優先する。
- 調査・研究・レビューでは根拠を要求する。
- 実装・デバッグでは検証条件を明示する。

### 推奨ブロック

```xml
<task>具体的な依頼</task>
<output_contract>欲しい出力の形</output_contract>
<safety>触ってよい範囲、触ってはいけない範囲</safety>
<verification>何を確認して完了とするか</verification>
```

### 例: investigate

```xml
<task>この不具合の根本原因を調べて。ファイル変更は禁止。</task>
<output_contract>観測事実、推測、未確認点を分けて簡潔に返す。</output_contract>
<verification>関連ファイルと実際のコード断片に基づいて説明する。</verification>
```

### 例: implement

```xml
<task>この不具合を最小安全パッチで修正して。</task>
<safety>無関係なリファクタ禁止。既存挙動を壊さない。</safety>
<verification>変更ファイル、実施した確認、残るリスクを最後に列挙する。</verification>
```

### 例: review

```xml
<task>この差分をレビューして。</task>
<output_contract>findings first。重大度順。ファイルパスと行番号を含める。</output_contract>
<verification>根拠が弱いものは推測として明示する。</verification>
```

## 引数パターン

| 呼び出し | 動作 |
|---------|------|
| `/codex investigate <prompt>` | 読み取り調査 |
| `/codex implement <prompt>` | 明示依頼された実装 |
| `/codex review` | 未コミット変更レビュー |
| `/codex review --base main` | ブランチ差分レビュー |

引数の最初の語が `investigate` / `implement` / `review` でモードを判別する。

## 4. Browser Operations `browser`

Use Codex with a lightweight model (o4-mini / Spark) for browser automation tasks.
Opus is too slow for interactive browser work — delegate to Codex first, escalate only on failure.

### Command

```bash
outfile=$(mktemp -t codex)
codex exec \
  --full-auto \
  -m o4-mini \
  -o "$outfile" \
  "<browser task prompt>" >/dev/null 2>&1
cat "$outfile"
```

### With directory and browser-use CLI

```bash
outfile=$(mktemp -t codex)
codex exec \
  --full-auto \
  -m o4-mini \
  -o "$outfile" \
  "Use browser-use CLI to: open http://localhost:3000, take a screenshot to /tmp/result.png, then close. Report what you see on the page." >/dev/null 2>&1
cat "$outfile"
```

### When to use

- Page content verification, screenshot collection, form testing
- Any browser interaction where speed matters more than deep reasoning
- Smoke-testing a deployed or local web app

### When NOT to use (escalate to Opus)

- Complex multi-step workflows requiring judgment calls
- Debugging subtle UI/UX issues that need visual reasoning
- Tasks where the Spark model has already failed

### Prompt template

```xml
<task>Use browser-use CLI to verify the login flow on http://localhost:3000</task>
<output_contract>Screenshot saved to .artifacts/feature/login.png. Report: page title, visible elements, any errors.</output_contract>
<safety>Do not modify any code. Browser interaction only.</safety>
<verification>Screenshot exists and shows expected page state.</verification>
```

## Divergent Thinking Mode

When Claude Code consults Codex for planning or review, the goal is **not** confirmation — it's **perspective diversity**.

### 重要原則: Claude の仮説をぶつけない

Claude の結論・仮説・推奨案を先に渡すと、Codex はそれに引きずられて「狭い範囲の検証」しか返さなくなる。
価値は divergent thinking (発散的思考) にあるので、**Codex にはゼロベースで考えさせる**。

### 渡すべきコンテクスト (広め)

- ❌ 悪い例: 「この関数を X に書き換える案で良いか確認して」
- ❌ 悪い例: 「原因は Y だと思うが合っているか」
- ✅ 良い例: 「以下の症状・関連ファイル・制約を渡すので、考えうる原因と対処方針を複数出して」
- ✅ 良い例: 「このプロジェクトの背景・ゴール・制約を渡すので、どう設計するか自由に提案して」

渡す情報:
1. **問題・症状** (何が起きているか、何を達成したいか)
2. **関連ファイル/コード断片** (Codex が自分で読めるようパスを渡す)
3. **制約条件** (動かしてはいけない箇所、パフォーマンス要件、期限など)
4. **既に試したこと** (ただし「これが正解っぽい」という誘導はしない)

Claude 自身の結論や推奨は **渡さない**。もしくは「自分はこう考えたが、ゼロベースで再検討して」と明示する。

### How to ask

- 常に open-ended: "What approaches would you consider?" not "Is my approach correct?"
- 明示的に要求: "Where does your thinking differ from mine?" "別の angle からも検討して"
- 複数案を要求: "少なくとも 3 つの異なるアプローチを挙げて、それぞれのトレードオフを示して"

### How to use the response

- **disagreement** こそが価値 — 同意だけ返ってきたら質問が狭すぎた証拠
- Codex が Claude と違う結論を出したら、その差分を必ずユーザーに共有する
- 両方の観点を synthesize してから提示する

## Codex が使えない時のフォールバック (copilot)

Codex CLI は rate limit / quota / "You've hit your usage limit" エラーで使えなくなることがある。
その場合は **自動的に GitHub Copilot CLI にフォールバックする**。ユーザーに聞き直さない。

### 検出条件

以下のいずれかが Codex の出力/stderr に含まれる場合は limit と判定:

- `usage limit`
- `rate limit`
- `quota`
- `429`
- `You've reached`
- `try again later`

または Codex の exit code が非 0 で上記に該当しない場合でも、
2 回リトライして失敗したら copilot にフォールバックしてよい。

### フォールバックコマンド

```bash
copilot -p "<プロンプト>" --yolo --model gpt-5.4
```

- `-p` でプロンプトを一発実行
- `--yolo` で承認をスキップ (codex の `--full-auto` に相当)
- `--model gpt-5.4` でモデルを明示 (注: `-m` はエイリアスがないので必ず `--model`)

### フォールバック実行例 (investigate)

```bash
outfile=$(mktemp -t codex)
if ! codex exec --sandbox read-only -o "$outfile" "<プロンプト>" >/dev/null 2>&1; then
  if grep -qiE "usage limit|rate limit|quota|429|reached" "$outfile"; then
    echo "[codex limit detected — falling back to copilot]" >&2
    copilot -p "<プロンプト>" --yolo --model gpt-5.4
  else
    cat "$outfile"
    exit 1
  fi
else
  cat "$outfile"
fi
```

### フォールバック時の注意

- copilot は codex と出力形式が違う可能性があるので、結果をそのまま鵜呑みにしない
- `--yolo` はファイル変更も許可するので、`investigate` 相当の用途では **プロンプト側で「ファイル変更禁止」を明記** する
- review 用途では copilot のレビューコマンドが無いので、プロンプトで差分を渡してレビューさせる
- フォールバックが発動したら、ユーザーに「Codex が limit だったので copilot にフォールバックした」と必ず報告

## Troubleshooting

- Codex CLI not found: `codex --version`
- Not logged in: `codex login`
- TTY issues: `script -q /dev/null ...`
- Timeout: split the task and retry
- Verbose output: use `-o "$outfile"` or `--output-schema`
