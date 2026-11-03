(() => {
  'use strict';
  const root = document.getElementById('word-exam');
  if (!root) return;
  const el = name => document.getElementById('we-' + name);
  const ctx = root.dataset.context || '';
  const api = ctx + '/exam/words/api';
  let exam, index = 0, selected = null, busy = false, stream, recorder, blob, previewUrl, attemptId;
  let timer, started = 0, discarded = false, disposed = false, cameraPending = false, videoReady = false, finalizing = false;
  const make = (tag, text, cls) => {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    if (cls) node.className = cls;
    return node;
  };
  const status = (text, error = false) => { el('status').textContent = text; el('status').dataset.error = String(error); };
  const question = () => exam?.questions[index];
  const recording = () => recorder?.state === 'recording';
  const mime = () => ['video/webm;codecs=vp8', 'video/webm', 'video/mp4'].find(t => window.MediaRecorder?.isTypeSupported(t));
  async function request(path, body) {
    const headers = {};
    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;
    if (token && header) headers[header] = token;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 150000);
    try {
      const response = await fetch(api + path, { method: body ? 'POST' : 'GET', body, headers, credentials: 'same-origin', signal: controller.signal });
      let data;
      try { data = await response.json(); } catch (_) { throw new Error('서버 응답을 확인하지 못했습니다. 로그인 상태를 확인해 주세요.'); }
      if (!response.ok) throw new Error(data.message || (response.status === 403 ? '세션이 만료되었을 수 있어요. 새로고침 후 다시 시도해 주세요.' : '요청을 처리하지 못했습니다.'));
      return data;
    } catch (error) {
      if (error.name === 'AbortError') throw new Error('응답 시간이 초과됐어요. 새로고침하면 저장된 진행 상황을 확인할 수 있어요.');
      throw error;
    } finally { clearTimeout(timeout); }
  }
  async function task(action) {
    if (busy || disposed) return;
    busy = true; controls();
    try { await action(); } catch (error) { status(error.message, true); }
    finally { busy = false; controls(); }
  }
  function controls() {
    const q = question();
    const rec = recording();
    const locked = busy || rec || cameraPending || finalizing;
    el('start').disabled = busy || el('scope').options.length < 2;
    el('camera-on').disabled = locked || !!stream;
    el('record').disabled = locked || !stream || q?.submitted && q?.verdict !== 'pending' || q?.attempts >= 3;
    el('stop').disabled = busy || !rec || performance.now() - started < 2000;
    el('submit').disabled = locked || !q || (q.type === 'choice' ? selected === null || !videoReady || q.submitted : !blob || q.attempts >= 3 || q.submitted && q.verdict !== 'pending');
    el('skip').disabled = locked;
    el('next').disabled = locked;
    root.querySelectorAll('.we-option').forEach(button => { button.disabled = locked || q?.submitted; });
    el('review').disabled = busy || !exam?.questions.some(q => q.verdict !== 'correct');
    el('history').querySelectorAll('button').forEach(button => { button.disabled = busy; });
  }
  function clearPreview() {
    blob = null; attemptId = null;
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = null;
    el('preview').removeAttribute('src'); el('preview').load(); el('preview-box').hidden = true;
  }
  function stopCamera() {
    stream?.getTracks().forEach(track => track.stop());
    stream = null; el('camera').srcObject = null;
  }
  function showQuestion() {
    clearPreview(); selected = null; videoReady = false;
    const q = question();
    el('setup').hidden = true; el('result').hidden = true; el('active').hidden = false;
    el('progress').textContent = (index + 1) + ' / ' + exam.questions.length + ' · ' + exam.scope;
    el('bar').max = exam.questions.length; el('bar').value = index;
    const motion = q.type === 'motion';
    el('kind').textContent = motion ? '동작 표현' : '영상 이해';
    el('prompt').textContent = motion ? '‘' + q.label + '’을 수어로 표현해 주세요' : '영상의 수어는 어떤 뜻일까요?';
    el('choice').hidden = motion; el('motion').hidden = !motion;
    el('video').pause(); el('video').removeAttribute('src'); el('video').load();
    el('video-error').textContent = '';
    el('timer').textContent = '00:00';
    el('attempt').textContent = q.verdict === 'pending' ? '동작을 또렷하게 확인하지 못했어요. 다시 촬영하거나 다음 문제로 넘어가도 돼요. (' + q.attempts + '/3회)' : '';
    el('record').textContent = '녹화 시작';
    el('next').hidden = !q.submitted;
    el('next').textContent = index === exam.questions.length - 1 ? '결과 확인' : '다음 문제';
    el('skip').hidden = q.submitted;
    el('options').replaceChildren();
    if (!motion) {
      stopCamera();
      el('video').src = api + '/' + exam.id + '/questions/' + index + '/video';
      q.choices.forEach(option => {
        const button = make('button', option.label, 'we-option');
        button.type = 'button'; button.dataset.answer = option.id; button.setAttribute('aria-pressed', 'false');
        button.addEventListener('click', () => {
          if (busy || question().submitted) return;
          selected = option.id;
          el('options').querySelectorAll('button').forEach(b => b.setAttribute('aria-pressed', String(b === button)));
          controls();
        });
        el('options').append(button);
      });
    }
    status(q.submitted ? '답안이 저장됐어요. 다음 문제로 이동해 주세요.' : '정답과 교정 안내는 시험이 끝난 뒤 확인할 수 있어요.');
    controls();
  }
  function receive(data) {
    exam = data;
    history.replaceState(null, '', ctx + '/exam/words?session=' + encodeURIComponent(exam.id));
    if (exam.finished) { showResult(); return; }
    index = exam.questions.findIndex(q => !q.submitted);
    if (index < 0) index = exam.questions.length - 1;
    showQuestion();
  }
  async function start(review = '') {
    stopCamera();
    const body = new URLSearchParams({ mode: el('mode').value, chapter: el('scope').value, review });
    receive(await request('/start', body));
  }
  async function openCamera() {
    if (cameraPending || stream || busy) return;
    if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia || !mime()) { status('HTTPS 또는 localhost에서 녹화를 지원하는 브라우저로 접속해 주세요.', true); return; }
    cameraPending = true; controls();
    try {
      const opened = await navigator.mediaDevices.getUserMedia({ audio: false, video: { width: { ideal: 1280, max: 1920 }, height: { ideal: 720, max: 1080 }, frameRate: { ideal: 30, max: 30 }, facingMode: 'user' } });
      if (disposed) { opened.getTracks().forEach(t => t.stop()); return; }
      stream = opened; el('camera').srcObject = stream; await el('camera').play();
      stream.getVideoTracks()[0].addEventListener('ended', () => {
        discarded = true;
        if (recording()) recorder.stop();
        stopCamera(); status('카메라 연결이 끊겼어요. 다시 켜 주세요.', true); controls();
      });
      status('카메라가 준비됐어요. 상체와 동작하는 손을 확인한 뒤 녹화해 주세요.');
    } catch (_) { stopCamera(); status('카메라를 열지 못했어요. 브라우저 권한과 다른 앱의 카메라 사용 여부를 확인해 주세요.', true); }
    finally { cameraPending = false; controls(); }
  }
  function record() {
    if (busy || !stream || recording() || finalizing) return;
    clearPreview();
    const chunks = []; let bytes = 0;
    discarded = false;
    try {
      recorder = new MediaRecorder(stream, { mimeType: mime(), videoBitsPerSecond: 1500000 });
      const active = recorder;
      active.ondataavailable = event => {
        bytes += event.data.size;
        if (bytes > 25 * 1024 * 1024) { discarded = true; if (active.state === 'recording') active.stop(); }
        else if (event.data.size) chunks.push(event.data);
      };
      active.onerror = () => { discarded = true; if (active.state === 'recording') active.stop(); };
      active.onstop = () => {
        clearInterval(timer); recorder = null; finalizing = false;
        if (disposed) return;
        if (discarded || performance.now() - started < 2000 || !chunks.length) { status('녹화를 완료하지 못했어요. 2~10초 동안 다시 촬영해 주세요.', true); controls(); return; }
        blob = new Blob(chunks, { type: active.mimeType });
        attemptId = crypto.randomUUID ? crypto.randomUUID() : Array.from(crypto.getRandomValues(new Uint8Array(16)), b => b.toString(16).padStart(2, '0')).join('');
        previewUrl = URL.createObjectURL(blob); el('preview').src = previewUrl; el('preview-box').hidden = false;
        el('record').textContent = '다시 촬영';
        status('녹화 영상을 확인하고 답안을 제출해 주세요.'); controls();
      };
      active.start(250); started = performance.now();
      timer = setInterval(() => {
        const elapsed = performance.now() - started;
        el('timer').textContent = '00:' + String(Math.floor(elapsed / 1000)).padStart(2, '0');
        if (elapsed >= 19000 && active.state === 'recording') { finalizing = true; active.stop(); }
        controls();
      }, 100);
      status('녹화 중이에요. 동작을 마친 뒤 녹화를 종료해 주세요.'); controls();
    } catch (_) { recorder = null; status('녹화를 시작하지 못했어요. 카메라와 브라우저를 확인해 주세요.', true); controls(); }
  }
  async function submit() {
    const q = question();
    let body, route;
    if (q.type === 'choice') { body = new URLSearchParams({ number: index, answer: selected }); route = '/choice'; }
    else {
      body = new FormData(); body.append('number', index); body.append('attempt_id', attemptId);
      body.append('video', blob, 'attempt.' + (blob.type.startsWith('video/mp4') ? 'mp4' : 'webm')); route = '/motion';
    }
    status('답안을 확인하고 있어요. 잠시만 기다려 주세요.');
    exam = await request('/' + exam.id + route, body);
    const current = question();
    el('next').hidden = false; el('skip').hidden = true;
    el('attempt').textContent = current.verdict === 'pending' ? '동작을 또렷하게 확인하지 못했어요. 다시 촬영하거나 다음 문제로 넘어가도 돼요. (' + current.attempts + '/3회)' : '';
    status(current.verdict === 'pending' ? '이번 동작은 다시 확인이 필요해요. 한 번 더 촬영해 볼까요?' : '답안이 저장됐어요. 정답은 시험 종료 후 공개돼요.');
    if (current.verdict !== 'pending') clearPreview();
  }
  async function next() {
    if (index + 1 < exam.questions.length) { index++; showQuestion(); }
    else { exam = await request('/' + exam.id + '/finish', new URLSearchParams({ finish: 'true' })); showResult(); }
  }
  function showResult() {
    stopCamera(); clearPreview();
    el('active').hidden = true; el('setup').hidden = true; el('result').hidden = false;
    el('summary').replaceChildren(); el('results').replaceChildren();
    ['choice', 'motion'].forEach(type => {
      const section = exam.summary[type];
      if (!section.count) return;
      const card = make('div', undefined, 'we-stat');
      card.append(make('p', type === 'choice' ? '영상 이해' : '동작 표현 · AI 학습 평가'));
      card.append(make('strong', section.correct + ' / ' + section.count + (type === 'choice' ? '개 정답' : '개 목표 단어로 인식')));
      card.append(make('p', '재연습 ' + section.incorrect + '개 · 확인 필요 ' + section.pending + '개'));
      if (section.score !== null) card.append(make('p', '이해 점수 ' + section.score + '점'));
      el('summary').append(card);
    });
    exam.questions.forEach((q, i) => {
      const row = make('article', undefined, 'we-result-row');
      row.append(make('h3', (i + 1) + '. ' + q.label + ' · ' + ({correct:'정답', incorrect:'재연습', pending:'확인 필요'}[q.verdict])));
      if (q.type === 'motion') {
        const feedback = make('div'); window.SignCoaching.render(feedback, q.evaluation?.feedback); row.append(feedback);
      } else if (q.answer) row.append(make('p', '선택한 답: ' + (q.choices.find(c => c.id === q.answer)?.label || '선택하지 않음'), 'we-muted'));
      const details = make('details'); details.append(make('summary', '모범 동작 보기'));
      details.addEventListener('toggle', () => {
        if (!details.open || details.querySelector('video')) return;
        const video = make('video'); video.controls = true; video.playsInline = true; video.preload = 'metadata';
        video.src = api + '/' + exam.id + '/questions/' + i + '/video'; details.append(video);
      }); row.append(details);
      const link = make('a', '이 단어 연습하기'); link.href = ctx + '/learn/signs?chapter=' + encodeURIComponent(q.chapter_id) + '&word=' + encodeURIComponent(q.word_id); row.append(link);
      el('results').append(row);
    });
    status(exam.questions.some(q => q.verdict === 'pending') ? '아직 확인하지 못한 단어가 있어요. 복습하면서 다시 도전해 보세요.' : '시험 결과가 저장됐어요. 필요한 단어부터 다시 연습해 보세요.');
    controls();
  }
  async function init() {
    status('시험 과정을 불러오고 있어요.');
    const response = await fetch(ctx + '/api/sign-learning/chapters', { credentials: 'same-origin' });
    if (!response.ok) throw new Error('학습 과정을 불러오지 못했어요. 새로고침 후 다시 시도해 주세요.');
    const catalog = await response.json();
    if (catalog.total_words !== 70 || catalog.chapters?.length !== 7) throw new Error('기본 70단어 과정에 연결되어 있는지 확인해 주세요.');
    catalog.chapters.forEach(c => { const option = make('option', c.title + ' · ' + c.word_count + '문항'); option.value = c.chapter_id; el('scope').append(option); });
    const id = new URLSearchParams(location.search).get('session');
    if (id) { receive(await request('/' + encodeURIComponent(id))); return; }
    const history = await request('/history');
    el('history').replaceChildren();
    history.forEach(item => {
      const date = new Date(item.started_at).toLocaleString('ko-KR', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' });
      const button = make('button', item.scope + ' · ' + item.count + '문항 · ' + date + ' · ' + (item.finished ? '결과 보기' : '이어서 풀기'));
      button.type = 'button'; button.addEventListener('click', () => task(async () => receive(await request('/' + item.id)))); el('history').append(button);
    });
    if (!history.length) el('history').append(make('p', '첫 시험을 시작해 보세요.', 'we-muted'));
    status('범위와 시험 방식을 선택해 주세요.');
  }
  el('video').addEventListener('loadeddata', () => { videoReady = true; controls(); });
  el('video').addEventListener('error', () => { videoReady = false; el('video-error').textContent = '영상을 불러오지 못했어요. 새로고침하거나 이 문제는 나중에 연습해 주세요.'; controls(); });
  el('start').addEventListener('click', () => task(() => start()));
  el('camera-on').addEventListener('click', openCamera);
  el('record').addEventListener('click', record);
  el('stop').addEventListener('click', () => { if (recording()) { finalizing = true; recorder.stop(); controls(); } });
  el('submit').addEventListener('click', () => task(submit));
  el('next').addEventListener('click', () => task(next));
  el('skip').addEventListener('click', () => task(async () => { exam = await request('/' + exam.id + '/skip', new URLSearchParams({ number: index })); await next(); }));
  el('review').addEventListener('click', () => task(() => start(exam.id)));
  document.addEventListener('visibilitychange', () => { if (document.hidden && recording()) { discarded = true; recorder.stop(); } });
  window.addEventListener('pagehide', () => { disposed = true; discarded = true; clearInterval(timer); if (recording()) recorder.stop(); stopCamera(); clearPreview(); });
  window.addEventListener('pageshow', event => { if (event.persisted) location.reload(); });
  task(init);
})();
