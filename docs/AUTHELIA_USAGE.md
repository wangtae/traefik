# Authelia 사용 가이드

## 현재 설정 완료!

Authelia가 성공적으로 설정되었습니다. 이제 웹 기반 로그인을 사용할 수 있습니다.

## 접속 방법

1. **Traefik 대시보드 접속**
   - URL: http://localhost/dashboard/
   - 자동으로 Authelia 로그인 페이지로 리다이렉트됩니다

2. **로그인 정보**
   - 사용자명: `admin`
   - 비밀번호: `traefik123`

## 작동 원리

```
사용자 → Traefik → Authelia 미들웨어 → 인증 확인
                          ↓
                    인증 안됨 → Authelia 로그인 페이지
                          ↓
                    로그인 성공 → 원래 페이지로 리다이렉트
```

## 주요 기능

1. **웹 로그인 화면**
   - 깔끔한 UI
   - Remember Me 기능
   - 세션 관리

2. **보안 기능**
   - bcrypt 암호화
   - 세션 타임아웃 (5분 비활성)
   - 세션 만료 (1시간)

3. **사용자 관리**
   - `/authelia/users_database.yml` 파일 수정
   - 비밀번호 생성: `docker run --rm authelia/authelia:4.37 authelia hash-password 'your-password'`

## 문제 해결

### 로그인이 안 되는 경우
1. 브라우저 쿠키 삭제
2. 시크릿 모드로 재시도
3. 로그 확인: `docker logs authelia`

### 세션이 자꾸 끊기는 경우
- configuration.yml에서 세션 시간 조정
- `expiration: 3600` (초 단위)
- `inactivity: 300` (초 단위)

## 다음 단계

1. **HTTPS 설정**
   - Let's Encrypt 인증서 추가
   - 보안 강화

2. **2FA 활성화**
   - TOTP 설정
   - 모바일 앱 연동

3. **사용자 추가**
   - users_database.yml 수정
   - 그룹별 권한 설정