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

Optional terminal configuration that auto-opens project tabs in separate windows, connected via local shell, `docker exec`, or SSH+tmux.

### Setup

```bash
ln -sf ~/workspace/ai-dev/wezterm ~/.config/wezterm
cp wezterm/projects.example.lua wezterm/projects.lua
```

Edit `projects.lua` with your project paths. The file is a list of **windows**, each containing **tabs**:

```lua
return {
  -- Window 1: Local shells
  {
    name = 'Local',
    tabs = {
      { name = 'MyApp', cwd = wezterm.home_dir .. '/workspace/myapp', panes = 3 },
    },
  },

  -- Window 2: Docker dev containers
  {
    name = 'Docker',
    tabs = {
      {
        name = 'MyApp',
        cwd = wezterm.home_dir .. '/workspace/myapp',
        panes = 3,
        devcontainer = {
          container = 'ai-dev',
          workdir = '/home/ai/workspace/myapp',
          user = 'ai',
          shell = 'zsh',
        },
      },
    },
  },

  -- Window 3: SSH + tmux sessions
  {
    name = 'Server',
    tabs = {
      { name = 'Main', ssh = { host = 'myserver', session = 'main', workdir = '/home/user/project' } },
    },
  },
}
```

- **panes**: `1` = single, `2` = left/right, `3` = left + right + bottom-right
- **devcontainer**: connects via `docker exec` — omit for local tabs
- **ssh**: connects via `ssh <host> -t "tmux new-session -A -s <session>"` — `workdir` sets the directory for new sessions

### Selective Window Launch

Set `WEZTERM_WINDOW_GROUP` to launch specific windows without closing existing ones:

```bash
WEZTERM_WINDOW_GROUP=Local wezterm start        # only local tabs
WEZTERM_WINDOW_GROUP=Docker wezterm start       # only docker tabs
WEZTERM_WINDOW_GROUP=Local,Server wezterm start # multiple groups
wezterm start                                   # all windows (default)
```

`projects.lua` is gitignored — it contains your private project names and paths.

| File                          | Committed | Description                     |
| ----------------------------- | --------- | ------------------------------- |
| `wezterm/wezterm.lua`         | Yes       | Main config (theme, keys, font) |
| `wezterm/startup.lua`         | Yes       | Tab/pane layout engine          |
| `wezterm/projects.example.lua`| Yes       | Example project config          |
| `wezterm/projects.lua`        | No        | Your project tabs (private)     |

## Alacritty

Same idea as the WezTerm setup, for [Alacritty](https://alacritty.org) (0.17+). Alacritty has no built-in tabs or panes, so `startup.sh` opens one **native macOS tab** per project entry via `alacritty msg create-window`. Tabs get fixed names and connect via local shell, `docker exec`, or SSH+tmux — exactly like the WezTerm tabs.

### Setup

```bash
ln -sfn ~/workspace/ai-dev/alacritty ~/.config/alacritty
cp alacritty/projects.example.sh alacritty/projects.sh
```

macOS must open new windows as tabs. Either set System Settings → Desktop & Dock → *Prefer tabs when opening documents* to **Always**, or enable it for Alacritty only:

```bash
defaults write org.alacritty AppleWindowTabbingMode -string always
```

Edit `projects.sh` — it is plain bash, sourced by `startup.sh`:

```bash
# Window 1: Local shells
group "Local"
tab_local "MyApp" "$HOME/workspace/myapp"

# Window 2: Docker dev containers
group "Docker"
tab_docker "MyApp" "$HOME/workspace/myapp" ai-dev /home/ai/workspace/myapp ai zsh

# Window 3: SSH + tmux sessions
group "Server"
tab_ssh "Main" myserver main /home/user/project
```

- **group**: one Alacritty window (the first group reuses the launching instance, every further group starts its own Alacritty instance)
- **tab_local** `NAME [CWD]`: login shell
- **tab_docker** `NAME CWD CONTAINER WORKDIR [USER] [SHELL]`: `docker exec` into a dev container
- **tab_ssh** `NAME HOST SESSION [WORKDIR]`: `ssh HOST -t "tmux new-session -A -s SESSION"`
- there is no `panes` option — Alacritty cannot split; for SSH tabs tmux on the server does that anyway

Only the first shell of an Alacritty process builds the tabs; `Cmd+T` / `Cmd+N` open plain login shells. Tab keys: `Cmd+1..9`, `Cmd+Shift+[` / `]`, `Ctrl+Tab`.

### Selective Window Launch

```bash
ALACRITTY_WINDOW_GROUP=Local alacritty         # only local tabs
ALACRITTY_WINDOW_GROUP=Local,Server alacritty  # multiple groups
alacritty                                      # all groups (default)
```

`projects.sh` is gitignored — it contains your private project names and paths.

| File                            | Committed | Description                           |
| ------------------------------- | --------- | ------------------------------------- |
| `alacritty/alacritty.toml`      | Yes       | Main config (theme, keys, font)       |
| `alacritty/themes/adventure.toml` | Yes     | Color scheme (WezTerm's `Adventure`)  |
| `alacritty/startup.sh`          | Yes       | Tab engine (native macOS tabs)        |
| `alacritty/projects.example.sh` | Yes       | Example project config                |
| `alacritty/projects.sh`         | No        | Your project tabs (private)           |

## Host Mounts

The container bind-mounts the following from the host:

- `~/workspace` — project source code
- `~/.ssh` — SSH keys (read-only)
- `~/.claude` — Claude Code auth and config
- `~/.aws` — AWS credentials
- `~/.gitconfig` — Git configuration
- `~/.zsh_history` — shared shell history
