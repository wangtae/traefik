# Traefik Docker 관리 Makefile
.PHONY: help up down restart logs ps clean encrypt decrypt init update backup restore network use-dev use-prod encrypt-all

# 기본 변수
DOCKER_COMPOSE = docker compose
PROJECT_NAME = traefik
ENV_FILE = .env
SECRETS_DIR = secrets
BACKUP_DIR = backups
NETWORK_NAME = docker-network
ENV ?= dev

# 색상 정의
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# 기본 타겟
.DEFAULT_GOAL := help

## 도움말
help:
	@echo "$(GREEN)Traefik Docker 관리 명령어$(NC)"
	@echo ""
	@echo "$(YELLOW)기본 명령어:$(NC)"
	@echo "  make init       환경 초기화 (네트워크 생성, .env 복호화)"
	@echo "  make up         컨테이너 시작"
	@echo "  make down       컨테이너 중지"
	@echo "  make restart    컨테이너 재시작"
	@echo "  make logs       로그 확인 (실시간)"
	@echo "  make ps         컨테이너 상태 확인"
	@echo ""
	@echo "$(YELLOW)환경 설정:$(NC)"
	@echo "  make encrypt    현재 환경 파일 암호화 (GPG)"
	@echo "  make decrypt    환경 파일 복호화"
	@echo "  make use-dev    개발 환경 사용"
	@echo "  make use-prod   운영 환경 사용"
	@echo "  make encrypt-all 모든 환경 파일 암호화"
	@echo ""
	@echo "$(YELLOW)유지보수:$(NC)"
	@echo "  make update     이미지 업데이트 및 재시작"
	@echo "  make clean      로그 및 임시 파일 정리"
	@echo "  make backup     설정 백업"
	@echo "  make restore    설정 복원"
	@echo ""
	@echo "$(YELLOW)네트워크:$(NC)"
	@echo "  make network    Docker 네트워크 생성"

## 환경 초기화
init: network check-env
	@echo "$(GREEN)✓ 환경 초기화 완료$(NC)"

## Docker 네트워크 생성
network:
	@if [ -z "$$(docker network ls -q -f name=^$(NETWORK_NAME)$$)" ]; then \
		echo "$(YELLOW)Docker 네트워크 생성 중: $(NETWORK_NAME)$(NC)"; \
		docker network create $(NETWORK_NAME); \
		echo "$(GREEN)✓ 네트워크 생성 완료$(NC)"; \
	else \
		echo "$(GREEN)✓ 네트워크가 이미 존재합니다: $(NETWORK_NAME)$(NC)"; \
	fi

## .env 파일 확인
check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		if [ -f ".env.$(ENV)" ]; then \
			echo "$(YELLOW).env 파일이 없습니다. $(ENV) 환경을 복사합니다...$(NC)"; \
			cp ".env.$(ENV)" "$(ENV_FILE)"; \
		elif [ -f "$(SECRETS_DIR)/.env.$(ENV).gpg" ]; then \
			echo "$(YELLOW).env 파일이 없습니다. $(ENV) 환경을 복호화합니다...$(NC)"; \
			./scripts/decrypt-env.sh -f "$(SECRETS_DIR)/.env.$(ENV).gpg" -o "$(ENV_FILE)"; \
		else \
			echo "$(YELLOW).env 파일이 없습니다. .env.example을 복사합니다...$(NC)"; \
			cp .env.example $(ENV_FILE); \
			echo "$(GREEN)✓ .env 파일 생성 완료. 필요한 값을 설정하세요.$(NC)"; \
		fi \
	fi

## 컨테이너 시작
up: check-env network
	@echo "$(YELLOW)Traefik 컨테이너 시작 중...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✓ Traefik가 시작되었습니다$(NC)"
	@echo ""
	@echo "대시보드: http://traefik.local:8080/dashboard/"
	@echo "인증: wangtae@gmail.com / !wangtae@gmail.com@."

## 컨테이너 중지
down:
	@echo "$(YELLOW)Traefik 컨테이너 중지 중...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Traefik가 중지되었습니다$(NC)"

## 컨테이너 재시작
restart: down up

## 로그 확인 (실시간)
logs:
	@$(DOCKER_COMPOSE) logs -f --tail=100

## 컨테이너 상태 확인
ps:
	@$(DOCKER_COMPOSE) ps

## 이미지 업데이트 및 재시작
update:
	@echo "$(YELLOW)Docker 이미지 업데이트 중...$(NC)"
	@$(DOCKER_COMPOSE) pull
	@echo "$(GREEN)✓ 이미지 업데이트 완료$(NC)"
	@$(MAKE) restart

## 로그 및 임시 파일 정리
clean:
	@echo "$(YELLOW)로그 파일 정리 중...$(NC)"
	@if [ -d "logs" ]; then \
		find logs -name "*.log" -type f -mtime +7 -delete; \
		echo "$(GREEN)✓ 7일 이상된 로그 파일 삭제 완료$(NC)"; \
	fi
	@echo "$(YELLOW)임시 파일 정리 중...$(NC)"
	@find . -name "*.tmp" -o -name "*.swp" -o -name "*~" | xargs -r rm -f
	@echo "$(GREEN)✓ 정리 완료$(NC)"

## 현재 환경 파일 암호화
encrypt:
	@if [ ! -f ".env.$(ENV)" ]; then \
		echo "$(RED)Error: .env.$(ENV) 파일이 없습니다$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)비밀번호를 사용한 대칭키 암호화를 수행합니다$(NC)"
	@./scripts/encrypt-env.sh -f ".env.$(ENV)" -o "$(SECRETS_DIR)/.env.$(ENV).gpg"

## 환경 파일 복호화
decrypt:
	@if [ ! -f "$(SECRETS_DIR)/.env.$(ENV).gpg" ]; then \
		echo "$(YELLOW)경고: $(SECRETS_DIR)/.env.$(ENV).gpg 파일이 없습니다$(NC)"; \
		exit 0; \
	fi
	@./scripts/decrypt-env.sh -f "$(SECRETS_DIR)/.env.$(ENV).gpg" -o ".env.$(ENV)"

## 모든 환경 파일 암호화
encrypt-all:
	@echo "$(YELLOW)모든 환경 파일을 비밀번호로 암호화합니다$(NC)"
	@echo "$(YELLOW)모든 파일에 동일한 비밀번호가 사용됩니다$(NC)"
	@for env in dev prod; do \
		if [ -f ".env.$$env" ]; then \
			echo "$(YELLOW)암호화: .env.$$env$(NC)"; \
			./scripts/encrypt-env.sh -f ".env.$$env" -o "$(SECRETS_DIR)/.env.$$env.gpg"; \
		fi \
	done

## 개발 환경 사용
use-dev:
	@cp .env.dev .env
	@echo "$(GREEN)✓ 개발 환경이 활성화되었습니다$(NC)"

## 운영 환경 사용
use-prod:
	@cp .env.prod .env
	@echo "$(GREEN)✓ 운영 환경이 활성화되었습니다$(NC)"

## 설정 백업
backup:
	@echo "$(YELLOW)설정 백업 중...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@backup_name="backup-$$(date +%Y%m%d-%H%M%S)"; \
	tar -czf "$(BACKUP_DIR)/$$backup_name.tar.gz" \
		--exclude='logs/*' \
		--exclude='letsencrypt/*' \
		--exclude='$(BACKUP_DIR)/*' \
		--exclude='.git/*' \
		.
	@echo "$(GREEN)✓ 백업 완료: $(BACKUP_DIR)/$$backup_name.tar.gz$(NC)"

## 설정 복원
restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: BACKUP_FILE을 지정하세요$(NC)"; \
		echo "사용법: make restore BACKUP_FILE=backups/backup-YYYYMMDD-HHMMSS.tar.gz"; \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: 백업 파일을 찾을 수 없습니다: $(BACKUP_FILE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)설정 복원 중: $(BACKUP_FILE)$(NC)"
	@tar -xzf "$(BACKUP_FILE)"
	@echo "$(GREEN)✓ 복원 완료$(NC)"

## Traefik 헬스체크
health:
	@echo "$(YELLOW)Traefik 헬스체크 중...$(NC)"
	@if $(DOCKER_COMPOSE) exec traefik traefik healthcheck 2>/dev/null; then \
		echo "$(GREEN)✓ Traefik가 정상적으로 작동 중입니다$(NC)"; \
	else \
		echo "$(RED)✗ Traefik 헬스체크 실패$(NC)"; \
		exit 1; \
	fi

## 인증서 상태 확인
certs:
	@echo "$(YELLOW)Let's Encrypt 인증서 상태:$(NC)"
	@if [ -f "letsencrypt/acme.json" ]; then \
		echo "$(GREEN)✓ acme.json 파일이 존재합니다$(NC)"; \
		echo "파일 크기: $$(du -h letsencrypt/acme.json | cut -f1)"; \
		echo "수정 시간: $$(stat -c %y letsencrypt/acme.json 2>/dev/null || stat -f %Sm letsencrypt/acme.json)"; \
	else \
		echo "$(YELLOW)아직 인증서가 생성되지 않았습니다$(NC)"; \
	fi

## 전체 상태 확인
status: ps health certs
	@echo ""
	@echo "$(GREEN)전체 상태 확인 완료$(NC)"