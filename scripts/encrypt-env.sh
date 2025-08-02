#!/bin/bash
# GPG를 사용한 .env 파일 대칭키 암호화 스크립트

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 기본값
ENV_FILE=".env"
GPG_FILE=".env.gpg"

# 사용법 출력
usage() {
    echo "Usage: $0 [-f env_file] [-o output_file]"
    echo "  -f  환경 파일 경로 (기본값: .env)"
    echo "  -o  출력 파일 경로 (기본값: .env.gpg)"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  $0 -f .env.production -o .env.production.gpg"
    echo ""
    echo "비밀번호를 사용한 대칭키 암호화를 수행합니다."
    exit 1
}

# 옵션 파싱
while getopts "f:o:h" opt; do
    case $opt in
        f) ENV_FILE="$OPTARG" ;;
        o) GPG_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# 환경 파일 존재 확인
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: 환경 파일 '$ENV_FILE'을 찾을 수 없습니다${NC}"
    exit 1
fi

# GPG 설치 확인
if ! command -v gpg &> /dev/null; then
    echo -e "${RED}Error: GPG가 설치되어 있지 않습니다${NC}"
    echo "설치 방법:"
    echo "  Ubuntu/Debian: sudo apt-get install gnupg"
    echo "  macOS: brew install gnupg"
    exit 1
fi

# 암호화 수행
echo -e "${YELLOW}대칭키 암호화 중: $ENV_FILE -> $GPG_FILE${NC}"
echo -e "${YELLOW}강력한 비밀번호를 입력하세요 (팀원과 공유할 비밀번호)${NC}"

if gpg --armor --symmetric --cipher-algo AES256 --output "$GPG_FILE" "$ENV_FILE"; then
    echo -e "${GREEN}✓ 암호화 완료: $GPG_FILE${NC}"
    echo ""
    echo "Git에 추가하려면:"
    echo "  git add $GPG_FILE"
    echo "  git commit -m \"Update encrypted environment file\""
    echo ""
    echo -e "${YELLOW}중요: 비밀번호를 안전하게 보관하고 팀원과 공유하세요${NC}"
else
    echo -e "${RED}✗ 암호화 실패${NC}"
    exit 1
fi