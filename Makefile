# ── Configuration ─────────────────────────────────────────────
DOCKER_REPO          ?= serpro69/cind
PLATFORMS            ?= linux/amd64,linux/arm64
CLAUDE_CODE_VERSION  ?=

# All Dockerfile targets and their tag suffixes
VARIANTS = slim-open slim-firewalled open firewalled

# Base image used for npm registry queries (must have npm)
NODE_IMAGE = node:24

.PHONY: help version build push clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Version detection ────────────────────────────────────────
version: ## Print the claude-code version baked into the image
	@docker build -q --target base \
		--build-arg CLAUDE_CODE_VERSION=$(or $(CLAUDE_CODE_VERSION),latest) \
		-t cind-base:probe . >/dev/null 2>&1
	@docker run --rm --entrypoint /bin/sh cind-base:probe -c 'claude --version' | awk '{print $$1}'

# ── Build (local, single-platform) ──────────────────────────
build: ## Build all variants for the local platform
	@if [ -n "$(CLAUDE_CODE_VERSION)" ]; then \
		VERSION="$(CLAUDE_CODE_VERSION)"; \
	else \
		echo "Detecting latest claude-code version..."; \
		VERSION=$$(docker run --rm $(NODE_IMAGE) npm view @anthropic-ai/claude-code version); \
		if [ -z "$$VERSION" ]; then \
			echo "ERROR: Failed to detect claude-code version from npm registry"; \
			exit 1; \
		fi; \
	fi; \
	echo "Claude Code version: $$VERSION"; \
	echo ""; \
	for variant in $(VARIANTS); do \
		echo "── Building $$variant ──"; \
		docker build --build-arg CLAUDE_CODE_VERSION=$$VERSION \
			--target $$variant \
			-t $(DOCKER_REPO):$$variant \
			-t $(DOCKER_REPO):$$VERSION-$$variant . ; \
	done; \
	echo ""; \
	echo "Tagged images:"; \
	for variant in $(VARIANTS); do \
		echo "  $(DOCKER_REPO):$$variant"; \
		echo "  $(DOCKER_REPO):$$VERSION-$$variant"; \
	done

# ── Push (multi-platform) ───────────────────────────────────
push: ## Build multi-platform images and push all variants to Docker Hub
	@if [ -n "$(CLAUDE_CODE_VERSION)" ]; then \
		VERSION="$(CLAUDE_CODE_VERSION)"; \
	else \
		echo "Detecting latest claude-code version..."; \
		VERSION=$$(docker run --rm $(NODE_IMAGE) npm view @anthropic-ai/claude-code version); \
		if [ -z "$$VERSION" ]; then \
			echo "ERROR: Failed to detect claude-code version from npm registry"; \
			exit 1; \
		fi; \
	fi; \
	echo "Claude Code version: $$VERSION"; \
	echo ""; \
	for variant in $(VARIANTS); do \
		TAGS="-t $(DOCKER_REPO):$$variant -t $(DOCKER_REPO):$$VERSION-$$variant"; \
		echo "── Pushing $$variant ($$TAGS) ──"; \
		docker build --build-arg CLAUDE_CODE_VERSION=$$VERSION \
			--platform $(PLATFORMS) --target $$variant \
			$$TAGS --push . ; \
	done; \
	echo ""; \
	echo "Pushed all variants for version $$VERSION"

# ── Cleanup ──────────────────────────────────────────────────
clean: ## Remove locally built cind images
	@docker images --format '{{.Repository}}:{{.Tag}}' | grep '^$(DOCKER_REPO):' | \
		xargs -r docker rmi 2>/dev/null || true
	@docker rmi cind-base:probe 2>/dev/null || true
	@echo "Cleaned up local cind images"
