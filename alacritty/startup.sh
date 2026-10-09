#!/bin/bash
# Alacritty startup — the equivalent of wezterm/startup.lua.
#
# Runs as the configured [terminal.shell]. The first shell of an Alacritty
# process opens one native macOS tab per entry in projects.sh (gitignored, see
# projects.example.sh). Every later shell in the same process (Cmd+T, Cmd+N)
# just becomes a plain login shell.
#
# Usage:
#   startup.sh [GROUP]            launch only GROUP in this Alacritty instance
#   ALACRITTY_WINDOW_GROUP=A,B    launch only these groups (like WEZTERM_WINDOW_GROUP)
#
# Groups map to WezTerm windows: the first selected group is opened in the
# current Alacritty process, every further group in its own Alacritty instance
# (= its own window with its own tabs).

set -u

CONFIG_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
LOGIN_SHELL="${SHELL:-/bin/zsh}"

ALACRITTY_BIN="$(command -v alacritty 2>/dev/null || true)"
[ -n "$ALACRITTY_BIN" ] || ALACRITTY_BIN=/Applications/Alacritty.app/Contents/MacOS/alacritty

# IPC to the running Alacritty. The socket refuses (or drops) messages while a
# window is still being created, so retry a few times.
msg() {
  local try
  for try in 1 2 3 4 5 6 7 8 9 10; do
    "$ALACRITTY_BIN" msg "$@" 2>/dev/null && return 0
    sleep 0.2
  done
  echo "alacritty msg $1 failed: $*" >&2
  return 1
}

# Alacritty's pid is encoded in the socket name (Alacritty-<pid>.sock).
ALACRITTY_PID="$(basename "${ALACRITTY_SOCKET:-}" .sock)"
ALACRITTY_PID="${ALACRITTY_PID##*-}"

shell_count() {
  pgrep -P "$ALACRITTY_PID" 2>/dev/null | wc -l | tr -d ' '
}

# create-window, then wait until its shell process exists before returning —
# otherwise the next create-window is silently lost.
create_tab() {
  local before after i
  before="$(shell_count)"
  msg create-window "$@" || return 1
  for i in $(seq 1 30); do
    after="$(shell_count)"
    [ "$after" -gt "$before" ] && return 0
    sleep 0.1
  done
  return 0
}

# ---------------------------------------------------------------------------
# Only the first shell of a process builds tabs. ALACRITTY_SOCKET is unique per
# process, so use it as the marker key.
# ---------------------------------------------------------------------------
if [ -z "${ALACRITTY_SOCKET:-}" ] || [ ! -x "$ALACRITTY_BIN" ]; then
  exec "$LOGIN_SHELL" -l
fi

MARKER_DIR="${TMPDIR:-/tmp}"
MARKER="$MARKER_DIR/alacritty-tabs-$(basename "$ALACRITTY_SOCKET")"
find "$MARKER_DIR" -maxdepth 1 -name 'alacritty-tabs-*' -mtime +1 -delete 2>/dev/null

if [ -e "$MARKER" ]; then
  exec "$LOGIN_SHELL" -l
fi
touch "$MARKER"

# ---------------------------------------------------------------------------
# Tab definition DSL used by projects.sh
# ---------------------------------------------------------------------------
GROUP_NAMES=()
CURRENT_GROUP=""
TAB_GROUP=()
TAB_NAME=()
TAB_CWD=()
TAB_CMD=()
TAB_DYN=()   # 1 = title follows the program (tmux sets it), 0 = fixed name

group() {
  CURRENT_GROUP="$1"
  GROUP_NAMES+=("$1")
}

add_tab() { # name cwd cmd [dynamic]
  [ -n "$CURRENT_GROUP" ] || group "Default"
  TAB_GROUP+=("$CURRENT_GROUP")
  TAB_NAME+=("$1")
  TAB_CWD+=("$2")
  TAB_CMD+=("$3")
  TAB_DYN+=("${4:-0}")
}

# tab_local NAME [CWD]
tab_local() {
  add_tab "$1" "${2:-$HOME}" ""
}

# tab_docker NAME CWD CONTAINER WORKDIR [USER] [SHELL]
tab_docker() {
  local user="${5:-ai}" shell="${6:-zsh}"
  add_tab "$1" "$2" "docker exec -it -u $user -w $4 $3 $shell -l"
}

# tab_ssh NAME HOST SESSION [WORKDIR]
tab_ssh() {
  local tmux_cmd="tmux new-session -A -s $3"
  [ -n "${4:-}" ] && tmux_cmd="$tmux_cmd -c $4"
  # Dynamic title: tmux sets it to the session name (= tab name), prefixed
  # with ⚙️ / 🔔 while a Claude in that session works / waits for input
  # (server-side Claude Code hook + tmux set-titles).
  add_tab "$1" "$HOME" "ssh $2 -t \"$tmux_cmd\"" 1
}

# tab_herdr NAME HOST
tab_herdr() {
  # herdr --remote: the panes run on HOST, the local herdr draws the UI (and
  # bridges image paste from the Mac clipboard). Needs herdr on the Mac too.
  # Tabs made via `alacritty msg` get Alacritty's bare launchd PATH, not the
  # zsh one, so resolve herdr here and hand the tab an absolute path.
  local bin
  bin="$(command -v herdr 2>/dev/null)"
  if [ -z "$bin" ]; then
    for bin in "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr /usr/local/bin/herdr "$HOME/.cargo/bin/herdr"; do
      [ -x "$bin" ] && break
    done
  fi
  # On failure keep the tab open, or the error vanishes with the tab.
  add_tab "$1" "$HOME" "'$bin' --remote $2 || { rc=\$?; echo; echo \"herdr --remote $2 failed (exit \$rc)\"; read -r -p 'Press Enter to close'; }"
}

if [ -f "$CONFIG_DIR/projects.sh" ]; then
  # shellcheck source=projects.example.sh
  . "$CONFIG_DIR/projects.sh"
else
  echo "projects.sh not found — create it from projects.example.sh" >&2
  group "Default"
  tab_local "Home" "$HOME"
fi

# ---------------------------------------------------------------------------
# Pick the groups to launch
# ---------------------------------------------------------------------------
selected=()
if [ $# -gt 0 ]; then
  selected=("$1")
elif [ -n "${ALACRITTY_WINDOW_GROUP:-}" ]; then
  IFS=',' read -r -a selected <<< "$ALACRITTY_WINDOW_GROUP"
  selected=("${selected[@]// /}")
else
  selected=("${GROUP_NAMES[@]}")
fi

this_group="${selected[0]}"

# Further groups → separate Alacritty instances (separate windows)
for g in "${selected[@]:1}"; do
  open -na Alacritty --args -e "$0" "$g"
done

# ---------------------------------------------------------------------------
# Open the tabs of this group. The first tab reuses the current window; the
# rest are created via IPC and become native tabs (macOS "Prefer tabs").
# ---------------------------------------------------------------------------
if [ "$(defaults read -g AppleWindowTabbingMode 2>/dev/null)" != "always" ] &&
   [ "$(defaults read org.alacritty AppleWindowTabbingMode 2>/dev/null)" != "always" ]; then
  echo "Warning: macOS 'Prefer tabs' is not 'always' — project tabs open as windows." >&2
  echo "Fix:     defaults write org.alacritty AppleWindowTabbingMode -string always" >&2
fi

first_name="" first_cwd="" first_cmd="" first_dyn=0 first_found=0
for i in "${!TAB_NAME[@]}"; do
  [ "${TAB_GROUP[$i]}" = "$this_group" ] || continue

  if [ "$first_found" -eq 0 ]; then
    first_found=1
    first_name="${TAB_NAME[$i]}"
    first_cwd="${TAB_CWD[$i]}"
    first_cmd="${TAB_CMD[$i]}"
    first_dyn="${TAB_DYN[$i]}"
    continue
  fi

  # -T freezes the title for good (Alacritty ignores title escapes afterwards),
  # so dynamic tabs only get the name via window.title, which escapes override.
  if [ "${TAB_DYN[$i]}" = 1 ]; then
    title_args=(-o "window.title=\"${TAB_NAME[$i]}\"")
  else
    title_args=(-T "${TAB_NAME[$i]}")
  fi
  if [ -n "${TAB_CMD[$i]}" ]; then
    create_tab "${title_args[@]}" --working-directory "${TAB_CWD[$i]}" \
      -e bash -lc "${TAB_CMD[$i]}"
  else
    create_tab "${title_args[@]}" --working-directory "${TAB_CWD[$i]}"
  fi
done

if [ "$first_found" -eq 0 ]; then
  echo "No tabs defined for group '$this_group'" >&2
  exec "$LOGIN_SHELL" -l
fi

# Name this window; freeze the title unless the tab is dynamic (same as
# tab:set_title in WezTerm)
dyn_title=false
[ "$first_dyn" = 1 ] && dyn_title=true
msg config -w "${ALACRITTY_WINDOW_ID:--1}" \
  "window.title=\"$first_name\"" "window.dynamic_title=$dyn_title"

cd "$first_cwd" 2>/dev/null || cd "$HOME"
if [ -n "$first_cmd" ]; then
  exec bash -lc "$first_cmd"
fi
exec "$LOGIN_SHELL" -l
