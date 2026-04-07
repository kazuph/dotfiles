import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'fs';
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

import { AgentOs, createHostDirBackend } from '@rivet-dev/agent-os-core';
const common = (await import('@rivet-dev/agent-os-common')).default;
const apiKey = readFileSync('/tmp/.agent-os-fireworks-key', 'utf-8').trim();
const agentDir = join(dirname(new URL(import.meta.url).pathname), '.pi-agent');

const os = await AgentOs.create({
  software: [common],
  mounts: [
    { path: '/workspace', driver: createHostDirBackend({ hostPath: '/tmp/pi-workspace', readOnly: false }) },
    { path: '/home/user/.pi/agent', driver: createHostDirBackend({ hostPath: agentDir, readOnly: true }) },
  ],
});

const session = await os.createSession("pi", {
  cwd: "/workspace",
  env: { PI_CODING_AGENT_DIR: "/home/user/.pi/agent", FIREWORKS_API_KEY: apiKey, HOME: "/home/user" },
});
console.log("Session:", session.sessionId);

// Capture ALL events
os.onSessionEvent(session.sessionId, (event) => {
  console.log("[EVENT]", JSON.stringify(event));
});

// Send prompt
console.log("\nSending prompt...");
const result = await os.prompt(session.sessionId, "hello");
console.log("\n[RESULT]", JSON.stringify(result));

await os.dispose();
