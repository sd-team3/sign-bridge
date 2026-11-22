const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');
const root = process.argv[2] || path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'src/main/webapp/WEB-INF/views/learn/jamo.jsp'), 'utf8')
  .replace(/<%[\s\S]*?%>/g, '').replace(/\$\{[^}]*\}/g, '');
const dom = new JSDOM(html, { runScripts: 'outside-only', url: 'http://localhost/learn/jamo' });
const w = dom.window;
let fail = true, starts = 0, stops = 0;
w.HandCameraWidget = class {
  constructor(options) { this.options = options; }
  async start() { starts++; if (fail) throw new Error('카메라 권한을 확인해 주세요'); }
  stopCamera() { stops++; }
};
w.cameraErrorMessage = error => error.message;
w.JamoApiClient = class {};
w.eval(fs.readFileSync(path.join(root, 'src/main/webapp/resources/js/jamo-camera.js'), 'utf8').replace(/^import .*;\r?\n/gm, ''));
const tick = () => new Promise(resolve => setTimeout(resolve, 10));
(async () => {
  const on = w.document.getElementById('jd-camera-on'), off = w.document.getElementById('jd-camera-off');
  assert.equal(on.textContent, '카메라 켜기');
  w.document.getElementById('jdCam').click();
  assert.equal(starts, 0);
  on.click(); await tick();
  assert.equal(on.disabled, false);
  assert.equal(w.jamoCamStarted, false);
  assert.match(w.document.getElementById('jd-camera-status').textContent, /권한/);
  fail = false;
  on.click(); await tick();
  assert.equal(on.disabled, true);
  assert.equal(off.disabled, false);
  assert.equal(w.jamoCamStarted, true);
  off.click();
  assert.equal(w.jamoCamStarted, false);
  assert.equal(on.disabled, false);
  assert.equal(off.disabled, true);
  assert(stops >= 2);
  console.log('JAMO_CONTROLS_OK: explicit buttons, visible error, retry and stop');
})().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => dom.window.close());
