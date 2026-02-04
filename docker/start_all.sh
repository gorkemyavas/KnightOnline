#!/bin/bash
# Script to start all OpenKO services with Docker
# This includes database and all game servers

set -e

export DOCKER_DEFAULT_PLATFORM=linux/amd64

# Find script location
SCRIPT_PATH="$0"

# Resolve symlink
if [ -h "$SCRIPT_PATH" ] && command -v readlink >/dev/null 2>&1 ; then
    LINK_TARGET=$(readlink "$SCRIPT_PATH")
    if [ "${LINK_TARGET#/}" != "$LINK_TARGET" ]; then
        SCRIPT_PATH="$LINK_TARGET"
    else
        LINK_DIR=$(dirname "$SCRIPT_PATH")
        SCRIPT_PATH="$LINK_DIR/$LINK_TARGET"
    fi
fi
SCRIPT_DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd)

cd "$SCRIPT_DIR" || { echo "Failed to change to directory: $SCRIPT_DIR"; exit 1; }
cd ..
echo "Working directory: $(pwd)"

echo "Building and starting all OpenKO services..."

# Start database first
docker compose up --build -d sqlserver
echo "Waiting for SQL Server to be healthy..."
docker compose up --build -d kodb-util

# Initialize database
echo "Initializing database..."
sleep 5
docker exec knightonline-kodb-util-1 /usr/local/bin/cleanImport.sh

# Start all game servers
echo "Starting game servers..."
docker compose up --build -d aiserver aujard ebenezer itemmanager versionmanager

echo ""
echo "All services started successfully!"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop services: docker compose down"
echo "To stop and remove all data: docker compose down -v"
