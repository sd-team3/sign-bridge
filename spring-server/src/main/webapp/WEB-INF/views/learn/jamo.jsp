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
      <a href="/learn" class="btn btn-ghost">← 학습 홈</a>
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
        <div style="font-size:11px; color:var(--text-muted); text-align:center; padding:6px;">
          출처: 국립국어원 한국수어사전(sldict.korean.go.kr)
        </div>
      </div>
      <div class="jd-panel">
        <div class="jd-header"><span>내 동작 인식</span></div>
        <div class="jd-cam" id="jdCam">
          <div class="cam-wrap">
            <video id="video" autoplay playsinline muted></video>
            <canvas id="canvas"></canvas>
          </div>
          <div id="result" style="font-size: large; cursor: pointer;">클릭해서 시작</div>
        </div>
      </div>
    </div>

    <!-- 자음 섹션 -->
    <div class="jamo-section active" id="section-consonant">
      <div class="result-count">기본 자음 ${fn:length(consonants)}개</div>
      <c:choose>
         <c:when test="${empty consonants}">
          <div style="text-align:center;color:var(--text-muted);padding:40px 0">자음 데이터를 불러오지 못했습니다.</div>
        </c:when>
        <c:otherwise>
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
        </c:otherwise>
      </c:choose>
    </div>

    <!-- 모음 섹션 -->
    <div class="jamo-section" id="section-vowel">
      <div class="result-count">기본 모음 ${fn:length(vowels)}개</div>
      <c:choose>
        <c:when test="${empty vowels}">
          <div style="text-align:center;color:var(--text-muted);padding:40px 0">모음 데이터를 불러오지 못했습니다.</div>
        </c:when>
        <c:otherwise>
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
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
// 카메라 시작 상태를 저장하는 전역 변수
window.jamoCamStarted = false;
// 현재 선택된 지문자 (module 스크립트에서도 참조하므로 전역으로 관리)
window.currentJamoChar = null;

// 탭 전환
const tabs = document.querySelectorAll('.jamo-tab');
tabs.forEach(tab => {
  tab.addEventListener('click', () => {
    tabs.forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    document.querySelectorAll('.jamo-section').forEach(s => s.classList.remove('active'));
    document.getElementById('section-' + tab.dataset.target).classList.add('active');
    document.getElementById('jamoDetail').classList.remove('show');
    window.stopJamoCam?.();
    window.currentJamoChar = null;

    const resultEl = document.getElementById('result');
    resultEl.textContent = '클릭해서 시작';
    resultEl.style.cursor = 'pointer';
    resultEl.style.color = '';
  });
});

/// 카드 클릭 -> 상세 표시
document.addEventListener('click', (e) => {
  const card = e.target.closest('.jamo-card');
  if (!card) return;

  window.currentJamoChar = card.dataset.char;

  document.getElementById('jdChar').textContent = card.dataset.char;
  document.getElementById('jdName').textContent = card.dataset.name;
  document.getElementById('jdTip').textContent = card.dataset.tip;

  const resultEl = document.getElementById('result');
  if (window.jamoCamStarted) {
    resultEl.textContent = '-';
    resultEl.style.cursor = 'default';
  } else {
    resultEl.textContent = '클릭해서 시작';
    resultEl.style.cursor = 'pointer';
  }
  resultEl.style.color = '';

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

// 닫기 버튼 클릭 시 카메라도 꺼주기
document.getElementById('jdClose').addEventListener('click', () => {
  document.getElementById('jamoDetail').classList.remove('show');
  window.stopJamoCam?.();
  window.currentJamoChar = null;

  const resultEl = document.getElementById('result');
  resultEl.textContent = '클릭해서 시작';
  resultEl.style.cursor = 'pointer';
  resultEl.style.color = '';
});
</script>
<script type="module" src="/resources/js/jamo-camera.js"></script>

</body>
</html>
