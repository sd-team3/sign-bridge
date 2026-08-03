function mpTab(name) {
  document.querySelectorAll('.mp-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.mp-panel').forEach(p => p.classList.toggle('active', p.id === 'mp-panel-' + name));
}

// 필터 칩: 같은 .mp-filter-row 안에서만 active 토글 (탭이 여러 개라 전역으로 묶으면 서로 간섭함)
document.querySelectorAll('.mp-filter-row').forEach(row => {
  row.querySelectorAll('.mp-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      row.querySelectorAll('.mp-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });
});

// 오답노트 탭: 유형(객관식·주관식 / 카메라 인식)별로 실제 행 필터링
document.querySelectorAll('#mp-panel-wrongnote .mp-filter-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    const type = chip.dataset.wtype;
    document.querySelectorAll('#wrongnote-tbody tr').forEach(row => {
      row.style.display = (type === 'all' || row.dataset.wtype === type) ? '' : 'none';
    });
  });
});

// 화면 설정: 테마 (라이트/다크/시스템)
function applyTheme(value) {
  if (value === 'system') {
    const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
  } else {
    document.documentElement.setAttribute('data-theme', value);
  }
}
const savedTheme = localStorage.getItem('sb-theme') || 'light';
applyTheme(savedTheme);
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  if ((localStorage.getItem('sb-theme') || 'light') === 'system') applyTheme('system');
});

// 화면 설정: 글자 크기 (작게/보통/크게)
function applyFontSize(value) {
  document.body.classList.remove('fs-small', 'fs-large');
  if (value === 'small') document.body.classList.add('fs-small');
  if (value === 'large') document.body.classList.add('fs-large');
}
const savedFontSize = localStorage.getItem('sb-fontsize') || 'normal';
applyFontSize(savedFontSize);

// 화면 설정 선택 카드 공통 처리 (그룹별로 하나만 selected, 클릭 시 저장 + 즉시 적용)
document.querySelectorAll('.mp-choice-row').forEach(row => {
  const group = row.dataset.group;
  const saved = group === 'theme' ? savedTheme : savedFontSize;
  row.querySelectorAll('.mp-choice').forEach(choice => {
    if (choice.dataset.value === saved) choice.classList.add('selected');
    choice.addEventListener('click', () => {
      row.querySelectorAll('.mp-choice').forEach(c => c.classList.remove('selected'));
      choice.classList.add('selected');
      const value = choice.dataset.value;
      if (group === 'theme') { localStorage.setItem('sb-theme', value); applyTheme(value); }
      if (group === 'fontsize') { localStorage.setItem('sb-fontsize', value); applyFontSize(value); }
    });
  });
});


const basicInfoForm = document.getElementById('basicInfoForm');
basicInfoForm.addEventListener('submit', async function(e) {
  e.preventDefault();

  const csrfToken = document.querySelector('meta[name="_csrf"]').content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

  const body = new URLSearchParams();
  body.set('memberId', document.querySelector('input[name="memberId"]').value);
  body.set('memberName', document.getElementById('name').value);

  const res = await fetch('/member/update', {
    method: 'POST',
    headers: { [csrfHeader]: csrfToken },
    body: body
  });

  const data = await res.json();
  if (data.success) {
    alert('변경 사항이 저장되었습니다.');
  } else {
    alert(data.message || '변경 사항이 저장에 실패했습니다.');
  }
});

const passwordForm = document.getElementById('passwordForm')
if(passwordForm) {
    passwordForm.addEventListener('submit', async function(e) {
    e.preventDefault();

    const currentPw = document.getElementById('pw-current').value;
    const newPw = document.getElementById('pw-new').value;
    const confirmPw = document.getElementById('pw-confirm').value;

    if (!currentPw || !newPw || !confirmPw) {
        alert('모든 항목을 입력해주세요.');
        return;
    }
    if (newPw.length < 8) {
        alert('새 비밀번호는 8자 이상이어야 합니다.');
        return;
    }
    if (newPw !== confirmPw) {
        alert('새 비밀번호가 일치하지 않습니다.');
        return;
    }

    const csrfToken = document.querySelector('meta[name="_csrf"]').content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

    const body = new URLSearchParams();
    body.set('currentPassword', currentPw);
    body.set('newPassword', newPw);

    const res = await fetch('/member/passUpdate', {
        method: 'POST',
        headers: { [csrfHeader]: csrfToken },
        body: body
    });

    const data = await res.json();
    if (data.success) {
        alert('성공적으로 비밀번호가 변경되었습니다.');
        document.getElementById('passwordForm').reset();
    } else {
        alert(data.message || '비밀번호 변경에 실패했습니다.');
    }
    });
}

const deleteBtn = document.getElementById('deleteBtn');
if (deleteBtn) {
  deleteBtn.addEventListener('click', async function() {
    if (!confirm('정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.')) return;

    const csrfToken = document.querySelector('meta[name="_csrf"]').content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

    const body = new URLSearchParams();
    const pwInput = document.getElementById('withdraw-password');
    if (pwInput) body.set('password', pwInput.value);

    const res = await fetch('/member/delete', {
      method: 'POST',
      headers: { [csrfHeader]: csrfToken },
      body: body
    });

    const data = await res.json();
    if (data.success) {
      alert('탈퇴가 완료되었습니다.');
      location.href = '/';
    } else {
      alert(data.message || '탈퇴에 실패했습니다.');
    }
  });
}