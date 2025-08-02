# Traefik 문제 해결 가이드

## 대시보드 인증 설정 (해결됨)

### 해결 방법: File Provider 사용
Docker 라벨 방식 대신 File Provider를 사용하여 인증 문제를 해결했습니다.

1. **config/dynamic.yml 파일 생성**
   - 라우터와 미들웨어 정의
   - Basic Auth 사용자 설정

2. **docker-compose.yml 설정**
   - File Provider 추가: `--providers.file.directory=/config`
   - `--api.insecure=false` (기본값)
   - 8080 포트 노출 불필요

3. **접속 정보**
   - URL: http://traefik.local/dashboard/
   - 인증: admin / traefik123

### 일반적인 문제

1. **traefik.local 접속 불가**
   - /etc/hosts에 `127.0.0.1 traefik.local` 추가
   - DNS 캐시 정리: `sudo systemctl restart systemd-resolved`

2. **인증 팝업이 나타나지 않음**
   - `--api.insecure=true`가 활성화되어 있는지 확인
   - 이 옵션이 활성화되면 모든 인증이 우회됨

3. **비밀번호가 작동하지 않음**
   - .env 파일의 DASHBOARD_AUTH에서 $ 문자가 $$로 이스케이프되었는지 확인
   - htpasswd 형식이 올바른지 확인

### 디버깅 명령어

```bash
# 로그 확인
docker logs traefik

# 라우터 상태 확인
curl http://localhost/api/http/routers

# 컨테이너 상태
docker ps

# 포트 확인
ss -tln | grep -E "(80|443)"
```