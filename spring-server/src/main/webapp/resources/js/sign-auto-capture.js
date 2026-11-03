(() => {
  'use strict';
  class Gate {
    constructor() { this.reset(); }
    reset(requireClear = false) {
      this.requireClear = requireClear;
      this.presentAt = null;
      this.absentAt = null;
      this.recordedAt = null;
    }
    update(count, now, phase, ready = true) {
      if (!ready) { this.presentAt = this.absentAt = null; return null; }
      if (phase === 'recording') {
        if (count > 0) this.absentAt = null;
        else if (this.absentAt === null) this.absentAt = now;
        if (this.absentAt !== null && now - this.absentAt >= 900 && now - this.recordedAt >= 2000) return 'finish';
        return null;
      }
      if (!['idle', 'result'].includes(phase)) { this.presentAt = this.absentAt = null; return null; }
      if (count === 0) {
        this.presentAt = null;
        if (this.absentAt === null) this.absentAt = now;
        if (now - this.absentAt >= 600) this.requireClear = false;
        return null;
      }
      this.absentAt = null;
      if (this.requireClear) return null;
      if (this.presentAt === null) this.presentAt = now;
      if (now - this.presentAt < 150) return null;
      this.requireClear = true;
      this.recordedAt = now;
      this.presentAt = null;
      return 'start';
    }
  }

  class Presence {
    constructor(url, onCount, onError) {
      this.url = url;
      this.onCount = onCount;
      this.onError = onError;
      this.generation = 0;
    }
    async start(video) {
      this.stop();
      const generation = this.generation;
      this.video = video;
      const worker = this.worker = new Worker(this.url);
      this.busy = false;
      this.lastSent = -Infinity;
      this.lastFrame = -1;
      await new Promise((resolve, reject) => {
        this.rejectStart = reject;
        this.loadTimer = setTimeout(() => {
          this.rejectStart = null;
          this.stop();
          reject(new Error('손 감지를 준비하는 데 시간이 걸리고 있어요. 네트워크 연결을 확인하고 카메라를 다시 켜 주세요.'));
        }, 45000);
        const fail = () => {
          if (generation !== this.generation) return;
          const error = new Error('손 감지를 시작하지 못했어요. 네트워크 연결을 확인하고 카메라를 다시 켜 주세요.');
          const loading = !!this.rejectStart;
          this.rejectStart = null;
          this.stop();
          reject(error);
          if (!loading && generation === this.generation - 1) this.onError(error);
        };
        worker.onerror = fail;
        worker.onmessage = event => {
          if (generation !== this.generation) return;
          if (event.data.type === 'ready') {
            clearTimeout(this.loadTimer); this.rejectStart = null;
            resolve(); this.loop(generation);
          } else if (event.data.type === 'count') {
            this.busy = false;
            this.onCount(event.data.count, performance.now());
          } else if (event.data.type === 'error') fail();
        };
        worker.postMessage({ type: 'init' });
      });
    }
    async loop(generation) {
      if (generation !== this.generation || !this.worker) return;
      const video = this.video;
      const now = performance.now();
      if (!this.busy && !document.hidden && video.readyState >= 2 && video.videoWidth && now - this.lastSent >= 100 && video.currentTime !== this.lastFrame) {
        this.busy = true; this.lastSent = now; this.lastFrame = video.currentTime;
        try {
          const width = Math.min(480, video.videoWidth);
          const frame = await createImageBitmap(video, { resizeWidth: width, resizeHeight: Math.max(1, Math.round(video.videoHeight * width / video.videoWidth)) });
          if (generation !== this.generation || !this.worker) { frame.close(); return; }
          this.worker.postMessage({ type: 'frame', frame, timestamp: now }, [frame]);
        } catch (_) {
          if (generation === this.generation) {
            this.stop();
            this.onError(new Error('카메라 화면에서 손을 확인하지 못했어요. 카메라를 다시 켜 주세요.'));
          }
          return;
        }
      }
      this.animation = requestAnimationFrame(() => this.loop(generation));
    }
    stop() {
      this.generation++;
      clearTimeout(this.loadTimer);
      cancelAnimationFrame(this.animation);
      this.worker?.terminate(); this.worker = null;
      const reject = this.rejectStart; this.rejectStart = null;
      if (reject) reject(new Error('손 감지 준비가 취소됐어요. 카메라를 다시 켜 주세요.'));
    }
  }
  window.SignAutoCapture = { Gate, Presence };
})();
