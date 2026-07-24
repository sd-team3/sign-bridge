import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { SignInputSession } from "/resources/js/sign-input.js";

const signInput = new SignInputSession({
    onUpdate: (data) => {
        document.getElementById("result-word").textContent = data.composedText || "";
        document.getElementById("progressFill").style.width = `${(data.holdProgress || 0) * 100}%`;
    },
});

const cam = new HandCameraWidget({
    videoEl: document.getElementById("video-word"),
    canvasEl: document.getElementById("canvas-word"),
    onFrame: (landmarks) => signInput.submitFrame(landmarks),
});
await cam.start();