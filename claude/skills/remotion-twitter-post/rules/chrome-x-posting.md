---
name: chrome-x-posting
description: Chrome拡張を使ったX(Twitter)投稿の完全手順
metadata:
  tags: chrome, x, twitter, posting, automation
---

# Chrome拡張でX投稿（完全手順）

## 前提条件

- Claude in Chrome拡張がインストール済み
- Chromeが起動中

## 手順1: ツール読み込み

**必ずこの順序で読み込む:**

```
ToolSearch: select:mcp__claude-in-chrome__tabs_context_mcp
ToolSearch: select:mcp__claude-in-chrome__navigate
ToolSearch: select:mcp__claude-in-chrome__read_page
ToolSearch: select:mcp__claude-in-chrome__computer
```

## 手順2: タブ情報取得

```
mcp__claude-in-chrome__tabs_context_mcp(createIfEmpty: true)
```

**レスポンス例:**
```json
{"availableTabs":[{"tabId":1594803532,"title":"New Tab","url":"chrome://newtab"}]}
```

→ `tabId: 1594803532` をメモ

## 手順3: Xホームへ移動

```
mcp__claude-in-chrome__navigate(
  url: "https://x.com/home",
  tabId: 1594803532
)
```

## 手順4: 投稿フォーム要素を取得

```
mcp__claude-in-chrome__read_page(
  tabId: 1594803532,
  filter: "interactive",
  depth: 10
)
```

**探すべき要素:**
```
textbox "ポスト本文" [ref_XX]
```

## 手順5: フォームをクリック

```
mcp__claude-in-chrome__computer(
  action: "left_click",
  tabId: 1594803532,
  ref: "ref_XX"  // 手順4で見つけたref
)
```

## 手順6: テキスト入力

```
mcp__claude-in-chrome__computer(
  action: "type",
  tabId: 1594803532,
  text: "投稿したいテキスト"
)
```

## 手順7: メディア添付

### 画像の場合（PNG）

**クリップボードにコピー:**
```bash
osascript -e 'set the clipboard to (read (POSIX file "/path/to/image.png") as «class PNGf»)'
```

### 動画の場合（MP4）

**注意:** 動画は直接ペーストできない場合がある。その場合は「画像や動画を追加」ボタンをクリックしてファイル選択ダイアログを使う。

**サムネイル画像をペーストする方法:**
```bash
# 動画からサムネイル抽出
ffmpeg -i video.mp4 -ss 00:00:02 -frames:v 1 -update 1 thumbnail.png

# クリップボードにコピー
osascript -e 'set the clipboard to (read (POSIX file "/path/to/thumbnail.png") as «class PNGf»)'
```

**ブラウザでペースト:**
```
mcp__claude-in-chrome__computer(
  action: "key",
  tabId: 1594803532,
  text: "cmd+v"
)
```

## 手順8: 確認スクリーンショット

```
mcp__claude-in-chrome__computer(
  action: "screenshot",
  tabId: 1594803532
)
```

## 手順9: 投稿（ユーザー確認後のみ！）

**⚠️ 実際の投稿は必ずユーザーの明示的な許可を得てから！**

```
# 「ポストする」ボタンのrefを取得してクリック
mcp__claude-in-chrome__computer(
  action: "left_click",
  tabId: 1594803532,
  ref: "ref_YY"  // ポストするボタンのref
)
```

## よくある問題と解決策

### 問題: form_input でエラー
**原因:** Xの投稿フォームはDIV要素
**解決:** `computer(left_click)` → `computer(type)` を使う

### 問題: テキストが入力されない
**原因:** フォーカスが当たっていない
**解決:** まず `computer(left_click)` でフォームをクリック

### 問題: 画像がペーストされない
**原因:** クリップボードに正しくコピーされていない
**解決:** `osascript` のコマンドを確認、ファイルパスが正しいか確認
