# Copy this file to projects.sh and customize with your project paths.
# projects.sh is gitignored. It is sourced by startup.sh (bash).
#
# Structure: groups (= windows), each with tabs. Every group after the first
# opens in its own Alacritty instance/window.
#
#   group      NAME
#   tab_local  NAME [CWD]                                   plain login shell
#   tab_docker NAME CWD CONTAINER WORKDIR [USER] [SHELL]    docker exec into a dev container
#   tab_ssh    NAME HOST SESSION [WORKDIR]                  ssh HOST -t "tmux new-session -A -s SESSION"
#   tab_herdr  NAME HOST                                    herdr --remote HOST (needs herdr on the Mac)
#
# Alacritty has no panes — the WezTerm `panes` option has no equivalent here.
# For SSH tabs that never mattered: tmux on the server handles the splits.

# Window 1: Local shells
group "Local"
tab_local "App1"    "$HOME/workspace/app1"
tab_local "Scripts" "$HOME/.local/share/scripts"

# Window 2: Docker dev containers
group "Docker"
tab_docker "App2" "$HOME/workspace/app2" ai-dev /home/ai/workspace/app2 ai zsh

# Window 3: SSH + tmux sessions
group "Server"
tab_ssh "Main" myserver main
tab_herdr "Herdr" myserver
