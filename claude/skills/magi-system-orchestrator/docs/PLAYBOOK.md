# MAGI System Playbook

MAGIは Claude (MELCHIOR-01)、Codex/GPT-5 (BALTHASAR-02)、Gemini (CASPER-03) の3視点を同時稼働させ、多面的な分析と実装を行うための運用手順です。ここではスキル全体の詳細要件をまとめます。

## 1. ペルソナと役割

| Persona | コールサイン | 得意分野 | 代表タスク |
| --- | --- | --- | --- |
| Claude | MELCHIOR-01 | 倫理観を含む広義の思考、課題要約 | ゴール整理、制約明記、最終レビュー |
| Codex / GPT-5 | BALTHASAR-02 | 技術調査、検索、実装、デバッグ | リサーチ、コード生成、検証ログ提示 |
| Gemini | CASPER-03 | パターン認識、統合、代替案提示 | 競合案比較、統合アクションプラン策定 |

## 2. 実行フロー

1. **インテント確認**: 予算/制約/成功指標を2文で確認。欠けていれば Stop-if-Unclear で質問。
2. **可用性チェック**: Codex/GPT-5用 CLI と Gemini CLI を並列起動できるか事前に疎通確認。（コマンド例は後述）
3. **フェーズ1 – 独立分析**:
   - 3モデルを同時に走らせ、互いの結果を参照しない状態でアウトプットを得る。
   - それぞれ「Action – Tool/Owner – Success Check」形式のBulletを3つずつ揃える。
4. **フェーズ2 – 統合**:
   - Geminiが中心となり、共通点とトレードオフを記述。
   - 最低3つのステップを持つ「Unified Action Plan」を作成し、各ステップにETAと検証方法を紐付け。
5. **リスク/フォローアップ**: リスクは「トリガー → 対応策」で1行、フォローアップ質問は1件のみ。
6. **セルフチェック**: `docs/CHECKLIST.md`を参照して提出前に必ずチェック。

## 3. Stop-if-Unclear ルール

- ゴール/制約/成功指標のいずれかが欠けている場合、即座に `Need more detail` を返し、欠損項目のチェックリストを提示。
- 曖昧さが解消されるまで MAGI 実行を開始しない。

## 4. CLI起動ルール

`script -q /dev/null` は不要。exec/ワンショットモードではTTYラッパーなしで動作する。

| Persona | 代表コマンド | 備考 |
| --- | --- | --- |
| Codex/GPT-5 | `outfile=$(mktemp -t codex); command codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox exec --skip-git-repo-check --full-auto -o "$outfile" "<prompt>" >/dev/null 2>&1; cat "$outfile"` | `-o` で最終メッセージのみファイル出力。失敗時はフォールバック CLI を再実行、不可ならセッション中止。 |
| Gemini | `outfile="/tmp/gemini_$$"; /opt/homebrew/bin/mise exec -- gemini --approval-mode=yolo -o json "<prompt>" 2>/dev/null \| jq -r '.response' > "$outfile"; cat "$outfile"` | `-o json` + `jq` で最終応答のみ抽出。思考トークン・stats除外。 |
| Claude | `CLAUDECODE= command claude --dangerously-skip-permissions --print "<prompt>"` | `CLAUDECODE=` でネスト検出バイパス。`--print` で最終応答のみ。 |

両者のCLIを同時起動し、シリアルな順番待ちにしない。どちらかが落ちたら MAGI 全体を中断し、状況を報告する。

## 5. タスク分類の判断基準

- **MAGI対象**: 建築的意思決定、複雑な比較調査、複数ステークホルダーが関与する方針策定。
- **非対象**: 単純なQ&A、テンプレ埋め、短いコード修正（→通常Claudeで対応）。

## 6. ログと証跡

- マルチエージェントの各出力は `runtime/magi-<timestamp>-persona.log` へ保存することを推奨（保存先は各タスクで適宜決める）。
- 完了後はアクションプランを報告し、`docs/CHECKLIST.md`に従った自己検証結果を添える。

## 7. フェイルオーバー

- Codex または Gemini どちらか一方でも永続不可なら即 Abort。「Claude単独で継続」は禁止。
- CLIログはエラーメッセージごとに保存し、再試行回数と理由を報告する。

## 8. 開発タスク時の特則

- コード生成/修正は、該当ペルソナ（多くはCodex/Gemini）が `apply_patch` 等の具体的なdiffを出力。
- テストは該当ペルソナが実行し、ログを添付。Claudeはレビュー役に徹する。

詳細テンプレートは `docs/OUTPUT_TEMPLATE.md` を参照。
