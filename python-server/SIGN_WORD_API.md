# 100단어 수어 학습 API — Spring 연동 명세

페이지 구현 순서는 [수어 학습 페이지 구현 도움집](SIGN_LEARNING_PAGE_GUIDE.md)을 참고하세요.

적용 모델: `curriculum100_seated_active_v2`, 입력 정책 `seated_active_v2`.
기본 7챕터 70단어 + 확장 3챕터 30단어이며 현재 모델은 전체 100단어를 지원한다.
챕터는 기존 2026-10-13 선정 목록의 단원 구성을 사용한다.
기존 지문자 `/predict`, `/coach`, `/health`와 Spring 소스는 변경하지 않는다.

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
| GET | `/api/v1/signs/health` | 모델 준비, 100클래스·100비교 좌표·10챕터 확인 |
| GET | `/api/v1/signs/chapters` | 챕터 요약 목록 |
| GET | `/api/v1/signs/chapters/{chapter_id}` | 챕터 상세와 순서가 있는 단어 목록 |
| GET | `/api/v1/signs/words/{word_id}` | 단어 상세·모범 영상·평가 URL·촬영 조건 |
| GET | `/api/v1/signs` | 기존 전체 단어 목록; 기존 필드는 유지하고 메타데이터 추가 |
| GET | `/api/v1/signs/reference/{word_id}` | 모범 MP4 영상, Range 지원 |
| POST | `/api/v1/signs/evaluate-video` | 녹화 영상 업로드 후 단어 인식·자세 피드백 |
| POST | `/api/v1/signs/evaluate` | 좌표 JSON으로 단어 인식·자세 피드백 |
| POST | `/api/v1/signs/predict` | 좌표 JSON으로 단어 분류 |
| WebSocket | `/api/v1/signs/practice` | 좌표 수집·검출 상태 안내·동작 완료 후 평가 |

`chapter_id`: `chapter-01`~`chapter-10`, `word_id`: `WORD` + 4자리 코드.
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

## 평가 응답 해석

- `attempt_id`, `target_word_id`, `model_id`, `input_policy`로 시도·목표·모델을 식별한다.
- `status: ok`: 추론 완료. `recognition.top3`, `predicted_label`, `target_matches_top1` 제공.
- `status: retry`: 동작 손 또는 어깨 검출 부족. `recognition: null`이므로 오답으로 집계하지 않는다.
- `quality`: 검출 프레임 수, `active_hand_frames`, `excluded_resting_slots` 등.
  제외 슬롯은 MediaPipe 슬롯 번호 0/1이며 해부학적 왼손/오른손 번호가 아니다.
- `recognition.top3[].score`: 분류 softmax 값. 자세 정확도나 숙련도 백분율이 아니다.
- `feedback.status: advice`: 모범 동작과 비교해 일관된 손 높이·손가락 각도 차이가 관측됨.
- `no_reliable_correction`: 신뢰할 교정이 없거나 비교 근거 부족. 합격·완벽한 자세를 뜻하지 않는다.
- `reference_unavailable`: 비교 기준 없음. 정상 100단어 패키지는 모든 단어의 기준을 포함한다.
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
모델 평가: 원본 200개 85%, 합성 손 가림 76.5~83%. 실제 앉은 웹캠 정확도는 별도 검증 대상이다.
