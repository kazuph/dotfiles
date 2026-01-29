---
name: magi-system-orchestrator
description: Multi-AI (Claude/Codex/Gemini) deliberation skill with strict availability checks and structured outputs.
allowed-tools:
  - Task
  - Bash
  - Read
  - Write
  - Glob
  - Grep
user-invocable: true
---

# MAGI System Orchestrator Skill

## 重要: 必ず専用エージェントを使用すること

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
- ステータス: 必須（ClaudeCodeサブエージェントで起動）
- 理由: Codex/Gemini/Claudeの多視点協調を行う際に大量のCLIとログを並列で扱うため、専用サブエージェントでセッションを固定しないと手順崩壊につながる。
- メモ: サブエージェント内で可用性チェック→ペルソナ投入→統合→ログ整理までをワンセットとして扱い、完了後に要約だけをメインへ返す。

## エージェント起動時の必須事項

**magi-system-orchestratorエージェントとして起動された場合、このスキルの内容に従って実行すること。**

スキルを読まずに実行すると、CLIパターンやトークン削減手法が適用されず、非効率な実行になる。

MAGIは複雑な意思決定や多視点レビューのための標準オペレーションです。このSkillを参照し、長文のエージェント定義の代わりにここで定義された手順とテンプレートを読み込んでください。

## 使うべきケース

- 大規模アーキテクチャ選定・投資判断・複数案比較のように、単独エージェントでは偏りが出るタスク。
- ユーザーから「MAGI」「多視点レビュー」「Codex/Geminiも巻き込んで」などの明示的な依頼があるとき。
- 実装フェーズでも根本方針を伴う場合（単純なbugfixなら通常Claudeで十分）。

## 実行フロー概要

1. **ゴール把握**: 予算/制約/成功指標を聞き出し、揃わなければ Stop-if-Unclear を発動。
2. **可用性チェック**: Codex/GPT-5とGeminiのCLIを同時に立ち上げられるか疎通（`docs/PLAYBOOK.md`参照）。必ず `script -q /dev/null` で疑似TTYを確保して実行する（TTY無しは失敗する）。
3. **フェーズ1**: 3ペルソナを並列実行し、互いに参照させずに初期アウトプットを取得。
4. **フェーズ2**: Geminiが統合プランをまとめ、共通点・トレードオフ・リスク・フォローアップを整理。
5. **セルフチェック**: `docs/CHECKLIST.md`に沿って検証し、満たせない場合は理由を報告。

詳細手順・CLIルールは `docs/PLAYBOOK.md` を参照。

## CLIチートシート

| Persona | コマンド例 |
| --- | --- |
| Codex/GPT-5 | `outfile=$(mktemp -t codex); script -q /dev/null codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox exec --skip-git-repo-check -o "$outfile" "<prompt>" >/dev/null 2>&1; cat "$outfile"` |
| Codex/GPT-5 (書込み有) | `outfile=$(mktemp -t codex); script -q /dev/null codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox exec --skip-git-repo-check --full-auto -o "$outfile" "<prompt>" >/dev/null 2>&1; cat "$outfile"` |
| Gemini | `script -q /dev/null /opt/homebrew/bin/mise exec -- gemini --approval-mode=yolo -p "<prompt>"` |
| Claude (ゴール整備) | `script -q /dev/null claude --dangerously-skip-permissions --print "<prompt>"` |
※ any-script等のラッパーは使わず、TTY付きで直接叩く。標準出力モードで実行し、会話状態は期待しないこと。

- 2系統以上のCLI経路を準備し、いずれかが落ちたら即時Abort。
- 同期処理は禁止。すべて並列またはできるだけ同時に走らせる。

## トークン削減パターン（推奨）

Codex execの出力は大量のログを含むため、**最終メッセージのみ取得**するパターンを使用する：

```bash
# Codex: -o オプションで最終メッセージのみファイルに出力（サンドボックス完全バイパス）
outfile=$(mktemp -t codex)
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check -o "$outfile" "<prompt>" >/dev/null 2>&1
cat "$outfile"
# ファイルは /var/folders 配下に作成され、macOSが自動クリーンアップするため rm 不要
```

**利点:**
- 返却トークン = 最終エージェントメッセージのみ（ログ・途中経過を除外）
- `mktemp -t` でユニークなファイル名を生成するため並列実行でも安全
- `rm` 不要（認証ダイアログ回避、macOSの自動クリーンアップに任せる）

**注意:** Gemini CLIには同等のオプションがないため、従来通り `| tail` 等で対応する。

## 出力フォーマット

必ず `docs/OUTPUT_TEMPLATE.md` の雛形を使い、以下を満たしてください。

- Situation Snapshotにゴール/制約/成功指標を明記。
- 各ペルソナのActionable Insightsは3件、`Action – Tool/Owner – Success Check`形式。
- Unified Action Planは3ステップ以上で、各ステップにETAと検証方法を付与。
- リスク1件・フォローアップ質問1件。

## 実装タスク時のルール

- Codex/Geminiは必要なdiffやテストログをその場で提示する。
- Claudeはゴール整備と整合性確認に専念。必要に応じてTaskツールで追加コマンドを実行。

## ログと証跡の扱い

- `runtime/` 以下に `magi-<timestamp>-<persona>.log` などの形で各出力を保存しておくと後から参照しやすい。
- リトライやAbort理由はログに必ず残し、最終報告で引用できるようにする。

## クリーンアップ手順（必須）

1. 実行に使用したCodex/GPT-5・Gemini CLIプロセスが残っていないか `ps` で確認し、必要なら安全に終了。
2. `runtime/` 以下に残したログで不要なものがあれば明示的に削除。
   - 重要ログは残す。削除対象を確定させてから削除を実行。
3. tmuxタイトルやOSC 0をリセットし、MAGI固有のモニタリングがあれば停止。

## トラブルシューティング

- **Codex or Gemini unreachable**: 即Abortし、再試行コマンド・ログを添えて報告。
- **テンプレ違反**: `docs/OUTPUT_TEMPLATE.md`を再参照し、不足要素を追記。
- **並列性崩壊**: 実行ログにタイムスタンプを残して並列性を示す。難しければタスクをリスケ。

このSkillを読み込むことで、エージェント定義に過度なテキストを持ち込まずにMAGI運用を再現できます。
