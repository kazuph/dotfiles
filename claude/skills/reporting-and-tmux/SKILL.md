---
name: reporting-and-tmux
description: 【タスク完了時に必ず実行】sayで音声報告＋tmuxウィンドウ名を更新するSkill。ユーザーへの完了通知に必須。実装・修正・調査などあらゆるタスク終了後に使うこと。
allowed-tools: Bash
---

# Reporting and tmux Workflow

## ClaudeCodeサブエージェント方針
- ステータス: ⚪ 任意（メインエージェントで即時実行するのが基本）
- 理由: `say`報告やtmuxリネームは最終回答の直後に走らせる必要があり、サブエージェント経由だと報告タイミングが遅れる。

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

1. 自分のpane/windowを操作するときは必ず `-t "$TMUX_PANE"` を付ける。
2. 作業完了時に、このスキルと同じディレクトリにある `rename_tmux_window.sh` を実行する。
3. **引数にタスク概要を日本語漢字2-3文字で渡す**。スクリプトが `<リポジトリ名>-<タスク概要>` 形式でウィンドウ名を設定する。
4. 引数なしの場合はリポジトリ名のみ設定される。
5. リポジトリ名は `git rev-parse --show-toplevel` のbasenameから自動取得（git外ならPWDのbasename）。
6. 角括弧、進捗ラベル、余計な半角スペースは追加しない。

### 命名例
- `reviw-認証実装` （reviwリポジトリで認証機能を実装中）
- `mimamorin-web-修正` （mimamorin-webリポジトリでバグ修正中）
- `dotfiles-設定` （dotfilesリポジトリで設定変更中）

### 実行例
```bash
# <BASE_DIR> はSkill実行時に「Base directory for this skill:」として表示されるパス
bash <BASE_DIR>/rename_tmux_window.sh "認証実装"
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
