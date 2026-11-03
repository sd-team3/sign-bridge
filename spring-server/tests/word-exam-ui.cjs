const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'src/main/webapp/WEB-INF/views/exam/words.jsp'), 'utf8')
  .replace(/<%[\s\S]*?%>/g, '').replace(/<jsp:include[^>]*\/>/g, '').replace(/<c:url value='([^']+)'\/>/g, '$1').replace(/\$\{[^}]*\}/g, '');
const dom = new JSDOM(html, { url: 'https://sign.test/exam/setup', runScripts: 'outside-only' });
const w = dom.window;
w.HTMLMediaElement.prototype.load = function () {};
w.HTMLMediaElement.prototype.play = async function () {};
w.HTMLMediaElement.prototype.pause = function () {};
w.URL.createObjectURL = () => 'blob:test'; w.URL.revokeObjectURL = () => {};
let now = 0;
Object.defineProperty(w.performance, 'now', { value: () => now });
const track = { stop() {}, addEventListener() {} };
Object.defineProperty(w.navigator, 'mediaDevices', { value: { getUserMedia: async () => ({ getTracks: () => [track], getVideoTracks: () => [track] }) } });
Object.defineProperty(w, 'isSecureContext', { value: true });
class Recorder {
  static isTypeSupported() { return true; }
  constructor(stream, options) { this.mimeType = options.mimeType; this.state = 'inactive'; }
  start() { this.state = 'recording'; }
  stop() { this.state = 'inactive'; this.ondataavailable({ data: new w.Blob(['video']) }); this.onstop(); }
}
w.MediaRecorder = Recorder;
let state = { id: 'exam-1', scope: '테스트 챕터', finished: false, questions: [
  {number:0,type:'choice',submitted:false,attempts:0,choices:[{id:'WORD0001',label:'나'},{id:'WORD0002',label:'너'}]},
  {number:1,type:'motion',submitted:false,attempts:0,label:'커피',word_id:'WORD0003',chapter_id:'chapter-01'}
] };
const requests = [];
const clone = obj => JSON.parse(JSON.stringify(obj));
w.fetch = async (url, options = {}) => {
  requests.push({url,options});
  let data;
  if (url.endsWith('/chapters')) data = {total_words:70,chapters:Array.from({length:7},(_,i)=>({chapter_id:'chapter-0'+(i+1),title:'챕터'+i,word_count:10}))};
  else if (url.endsWith('/history')) data = [];
  else if (url.endsWith('/start')) data = state;
  else if (url.endsWith('/choice')) { state.questions[0].submitted = true; data = state; }
  else if (url.endsWith('/motion')) { state.questions[1].submitted = true; state.questions[1].verdict = 'pending'; state.questions[1].attempts++; data = state; }
  else if (url.endsWith('/finish')) {
    state.finished = true;
    state.summary = {choice:{count:1,correct:1,incorrect:0,pending:0,score:100},motion:{count:1,correct:0,incorrect:0,pending:1,score:null},complete:false};
    Object.assign(state.questions[0],{word_id:'WORD0001',chapter_id:'chapter-01',label:'나',answer:'WORD0001',verdict:'correct'}); data = state;
  } else throw new Error('Unexpected request: '+url);
  return {ok:true,json:async()=>clone(data)};
};
for (const script of ['sign-coaching.js','word-exam.js']) w.eval(fs.readFileSync(path.join(root,'src/main/webapp/resources/js',script),'utf8'));
const el = id => w.document.getElementById('we-'+id);
const tick = () => new Promise(resolve=>setTimeout(resolve,15));
(async () => {
  await tick(); assert.equal(el('scope').options.length,8); assert.equal(el('start').disabled,false);
  el('start').click(); await tick();
  assert.equal(el('active').hidden,false); assert.equal(el('submit').disabled,true);
  el('video').dispatchEvent(new w.Event('loadeddata'));
  w.document.querySelector('.we-option').click(); assert.equal(el('submit').disabled,false);
  el('submit').click(); await tick(); assert.equal(el('next').hidden,false); assert.equal(el('submit').disabled,true);
  assert.equal(el('result').hidden,true);
  el('next').click(); await tick(); assert.match(el('prompt').textContent,/커피/);
  el('camera-on').click(); await tick(); assert.equal(el('record').disabled,false);
  el('record').click(); now=3000; el('stop').disabled=false; el('stop').click();
  assert.equal(el('preview-box').hidden,false); assert.equal(el('submit').disabled,false);
  el('submit').click(); await tick(); assert.match(el('attempt').textContent,/확인하지 못/); assert.equal(el('next').hidden,false);
  el('next').click(); await tick(); assert.equal(el('result').hidden,false); assert.match(el('status').textContent,/다시 도전/);
  assert.equal(w.document.querySelectorAll('.we-result-row').length,2); assert.equal(el('review').disabled,false);
  assert.match(el('results').textContent,/자세 피드백을 확인하지 못했어요/);
  const feedback = {feedback_required:true,reason:'correction',actions:['손을 올려 주세요.','손가락을 펴 주세요.','손을 올려 주세요.'],similarity:{available:true,score:65}};
  const container=w.document.createElement('div'); w.SignCoaching.render(container,feedback);
  assert.equal(container.querySelector('.sc-primary').textContent,'손을 올려 주세요.');
  assert.equal(container.querySelector('details').open,false); assert.equal(container.querySelectorAll('li').length,1);
  assert.match(container.querySelector('.sc-score').textContent,/65.0/);
  w.SignCoaching.render(container,{feedback_required:true,reason:'insufficient_tracking',actions:['잘하셨어요. 다음 단어를 연습해 볼까요?'],similarity:{available:false,score:null}});
  assert.doesNotMatch(container.querySelector('.sc-primary').textContent,/잘하셨어요/); assert.match(container.textContent,/계산하지 못/);
  w.SignCoaching.render(container,{feedback_required:true,reason:'correction',actions:['<img src=x onerror=alert(1)>']});
  assert.equal(container.querySelector('img'),null);
  assert(requests.some(r=>r.url.endsWith('/motion')&&r.options.body instanceof w.FormData));
  w.SignCoaching.render(container,{policy:'semantic_v1',reason:'recognized_variation',feedback_required:false,message:'목표 단어로 인식됐어요.',actions:[],observations:{corrections:[{text:'손을 올려 주세요.'}]},reference_notes:['손 높이가 다르게 측정됐어요.'],similarity:{available:true,score:40}});
  assert.equal(container.querySelector('.sc-primary').textContent,'목표 단어로 인식됐어요.');
  assert.doesNotMatch(container.textContent,/손을 올려/);
  assert.equal(container.querySelector('details').open,false);
  assert(container.querySelector('.sc-score').closest('details'));
  console.log('WORD_EXAM_UI_OK: choice, recording, preview, pending, results, coaching, safe text');
  dom.window.close();
})().catch(error=>{console.error(error);dom.window.close();process.exitCode=1;});
