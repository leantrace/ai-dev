#!/usr/bin/env bash
set -euo pipefail

IMAGE="ai-dev"
CONTAINER="ai-dev"

build() {
  docker build \
    --build-arg HOST_UID="$(id -u)" \
    -t "$IMAGE" \
    "$(cd "$(dirname "$0")" && pwd)"
}

start() {
  PORTS=(
    # Slot 1
    -p 3010:3010
    -p 8010:8010
    -p 8011:8011

    # Slot 2
    -p 3020:3020
    -p 8020:8020
    # 8021 is reserved for apple system/com.apple.ftp-proxy
    -p 8022:8022

    # Slot 3
    -p 3030:3030
    -p 8030:8030
    -p 8031:8031

    # Slot 4
    -p 3040:3040
    -p 8040:8040
    -p 8041:8041

    # Slot 5
    -p 3050:3050
    -p 8050:8050
    -p 8051:8051

    # Slot 6
    -p 3060:3060
    -p 8060:8060
    -p 8061:8061

    # Slot 7
    -p 3070:3070
    -p 8070:8070
    -p 8071:8071

    # Slot 8
    -p 3080:3080
    -p 8080:8080
    -p 8081:8081

    # Slot 9
    -p 3090:3090
    -p 8090:8090
    -p 8091:8091

    # Slot 10
    -p 4000:4000
    -p 9000:9000
    -p 9001:9001

    # Slot 11
    -p 4010:4010
    -p 9010:9010
    -p 9011:9011

  )

  docker run -d \
    --name "$CONTAINER" \
    --cap-add NET_ADMIN \
    -it \
    "${PORTS[@]}" \
    -v ".home/.config:/home/ai/.config" \
    -v "${HOME}/workspace:/home/ai/workspace" \
    -v "${HOME}/.ssh:/home/ai/.ssh:ro" \
    -v "${HOME}/.claude:/home/ai/.claude" \
    -v "${HOME}/.kratos:/home/ai/.kratos" \
    -v "${HOME}/.aws:/home/ai/.aws" \
    -v "${HOME}/.zsh_history:/home/ai/.zsh_history" \
    -v "${HOME}/.gitconfig:/home/ai/.gitconfig" \
    -e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}" \
    -e "OPENAI_API_KEY=${OPENAI_API_KEY:-}" \
    "$IMAGE"
  docker attach "$CONTAINER"
}

stop() {
  docker stop "$CONTAINER"
}

shell() {
  if ! docker ps -q -f name="^${CONTAINER}$" | grep -q .; then
    echo "Container '$CONTAINER' is not running. Use '$0 start' first."
    exit 1
  fi
  docker exec -it "$CONTAINER" /bin/zsh
}

remove() {
  docker rm -f "$CONTAINER" 2>/dev/null || true
}

usage() {
  echo "Usage: $0 {build|start|stop|shell|remove}"
  echo ""
  echo "  build   Build the Docker image"
  echo "  start   Start the container and attach"
  echo "  stop    Stop the container"
  echo "  shell   Open an additional shell in the container"
  echo "  remove  Stop and remove the container"
}

case "${1:-}" in
  build)  build  ;;
  start)  start  ;;
  stop)   stop   ;;
  shell)  shell  ;;
  remove) remove ;;
  *)      usage  ;;
esac
