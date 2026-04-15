---
name: figma
description: Figma design ingestion and fidelity enforcement. Use when extracting designs via Figma CLI, implementing UI components, or validating design compliance.
allowed-tools: Bash, Write, Read
---

# Figma Design Workflow

## Triggers

- "Figma", "デザイン仕様取得", "画面仕様", "レイアウト抽出", "Figma CLI", "ノード解析"
- UI実装時のFigma準拠確認
- コンポーネント実装前のデザイン検証

---

## Part 1: Design Ingestion (Figma CLI)

### Goal
- Figma URLから`fileKey`と`node-id`を抽出し、`figma` CLIでレイアウトデータとアセットを取得
- YAML/JSONとして整理し、デザイン仕様・文言・スタイルを参照可能にする

### Pre-flight Checks
1. 認証確認: `figma auth --show`
2. CLIバージョン: `figma --version`
3. `node-id`は`-`区切りの場合、`9614-2398 → 9614:2398`へ変換が必要な場合あり

### Workflow

#### 1. URL解析
```
https://www.figma.com/design/<fileKey>/...?...node-id=<nodeId>
```
- `nodeId`省略時は`figma get-data <fileKey>`でトップレベル構造を確認

#### 2. レイアウトデータ取得
```bash
figma get-data <FILE_KEY> <NODE_ID> --format yaml > /tmp/figma_screen.yaml
```
- `--depth`は情報欠落を招くため極力使わない
- 詳細ログは`--verbose`で取得

#### 3. 仕様抽出
```bash
# 文言抽出
yq '.. | select(has("text")) | .text' /tmp/figma_screen.yaml

# 色一覧
yq '.. | select(has("fills")) | .fills[]' /tmp/figma_screen.yaml | sort -u

# 特定コンポーネントのレイアウト
yq '.. | select(.name? | test("(?i)button")) | .layout' /tmp/figma_screen.yaml
```

#### 4. アセット取得（必要時）
```bash
tmp_dir=$(mktemp -d)
figma download-images <FILE_KEY> "$tmp_dir" --nodes '[{"nodeId":"<NODE_ID>","fileName":"asset.png"}]'
```

#### 5. 成果整理
- YAML/JSON/アセットの保存先を報告
- 抽出コマンドとパスを明記

---

## Part 2: Design Fidelity Enforcement

### Core Principle

**Storybook Components = Figma Components**

Figmaに存在しないUI要素は実装してはならない。

### Implementation Rules

#### Before Creating Any Component
1. Figmaでコンポーネントの存在を確認
2. Figmaからスクリーンショットを取得
3. `docs/reference/figma_screenshots/`に保存

#### Component + Story Creation
1. Figmaスクリーンショットに基づいて実装
2. `.stories.tsx`を同時作成
3. StorybookレンダリングとFigmaを比較
4. 差異があれば即座にドキュメント化

### Color Compliance

プロジェクトの`constants/Colors.ts`（または同等ファイル）でFigma指定の色のみを定義。

フレームワークデフォルトの色（Expoの紫 #6366F1 など）が残っていないか確認：
```bash
grep -r "#6366F1" components/
```

### Critical Reminders

1. **No Figma = No Component** - Figmaにないものは作らない
2. **Storybook Required** - 全コンポーネントに`.stories.tsx`必須
3. **Screenshot Evidence** - 実装前にFigmaスクリーンショット保存
4. **Color Compliance** - Figma定義の色のみ使用
5. **Verify Framework Defaults** - フレームワークデフォルト色の混入を防ぐ

---

## Best Practices

- 大規模ファイルでは必要なノードのみ指定し、パイプラインで絞る
- `node-id`探索困難時は`figma get-data <FILE_KEY>`で上位構造を確認
- 多言語UIはテキスト抽出後に言語タグ・フォント情報も併記
- `figma download-images`結果は`/tmp`で受け、必要ファイルのみワークスペースへ移動
- エラー時は`--verbose`でAPIレスポンスを確認
