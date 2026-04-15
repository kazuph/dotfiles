---
name: obsidian
description: Obsidianヴォルト操作の統一窓口。文献ノート、デイリーノート、メモ、タスク、リンク分析を `ob` CLI 経由で行う。ユーザーが Obsidian / vault / 文献ノート / literature notes / デイリーノート / daily notes / メモ / knowledge base に触れる時は必ずこれを使う。
allowed-tools: Bash, Read
---

# obsidian - Obsidian Vault 操作スキル

Obsidian Vault を `ob` CLI（Obails プロジェクト製）経由で読み書きする。
JSON出力がデフォルトでAIエージェント向け。Obsidianアプリ未起動でも動作する。

## Vault 情報（既知）

| 項目 | 値 |
|------|-----|
| Vaultパス | `/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault` |
| デイリーノート | `02_dailynotes/` （形式: `YYYY-MM-DD`） |
| **文献ノート** | **`03_文献ノート/`** |
| テンプレート | `99_template/` |
| Timelineセクション | `## Memos` |
| 設定ファイル | `~/.config/obails/config.toml` |

※ パス絶対指定が必要な時のみ使う。基本は `ob` コマンドが config を読むので気にしなくていい。

## 文献ノートの運用規約（重要）

ユーザーが「文献ノート」「論文読んだ」「資料まとめて」系の発言をしたら、以下に従う。

- **保存先**: `03_文献ノート/`（必ず）
- **ファイル名規約**: `YYYY-MM-DD <簡潔なタイトル>文献ノート.md`
  - 例: `2026-04-15 Qwen3.5ローカル比較とOpenCodeGo評価文献ノート.md`
  - 日付は今日の日付（`date +%F`）
  - タイトルは内容が一目でわかる日本語で短く
  - 末尾は原則「文献ノート」で終わらせる（既存ファイルと検索性を合わせるため）
- **作成コマンド例**:
  ```bash
  ob create name="2026-04-15 トピック名文献ノート" folder=03_文献ノート
  ob append file="2026-04-15 トピック名文献ノート" content="## 要点\n- ..."
  ```
- **検索**: `ob search query=文献` で一覧、特定トピックは `ob search query=<keyword> --matches`

## よく使うコマンド

### 読む
```bash
ob read file=<名前>                         # wiki-link解決で読む
ob read path=<相対パス>                     # 直接パス指定
ob read file=<名前> --section "## 見出し"  # セクション抽出
ob outline file=<名前>                      # 見出し一覧
ob search query=<text>                      # ファイル名検索
ob search query=<text> --matches            # 本文検索
```

### 書く
```bash
ob create name=<名前>                                           # 新規作成
ob create name=<名前> folder=03_文献ノート                      # フォルダ指定
ob create name=<名前> template=<テンプレ名>                     # テンプレから作成
ob append  file=<名前> content="本文" section="## Notes"        # 追記
ob prepend file=<名前> content="先頭に追加"                     # 先頭追記
ob upsert  file=<名前> content="本文" section="## Log"          # 無ければ作成
```

### デイリーノート
```bash
ob daily read                                        # 今日のデイリー
ob daily read --date 2026-04-15                      # 特定日
ob daily append content="メモ" section="## Notes"
ob daily timeline content="作業ログ"                 # タイムスタンプ付き追記（## Memos）
ob daily timeline content="レビュー" --todo          # TODOとして追加
```

### タスク / リンク
```bash
ob tasks                  # vault全体のタスク
ob tasks --daily --todo   # 今日の未完了
ob task file=<名前> line=18 --done

ob links     file=<名前>  # outgoing
ob backlinks file=<名前>  # incoming
ob orphans                # 孤立ノート
```

### アプリ連携
```bash
ob open                        # アプリ起動
ob open file=<名前>            # 特定ノートを開く
```

## 使い分けの指針

| ユーザー発言 | 取るべき行動 |
|---|---|
| 「Obsidianの〜」「vault の〜」 | まず `ob search` で当該ノートを探す |
| 「文献ノート作って」「論文まとめて」 | `ob create ... folder=03_文献ノート` で命名規約どおり作成 |
| 「今日のデイリーに追記」「作業ログ残して」 | `ob daily timeline content=...` |
| 「あのノートどこだっけ」 | `ob search query=<keyword>` → 見つからなければ `--matches` で本文検索 |
| 「〜についてvaultに何かあった？」 | `ob search --matches` → ヒットしたら `ob read` |

## やらないこと

- ❌ Vault内のファイルを直接 `Write`/`Edit` で書き換える（Obsidian側のインデックスと整合しなくなる）
- ❌ `03_文献ノート/` 以外に文献ノートを作る
- ❌ ファイル名規約を崩す（検索性が落ちる）
- ❌ `find`/`grep` で直接vaultを漁る（`ob search` を使う）

## トラブルシュート

- `ob` が見つからない → `/Users/kazuph/bin/ob` に実体あり。PATH確認
- 設定がおかしい → `~/.config/obails/config.toml` を確認
- iCloud同期未完了 → ファイル末尾 `.icloud` が残ってたら同期待ち
