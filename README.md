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

### 2. 설치

```bash
# 환경 설정 파일 복사
cp .env.example .env

# 필요시 .env 파일 수정
nano .env

# Docker 네트워크 생성 (최초 1회, 이미 있다면 생략)
docker network create docker-network

# Traefik 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

### 3. 대시보드 접속

- URL: https://traefik.local:8080
- 계정: admin / traefik (기본값)

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
| BASE_DOMAIN | 기본 도메인 | local |
| ACME_EMAIL | Let's Encrypt 이메일 | admin@example.com |
| ACME_CA_SERVER | Let's Encrypt 서버 | 스테이징 서버 |
| DASHBOARD_AUTH | 대시보드 인증 | admin:traefik |
| LOG_LEVEL | 로그 레벨 | INFO |

## 파일 구조

```
traefik/
├── docker-compose.yml   # Traefik 설정
├── .env                # 환경 변수
├── .env.example        # 환경 변수 예제
├── config/             # 정적 설정 (선택사항)
├── letsencrypt/        # SSL 인증서 저장
├── logs/               # 로그 파일
│   ├── traefik.log    # 시스템 로그
│   └── access.log     # 액세스 로그
└── README.md          # 이 파일
```

## 유용한 명령어

```bash
# 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f

# 설정 재로드 (재시작)
docker-compose restart

# 정지
docker-compose down

# 완전 제거 (볼륨 포함)
docker-compose down -v
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

1. 방화벽에서 8080 포트 허용 확인
2. `docker-compose logs traefik`로 오류 확인
3. traefik.local을 /etc/hosts에 추가:
   ```
   127.0.0.1 traefik.local
   ```

## 보안 권장사항

1. **대시보드 비밀번호 변경**
   ```bash
   # 새 비밀번호 생성
   echo $(htpasswd -nb admin 새비밀번호) | sed -e s/\\$/\\$\\$/g
   # .env 파일의 DASHBOARD_AUTH 업데이트
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

## 참고 자료

- [Traefik 공식 문서](https://doc.traefik.io/traefik/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Compose](https://docs.docker.com/compose/)