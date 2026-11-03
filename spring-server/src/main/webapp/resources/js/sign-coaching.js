(() => {
  'use strict';
  const make = (tag, text, cls) => {
    const node = document.createElement(tag);
    if (text) node.textContent = text;
    if (cls) node.className = cls;
    return node;
  };
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
  function render(container, feedback) {
    const data = model(feedback);
    container.replaceChildren();
    container.classList.add('sc-card');
    container.append(make('p', data.semantic ? '단어 인식 피드백' : data.required ? '다음 연습 포인트' : '자세 코칭', 'sc-eyebrow'), make('h4', data.title), make('p', data.primary, 'sc-primary'));
    if (data.rest.length) {
      const details = make('details');
      details.append(make('summary', data.semantic ? '다음 촬영에서 확인할 점' : '추가 연습 포인트 ' + data.rest.length + '개'));
      const list = make('ul');
      data.rest.forEach(text => list.append(make('li', text)));
      details.append(list); container.append(details);
    }
    const note = data.score === null ? '이번 촬영에서는 동작 비교 점수를 계산하지 못했어요.' : '모범 영상과 좌표 비교 ' + data.score.toFixed(1) + ' / 100';
    if (data.semantic) {
      if (data.notes.length || data.score !== null) {
        const details = make('details'); details.append(make('summary', '모범 영상과 비교해 보기 · 참고'));
        if (data.notes.length) {
          const list = make('ul'); data.notes.forEach(text => list.append(make('li', text))); details.append(list);
        }
        details.append(make('p', note + ' · 정답 여부나 수어 정확도를 뜻하지 않아요.', 'sc-score'));
        container.append(details);
      }
    } else container.append(make('p', note + ' · 비교 점수는 정확도가 아니에요.', 'sc-score'));
  }
  window.SignCoaching = { model, render };
})();
