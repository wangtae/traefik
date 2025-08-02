# Let's Encrypt SSL 인증서 자동 발급 가이드

## Cloudflare DNS Challenge 설정

Traefik은 Cloudflare DNS Challenge를 통해 Let's Encrypt SSL 인증서를 자동으로 발급하고 갱신합니다.

### 1. Cloudflare API 토큰 발급

#### 방법 1: Global API Key 사용 (간단하지만 권한이 넓음)
1. [Cloudflare Dashboard](https://dash.cloudflare.com) 로그인
2. My Profile → API Tokens
3. Global API Key 확인
4. `.env.prod`에 설정:
   ```env
   CF_API_EMAIL=your-email@example.com
   CF_API_KEY=your_global_api_key_here
   ```

#### 방법 2: API Token 사용 (권장 - 최소 권한)
1. [Cloudflare Dashboard](https://dash.cloudflare.com) → My Profile → API Tokens
2. "Create Token" 클릭
3. "Edit zone DNS" 템플릿 선택
4. 권한 설정:
   - Zone:DNS:Edit
   - Zone:Zone:Read
5. Zone Resources: 특정 도메인 또는 All zones
6. 토큰 생성 후 `.env.prod`에 설정:
   ```env
   CF_DNS_API_TOKEN=your_api_token_here
   ```

### 2. 도메인별 인증서 발급 예시

#### 예시 1: 단일 도메인 (example.com)
```yaml
# your-app/docker-compose.yml
services:
  web:
    image: nginx:alpine
    labels:
      - "traefik.enable=true"
      
      # HTTP 라우터
      - "traefik.http.routers.web.rule=Host(`example.com`)"
      - "traefik.http.routers.web.entrypoints=web"
      - "traefik.http.routers.web.middlewares=redirect-to-https"
      
      # HTTPS 라우터
      - "traefik.http.routers.web-secure.rule=Host(`example.com`)"
      - "traefik.http.routers.web-secure.entrypoints=websecure"
      - "traefik.http.routers.web-secure.tls=true"
      - "traefik.http.routers.web-secure.tls.certresolver=letsencrypt"
      
      # HTTP → HTTPS 리다이렉트 미들웨어
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.permanent=true"
    networks:
      - docker-network

networks:
  docker-network:
    external: true
```

#### 예시 2: 와일드카드 인증서 (*.example.com)
```yaml
services:
  web:
    image: nginx:alpine
    labels:
      - "traefik.enable=true"
      
      # 서브도메인 라우팅
      - "traefik.http.routers.web-secure.rule=Host(`app.example.com`)"
      - "traefik.http.routers.web-secure.entrypoints=websecure"
      - "traefik.http.routers.web-secure.tls=true"
      - "traefik.http.routers.web-secure.tls.certresolver=letsencrypt"
      
      # 와일드카드 인증서 도메인 지정
      - "traefik.http.routers.web-secure.tls.domains[0].main=example.com"
      - "traefik.http.routers.web-secure.tls.domains[0].sans=*.example.com"
    networks:
      - docker-network
```

#### 예시 3: 여러 도메인 (example.com, example.org)
```yaml
services:
  web:
    image: nginx:alpine
    labels:
      - "traefik.enable=true"
      
      # 여러 도메인 라우팅
      - "traefik.http.routers.web-secure.rule=Host(`example.com`) || Host(`example.org`)"
      - "traefik.http.routers.web-secure.entrypoints=websecure"
      - "traefik.http.routers.web-secure.tls=true"
      - "traefik.http.routers.web-secure.tls.certresolver=letsencrypt"
      
      # 각 도메인별 인증서
      - "traefik.http.routers.web-secure.tls.domains[0].main=example.com"
      - "traefik.http.routers.web-secure.tls.domains[0].sans=www.example.com"
      - "traefik.http.routers.web-secure.tls.domains[1].main=example.org"
      - "traefik.http.routers.web-secure.tls.domains[1].sans=www.example.org"
    networks:
      - docker-network
```

### 3. 실제 배포 프로세스

1. **환경 변수 설정**
   ```bash
   # Cloudflare API 정보 입력
   nano .env.prod
   # CF_API_EMAIL과 CF_API_KEY 또는 CF_DNS_API_TOKEN 설정
   
   # 환경 변수 암호화
   make encrypt ENV=prod
   ```

2. **운영 환경 활성화**
   ```bash
   make use-prod
   make restart
   ```

3. **인증서 발급 확인**
   ```bash
   # 로그 확인
   make logs
   
   # 인증서 상태 확인
   make certs
   
   # acme.json 파일 확인
   ls -la letsencrypt/acme.json
   ```

### 4. 테스트 및 디버깅

#### 일반적인 문제 해결

1. **DNS 전파 대기**
   - 새 도메인의 경우 DNS가 전파될 때까지 기다려야 함
   - `nslookup yourdomain.com 1.1.1.1`로 확인

2. **Cloudflare 프록시 설정**
   - DNS Challenge는 Cloudflare 프록시 ON/OFF 상관없이 작동
   - HTTP Challenge를 사용하는 경우 프록시 OFF 필요

3. **인증서 갱신**
   - Traefik이 자동으로 처리 (만료 30일 전)
   - 수동 갱신: 컨테이너 재시작

### 5. 보안 권장사항

1. **API Token 사용**
   - Global API Key 대신 최소 권한의 API Token 사용
   
2. **환경 변수 암호화**
   - GPG로 암호화하여 Git에 저장
   - 절대 평문으로 커밋하지 않음

3. **Rate Limit 주의**
   - 운영 환경: 도메인당 주 50개 인증서 제한
   - 테스트는 스테이징 서버 사용

### 6. 고급 설정

#### DNS 프로바이더 변경
다른 DNS 프로바이더 사용 시:
- Route53: `provider: route53`
- Google Cloud DNS: `provider: gcloud`
- Azure DNS: `provider: azure`

각 프로바이더별 환경 변수는 [Traefik 문서](https://doc.traefik.io/traefik/https/acme/#providers) 참고

#### 인증서 백업
```bash
# acme.json 백업 (중요!)
cp letsencrypt/acme.json backups/acme-$(date +%Y%m%d).json

# 권한 설정 (필수)
chmod 600 letsencrypt/acme.json
```