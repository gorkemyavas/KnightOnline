#!/bin/bash
# Startup script for OpenKO servers
# This script copies configuration templates if they don't exist

set -e

# Configuration directory
CONFIG_DIR="/app/config"
BIN_DIR="/app/bin"

# Server name (passed as first argument or detected from binary)
SERVER_NAME="${1:-Ebenezer}"
CONFIG_FILE="${SERVER_NAME}.ini"

# Copy config template if it doesn't exist in the volume
if [ ! -f "${BIN_DIR}/${CONFIG_FILE}" ]; then
    if [ -f "${CONFIG_DIR}/${CONFIG_FILE}" ]; then
        echo "Copying ${CONFIG_FILE} from template..."
        cp "${CONFIG_DIR}/${CONFIG_FILE}" "${BIN_DIR}/${CONFIG_FILE}"
    else
        echo "Warning: No configuration template found for ${CONFIG_FILE}"
    fi
fi

# Update ODBC configuration with environment variables if set
if [ ! -z "${GAME_DB_NAME}" ]; then
    sed -i "s/GAME_DSN=.*/GAME_DSN=${GAME_DB_NAME}/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
fi

if [ ! -z "${GAME_DB_USER}" ]; then
    sed -i "s/GAME_UID=.*/GAME_UID=${GAME_DB_USER}/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
fi

if [ ! -z "${GAME_DB_PASS}" ]; then
    sed -i "s/GAME_PWD=.*/GAME_PWD=${GAME_DB_PASS}/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
fi

# Update AI_SERVER IP configuration (for Ebenezer)
# Default to 'aiserver' hostname for Docker networking
# This runs EVERY startup to ensure config is correct, even if volume persists
if grep -q "\[AI_SERVER\]" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null; then
    # Set AI_SERVER_IP, defaulting to 'aiserver' if not set
    AI_SERVER_TARGET="${AI_SERVER_IP:-aiserver}"
    echo "Updating AI_SERVER IP to: ${AI_SERVER_TARGET}"
    
    # Use awk for more reliable section-specific replacement
    awk -v ip="${AI_SERVER_TARGET}" '
        /^\[AI_SERVER\]/ { in_section=1; print; next }
        /^\[/ && in_section { in_section=0 }
        in_section && /^IP=/ { print "IP=" ip; next }
        { print }
    ' "${BIN_DIR}/${CONFIG_FILE}" > "${BIN_DIR}/${CONFIG_FILE}.tmp" && \
    mv "${BIN_DIR}/${CONFIG_FILE}.tmp" "${BIN_DIR}/${CONFIG_FILE}"
fi

echo "Starting ${SERVER_NAME}..."
cd "${BIN_DIR}"

# Execute the server without passing positional arguments
# Servers expect zero positional arguments and read config from current directory
exec "./${SERVER_NAME}"
