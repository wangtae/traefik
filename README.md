# Traefik 리버스 프록시

Traefik을 사용한 중앙 집중식 리버스 프록시 시스템입니다.

## 특징

- 🚀 Docker 라벨 기반 자동 서비스 디스커버리
- 🔒 Let's Encrypt를 통한 자동 SSL 인증서 관리
- 📊 실시간 대시보드
- 🔄 HTTP → HTTPS 자동 리다이렉트
- 📝 JSON 형식 로깅
- 🐳 Docker Compose 기반 간편한 관리

## 빠른 시작

### 1. 사전 요구사항

- Docker 및 Docker Compose 설치
- 80, 443 포트가 사용 가능해야 함
- GPG 설치 (환경 변수 암호화용)
- Make 설치 (자동화 명령어용)

### 2. 설치

```bash
# 프로젝트 클론
git clone https://github.com/wangtae/traefik.git
cd traefik

# 환경 초기화 (네트워크 생성, .env 복호화)
make init

# 필요시 .env 파일 수정
nano .env

# Traefik 시작
make up

# 로그 확인
make logs
```

### 3. 대시보드 접속

- URL: http://traefik.local:8080/dashboard/
- 계정: wangtae@gmail.com / !wangtae@gmail.com@.
- 주의: 브라우저에서 Basic 인증 팝업이 나타납니다

**중요**: 
1. /etc/hosts에 다음 항목 추가 필요
   ```
   127.0.0.1 traefik.local
   ```
2. 포트가 8080으로 변경됨 (호스트 nginx와 충돌 방지)

## 프로젝트 연동 방법

### Docker Compose 설정

프로젝트의 `docker-compose.yml`에 다음과 같이 설정합니다:

```yaml
version: '3.8'

services:
  your-app:
    image: your-app:latest
    labels:
      # Traefik 활성화
      - "traefik.enable=true"
      
      # 라우터 설정
      - "traefik.http.routers.your-app.rule=Host(`your-app.local`)"
      - "traefik.http.routers.your-app.entrypoints=websecure"
      - "traefik.http.routers.your-app.tls=true"
      
      # 서비스 설정 (내부 포트 지정)
      - "traefik.http.services.your-app.loadbalancer.server.port=80"
    networks:
      - docker-network
      - internal

networks:
  docker-network:
    external: true
  internal:
    # 내부 서비스 간 통신용
```

### 실제 도메인 사용 시

실제 도메인으로 SSL 인증서를 받으려면:

1. `.env` 파일 수정:
   ```env
   ACME_EMAIL=your-email@example.com
   ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory
   ```

2. 라벨에 인증서 리졸버 추가:
   ```yaml
   - "traefik.http.routers.your-app.tls.certresolver=letsencrypt"
   ```

## 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| DOMAIN | 기본 도메인 | local |
| ACME_EMAIL | Let's Encrypt 이메일 (운영용) | wangtae@gmail.com |
| ACME_CA_SERVER | Let's Encrypt 서버 (운영용) | 운영 서버 |
| CF_API_EMAIL | Cloudflare 이메일 (운영용) | wangtae@gmail.com |
| CF_DNS_API_TOKEN | Cloudflare API 토큰 (운영용) | - |
| LOG_LEVEL | 로그 레벨 | INFO |
| TZ | 타임존 | Asia/Seoul |

**참고**: 대시보드 인증은 `traefik/dynamic/basicauth.yml`에서 관리됩니다.

## 파일 구조

```
traefik/
├── docker-compose.yml   # Traefik 설정
├── Makefile            # 자동화 명령어
├── .env                # 환경 변수 (Git 제외)
├── .env.gpg            # 암호화된 환경 변수
├── .env.example        # 환경 변수 예제
├── scripts/            # 유틸리티 스크립트
│   ├── encrypt-env.sh  # 환경 변수 암호화
│   └── decrypt-env.sh  # 환경 변수 복호화
├── traefik/            # Traefik 설정 파일
│   ├── traefik.yml    # 메인 설정
│   └── dynamic/       # 동적 설정
│       ├── basicauth.yml  # Basic 인증 설정
│       └── dashboard.yml  # 대시보드 라우팅
├── letsencrypt/        # SSL 인증서 저장
├── logs/               # 로그 파일
│   ├── traefik.log    # 시스템 로그
│   └── access.log     # 액세스 로그
├── backup/            # 이전 설정 백업
├── docs/              # 추가 문서
└── README.md          # 이 파일
```

## 유용한 명령어

### Makefile 명령어

```bash
# 도움말 표시
make help

# 기본 작업
make init       # 환경 초기화 (최초 설치 시)
make up         # Traefik 시작
make down       # Traefik 중지
make restart    # Traefik 재시작
make logs       # 로그 확인 (실시간)
make ps         # 컨테이너 상태 확인
make status     # 전체 상태 확인 (헬스체크, 인증서 등)

# 환경 설정 관리
make encrypt    # .env 파일 암호화 (GPG)
make decrypt    # .env.gpg 파일 복호화

# 유지보수
make update     # Docker 이미지 업데이트
make clean      # 로그 및 임시 파일 정리
make backup     # 설정 백업
make restore BACKUP_FILE=backups/backup-YYYYMMDD-HHMMSS.tar.gz  # 백업 복원
```

### Docker Compose 직접 명령어

```bash
# 상태 확인
docker compose ps

# 로그 확인
docker compose logs -f

# 설정 재로드 (재시작)
docker compose restart

# 정지
docker compose down

# 완전 제거 (볼륨 포함)
docker compose down -v
```

## 문제 해결

### 포트 충돌

80 또는 443 포트가 이미 사용 중인 경우:

```bash
# 포트 사용 확인
sudo lsof -i :80
sudo lsof -i :443

# nginx가 실행 중이라면
sudo systemctl stop nginx
```

### 인증서 문제

개발 환경에서 자체 서명 인증서 경고가 나타나는 것은 정상입니다.
실제 도메인 사용 시 Let's Encrypt 프로덕션 서버로 변경하세요.

### 대시보드 접속 불가

1. traefik.local을 /etc/hosts에 추가:
   ```
   127.0.0.1 traefik.local
   ```
2. 포트 8080으로 접속 (http://traefik.local:8080/)
3. `docker compose logs traefik`로 오류 확인
4. Basic 인증 자격 증명 확인

## SSL 인증서 자동 발급 (Let's Encrypt + Cloudflare)

Traefik은 Cloudflare DNS Challenge를 통해 Let's Encrypt SSL 인증서를 자동으로 발급하고 갱신합니다.

### 빠른 설정

1. **Cloudflare API Token 발급**
   - [Cloudflare Dashboard](https://dash.cloudflare.com) → API Tokens
   - "Edit zone DNS" 템플릿으로 토큰 생성

2. **환경 변수 설정**
   ```bash
   # .env.prod 편집
   CF_API_EMAIL=your-email@example.com
   CF_DNS_API_TOKEN=your_api_token_here
   ```

3. **프로젝트에 SSL 적용**
   ```yaml
   labels:
     - "traefik.http.routers.app-secure.rule=Host(`app.yourdomain.com`)"
     - "traefik.http.routers.app-secure.entrypoints=websecure"
     - "traefik.http.routers.app-secure.tls=true"
     - "traefik.http.routers.app-secure.tls.certresolver=letsencrypt"
   ```

자세한 설정은 [SSL 인증서 가이드](docs/ssl-certificate-example.md) 참고

## 보안 권장사항

1. **대시보드 비밀번호 변경**
   - `traefik/dynamic/basicauth.yml` 파일 편집
   - htpasswd 명령어로 새 해시 생성:
     ```bash
     docker run --rm httpd:2.4-alpine htpasswd -nb '사용자명' '비밀번호'
     ```

2. **운영 환경에서는 대시보드 비활성화 고려**
   ```yaml
   command:
     - "--api.dashboard=false"
   ```

3. **액세스 로그 주기적 정리**
   ```bash
   # logrotate 설정 추가 권장
   ```

4. **API 토큰 보안**
   - Cloudflare API 토큰은 최소 권한 원칙 적용
   - 환경 변수는 GPG로 암호화하여 저장

## 환경별 설정 관리

개발(dev)과 운영(prod) 환경을 분리하여 관리합니다.

### 환경 파일 구조
- `.env.dev` - 개발 환경 설정
- `.env.prod` - 운영 환경 설정  
- `secrets/` - GPG로 암호화된 환경 파일
- `.env` - 현재 활성화된 환경 (Git 제외)

### 환경 전환
```bash
# 개발 환경 사용
make use-dev

# 운영 환경 사용
make use-prod
```

## GPG를 통한 환경 변수 암호화

환경 파일은 민감한 정보를 포함하므로 GPG 대칭키 암호화로 Git에 안전하게 저장합니다.

### 비밀번호 기반 암호화 (단순화)

본 프로젝트는 GPG 키 생성 없이 **비밀번호만으로** 환경 파일을 암호화합니다.

**장점:**
- GPG 키 생성/관리 불필요
- 팀원과 비밀번호만 공유하면 됨
- 어느 환경에서도 복호화 가능

### 환경 변수 암호화/복호화

```bash
# 현재 환경 파일 암호화 (ENV=dev 또는 ENV=prod)
make encrypt ENV=dev
# 비밀번호 입력 프롬프트가 나타납니다

# 모든 환경 파일 한번에 암호화  
make encrypt-all
# 모든 파일에 동일한 비밀번호 사용

# 환경 파일 복호화
make decrypt ENV=dev
# 암호화 시 사용한 비밀번호 입력

# 직접 스크립트 사용
./scripts/encrypt-env.sh -f .env.dev -o secrets/.env.dev.gpg
./scripts/decrypt-env.sh -f secrets/.env.dev.gpg -o .env.dev
```

### 비밀번호 관리 권장사항

1. **강력한 비밀번호 사용**
   - 최소 12자 이상
   - 대/소문자, 숫자, 특수문자 혼합

2. **비밀번호 공유**
   - 안전한 채널로 팀원과 공유 (Signal, 1Password 등)
   - 절대 Git commit에 포함하지 말 것

3. **주기적 변경**
   - 팀원 변동 시 비밀번호 변경
   - 3-6개월마다 주기적 갱신

### 워크플로우

1. **새 환경에서 시작**
   ```bash
   git clone https://github.com/wangtae/traefik.git
   cd traefik
   make init  # 네트워크 생성 및 환경 설정
   make decrypt ENV=dev  # 개발 환경 복호화
   make use-dev  # 개발 환경 활성화
   make up  # Traefik 시작
   ```

2. **환경 변수 수정 후**
   ```bash
   # 환경 파일 수정
   nano .env.dev
   
   # 암호화
   make encrypt ENV=dev
   
   # Git에 커밋
   git add secrets/.env.dev.gpg
   git commit -m "Update encrypted dev environment"
   git push
   ```

## 참고 자료

- [Traefik 공식 문서](https://doc.traefik.io/traefik/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- [GNU Privacy Guard (GPG)](https://gnupg.org/)