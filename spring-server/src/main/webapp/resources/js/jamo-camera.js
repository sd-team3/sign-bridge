import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { JamoApiClient } from "http://localhost:8000/static/js/api-client.js";

const api = new JamoApiClient("http://localhost:8000");

const cam = new HandCameraWidget({
    videoEl: document.getElementById("video-jamo"),
    canvasEl: document.getElementById("canvas-jamo"),
    onFrame: async (landmarks) => {
        if (!landmarks) return;
        const result = await api.predict(landmarks, false);
        document.getElementById("result-jamo").textContent = result.label;
    },
});

await cam.start();