(() => {
  'use strict';
  const make = (tag, text, cls) => {
    const node = document.createElement(tag);
    if (text) node.textContent = text;
    if (cls) node.className = cls;
    return node;
  };
  const comparisonDialogs = new WeakMap();
  function model(feedback) {
    const f = feedback || {};
    const semantic = f.policy === 'semantic_v1';
    const corrections = semantic ? [] : f.observations?.corrections || [];
    const items = [...new Set([...corrections.map(c => c.text), ...(f.actions || [])].filter(x => typeof x === 'string' && x.trim()))];
    const titles = {
      insufficient_tracking: '먼저 촬영 환경을 맞춰 주세요', insufficient_comparison: '동작 전체를 다시 보여 주세요',
      reference_unavailable: '모범 동작을 불러오지 못했어요', target_mismatch: '목표 단어와 다르게 인식됐어요',
      uncertain_recognition: '한 번 더 확인할게요', low_similarity: '모범 동작과 차근차근 맞춰 봐요',
      alignment_difference: '시작 위치와 이동 순서를 확인해요', correction: '이번에는 이 부분부터 연습해요',
      recognized_variation: '목표 단어로 인식했어요', outside_curriculum: '목표 단어를 다시 확인해요'
    };
    const required = f.feedback_required === true;
    let title = semantic ? titles[f.reason] || '이번 동작을 확인했어요'
      : required ? titles[f.reason] || '한 가지씩 천천히 맞춰 봐요' : '좋아요. 다음 동작으로 이어가요';
    let primary = semantic ? f.message : items[0] || f.message;
    primary ||= '모범 영상을 확인하고 동작 전체를 다시 촬영해 주세요.';
    if (required && /잘하셨어요|다음 단어/.test(primary)) primary = f.reason === 'insufficient_tracking'
      ? '양쪽 어깨와 동작에 사용하는 손이 보이도록 맞추고, 동작 전체를 다시 촬영해 주세요.'
      : '모범 영상을 느리게 보며 손의 시작 위치와 이동 경로를 확인해 주세요.';
    if (!feedback) { title = '자세 피드백을 확인하지 못했어요'; primary = '잠시 후 같은 영상으로 다시 평가해 주세요.'; }
    const score = f.similarity?.available === true && typeof f.similarity.score === 'number' && Number.isFinite(f.similarity.score) ? f.similarity.score : null;
    const rest = (semantic ? items : items.slice(1)).filter(x => x !== primary && !/잘하셨어요|다음 단어/.test(x));
    return { title, primary, rest, score, required, semantic, notes: (f.reference_notes || []).filter(x => typeof x === 'string') };
  }
  function renderHighlightNotes(container, frame, comparison) {
    container.replaceChildren();
    const notes = [...new Set((frame?.highlight_notes || []).filter(x => typeof x === 'string' && x.trim()))].slice(0, 3);
    if (frame) container.append(make('p', frame.phase + ' 구간의 비교', 'sc-score'));
    if (frame?.comparison_status === 'highlighted' && notes.length) {
      const list = make('ul');
      notes.forEach(text => list.append(make('li', text)));
      container.append(list);
    } else if (frame?.comparison_status === 'no_major_difference' && !notes.length) {
      container.append(make('p', '동작에서 큰 차이를 찾지 못했어요.'));
    } else {
      let message = '이 구간의 개선 부위 정보를 확인하지 못했어요. 다시 촬영해 주세요.';
      if (!comparison) message = '이번 결과에는 비교 이미지가 포함되지 않아 표시된 부위를 확인할 수 없어요.';
      else if (comparison.available === false) message = comparison.notice || '이번 촬영은 모범 동작과 비교하기 어려워요.';
      else if (frame?.comparison_status === 'unavailable') message = comparison.alignment === 'relative_time' && comparison.notice
        ? comparison.notice : '이 구간은 손의 위치나 동작 시점을 충분히 확인하지 못해 개선 부위를 안내하기 어려워요.';
      container.append(make('p', message));
    }
  }
  function renderComparison(container, feedback, onSelect) {
    const comparison = feedback?.comparison;
    if (!comparison) return;
    if (!comparison.available) {
      container.append(make('p', comparison.notice || '이번 촬영의 비교 화면을 준비하지 못했어요.', 'sc-score'));
      return;
    }
    const frames = (comparison.frames || []).filter(frame => typeof frame.image === 'string' && frame.image.startsWith('data:image/svg+xml;base64,') && frame.image.length < 300000);
    if (!frames.length) return;
    const details = make('details', undefined, 'sc-avatar');
    details.open = feedback.feedback_required === true;
    details.append(make('summary', '모범 · 내 동작을 아바타로 비교하기'));
    details.append(make('p', comparison.notice, 'sc-score'));
    const tools = make('div', undefined, 'sc-avatar-tools');
    const scroll = make('div', undefined, 'sc-avatar-scroll');
    const picture = make('img', undefined, 'sc-avatar-image');
    picture.width = 900; picture.height = 510;
    const phase = make('p', '', 'sc-score');
    const buttons = [];
    let selected = Math.min(1, frames.length-1);
    function choose(index) {
      selected = index;
      picture.src = frames[index].image;
      picture.alt = frames[index].phase + ' 구간의 모범 동작과 사용자 동작, 손 모양 확대 비교';
      buttons.forEach((button,i) => button.setAttribute('aria-pressed',String(i===index)));
      phase.textContent = '모범 ' + (frames[index].reference_timestamp_ms/1000).toFixed(1) + '초 · 내 동작 ' + (frames[index].user_timestamp_ms/1000).toFixed(1) + '초';
      onSelect(frames[index], comparison);
    }
    frames.forEach((frame,index) => {
      const button = make('button', frame.phase, 'btn btn-ghost btn-sm');
      button.type = 'button';button.addEventListener('click',()=>choose(index));buttons.push(button);tools.append(button);
    });
    const zoom = make('button', '크게 보기', 'btn btn-ghost btn-sm');zoom.type='button';
    zoom.addEventListener('click',()=>{
      const dialog=make('dialog',undefined,'sc-avatar-dialog');
      const close=make('button','닫기','btn btn-ghost');close.type='button';
      const image=make('img');image.src=frames[selected].image;image.alt=picture.alt;
      const viewport=make('div',undefined,'sc-avatar-scroll');viewport.append(image);
      dialog.append(close,viewport);document.body.append(dialog);comparisonDialogs.set(container,dialog);
      close.addEventListener('click',()=>dialog.close());dialog.addEventListener('close',()=>{dialog.remove();if(comparisonDialogs.get(container)===dialog)comparisonDialogs.delete(container);});
      dialog.showModal();
    });tools.append(zoom);
    scroll.append(picture);details.append(tools,scroll,phase);
    details.append(make('p','측정 좌표에 두께를 더해 그린 아바타예요. 양쪽을 정면 영상 방향으로 맞췄으며, 거울처럼 보이는 카메라 미리보기와는 방향이 다를 수 있어요. 작은 화면에서는 이미지를 옆으로 밀어 보세요.','sc-score'));
    container.append(details);choose(selected);
  }
  function render(container, feedback) {
    const previous = comparisonDialogs.get(container);
    if (previous) { previous.close(); previous.remove(); comparisonDialogs.delete(container); }
    const data = model(feedback);
    container.replaceChildren();
    container.classList.add('sc-card');
    container.append(make('p', data.semantic ? '단어 인식 피드백' : data.required ? '다음 연습 포인트' : '자세 코칭', 'sc-eyebrow'), make('h4', data.title), make('p', data.primary, 'sc-primary'));
    const highlightNotes = make('div', undefined, 'sc-highlight-notes');
    highlightNotes.setAttribute('aria-live', 'polite');
    renderHighlightNotes(highlightNotes, null, feedback?.comparison);
    renderComparison(container, feedback, (frame, comparison) => renderHighlightNotes(highlightNotes, frame, comparison));
    if (data.rest.length) {
      const details = make('details');
      details.append(make('summary', data.semantic ? '다음 촬영에서 확인할 점' : '추가 연습 포인트 ' + data.rest.length + '개'));
      const list = make('ul');
      data.rest.forEach(text => list.append(make('li', text)));
      details.append(list); container.append(details);
    }
    const note = data.score === null ? '이번 촬영에서는 동작 비교 점수를 계산하지 못했어요.' : '모범 영상과 좌표 비교 ' + data.score.toFixed(1) + ' / 100';
    if (data.semantic || feedback?.comparison) {
      if (feedback?.comparison || data.notes.length || data.score !== null) {
        const details = make('details'); details.append(make('summary', '모범 영상과 비교해 보기 · 참고'));
        details.append(highlightNotes);
        details.append(make('p', note + ' · 정답 여부나 수어 정확도를 뜻하지 않아요.', 'sc-score'));
        container.append(details);
      }
    } else container.append(make('p', note + ' · 비교 점수는 정확도가 아니에요.', 'sc-score'));
  }
  window.SignCoaching = { model, render };
})();
