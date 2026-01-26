---
name: reporting-and-tmux
description: 【タスク完了時に必ず実行】sayで音声報告＋tmuxウィンドウ名を更新するSkill。ユーザーへの完了通知に必須。実装・修正・調査などあらゆるタスク終了後に使うこと。
allowed-tools: Shell
---

# Reporting and tmux Workflow

## ClaudeCodeサブエージェント方針
- ステータス: ⚪ 任意（メインエージェントで即時実行するのが基本）
- 理由: `say`報告やtmuxリネームは最終回答の直後に走らせる必要があり、サブエージェント経由だと報告タイミングが遅れる。
- メモ: 他タスクと並列で練習する場合のみサブエージェントを立て、実際の本番報告はメインエージェントから直接行う。

## say報告

1. 最終回答の直後に必ず1回だけ `say` を実行する（ユーザーから依頼がなくても強制）。
2. `tmux display-message -p -t "$TMUX_PANE" '#I'` で取得したウィンドウIDをメッセージ先頭に `Window <ID> ` 形式で付ける。
3. `say -r ${SAY_RATE:-230}` など速度220以上で実行し、`-o`は使わない。タイムアウトは無視してよいが `timeout_ms>=6000` で投機実行する。
4. メッセージは毎回内容を変え、軽い挨拶と完了要約を含めて60文字・6秒以内を目安にする。否定的な感嘆（やれやれ等）は避ける。

### 実行例
```
say -r 230 "Window 2 タスク完了。要約と挨拶を添えて報告します。"
```

## tmuxウィンドウ命名

1. 自分のpane/windowを操作するときは必ず `-t "$TMUX_PANE"` を付け、`tmux display-message -p -t "$TMUX_PANE" '#D'` で取得したペインID(%)を一度だけ取得して使う。
2. 作業完了時に`~/.claude/skills/reporting-and-tmux/rename_tmux_window.sh "調査完了🔍"`のように「漢字+絵文字」の短い識別子を渡して実行する。
3. スクリプトが1階層のディレクトリ名を取得し、`[<dir>] <ラベル>`形式へ統一する。
4. 角括弧や半角スペースを追加しない。指示された漢字＋絵文字のみを末尾に渡す。

### 動作確認コマンド
```
bash ~/.claude/skills/reporting-and-tmux/rename_tmux_window.sh "検証完了✨"
```

## OSC 0更新

1. 作業中にタイトルを更新したい場合のみOSC 0を送信し、tmuxのpane/window名は触らない。
2. 空送信は禁止。必ず内容付きで送る。
3. **末尾に現在のブランチ名を `(branch-name)` 形式で付ける**。ブランチ名は `git rev-parse --abbrev-ref HEAD 2>/dev/null` で取得。
4. タスク完了時も内容付きで送信し、空クリアを行わない。

### OSC 0送信例
```bash
pane_tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}')
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")
printf '\033]0;◆ Codex: 状況 (%s)\007' "$branch" > "$pane_tty"
```

### 完了時の例
```bash
printf '\033]0;◆ Codex: 完了サマリ (%s)\007' "$branch" > "$pane_tty"
```

上記手順を守ることで報告とウィンドウ管理を自動化しつつ、CLAUDE.md本文を最小化する。
