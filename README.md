# ai-dev

Containerized Linux/arm64 development environment for running AI coding agents (Claude, Codex) with a pre-configured toolchain, firewall-based network sandboxing, and multi-project port mappings.

## Prerequisites

- Docker (with ARM64/aarch64 support)
- API keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` (exported in your shell)

## Quick Start

```bash
./dev.sh build    # Build the Docker image
./dev.sh start    # Start container and attach
```

## Commands

| Command           | Description                              |
| ----------------- | ---------------------------------------- |
| `./dev.sh build`  | Build the Docker image                   |
| `./dev.sh start`  | Start the container and attach a shell   |
| `./dev.sh shell`  | Open an additional shell in the container|
| `./dev.sh stop`   | Stop the container                       |
| `./dev.sh remove` | Stop and remove the container            |

## Toolchain

| Category       | Tools                                          |
| -------------- | ---------------------------------------------- |
| Languages      | Node.js (LTS), Go (latest), Bun, Python (uv)  |
| Package mgmt   | pnpm, npm, nvm, mise                           |
| AI agents      | Claude Code, OpenAI Codex                      |
| Cloud / CLI    | AWS CLI v2, GitHub CLI                         |
| Build          | Task (taskfile.dev), Make, Wails                |
| Data           | jq, yq, postgresql-client, sqlite3             |
| Network        | curl, wget, nmap, tcpdump, netcat, traceroute  |
| Shell          | Zsh + Oh My Zsh (af-magic theme), fzf, ripgrep |

## Network Sandboxing

The container includes a firewall script (`init-firewall.sh`) that restricts outbound traffic to an allowlist:

- GitHub (API, web, git)
- npm registry
- Anthropic API
- VS Code Marketplace

Run inside the container:

```bash
sudo /usr/local/bin/init-firewall.sh
```

## Shared Docker Network

To connect project databases across containers:

```bash
./shared-network.sh
```

This creates a `shared` Docker network and connects `kratos-db`, `gorehab-db`, `schaltapp-db`, and `polasight-db` to it.

## Port Mappings

Each project gets a dedicated port range with three ports (web, API, extra):

| Slot | Web  | API  | Extra |
| ---- | ---- | ---- | ----- |
| 1    | 3010 | 8010 | 8011  |
| 2    | 3020 | 8020 | 8022  |
| 3    | 3030 | 8030 | 8031  |
| 4    | 3040 | 8040 | 8041  |
| 5    | 3050 | 8050 | 8051  |
| 6    | 3060 | 8060 | 8061  |
| 7    | 3070 | 8070 | 8071  |
| 8    | 3080 | 8080 | 8081  |
| 9    | 3090 | 8090 | 8091  |
| 10   | 4000 | 9000 | 9001  |
| 11   | 4010 | 9010 | 9011  |

## Host Mounts

The container bind-mounts the following from the host:

- `~/workspace` — project source code
- `~/.ssh` — SSH keys (read-only)
- `~/.claude` — Claude Code auth and config
- `~/.aws` — AWS credentials
- `~/.gitconfig` — Git configuration
- `~/.zsh_history` — shared shell history
