import { mkdirSync, writeFileSync, existsSync, readFileSync } from 'fs';
import { dirname, join } from 'path';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const stdlibPath = dirname(require.resolve('node-stdlib-browser/package.json'));
['mock', 'proxy'].forEach(d => mkdirSync(join(stdlibPath, d), { recursive: true }));
if (!existsSync(join(stdlibPath, 'mock/empty.js'))) writeFileSync(join(stdlibPath, 'mock/empty.js'), 'module.exports = {};');
for (const m of ['process','buffer','console','constants','domain','events','http','https','os','path','querystring','stream','string_decoder','sys','timers','tty','url','util','vm','zlib','punycode','assert','crypto']) {
  const p = join(stdlibPath, 'proxy', m+'.js');
  if (!existsSync(p)) writeFileSync(p, `module.exports = require('${m}');`);
}

import { AgentOs } from '@rivet-dev/agent-os-core';
const common = (await import('@rivet-dev/agent-os-common')).default;
const os = await AgentOs.create({ software: [common] });
console.log('VM ready');

function getApiKey() {
  if (process.env.FIREWORKS_API_KEY) return process.env.FIREWORKS_API_KEY.trim();
  return readFileSync('/tmp/.agent-os-fireworks-key', 'utf-8').trim();
}

const apiKey = getApiKey();

const code = `
const https = require('https');
const data = JSON.stringify({
  model: 'accounts/fireworks/models/kimi-k2p5',
  messages: [{ role: 'user', content: 'say hi' }],
  max_tokens: 50
});
const req = https.request({
  hostname: 'api.fireworks.ai',
  path: '/inference/v1/chat/completions',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${apiKey}'
  }
}, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => console.log('RESPONSE: HTTP ' + res.statusCode + ' ' + body.substring(0, 200)));
});
req.on('error', (e) => console.error('ERROR: ' + e.message));
req.setTimeout(15000, () => { console.error('TIMEOUT'); req.destroy(); });
req.write(data);
req.end();
`;

const { pid } = os.spawn("node", ["-e", code]);
os.onProcessStdout(pid, (d) => process.stdout.write(new TextDecoder().decode(d)));
os.onProcessStderr(pid, (d) => process.stderr.write(new TextDecoder().decode(d)));
const exit = await Promise.race([os.waitProcess(pid), new Promise(r => setTimeout(() => r('timeout'), 20000))]);
console.log('exit:', exit);
await os.dispose();
