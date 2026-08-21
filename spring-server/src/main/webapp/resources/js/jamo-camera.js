// jamo-camera.js
// 자모 학습 페이지(jamo.jsp)의 카메라 인식 로직.
//
// 기존에는 Python 서버(JamoApiClient)를 직접 호출해서 인식만 하고 끝났는데,
// 그러면 Spring을 거치지 않아서 recognition_confirm_log에 아무것도 안 쌓였다.
// word-camera.js / dict-camera.js와 동일하게 SignInputSession(/api/sign/frame)을
// 태우도록 바꿔서, hold(1.2초 유지) 판정과 로그 저장(RecognitionLogService)을
// 그대로 재사용한다. 정답 여부(target과 일치하는지) 판정은 지금처럼 프론트에서만 한다.
import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { SignInputSession } from "/resources/js/sign-input.js";

window.jamoCamStarted = false;
window.currentJamoChar = null;

const resultEl = document.getElementById("result");

// 정답/오답 문구가 뜬 뒤 바로 다음 프레임(raw label)에 덮어써지지 않도록
// 이 시간 동안은 화면 갱신을 잠깐 붙잡아둔다 (사용자가 결과를 읽을 시간을 줌)
const FEEDBACK_HOLD_MS = 1500;
let feedbackLockUntil = 0;

const signInput = new SignInputSession({
  onUpdate: (data) => {
    const now = performance.now();
    if (now < feedbackLockUntil) return; // 정답/오답 문구 유지 중이면 아무것도 안 함

    // 타겟 자모를 아직 선택 안 한 상태 -> 지금 인식되고 있는 raw label만 보여줌 (판정 없음)
    if (!window.currentJamoChar) {
      resultEl.textContent = data.rawLabel || '';
      resultEl.style.color = '';
      return;
    }

    // 1.2초 유지가 끝나서 서버가 이번 프레임에 "확정"한 경우에만 정답 판정
    if (data.confirmedChar) {
      const isCorrect = data.confirmedChar === window.currentJamoChar;
      resultEl.textContent = isCorrect
        ? '✅ 정답! (' + data.confirmedChar + ')'
        : '❌ 오답 (' + data.confirmedChar + ')';
      resultEl.style.color = isCorrect ? '#2D9B6F' : '#D85A30';
      feedbackLockUntil = now + FEEDBACK_HOLD_MS;
      return;
    }

    // 아직 유지 중 / 확정 전 -> raw label만 참고용으로 표시
    if (data.rawLabel) {
      resultEl.textContent = data.rawLabel;
      resultEl.style.color = '';
    } else {
      resultEl.textContent = '';
      resultEl.style.color = '';
    }
  },
});

const cam = new HandCameraWidget({
  videoEl: document.getElementById("video"),
  canvasEl: document.getElementById("canvas"),
  onFrame: (landmarks) => {
    if (!landmarks) {
      // 손을 화면에서 내리면(인식 안 되면) 직전 정답/오답 문구를 바로 지운다.
      // submitFrame은 landmarks가 없으면 서버로 아예 안 보내서 onUpdate가 안 불리기 때문에
      // 여기서 직접 처리해야 함.
      feedbackLockUntil = 0;
      resultEl.textContent = '';
      resultEl.style.color = '';
      return;
    }
    signInput.submitFrame(landmarks);
  },
});

let started = false;

document.getElementById("jdCam").addEventListener("click", async () => {
  if (started) return;
  started = true;
  window.jamoCamStarted = true;

  resultEl.style.cursor = 'default';
  resultEl.textContent = '-';

  try {
    await signInput.reset(); // 이전 조합/hold 상태 초기화하고 깨끗하게 시작
    await cam.start();
  } catch (error) {
    console.error('카메라 시작 실패: ', error);
    started = false;
    window.jamoCamStarted = false;
    resultEl.textContent = '카메라 연결 실패';
    resultEl.style.cursor = 'pointer';
  }
});

window.stopJamoCam = () => {
  cam.stopCamera();
  started = false;
  window.jamoCamStarted = false;
};

// jamo.jsp에서 카드/탭 전환 시 호출 -> 카메라는 그대로 두고 hold 상태만 리셋.
// (같은 손모양을 유지한 채로 타겟만 바꾸는 경우, 새 타겟에 대해 다시 판정/로그가
//  찍히도록 하기 위함. 카메라 자체를 껐다 켤 필요는 없음)
window.resetJamoSession = async () => {
  if (!window.jamoCamStarted) return;
  try {
    await signInput.reset();
  } catch (err) {
    console.error('세션 리셋 실패:', err);
  }
};

window.addEventListener('beforeunload', () => {
  window.stopJamoCam?.();
});