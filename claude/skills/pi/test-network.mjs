import { mkdirSync, writeFileSync, existsSync } from 'fs';
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
console.log('VM created');

// Test: Can VM make HTTPS request?
const code = `
const https = require('https');
const req = https.get('https://httpbin.org/get', (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => console.log('HTTP ' + res.statusCode + ' len=' + data.length));
});
req.on('error', (e) => console.error('ERROR: ' + e.message));
req.setTimeout(10000, () => { console.error('TIMEOUT'); req.destroy(); });
`;

const { pid } = os.spawn("node", ["-e", code]);
os.onProcessStdout(pid, (data) => process.stdout.write('[out] ' + new TextDecoder().decode(data)));
os.onProcessStderr(pid, (data) => process.stderr.write('[err] ' + new TextDecoder().decode(data)));

const exit = await Promise.race([
  os.waitProcess(pid),
  new Promise(r => setTimeout(() => r('timeout'), 15000)),
]);
console.log('exit:', exit);
await os.dispose();
