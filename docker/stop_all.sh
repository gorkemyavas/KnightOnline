#!/bin/bash
# Script to stop all OpenKO services

set -e

SCRIPT_PATH="$0"

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

echo "Stopping all OpenKO services..."
docker compose down

echo "All services stopped successfully!"
