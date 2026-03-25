#!/bin/bash
set -e

NETWORK="shared"
CONTAINERS=("kratos-db" "gorehab-db" "schaltapp-db" "polasight-db")

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
