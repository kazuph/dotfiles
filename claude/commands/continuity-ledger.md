# Continuity Ledger（継続性台帳）

コンテキスト圧縮に耐えるワークスペースの継続性を維持するためのルール。

## 概要

このワークスペースでは `CONTINUITY.md` という単一の継続性台帳を管理する。この台帳はコンテキスト圧縮を生き残るためのセッションブリーフィングであり、台帳に反映されていない限り、以前のチャットテキストに依存しないこと。

## 運用方法

### アシスタントターン開始時
1. `CONTINUITY.md` を読む
2. 最新のゴール/制約/決定/状態を反映して更新
3. 作業を進める

### 更新タイミング
以下のいずれかが変更されたら `CONTINUITY.md` を更新：
- ゴール
- 制約/前提条件
- 重要な決定
- 進捗状態（Done/Now/Next）
- 重要なツール出力

### 記述ルール
- 短く安定した内容を維持：事実のみ、会話の転記は不要
- 箇条書きを推奨
- 不確かな情報は `UNCONFIRMED` とマーク（推測しない）
- 記憶の欠落や圧縮/要約イベントに気づいたら：
  - 見えるコンテキストから台帳を再構築
  - 欠落部分を `UNCONFIRMED` とマーク
  - 1〜3個の的を絞った質問をする
  - その後作業を継続

## `functions.update_plan` vs 台帳

| 用途 | ツール |
|------|--------|
| 短期的な実行スキャフォールディング（3〜7ステップの小さな計画、pending/in_progress/completed） | `functions.update_plan` |
| 圧縮を超えた長期的な継続性（what/why/現在の状態） | `CONTINUITY.md` |

**注意**: 両者を一貫させること。計画や状態が変わったら、台帳も意図/進捗レベルで更新する（マイクロステップごとではない）。

## 返答での表示

返答の冒頭に簡潔な「Ledger Snapshot」を表示：
- Goal + Now/Next + Open Questions

完全な台帳は、重要な変更があった時、またはユーザーが求めた時のみ表示。

## `CONTINUITY.md` フォーマット

```markdown
# Continuity Ledger

## Goal（成功基準を含む）
-

## Constraints/Assumptions（制約/前提）
-

## Key decisions（重要な決定）
-

## State（状態）

### Done（完了）
-

### Now（現在）
-

### Next（次）
-

## Open questions（未解決の質問、必要に応じてUNCONFIRMED）
-

## Working set（作業セット：ファイル/ID/コマンド）
-
```
