---
name: obsidian-knowledge-synthesizer
description: Obsidian note creation, search, and management. Use when working with Obsidian vault, creating literature notes, searching knowledge base, or synthesizing research into Mermaid diagrams with Raindrop integration.
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__raindrop__bookmark_recent
  - mcp__fetch__imageFetch
---

# Obsidian Knowledge Synthesizer Skill

## ClaudeCodeサブエージェント方針
- ステータス: ✅ 必須（ClaudeCodeサブエージェントで起動）
- 理由: Obsidianノート生成にはRaindrop連携・Mermaid CLI検証・添付管理など多数の手順があり、サブエージェントで完結させないとiCloudパスや並列fetchの状態が混線する。
- メモ: サブエージェント内でデータ取得→ノート生成→Mermaid検証→ファイル配置まで終えてから、成果パスと`obsidian://` URIだけをメインに報告する。

研究結果や調査メモをObsidianに残すときはこのSkillを参照し、詳細要件は `docs/WORKFLOW.md` で確認してください。

## トリガー

- 「Obsidian」「文献ノート」「Mermaid図」「記録として残して」等の指示。
- 調査完了後に成果を体系化したい場合。

## 標準フロー（概要）

1. **データ取得**: `mcp__raindrop__bookmark_recent`で最新5件を取得。手動URLの場合も同じ形式へ整形。
2. **並列fetch**: 5本の `mcp__fetch__imageFetch` を独立に走らせ、成功/失敗を分離。詳細は `docs/WORKFLOW.md`。
3. **ノート生成**:
   - `docs/NOTE_TEMPLATE.md`をベースに日本語で記述。
   - `date`コマンドで作成日時を取得し、Frontmatterに設定。
   - Mermaid図を作成し `npx -y @mermaid-js/mermaid-cli --check diagram.mmd` 等で検証。
4. **Obsidian保存**: `/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/03_文献ノート/` に `YYYY-MM-DD-HHmm-<slug>.md` で書き出し、`obsidian://` URIを結果に含める。添付は `attachment/<topic>/` 配下にまとめる。
5. **レポート**: 成功件数、失敗理由、ノートURIを日本語で報告。

## 重要ルール

- 出力/エラーメッセージはすべて日本語。
- Mermaid図は必須。CLIチェックに通らない図は修正してから保存。
- 1記事ごとに独立処理。失敗しても残りのジョブは継続。
- ランダムな日付記入は禁止。必ず`date`コマンドで取得。
- TikZ図が必要な場合はスタンドアロンTeXで描き、`pdflatex` → `magick` でPNG/SVG化して `attachment/<topic>/` に格納し、同じ節にTikZコードブロックも残す（Obsidianは生TikZをレンダリングしないため）。

## 参考ドキュメント

- `docs/WORKFLOW.md`: Autoモード詳細、並列処理・Mermaidルール。
- `docs/NOTE_TEMPLATE.md`: フロントマターと本文テンプレ。

## ログとファイル

- 一時ファイルやフェッチ結果は `obsidian-knowledge-synthesizer/runtime/` 配下に保存してよい。
- 記録が不要になった場合は`rm runtime/<file>`で整理するが、削除対象を確認してから実行。

## クリーンアップ手順（必須）

1. Mermaid検証用に生成した一時 `.mmd` / `.svg` / `/tmp/*` が残っていないか確認し、不要なら `rm` で削除。
2. `runtime/` 以下のキャッシュ (`bookmark-*.json` など) で不要なものを明示的に削除。
3. Obsidianで開いたノートがあれば確認し、必要なら `obsidian://` で対象ノートを表示して内容チェック後に閉じる。

## トラブルシューティング

- **Raindrop APIエラー**: レスポンスIDとエラー文を報告し、手動URLリストで代替。
- **Mermaid CLIに失敗**: エラーログを出し、修正後に再実行。どうしても描けない場合は理由を記載。
- **iCloudパス未マウント**: `ls`で確認し、未同期ならユーザーに同期状況を問い合せる。

このSkillを使うことで長大なエージェント定義を参照せずにObsidianノートを安定生成できます。
