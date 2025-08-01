#!/bin/bash
# GPG를 사용한 .env 파일 복호화 스크립트

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 기본값
GPG_FILE=".env.gpg"
ENV_FILE=".env"
FORCE=false

# 사용법 출력
usage() {
    echo "Usage: $0 [-f gpg_file] [-o output_file] [-F]"
    echo "  -f  GPG 파일 경로 (기본값: .env.gpg)"
    echo "  -o  출력 파일 경로 (기본값: .env)"
    echo "  -F  기존 파일 덮어쓰기"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  $0 -f .env.production.gpg -o .env.production"
    exit 1
}

# 옵션 파싱
while getopts "f:o:Fh" opt; do
    case $opt in
        f) GPG_FILE="$OPTARG" ;;
        o) ENV_FILE="$OPTARG" ;;
        F) FORCE=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# GPG 파일 존재 확인
if [ ! -f "$GPG_FILE" ]; then
    echo -e "${RED}Error: GPG 파일 '$GPG_FILE'을 찾을 수 없습니다${NC}"
    exit 1
fi

# 출력 파일이 이미 존재하는 경우
if [ -f "$ENV_FILE" ] && [ "$FORCE" = false ]; then
    echo -e "${YELLOW}경고: '$ENV_FILE' 파일이 이미 존재합니다${NC}"
    read -p "덮어쓰시겠습니까? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "작업 취소됨"
        exit 0
    fi
fi

# GPG 설치 확인
if ! command -v gpg &> /dev/null; then
    echo -e "${RED}Error: GPG가 설치되어 있지 않습니다${NC}"
    echo "설치 방법:"
    echo "  Ubuntu/Debian: sudo apt-get install gnupg"
    echo "  macOS: brew install gnupg"
    exit 1
fi

# 복호화 수행
echo -e "${YELLOW}복호화 중: $GPG_FILE -> $ENV_FILE${NC}"
if gpg --decrypt --output "$ENV_FILE" "$GPG_FILE"; then
    echo -e "${GREEN}✓ 복호화 완료: $ENV_FILE${NC}"
    
    # 파일 권한 설정 (중요한 환경 변수 보호)
    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✓ 파일 권한 설정: 600${NC}"
else
    echo -e "${RED}✗ 복호화 실패${NC}"
    echo "가능한 원인:"
    echo "  - GPG 키가 없거나 만료됨"
    echo "  - 잘못된 패스프레이즈"
    echo "  - 파일이 손상됨"
    exit 1
fi