const MEDIAPIPE_CDN = new URL("../vendor/mediapipe", import.meta.url).href;
const HAND_MODEL_URL = `${MEDIAPIPE_CDN}/hand_landmarker.task`;

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
      for (const key of ["wasmLoaderPath", "wasmBinaryPath"]) vision[key] += "?v=cors-20261113";
      return await HandLandmarker.createFromOptions(vision, {
        baseOptions: { modelAssetPath: HAND_MODEL_URL, delegate: "CPU" },
        runningMode: "VIDEO", numHands: 1
      });
    })().catch(error => {
      _handLandmarkerPromise = null;
      console.error("손 인식 모델 초기화 실패", error);
      throw new Error("카메라는 연결되었지만 손 인식 모델을 준비하지 못했습니다. 분석 서버 연결을 확인하고 다시 켜 주세요.", { cause: error });
    });
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

export function cameraErrorMessage(error) {
  const messages = {
    NotAllowedError: "카메라 권한이 차단되었습니다. 브라우저에서 카메라를 허용한 뒤 다시 켜 주세요.",
    NotFoundError: "연결된 카메라를 찾을 수 없습니다. USB 연결을 확인한 뒤 다시 켜 주세요.",
    NotReadableError: "카메라를 열지 못했습니다. 다른 앱의 카메라 사용을 종료한 뒤 다시 켜 주세요.",
    OverconstrainedError: "카메라가 요청한 촬영 설정을 지원하지 않습니다. 다른 카메라를 연결해 주세요."
  };
  return messages[error.name] || error.message || "카메라를 시작하지 못했습니다. 다시 켜 주세요.";
}

async function openCameraStream() {
  if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
    throw new Error("카메라는 HTTPS 또는 localhost에서 사용할 수 있습니다.");
  }
  const video = { width: { ideal: 1280, max: 1920 }, height: { ideal: 720, max: 1080 }, frameRate: { ideal: 30, max: 30 }, facingMode: "user" };
  try {
    return await navigator.mediaDevices.getUserMedia({ audio: false, video });
  } catch (error) {
    if (!["NotFoundError", "NotReadableError", "OverconstrainedError"].includes(error.name)) throw error;
    const devices = await navigator.mediaDevices.enumerateDevices();
    for (const device of devices.filter(d => d.kind === "videoinput" && d.deviceId)) {
      try {
        return await navigator.mediaDevices.getUserMedia({ audio: false, video: { ...video, deviceId: { exact: device.deviceId } } });
      } catch (next) {
        if (next.name === "NotAllowedError") throw next;
      }
    }
    throw error;
  }
}

export class HandCameraWidget {
  constructor({ videoEl, canvasEl, onFrame = null, onError = null, drawSkeleton = true, color = "#3ddc97" }) {
    this.videoEl = videoEl;
    this.canvasEl = canvasEl;
    this.ctx = canvasEl ? canvasEl.getContext("2d") : null;
    this.onFrame = onFrame;
    this.onError = onError;
    this.drawSkeleton = drawSkeleton;
    this.color = color;
    this._running = false;
    this._generation = 0;
    this._lastTs = -1;
    this._latest = null;
    this._pending = null;
  }

  async _startCamera(generation) {
    const stream = await openCameraStream();
    if (generation !== this._generation) {
      stream.getTracks().forEach(track => track.stop());
      throw new DOMException("카메라 시작이 취소되었습니다.", "AbortError");
    }
    this.videoEl.srcObject = stream;
    this.videoEl.muted = true;
    this.videoEl.playsInline = true;
    await this.videoEl.play();
    if (generation !== this._generation) throw new DOMException("카메라 시작이 취소되었습니다.", "AbortError");
    if (this.canvasEl) {
      this.canvasEl.width = this.videoEl.videoWidth;
      this.canvasEl.height = this.videoEl.videoHeight;
    }
    stream.getVideoTracks()[0].addEventListener("ended", () => {
      if (this.videoEl.srcObject !== stream) return;
      this.stopCamera();
      this.onError?.(new Error("카메라 연결이 끊겼습니다. 연결을 확인하고 다시 켜 주세요."));
    });
  }

  start() {
    if (this._running) return Promise.resolve();
    if (this._pending) return this._pending;
    const generation = this._generation;
    const pending = (async () => {
      try {
        if (!this.videoEl.srcObject) await this._startCamera(generation);
        this._handLandmarker = await getHandLandmarker();
        if (generation !== this._generation) throw new DOMException("카메라 시작이 취소되었습니다.", "AbortError");
        this._running = true;
        this._loop();
      } catch (error) {
        if (generation === this._generation) this.stopCamera();
        throw error;
      } finally {
        if (this._pending === pending) this._pending = null;
      }
    })();
    this._pending = pending;
    return pending;
  }

  stop() {
    this._running = false;
    this._generation++;
    this._pending = null;
    cancelAnimationFrame(this._animation);
    this._latest = null;
    this._lastTs = -1;
  }

  stopCamera() {
    this.stop();
    const stream = this.videoEl.srcObject;
    if (stream) stream.getTracks().forEach(track => track.stop());
    this.videoEl.srcObject = null;
    this.ctx?.clearRect(0, 0, this.canvasEl.width, this.canvasEl.height);
  }

  getLatestLandmarks() { return this._latest; }

  _loop() {
    if (!this._running) return;
    try {
      if (this.videoEl.readyState >= 2 && this.videoEl.currentTime !== this._lastTs) {
        this._lastTs = this.videoEl.currentTime;
        const result = this._handLandmarker.detectForVideo(this.videoEl, performance.now());
        const raw = result.landmarks?.[0] || null;
        this._latest = raw ? toSelfieCoords(raw) : null;
        if (this.drawSkeleton && this.ctx) drawHandSkeleton(this.ctx, raw, this.canvasEl.width, this.canvasEl.height, this.color);
        if (this.onFrame) Promise.resolve(this.onFrame(this._latest)).catch(() => {});
      }
      this._animation = requestAnimationFrame(() => this._loop());
    } catch (error) {
      this.stopCamera();
      this.onError?.(new Error("손 인식을 계속하지 못했습니다. 카메라를 다시 켜 주세요."));
    }
  }
}
