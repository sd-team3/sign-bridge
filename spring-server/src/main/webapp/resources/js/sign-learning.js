(() => {
  'use strict';
  const root = document.getElementById('sign-learning');
  if (!root) return;
  const el = name => document.getElementById('sl-' + name);
  const ctx = root.dataset.context || '';
  const api = ctx + '/api/sign-learning';
  let signedIn = root.dataset.signedIn === 'true';
  const chapters = new Map();
  const sessionResults = new Map();
  let current = null, stream = null, recorder = null, recording = null;
  let phase = 'idle', referenceReady = false, cameraPending = false;
  let revision = 0, timer = null, startedAt = 0, requestAbort = null, disposed = false;
  let wordAbort = null, failedRecording = false, durationLimit = 19000;
  const maxBytes = 25 * 1024 * 1024;
  const locked = () => ['recording', 'finalizing', 'evaluating'].includes(phase);
  const status = (message, error = false) => {
    el('status').textContent = message;
    el('status').dataset.error = String(error);
  };
  function updateControls() {
    const busy = locked();
    el('record').disabled = busy || !current || !stream || !referenceReady || !signedIn || cameraPending;
    el('finish').disabled = phase !== 'recording' || performance.now() - startedAt < 2000;
    el('start-camera').disabled = busy || cameraPending || !!stream || !signedIn || !current;
    el('stop-camera').disabled = busy || !stream;
    el('resubmit').hidden = !recording || phase !== 'error';
    el('resubmit').disabled = busy || !signedIn;
    el('record').textContent = recording || phase === 'result' ? '다시 촬영' : '녹화 시작';
    el('recording-badge').hidden = phase !== 'recording';
    const index = current ? current.chapter.words.findIndex(w => w.word_id === current.word.word_id) : -1;
    el('prev').disabled = busy || !current || index <= 0;
    el('next').disabled = busy || !current || index >= current.chapter.words.length - 1;
    root.querySelectorAll('.sl-word').forEach(button => { button.disabled = busy; });
    el('workspace').setAttribute('aria-busy', String(phase === 'evaluating'));
  }
  async function fetchJson(url, options = {}) {
    const response = await fetch(url, { credentials: 'same-origin', ...options });
    let body;
    try { body = await response.json(); } catch (_) { body = null; }
    if (!response.ok) {
      const message = response.status === 401 ? '로그인이 필요합니다. 로그인 후 다시 이용해 주세요.'
        : response.status === 403 ? '로그인 세션이 변경되었거나 만료되었습니다. 페이지를 새로고침해 주세요.'
        : body?.message || '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      throw Object.assign(new Error(message), { status: response.status });
    }
    if (!body || response.redirected) throw new Error('서버 응답을 확인할 수 없습니다. 페이지를 새로고침해 주세요.');
    return body;
  }
  function make(tag, text, className) {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    if (className) node.className = className;
    return node;
  }
  function refreshWordMarks() {
    root.querySelectorAll('.sl-word').forEach(button => {
      button.setAttribute('aria-current', String(current?.word.word_id === button.dataset.word));
      button.querySelector('.sl-word-mark').textContent = sessionResults.get(button.dataset.word) || '';
    });
  }
  async function loadChapter(entry) {
    if (entry.data) return entry.data;
    if (entry.pending) return entry.pending;
    entry.list.replaceChildren(make('p', '단어를 불러오고 있어요…', 'sl-placeholder'));
    entry.pending = (async () => {
      try {
        const data = await fetchJson(api + '/chapters/' + encodeURIComponent(entry.id));
        if (!Array.isArray(data.words) || !data.words.length) throw new Error('이 챕터의 단어가 없습니다.');
        data.words.sort((a, b) => a.order - b.order);
        entry.data = data;
        entry.list.replaceChildren();
        data.words.forEach(word => {
          const button = make('button', undefined, 'sl-word');
          button.type = 'button';
          button.dataset.word = word.word_id;
          button.append(make('span', String(word.order).padStart(2, '0'), 'sl-word-number'), make('span', word.label), make('span', '', 'sl-word-mark'));
          button.addEventListener('click', () => selectWord(data, word));
          entry.list.append(button);
        });
        refreshWordMarks();
        updateControls();
        return data;
      } catch (error) {
        const retry = make('button', '다시 불러오기', 'btn btn-ghost btn-sm');
        retry.type = 'button';
        retry.addEventListener('click', () => loadChapter(entry).catch(() => {}));
        entry.list.replaceChildren(make('p', error.message, 'sl-hint'), retry);
        throw error;
      } finally { entry.pending = null; }
    })();
    return entry.pending;
  }
  async function loadCatalog() {
    el('catalog-error').hidden = true;
    el('chapters').setAttribute('aria-busy', 'true');
    el('reload').disabled = true;
    try {
      const catalog = await fetchJson(api + '/chapters');
      if (!Array.isArray(catalog.chapters) || !catalog.chapters.length) throw new Error('아직 학습 과정이 준비되지 않았습니다.');
      el('course-count').textContent = catalog.chapters.length + '개 챕터 · ' + catalog.total_words + '개 단어';
      el('chapters').replaceChildren();
      chapters.clear();
      catalog.chapters.sort((a, b) => a.order - b.order).forEach(chapter => {
        const details = make('details', undefined, 'sl-chapter');
        const summary = make('summary', chapter.order + '. ' + chapter.title);
        summary.append(make('span', chapter.stage + ' · ' + chapter.word_count + '개 단어', 'sl-stage'));
        const list = make('div', undefined, 'sl-words');
        const entry = { id: chapter.chapter_id, details, list, data: null, pending: null };
        chapters.set(entry.id, entry);
        details.append(summary, list);
        details.addEventListener('toggle', () => { if (details.open) loadChapter(entry).catch(() => {}); });
        el('chapters').append(details);
      });
      const params = new URLSearchParams(location.search);
      const entry = chapters.get(params.get('chapter')) || chapters.values().next().value;
      entry.details.open = true;
      const initialRevision = revision;
      const chapter = await loadChapter(entry);
      if (revision === initialRevision) {
        const word = chapter.words.find(w => w.word_id === params.get('word')) || chapter.words[0];
        await selectWord(chapter, word, false);
      }
    } catch (error) {
      el('catalog-error').hidden = false;
      el('catalog-message').textContent = error.message;
      el('course-count').textContent = '과정 연결 대기';
    } finally {
      el('chapters').setAttribute('aria-busy', 'false');
      el('reload').disabled = false;
    }
  }
  async function selectWord(chapter, word, scroll = true) {
    if (locked() || disposed) return;
    const token = ++revision;
    wordAbort?.abort();
    wordAbort = new AbortController();
    current = null;
    referenceReady = false;
    recording = null;
    phase = 'idle';
    el('workspace').hidden = false;
    el('empty').hidden = true;
    el('result').hidden = true;
    el('timer').textContent = '00:00';
    el('word-label').textContent = word.label;
    el('chapter-label').textContent = chapter.title;
    el('word-order').textContent = word.order + ' / ' + chapter.words.length;
    el('reference-status').textContent = '모범 영상을 준비하고 있어요.';
    el('reference').pause();
    el('reference').removeAttribute('src');
    el('reference').load();
    el('speed').value = '1';
    status('단어 정보를 불러오고 있어요…');
    refreshWordMarks();
    updateControls();
    try {
      const detail = await fetchJson(api + '/words/' + encodeURIComponent(word.word_id), { signal: wordAbort.signal });
      if (token !== revision || disposed) return;
      if (detail.chapter_id !== chapter.chapter_id || detail.word_id !== word.word_id) throw new Error('챕터와 단어 정보가 일치하지 않습니다. 목록을 다시 불러와 주세요.');
      current = { chapter, word: detail };
      durationLimit = Math.min(19000, (detail.capture?.max_duration_ms || 20000) - 1000);
      el('guidance').textContent = detail.capture?.guidance || '양쪽 어깨와 동작에 사용하는 손이 보이도록 촬영해 주세요.';
      el('reference').src = api + '/reference/' + encodeURIComponent(word.word_id);
      el('reference').playbackRate = 1;
      status('2~10초 동안 동작 전체를 촬영해 주세요. 최대 19초에 자동 종료됩니다.');
      history.replaceState(null, '', ctx + '/learn/signs?chapter=' + encodeURIComponent(chapter.chapter_id) + '&word=' + encodeURIComponent(word.word_id));
      if (scroll && window.matchMedia('(max-width: 700px)').matches) el('workspace').scrollIntoView({ behavior: 'smooth', block: 'start' });
    } catch (error) {
      if (token !== revision || error.name === 'AbortError') return;
      el('reference-status').textContent = '단어를 다시 선택해 주세요.';
      status(error.message, true);
    }
    refreshWordMarks();
    updateControls();
  }
  el('reference').addEventListener('loadeddata', () => {
    if (!current || !el('reference').getAttribute('src')) return;
    referenceReady = true;
    el('reference-status').textContent = '반복해서 보거나 느리게 재생하며 동작을 익혀보세요.';
    updateControls();
  });
  el('reference').addEventListener('error', () => {
    if (!el('reference').getAttribute('src')) return;
    referenceReady = false;
    el('reference-status').textContent = '모범 영상을 불러오지 못했습니다. 단어를 다시 선택해 주세요.';
    updateControls();
  });
  el('speed').addEventListener('change', () => { el('reference').playbackRate = Number(el('speed').value); });
  el('restart').addEventListener('click', () => {
    if (!referenceReady) return;
    el('reference').currentTime = 0;
    el('reference').play().catch(() => {});
  });
  function stopCamera() {
    if (stream) stream.getTracks().forEach(track => track.stop());
    stream = null;
    el('camera').srcObject = null;
    el('camera-placeholder').hidden = false;
    updateControls();
  }
  async function startCamera() {
    if (cameraPending || stream || !signedIn) return;
    if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
      status('카메라는 HTTPS 또는 localhost에서 사용할 수 있습니다.', true); return;
    }
    if (!window.MediaRecorder || !chooseMime()) {
      status('이 브라우저에서는 영상 녹화를 지원하지 않습니다. 최신 Chrome, Edge 또는 Safari를 이용해 주세요.', true); return;
    }
    cameraPending = true;
    updateControls();
    try {
      const opened = await navigator.mediaDevices.getUserMedia({ audio: false, video: { width: { ideal: 1280, max: 1920 }, height: { ideal: 720, max: 1080 }, frameRate: { ideal: 30, max: 30 }, facingMode: 'user' } });
      if (disposed) { opened.getTracks().forEach(track => track.stop()); return; }
      const settings = opened.getVideoTracks()[0].getSettings();
      if (settings.width > 1920 || settings.height > 1080) {
        opened.getTracks().forEach(track => track.stop());
        throw new Error('카메라 해상도를 1920×1080 이하로 설정해 주세요.');
      }
      stream = opened;
      el('camera').srcObject = stream;
      await el('camera').play();
      el('camera-placeholder').hidden = true;
      stream.getVideoTracks()[0].addEventListener('ended', () => {
        failedRecording = true;
        if (recorder?.state === 'recording') recorder.stop();
        stopCamera();
        status('카메라 연결이 끊겼습니다. 다시 켜 주세요.', true);
      });
      status('카메라가 준비됐어요. 양쪽 어깨와 동작에 사용하는 손을 화면 안에 맞춰 주세요.');
    } catch (error) {
      stopCamera();
      const messages = { NotAllowedError: '카메라 권한이 차단되었습니다. 브라우저 설정에서 카메라를 허용해 주세요.', NotFoundError: '연결된 카메라를 찾을 수 없습니다.', NotReadableError: '다른 앱이 카메라를 사용 중입니다. 카메라 사용을 종료한 뒤 다시 시도해 주세요.', OverconstrainedError: '카메라가 요청한 해상도를 지원하지 않습니다. 다른 카메라를 이용해 주세요.' };
      status(messages[error.name] || error.message, true);
    } finally { cameraPending = false; updateControls(); }
  }
  function chooseMime() {
    return ['video/webm;codecs=vp8', 'video/webm;codecs=vp9', 'video/webm', 'video/mp4'].find(type => window.MediaRecorder?.isTypeSupported(type));
  }
  function finishRecording() {
    if (recorder?.state !== 'recording') return;
    phase = 'finalizing';
    clearInterval(timer);
    recorder.stop();
    status('촬영을 마무리하고 있어요…');
    updateControls();
  }
  function startRecording() {
    if (locked() || !current || !stream || !referenceReady || !signedIn) return;
    const selected = current;
    const chunks = [];
    let size = 0;
    const attemptId = window.crypto.randomUUID ? window.crypto.randomUUID() : Array.from(window.crypto.getRandomValues(new Uint8Array(16)), b => b.toString(16).padStart(2, '0')).join('');
    try {
      recorder = new MediaRecorder(stream, { mimeType: chooseMime(), videoBitsPerSecond: 1500000 });
      const activeRecorder = recorder;
      failedRecording = false;
      recording = null;
      el('result').hidden = true;
      activeRecorder.addEventListener('dataavailable', event => {
        if (!event.data.size) return;
        size += event.data.size;
        if (size > Math.min(maxBytes, selected.word.capture?.max_video_bytes || maxBytes)) {
          failedRecording = true;
          finishRecording();
        } else chunks.push(event.data);
      });
      activeRecorder.addEventListener('error', () => {
        failedRecording = true;
        clearInterval(timer);
        if (activeRecorder.state === 'recording') finishRecording();
        phase = 'idle';
        status('녹화를 완료하지 못했습니다. 카메라를 다시 켜고 촬영해 주세요.', true);
        updateControls();
      });
      activeRecorder.addEventListener('stop', () => {
        clearInterval(timer);
        if (recorder === activeRecorder) recorder = null;
        if (disposed) return;
        const blob = new Blob(chunks, { type: activeRecorder.mimeType });
        if (failedRecording || !blob.size || blob.size > maxBytes || performance.now() - startedAt < 1800) {
          phase = 'idle';
          status('영상이 너무 짧거나 녹화를 완료하지 못했습니다. 2~10초 동안 다시 촬영해 주세요.', true);
          updateControls();
          return;
        }
        recording = { blob, attemptId, wordId: selected.word.word_id, revision };
        submitRecording();
      });
      el('reference').pause();
      activeRecorder.start(250);
      startedAt = performance.now();
      phase = 'recording';
      el('timer').textContent = '00:00';
      status('녹화 중이에요. 동작을 끝낸 뒤 ‘종료 후 평가’를 눌러 주세요.');
      timer = setInterval(() => {
        const elapsed = performance.now() - startedAt;
        el('timer').textContent = '00:' + String(Math.floor(elapsed / 1000)).padStart(2, '0');
        if (elapsed >= durationLimit) finishRecording();
        updateControls();
      }, 100);
      updateControls();
    } catch (_) {
      phase = 'idle';
      status('이 카메라의 녹화 형식을 사용할 수 없습니다. 다른 브라우저에서 다시 시도해 주세요.', true);
      updateControls();
    }
  }
  async function submitRecording() {
    if (!recording || !current || phase === 'evaluating' || !signedIn) return;
    const attempt = recording;
    phase = 'evaluating';
    status('동작을 분석하고 있어요. 잠시만 기다려 주세요.');
    updateControls();
    const form = new FormData();
    form.append('target_word_id', attempt.wordId);
    form.append('attempt_id', attempt.attemptId);
    form.append('use_llm', 'false');
    form.append('video', attempt.blob, 'attempt.' + (attempt.blob.type.startsWith('video/mp4') ? 'mp4' : 'webm'));
    const headers = {};
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    if (csrfHeader && csrfToken) headers[csrfHeader] = csrfToken;
    requestAbort = new AbortController();
    const timeout = setTimeout(() => requestAbort?.abort(), 150000);
    try {
      const result = await fetchJson(api + '/evaluate-video', { method: 'POST', body: form, headers, signal: requestAbort.signal });
      if (disposed || attempt.revision !== revision || current.word.word_id !== attempt.wordId) return;
      if (result.attempt_id !== attempt.attemptId || result.target_word_id !== attempt.wordId) throw new Error('현재 촬영과 다른 응답을 받았습니다. 다시 시도해 주세요.');
      renderResult(result);
      phase = 'result';
      status('피드백을 확인하고 다시 연습하거나 다음 단어로 이동해 보세요.');
    } catch (error) {
      if (disposed || attempt.revision !== revision) return;
      phase = 'error';
      if (error.status === 401) { signedIn = false; el('login-notice').hidden = false; stopCamera(); }
      status(error.name === 'AbortError' ? '응답 시간이 초과되어 결과를 확인하지 못했습니다. 잠시 후 같은 영상으로 다시 평가해 주세요.' : error.message, true);
    } finally { clearTimeout(timeout); requestAbort = null; updateControls(); }
  }
  function renderResult(result) {
    if (result.status === 'retry') {
      el('recognition').textContent = '손과 어깨가 잘 보이도록 다시 촬영해 주세요';
      el('prediction').textContent = '동작을 충분히 확인하지 못했어요. 오답으로 처리하지 않습니다.';
    } else if (result.status === 'ok' && result.recognition) {
      const matches = result.recognition.target_matches_top1 === true;
      el('recognition').textContent = matches ? '목표 단어로 인식됐어요!' : '다른 단어로 인식됐어요';
      el('prediction').textContent = '인식한 단어: ' + result.recognition.predicted_label;
      sessionResults.set(current.word.word_id, matches ? '인식됨' : '연습함');
    } else throw new Error('평가 결과 형식을 확인할 수 없습니다. 다시 시도해 주세요.');
    el('feedback-message').textContent = result.feedback?.message || '이번 동작의 자세 피드백을 제공할 수 없습니다.';
    el('result').hidden = false;
    refreshWordMarks();
  }
  function navigate(offset) {
    if (!current || locked()) return;
    const words = current.chapter.words;
    const index = words.findIndex(w => w.word_id === current.word.word_id);
    if (words[index + offset]) selectWord(current.chapter, words[index + offset]);
  }
  function cleanup() {
    disposed = true;
    failedRecording = true;
    clearInterval(timer);
    requestAbort?.abort();
    wordAbort?.abort();
    if (recorder?.state === 'recording') recorder.stop();
    stopCamera();
    recording = null;
  }
  el('reload').addEventListener('click', loadCatalog);
  el('start-camera').addEventListener('click', startCamera);
  el('stop-camera').addEventListener('click', stopCamera);
  el('record').addEventListener('click', startRecording);
  el('finish').addEventListener('click', finishRecording);
  el('resubmit').addEventListener('click', submitRecording);
  el('prev').addEventListener('click', () => navigate(-1));
  el('next').addEventListener('click', () => navigate(1));
  window.addEventListener('pagehide', cleanup);
  window.addEventListener('pageshow', event => { if (event.persisted) location.reload(); });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && phase === 'recording') {
      failedRecording = true;
      finishRecording();
    }
  });
  loadCatalog();
})();
