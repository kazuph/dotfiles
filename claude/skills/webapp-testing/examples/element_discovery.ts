/**
 * Element Discovery Pattern
 * ページの要素を探索してセレクタを特定する
 */
import { chromium } from 'playwright';

async function discoverElements() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.goto(process.env.BASE_URL || 'http://localhost:3000');
  await page.waitForLoadState('networkidle');

  // ボタン一覧
  const buttons = await page.getByRole('button').all();
  for (const btn of buttons) {
    console.log('Button:', await btn.textContent());
  }

  // リンク一覧
  const links = await page.getByRole('link').all();
  for (const link of links) {
    console.log('Link:', await link.textContent(), '->', await link.getAttribute('href'));
  }

  // 入力フィールド一覧
  const inputs = await page.locator('input').all();
  for (const input of inputs) {
    const name = await input.getAttribute('name');
    const type = await input.getAttribute('type');
    console.log('Input:', name, `(${type})`);
  }

  // フルページスクリーンショット
  await page.screenshot({ path: '/tmp/element_discovery.png', fullPage: true });
  console.log('Screenshot saved: /tmp/element_discovery.png');

  await browser.close();
}

discoverElements();
