<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge 관리자 - 오류 신고 확인</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#1A1A2E;--ink2:#4A4A6A;--ink3:#9090B0;--page:#F4FAF7;--surface:#FFFFFF;--line:rgba(26,46,36,0.09);--p:#2d9b6f;--p-light:#e2f5ec;--p-mid:#5bb896;--p-dark:#1e7a53;--rose:#c0392b;--rose-light:#fdecea;--amber:#d4840a;--amber-light:#FEF3C7;--purple:#7c3aed;--purple-light:#ede9fe;--blue:#1d6fde;--blue-light:#dbeafe;--sidebar-w:240px;--header-h:60px;--r:12px;--r-sm:8px}
html{scroll-behavior:smooth}
body{font-family:'Outfit',sans-serif;color:var(--ink);background:var(--page);display:flex;min-height:100vh;overflow-x:hidden}
.sidebar{width:var(--sidebar-w);min-width:var(--sidebar-w);background:var(--ink);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:200;transition:transform .2s}
.sidebar-logo{height:var(--header-h);display:flex;align-items:center;gap:10px;padding:0 20px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-logo-icon{width:30px;height:30px;background:var(--p);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:16px}
.sidebar-logo-text{font-size:15px;font-weight:700;color:#fff}
.sidebar-logo-badge{font-size:9px;font-weight:700;letter-spacing:.08em;background:rgba(45,155,111,.3);color:var(--p-mid);padding:2px 6px;border-radius:4px;margin-left:auto}
.sidebar-nav{flex:1;overflow-y:auto;padding:16px 0}
.nav-group{margin-bottom:8px}
.nav-group-label{font-size:10px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:rgba(255,255,255,.25);padding:8px 20px 4px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 20px;cursor:pointer;font-size:13.5px;font-weight:500;color:rgba(255,255,255,.55);transition:all .15s;border-left:2px solid transparent;text-decoration:none}
.nav-item:hover{background:rgba(255,255,255,.05);color:rgba(255,255,255,.9)}
.nav-item.active{background:rgba(45,155,111,.12);color:#fff;border-left-color:var(--p);font-weight:600}
.nav-item .ni{font-size:16px;width:20px;text-align:center;flex-shrink:0}
.nav-item .badge{margin-left:auto;font-size:10px;font-weight:700;background:var(--rose);color:#fff;padding:1px 6px;border-radius:10px}
.sidebar-footer{padding:16px 20px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px}
.sidebar-avatar{width:32px;height:32px;border-radius:50%;background:var(--p);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;color:#fff;flex-shrink:0}
.sidebar-user-info{flex:1;min-width:0}
.sidebar-user-name{font-size:13px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sidebar-user-role{font-size:11px;color:rgba(255,255,255,.3)}
.sidebar-logout{font-size:18px;color:rgba(255,255,255,.25);cursor:pointer;transition:color .15s;padding:4px}
.sidebar-logout:hover{color:rgba(255,255,255,.7)}
.main{margin-left:var(--sidebar-w);flex:1;display:flex;flex-direction:column;min-width:0}
.topbar{height:var(--header-h);background:var(--surface);border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;padding:0 28px;position:sticky;top:0;z-index:100;gap:16px}
.topbar-title{font-size:15px;font-weight:700;color:var(--ink)}
.topbar-path{font-size:12px;color:var(--ink3);font-family:'DM Mono',monospace;background:var(--page);padding:3px 10px;border-radius:6px;border:1px solid var(--line)}
.topbar-right{display:flex;align-items:center;gap:12px}
.topbar-btn{display:flex;align-items:center;gap:6px;padding:6px 14px;border-radius:var(--r-sm);font-size:13px;font-weight:600;cursor:pointer;font-family:'Outfit',sans-serif;transition:all .15s;text-decoration:none;border:none}
.btn-primary{background:var(--p);color:#fff}
.btn-primary:hover{background:var(--p-dark)}
.btn-ghost{background:transparent;color:var(--ink2);border:1.5px solid var(--line)}
.btn-ghost:hover{border-color:var(--p);color:var(--p)}
.btn-danger{background:var(--rose);color:#fff}
.btn-danger:hover{background:#a93226}
.btn-warning{background:var(--amber);color:#fff}
.btn-warning:hover{background:#b8700a}
.btn-sm{padding:5px 12px;font-size:12px}
.content{padding:28px;flex:1}
.page{display:none}
.page.active{display:block}
.card{background:var(--surface);border:1px solid var(--line);border-radius:var(--r);padding:22px 24px}
.card-title{font-size:14px;font-weight:700;color:var(--ink);margin-bottom:16px;display:flex;align-items:center;gap:8px}
.card-title .ct-icon{font-size:18px}
.pill{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:700}
.pill-green{background:var(--p-light);color:var(--p-dark)}
.pill-red{background:var(--rose-light);color:var(--rose)}
.pill-amber{background:var(--amber-light);color:var(--amber)}
.pill-purple{background:var(--purple-light);color:var(--purple)}
.pill-blue{background:var(--blue-light);color:var(--blue)}
.pill-gray{background:#f0f0f5;color:var(--ink2)}
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:500;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.modal-overlay.open{opacity:1;pointer-events:all}
.modal{background:var(--surface);border-radius:var(--r);padding:28px;width:440px;max-width:90vw;transform:translateY(10px);transition:transform .2s;box-shadow:0 20px 60px rgba(0,0,0,.15)}
.modal-overlay.open .modal{transform:none}
.modal-title{font-size:17px;font-weight:800;color:var(--ink);margin-bottom:8px}
.modal-desc{font-size:13px;color:var(--ink2);line-height:1.6;margin-bottom:22px}
.modal-actions{display:flex;gap:10px;justify-content:flex-end}
.toast-wrap{position:fixed;bottom:24px;right:24px;z-index:600;display:flex;flex-direction:column;gap:8px;pointer-events:none}
.toast{background:var(--ink);color:#fff;padding:12px 18px;border-radius:var(--r-sm);font-size:13px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 24px rgba(0,0,0,.2);transform:translateX(120%);transition:transform .3s cubic-bezier(.34,1.56,.64,1);pointer-events:all}
.toast.show{transform:none}
.toast-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
.section-eyebrow{font-size:10px;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--p);margin-bottom:6px}
.section-hd{font-size:20px;font-weight:800;color:var(--ink);letter-spacing:-.5px;margin-bottom:4px}
.section-sub{font-size:13px;color:var(--ink3);margin-bottom:22px}
.page-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px;flex-wrap:wrap;gap:12px}
.tabs{display:flex;gap:0;border-bottom:1px solid var(--line);margin-bottom:20px}
.tab{padding:10px 18px;font-size:13px;font-weight:600;color:var(--ink3);cursor:pointer;border-bottom:2px solid transparent;transition:all .15s;margin-bottom:-1px}
.tab:hover{color:var(--ink)}
.tab.active{color:var(--p);border-bottom-color:var(--p)}
.empty{text-align:center;padding:48px 24px;color:var(--ink3)}
.empty-icon{font-size:40px;margin-bottom:12px;opacity:.5}
.empty-text{font-size:14px;font-weight:500}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--line);border-radius:10px}
@media(max-width:768px){.sidebar{transform:translateX(-100%)}
.sidebar.open{transform:none}
.main{margin-left:0}
}
</style>
</head>
<body>

<!-- ═══════════ SIDEBAR ═══════════ -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-logo">
    <div class="sidebar-logo-icon">✋</div>
    <span class="sidebar-logo-text">SignBridge</span>
    <span class="sidebar-logo-badge">ADMIN</span>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-group">
      <div class="nav-group-label">문의 / 신고</div>
      <a class="nav-item active" href="error-report.html">
        <span class="ni">🚨</span> 오류 신고
        <span class="badge">4</span>
      </a>
      <a class="nav-item" href="word-request.html">
        <span class="ni">📝</span> 단어 요청
        <span class="badge">9</span>
      </a>
    </div>
  </nav>

  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="sidebar-avatar">관</div>
      <div class="sidebar-user-info">
        <div class="sidebar-user-name">관리자</div>
        <div class="sidebar-user-role">Super Admin</div>
      </div>
      <div class="sidebar-logout" title="로그아웃" onclick="showToast('로그아웃 되었습니다', '#c0392b')">⏻</div>
    </div>
  </div>
</aside>

<!-- ═══════════ MAIN ═══════════ -->
<div class="main">

  <!-- TOPBAR -->
  <div class="topbar">
    <div style="display:flex;align-items:center;gap:12px">
      <button onclick="document.getElementById('sidebar').classList.toggle('open')" style="display:none;background:none;border:none;font-size:20px;cursor:pointer" id="menu-toggle">☰</button>
      <span class="topbar-title">오류 신고 확인</span>
    </div>
    <span class="topbar-path">/admin/question/error</span>
    <div class="topbar-right">
      <button class="topbar-btn btn-ghost" onclick="showToast('새로고침 되었습니다', '#2d9b6f')">↻ 새로고침</button>
      <a href="index.html" class="topbar-btn btn-ghost">← 사이트로</a>
    </div>
  </div>

  <!-- ══════════ PAGE: 오류 신고 확인 ══════════ -->
  <div class="content page active" id="page-question-error">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">문의 / 신고</div>
        <div class="section-hd">오류 신고 확인</div>
        <div class="section-sub">미처리 신고 4건이 있습니다</div>
      </div>
    </div>
    <div class="tabs">
      <div class="tab active">미처리 <span class="pill pill-red" style="margin-left:4px;padding:1px 7px">4</span></div>
      <div class="tab">처리 완료</div>
      <div class="tab">전체</div>
    </div>
    <div style="display:flex;flex-direction:column;gap:12px" id="error-list"></div>
  </div>

</div><!-- /main -->

<!-- TOAST CONTAINER -->
<div class="toast-wrap" id="toast-wrap"></div>

<script>
// ═══════════ DATA ═══════════
const ERRORS = [
  {id:'ERR-041',word:'"화재"',desc:'동영상 재생이 안 됩니다. 로딩 후 바로 끊겨요.',user:'김지수',date:'2025-06-29',status:'미처리'},
  {id:'ERR-040',word:'"지진 대피"',desc:'AI 인식이 다른 단어로 계속 인식됩니다.',user:'이민준',date:'2025-06-28',status:'미처리'},
  {id:'ERR-039',word:'"감사합니다"',desc:'모범 동작 영상 화질이 너무 낮습니다.',user:'박서연',date:'2025-06-27',status:'미처리'},
  {id:'ERR-038',word:'"병원"',desc:'단어 설명 텍스트가 잘려서 나와요.',user:'정다은',date:'2025-06-26',status:'미처리'},
];

// ═══════════ RENDER ═══════════
function renderErrors(){
  const el=document.getElementById('error-list');
  el.innerHTML=ERRORS.map(e=>`
  <div class="card" style="display:flex;align-items:flex-start;gap:16px;flex-wrap:wrap">
    <div style="flex:1;min-width:240px">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px">
        <span class="pill pill-red">미처리</span>
        <span class="td-mono" style="font-size:12px;color:var(--ink3)">${e.id}</span>
        <span style="font-size:12px;color:var(--ink3)">· ${e.date} · ${e.user}</span>
      </div>
      <div style="font-size:15px;font-weight:700;margin-bottom:4px">단어 ${e.word} 오류 신고</div>
      <div style="font-size:13px;color:var(--ink2)">${e.desc}</div>
    </div>
    <div style="display:flex;gap:6px;flex-shrink:0;align-items:center">
      <button class="topbar-btn btn-primary btn-sm" onclick="showToast('처리 완료로 변경되었습니다 ✓','#2d9b6f')">처리 완료</button>
      <button class="topbar-btn btn-ghost btn-sm" onclick="location.href='word-update.html'">단어 수정</button>
    </div>
  </div>`).join('');
}

// ═══════════ TOAST ═══════════
function showToast(msg,color='#2d9b6f'){
  const wrap=document.getElementById('toast-wrap');
  const t=document.createElement('div');
  t.className='toast';
  t.innerHTML=`<div class="toast-dot" style="background:${color}"></div>${msg}`;
  wrap.appendChild(t);
  requestAnimationFrame(()=>requestAnimationFrame(()=>t.classList.add('show')));
  setTimeout(()=>{t.classList.remove('show');setTimeout(()=>t.remove(),350)},2800);
}

// ═══════════ INIT ═══════════
renderErrors();
</script>
</body>
</html>
