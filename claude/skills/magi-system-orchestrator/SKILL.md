---
name: magi-system-orchestrator
description: Multi-AI (Claude/Codex/Gemini) deliberation skill with strict availability checks and structured outputs.
allowed-tools:
  - Task
  - Shell
  - Read
---

# MAGI System Orchestrator Skill

## ⚠️ 重要: 必ず専用エージェントを使用すること

**MAGIを使う場合は、現在のコンテキストで直接実行しないでください。**

必ず `Task` ツールで `magi-system-orchestrator` エージェントを起動してください：

```
Task(subagent_type="magi-system-orchestrator", prompt="<依頼内容>")
```

理由:
- 現在のコンテキストで実行すると、大量のCLI出力でトークンが爆発する
- 専用エージェントなら、完了後に要約だけをメインへ返せる
- 並列CLI実行のセッション管理が安定する

## ClaudeCodeサブエージェント方針
- ステータス: ✅ 必須（ClaudeCodeサブエージェントで起動）
- 理由: Codex/Gemini/Claudeの多視点協調を行う際に大量のCLIとログを並列で扱うため、専用サブエージェントでセッションを固定しないと手順崩壊につながる。
- メモ: サブエージェント内で可用性チェック→ペルソナ投入→統合→ログ整理までをワンセットとして扱い、完了後に要約だけをメインへ返す。

## エージェント起動時の必須事項

**magi-system-orchestratorエージェントとして起動された場合、必ずこのスキルファイルを最初に読み込むこと。**

```
Read("/Users/kazuph/.claude/skills/magi-system-orchestrator/SKILL.md")
```

スキルを読まずに実行すると、CLIパターンやトークン削減手法が適用されず、非効率な実行になる。

MAGIは複雑な意思決定や多視点レビューのための標準オペレーションです。このSkillを参照し、長文のエージェント定義の代わりにここで定義された手順とテンプレートを読み込んでください。

## 使うべきケース

- 大規模アーキテクチャ選定・投資判断・複数案比較のように、単独エージェントでは偏りが出るタスク。
- ユーザーから「MAGI」「多視点レビュー」「Codex/Geminiも巻き込んで」などの明示的な依頼があるとき。
- 実装フェーズでも根本方針を伴う場合（単純なbugfixなら通常Claudeで十分）。

## 実行フロー概要

1. **ゴール把握**: 予算/制約/成功指標を聞き出し、揃わなければ Stop-if-Unclear を発動。
2. **可用性チェック**: Codex/GPT-5とGeminiのCLIを同時に立ち上げられるか疎通（`docs/PLAYBOOK.md`参照）。`exec` モード（codex）やワンショットモード（gemini）では `script` ラッパー不要。Claude CLIは `CLAUDECODE=` で環境変数をクリアして実行。
3. **フェーズ1**: 3ペルソナを並列実行し、互いに参照させずに初期アウトプットを取得。
4. **フェーズ2**: Geminiが統合プランをまとめ、共通点・トレードオフ・リスク・フォローアップを整理。
5. **セルフチェック**: `docs/CHECKLIST.md`に沿って検証し、満たせない場合は理由を報告。

詳細手順・CLIルールは `docs/PLAYBOOK.md` を参照。

## CLIチートシート

| Persona | コマンド例 |
| --- | --- |
| Codex/GPT-5 | `outfile=$(mktemp -t codex); command codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox exec --skip-git-repo-check --full-auto -o "$outfile" "<prompt>" >/dev/null 2>&1; cat "$outfile"` |
| Gemini | `outfile="/tmp/gemini_$$"; /opt/homebrew/bin/mise exec -- gemini --approval-mode=yolo -o json "<prompt>" 2>/dev/null \| jq -r '.response' > "$outfile"; cat "$outfile"` |
| Claude (ゴール整備) | `CLAUDECODE= command claude --dangerously-skip-permissions --print "<prompt>"` |
※ `script -q /dev/null` は不要。`exec`/ワンショットモードではTTYラッパーなしで動作する。標準出力モードで実行し、会話状態は期待しないこと。

- 2系統以上のCLI経路を準備し、いずれかが落ちたら即時Abort。
- 同期処理は禁止。すべて並列またはできるだけ同時に走らせる。

## トークン削減パターン（推奨）

各CLIから**最終メッセージのみ取得**するパターン。`script -q /dev/null` は不要（exec/ワンショットモードではTTY不要）。

### Codex: `-o` オプションで最終メッセージのみファイルに出力

```bash
outfile=$(mktemp -t codex)
command codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check --full-auto -o "$outfile" "<prompt>" >/dev/null 2>&1
cat "$outfile"
```

- `command codex` でエイリアスをバイパス（エイリアスとフラグが重複すると失敗する）
- `>/dev/null 2>&1` でstdoutのログを抑制しつつ `-o` のファイル出力は維持される
- `--full-auto` で書き込み権限を付与（読み取り専用にする場合は外す）

### Gemini: `-o json` + `jq` で最終応答のみ抽出

```bash
outfile="/tmp/gemini_$$"
/opt/homebrew/bin/mise exec -- gemini \
  --approval-mode=yolo -o json "<prompt>" 2>/dev/null \
  | jq -r '.response' > "$outfile"
cat "$outfile"
```

- `-o json` で構造化出力。`.response` フィールドに最終応答のみ格納される
- `-p` フラグは非推奨。位置引数（positional prompt）を使う
- 思考トークン・stats・session_idは `jq` で除外される

### Claude: `--print` で最終応答のみ出力

```bash
CLAUDECODE= command claude --dangerously-skip-permissions --print "<prompt>"
```

- `CLAUDECODE=` でネストセッション検出をバイパス（サブエージェント内から呼ぶ場合に必須）

### 共通の利点
- 返却トークン = 最終エージェントメッセージのみ（ログ・途中経過・思考トークンを除外）
- `mktemp -t` でユニークなファイル名を生成するため並列実行でも安全
- `/tmp` 配下のファイルはmacOSが自動クリーンアップするため明示的削除不要

## 出力フォーマット（Compact方式）

必ず `docs/OUTPUT_TEMPLATE.md` の雛形を使い、以下を満たしてください。

**メインセッションへの返却は最小限に。生ログは返さない。**

- MAGI VERDICTにGoal（40字以内）+ Verdict（1文）+ Confidence
- PERSONA VOTESは1行×3ペルソナのテーブル形式（推奨/信頼度/リスク各1行）
- Consensus/Conflictは各1行のみ
- Action Planは最大5ステップ、各ステップ1アクション + 1検証
- 各ペルソナの生分析は `runtime/` に保存し、返却メッセージには含めない
- **全体で200トークン以内を目標**: メインセッションのコンテキストを汚染しない

## 実装タスク時のルール

- Codex/Geminiは必要なdiffやテストログをその場で提示する。
- Claudeはゴール整備と整合性確認に専念。必要に応じてTaskツールで追加コマンドを実行。

## ログと証跡の扱い

- `runtime/` 以下に `magi-<timestamp>-<persona>.log` などの形で各出力を保存しておくと後から参照しやすい。
- リトライやAbort理由はログに必ず残し、最終報告で引用できるようにする。

## クリーンアップ手順（必須）

1. 実行に使用したCodex/GPT-5・Gemini CLIプロセスが残っていないか `ps` で確認し、必要なら安全に終了。
2. `runtime/` 以下に残したログで不要なものがあれば `rm magi-system-orchestrator/runtime/*.log` などで明示的に削除。  
   - 重要ログは残す。削除対象を確定させてから`rm`を実行。
3. tmuxタイトルやOSC 0をリセットし、MAGI固有のモニタリングがあれば停止。

## トラブルシューティング

- **Codex or Gemini unreachable**: 即Abortし、再試行コマンド・ログを添えて報告。
- **テンプレ違反**: `docs/OUTPUT_TEMPLATE.md`を再参照し、不足要素を追記。
- **並列性崩壊**: 実行ログにタイムスタンプを残して並列性を示す。難しければタスクをリスケ。

このSkillを読み込むことで、エージェント定義に過度なテキストを持ち込まずにMAGI運用を再現できます。
