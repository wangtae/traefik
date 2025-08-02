# Traefik 대시보드 인증 설정 해결 방안

## 해결 완료
- File Provider 방식을 사용하여 대시보드 인증 설정 성공
- 대시보드 접근 URL: http://traefik.local/dashboard/
- 인증 정보: admin / traefik123

## 문제 해결 방법

### 1단계: 기본 설정으로 작동 확인

먼저 `--api.insecure=true`로 대시보드가 작동하는지 확인:

```yaml
command:
  - "--api.dashboard=true"
  - "--api.insecure=true"  # 먼저 이것으로 작동 확인
  
ports:
  - "8080:8080"  # API 포트 열기
```

접속: http://localhost:8080

### 2단계: 인증 있는 대시보드 설정 (권장)

작동이 확인되면 인증을 추가:

#### 방법 1: External File Provider 사용 (권장)

1. `config/dynamic.yml` 파일 생성:
```yaml
http:
  routers:
    dashboard:
      rule: Host(`traefik.local`)
      service: api@internal
      entryPoints:
        - web
      middlewares:
        - auth
  
  middlewares:
    auth:
      basicAuth:
        users:
          - "admin:$$apr1$$Wf/r5xg9$$nXDpu17UvG4q.Q33JAswT."
```

2. docker-compose.yml에 파일 프로바이더 추가:
```yaml
command:
  - "--providers.file.directory=/config"
  - "--providers.file.watch=true"
volumes:
  - ./config:/config:ro
```

#### 방법 2: Docker 라벨 사용 (현재 시도한 방법)

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.dashboard.rule=Host(`traefik.local`)"
  - "traefik.http.routers.dashboard.service=api@internal"
  - "traefik.http.routers.dashboard.entrypoints=web"
  - "traefik.http.routers.dashboard.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=${DASHBOARD_AUTH}"
```

### 3단계: 문제 해결 체크리스트

1. **포트 확인**
   ```bash
   # WSL2에서 포트 확인
   ss -tln | grep -E "(80|443|8080)"
   ```

2. **도메인 설정**
   - /etc/hosts에 `127.0.0.1 traefik.local` 추가
   - 또는 localhost 직접 사용

3. **로그 확인**
   ```bash
   docker logs traefik
   docker exec traefik cat /logs/traefik.log
   ```

4. **네트워크 확인**
   ```bash
   docker network inspect docker-network
   ```

### 4단계: WSL2 특수 상황

WSL2에서 네트워크 문제가 있을 경우:

1. **Windows 방화벽 확인**
   - Windows Defender 방화벽에서 Docker Desktop 허용

2. **WSL2 네트워크 재시작**
   ```bash
   # WSL2 재시작
   wsl --shutdown
   # 다시 시작 후 Docker 서비스 확인
   ```

3. **localhost 대신 WSL2 IP 사용**
   ```bash
   # WSL2 IP 확인
   ip addr show eth0 | grep inet
   ```

## 권장 설정

### 개발 환경
- `--api.insecure=true` 사용
- localhost:8080으로 직접 접속

### 운영 환경
- External File Provider로 인증 설정
- HTTPS 사용 (Let's Encrypt)
- IP 화이트리스트 추가

## 최종 작동 설정

### 1. File Provider 설정 (config/dynamic.yml)
```yaml
http:
  routers:
    dashboard:
      rule: "Host(`traefik.local`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
      service: api@internal
      entryPoints:
        - web
      middlewares:
        - auth
  
  middlewares:
    auth:
      basicAuth:
        users:
          # 주의: YAML 파일에서는 단일 $ 사용
          - "admin:$apr1$pIIuJGs2$Ki.Bhl.dNz1XPvB54noGJ1"
```

### 2. Docker Compose 설정
- File Provider 추가: `--providers.file.directory=/config`
- `--api.insecure=false` (기본값이므로 생략 가능)
- 8080 포트 노출 불필요

### 3. 접속 정보
- URL: http://traefik.local/dashboard/
- 인증: admin / traefik123

### 주의사항
- YAML 파일에서는 단일 `$` 사용 (Docker 환경변수는 `$$` 사용)
- /etc/hosts에 `127.0.0.1 traefik.local` 추가 필요