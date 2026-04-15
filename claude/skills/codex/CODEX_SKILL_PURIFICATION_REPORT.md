# Codex Skill Purification Report

## 1. 目的の再定義

もともとの skill は「Codex を使う統合スキル」という説明で、Claude Code の主導権と補助関係が曖昧でした。ここでは、Codex を補助役として限定し、ユーザーが明示的に求めた調査・実装・レビューだけを扱う方針に変えました。

```diff
--- a/plugins/kazuph-dotfiles/skills/codex/SKILL.md
+++ b/plugins/kazuph-dotfiles/skills/codex/SKILL.md
@@
-description: Codex CLI (GPT-5) を使って調査・実装・レビューを実行する。「codexで調べて」「codexに実装させて」「codexでレビュー」等で自動発動。
+description: Codex CLI を使って、ユーザーが明示的に望んだ調査・実装・レビューだけを補助的に実行する。Claude Code の主導権は維持し、乗っ取り的な委譲や危険な自動化は行わない。
@@
-Codex CLI を使って3種類のタスクを実行する統合スキル。
+Codex CLI を Claude Code の補助として安全に使うためのスキル。
```

## 2. 危険な設計の排除と、安全境界の明文化

OpenAI 版に見られた「明示依頼なしでも委譲」「hook や gate の持ち込み」といった侵襲的な方向は除去しました。一方で、今回の依頼に合わせて `--dangerously-bypass-approvals-and-sandbox` は全面禁止ではなく、必要性を理解した上で明示的に使う扱いへ戻しています。

```diff
--- a/plugins/kazuph-dotfiles/skills/codex/SKILL.md
+++ b/plugins/kazuph-dotfiles/skills/codex/SKILL.md
@@
-## 共通ルール
+## 基本姿勢
@@
-**TTY必須**: 全コマンドを `script -q /dev/null` でラップ（ないと `tcgetattr` エラー）
-**モデル固定**: `exec` は `-m gpt-5.3-codex-spark`、`review` は `-c model="gpt-5.3-codex-spark"` を指定（reviewに `-m` フラグはない）
-**サンドボックス**: `--sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox`
-**出力抑制（exec系）**: `>/dev/null 2>&1` + `-o "$outfile"` で最終メッセージのみ取得（トークン節約）
+- この skill は Claude Code の代替ではなく補助。ユーザーが `codex で` と明示した時だけ使う。
+- Codex への丸投げや自動乗っ取りはしない。明示依頼なしで委譲しない。
+- Stop hook、review gate、常駐フック、自動 install などの侵襲的な仕組みは持ち込まない。
+- `--dangerously-bypass-approvals-and-sandbox` は禁止しない。ただし必要性と影響範囲を理解した上で、明示的に使う。
+- 調査とレビューは必ず read-only。実装だけを明示依頼時に write で走らせる。
+- 破壊的な git コマンドは提案しない。`git checkout -- .` や `git reset --hard` は禁止。
+- Codex の出力はそのまま鵜呑みにせず、事実・推測・未確認点を分けて扱う。
```

## 3. 調査と実装の境界整理

以前は `workspace-write` と危険フラグが全面に出ていて、調査と実装の境界が弱い状態でした。そこで、調査は常に read-only、実装は明示依頼時だけ `--full-auto`、という役割分離に整理しました。

```diff
--- a/plugins/kazuph-dotfiles/skills/codex/SKILL.md
+++ b/plugins/kazuph-dotfiles/skills/codex/SKILL.md
@@
-## 1. 調査 (investigate)
-コードベースの調査・分析。読み取り専用（`--full-auto` なし）。
+### 1. 調査 `investigate`
+コードベースの読取り調査、原因分析、設計確認、仕様確認に使う。
@@
-script -q /dev/null codex \
-  --sandbox workspace-write \
-  --config sandbox_workspace_write.network_access=true \
-  --dangerously-bypass-approvals-and-sandbox \
-  exec --skip-git-repo-check -m gpt-5.3-codex-spark -o "$outfile" \
+codex exec \
+  --sandbox read-only \
+  -o "$outfile" \
@@
-## 2. 実装 (implement)
-コードの実装・修正。書き込み有効（`--full-auto` 付き）。
+### 2. 実装 `implement`
+コード修正、最小安全パッチ、明示された実装作業にだけ使う。
@@
-script -q /dev/null codex \
-  --sandbox workspace-write \
-  --config sandbox_workspace_write.network_access=true \
-  --dangerously-bypass-approvals-and-sandbox \
-  exec --skip-git-repo-check --full-auto -m gpt-5.3-codex-spark -o "$outfile" \
+codex exec \
+  --full-auto \
+  -o "$outfile" \
```

## 4. レビューを「読むだけ」に戻した

OpenAI 側の良い部分として、レビュー結果の厳密な扱いは残しました。ただし、レビューからそのまま修正に雪崩れ込む流れは切り、findings first と証拠境界の維持を中心に再構成しています。

```diff
--- a/plugins/kazuph-dotfiles/skills/codex/SKILL.md
+++ b/plugins/kazuph-dotfiles/skills/codex/SKILL.md
@@
-## 3. レビュー (review)
-コードレビュー。`codex review` サブコマンドを使用。
+### 3. レビュー `review`
+コードレビュー専用。レビュー結果から勝手に修正へ進まない。
@@
-script -q /dev/null codex \
-  --sandbox workspace-write \
-  --config sandbox_workspace_write.network_access=true \
-  --dangerously-bypass-approvals-and-sandbox \
-  review --uncommitted -c model="gpt-5.3-codex-spark" 2>&1
+codex review --uncommitted
@@
-review --base develop -c model="gpt-5.3-codex-spark" 2>&1
+review --base main
@@
- レビュー後に自動修正へ進まない。直すなら別途 `implement` を明示実行する。
+- レビュー結果は findings first で扱う。
+- 重大度順、ファイルパス・行番号つきで返す。
+- 推測なら推測と明示し、証拠境界を崩さない。
+- レビュー後に自動修正へ進まない。直すなら別途 `implement` を明示実行する。
```

## 5. 残した価値は prompt contract だけ

OpenAI 版から残した価値は、プロンプトを短く構造化する考え方です。ここだけは再利用しつつ、Claude の主導権を奪う命令系ではなく、依頼の精度を上げるためのガイドとして組み直しました。

```diff
--- a/plugins/kazuph-dotfiles/skills/codex/SKILL.md
+++ b/plugins/kazuph-dotfiles/skills/codex/SKILL.md
@@
+## Prompt の組み方
+
+OpenAI 版から採る価値があるのは、プロンプトを短く構造化する考え方だけ。以下は採用してよい。
+
+- 1回の Codex 実行には 1つの仕事だけ渡す。
+- 「何をやるか」より先に「何が done か」を書く。
+- 曖昧な長文より、短いブロック構造を優先する。
+- 調査・研究・レビューでは根拠を要求する。
+- 実装・デバッグでは検証条件を明示する。
+
+### 推奨ブロック
+
+```xml
+<task>具体的な依頼</task>
+<output_contract>欲しい出力の形</output_contract>
+<safety>触ってよい範囲、触ってはいけない範囲</safety>
+<verification>何を確認して完了とするか</verification>
+```
```
