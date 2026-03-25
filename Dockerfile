FROM ubuntu:latest

# ── System deps ───────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    make \
    less \
    wget \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    gnupg2 \
    locales \
    vim \
    jq \
    unzip \
    htop \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    nano \
    postgresql-client \
    ripgrep \
    sqlite3 \
    tree \
    lsof \
    iputils-ping \
    traceroute \
    netcat-openbsd \
    tcpdump \
    nmap \
    net-tools \
    openssh-client \
    uuid-runtime \
    aggregate \
    ca-certificates \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI ────────────────────────────────────────────────────────────────
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js (via NodeSource — avoids Ubuntu's outdated/conflicting packages) ──
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Playwright system deps ────────────────────────────────────────────────────
# Let Playwright detect and install the correct libs for this OS version
RUN npx playwright install-deps

# ── Go (latest stable) ────────────────────────────────────────────────────────
RUN GOVERSION=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1) \
    && wget -q "https://go.dev/dl/${GOVERSION}.linux-arm64.tar.gz" -O /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# ── yq (YAML processor) ──────────────────────────────────────────────────────
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64 \
    && chmod +x /usr/local/bin/yq

# ── AWS CLI v2 ────────────────────────────────────────────────────────────
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# ── Task (taskfile.dev) ──────────────────────────────────────────────────────
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# ── pnpm ─────────────────────────────────────────────────────────────────────
RUN npm install -g pnpm

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ── User ──────────────────────────────────────────────────────────────────────
# Match the host user's UID so bind-mounted files (e.g. ~/.claude.json) are
# owned by the same UID inside the container — required for Claude auth to work.
ARG HOST_UID=1000
RUN useradd -u ${HOST_UID} -m -s /bin/zsh ai
USER ai
WORKDIR /home/ai

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Use the 'agnoster' theme for git branch display; keep useful plugins.
RUN sed -i \
    -e 's/^ZSH_THEME=.*/ZSH_THEME="af-magic"/' \
    -e 's/^plugins=.*/plugins=(git z colored-man-pages command-not-found)/' \
    /home/ai/.zshrc \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ai/.zshrc

# ── Bun ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://bun.sh/install | bash \
    && echo 'export PATH="$HOME/.bun/bin:$PATH"' >> /home/ai/.zshrc
ENV PATH="/home/ai/.bun/bin:${PATH}"

# ── nvm ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
ENV NVM_DIR="/home/ai/.nvm"

# ── uv (Astral) ──────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/ai/.local/bin:${PATH}"

# ── mise ─────────────────────────────────────────────────────────────────────
RUN curl https://mise.run | sh \
    && echo 'eval "$(~/.local/bin/mise activate zsh)"' >> /home/ai/.zshrc

# ── Wails ────────────────────────────────────────────────────────────────────
ENV GOPATH="/home/ai/go"
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"
RUN go install github.com/wailsapp/wails/v2/cmd/wails@latest

# ── Claude CLI ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://claude.ai/install.sh | bash

USER root
RUN cp /home/ai/.local/bin/claude /usr/local/bin/claude

# Convenience wrapper: runs Claude in isolated (dangerously-skip-permissions) mode.
# Git push and remote writes are still blocked by the PreToolUse hook in
# .claude/settings.json regardless of this flag.
RUN printf '#!/bin/sh\nexec claude --dangerously-skip-permissions "$@"\n' \
    > /usr/local/bin/claude-isolated \
    && chmod +x /usr/local/bin/claude-isolated

# ── OpenAI Codex ──────────────────────────────────────────────────────────────
# Uses OPENAI_API_KEY from the environment at runtime.
RUN npm install -g @openai/codex

# ── Firewall Init Script ─────────────────────────────────────────────────────
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "ai ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/ai-firewall && \
  chmod 0440 /etc/sudoers.d/ai-firewall

# ── Switch back to ai user ────────────────────────────────────────────────────
USER ai
WORKDIR /home/ai/workspace

CMD ["/bin/zsh"]
