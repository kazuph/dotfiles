---
name: webapp-testing
description: Toolkit for interacting with and testing local web applications using Playwright (TypeScript). Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs. [MANDATORY] Before saying "implementation complete", you MUST use this skill to run tests and verify functionality. Completion reports without verification are PROHIBITED.
license: Complete terms in LICENSE.txt
---

# Web Application Testing

TypeScript + Playwright によるWebアプリケーションのテスト・検証スキル。

## 🚨 絶対ルール: メインセッション禁止

**ブラウザ操作・テスト実行は絶対にメインセッションで行ってはならない。**

理由:
1. **トークン爆発**: ブラウザ操作はスクリーンショット・DOM・ログで大量のトークンを消費する
2. **コンテキスト汚染**: メインセッションのコンテキストがすぐにリフレッシュ（コンパクション）される
3. **デバッグ地獄**: メインセッションでやるとデバッグループのたびにコンテキストが失われる

**必ずサブエージェント（Agent tool）を使って、その内部で以下を全て完結させること：**
- Playwright CLI / Agent Browser CLI での概要把握
- Playwright Test のE2Eテスト実装
- テスト実行・デバッグ
- スクリーンショット・動画の証跡収集

```
❌ メインセッションで: page.goto(), page.screenshot(), npx playwright test
✅ Agent tool → サブエージェント内で全てのブラウザ操作を実行
```

## 必須フロー: CLI先行 → E2Eテスト

**いきなりE2Eテストを書き始めてはいけない。**

E2Eテストから書き始めると、途中まで実装して失敗した場合のデバッグコストが跳ね上がる。
まず軽量CLIでサイトの現状を把握してから、確実なテストを書く。

### Step 1: CLI でサイト概要把握（トークン節約）

**Playwright CLI** (`@playwright/cli`) または **Agent Browser CLI** (`agent-browser`) を使って、
対象ページの構造・要素・状態を低コストで把握する。

> ⚠️ これらは新しいツールのため、使用前に必ず `--help` や公式ドキュメントを確認して最新の使い方を調べること。

#### Playwright CLI（Microsoft）
```bash
# スナップショット取得（YAML形式、トークン効率的）
npx @playwright/cli snapshot http://localhost:3000
# → コンパクトなYAMLで要素参照（e21, e35等）をディスクに保存

# 要素をクリック
npx @playwright/cli click e21

# スクリーンショット保存
npx @playwright/cli screenshot --output /tmp/page.png
```

#### Agent Browser CLI（Vercel Labs）
```bash
# ページを開く
agent-browser open http://localhost:3000

# アクセシビリティツリーのスナップショット取得
agent-browser snapshot -i
# → ref付きのコンパクトなツリーを出力

# 要素操作（refベース）
agent-browser click @e3
agent-browser fill @e1 "user@example.com"

# スクリーンショット
agent-browser screenshot /tmp/page.png

# テキスト取得
agent-browser get text @e1

# 閉じる
agent-browser close
```

**なぜCLI先行が必要か:**
- DOM構造、セレクタ、要素の状態を事前に把握できる
- テスト記述の精度が上がり、一発で通る確率が大幅に向上
- CLIの出力はファイルベースなので、LLMコンテキストを消費しない

### Step 2: Playwright Test でE2Eテスト実装（永続化・リグレッション）

CLIで把握した情報を元に、**プロジェクトに根差した永続的なリグレッションテスト**を書く。

```typescript
// e2e/features/auth/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('ログイン機能', () => {
  test('メールアドレスとパスワードでログインできる', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    await page.getByLabel('メールアドレス').fill('test@example.com');
    await page.getByLabel('パスワード').fill('password123');
    await page.getByRole('button', { name: 'ログイン' }).click();

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'ダッシュボード' })).toBeVisible();
  });

  test('不正なパスワードでエラーが表示される', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    await page.getByLabel('メールアドレス').fill('test@example.com');
    await page.getByLabel('パスワード').fill('wrong');
    await page.getByRole('button', { name: 'ログイン' }).click();

    await expect(page.getByText('認証に失敗しました')).toBeVisible();
  });
});
```

## テスト永続化ルール（リグレッション前提）

**テストは一時ファイルではなく、プロジェクトのリポジトリに永続的に配置する。**

### テスト配置ルール
```
<project-root>/
├── e2e/                          # E2Eテストルート
│   ├── features/                 # 機能別テスト
│   │   ├── auth/
│   │   │   ├── login.spec.ts
│   │   │   └── signup.spec.ts
│   │   ├── dashboard/
│   │   │   └── overview.spec.ts
│   │   └── ...
│   └── fixtures/                 # 共有フィクスチャ
│       └── auth.fixture.ts
├── playwright.config.ts          # Playwright設定
└── .artifacts/<feature>/         # 証跡（gitignore対象）
    ├── images/
    ├── videos/
    └── traces/
```

### 命名規則
- テストファイル: `<feature>.spec.ts`（必ず `.spec.ts` 拡張子）
- フィクスチャ: `<name>.fixture.ts`
- テスト記述: 日本語で具体的な振る舞いを書く

### テストの書き方ポリシー
1. **一時的なテストは禁止**: `/tmp/` にテストスクリプトを書いて使い捨てにしない
2. **リグレッション前提**: 一度書いたテストはCIで継続的に実行される前提で書く
3. **独立実行可能**: 各テストファイルは単体でも、スイート全体でも実行できること
4. **実際のデータフロー**: モック・スタブ禁止。実際のAPI・DBに接続するテストを書く
5. **エッジケース重視**: ハッピーパスだけでなく、エラー状態・空状態・ローディング状態もテスト

### playwright.config.ts テンプレート
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## サブエージェントでの実行パターン

メインセッションからサブエージェントに委譲する際のプロンプト例：

```
Agent tool prompt例:
「以下のWebアプリをテストしてください：
1. まず agent-browser または Playwright CLI でサイト構造を把握
2. e2e/features/<feature>/<name>.spec.ts にリグレッションテストを作成
3. npx playwright test で実行し、全テストがパスするまでデバッグ
4. スクリーンショットを .artifacts/<feature>/images/ に保存
5. 結果を報告」
```

## 証跡ファイル配置規約

検証時に生成するファイルは以下の構成で `.artifacts/<feature>/` に集約する：

```
.artifacts/<feature>/
├── scripts/      # 検証用Playwrightスクリプト（.ts）
├── images/       # スクリーンショット
├── videos/       # 録画ファイル
└── traces/       # Playwright trace（.zip）
```

- **スクリプトも証跡の一部**: 何を実行したか再現可能にするため `scripts/` に保存
- **命名規則**: `<timestamp>-<step>.png`、`verify-<feature>.ts` など意図が分かる名前
- **即席検証のみ `/tmp`**: 証跡不要の一発確認は `/tmp` でOK、ただし後から参照できない前提

## Playwright Test 実行コマンド

```bash
# 全テスト実行
npx playwright test

# 特定ファイルのみ
npx playwright test e2e/features/auth/login.spec.ts

# headedモード（ブラウザ表示）
npx playwright test --headed

# trace付き実行
npx playwright test --trace=retain-on-failure

# 証跡をartifactsに出力
npx playwright test --output=.artifacts/<feature>/images
```

## Common Pitfall

❌ **Don't** いきなりE2Eテストを書き始める → デバッグコスト爆発
✅ **Do** まずCLI（Playwright CLI / Agent Browser）で構造把握 → テスト作成

❌ **Don't** メインセッションでブラウザ操作 → コンテキスト消費・コンパクション
✅ **Do** サブエージェントに委譲して完結させる

❌ **Don't** `/tmp/test.ts` に使い捨てテスト → リグレッション不可
✅ **Do** `e2e/features/<feature>/` に永続テスト → CI連続実行

❌ **Don't** `networkidle` 前にDOMを検査する
✅ **Do** `page.waitForLoadState('networkidle')` 後に検査
