#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo ""
  echo "Create a .env file with:"
  echo "  containers=ai-dev,app1-db,app2-db"
  exit 1
fi

source "$ENV_FILE"

if [ -z "${containers:-}" ]; then
  echo "Error: 'containers' not set in .env"
  echo ""
  echo "Add a comma-separated list of container names:"
  echo "  containers=ai-dev,app1-db,app2-db"
  exit 1
fi

NETWORK="shared"
IFS=',' read -ra CONTAINERS <<< "$containers"

# Create network if it doesn't exist
if ! docker network inspect "$NETWORK" &>/dev/null; then
  echo "Creating network '$NETWORK'..."
  docker network create "$NETWORK"
else
  echo "Network '$NETWORK' already exists."
fi

# Connect containers
for c in "${CONTAINERS[@]}"; do
  if ! docker inspect "$c" &>/dev/null; then
    echo "Container '$c' not found, skipping."
  elif docker network inspect "$NETWORK" --format '{{range .Containers}}{{.Name}} {{end}}' | grep -qw "$c"; then
    echo "Container '$c' already connected."
  else
    echo "Connecting '$c' to '$NETWORK'..."
    docker network connect "$NETWORK" "$c"
  fi
done
