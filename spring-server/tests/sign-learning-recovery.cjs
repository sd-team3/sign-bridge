const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');
const root = process.argv[2] || path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'src/main/webapp/WEB-INF/views/learn/signs.jsp'), 'utf8')
  .replace(/<%[\s\S]*?%>/g, '').replace(/<jsp:include[^>]*\/>/g, '').replace(/<c:url value='([^']+)'\/>/g, '$1').replace(/\$\{[^}]*\}/g, '');
const tick = () => new Promise(resolve => setTimeout(resolve, 15));
async function check(status) {
  const dom = new JSDOM(html, { url: 'https://sign.test/learn/signs', runScripts: 'outside-only', pretendToBeVisual: true });
  const w = dom.window;
  try {
    w.document.getElementById('sign-learning').dataset.signedIn = 'true';
    w.HTMLMediaElement.prototype.load = function () {};
    w.HTMLMediaElement.prototype.play = async function () {};
    w.HTMLMediaElement.prototype.pause = function () {};
    let now = 0, presence, stopped = 0, starts = 0;
    Object.defineProperty(w.performance, 'now', { value: () => now });
    Object.defineProperty(w, 'isSecureContext', { value: true });
    const track = { stop() { stopped++; }, addEventListener() {}, getSettings() { return { width: 1280, height: 720 }; } };
    Object.defineProperty(w.navigator, 'mediaDevices', { value: { getUserMedia: async () => ({ getTracks: () => [track], getVideoTracks: () => [track] }) } });
    class Recorder extends w.EventTarget {
      static isTypeSupported() { return true; }
      constructor(stream, options) { super(); this.mimeType = options.mimeType; this.state = 'inactive'; }
      start() { this.state = 'recording'; starts++; }
      stop() {
        this.state = 'inactive';
        const event = new w.Event('dataavailable');
        event.data = new w.Blob(['video'], { type: this.mimeType });
        this.dispatchEvent(event);
        this.dispatchEvent(new w.Event('stop'));
      }
    }
    w.MediaRecorder = Recorder;
    w.eval(fs.readFileSync(path.join(root, 'src/main/webapp/resources/js/sign-auto-capture.js'), 'utf8'));
    w.SignAutoCapture.Presence = class {
      constructor(url, onCount) { presence = onCount; }
      async start() {}
      stop() {}
    };
    w.SignCoaching = { render() {} };
    const word = { word_id: 'WORD0001', chapter_id: 'chapter-01', label: '나', order: 1 };
    const chapter = { chapter_id: 'chapter-01', title: '기초', order: 1, word_count: 1, words: [word] };
    const attempts = [];
    w.fetch = async (url, options = {}) => {
      let data;
      if (url.endsWith('/evaluate-video')) {
        attempts.push(options.body.get('attempt_id'));
        if (attempts.length === 1) return { ok: false, status, json: async () => ({ message: '다시 촬영해 주세요. (VIDEO_FRAMES)' }) };
        data = { status: 'ok', attempt_id: options.body.get('attempt_id'), target_word_id: word.word_id, recognition: { target_matches_top1: true, accepted: true, predicted_label: '나' }, feedback: {} };
      } else if (url.endsWith('/chapters')) data = { chapters: [chapter], total_words: 1 };
      else if (url.includes('/chapters/')) data = chapter;
      else if (url.includes('/words/')) data = word;
      else throw new Error(url);
      return { ok: true, json: async () => data };
    };
    w.eval(fs.readFileSync(path.join(root, 'src/main/webapp/resources/js/sign-learning.js'), 'utf8'));
    const el = id => w.document.getElementById('sl-' + id);
    const hands = (count, time) => { now = time; presence(count, now); };
    await tick();
    el('reference').dispatchEvent(new w.Event('loadeddata'));
    el('start-camera').click();
    await tick();
    hands(1, 100); hands(1, 300);
    assert.equal(starts, 1);
    hands(0, 2500); hands(0, 3500);
    await tick();
    assert.equal(attempts.length, 1);
    if (status === 401) {
      assert.equal(stopped, 1);
      hands(0, 4000); hands(0, 4700); hands(1, 4800); hands(1, 5000);
      assert.equal(starts, 1);
      return;
    }
    assert.equal(stopped, 0);
    assert.equal(el('resubmit').hidden, [413, 415, 422].includes(status));
    hands(1, 4000); hands(1, 4500);
    assert.equal(starts, 1);
    hands(0, 5000); hands(0, 5700); hands(1, 5800); hands(1, 6000);
    assert.equal(starts, 2);
    hands(0, 8500); hands(0, 9500);
    await tick();
    assert.equal(attempts.length, 2);
    assert.notEqual(attempts[0], attempts[1]);
    assert.equal(el('result').hidden, false);
    assert.match(el('recognition').textContent, /인식됐어요/);
  } finally {
    w.dispatchEvent(new w.Event('pagehide'));
    dom.window.close();
  }
}
(async () => {
  for (const status of [422, 413, 415, 500, 401]) await check(status);
  console.log('LEARNING_RECOVERY_OK: retake after invalid video and server error, fresh attempt, camera continuity, login guard');
})().catch(error => { console.error(error); process.exitCode = 1; });

