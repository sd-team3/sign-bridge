'use strict';
(()=>{
const $=id=>document.getElementById(id),v=$('video'),c=$('avatar'),g=c.getContext('2d');
const edges=[[0,1],[1,2],[2,3],[3,4],[0,5],[5,6],[6,7],[7,8],[5,9],[9,10],[10,11],[11,12],[9,13],[13,14],[14,15],[15,16],[13,17],[0,17],[17,18],[18,19],[19,20]];
let data=null;
function point(p){const w=800,h=800/data.aspect,top=(600-h)/2;return[p[0]*w,p[1]*h+top];}
function line(a,b,color,width){g.beginPath();g.moveTo(...a);g.lineTo(...b);g.strokeStyle=color;g.lineWidth=width;g.lineCap='round';g.stroke();}
function circle(p,r,color){g.beginPath();g.arc(p[0],p[1],r,0,Math.PI*2);g.fillStyle=color;g.fill();}
function draw(t){g.clearRect(0,0,800,600);g.fillStyle='#f4f9f6';g.fillRect(0,0,800,600);g.strokeStyle='#e4ede7';g.lineWidth=1;for(let x=0;x<800;x+=40){g.beginPath();g.moveTo(x,0);g.lineTo(x,600);g.stroke();}for(let y=0;y<600;y+=40){g.beginPath();g.moveTo(0,y);g.lineTo(800,y);g.stroke();}
if(!data)return;let lo=0,hi=data.frames.length-1;while(lo<hi){const m=Math.ceil((lo+hi)/2);if(data.frames[m].t<=t)lo=m;else hi=m-1;}const f=data.frames[lo],pose=f.pose,valid=i=>pose&&pose[i]&&pose[i][2]>=.7;
if(valid(11)&&valid(12)){const a=point(pose[11]),b=point(pose[12]),mid=[(a[0]+b[0])/2,(a[1]+b[1])/2],span=Math.hypot(a[0]-b[0],a[1]-b[1]);if(valid(23)&&valid(24)){g.beginPath();g.moveTo(...a);g.lineTo(...b);g.lineTo(...point(pose[24]));g.lineTo(...point(pose[23]));g.closePath();g.fillStyle='#d6e5dc';g.fill();}line(a,b,'#85a99a',Math.max(9,span*.09));if(valid(0)){const n=point(pose[0]);line(mid,[n[0],n[1]+span*.18],'#85a99a',span*.11);circle(n,span*.21,'#c1d9cb');}}
for(const[a,b]of [[11,13],[13,15],[12,14],[14,16]])if(valid(a)&&valid(b))line(point(pose[a]),point(pose[b]),'#789f90',13);
for(const i of[11,12,13,14,15,16])if(valid(i))circle(point(pose[i]),7,'#507f6d');
let hands=0;f.hands.forEach((h,slot)=>{if(!h)return;hands++;const color=slot===0?'#10a887':'#eb8959';g.beginPath();[0,5,9,13,17].forEach((idx,j)=>{const p=point(h[idx]);j?g.lineTo(...p):g.moveTo(...p);});g.closePath();g.fillStyle=slot===0?'#a4e3ce':'#f4c9b2';g.fill();for(const[a,b]of edges)line(point(h[a]),point(h[b]),color,3.2);h.forEach(p=>circle(point(p),2.7,color));});
g.fillStyle='#426756';g.font='18px system-ui';g.fillText(`커피 · ${lo+1}/${data.frames.length} 프레임`,22,32);if(hands<2){g.fillStyle='#8c6040';g.fillText(`검출된 손 ${hands}개 · 미검출 손은 추정하지 않음`,22,578);}
$('seek').value=t;$('time').textContent=t.toFixed(1)+' / '+data.duration.toFixed(1)+'초';}
function tick(){draw(v.currentTime);requestAnimationFrame(tick);}
function sync(){ $('play').textContent=v.paused?'재생':'일시정지';}
$('play').onclick=async()=>{try{v.paused?await v.play():v.pause();}catch(e){$('status').textContent='재생 실패: '+e.message;}sync();};
$('restart').onclick=()=>{v.currentTime=0;draw(0);};$('seek').oninput=e=>{v.currentTime=Number(e.target.value);draw(v.currentTime);};$('speed').onchange=e=>v.playbackRate=Number(e.target.value);$('loop').onchange=e=>v.loop=e.target.checked;v.loop=true;v.onplay=sync;v.onpause=sync;v.onended=sync;
v.onerror=()=>{$('status').textContent='원본 영상을 불러오지 못했습니다. 서버 상태를 확인하세요.';$('play').disabled=true;};
fetch('/static/avatar/coffee.json').then(r=>{if(!r.ok)throw Error('HTTP '+r.status);return r.json();}).then(d=>{if(!d.frames?.length)throw Error('빈 랜드마크');data=d;$('seek').max=d.duration;$('play').disabled=false;$('restart').disabled=false;$('seek').disabled=false;$('status').textContent=`준비 완료 · ${d.frames.length}프레임 · ${d.sample_fps.toFixed(1)}fps. 재생을 누르세요.`;draw(0);}).catch(e=>$('status').textContent='아바타 로딩 실패: '+e.message);
requestAnimationFrame(tick);
})();
