<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 오류 신고</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<header>
  <div class="logo">✋ SignBridge</div>
  <nav>
    <a href="index.html">홈</a>
    <div class="nav-item has-sub">
      <a href="learn_basic.html">학습 <span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="learn_basic.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔤</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">기초 어휘</span>
              <span class="nav-dropdown-desc">일상 속 기본 단어부터 차근차근</span>
            </span>
          </a>
          <a href="learn_list.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🚨</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">상황별 수어 학습</span>
              <span class="nav-dropdown-desc">지진, 화재 등 긴급 상황 어휘</span>
            </span>
          </a>
          <a href="learn_word.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔍</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">개별 어휘 학습</span>
              <span class="nav-dropdown-desc">분야별로 찾거나 검색해서 학습</span>
            </span>
          </a>
        </div>
      </div>
    </div>
    <a href="exam_setup.html">시험</a>
    <div class="nav-item has-sub">
      <a href="play_chain.html">플레이존 <span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="play_chain.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔗</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 끝말잇기</span>
              <span class="nav-dropdown-desc">AI와 실시간 끝말잇기 대결</span>
            </span>
          </a>
          <a href="play_defense.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🎯</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 디펜스</span>
              <span class="nav-dropdown-desc">떨어지는 단어를 수어로 막기</span>
            </span>
          </a>
        </div>
      </div>
    </div>
    <a href="board_list.html">게시판</a>
    <a href="mypage.html" class="active btn btn-ghost btn-sm" style="margin-left:12px;">내 계정</a>
  </nav>
</header>

<main>
  <div class="container page-body">
    <div class="edit-wrap">

      <div class="edit-header">
        <h1>⚠️ 오류 신고</h1>
        <p>수어 인식, 영상 재생, 번역 등에서 발견한 문제를 알려주세요. 확인 후 빠르게 수정하겠습니다.</p>
      </div>

      <div class="card">
        <div class="form-group">
          <label class="form-label" for="report-category">오류 유형</label>
          <select id="report-category" class="form-input">
            <option>동작 인식 오류</option>
            <option>영상 재생 오류</option>
            <option>번역 · 뜻풀이 오류</option>
            <option>화면 · 디자인 오류</option>
            <option>기타</option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label" for="report-word">관련 단어 / 기능</label>
          <input type="text" id="report-word" class="form-input" placeholder="예: 감사합니다, 자음 지문자 학습 등">
          <div class="form-hint">문제가 발생한 학습 페이지나 단어를 적어주시면 확인이 빨라져요.</div>
        </div>

        <div class="form-group">
          <label class="form-label" for="report-title">제목</label>
          <input type="text" id="report-title" class="form-input" placeholder="오류 내용을 한 줄로 요약해주세요">
        </div>

        <div class="form-group">
          <label class="form-label" for="report-content">상세 내용</label>
          <textarea id="report-content" class="form-input" placeholder="어떤 상황에서 문제가 발생했는지, 재현 방법을 자세히 적어주세요."></textarea>
          <div class="form-hint">브라우저, 기기(OS) 정보를 함께 적어주시면 원인 파악에 도움이 됩니다.</div>
        </div>

        <div class="form-group">
          <label class="form-label" for="report-file">스크린샷 첨부 (선택)</label>
          <input type="file" id="report-file" class="form-input" accept="image/*">
        </div>

        <div class="alert alert-warn">신고 처리 상황은 별도로 알려드리지 않고, 확인이 필요한 경우 이 글의 댓글로 안내드립니다.</div>

        <div class="edit-actions">
          <a href="board_list.html" class="btn btn-ghost btn-sm">취소</a>
          <button class="btn btn-primary btn-sm">신고 등록</button>
        </div>
      </div>

    </div>
  </div>
</main>

<footer>© 2025 SignBridge. 청각장애인과 세상을 잇는 다리.</footer>
</body>
</html>
