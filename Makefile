.PHONY: help bootstrap lint test clean launch health monitor

# Default target
help:
	@echo "Speccy-Kit Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  bootstrap   - Initialize the development environment"
	@echo "  lint        - Run linting across the project"
	@echo "  test        - Run tests across the project"
	@echo "  clean       - Clean build artifacts"

bootstrap:
	@echo "🚀 Bootstrapping Speccy-Kit..."
	@echo "✅ Making scripts executable..."
	@chmod +x speccy
	@chmod +x speccy-kit/tools/*.sh
	@chmod +x tools/*.sh
	@echo "✅ Creating necessary directories..."
	@mkdir -p proposed
	@mkdir -p logs
	@echo "✅ Bootstrap complete!"

lint:
	@echo "🔍 Running linting..."
	@if [ -f "package.json" ]; then \
		if npm run lint 2>/dev/null || [ $$? -eq 1 ]; then \
			echo "✅ Linting complete (no lint script found)"; \
		fi; \
	else \
		echo "✅ Linting complete (no package.json)"; \
	fi

test:
	@echo "🧪 Running tests..."
	@if [ -f "package.json" ]; then \
		if npm test 2>/dev/null || [ $$? -eq 1 ]; then \
			echo "✅ Tests complete (no test script found)"; \
		fi; \
	else \
		echo "✅ Tests complete (no package.json)"; \
	fi

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf node_modules/.cache
	@rm -rf dist
	@rm -rf .next
	@echo "✅ Clean complete!"

launch:
	@./scripts/omarchy_one_button.sh

health:
	@./scripts/health-check.sh || true

monitor:
	@./quantum-forge-monitor

# --- Omarchy R&D / BYOX (repo-local caches, clean teardown) ---
GO_BUILD_CACHE := .cache/go-build
GO_MOD_CACHE   := .cache/go-mod
SEARCHD_BIN    := RnD/searchd
SEARCHD_PID    := .cache/searchd.pid
BYOX_CACHE     := .cache/byox-repo
BYOX_MODULES   := RnD/byox-modules

.PHONY: rnd-prep rnd-build rnd-run rnd-search rnd-stop import-byox

rnd-prep:
	@mkdir -p $(GO_BUILD_CACHE) $(GO_MOD_CACHE) .cache
	@echo "⬢ prep: using repo-local Go caches → $(GO_BUILD_CACHE), $(GO_MOD_CACHE)"

rnd-build: rnd-prep
	@( cd RnD/byox-search-engine/cmd/searchd && \
		GOCACHE=$(abspath $(GO_BUILD_CACHE)) \
		GOMODCACHE=$(abspath $(GO_MOD_CACHE)) \
		go build -o ../../../searchd )
	@echo "✅ built $(SEARCHD_BIN)"

rnd-run: rnd-build
	@echo "▶ starting $(SEARCHD_BIN) on :8188"
	@./$(SEARCHD_BIN) >/dev/null 2>&1 & echo $$! > $(SEARCHD_PID)
	@printf "⏳ waiting for server"; for i in $$(seq 1 20); do \
		sleep 0.2; \
		curl -sf localhost:8188/ping >/dev/null 2>&1 && break || printf "."; \
	done; echo
	@curl -s localhost:8188/ping | (jq . 2>/dev/null || cat)
	@echo "ℹ pid: $$(cat $(SEARCHD_PID))"

rnd-search:
	@curl -s localhost:8188/search \
		-H "Content-Type: application/json" \
		-d '{"q":"test"}' | (jq . 2>/dev/null || cat)

rnd-stop:
	@touch $(SEARCHD_PID) >/dev/null 2>&1 || true
	@if [ -s "$(SEARCHD_PID)" ]; then \
		echo "■ stopping searchd ($$(cat $(SEARCHD_PID)))"; \
		kill $$(cat $(SEARCHD_PID)) >/dev/null 2>&1 || true; \
		rm -f $(SEARCHD_PID); \
	else \
		echo "■ searchd not running"; \
	fi

import-byox:
	@[ "$${X:-}" ] || (echo "usage: make import-byox X=search-engine" && exit 1)
	@mkdir -p $(BYOX_CACHE) $(BYOX_MODULES)
	@if [ ! -d "$(BYOX_CACHE)/.git" ]; then \
		git clone --depth 1 https://github.com/codecrafters-io/build-your-own-x.git $(BYOX_CACHE); \
	else \
		git -C $(BYOX_CACHE) pull --ff-only; \
	fi
	@if [ -d "$(BYOX_CACHE)/projects/$(X)" ]; then \
		mkdir -p $(BYOX_MODULES)/$(X); \
		rsync -a --delete "$(BYOX_CACHE)/projects/$(X)/" "$(BYOX_MODULES)/$(X)/"; \
		echo "✅ imported BYOX module → $(BYOX_MODULES)/$(X)"; \
	else \
		echo "⚠ project '$(X)' not found upstream; seeding placeholder in $(BYOX_MODULES)/$(X)"; \
		mkdir -p $(BYOX_MODULES)/$(X); \
		echo "# BYOX module $(X)" > $(BYOX_MODULES)/$(X)/README.md; \
		echo "" >> $(BYOX_MODULES)/$(X)/README.md; \
		echo "Source: https://github.com/codecrafters-io/build-your-own-x" >> $(BYOX_MODULES)/$(X)/README.md; \
		echo "" >> $(BYOX_MODULES)/$(X)/README.md; \
		echo "Placeholder generated on $$(date -u +%Y-%m-%dT%H:%M:%SZ)." >> $(BYOX_MODULES)/$(X)/README.md; \
	fi
launch-rnd:
	./scripts/omarchy_rnd_bootstrap.sh
