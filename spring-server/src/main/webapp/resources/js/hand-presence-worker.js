let detector;
self.onmessage = async event => {
  const data = event.data;
  try {
    if (data.type === 'init') {
      const cdn = '/api/sign/assets/vendor/mediapipe';
      const { HandLandmarker, FilesetResolver } = await import(cdn + '/vision_bundle.mjs');
      const vision = await FilesetResolver.forVisionTasks(cdn + '/wasm');
      detector = await HandLandmarker.createFromOptions(vision, {
        baseOptions: { modelAssetPath: '/api/sign/assets/vendor/mediapipe/hand_landmarker.task', delegate: 'CPU' },
        runningMode: 'VIDEO', numHands: 2,
        minHandDetectionConfidence: .5, minHandPresenceConfidence: .5, minTrackingConfidence: .5
      });
      self.postMessage({ type: 'ready' });
    } else if (data.type === 'frame') {
      try {
        const result = detector.detectForVideo(data.frame, data.timestamp);
        self.postMessage({ type: 'count', count: result.landmarks.length });
      } finally { data.frame.close(); }
    }
  } catch (_) { self.postMessage({ type: 'error' }); }
};

