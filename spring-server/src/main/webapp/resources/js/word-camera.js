import { HandCameraWidget, cameraErrorMessage } from "/api/sign/assets/js/hand-camera.js?v=20261113cpu";
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
    onError: showCameraError,
    onFrame: (landmarks) => signInput.submitFrame(landmarks),
});
const on = document.getElementById("motion-camera-on");
const off = document.getElementById("motion-camera-off");
const status = document.getElementById("motion-camera-status");
function showCameraError(error) {
    on.disabled = false; off.disabled = true;
    status.textContent = cameraErrorMessage(error);
}
on.addEventListener("click", async () => {
    if (on.disabled) return;
    on.disabled = true; off.disabled = false;
    status.textContent = "카메라와 손 인식을 준비하고 있어요…";
    try {
        await cam.start();
        status.textContent = "카메라가 준비됐어요. 손을 화면에 보여 주세요.";
    } catch (error) { if (error.name !== "AbortError") showCameraError(error); }
});
off.addEventListener("click", () => {
    cam.stopCamera(); on.disabled = false; off.disabled = true;
    status.textContent = "카메라가 꺼졌습니다.";
});
window.addEventListener("pagehide", () => cam.stopCamera());