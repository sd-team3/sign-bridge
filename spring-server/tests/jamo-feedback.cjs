const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');
const root = process.argv[2] || path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'src/main/webapp/WEB-INF/views/learn/jamo.jsp'), 'utf8')
  .replace(/<%[\s\S]*?%>/g, '').replace(/\$\{[^}]*\}/g, '');
const dom = new JSDOM(html, { runScripts: 'outside-only', url: 'https://test.local/learn/jamo' });
const w = dom.window;
let frame, now = 10000, requests = [], failCoach = false, delayedCoach;
w.Date.now = () => now;
w.console.error = () => {};
w.HandCameraWidget = class {
  constructor(options) { frame = options.onFrame; }
  async start() {}
  stopCamera() {}
};
w.cameraErrorMessage = error => error.message;
w.JamoApiClient = class {
  async predict() { return { label: w.currentJamoChar, confidence: .99 }; }
  async coach(landmarks, target) {
    requests.push(target);
    if (failCoach) throw Error('network');
    if (delayedCoach) return delayedCoach;
    return { kind: 'perfect', tip: '기존 서버 문구' };
  }
};
w.eval(fs.readFileSync(path.join(root, 'src/main/webapp/resources/js/jamo-camera.js'), 'utf8')
  .replace(/^import .*;\r?\n/gm, ''));
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
const landmarks = Array.from({length:21}, () => ({x:.2,y:.3,z:0}));
(async () => {
  const camera = w.document.getElementById('jdCam');
  const on = w.document.getElementById('jd-camera-on');
  assert(camera.compareDocumentPosition(on) & w.Node.DOCUMENT_POSITION_FOLLOWING);
  assert(!w.document.body.textContent.includes('카메라 켜기를 눌러 주세요'));
  on.click();
  await tick();
  for (const vowel of ['ㅔ', 'ㅚ', 'ㅟ', 'ㅢ']) {
    w.currentJamoChar = vowel;
    w.resetJamoFeedback();
    await frame(landmarks);
    now += 1300;
    await frame(landmarks);
    await tick();
    assert.equal(requests.at(-1), vowel);
    assert.equal(w.document.getElementById('result').textContent, '✅ 정답! (' + vowel + ')');
    assert.equal(w.document.getElementById('coachTip').textContent, '✨ 완벽합니다!');
  }
  failCoach = true;
  now += 3100;
  await frame(landmarks);
  await tick();
  assert.match(w.document.getElementById('coachTip').textContent, /불러오지 못/);
  failCoach = false;
  now += 3100;
  await frame(landmarks);
  await tick();
  assert.equal(w.document.getElementById('coachTip').textContent, '✨ 완벽합니다!');
  let finish;
  delayedCoach = new Promise(resolve => { finish = resolve; });
  now += 3100;
  await frame(landmarks);
  w.currentJamoChar = 'ㅏ';
  w.resetJamoFeedback();
  finish({ kind: 'advice', tip: '이전 모음의 피드백' });
  await tick();
  assert.equal(w.document.getElementById('coachTip').style.display, 'none');
  delayedCoach = null;
  w.stopJamoCam();
  assert.equal(w.document.getElementById('result').textContent, '');
  console.log('JAMO_FEEDBACK_OK: four vowels, success message, recovery, stale-response guard and camera layout');
})().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => dom.window.close());
