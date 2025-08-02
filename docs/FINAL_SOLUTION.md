# Traefik 대시보드 인증 최종 해결 방안

## 작동 확인된 설정

### docker-compose-auth.yml
```yaml
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "8080:8080"  # 디버깅용 (운영에서는 제거)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"  # 디버깅용 (운영에서는 false)
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.traefik.address=:8080"
      - "--log.level=INFO"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`traefik.local`)"
      - "traefik.http.routers.api.service=api@internal"
      - "traefik.http.routers.api.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$pIIuJGs2$$Ki.Bhl.dNz1XPvB54noGJ1"

networks:
  default:
    name: traefik
```

## 접속 방법

1. **디버깅 모드 (insecure)**
   - URL: http://localhost:8080/dashboard/
   - 인증: 불필요

2. **보안 모드**
   - URL: http://traefik.local/dashboard/
   - 인증: admin / traefik123

## 주요 포인트

1. **Docker 라벨 방식 사용**
   - File Provider보다 간단하고 직관적
   - Kubernetes 환경으로 전환 시 유리

2. **비밀번호 해시 이스케이프**
   - Docker Compose에서는 `$$` 사용
   - `htpasswd` 명령으로 생성한 해시값의 `$`를 `$$`로 변경

3. **운영 환경 설정**
   - `--api.insecure=false`로 변경
   - 8080 포트 제거
   - HTTPS 추가 권장

## 문제 해결 과정

1. 초기 문제: `--api.insecure=false` 시 Traefik이 응답하지 않음
2. 시도한 방법: File Provider, Docker 라벨, 환경변수
3. 최종 해결: Docker 라벨 + 하드코딩된 인증 정보

## 운영 권장사항

```yaml
# 운영 환경용 설정
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    environment:
      - DASHBOARD_AUTH=${DASHBOARD_AUTH}  # .env 파일에서 관리
    command:
      - "--api.dashboard=true"
      # --api.insecure는 제거 (기본값 false)
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      # HTTPS 리다이렉트 추가
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`traefik.yourdomain.com`)"
      - "traefik.http.routers.api.service=api@internal"
      - "traefik.http.routers.api.middlewares=auth"
      - "traefik.http.routers.api.tls=true"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      - "traefik.http.middlewares.auth.basicauth.users=${DASHBOARD_AUTH}"
```

## 비밀번호 생성 방법

```bash
# htpasswd 명령으로 비밀번호 생성
docker run --rm httpd:2.4-alpine htpasswd -nb admin your-password

# 생성된 해시에서 $ 를 $$ 로 변경하여 사용
# 예: $apr1$xxx -> $$apr1$$xxx
```