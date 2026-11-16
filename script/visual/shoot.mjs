// Screenshots a list of pages from one server via headless Chrome (CDP, no deps).
// usage: node script/visual/shoot.mjs <baseUrl> <outDir> (see CLAUDE.md, "Visual regression check")
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [base, outDir] = process.argv.slice(2);
mkdirSync(outDir, { recursive: true });

const PUBLIC = [
  ['landing', '/'],
  ['privacy', '/privacy'],
  ['about-motivation', '/about/motivation'],
  ['about-organisation', '/about/organisation'],
  ['about-open', '/about/open'],
  ['about-pricing', '/about/pricing'],
  ['about-comparison', '/about/comparison'],
  ['login', '/login'],
  ['login-da', '/login?locale=da'],
  ['verify-password-known', '/verify_password?email=visual%40example.com'],
  ['verify-human', '/registrations/verify_human?email=new%40example.com'],
  ['verify-email', '/registrations/verify_email?email=pending%40example.com'],
  ['create-password', '/registrations/create_password?email=pending%40example.com&email_verification_code=AB7K'],
  ['password-new', '/password/new'],
  ['password-wait', '/password/wait'],
  ['admin-relying-parties', '/admin/relying_parties'],
];
const SIGNED_IN = [
  ['me', '/me'],
  ['password-edit', '/password/edit'],
  ['email-edit', '/email/edit'],
  ['uniq', '/uniq'],
];
const VIEWPORTS = [['desktop', 1280, 900, false], ['mobile', 390, 844, true]];

const profile = mkdtempSync(join(tmpdir(), 'visual-chrome-'));
const port = 9300 + Math.floor(Math.random() * 500);
const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
  '--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  '--hide-scrollbars', '--force-device-scale-factor=1', '--disable-gpu', '--font-render-hinting=none',
  '--no-first-run', '--no-default-browser-check', 'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let wsUrl;
for (let i = 0; i < 50 && !wsUrl; i++) {
  try {
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    wsUrl = targets.find((t) => t.type === 'page')?.webSocketDebuggerUrl;
  } catch { await sleep(200); }
}

const ws = new WebSocket(wsUrl);
await new Promise((r) => ws.addEventListener('open', r));
let id = 0;
const pending = new Map();
const listeners = [];
ws.addEventListener('message', (e) => {
  const msg = JSON.parse(e.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  else listeners.forEach((l) => l(msg));
});
const send = (method, params = {}) => new Promise((resolve, reject) => {
  const n = ++id;
  pending.set(n, (m) => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
  ws.send(JSON.stringify({ id: n, method, params }));
});
const loaded = () => new Promise((r) => {
  const l = (m) => { if (m.method === 'Page.loadEventFired') { listeners.splice(listeners.indexOf(l), 1); r(); } };
  listeners.push(l);
});
const evaluate = async (expression) => (await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })).result.value;

await send('Page.enable');
await send('Runtime.enable');
// Same clock for local-time rendering on both servers.
await send('Emulation.setTimezoneOverride', { timezoneId: 'Europe/Copenhagen' });

// Freeze motion: finish finite animations, rewind infinite ones, hide carets and
// the third-party Turnstile iframe (its content is Cloudflare's, not ours).
const FREEZE = `(() => {
  const s = document.createElement('style');
  s.textContent = '*{caret-color:transparent!important} .cf-turnstile iframe{visibility:hidden!important}';
  document.head.appendChild(s);
  document.getAnimations().forEach((a) => { try { a.finish(); } catch (e) { a.pause(); a.currentTime = 0; } });
  if (document.activeElement) document.activeElement.blur();
  return document.documentElement.scrollHeight;
})()`;

async function shoot(name, path) {
  for (const [vp, width, height, mobile] of VIEWPORTS) {
    await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile });
    const done = loaded();
    await send('Page.navigate', { url: base + path });
    await done;
    await sleep(1500);
    const fullHeight = await evaluate(FREEZE);
    await sleep(300);
    const finalUrl = await evaluate('location.pathname + location.search');
    await send('Emulation.setDeviceMetricsOverride', { width, height: Math.min(fullHeight, 12000), deviceScaleFactor: 1, mobile });
    await sleep(300);
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(outDir, `${name}--${vp}.png`), Buffer.from(data, 'base64'));
    writeFileSync(join(outDir, `${name}--${vp}.url`), finalUrl);
  }
}

for (const [name, path] of PUBLIC) await shoot(name, path);

const signIn = loaded();
await send('Page.navigate', { url: `${base}/login` });
await signIn;
const status = await evaluate(`fetch('/authenticate', { method: 'POST', credentials: 'include', redirect: 'manual',
  body: new URLSearchParams({ email: 'visual@example.com', password: 'visual-secret', remember_me: '1' }) })
  .then((r) => r.type + ' ' + r.status)`);
console.log('sign-in:', status);
for (const [name, path] of SIGNED_IN) await shoot(name, path);

ws.close();
chrome.kill();
console.log('done', outDir);
