const MEDIAPIPE_CDN = "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14";
const HAND_MODEL_URL = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task";

const HAND_CONNECTIONS = [
  [0, 1], [1, 2], [2, 3], [3, 4],
  [0, 5], [5, 6], [6, 7], [7, 8],
  [5, 9], [9, 10], [10, 11], [11, 12],
  [9, 13], [13, 14], [14, 15], [15, 16],
  [13, 17], [17, 18], [18, 19], [19, 20],
  [0, 17],
];

let _handLandmarkerPromise = null;

async function getHandLandmarker() {
  if (!_handLandmarkerPromise) {
    _handLandmarkerPromise = (async () => {
      const { HandLandmarker, FilesetResolver } = await import(`${MEDIAPIPE_CDN}/vision_bundle.mjs`);
      const vision = await FilesetResolver.forVisionTasks(`${MEDIAPIPE_CDN}/wasm`);
      return HandLandmarker.createFromOptions(vision, {
        baseOptions: { modelAssetPath: HAND_MODEL_URL, delegate: "GPU" },
        runningMode: "VIDEO",
        numHands: 1,
      });
    })();
  }
  return _handLandmarkerPromise;
}

export function toSelfieCoords(landmarks) {
  return landmarks.map((p) => ({ x: 1 - p.x, y: p.y, z: p.z }));
}

export function drawHandSkeleton(ctx, landmarks, width, height, color = "#3ddc97") {
  ctx.clearRect(0, 0, width, height);
  if (!landmarks) return;

  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  HAND_CONNECTIONS.forEach(([a, b]) => {
    ctx.beginPath();
    ctx.moveTo(landmarks[a].x * width, landmarks[a].y * height);
    ctx.lineTo(landmarks[b].x * width, landmarks[b].y * height);
    ctx.stroke();
  });

  ctx.fillStyle = color;
  landmarks.forEach((p) => {
    ctx.beginPath();
    ctx.arc(p.x * width, p.y * height, 3, 0, 2 * Math.PI);
    ctx.fill();
  });
}

export class HandCameraWidget {
  constructor({ videoEl, canvasEl, onFrame = null, drawSkeleton = true, color = "#3ddc97" }) {
    this.videoEl = videoEl;
    this.canvasEl = canvasEl;
    this.ctx = canvasEl ? canvasEl.getContext("2d") : null;
    this.onFrame = onFrame;
    this.drawSkeleton = drawSkeleton;
    this.color = color;

    this._handLandmarker = null;
    this._running = false;
    this._lastTs = -1;
    this._latest = null;
  }

  async _startCamera() {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480 },
    });
    this.videoEl.srcObject = stream;
    await new Promise((resolve) => { this.videoEl.onloadedmetadata = resolve; });
    if (this.canvasEl) {
      this.canvasEl.width = this.videoEl.videoWidth;
      this.canvasEl.height = this.videoEl.videoHeight;
    }
  }

  async start() {
    if (this._running) return;
    this._handLandmarker = await getHandLandmarker();
    if (!this.videoEl.srcObject) {
      await this._startCamera();
    }
    this._running = true;
    this._loop();
  }

  stop() {
    this._running = false;
  }

  stopCamera() {
    this.stop();
    const stream = this.videoEl.srcObject;
    if (stream) {
      stream.getTracks().forEach((t) => t.stop());
      this.videoEl.srcObject = null;
    }
  }

  getLatestLandmarks() {
    return this._latest;
  }

  _loop() {
    if (!this._running) return;

    if (this.videoEl.readyState >= 2) {
      const ts = performance.now();
      if (ts !== this._lastTs) {
        this._lastTs = ts;
        const result = this._handLandmarker.detectForVideo(this.videoEl, ts);
        const raw = result.landmarks && result.landmarks[0] ? result.landmarks[0] : null;
        this._latest = raw ? toSelfieCoords(raw) : null;

        if (this.drawSkeleton && this.ctx) {
          drawHandSkeleton(this.ctx, raw, this.canvasEl.width, this.canvasEl.height, this.color);
        }
        if (this.onFrame) this.onFrame(this._latest);
      }
    }
    requestAnimationFrame(() => this._loop());
  }
}
