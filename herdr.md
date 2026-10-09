# herdr cheatsheet

herdr is a terminal workspace manager for AI coding agents. Like tmux, a server keeps shells and
agents running after you disconnect, and you reattach later. Unlike tmux, it has a sidebar of
**workspaces → tabs → panes** and shows each agent's state (working, waiting, done).

Installed on **sampo** (`<sampo-ip>`, user `ai`) in `~/.local/bin/herdr`.
Docs: https://herdr.dev/docs/how-to-work/

## The mental model

- **tmux setup (gazorpazorp):** one Alacritty tab per tmux session (Slot 1, Slot 2, …).
- **herdr setup (sampo):** one Alacritty window. Projects are herdr **workspaces** inside it.

## Start, detach, stop

```bash
ssh ai@<sampo-ip>      # or: ssh sampo, once the alias exists
herdr                    # start the session, or reattach to it
```

| Command | Effect |
|---|---|
| `herdr` | Start or reattach to the persistent session |
| `Ctrl+b q` | **Detach.** Everything keeps running |
| `herdr --session <name>` | Use or create a named session |
| `herdr status` | Show client and server status |
| `herdr server stop` | End the session and stop all panes |
| `herdr update` | Install the latest version |

## Keys

The prefix is `Ctrl+b`, the same as tmux.

### Workspaces (one per project)

| Key | Action |
|---|---|
| `Ctrl+b Shift+n` | New workspace |
| `Ctrl+b w` | Workspace picker |
| `Ctrl+b g` | Go to … |
| `Ctrl+b Shift+w` | Rename workspace |
| `Ctrl+b Shift+d` | Close workspace |
| `Ctrl+b b` | Show or hide the sidebar |

### Tabs

| Key | Action |
|---|---|
| `Ctrl+b c` | New tab |
| `Ctrl+b n` / `Ctrl+b p` | Next / previous tab |
| `Ctrl+b 1..9` | Go to tab 1–9 |
| `Ctrl+b Shift+t` | Rename tab |
| `Ctrl+b Shift+x` | Close tab |

### Panes

| Key | Action |
|---|---|
| `Ctrl+b v` | Split side by side |
| `Ctrl+b -` | Split top and bottom |
| `Ctrl+b h` `j` `k` `l` | Move to the pane left / down / up / right |
| `Ctrl+b Tab` / `Ctrl+b Shift+Tab` | Next / previous pane |
| `Ctrl+b z` | Zoom a pane |
| `Ctrl+b r` | Resize mode |
| `Ctrl+b Shift+p` | Rename pane |
| `Ctrl+b x` | Close pane |
| `Ctrl+b e` | Edit the scrollback in an editor |

### Other

| Key | Action |
|---|---|
| `Ctrl+b ?` | Help |
| `Ctrl+b s` | Settings |
| `Ctrl+b o` | Jump to the pane that sent the notification |
| `Ctrl+b Shift+r` | Reload the config |

## Two ways to connect from the Mac

1. **`ssh sampo -t herdr`.** herdr runs entirely on sampo. Nothing to install on the Mac. Works
   like the tmux tabs today.
2. **`herdr --remote sampo`.** You install herdr on the Mac too. The panes still run on sampo, but
   the Mac draws the screen. This adds **pasting images from the Mac clipboard** into Claude
   (`Ctrl+v`).

For option 2 or for several machines in one window: `herdr machine add sampo --label sampo`.

## Daily use

```bash
herdr                         # attach
# Ctrl+b Shift+n              → new workspace for a project
cd ~/workspace/<project>
claude                        # or claude-isolated (= --dangerously-skip-permissions)
# Ctrl+b q                    → detach, close the laptop, come back later
```

## Config

- File: `~/.config/herdr/config.toml`
- Print every default with comments: `herdr --default-config`
- Themes: catppuccin, tokyo-night, dracula, nord, gruvbox, one-dark, solarized, kanagawa,
  rose-pine, vesper, terminal

```toml
[theme]
name = "tokyo-night"

[keys]
prefix = "ctrl+b"
```

After you edit the file, press `Ctrl+b Shift+r` or run `herdr server reload-config`.

## Claude integration

`herdr integration install` connects Claude Code to herdr, so the sidebar shows when each Claude is
working or waiting for you. Check it with `herdr integration status`.

## Optional setup, not done yet

- **SSH alias** in `~/.ssh/config`, on the Mac and on gazorpazorp:

  ```
  Host sampo
    HostName <sampo-ip>
    User ai
  ```

- **A `tab_herdr NAME HOST` helper** in `alacritty/startup.sh`, next to `tab_ssh`. With it,
  `group "Sampo"` plus `tab_herdr "Sampo" sampo` in `projects.sh` opens one Alacritty window
  attached to herdr.
