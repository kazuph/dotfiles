# MAGI System Final Output: Firebase Cloud Functions メールOTP認証テスト設計

```
Situation Snapshot:
- Goal: Firebase Cloud Functions + Resend でのメールOTP認証において、ローカル環境のみでE2E/ユニットテストを完結させる設計パターンを選定
- Constraints: 本番コードにMock/Stub禁止、Supabaseコンテナ不使用、軽量、一般的なDIパターン採用
- Success Metric: ローカルで npm run e2e/test 完結、本番デプロイ時変更不要、CI環境動作

## PHASE 1: INDEPENDENT MULTI-PERSPECTIVE ANALYSIS

### 🔷 MELCHIOR-01 (Claude) - Comprehensive Reasoning
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 長期的視点、保守性、チーム認知負荷の最小化

Actionable Insights:
- Firebase Auth Emulator のメールフックを第一候補とする – Firebase SDK/Auth Emulator – エミュレータログでOTP取得を確認（懸念: カスタムメール送信のフック可否要確認）
- 環境変数ベースのTransport層DIを採用（本番: Resend SDK、テスト: nodemailer SMTP） – DI Container/環境変数 – E2Eテストで実メール送信なしにOTP検証完了を確認
- Mailpit単体を軽量SMTP受信サーバーとして採用 – Mailpit CLI/Docker（オプション） – `curl http://localhost:8025/api/v1/messages` でOTP含むメール取得成功

### 🔶 BALTHASAR-02 (GPT-5/Codex) - Deep Research & Technical
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 技術調査、実装パターン、ベストプラクティス

Actionable Insights:
- `Mailer`抽象を導入し環境で実装切替（ResendClient / NodemailerSmtpClient） – TypeScript実装 & env切替 / Cloud Functions担当 – `firebase emulators:start --only functions` 下でOTP送信がMailpit UIにHTML表示され、本番は無変更でResend送信を確認
- Mailpitバイナリをdev依存に追加し起動スクリプト作成（例: `npm run mailpit`で1025/8025） – Mailpit公式リリース / DevEx – 開発者が追加セットアップなしで`http://localhost:8025`でOTP確認でき、Port競合なし
- CI用軽量SMTPプロファイルをdocs化（Mailpit推奨、Ethereal代替、環境変数サンプル） – repo docs/README追記 / QA – CIジョブでOTP検証が自動化され、E2Eログに受信メール件名/リンクが残る

**技術所見:**
- Mailpit: Go単体バイナリ、SMTP(1025)+Web(8025)、TLS/HTML対応、軽量、Docker不要
- MailHog: メンテ頻度低、TLS弱、新規採用理由薄
- Ethereal Email: 外部依存、UIなし、TTL短、CIの一時的検証向き
- Firebase Auth Emulator hooks: Auth標準メール送信の代替には便利だが、カスタムOTP/Resend経路との整合が難しく、セットアップが重い

### 🔸 CASPER-03 (Gemini) - Pattern Recognition & Synthesis
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: パターン認識、トレードオフ分析、代替フレーミング

Actionable Insights:
- **Protocol Mismatch問題の解決**: Resend SDK (HTTP) ≠ Mailpit/MailHog (SMTP) → Transport Adapter Pattern必須 – `EmailProvider`インターフェイス定義 / Developer – `process.env.FUNCTIONS_EMULATOR` で NodemailerProvider vs ResendProvider 切り替え確認
- **Mailpit APIによるOTP自動取得**: UI手動確認ではなくREST APIで自動化 – Mailpit API (port 8025) / DevOps – `curl http://localhost:8025/api/v1/messages` が JSON返却、E2Eテストで OTP 自動抽出成功
- **Zero-Docker軽量セットアップ**: docker-compose オーバーヘッド回避 – Mailpit単体バイナリ / Developer – `npm run mail:start` でMailpit起動、`npm run dev` でFirebase Emulators + Mailpit 同時起動

**パターン分析:**
- Next.js/Rails/Django等では環境変数ベースSMTP切り替えが標準的DI手法
- "メールをインターセプト" ではなく "副作用を検証" という視点の転換が重要
- 開発人間工学 vs CI複雑性 vs 本番同等性のトレードオフ

## PHASE 2: FINAL SYNTHESIS & UNIFIED ACTION PLAN

**Synthesis Engine**: CASPER-03 (Gemini) | **Integration Status**: ✓ COMPLETE

### Unified Action Plan

**目的**: `api.resend.com` に触れずに完全なローカルOTPテストを可能にする

**Step 1: EmailProvider 抽象定義 – Cloud Functions担当 – ETA: 30分 – 成果物: `src/lib/email/EmailProvider.ts`**
- TypeScript インターフェイス `EmailProvider { send(to, subject, html): Promise<void> }` を定義
- `ResendProvider` (本番) と `NodemailerProvider` (Dev/Local) を実装
- 検証方法: `process.env.FUNCTIONS_EMULATOR === 'true'` で NodemailerProvider がインスタンス化されることをユニットテストで確認

**Step 2: Mailpitセットアップ – DevEx担当 – ETA: 15分 – 成果物: 起動スクリプト + ドキュメント**
- Mac: `brew install mailpit` で全開発者がインストール
- `package.json` に `"mail": "mailpit --smtp 1025 --ui 8025"` を追加
- 検証方法: `npm run mail` 実行後、`http://localhost:8025` でUI起動確認、`curl http://localhost:8025/api/v1/messages` でAPI応答確認

**Step 3: 環境切り替え実装 – Cloud Functions担当 – ETA: 45分 – 成果物: DI実装コード**
- Cloud Function初期化時に環境変数で Transport切り替え
```typescript
const mailer = process.env.FUNCTIONS_EMULATOR === 'true'
  ? new NodemailerProvider({ host: 'localhost', port: 1025 })
  : new ResendProvider(process.env.RESEND_API_KEY);
```
- 検証方法: `firebase emulators:start` でローカル起動、Function実行時にMailpit UIでメール受信確認、本番デプロイ後にResendダッシュボードでメール送信確認

**Step 4: E2Eテスト自動化 – QA担当 – ETA: 60分 – 成果物: `e2e/firebase-auth.test.ts` 更新**
- Mailpit API経由でOTP自動取得
```typescript
const response = await fetch('http://localhost:8025/api/v1/messages');
const emails = await response.json();
const otp = extractOtpFromEmail(emails.messages[0].html);
```
- 検証方法: `npm run e2e:test` 実行時、手動介入なしでOTP検証フロー完走

### Consensus Highlights
- **全ペルソナ一致**: Mailpit + 環境変数ベースDI（Resend SDK ⇔ Nodemailer SMTP）が最適解
- **Protocol Mismatch認識**: Resend (HTTP) と Mailpit (SMTP) の違いを Transport Adapter Pattern で吸収
- **軽量性**: Docker不要、Go単体バイナリ、メモリ効率良好
- **一般的パターン**: DI/Strategy Patternは Rails/Django/Next.js等で実績多数

### Conflicts / Trade-offs
- **Claude vs Codex/Gemini**: Firebase Auth Emulator フック → Codex/Gemini は「カスタムOTP/Resend経路では機能しない」と判断、Claudeは「要確認」としたが、最終的には **Transport Adapter Pattern に収束**
- **Ethereal Email**: Codex は「CI補助的利用可」、Gemini は「外部依存でローカル完結せず REJECTED」→ 結論: ローカル優先、CIは Mailpit で統一
- **Docker vs バイナリ**: 全員一致で **バイナリ直接実行** を推奨

### Risk & Follow-up

**Risk**: Cloud Functions Emulator から `localhost:1025` への SMTP 接続がファイアウォール/ネットワーク制約で失敗
→ **Mitigation**: `nodemailer.createTransport({ host: '127.0.0.1', port: 1025, secure: false })` で明示的にlocalhost指定、初回セットアップ時に接続テスト実施

**Follow-up Question**: 本番環境で Resend SDK の送信失敗時のリトライ/ログ/監視をどう実装するか？（今回のローカルテスト設計とは別途、本番運用として要検討）

MAGI SYSTEM STATUS: DELIBERATION COMPLETE
```

## 実装優先順位（推奨）

1. **Step 1 + Step 2 を並行実施**（計45分）→ 開発環境でMailpitが即座に使える状態に
2. **Step 3 実装**（45分）→ ローカルで実メール送信なしにOTP検証可能に
3. **Step 4 自動化**（60分）→ CI/E2Eテスト完全自動化

## 次のアクション（ユーザー選択用）

1. Step 1を開始: `EmailProvider.ts` インターフェイス定義を作成
2. Step 2を開始: Mailpitインストール + 起動スクリプト追加
3. 詳細設計レビュー: 3ペルソナの分析ログを精査して追加質問
4. 即座に実装開始: Step 1〜4 を一括でタスク化して実行
5. 代替案検討: 他の選択肢（MailHog/Ethereal）を再評価
