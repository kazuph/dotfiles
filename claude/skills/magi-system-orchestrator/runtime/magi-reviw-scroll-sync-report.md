# MAGI System Report: reviw Scroll Sync & Comment Dialog Issue

Generated: 2025-12-26
Session ID: reviw-scroll-sync-2025-12-26

---

## Situation Snapshot

- **Goal**: スクロール同期を正確にし、クリック位置に正しくコメントダイアログを表示する
- **Constraints**:
  - 単一ファイル（cli.cjs）での実装
  - 既存のコメント機能・データ構造を維持
  - パフォーマンス重視（requestAnimationFrame使用）
- **Success Metric**:
  1. プレビューの任意の位置をクリックして、対応するソース行が選択される
  2. コメントダイアログがクリックした要素の近くに表示される
  3. スクロール同期が滑らかで直感的

---

## PHASE 1: INDEPENDENT MULTI-PERSPECTIVE ANALYSIS

### 🔷 MELCHIOR-01 (Claude) - Comprehensive Reasoning
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 長期的視点、ユーザビリティ、倫理的配慮

**Root Cause Analysis**:
- プレビュー（レンダリング結果）とソース（行ベース）は本質的に異なる座標系を持つ
- 「プレビューとソースの高さ比率が一定」という暗黙の前提が、画像展開・シンタックスハイライト等で崩れる
- `openCardForSelection(previewElement)`がパラメータを無視しているため、ユーザーの期待と異なる位置にダイアログが表示される

**Actionable Insights**:
- **段階的マッピング強化を実装** – Edit tool / 実装者 – プレビューの全ブロック要素（p, ul, ol, table, pre, blockquote等）に`data-source-lines`属性を付与し、対応するソース行範囲を記録。検証：プレビュー要素をinspectして属性が正しく設定されているか確認。
- **クリック位置ベースのカード配置を修正** – Edit tool / 実装者 – `openCardForSelection()`内で`previewElement`が提供されている場合は`positionCardNearElement()`を呼び出すように分岐。検証：プレビュー下部の要素をクリックして、カードがクリック位置近くに表示されるか目視確認。
- **視覚フィードバック追加** – Edit tool / 実装者 – クリック時にプレビュー要素に一時的なハイライト（例：0.3秒間のborder/background変化）を追加し、どの要素が選択されたかを明示。検証：各種要素をクリックしてハイライトが正しく表示されるか確認。

### 🔶 BALTHASAR-02 (GPT-5/Codex) - Deep Research & Technical
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 技術調査、実装詳細、パフォーマンス分析

**Root Cause Analysis**:
- headingアンカーのみだとアンカー密度が低く、テーブル/長文/リスト/コードなど大きなブロックでクリック位置に対応する基準点がない
- 比率フォールバックは非線形: Markdown→HTMLで高さが変化（表の行高、画像/コードの折返し、フォント/スタイル差）し、scrollTop比率が一致しない
- `openCardForSelection()`が`previewElement`を無視してソース側`td`基準で座標計算

**Technical Solutions**:
1. **全要素マッピング（推奨）**: Markdown変換時に各ブロック要素へ`data-line`付与。`[{line, previewTop}]`と`[{line, sourceTop}]`を構築し、クリック時は`event.composedPath()`で最近接`data-line`祖先を取得、スクロール時は二分探索で近傍アンカー同期
2. **IntersectionObserver**: `data-line`付き要素の可視状態を監視し、中央に近い要素を現在アンカーとして採用
3. **仮想スクロール**: DOM量削減で高速化だが、整合管理が複雑化（非推奨）

**Performance Impact**:
- 全要素マッピング: 初期計測O(n)、メモリO(n)、スクロール時O(log n)
- IntersectionObserver: 登録O(n)、コールバックはスクロール速度と可視要素数に依存
- 仮想スクロール: DOM負荷最小だが実装コスト最大

**Actionable Insights**:
- **全要素マッピング実装** – cli.cjs編集 / BALTHASAR-02 – プレビューの任意クリックで対応するソース行が選択される
- **rAF + 二分探索同期** – cli.cjs編集 / BALTHASAR-02 – テーブル/長文でもスクロール同期が視覚的に一致する
- **openCardForSelection()の座標基準修正** – cli.cjs編集 / BALTHASAR-02 – コメントダイアログがクリック要素近傍に表示される

### 🔸 CASPER-03 (Gemini) - Pattern Recognition & Synthesis
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: パターン認識、統合、代替案提示

**Existing Patterns**:
- **VS Code (Source Map方式)**: Markdownレンダリング時に行番号(`data-line`)をHTML属性として埋め込み、スクロール位置を「行番号」を介して相互変換（最も精度が高い標準的アプローチ）
- **GitHub (AST Mapping方式)**: AST解析時に各ノードのソース位置を特定し、プレビュー側のDOM要素と紐付け
- **Notion (Block-based方式)**: エディタ自体がブロック構造を持ち、ViewとModelが1:1で対応

**Alternative UX Approaches**:
- **Click-to-Sync**: クリックした瞬間にソース側の該当行をビューポート中央に強制スクロール
- **Contextual Dialog**: ダイアログを「プレビュー」のクリックした要素の直下に表示し、視線移動を減らす

**Phased Improvements**:
- **短期**: `openCardForSelection`関数のバグ修正（previewElement引数を活用）
- **中期**: `selectSourceRange`のスクロールブロック解除
- **長期**: `headingAnchors`をtable, img, preにも拡張

**Actionable Insights**:
- **Fix Dialog Placement** – replace / CASPER-03 – `openCardForSelection`内で`previewElement`引数が存在する場合、`positionCardNearElement`関数を呼び出す分岐を追加。検証：ダイアログがクリック位置の近くに表示されることを確認。
- **Enable Click-Scroll** – replace / CASPER-03 – `selectSourceRange`関数内で、プレビュークリック時にも`sourceTd.scrollIntoView`を実行。検証：クリック箇所に対応するソース行が表示されることを確認。
- **Expand Sync Anchors** – replace / CASPER-03 – `headingAnchors`の生成ロジックを拡張し、`h1-h6`に加えて`table`, `img`, `pre`要素もマッピング。検証：テーブルでのスクロール同期ズレが解消されることを確認。

---

## PHASE 2: FINAL SYNTHESIS & UNIFIED ACTION PLAN

**Synthesis Engine**: CASPER-03 (Gemini) | **Integration Status**: ✓ COMPLETE

### Unified Action Plan

#### Step 1: カード配置ロジックの修正 (Immediate Fix)
既存のバグを修正し、要素が特定できる場合は確実にその横にカードを表示させます。
- **Owner**: CASPER-03 (Bug Fixing)
- **ETA**: 30 min
- **Deliverable**: 修正された `openCardForSelection` 関数。`previewElement` が存在する場合、強制的に `positionCardNearElement` を呼び出すロジック。
- **Verification**: プレビュー内の特定の段落をクリックし、カードがその段落の真横（スクロール位置に関わらず）に表示されるか確認。

#### Step 2: マッピング属性の拡張 (Mapping Enhancement)
Markdownレンダラーの設定を変更し、同期精度を向上させます。
- **Owner**: MELCHIOR-01 (Frontend)
- **ETA**: 1 hour
- **Deliverable**: `markdown-it` (または使用中のパーサ) の設定変更。全てのブロックレベル要素に `data-source-lines` 属性が出力されるようにする。
- **Verification**: 開発者ツールでプレビューのDOMを検査し、`<p>`, `<table>`, `<ul>` 等に行番号属性が付与されているか確認。

#### Step 3: 視覚フィードバックとスクロール制御 (UX & Polish)
ユーザーがどこをクリックしたか明確にし、スクロールの競合を防ぎます。
- **Owner**: BALTHASAR-02 (UX/Logic)
- **ETA**: 45 min
- **Deliverable**: クリックされた要素への一時的なCSSハイライトクラス追加機能と、`selectSourceRange` 実行時のスムーズスクロール（及び一時的なObserver解除）。
- **Verification**: プレビューをクリックした際、対象要素が一瞬ハイライトされ、ソースエディタがスムーズに対応行へスクロールすることを確認。

### Consensus Highlights

- **DOMマッピングの粒度向上**: 現状のヘッダーのみのマッピングでは不十分であり、`data-source-lines`（または同等の属性）を全てのブロック要素（段落、リスト、テーブル、画像）に拡張する必要がある。
- **コンテキスト依存の配置**: コメントカードの表示位置は、単なるY座標（`top`）ではなく、可能な限り「対応するDOM要素」の近傍（`positionCardNearElement`）に合わせるべきである。

### Conflicts / Trade-offs

- **即時修正 vs 構造改革**:
  - CASPER-03は`openCardForSelection`のバグ修正（短期）を優先
  - BALTHASAR-02は二分探索やObserverを用いた完全な同期システム（長期・高コスト）を提案
  - **Resolution**: MELCHIOR-01の「段階的アプローチ」を採用。まずは既存のロジック内で要素特定を修正し、高度なアルゴリズムはパフォーマンス問題が顕在化した場合の「プランB」として保留。

### Risk
**Trigger**: 数千行を超える巨大なMarkdownファイルを開いた場合
**Mitigation**: `mousemove` や `scroll` イベントの処理に `requestAnimationFrame` または `debounce` (10-20ms) を適用し、DOM探索の頻度を制限する。

### Follow-up Question
「現在、Markdown以外のファイル形式（CSV/TSVなど）における行同期の精度は許容範囲内ですか？ それともこれらにも同様の厳密なマッピングが必要でしょうか？」

---

## MAGI SYSTEM STATUS: DELIBERATION COMPLETE

**All Systems**: ✓ OPERATIONAL
**Consensus Achieved**: YES
**Action Plan Ready**: YES
**Implementation Ready**: PENDING USER APPROVAL
