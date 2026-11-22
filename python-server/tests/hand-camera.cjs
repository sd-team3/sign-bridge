const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.argv[2] || path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'static/js/hand-camera.js'), 'utf8')
  .replace(/export /g, '').replace('import.meta.url', '"http://localhost/static/js/hand-camera.js"').replace('await import(`${MEDIAPIPE_CDN}/vision_bundle.mjs`)', 'await loadVision()');
function fixture() {
  const requests = [], delegates = [];
  let stopped = 0, played = 0, enumerated = 0, ended;
  const track = { stop() { stopped++; }, addEventListener(type, fn) { ended = fn; } };
  const stream = { getTracks: () => [track], getVideoTracks: () => [track] };
  const model = { detectForVideo: () => ({ landmarks: [] }) };
  const video = { srcObject: null, readyState: 2, currentTime: 0, videoWidth: 1280, videoHeight: 720, async play() { played++; } };
  const canvas = { getContext: () => ({ clearRect() {} }) };
  const ctx = {
    URL,
    window: { isSecureContext: true }, DOMException, performance: { now: () => 1 },
    requestAnimationFrame: () => 1, cancelAnimationFrame() {},
    navigator: { mediaDevices: {
      async getUserMedia(options) { requests.push(options); return stream; },
      async enumerateDevices() { enumerated++; return [{ kind: 'videoinput', deviceId: 'usb-camera' }]; }
    } },
    async loadVision() { return {
      FilesetResolver: { forVisionTasks: async () => ({}) },
      HandLandmarker: { async createFromOptions(v, options) { delegates.push(options.baseOptions.delegate); return model; } }
    }; }
  };
  vm.createContext(ctx);
  vm.runInContext(source + '\nglobalThis.Widget = HandCameraWidget;', ctx);
  const widget = new ctx.Widget({ videoEl: video, canvasEl: canvas });
  return { ctx, widget, requests, delegates, video, canvas, stream, model, track,
    stopped: () => stopped, played: () => played, enumerated: () => enumerated, end: () => ended() };
}
(async () => {
  {
    const f = fixture();
    const a = f.widget.start(), b = f.widget.start();
    assert.equal(a, b);
    await a;
    assert.equal(f.played(), 1);
    assert.equal(f.requests.length, 1);
    assert.equal(f.requests[0].audio, false);
    assert.equal(f.requests[0].video.width.ideal, 1280);
    assert.equal(f.requests[0].video.deviceId, undefined);
    assert.equal(f.canvas.width, 1280);
    f.widget.stop(); await f.widget.start();
    assert.equal(f.requests.length, 1);
    f.end(); assert.equal(f.video.srcObject, null);
  }
  {
    const f = fixture();
    const open = f.ctx.navigator.mediaDevices.getUserMedia;
    f.ctx.navigator.mediaDevices.getUserMedia = async options => {
      if (!options.video.deviceId) throw new DOMException('unavailable', 'NotReadableError');
      return open(options);
    };
    await f.widget.start();
    assert.equal(f.requests[0].video.deviceId.exact, 'usb-camera');
    f.widget.stopCamera();
  }
  {
    const f = fixture();
    f.ctx.navigator.mediaDevices.getUserMedia = async () => { throw new DOMException('denied', 'NotAllowedError'); };
    await assert.rejects(f.widget.start(), { name: 'NotAllowedError' });
    assert.equal(f.enumerated(), 0);
  }
  {
    const f = fixture();
    let fail = true;
    f.ctx.loadVision = async () => ({
      FilesetResolver: { forVisionTasks: async () => ({}) },
      HandLandmarker: { async createFromOptions(v, options) {
        f.delegates.push(options.baseOptions.delegate);
        if (fail) throw new Error('model failure');
        return f.model;
      } }
    });
    await assert.rejects(f.widget.start(), /손 인식 모델/);
    assert.equal(f.stopped(), 1);
    assert.equal(f.video.srcObject, null);
    fail = false;
    await f.widget.start();
    assert.deepEqual(f.delegates, ['CPU', 'CPU']);
    f.widget.stopCamera();
  }
  {
    const f = fixture();
    let resolve;
    f.ctx.navigator.mediaDevices.getUserMedia = () => new Promise(done => { resolve = done; });
    const pending = f.widget.start();
    f.widget.stopCamera();
    resolve(f.stream);
    await assert.rejects(pending, { name: 'AbortError' });
    assert.equal(f.stopped(), 1);
    assert.equal(f.video.srcObject, null);
    assert.equal(f.played(), 0);
  }
  console.log('HAND_CAMERA_OK: playback, shared constraints, alternate device, permission guard, CPU initialization, retry, cancellation, cleanup');
})().catch(error => { console.error(error); process.exitCode = 1; });

