# Obsidian Knowledge Synthesizer Workflow

このドキュメントはスキル全体の詳細手順をまとめたものです。SKILL.mdで概要を把握し、本書で実装レベルのフローを確認してください。

## 1. トリガーと前提

- ユーザーが「Obsidian」「文献ノート」「Mermaid図」などを要求。
- Raindrop、Fetch、Mermaid CLI が利用可能。
- ノート保存先: `/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/03_文献ノート/`

## 2. Autoモード手順

1. `mcp__raindrop__bookmark_recent` で最新5件を取得（count=5）。
2. 5件を独立ジョブとして並列fetch: `mcp__fetch__imageFetch`（`enableFetchImages=true`, `returnBase64=true`）。
3. 各記事ごとに:
   - コンテンツ分析 → 要約抽出
   - Mermaid図設計 → `npx -y @mermaid-js/mermaid-cli -i diagram.mmd -o /tmp/diagram.svg --check` で構文検証
   - ノート本文生成（日本語）
   - Obsidianパスへ保存
4. 成功/失敗の結果を集計し、Obsidian URIとともにレポート。

## 3. Mermaid図ルール

- すべてのノートに最低1図。
- 図記法は `graph TD` など用途に応じて選択し、ノードテキストに簡潔な絵文字ラベルを付与。
- CLIチェックに失敗した場合は修正して再実行。最終的にバリデート済みであること。

## 4. ノート構成

1. YAML Frontmatter
   - `title`
   - `created`（`date "+%Y-%m-%d %H:%M:%S %z"`で取得）
   - `tags`, `read`, `important`
2. 本文セクション
   - `## 概要`
   - `## 詳細内容`
   - `## 重要なポイント`
   - `## 実践的な活用方法`
   - `## Mermaid`
3. ソースURLや関連資料へのリンクは本文末尾。

テンプレは `docs/NOTE_TEMPLATE.md` を参照。

## 5. 並列処理ガイド

- 5つの記事を完全に独立扱いし、失敗しても他ジョブを継続。
- 並列処理を模す場合はバックグラウンド実行や別Task呼び出しを行い、完了まで`wait`する。
- 失敗記録は `runtime/obsidian-jobs/<timestamp>-<slug>.json` などへ保存可。

## 6. エラーハンドリング

- **Fetch失敗**: URL・エラー内容を記録し、ノートには失敗理由を書いた簡易テンプレを保存。
- **Mermaid失敗**: CLIログを貼り付けたうえで修正を再試行。描画を諦める場合はその旨を明記（原則避ける）。
- **保存失敗**: 同名ファイルがある場合は連番を付与。

## 7. 日本語運用

- すべてのメッセージ・ノートを日本語で出力。
- 引用ソースが英語でも、本文では可能な限り日本語で要約する。

## 8. ログ

- `runtime/` 以下に各ジョブのフェッチ結果やメタデータを保存すると再利用しやすい。
- 完了レポートには作成ノートのObsidian URIを列挙。
