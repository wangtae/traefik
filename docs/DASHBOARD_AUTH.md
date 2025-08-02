# Traefik 대시보드 인증 설정 가이드

## 문제 해결

### 1. 인증이 작동하지 않는 경우

`--api.insecure=true` 옵션이 활성화되어 있으면 인증이 우회됩니다.
이 옵션을 비활성화해야 Basic Auth가 작동합니다.

### 2. 대시보드 접속 설정

1. **/etc/hosts 파일 수정** (또는 Windows의 경우 C:\Windows\System32\drivers\etc\hosts)
   ```
   127.0.0.1 traefik.local
   ```

2. **브라우저에서 접속**
   - URL: http://traefik.local
   - 인증 팝업이 나타나면 admin / traefik 입력

### 3. 비밀번호 변경 방법

1. **새 비밀번호 생성**
   ```bash
   # htpasswd가 설치되어 있는 경우
   echo $(htpasswd -nb admin 새비밀번호) | sed -e s/\\$/\\$\\$/g
   
   # htpasswd가 없는 경우 (Docker 사용)
   docker run --rm httpd:alpine htpasswd -nb admin 새비밀번호 | sed -e s/\\$/\\$\\$/g
   ```

2. **.env 파일 수정**
   ```
   DASHBOARD_AUTH=생성된_해시값
   ```

3. **Traefik 재시작**
   ```bash
   make restart
   ```

### 4. 추가 보안 설정

운영 환경에서는 다음을 고려하세요:

1. **HTTPS 사용**
   ```yaml
   - "traefik.http.routers.dashboard.tls=true"
   - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
   ```

2. **IP 제한**
   ```yaml
   - "traefik.http.middlewares.dashboard-ipwhitelist.ipwhitelist.sourcerange=192.168.1.0/24"
   - "traefik.http.routers.dashboard.middlewares=dashboard-auth,dashboard-ipwhitelist"
   ```

3. **대시보드 완전 비활성화**
   ```yaml
   - "--api.dashboard=false"
   ```

## 참고사항

- Traefik의 Basic Auth는 웹 인터페이스에서 직접 비밀번호를 변경하는 기능을 제공하지 않습니다.
- 비밀번호 변경은 위의 방법으로 .env 파일을 수정해야 합니다.
- 더 고급 인증이 필요한 경우 OAuth2 프록시나 ForwardAuth 미들웨어 사용을 고려하세요.