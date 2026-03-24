# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claude-in-docker** (CinD) is a Docker image for running Claude Code in an isolated container. It treats AI agents as untrusted contractors and mitigates risks of running them directly on the host machine.

The image is based on `node:20`, installs claude-code via npm, and includes a network firewall (`init-firewall.sh`) that restricts outbound traffic to an allowlist of domains (GitHub, npm registry, Anthropic API, Sentry, VS Code marketplace).

## Architecture

The project has two main components:

1. **Dockerfile** - Builds the container image. Based on the official Anthropic devcontainer Dockerfile. Runs as the `node` user with zsh shell. Key build args: `CLAUDE_CODE_VERSION` (defaults to `latest`), `TZ` (timezone), `GIT_DELTA_VERSION`.

2. **init-firewall.sh** - Network isolation script run inside the container with sudo. It:
   - Flushes iptables rules while preserving Docker DNS resolution
   - Creates an `ipset` allowlist (`allowed-domains`) with GitHub IP ranges (fetched from GitHub meta API) and resolved IPs for npm, Anthropic, Sentry, statsig, and VS Code domains
   - Sets default policies to DROP for INPUT/FORWARD/OUTPUT
   - Self-verifies by confirming `example.com` is blocked and `api.github.com` is reachable
   - The `node` user has passwordless sudo access **only** for this script

Docker image tags follow `CC_VERSION-VARIANT` format (e.g. `2.1.81-open`). Floating variant tags (`open`, `firewalled`, etc.) always point to the latest build. Pin via digest for reproducibility.

## Build & Publish

```bash
make build    # Build all variants for the local platform
make push     # Build multi-platform (amd64+arm64) and push to Docker Hub
make version  # Print the claude-code version from the image
make clean    # Remove locally built cind images
make help     # Show all targets
```

## Claude-Code Behavioral Instructions

Always follow these guidelines for the given phase.

### Exploration Phase

When you run Explore:

- **DO NOT** spawn exploration agents unless explicitly asked to do so by the user. **Always explore everything on your own** to gain a complete and thorough understanding.

# Extra Instructions
@.claude/CLAUDE.extra.md
