# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claude-in-docker** (CinD) is a Docker image for running Claude Code in an isolated container. The project itself is a template-managed AI development environment — not a traditional application with a build/run cycle. It is derived from the upstream template [serpro69/claude-starter-kit](https://github.com/serpro69/claude-starter-kit).

There is no Makefile, Dockerfile, go.mod, or package.json yet. The README references `make build` and `make publish` as future goals.

## Security Model

This project treats AI agents as untrusted contractors. Key security layers:

- **Pre-tool hook** (`.claude/scripts/validate-bash.sh`): Blocks bash commands touching `.env`, `.git/`, `node_modules`, `venv/`, `build/`, `dist/`, and other sensitive paths. Exit code 2 = blocked.
- **Permission allowlist** (`.claude/settings.json`): Explicit allow/deny lists for tools. `rm` is denied. Only specific bash commands (`cat`, `chmod`, `grep`, `ls`, `mkdir`, `sort`) are allowed.
- **Deny rules**: No reading `.env`, lock files, `.git/`, `.idea/`, `.vscode/`, `node_modules/`, `__pycache__/`, `build/`, `dist/`, `data/`, `.csv`, `.log`, `.pyc`.

## Template Sync System

The repo syncs configuration from the upstream `claude-starter-kit` template:

- **Manifest**: `.github/template-state.json` tracks upstream version, project variables, and sync exclusions
- **Sync script**: `.github/scripts/template-sync.sh` (~1250 lines) handles fetching, variable substitution, diffing, and staging
- **GitHub Action**: `.github/workflows/template-sync.yml` — manual dispatch, creates PRs with changes
- **Variables**: `PROJECT_NAME`, `LANGUAGES` (bash,go,markdown), `CC_MODEL`, `TM_PERMISSION_MODE` are substituted into template files

To sync manually: `.github/scripts/template-sync.sh --version latest` (add `--dry-run` to preview).

## Key Directories

- `.claude/` — Claude Code config, scripts, agents, skills, and slash commands
- `.claude/skills/` — Reusable skill definitions (analysis, cove, development-guidelines, documentation, implementation, solid-code-review, testing)
- `.claude/commands/` — Slash command definitions (cove, tm)
- `.serena/` — Serena code intelligence config (project.yml, memories, cache)
- `.taskmaster/` — Task Master project management (tasks.json, config, PRDs, reports)
- `.github/` — Template sync workflow and scripts

## MCP Integrations

Three MCP servers are configured:

1. **Task Master AI** — Task management (get_tasks, next_task, set_task_status, expand_task, etc.). Prefer MCP tools over CLI.
2. **Serena** — Symbol-aware code navigation. Use its tools for reading/editing code over raw file reads when working with source files.
3. **Context7** — Library documentation lookup.

## Claude-Code Behavioral Instructions

Always follow these guidelines for the given phase.

### Exploration Phase

When you run Explore:

- DO NOT spawn exploration agents unless explicitly asked to do so by the user. **Always explore everything on your own** to gain a complete and thorough understanding.
  <!-- Why: Claude tends to first spawn exploration agents,
       and then re-reads all the files on it's own...
       resulting in double token consumption -->

## Task Master AI Instructions

**IMPORTANT!!! Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**

@./.taskmaster/CLAUDE.md

## Claude-Code Behavioral Instructions

Always follow these guidelines for the given phase.

### Exploration Phase

When you run Explore:

- DO NOT spawn exploration agents unless explicitly asked to do so by the user. **Always explore everything on your own** to gain a complete and thorough understanding.
  <!-- Why: Claude tends to first spawn exploration agents,
       and then re-reads all the files on it's own...
       resulting in double token consumption -->
