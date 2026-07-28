<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 게시글 상세</title>
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

    <div class="detail-layout">
      <!-- 메인 -->
      <div>

        <!-- 게시글 헤더 -->
        <div class="detail-header">
          <div class="detail-badge-row">
            <span class="badge badge-primary">질문</span>
          </div>
          <div class="detail-title">'감사합니다' 수어 동작이 계속 인식이 안 돼요</div>
          <div class="detail-meta">
            <div class="detail-author">
              <div class="author-avatar">홍</div>
              <div>
                <div class="author-name">홍길동</div>
                <div class="author-date">2025.06.25 14:32</div>
              </div>
            </div>
            <div class="detail-stats">
              <span>조회 48</span>
              <span>댓글 4</span>
            </div>
          </div>
        </div>

        <!-- 게시글 본문 -->
        <div class="detail-content">
          안녕하세요, '감사합니다' 수어 동작을 계속 연습하고 있는데 카메라 인식이 잘 안 되는 것 같아요.<br><br>
          손 모양은 튜토리얼이랑 똑같이 따라 하는 것 같은데 자꾸 다른 단어로 인식되거나 "인식 실패"가 뜹니다.
          혹시 조명이나 손 위치 관련해서 팁이 있으면 공유 부탁드립니다. 같은 문제 겪으신 분 계신가요?
          <div class="detail-images">
            <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NDAiIGhlaWdodD0iMzIwIj4KICA8cmVjdCB3aWR0aD0iNDQwIiBoZWlnaHQ9IjMyMCIgZmlsbD0iIzBkMWExMyIvPgogIDxyZWN0IHg9IjE2IiB5PSIxNiIgd2lkdGg9IjQwOCIgaGVpZ2h0PSIyODgiIHJ4PSIxMiIgZmlsbD0iIzExMWMxNyIgc3Ryb2tlPSIjMmQ5YjZmIiBzdHJva2Utd2lkdGg9IjEuNSIvPgogIDx0ZXh0IHg9IjIyMCIgeT0iMTIwIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZm9udC1zaXplPSI2NCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+4pyLPC90ZXh0PgogIDx0ZXh0IHg9IjIyMCIgeT0iMTgwIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZm9udC1zaXplPSIxNSIgZmlsbD0icmdiYSgyNTUsMjU1LDI1NSwuNSkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkFJIOyduOyLnSDqsrDqs7w8L3RleHQ+CiAgPHRleHQgeD0iMjIwIiB5PSIyMTIiIGZvbnQtZmFtaWx5PSJzYW5zLXNlcmlmIiBmb250LXNpemU9IjI0IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iI2UwNjA1YSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+7J247IudIOyLpO2MqDwvdGV4dD4KICA8dGV4dCB4PSIyMjAiIHk9IjI0MCIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTMiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsLjM1KSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+7Iug66Kw64+EIDQyJTwvdGV4dD4KPC9zdmc+Cg==" alt="인식 실패 스크린샷" onclick="window.open(this.src)">
            <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NDAiIGhlaWdodD0iMzIwIj4KICA8cmVjdCB3aWR0aD0iNDQwIiBoZWlnaHQ9IjMyMCIgZmlsbD0iIzBkMWExMyIvPgogIDxyZWN0IHg9IjE2IiB5PSIxNiIgd2lkdGg9IjQwOCIgaGVpZ2h0PSIyODgiIHJ4PSIxMiIgZmlsbD0iIzExMWMxNyIgc3Ryb2tlPSIjMmQ5YjZmIiBzdHJva2Utd2lkdGg9IjEuNSIvPgogIDx0ZXh0IHg9IjIyMCIgeT0iMTEwIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZm9udC1zaXplPSI2NCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+8J+ZjzwvdGV4dD4KICA8dGV4dCB4PSIyMjAiIHk9IjE3MiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTUiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsLjUpIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5BSSDsnbjsi50g6rKw6rO8PC90ZXh0PgogIDx0ZXh0IHg9IjIyMCIgeT0iMjA0IiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZm9udC1zaXplPSIyNCIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiNmMGMwNjAiIHRleHQtYW5jaG9yPSJtaWRkbGUiPiLslYjrhZXtlZjshLjsmpQi66GcIOyduOyLneuQqDwvdGV4dD4KICA8dGV4dCB4PSIyMjAiIHk9IjIzMiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTMiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsLjM1KSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+7J2Y64+E7ZWcIOuLqOyWtDog6rCQ7IKs7ZWp64uI64ukPC90ZXh0Pgo8L3N2Zz4K" alt="다른 단어로 인식된 스크린샷" onclick="window.open(this.src)">
          </div>
        </div>

        <div class="detail-actions">
          <button class="btn btn-ghost btn-sm">수정</button>
          <button class="btn btn-ghost btn-sm" onclick="openDeleteModal()">삭제</button>
        </div>

        <!-- 댓글 섹션 -->
        <div class="comment-section">
          <div class="comment-count-title">댓글 <span>4</span></div>

          <!-- 댓글 작성 -->
          <div class="comment-write">
            <textarea placeholder="댓글을 입력하세요..."></textarea>
            <div class="comment-write-footer">
              <button class="btn btn-primary btn-sm">댓글 등록</button>
            </div>
          </div>

          <!-- 댓글 리스트 -->
          <div class="comment-list">
            <div class="comment-item">
              <div class="comment-item-header">
                <div class="comment-avatar">이</div>
                <span class="comment-author">이수진</span>
                <span class="comment-time">2025.06.25 15:10</span>
              </div>
              <div class="comment-body">저도 처음에 비슷한 문제 겪었는데 조명을 밝게 하니까 인식률이 확 올라갔어요!</div>
              <div class="comment-actions">
                <button class="comment-reply-btn" onclick="toggleReplyForm(this, 'reply-form-1')">답글</button>
              </div>
              <div class="comment-reply-form" id="reply-form-1">
                <textarea placeholder="답글을 입력하세요..."></textarea>
                <div class="comment-reply-form-footer">
                  <button class="btn btn-ghost btn-sm" onclick="toggleReplyForm(this, 'reply-form-1')">취소</button>
                  <button class="btn btn-primary btn-sm">답글 등록</button>
                </div>
              </div>

              <!-- 대댓글 -->
              <div class="comment-replies">
                <div class="comment-reply">
                  <div class="comment-item-header">
                    <div class="comment-avatar">홍</div>
                    <span class="comment-author">홍길동</span>
                    <span class="comment-time">2025.06.25 15:22</span>
                  </div>
                  <div class="comment-body">오 저도 조명 한번 밝게 해볼게요! 답변 감사합니다 🙏</div>
                  <div class="comment-actions">
                    <button class="comment-reply-btn" onclick="toggleReplyForm(this, 'reply-form-1')">답글</button>
                  </div>
                </div>
              </div>
            </div>
            <div class="comment-item">
              <div class="comment-item-header">
                <div class="comment-avatar">김</div>
                <span class="comment-author">김민준</span>
                <span class="comment-time">2025.06.25 16:44</span>
              </div>
              <div class="comment-body">카메라와의 거리도 중요한 것 같아요. 너무 가까우면 손 전체가 안 잡히더라고요.</div>
              <div class="comment-actions">
                <button class="comment-reply-btn" onclick="toggleReplyForm(this, 'reply-form-2')">답글</button>
              </div>
              <div class="comment-reply-form" id="reply-form-2">
                <textarea placeholder="답글을 입력하세요..."></textarea>
                <div class="comment-reply-form-footer">
                  <button class="btn btn-ghost btn-sm" onclick="toggleReplyForm(this, 'reply-form-2')">취소</button>
                  <button class="btn btn-primary btn-sm">답글 등록</button>
                </div>
              </div>
            </div>
            <div class="comment-item">
              <div class="comment-item-header">
                <div class="comment-avatar">홍</div>
                <span class="comment-author">홍길동</span>
                <span class="comment-time">2025.06.25 17:02</span>
              </div>
              <div class="comment-body">오 조언 감사합니다! 조명이랑 거리 조절해서 다시 시도해볼게요.</div>
              <div class="comment-actions">
                <button class="comment-reply-btn" onclick="toggleReplyForm(this, 'reply-form-3')">답글</button>
              </div>
              <div class="comment-reply-form" id="reply-form-3">
                <textarea placeholder="답글을 입력하세요..."></textarea>
                <div class="comment-reply-form-footer">
                  <button class="btn btn-ghost btn-sm" onclick="toggleReplyForm(this, 'reply-form-3')">취소</button>
                  <button class="btn btn-primary btn-sm">답글 등록</button>
                </div>
              </div>
            </div>
          </div>

          <!-- 댓글이 없을 때 (참고용, 필요시 사용) -->
          <!--
          <div class="comment-empty">아직 작성된 댓글이 없습니다. 첫 댓글을 남겨보세요!</div>
          -->
        </div>

        <div class="back-row">
          <a href="board_list.html" class="btn btn-ghost btn-sm">← 목록으로</a>
        </div>

      </div>

      <!-- 사이드바 -->
      <div class="board-sidebar">
        <div class="sidebar-box">
          <div class="sidebar-box-header">글쓰기</div>
          <div class="sidebar-write-btns">
            <a href="board_write.html" class="btn btn-primary btn-sm">✏️ 일반 글쓰기</a>
            <a href="board_report.html" class="btn btn-ghost btn-sm">⚠️ 오류 신고</a>
            <a href="board_suggest.html" class="btn btn-ghost btn-sm">➕ 단어 건의</a>
          </div>
        </div>
        <div class="sidebar-box">
          <div class="sidebar-box-header">게시판 현황</div>
          <div class="sidebar-stats">
            <div class="stat-row"><span class="lbl">전체 게시글</span><span class="val">247</span></div>
            <div class="stat-row"><span class="lbl">오류 신고</span><span class="val">18</span></div>
            <div class="stat-row"><span class="lbl">단어 건의</span><span class="val">43</span></div>
            <div class="stat-row"><span class="lbl">해결된 이슈</span><span class="val">31</span></div>
          </div>
        </div>
      </div>
    </div>

  </div>
</main>

<footer>© 2025 SignBridge. 청각장애인과 세상을 잇는 다리.</footer>

<!-- 게시글 삭제 확인 모달 -->
<div class="modal-backdrop" id="deleteModal">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">게시글을 삭제할까요?</span>
      <button class="modal-close" onclick="closeDeleteModal()">✕</button>
    </div>
    <div class="modal-body">
      <div class="modal-content">삭제한 게시글과 댓글 4개는 복구할 수 없습니다. 정말 삭제하시겠어요?</div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-ghost btn-sm" onclick="closeDeleteModal()">취소</button>
      <button class="btn btn-danger btn-sm">삭제하기</button>
    </div>
  </div>
</div>

<script>
function openDeleteModal() {
  document.getElementById('deleteModal').classList.add('open');
}
function closeDeleteModal() {
  document.getElementById('deleteModal').classList.remove('open');
}
function toggleReplyForm(btn, id) {
  document.getElementById(id).classList.toggle('open');
}
</script>
</body>
</html>
