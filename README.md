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

This creates a `shared` Docker network and connects the database containers listed in `.env`.

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

## WezTerm

Optional terminal configuration that auto-opens project tabs connected to the `ai-dev` container via `docker exec`.

### Setup

```bash
ln -sf ~/workspace/ai-dev/wezterm ~/.config/wezterm
cp wezterm/projects.example.lua wezterm/projects.lua
```

Edit `projects.lua` with your project paths. Each entry defines a tab:

```lua
{
  name = 'MyApp',
  cwd = wezterm.home_dir .. '/workspace/myapp',
  panes = 3,                    -- 1 = single, 2 = left/right, 3 = left + right + bottom-right
  devcontainer = {              -- omit for local-only tabs
    container = 'ai-dev',
    workdir = '/home/ai/workspace/myapp',
    user = 'ai',
    shell = 'zsh',
  },
}
```

`projects.lua` is gitignored — it contains your private project names and paths.

| File                          | Committed | Description                     |
| ----------------------------- | --------- | ------------------------------- |
| `wezterm/wezterm.lua`         | Yes       | Main config (theme, keys, font) |
| `wezterm/startup.lua`         | Yes       | Tab/pane layout engine          |
| `wezterm/projects.example.lua`| Yes       | Example project config          |
| `wezterm/projects.lua`        | No        | Your project tabs (private)     |

## Host Mounts

The container bind-mounts the following from the host:

- `~/workspace` — project source code
- `~/.ssh` — SSH keys (read-only)
- `~/.claude` — Claude Code auth and config
- `~/.aws` — AWS credentials
- `~/.gitconfig` — Git configuration
- `~/.zsh_history` — shared shell history
