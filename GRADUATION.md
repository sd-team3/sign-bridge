# SignBridge 졸업작품 실행 및 배포

## 현장 실행

1. 실행 폴더를 전시 PC의 로컬 디스크에 복사합니다. Docker Desktop을 실행하고 Linux 컨테이너 모드를 확인합니다.
2. 오프라인 실행본에서는 `images/signbridge-graduation-images.tar`를 실행 폴더 안에 둔 상태로 `run-graduation.bat`을 실행합니다. 첫 실행은 약 3GB의 이미지와 초기 데이터를 불러옵니다. 본 저장소에서 시작하면 스크립트가 온라인으로 이미지를 빌드합니다.
3. Chrome 또는 Edge에서 [SignBridge](http://localhost:8080/)를 열고 카메라를 허용합니다. 시작 전에 한 번 로그인하고 '커피' 동작 테스트를 합니다.

| 역할 | 이메일 | 전시용 비밀번호 |
| --- | --- | --- |
| 발표자 | `demo@signbridge.test` | `SignBridgeDemo!26` |
| 끝말잇기 두 번째 참가자 | `player@signbridge.test` | 같은 비밀번호 |
| 관리자 | `admin@signbridge.test` | 같은 비밀번호 |

- 실행 상태는 `docker compose -f docker-compose.graduation.yml ps`로 확인합니다. 포트 8080과 8000을 사용하는 다른 실행본이 있으면 먼저 종료합니다.
- 종료 명령은 `docker compose -f docker-compose.graduation.yml down`입니다. 학습 및 시험 기록은 이 구성의 볼륨에 남습니다.
- 지문자 코칭, 챕터 학습, 단어 시험, 내장 단어로 하는 끝말잇기를 로컬에서 시연할 수 있습니다. 브라우저 로컬 모델도 포함되어 있습니다. 한국수어사전 외부 원본 영상, 소셜 로그인과 외부 사전 API에는 인터넷이 필요합니다.

## 외부 관람객용 배포 후보

| 플랫폼 | 추천 상황 | 준비 사항 |
| --- | --- | --- |
| AWS Lightsail | 공개 URL이 필요하고 기존 Compose 구성으로 운영할 때 | Linux x86_64 8GB를 초기 후보로 검토합니다. 공개 IPv4 기준 월 $44 표기이며, 리전과 사용량에 따라 청구 조건이 달라질 수 있습니다. HTTPS 프록시, DB 백업, 서버 업데이트는 운영자가 맡습니다. |
| Railway | 서비스를 개별 컨테이너로 운영하고 웹 UI에서 배포·로그를 관리할 때 | Hobby 월 $5부터이며 리소스 초과분이 추가됩니다. Spring만 공개하고 FastAPI·MySQL·검색은 사설 네트워크로 연결합니다. DB와 검색용 볼륨 및 이미지 크기를 확인합니다. |
| 로컬 Docker Desktop | 학교 전시 및 심사장 | 기존 시연 흐름을 인터넷 없이 재현할 수 있습니다. 다른 장소의 사용자는 실행본을 받아 Docker Desktop을 설치해야 합니다. |

- [AWS Lightsail 요금](https://aws.amazon.com/lightsail/pricing/)
- [Railway Docker 배포 및 요금](https://railway.com/guides/deploy-scale-docker-containers-railway)
- [Railway 볼륨](https://docs.railway.com/volumes/reference)

로컬 준비 상태에서 네 컨테이너가 약 3.8GiB를 사용했습니다. 공개 환경에서는 8GB를 시작점으로 잡고 학습과 시험 영상이 동시에 들어올 때의 메모리와 응답 시간을 측정합니다.

## 공개 URL 적용 전

- 전시용 시드의 관리자와 공용 시연 계정을 제거하거나 비밀번호를 교체합니다. DB 설정을 배포 플랫폼의 비밀값으로 전환하고 새 볼륨에 승인된 공개용 데이터만 넣습니다.
- HTTPS를 설정하고 Spring만 외부에 연결합니다. 카메라 모듈, 모델 및 지문자 인식은 Spring의 동일 출처 경로를 통해 접근합니다. Python의 도구 화면과 수집·학습 API, MySQL, Elasticsearch는 내부에 둡니다.
- 소셜 로그인을 제공한다면 선택한 도메인의 콜백 주소를 등록합니다. 참조 영상과 모델 자산의 공개 재배포 범위를 확인합니다.
- 외부 주소에서 HTTPS, 카메라 권한, 연습 업로드, 아바타 결과, 시험 저장, 끝말잇기 WebSocket, 볼륨 복원을 점검합니다.
