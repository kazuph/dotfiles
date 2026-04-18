---
name: obsidian
description: Obsidianヴォルト操作の唯一の窓口。「ノートにまとめておいて」「まとめておいて」「文献ノート」「論文読んだ」「資料まとめて」「Obsidian」「vault」「daily notes」「メモ」「knowledge base」「Mermaid図」「記録として残して」「調査結果まとめて」のいずれかが出たら必ずこのスキル。デフォルト保存先は `03_文献ノート/`。書き終わったら必ず `ob open file=...` でobailsを開いてユーザーに見せる。`ob` CLIを使い、Vaultを直接Write/Editしない。
allowed-tools:
  - Bash
  - Read
  - Write
  - mcp__raindrop__bookmark_recent
  - mcp__fetch__imageFetch
---

# obsidian - Obsidian Vault 統合スキル

Obsidian Vault を `ob` CLI（Obails 製）経由で読み書きする唯一の窓口。
JSON出力がデフォルトでAIエージェント向け。Obsidianアプリ未起動でも動作する。

## ⚡ ショートカット運用（最重要）

ユーザーが下記いずれかを発したら **追加質問せず即座に文献ノートを作成**する。

- 「ノートにまとめておいて」
- 「まとめておいて」 / 「まとめて」
- 「文献ノート作って」 / 「論文読んだ」 / 「資料まとめて」
- 「記録として残して」 / 「調査結果まとめて」

### 即時アクション

```bash
# 1) 今日の日付取得（必ず date コマンド、絶対にハードコードしない）
TODAY=$(date +%F)                       # YYYY-MM-DD
NOW=$(date '+%Y-%m-%d %H:%M:%S %z')

# 2) タイトルは会話文脈から日本語で短く決める
TITLE="${TODAY} <内容を一目で表す日本語タイトル>文献ノート"

# 3) 03_文献ノート/ に作成（folder 指定必須）
ob create name="${TITLE}" folder=03_文献ノート

# 4) frontmatter + 本文を流し込む（reference/note-template.md 準拠）
ob append file="${TITLE}" content="..."

# 5) ★必ず最後にobailsを開いてユーザーに見せる（セットで完結）
ob open file="${TITLE}"
```

**書いたら開く** ＝ 1セット。ユーザーが確認できないうちに完了報告しない。
迷ったら `reference/note-template.md` のテンプレ通りに本文を構成し、Mermaid図を1つ以上必ず入れる。

## Vault 情報

| 項目 | 値 |
|------|-----|
| Vaultパス | `/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault` |
| **デフォルト保存先（文献ノート）** | **`03_文献ノート/`** |
| デイリーノート | `02_dailynotes/` （形式: `YYYY-MM-DD`） |
| テンプレート | `99_template/` |
| 添付 | `attachment/<topic>/` |
| Timelineセクション | `## Memos` |
| 設定ファイル | `~/.config/obails/config.toml` |

> Vault パスは `~/.config/obails/config.toml` で一度だけ設定済み。AIは `--vault` フラグや config.toml を **絶対に触らない**。

## 文献ノート運用規約

- **保存先**: `03_文献ノート/`（必ず）
- **ファイル名**: `YYYY-MM-DD <簡潔な日本語タイトル>文献ノート.md`
  - 例: `2026-04-19 Qwen3.5ローカル比較とOpenCodeGo評価文献ノート.md`
  - 日付は `date +%F`、タイトルは内容が一目でわかる日本語、末尾は原則「文献ノート」
  - 細かいタイムスタンプ版（`YYYY-MM-DD-HHmm-<slug>.md`）はRaindrop連携時など複数生成する場合に使用可
- **本文**: `reference/note-template.md` のテンプレに従う（概要 / 詳細内容 / 重要なポイント / 実践的な活用方法 / Mermaid / 参考）
- **言語**: 本文・コミュニケーションともすべて日本語
- **日付**: 必ず `date` コマンドで取得。ハードコードや推測は禁止
- **Mermaid図**: 1ノートにつき最低1図。`npx -y @mermaid-js/mermaid-cli --check` で構文検証してから保存
- **添付**: 画像・図は `attachment/<topic>/` に格納
- **★最後に必ず開く**: ノート保存が終わったら `ob open file="<TITLE>"` でobailsを起動して該当ノートを表示する。ユーザーが目視確認できる状態にしてから完了報告する

## よく使うコマンド（最小セット）

詳細リファレンスは `reference/ob-cli.md`。

### 読む
```bash
ob read file=<名前>                         # wiki-link解決
ob read file=<名前> --section "## 見出し"  # セクション抽出
ob outline file=<名前>                      # 見出し一覧
ob search query=<text>                      # ファイル名検索
ob search query=<text> --matches            # 本文検索
```

### 書く
```bash
ob create  name=<名前> folder=03_文献ノート             # 新規（文献ノートはfolder必須）
ob append  file=<名前> content="本文" section="## 見出し"
ob prepend file=<名前> content="先頭に追加"
ob upsert  file=<名前> content="本文" section="## Log"  # 無ければ作成
```

### デイリーノート
```bash
ob daily read                                        # 今日のデイリー（無ければ作成）
ob daily read --date 2026-04-19                      # 特定日
ob daily timeline content="作業ログ"                 # ## Memos に時刻付き追記
ob daily timeline content="レビュー" --todo          # TODOチェックボックスで追加
```

### タスク / リンク
```bash
ob tasks --daily --todo            # 今日の未完了タスク
ob task file=<名前> line=18 --done # 完了マーク

ob links     file=<名前>           # outgoing
ob backlinks file=<名前>           # incoming
ob orphans                         # 孤立ノート
ob unresolved                      # 壊れたwiki-link
```

### アプリ連携
```bash
ob open                       # アプリ起動
ob open file=<名前>           # 特定ノートを開く
```

## 使い分けの指針

| ユーザー発言 | 取るべき行動 |
|---|---|
| 「ノートにまとめておいて」「まとめておいて」 | **即座に** `03_文献ノート/` へ命名規約どおり作成 → `ob open file=...` でobailsを開く。質問しない |
| 「文献ノート作って」「論文まとめて」 | 同上（作成→openセット） |
| 「Obsidianの〜」「vault の〜」 | まず `ob search` で当該ノートを探す |
| 「今日のデイリーに追記」「作業ログ残して」 | `ob daily timeline content=...` |
| 「あのノートどこだっけ」 | `ob search query=<keyword>` → `--matches` で本文検索 |
| 「〜についてvaultに何かあった？」 | `ob search --matches` → ヒットしたら `ob read` |
| 「Raindropから記事まとめて」「最近ブクマした記事を文献ノート化」 | `reference/synthesizer-workflow.md` の並列fetchフローを使用 |

## やらないこと

- ❌ Vault内のファイルを直接 `Write`/`Edit` で書き換える（Obsidianインデックス不整合の元）
- ❌ `03_文献ノート/` 以外に文献ノートを作る
- ❌ ファイル名規約を崩す（検索性が落ちる）
- ❌ `find`/`grep` で直接vaultを漁る（`ob search` を使う）
- ❌ `--vault` フラグや `~/.config/obails/config.toml` を AI が変更する
- ❌ 日付をハードコード／推測する（必ず `date` コマンド）
- ❌ Mermaid CLIに通らない図を保存する

## トラブルシュート

- `ob` が見つからない → `/Users/kazuph/bin/ob` または `/usr/local/bin/ob` を確認、PATHに無ければユーザーへ
- 「vault path not configured」 → 触らずユーザーへ案内（config.toml は手動設定のみ）
- iCloud同期未完了 → ファイル末尾 `.icloud` が残ってたら同期待ち、`ls` で確認しユーザー確認
- Raindrop API失敗 → IDとエラー文を報告、手動URLで代替
- Mermaid CLI失敗 → ログを出して修正再試行、最後まで描けない場合は理由を本文に明記

## 参考ドキュメント

- `reference/ob-cli.md` — `ob` CLIの全コマンド詳細リファレンス
- `reference/synthesizer-workflow.md` — Raindrop連携・並列fetch・複数記事一括ノート化の手順
- `reference/note-template.md` — 文献ノート本文テンプレート（YAML+Mermaid込み）
- `runtime/` — Mermaid成果物・キャッシュ置き場（不要になったら明示削除）

## クリーンアップ

1. Mermaid検証用の `/tmp/*.mmd` `/tmp/*.svg` が残っていれば `rm`
2. `runtime/` の不要キャッシュ（`bookmark-*.json` 等）を確認のうえ削除
3. Obsidianで開いたノートは `obsidian://` で内容確認後に閉じる
