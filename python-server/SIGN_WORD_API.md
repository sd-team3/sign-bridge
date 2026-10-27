# 70단어 수어 학습 API — Spring 연동 명세

페이지 구현 순서는 [수어 학습 페이지 구현 도움집](SIGN_LEARNING_PAGE_GUIDE.md)을 참고하세요.

적용 모델: `curriculum70_seated_v3`, 입력 정책 `seated_active_v2`.
기본 과정 7챕터 70단어를 제공한다. 확장 30단어는 현재 과정과 분류 대상에서 제외한다.
챕터는 기존 2026-10-13 선정 목록의 단원 구성을 사용한다.
기존 지문자 `/predict`, `/coach`, `/health`는 유지한다. 이 브랜치에는 Python 모델·코칭·API만 반영하며 Spring 소스는 변경하지 않는다.

## 페이지 연결 순서

1. 챕터 페이지: `GET /api/v1/signs/chapters`.
2. 챕터 진입: `GET /api/v1/signs/chapters/chapter-01` → 순서가 있는 단어 10개.
3. 단어 진입: `GET /api/v1/signs/words/WORD1157` → 단어·소속 챕터·영상 URL·촬영 조건.
4. 반환된 `reference_video_url`로 모범 영상 재생. HTTP Range를 지원하여 탐색·반복 가능.
5. 사용자 동작 전체를 녹화한 뒤 좌표 JSON 또는 영상 파일로 평가 요청.
6. 인식 결과와 자세 피드백을 별도로 표시하고 `attempt_id`로 Spring 학습 이력에 연결.

Python은 사용자·챕터 잠금 해제·이수 여부·진도·시도 이력을 저장하지 않는다.
Spring이 인증한 사용자와 `attempt_id`, `chapter_id`, `word_id`, 응답 결과를 연결해 관리한다.
평가 응답은 이수/합격 판정이 아니다. 이수 기준은 Spring 쪽 정책으로 정한다.
`attempt_id`는 상관관계 식별자이며 중복 호출 제거 또는 영속 저장을 제공하지 않는다.

## 엔드포인트

| 메서드 | 경로 | 용도 |
|---|---|---|
| GET | `/api/v1/signs/health` | 모델 준비, 70클래스·70비교 좌표·7챕터 확인 |
| GET | `/api/v1/signs/chapters` | 챕터 요약 목록 |
| GET | `/api/v1/signs/chapters/{chapter_id}` | 챕터 상세와 순서가 있는 단어 목록 |
| GET | `/api/v1/signs/words/{word_id}` | 단어 상세·모범 영상·평가 URL·촬영 조건 |
| GET | `/api/v1/signs` | 기존 전체 단어 목록; 기존 필드는 유지하고 메타데이터 추가 |
| GET | `/api/v1/signs/reference/{word_id}` | 모범 MP4 영상, Range 지원 |
| POST | `/api/v1/signs/evaluate-video` | 녹화 영상 업로드 후 단어 인식·자세 피드백 |
| POST | `/api/v1/signs/evaluate` | 좌표 JSON으로 단어 인식·자세 피드백 |
| POST | `/api/v1/signs/predict` | 좌표 JSON으로 단어 분류 |
| WebSocket | `/api/v1/signs/practice` | 좌표 수집·검출 상태 안내·동작 완료 후 평가 |

`chapter_id`: `chapter-01`~`chapter-07`, `word_id`: `WORD` + 4자리 코드.
한국어 라벨을 식별자로 사용하지 않는다. 반환 URL은 Python 서비스 기준 상대 경로다.
Spring에서 해당 경로를 중계하거나 자신의 공개 API URL로 변환한다. 로컬 파일 경로를 브라우저에 노출하지 않는다.

### 챕터 응답

목록은 `curriculum_version`, `total_words: 100`, `chapters`를 반환한다.
각 챕터는 `chapter_id`, `order`, `title`, `stage`, `word_count: 10`, `detail_url`을 가진다.
`stage`는 `기본70`, `확장1`, `확장2`, `확장3`이다.
상세는 위 메타데이터와 `words` 배열을 반환한다. 각 단어는 챕터 내 `order` 1~10,
`word_id`, `label`, `chapter_id`, `feedback_available`, `reference_video_url`,
`evaluation_url`, `video_evaluation_url`을 가진다.

### 단어 상세 예시

`GET /api/v1/signs/words/WORD0115`의 주요 필드:

```json
{
  "word_id": "WORD0115",
  "label": "커피",
  "chapter_id": "chapter-04",
  "feedback_available": true,
  "reference_video_url": "/api/v1/signs/reference/WORD0115",
  "evaluation_url": "/api/v1/signs/evaluate",
  "video_evaluation_url": "/api/v1/signs/evaluate-video"
}
```

실제 상세 응답에는 `capture`, `feedback`도 포함된다.
`capture`: 최대 20000ms, 좌표 16~300프레임, 영상 최대 25MiB, `mirrored: false`,
`both_hands_required: false`, `shoulders_required: true` 및 한국어 촬영 안내.
양쪽 어깨와 동작에 사용하는 손이 보여야 한다. 한 손 수어의 쉬는 손은 내려놓아도 된다.
양손 수어에서 의미를 만드는 손까지 숨기라는 뜻은 아니다.

## 영상 업로드 평가

`POST /api/v1/signs/evaluate-video`, `multipart/form-data`:

| 필드 | 필수 | 설명 |
|---|---|---|
| `target_word_id` | 예 | 학습 중인 WORD 코드 |
| `video` | 예 | 브라우저 녹화 파일, 최대 25MiB·20초·1920×1080 |
| `attempt_id` | 아니오 | 1~80자, 영문·숫자·`_`·`-`. 생략하면 서버 생성 |
| `use_llm` | 아니오 | 기본 false. 확실한 교정 관측이 있을 때만 Groq 설명 추가 |

정상 속도 동작 전체를 권장 2~10초 녹화한다. 서버는 약 15fps로 샘플링하고
최소 16개 샘플이 필요하다. 파일은 임시 저장 후 성공·실패 모두 삭제한다.
프런트에서 파일명만 `.mp4`로 바꾸어도 코덱은 변환되지 않는다. 실제 사용하는
MediaRecorder의 WebM/MP4 코덱은 배포 OpenCV/FFmpeg 환경에서 확인해야 한다.
브라우저 표시를 거울처럼 뒤집어도 저장 영상 자체는 반전하지 않는다.

## 좌표 JSON 평가

`/evaluate`는 `target_word_id`가 필수이고 `/predict`에서는 선택이다.

```json
{
  "attempt_id": "spring-user-attempt-001",
  "schema_version": "raw_mp_legacy_v1",
  "mirrored": false,
  "aspect": 1.7777778,
  "target_word_id": "WORD0115",
  "use_llm": false,
  "frames": [{"timestamp_ms": 0, "hands": [null, null], "pose": null}]
}
```

위 프레임은 구조 설명용이다. 실제로는 16~300개, 시각은 0~20000ms에서 엄격히 증가해야 한다.
`hands`: MediaPipe Hands Left/Right 슬롯 순서, 각 손 21행 `[x,y,z]`, 미검출은 null.
`pose`: 33행 `[x,y,visibility]`; 세 번째 값은 z가 아니다. 미검출은 null.
`aspect`: 원본 영상 가로/세로. 정규화·미러링하지 않은 좌표를 전송한다.
슬롯의 Left/Right는 해부학적 좌우로 임의 변환하지 않는다.
서버가 쉬는 손 제외와 학습 시 전처리를 적용한다.
학습 추출기는 MediaPipe 0.10.14 legacy Hands/Pose다. 브라우저의 다른 Tasks 모델과는 별도 동등성 검증이 필요하다.


## 필수 피드백과 동작 비교 점수

완료된 동작의 평가 응답에는 `feedback.message`가 항상 있다.
`feedback.feedback_required: true`면 프런트에서 안내를 반드시 표시한다.
`observations.corrections`가 비어 있다는 이유로 피드백 영역을 숨기지 않는다.
`feedback.actions`는 사용자가 다음 촬영에서 해볼 행동 목록이다.

모범 동작과 손 위치·손가락 각도를 시점 정렬한 DTW 비용을 바탕으로
`feedback.similarity.score = round(100 × exp(-alignment_cost), 1)`을 계산한다.
점수는 0~100의 참고용 동작 비교 지표이며, 분류 확률·수어 정확도·전문가 채점 점수가 아니다.
검증된 보정 확률도 아니다. 실제 사용자 평가에 따라 기준을 조정할 수 있다.

기본 기준은 70점이며 **70점 이하(경계값 포함)**면 `status: advice`,
`feedback_required: true`와 비어 있지 않은 안내·행동 목록을 반환한다.
구체적인 관절 차이가 확인되면 해당 손·손가락·방향을 안내하고,
확인되지 않으면 모범 영상의 시작 위치·이동 경로·끝나는 위치를 순서대로 확인하도록 안내한다.
잘 측정되지 않은 손가락이나 교정 방향을 임의로 만들지 않는다.

환경변수 `SIGN_FEEDBACK_SIMILARITY_THRESHOLD`로 기준을 0~100 사이에서 설정한다.
값은 서버 시작 시 읽는다. 예: `SIGN_FEEDBACK_SIMILARITY_THRESHOLD=85`.
`/health`의 `feedback_similarity_threshold`와 단어 상세의 `feedback.similarity_threshold`에서 적용값을 확인한다.

`feedback.similarity`의 필드:

| 필드 | 의미 |
|---|---|
| `available` | 손의 비교 가능 구간이 충분하여 점수를 계산했는지 |
| `score` | 0~100 참고 점수. 계산할 수 없으면 null |
| `threshold` | 현재 서버 기준 |
| `below_threshold` | score가 기준 이하인지. 점수가 없으면 null |
| `method` | `dtw_geometry_v1` |

비교할 손의 관측이 부족하면 점수를 0으로 만들지 않는다. 점수는 null로 두고
`feedback_required: true`와 구체적인 재촬영 안내를 반환한다. 쉬는 손 노출은 요구하지 않는다.
원시 검출 부족으로 `status: retry`일 때도 같은 필수 안내 규칙을 적용한다.

모델이 목표와 다른 단어로 인식하면 비교 점수가 높아도 재연습 안내를 반환한다.
목표 단어로 인식됐지만 `recognition.target_score`가 0.7 미만인 경우에도 안내한다.
이 값은 목표 클래스의 softmax이며 위의 동작 비교 점수와 다른 지표다.

`feedback.reason`은 `low_similarity`, `target_mismatch`, `uncertain_recognition`,
`insufficient_tracking`, `insufficient_comparison`, `alignment_difference`,
`correction`, `no_clear_difference`, `reference_unavailable` 중 하나다.
낮은 점수와 오인식이 함께 있으면 점수 관련 사유를 유지하고 안내 문구에 목표·예측 단어를 함께 보여준다.

Groq를 사용해도 기본 안내 `message`와 `actions`는 유지한다.
구체적인 교정 항목이 있는 경우에만 보충 설명을 요청하며,
성공하면 `explanation`, `explanation_source: groq`를 추가한다.
빈 응답·오류·미설정일 때도 기본 안내가 사라지지 않는다.

프런트 처리 순서:

1. `status == retry`면 재촬영 안내. 인식 점수는 표시하지 않는다.
2. 정상 평가이면 목표 단어 일치 여부와 동작 비교 점수를 따로 표시한다.
3. `feedback_required`가 참이면 message와 actions를 펼쳐서 표시한다.
4. 점수가 null이면 “비교 점수 측정 불가”로 표시하고 재촬영 안내를 제공한다.
5. `explanation`은 선택적으로 보충 표시한다. 기본 안내를 대체하지 않는다.

이 변경은 평가·피드백 처리 변경이다. 70단어 분류 모델 가중치는 변경하지 않는다.

## 평가 응답 해석

- `attempt_id`, `target_word_id`, `model_id`, `input_policy`로 시도·목표·모델을 식별한다.
- `status: ok`: 추론 완료. `recognition.top3`, `predicted_label`, `target_matches_top1` 제공.
- `status: retry`: 동작 손 또는 어깨 검출 부족. `recognition: null`이므로 오답으로 집계하지 않는다.
- `quality`: 검출 프레임 수, `active_hand_frames`, `excluded_resting_slots` 등.
  제외 슬롯은 MediaPipe 슬롯 번호 0/1이며 해부학적 왼손/오른손 번호가 아니다.
- `recognition.top3[].score`: 분류 softmax 값. 자세 정확도나 숙련도 백분율이 아니다.
- `feedback.status: advice`: 관측된 자세 차이 또는 낮은 비교 점수·오인식·측정 부족에 대한 연습 안내.
- `no_reliable_correction`: 신뢰할 교정이 없거나 비교 근거 부족. 합격·완벽한 자세를 뜻하지 않는다.
- `reference_unavailable`: 비교 기준 없음. 정상 70단어 패키지는 모든 단어의 기준을 포함한다.
- `feedback.message`는 표시 가능한 문구, `observations`는 구조화된 측정 결과다.

교정은 정면 학습 영상 1개/단어 기준이다. 엄지·손바닥 방향·깊이·표정·문법 전체를 평가하지 않는다.
낮고 거의 움직이지 않는 손을 보수적으로 제외하며, 의미 있는 낮은 받침 손과의 구분에는 한계가 있다.
실시간 단계별 자세 교정은 제공하지 않고, 동작 완료 후 비교한다.

## WebSocket

1. `{"type":"start","attempt_id":"a1","aspect":1.7777778,"target_word_id":"WORD0115","use_llm":false}`
2. `{"type":"frames","frames":[...]}` 배치당 1~15개. `tracking` 응답을 받고 다음 배치 전송.
3. `{"type":"finish"}` → `result`; 성공 후 버퍼 해제.
4. `{"type":"reset"}` → 현재 시도 폐기.

실시간 응답은 검출 상태만 안내한다. 한 손이 검출돼도 촬영 가능하다.
연결별 버퍼, 최대 300프레임·128KiB/메시지, 무응답 30초 제한.
Spring은 브라우저 WS마다 Python WS 하나를 중계하고 종료 시 함께 닫는다.
HTTP 프록시만 추가하면 WS가 자동 연결되지는 않는다.

## 오류·인증·운영

- 404: 없는 챕터/단어/모범 영상.
- 422: 잘못된 요청, 목표 코드, 코덱/디코딩·영상 제한 위반.
- 413: 업로드 25MiB 초과. 429: 추론/영상 분석 중; 재시도 안내.
- 503: 모델 또는 모델과 맞는 자산이 준비되지 않음.
- `SIGN_API_KEY`가 있으면 모든 수어 HTTP/WS 경로에 `X-Sign-Api-Key` 필요.
  Spring 서버에서 전달하고 브라우저 코드에 서비스 키를 넣지 않는다.
- `GROQ_API_KEY`, `GROQ_MODEL`은 서버 환경변수. LLM은 선택 사항이며 실패하면 규칙 피드백을 유지한다.
  영상·원본 좌표 대신 계산된 교정 관측만 Groq에 전달한다.
- Python은 프로세스당 모델 1개·동시 추론 1개다. 배포 worker 증가 시 메모리도 복제된다.
- 서비스 반영 후 Python 프로세스를 재시작한다. Docker는 Python 이미지를 다시 빌드한다.
  기존 `SIGN_MODEL_PATH`가 50단어 모델로 지정되어 있으면 제거하거나 새 모델로 변경한다.

```powershell
cd C:\sign-bridge\python-server
python -m unittest discover -s tests -v
python tests/smoke_sign_word_video.py
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --ws-max-size 131072
```

Swagger는 `/docs`. 기존 requirements와 main.py는 변경하지 않는다.
기본70 모델 평가: 원본 140개 91.4%, 합성 손 가림 85.7~92.1%. 실제 앉은 웹캠 정확도는 별도 검증 대상이다.

## 2026-10-28 기본70 적용 사항

- 현재 과정은 7챕터·70단어다. 확장 단어/챕터 요청은 404 또는 422로 거절한다.
- 모델은 `curriculum70_seated_v3`, 좌우 반전 예측 결합과 검증셋 온도 보정을 적용한다.
- 단어당 학습 인물 REAL01/02/03 시범 3개 중 비교 가능한 시범·좌우 반전 상태를 선택한다.
- `feedback.reference`에는 `subject`, `video_url`, `mirrored`가 있다. 새로운 영상 경로는
  `/api/v1/signs/reference/{word_id}/{subject}`이며 subject는 REAL01~03만 허용한다.
- 시범 variant를 Spring에서 사용하려면 위 URL 중계 경로를 별도로 추가해야 한다. 이 브랜치에는 Spring 변경을 포함하지 않는다.
- 클라이언트는 message·actions·feedback_required와 참고용 비교 점수를 함께 표시할 수 있다. 화면 변경은 이번 이식 범위에 포함하지 않는다.
  비교 점수를 측정할 수 없으면 0점 대신 측정 불가로 표시한다.
- 비교한 시범을 재생하는 화면을 구현할 때는 `mirrored`가 참이면 표시를 좌우 반전한다.
  이 반전은 시범 영상 표시용이며 사용자 녹화 입력은 반전하지 않는다.
- 손의 몸 중심 거리 차이가 안정적으로 관측되면 안쪽/바깥쪽 위치 교정을 안내한다.
- WebM의 잘못된 총 프레임 메타데이터로 짧은 영상이 길이 초과로 거절되지 않게 했다.
  실제 디코딩 프레임 수에 대한 20초 상한은 유지한다.
- 기존의 70점 이하 필수 피드백과 검출 부족 재촬영 안내는 유지한다.
- 실제 사용자 웹캠 정확도, 로그인·DB 이력 저장 및 브라우저별 녹화는 별도 운영 검증 대상이다.

상세 결과는 [BASIC70_UPDATE.md](BASIC70_UPDATE.md)를 참고한다.
