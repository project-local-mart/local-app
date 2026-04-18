SHELL := /bin/bash

.PHONY: setup up down dev db-generate db-migrate db-seed db-reset clean logs ps

# Load nvm if node is not already on PATH (common when running make from an IDE terminal)
ifeq ($(shell command -v node 2>/dev/null),)
  NVM_DIR ?= $(HOME)/.nvm
  ifneq ($(wildcard $(NVM_DIR)/nvm.sh),)
    $(shell source $(NVM_DIR)/nvm.sh && nvm use --silent 2>/dev/null; echo "export PATH=$$PATH" > /tmp/.localmart_path)
    include /tmp/.localmart_path
  endif
endif

# Guard: fail fast with a clear message if node is still not found after the above.
NODE_CHECK := $(shell command -v node 2>/dev/null)
define CHECK_NODE
	@if [ -z "$(NODE_CHECK)" ]; then \
		echo ""; \
		echo "  ERROR: node not found on PATH."; \
		echo ""; \
		echo "  If you use nvm, run:  nvm install  (reads .nvmrc → Node 20)"; \
		echo "  If you use mise/asdf, run: mise install"; \
		echo "  Or install Node 20 directly: https://nodejs.org"; \
		echo ""; \
		exit 1; \
	fi
endef

PNPM_CHECK := $(shell command -v pnpm 2>/dev/null)
define CHECK_PNPM
	@if [ -z "$(PNPM_CHECK)" ]; then \
		echo ""; \
		echo "  ERROR: pnpm not found. Install it with:  npm install -g pnpm"; \
		echo ""; \
		exit 1; \
	fi
endef

# ── First-time setup ──────────────────────────────────────────────────────────

setup: ## Full first-time setup: install deps, start services, run migrations, seed
	$(CHECK_NODE)
	$(CHECK_PNPM)
	pnpm install
	cp -n .env.example .env || true
	$(MAKE) up
	@echo "Waiting for Postgres to be ready..."
	@until docker exec localmart_postgres pg_isready -U localmart -d localmart_dev > /dev/null 2>&1; do sleep 1; done
	$(MAKE) db-migrate
	$(MAKE) db-seed
	@echo ""
	@echo "✓ Setup complete. Run 'make dev' to start all services."

# ── Docker services ───────────────────────────────────────────────────────────

up: ## Start all background services (Postgres, Redis, Meilisearch, MinIO)
	docker compose up -d

down: ## Stop all background services
	docker compose down

logs: ## Tail logs for all services
	docker compose logs -f

ps: ## Show service status
	docker compose ps

# ── Development ───────────────────────────────────────────────────────────────

dev: ## Start all apps in watch mode (requires services to be running)
	pnpm dev

# ── Database ──────────────────────────────────────────────────────────────────

db-generate: ## Generate a new Drizzle migration from schema changes
	pnpm db:generate

db-migrate: ## Apply pending migrations
	pnpm db:migrate

db-seed: ## Seed the database with development data
	pnpm db:seed

db-reset: ## Drop and recreate the database, re-run migrations and seed
	docker exec localmart_postgres psql -U localmart -c "DROP DATABASE IF EXISTS localmart_dev;"
	docker exec localmart_postgres psql -U localmart -c "CREATE DATABASE localmart_dev;"
	$(MAKE) db-migrate
	$(MAKE) db-seed

db-shell: ## Open a psql shell against the local database
	docker exec -it localmart_postgres psql -U localmart -d localmart_dev

# ── MinIO ─────────────────────────────────────────────────────────────────────

minio-setup: ## Create the default bucket in MinIO (run once after first 'make up')
	docker exec localmart_minio mc alias set local http://localhost:9000 localmart localmart_dev_password
	docker exec localmart_minio mc mb local/localmart-product-images --ignore-existing

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean: ## Remove build artifacts across all packages
	pnpm clean

nuke: ## Stop services and delete all volumes (destroys all local data)
	docker compose down -v

# ── Misc ──────────────────────────────────────────────────────────────────────

install: ## Install/refresh pnpm dependencies
	pnpm install

typecheck: ## Run TypeScript type checking across all packages
	pnpm typecheck

lint: ## Run ESLint across all packages
	pnpm lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
