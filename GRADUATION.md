# SignBridge 현재 브랜치 실행

기본 실행은 Spring/Tomcat, FastAPI, MySQL, Elasticsearch를 함께 시작합니다. 단어 70개·7개 챕터, 지문자 31개, 자동 녹화, 코칭·아바타 비교, 시험·사전·게시판·끝말잇기는 배포 실행본과 같은 소스와 모델을 사용합니다.

## 운영 노트북에서 처음 전환

1. Git 저장소를 노트북의 별도 폴더에 체크아웃하고 `dev-배포버전` 브랜치를 선택합니다. 기존 `C:\SignBridge-Laptop` 실행 폴더도 둡니다.
2. Docker Desktop을 실행한 상태로 저장소 폴더의 `run-graduation.bat` 또는 `dev-up.bat`을 실행합니다.
3. 저장소에 `.env`가 없으면 `C:\SignBridge-Laptop\.env`의 현재 키와 공개 주소를 가져오고 기존 Compose 프로젝트 이름 및 데이터 볼륨 5개를 확인합니다. 해당 볼륨에 있는 회원·비밀번호·시험·게시글·업로드·모델 데이터를 이어 사용합니다.
4. 현재 체크아웃 소스를 빌드한 다음 같은 프로젝트의 컨테이너를 교체합니다. 기존 서버를 먼저 종료했다면 데이터 볼륨을 남긴 상태에서 실행하세요.
5. Caddy가 기존과 같이 `127.0.0.1:8080`을 바라보면 공개 주소도 그대로 사용합니다. Funnel을 사용하는 환경도 같은 포트에 연결합니다.

이미 저장소에 `.env`가 있거나 이전 실행 폴더가 다른 경우에는 PowerShell에서 이전 폴더를 명시하세요.

```powershell
.\Start-SignBridge.ps1 -ImportFrom 'C:\SignBridge-Laptop'
```

기존 저장소 `.env`는 날짜가 붙은 로컬 백업으로 보관한 후 이전 배포 환경을 가져옵니다. API 키는 Git에 포함되지 않습니다.

## 이후 소스 수정 및 실행

`run-graduation.bat`과 `dev-up.bat`은 매번 현재 소스로 이미지를 빌드하고 준비 상태까지 기다립니다. Docker 빌드 캐시가 적용됩니다. `build.bat`은 빌드까지만 수행합니다. Compose를 직접 실행할 때는 `docker compose up -d --build --wait`를 사용합니다. `docker-compose.dev.yml`과 `docker-compose.graduation.yml`도 기본 구성 파일을 포함합니다.

새 PC에서 처음 시작하면 `.env.example`로 로컬 설정이 만들어집니다. 공개 운영에서는 아래 값과 각 제공자의 클라이언트 ID·Secret을 `.env`에서 설정하세요.

```dotenv
SIGNBRIDGE_PUBLIC_URL=https://signbridge.kro.kr
```

실행 스크립트는 주소 끝의 슬래시를 제거한 후 Google·Naver·Kakao 콜백 주소를 구성합니다. 각 제공자에 등록할 주소는 `공개주소/oauth2/google/callback`, `공개주소/oauth2/naver/callback`, `공개주소/oauth2/kakao/callback`입니다. Caddy 직접 연결로 운영할 때는 Tailscale용 이전 Publish 스크립트 대신 이 저장소의 실행 스크립트를 사용합니다.

## 운영 상태와 종료

```powershell
docker compose ps
docker compose logs --tail 80
docker compose down
```

볼륨은 일반 종료 후에도 유지됩니다. 운영 데이터가 있는 서버에서는 `down -v`를 실행하면 데이터가 삭제됩니다.

기존 노트북의 운영 DB는 이전 배포에서 설정한 계정·비밀번호를 그대로 사용합니다. 새로운 볼륨에는 `db/init`의 시연 데이터를 초기화합니다. 학습 모델은 `python-server/sign_api/assets`, 지문자 모델은 `python-server/model`에 포함되어 있습니다.

## 확인할 흐름

외부 네트워크에서 공개 HTTPS 주소로 로그인 → 챕터별 커피 자동 녹화·아바타 → 지문자 → 단어 시험 제출·기록 → 사전 → 게시판 검색 → 두 계정 끝말잇기를 확인합니다. 실제 소셜 로그인은 제공자에 등록한 공개 주소와 현재 `.env` 키를 사용합니다. 국어사전 검증은 `KRDICT_API_KEY`가 유효해야 합니다.
