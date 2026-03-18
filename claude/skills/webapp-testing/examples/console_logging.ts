/**
 * Console Logging Pattern
 * ブラウザのコンソールログ・エラーを収集する
 */
import { chromium } from 'playwright';

async function captureConsoleLogs() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // コンソール・エラー・ネットワーク失敗を収集
  page.on('console', (msg) => console.log('console:', msg.type(), msg.text()));
  page.on('pageerror', (err) => console.log('pageerror:', err.message));
  page.on('requestfailed', (req) => console.log('requestfailed:', req.url(), req.failure()?.errorText));

  await page.goto(process.env.BASE_URL || 'http://localhost:3000');
  await page.waitForLoadState('networkidle');

  // 操作後のログも収集
  // await page.click('button#submit');

  await page.screenshot({ path: '/tmp/console_logging.png', fullPage: true });
  console.log('Screenshot saved: /tmp/console_logging.png');

  await browser.close();
}

captureConsoleLogs();
