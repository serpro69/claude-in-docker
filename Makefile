# ── Configuration ─────────────────────────────────────────────
DOCKER_REPO   ?= serpro69/cind
PLATFORMS     ?= linux/amd64,linux/arm64

# All Dockerfile targets and their tag suffixes
VARIANTS = slim-open slim-firewalled open firewalled

.PHONY: help version build push clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Version detection ────────────────────────────────────────
version: ## Print the claude-code version from the image
	@docker build -q --target base -t cind-base:probe . >/dev/null 2>&1
	@docker run --rm --entrypoint /bin/sh cind-base:probe -c 'claude --version' | awk '{print $$1}'

# ── Build (local, single-platform) ──────────────────────────
build: ## Build all variants for the local platform
	@echo "Building all variants..."
	@for variant in $(VARIANTS); do \
		echo "── Building $$variant ──"; \
		docker build --target $$variant -t $(DOCKER_REPO):$$variant . ; \
	done
	@VERSION=$$(docker run --rm --entrypoint /bin/sh $(DOCKER_REPO):open -c 'claude --version' | awk '{print $$1}'); \
	echo ""; \
	echo "Claude Code version: $$VERSION"; \
	echo ""; \
	echo "Tagged images:"; \
	for variant in $(VARIANTS); do \
		docker tag $(DOCKER_REPO):$$variant $(DOCKER_REPO):$$VERSION-$$variant; \
		echo "  $(DOCKER_REPO):$$variant"; \
		echo "  $(DOCKER_REPO):$$VERSION-$$variant"; \
	done

# ── Push (multi-platform) ───────────────────────────────────
push: ## Build multi-platform images and push all variants to Docker Hub
	@echo "Detecting claude-code version..."
	@VERSION=$$(docker run --rm --entrypoint /bin/sh $(DOCKER_REPO):open -c 'claude --version' 2>/dev/null | awk '{print $$1}' || true); \
	if [ -z "$$VERSION" ]; then \
		echo "No local image found. Building base to detect version..."; \
		docker build -q --target base -t cind-base:probe . >/dev/null; \
		VERSION=$$(docker run --rm --entrypoint /bin/sh cind-base:probe -c 'claude --version' | awk '{print $$1}'); \
	fi; \
	echo "Claude Code version: $$VERSION"; \
	echo ""; \
	for variant in $(VARIANTS); do \
		TAGS="-t $(DOCKER_REPO):$$variant -t $(DOCKER_REPO):$$VERSION-$$variant"; \
		echo "── Pushing $$variant ($$TAGS) ──"; \
		docker build --platform $(PLATFORMS) --target $$variant \
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
