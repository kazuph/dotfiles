# MAGI Session: Firebase Cloud Functions メールOTP認証テスト設計パターン比較

## Situation Snapshot

**Goal:**  
Firebase Cloud Functions + Resend でのメールOTP認証において、**ローカル環境のみでE2E/ユニットテストを完結**させる設計パターンを比較・選定する。

**Constraints:**
1. **本番コードにMock/Stubを絶対に入れない** - テストコード or DI設定のみで切り替え
2. **Supabaseコンテナは使わない** - 以前メモリ数GBを消費して不採用になった経緯あり
3. **軽量であること** - Mailpit単体 or コンテナ不要の選択肢を優先
4. **よくある設計パターンを採用** - 独自実装より一般的なDI/設定切り替え手法

**Success Metrics:**
- ローカルでnpm run e2e または npm run test を実行するだけでメールOTP検証が完結
- 本番デプロイ時は何も変更せずResendにメールが飛ぶ
- CI環境でも同じテストが動作する

## 比較選択肢

1. **Mailpit単体** - Docker不要で起動できるか？軽量か？Cloud Functionsから送信可能か？
2. **MailHog** - Mailpitとの違い、メリット/デメリット
3. **Ethereal Email** - Nodemailer公式のテスト用サービス、ローカル完結か？
4. **環境変数でSMTP切り替え** - Resend SDKではなくnodemailer + SMTP設定でDI
5. **Firebase Auth Emulator のメールフック** - エミュレータ側でメール内容を取得できるか？
6. **その他の選択肢** - 上記以外で有効なものがあれば

## 質問

- Cloud Functions Emulator から localhost の Mailpit/MailHog に SMTP 接続できるか？
- Resend SDK を本番で使いつつ、ローカルではnodemailer+SMTPに差し替えるDIパターンは一般的か？
- Firebase Auth Emulator にはOTPメールをインターセプトする機能があるか？

## 出力要件

docs/OUTPUT_TEMPLATE.md の形式に従い、3ペルソナ（Codex/Gemini/Claude）の見解を統合した結論を出してください。

---
Session Start: $(date -Iseconds)
