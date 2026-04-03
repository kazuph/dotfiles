---
name: pr
description: worktreeからPR作成→push→CI監視→失敗修正→Copilotレビュー対応まで自律完結するフロー。「/pr」「PRを作成して」「PR出して」で発動。
user_invocable: true
---

# PR 自律完結フロー

worktreeでの実装完了後、PR作成からレビュー対応まで全て自律的に完結させる。
途中でユーザーに確認を求めない。全部終わってから報告する。

## 前提条件

- `gh` 認証済み
- worktree内で作業中（`git wt` で作成済み）
- 実装・ビルド・テストが完了済み

## フロー

### 1. 事前確認

```bash
# 現在のブランチとworktree確認
git branch --show-current
git status

# 未コミットの変更があればコミット（prettier実行後）
npx prettier --write <changed-files>
git add <files> && git commit -m "..."

# ビルド確認
npm run build
```

### 2. Push & PR作成

```bash
# 初回push（-u でトラッキング設定）
git push -u origin <branch-name>

# 2回目以降のpush（カレントブランチのみ）
git push origin HEAD

# PR作成（developベース）
gh pr create --base develop --head <branch-name> \
  --title "..." \
  --body "$(cat <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**重要**: `git push` ではなく必ず `git push origin HEAD` を使う。worktreeで `git push` するとdevelopもpush試行してエラーになる。

### 3. CI監視

**`sleep` で待たない。`--watch` をバックグラウンドで実行し、完了通知を受け取る。**

```bash
# バックグラウンドでCI完了を監視（run_in_background: true で実行）
gh pr checks <PR番号> --watch

# 完了通知を受け取ったら結果を確認
gh pr checks <PR番号>

# 失敗していたらログ確認
gh run view <run-id> --log-failed | tail -40
```

- `gh pr checks --watch` は全チェックが完了するまでブロックする。`run_in_background: true` で実行し、完了通知が来たら次に進む
- 待機中は他の作業（Copilotレビューコメントの事前確認など）を進めてよい
- **CI失敗時**: ログを読んで原因特定→修正→`npx prettier --write`→コミット→`git push origin HEAD`→再度CI監視
- **全パスするまで繰り返す**

### 4. Copilotレビュー対応

```bash
# CIパス後、レビューコメントを確認（CIパス後30-90秒で付く）
# こちらもバックグラウンドで待機してよい
gh api repos/{owner}/{repo}/pulls/<PR番号>/comments \
  --jq '.[] | "[\(.path):\(.line)] \(.body[0:200])"'
```

- **指摘があれば**: 全件修正→コミット→push→CI再監視
- **各コメントに返信**: `gh api repos/{owner}/{repo}/pulls/<PR番号>/comments/<id>/replies -f body="対応済み。"`
- **追加指摘がなくなるまで繰り返す**

### 5. ローカル検証（ブラウザ確認が必要な場合）

ローカルのdevサーバー（worktree内で `npm run dev:app`）でブラウザ確認。
Preview環境のデプロイを待つ必要はない。

### 6. 完了報告

全て終わったら以下を含めて報告:

```
PR #XX: <URL>

| 項目 | 状態 |
|------|------|
| CI | 全チェックパス |
| Copilotレビュー | N件対応済み / 追加指摘なし |
| テスト | N件パス |
| 検証 | ローカル/Preview で確認済み |
```

## 禁止事項

- 途中で「CIが通ったらやる？」「レビュー対応する？」と聞かない
- Preview環境のデプロイ待ちでブロックしない（ローカルで検証）
- `git push` を使わない（`git push origin HEAD` を使う）
- `sleep` でCI/レビュー完了を待たない（`gh pr checks --watch` + `run_in_background` を使う）
- CI失敗を放置しない
- Copilotの指摘を無視しない
