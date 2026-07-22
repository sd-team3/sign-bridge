<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 자음/모음 지문자 학습</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="page-header">
      <div>
        <h1>🤟 자음 · 모음 지문자 학습</h1>
        <p>수어의 기본이 되는 지문자(指文字)를 하나씩 익혀보세요. 자음 ${fn:length(consonants)}개, 모음 ${fn:length(vowels)}개로 구성되어 있어요.</p>
      </div>
      <a href="learn_basic.html" class="btn btn-ghost">← 학습 홈</a>
    </div>

    <div class="jamo-tabs">
      <button class="jamo-tab active" data-target="consonant">자음 (${fn:length(consonants)})</button>
      <button class="jamo-tab" data-target="vowel">모음 (${fn:length(vowels)})</button>
    </div>

    <!-- 선택된 지문자 상세 -->
    <div class="jamo-detail" id="jamoDetail">
      <div class="jd-panel">
        <div class="jd-header"><span>지문자 정보</span><span class="jd-close" id="jdClose">✕ 닫기</span></div>
        <div class="jd-info">
          <div class="jd-char-big" id="jdChar"></div>
          <div class="word-category" id="jdName"></div>
          <div class="jd-tip" id="jdTip">카드를 클릭하면 상세 정보가 표시됩니다.</div>
        </div>
      </div>
      <div class="jd-panel">
        <div class="jd-header"><span>모범 동작</span></div>
        <div class="jd-video" id="jdImageWrap">
          <img id="jdImage" src="" alt="손모양 예시" style="width:100%; height:100%; object-fit:contain; display:none;">
          <div id="jdImagePlaceholder" style="display:flex; flex-direction:column; align-items:center; gap:10px;">
            <div style="font-size:48px; opacity:.15;">🤟</div>
            <div id="jdImageText">이미지 준비 중</div>
          </div>
        </div>
      </div>
      <div class="jd-panel">
        <div class="jd-header"><span>내 동작 인식</span></div>
        <div class="jd-cam" id="jdCam" style="flex-direction:column; padding:16px;">
          <div class="cam-wrap">
            <video id="video" autoplay playsinline muted></video>
            <canvas id="canvas"></canvas>
          </div>
          <div id="result" style="font-size: large;">-</div>
        </div>
      </div>
    </div>

    <!-- 자음 섹션 -->
    <div class="jamo-section" id="section-consonant">
      <div class="result-count">기본 자음 ${fn:length(consonants)}개</div>
      <div class="jamo-grid" id="grid-consonant">
        <c:forEach var="jamo" items="${consonants}">
          <div class="jamo-card" 
              data-char="${jamo.jamoChar}"
              data-name="${jamo.jamoName}"
              data-tip="${jamo.jamoInfo}"
              data-image="${jamo.jamoImage}">
            <div class="jamo-char">${jamo.jamoChar}</div>
            <div class="jamo-name">${jamo.jamoName}</div>
          </div>
        </c:forEach>
      </div>
    </div>

    <!-- 모음 섹션 -->
    <div class="jamo-section" id="section-vowel">
      <div class="result-count">기본 모음 ${fn:length(vowels)}개</div>
      <div class="jamo-grid" id="grid-vowel">
        <c:forEach var="jamo" items="${vowels}">
          <div class="jamo-card"
              data-char="${jamo.jamoChar}"
              data-name="${jamo.jamoName}"
              data-tip="${jamo.jamoInfo}"
              data-image="${jamo.jamoImage}">
            <div class="jamo-char">${jamo.jamoChar}</div>
            <div class="jamo-name">${jamo.jamoName}</div>
          </div>
        </c:forEach>
      </div>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script type="module">
  import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
  import { JamoApiClient } from "http://localhost:8000/static/js/api-client.js";

  const api = new JamoApiClient("http://localhost:8000");

  const cam = new HandCameraWidget({
    videoEl: document.getElementById("video"),
    canvasEl: document.getElementById("canvas"),
    onFrame: async (landmarks) => {
      if (!landmarks) return;
      const result = await api.predict(landmarks, false);
      document.getElementById("result").textContent = result.label;
    },
  });

  await cam.start();
</script>

<script>
// 탭 전환
const tabs = document.querySelectorAll('.jamo-tab');
tabs.forEach(tab => {
  tab.addEventListener('click', () => {
    tabs.forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    document.querySelectorAll('.jamo-section').forEach(s => s.classList.remove('active'));
    document.getElementById('section-' + tab.dataset.target).classList.add('active');
    document.getElementById('jamoDetail').classList.remove('show');
  });
});

/// 카드 클릭 -> 상세 표시
document.addEventListener('click', (e) => {
  const card = e.target.closest('.jamo-card');
  if (!card) return;

  document.getElementById('jdChar').textContent = card.dataset.char;
  document.getElementById('jdName').textContent = card.dataset.name;
  document.getElementById('jdTip').textContent = card.dataset.tip;

  // 모범 동작 이미지
  const img = document.getElementById('jdImage');
  const imgPlaceholder = document.getElementById('jdImagePlaceholder');
  if (card.dataset.image) {
    img.src = card.dataset.image;
    img.style.display = 'block';
    imgPlaceholder.style.display = 'none';
  } else {
    img.style.display = 'none';
    imgPlaceholder.style.display = 'flex';
  }

  document.getElementById('jamoDetail').classList.add('show');
  document.getElementById('jamoDetail').scrollIntoView({behavior:'smooth', block:'center'});
});

// 카메라 켜기
let camStream = null;
document.getElementById('jdCam').addEventListener('click', async () => {
  const camVideo = document.getElementById('jdCamStream');
  const placeholder = document.getElementById('jdCamPlaceholder');
  if (camStream) return;

  try {
    camStream = await navigator.mediaDevices.getUserMedia({ video: true });
    camVideo.srcObject = camStream;
    camVideo.style.display = 'block';
    placeholder.style.display = 'none';
  } catch (err) {
    alert('카메라 권한이 필요합니다.');
    console.error(err);
  }
});

// 닫기 버튼 클릭 시 카메라도 꺼주기
document.getElementById('jdClose').addEventListener('click', () => {
  document.getElementById('jamoDetail').classList.remove('show');
  if (camStream) {
    camStream.getTracks().forEach(track => track.stop());
    camStream = null;
    document.getElementById('jdCamStream').style.display = 'none';
    document.getElementById('jdCamPlaceholder').style.display = 'flex';
  }
});
</script>

</body>
</html>
