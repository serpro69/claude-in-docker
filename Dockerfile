# original source: https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/.devcontainer/Dockerfile
ARG UV_VERSION=0.6.14
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM node:20 AS base

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  jq \
  python3-venv \
  nano \
  vim \
  gosu \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Install uv/uvx (Python package manager) for MCP servers that use uvx
COPY --from=uv /uv /uvx /usr/local/bin/

# Ensure uv cache dir exists for node user
RUN mkdir -p /home/node/.cache/uv && chown -R node:node /home/node/.cache

# Entrypoint handles UID remapping and drops to node user via gosu
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to node for build steps (installing packages, zsh config)
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/node/.local/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Switch back to root for runtime — entrypoint drops to node via gosu
USER root
ENTRYPOINT ["entrypoint.sh"]

# --- Full variant: pre-installs MCP server packages for faster startup ---
FROM base AS full
USER node
RUN npm install -g task-master-ai
RUN uv tool install git+https://github.com/oraios/serena && \
  uv tool install git+https://github.com/BeehiveInnovations/pal-mcp-server.git
USER root

# --- Final images: combine base/full with open/firewalled ---

# Slim (runtimes only, MCP packages downloaded at runtime via npx/uvx)
FROM base AS slim-open
FROM base AS slim-firewalled
RUN apt-get update && apt-get install -y --no-install-recommends \
  iptables ipset iproute2 dnsutils aggregate \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

# Full (MCP packages pre-installed)
FROM full AS open
FROM full AS firewalled
RUN apt-get update && apt-get install -y --no-install-recommends \
  iptables ipset iproute2 dnsutils aggregate \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
