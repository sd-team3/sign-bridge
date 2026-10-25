# 수어 50단어 API 연동

## 설치와 실행

기존 `main:app`에 `sign_api` 라우터를 추가했습니다. 기존 지문자 `/predict`, `/coach`, `/health`는 유지됩니다.
모델은 서버 시작 시 프로세스당 한 번 CPU에 로드합니다. 모델 로딩 실패 시 수어 API는 503으로 응답하며 지문자 모델은 별개입니다.

```powershell
cd C:\sign-bridge\python-server
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --ws-max-size 131072
```

Docker 사용 시 Python 이미지를 재빌드해야 합니다. PyTorch 의존성을 추가했습니다. 기존 requirements의 다른 버전은 변경하지 않았으므로 기존 환경의 설치 호환성 문제는 별도로 확인하세요.

Swagger: `http://127.0.0.1:8000/docs`

## 엔드포인트

| 메서드 | 경로 | 역할 |
|---|---|---|
| GET | /api/v1/signs/health | 모델 준비 상태, 클래스/기준 좌표 개수 |
| GET | /api/v1/signs | 지원 WORD 코드와 한국어 라벨 |
| POST | /api/v1/signs/predict | 완료된 좌표 시퀀스의 단어 분류 |
| POST | /api/v1/signs/evaluate | 목표 단어 인식 + 기준 영상과 자세 비교 |
| WebSocket | /api/v1/signs/practice | 좌표 수집, 촬영 상태 안내, 완료 후 평가 |

**실시간 안내는 손/어깨 검출 상태입니다. 동작 단계별 실시간 자세 교정은 아직 지원하지 않습니다.**
분류 점수는 자세 정확도가 아닙니다. 기준 비교는 정면 학습 영상 1개/단어를 기반으로 하며 전문가 정답 판정이나 다양한 수어 변이의 우열을 판정하지 않습니다.

## HTTP 요청

```json
{
  "attempt_id": "attempt-001",
  "schema_version": "raw_mp_legacy_v1",
  "mirrored": false,
  "aspect": 1.7777778,
  "target_word_id": "WORD0115",
  "use_llm": false,
  "frames": [
    {"timestamp_ms": 0, "hands": [null, null], "pose": null}
  ]
}
```

위 frames는 구조 설명용으로, 실제 요청에는 16~300개 프레임이 필요합니다. 시각은 구간 시작 기준 0~20000ms, 엄격히 증가해야 합니다. 샘플링은 약 15fps를 시작점으로 사용하세요.

- `hands`: 길이 2. MediaPipe Hands가 반환한 **Left 슬롯, Right 슬롯** 순서. 각각 21행 `[x,y,z]`, 미검출은 null. 좌우 라벨을 해부학적 좌우로 임의 교체하지 마세요.
- `pose`: 33행 `[x,y,visibility]`. 세 번째 값은 **z가 아니라 visibility**입니다. 미검출은 null.
- `aspect`: 랜드마크를 추출한 원본 프레임의 가로/세로 비율.
- 미러링하지 않은 이미지 좌표를 전달하세요. 화면 표시만 CSS 반전해도 되지만 추출 입력은 반전하지 않습니다.
- 정규화하지 않은 좌표를 보냅니다. 서버가 학습 때와 같은 손목/어깨 기준 전처리를 합니다.
- 목표 단어는 `/evaluate`와 WS start에서 필수입니다. `/predict`에서는 선택입니다.
- 손 검출 프레임 또는 양어깨 유효 프레임이 16개 미만이면 `status: retry`, `recognition: null`로 반환합니다.

Python 학습 추출기는 MediaPipe 0.10.14의 legacy Hands(2 hands, complexity 1, detection/tracking .5), Pose(complexity 1, smooth_landmarks True, detection/tracking .5)를 사용합니다. 브라우저에서 다른 Tasks 모델을 사용하면 분포가 같다고 보장할 수 없습니다. 웹 추출기와 학습 추출기의 동등성 검증은 별도로 필요합니다.

## WebSocket 프로토콜

1. `{"type":"start","attempt_id":"a1","aspect":1.7777778,"target_word_id":"WORD0115","use_llm":false}`
2. `{"type":"frames","frames":[...]}`: 배치당 1~15개. 서버 tracking 응답을 받은 후 다음 배치를 전송하는 방식으로 역압을 적용하세요.
3. `{"type":"finish"}`: 전체 동작을 평가하고 result 반환. 성공 후 버퍼 해제.
4. `{"type":"reset"}`: 현재 시도 폐기.

`started`, `tracking`, `result`, `reset`, `error` 메시지로 응답합니다. 세션별 버퍼를 분리하며 최대 300프레임, 메시지 최대 128KiB, 무응답 30초 후 종료합니다. 429 발생 시 완료 요청을 나중에 다시 보내거나 reset하세요. 잘못된 start는 기존 세션을 리셋하므로 녹화 중 start를 반복하지 마세요.

## Spring 연결

기존 Python 서비스 주소(`python.server.url`) 뒤에 위 경로를 붙입니다. Spring은 인증된 사용자의 요청만 전달하고 attempt_id를 학습 이력과 연결하세요. 완료된 시퀀스는 RestClient/WebClient 등 기존 HTTP 클라이언트로 JSON POST하면 됩니다.

WebSocket은 Spring의 WS 핸들러에서 연결별로 Python WS 연결 하나를 만들고 텍스트 메시지를 중계합니다. 브라우저 연결 종료 시 Python 연결도 닫고, 다음 배치를 무제한 큐에 쌓지 마세요. HTTP 프록시만 만든다고 WebSocket이 자동 연결되지는 않습니다. 이번 이식은 Python 서버 범위이며 Spring 컨트롤러/웹 UI는 변경하지 않았습니다.

## 인증·배포·LLM

- `SIGN_API_KEY`를 서버 환경변수로 설정하면 새 수어 HTTP/WS API에 `X-Sign-Api-Key` 헤더가 필요합니다. Spring에서만 이 키를 전달하세요. 브라우저 JavaScript에 서비스 키를 넣지 마세요.
- 키가 없으면 개발용 무인증입니다. Python 포트를 인터넷에 직접 공개하지 말고 Spring/내부망 뒤에 두세요. 기존 지문자 API의 인증/CORS 정책은 이번 작업에서 변경하지 않았습니다.
- 프록시에서 HTTP body 제한(예: 5MiB), 인증, 연결 수/요청 빈도 제한과 TLS를 적용하세요. 추론 동시 실행은 프로세스당 1개이며 나머지는 429입니다. worker 증가 시 모델 메모리도 복제됩니다.
- Groq는 `use_llm: true`이고 확실한 교정 관측이 있는 경우에만 호출합니다. 서버 환경변수 `GROQ_API_KEY`, `GROQ_MODEL`이 필요합니다. 원본 영상/좌표 대신 계산된 교정 관측만 전달합니다.
- LLM 실패/미설정 시 규칙 문구를 사용합니다. Groq 응답은 자연어이며 의미 보존을 완전히 보증하지 않으므로 초기 검증에는 기본값 false를 권장합니다.
- 원본 영상과 사용자 좌표는 이 API가 디스크에 저장하지 않습니다. 운영 로그에 요청 본문을 기록하지 않도록 주의하세요.

## 검증 범위

API 입력 검증·인증·버퍼 분리·검출 부족·과부하 응답을 자동 테스트하고 실제 영상의 예측을 기존 로컬 실행 코드와 비교합니다. 브라우저/스프링 종단 간 연동과 실제 다중 사용자 부하는 별도 검증 대상입니다.
