# Docker AIServer Connection Fix - Version 2

## Problem

Ebenezer container was unable to connect to AIServer, showing this error repeatedly:

```
[error] TcpClientSocket(AISocket)::Connect: failed to connect: Connection refused
[error] EbenezerApp::AISocketConnect: Failed to connect to AI server (zone 0) (127.0.0.1:10020)
[error] EbenezerApp::OnInitDialog: failed to connect to the AIServer
```

## Root Cause

### Why was Ebenezer trying to connect to 127.0.0.1?

In Docker, `127.0.0.1` refers to the container itself, not the host or other containers. The AIServer runs in a separate container, so Ebenezer needs to use the Docker service name (`aiserver`) to connect.

**The problem had two parts:**

1. **Old configuration persisting in volumes**: Users who ran the containers before might have had old `Ebenezer.ini` files in their Docker volumes with `IP=127.0.0.1`

2. **Previous fix didn't work reliably**: The sed-based approach had issues:
   - Only ran if `AI_SERVER_IP` environment variable was set
   - Pattern matching was fragile and could fail
   - Didn't guarantee updates on every startup

## Solution

### New Approach: AWK-based Section-Aware Replacement

The entrypoint script now uses AWK to reliably update the AI_SERVER IP configuration:

```bash
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
```

### How It Works

1. **Default Value**: Uses `${AI_SERVER_IP:-aiserver}` to default to `aiserver` if env var not set
2. **Section-Specific**: AWK script only modifies `IP=` lines within `[AI_SERVER]` section
3. **Every Startup**: Runs on every container start, fixing old configs automatically
4. **Visible Output**: Prints "Updating AI_SERVER IP to: aiserver" so you can verify

### AWK Script Breakdown

```awk
/^\[AI_SERVER\]/ { in_section=1; print; next }    # Start of [AI_SERVER] section
/^\[/ && in_section { in_section=0 }               # End when next section starts
in_section && /^IP=/ { print "IP=" ip; next }      # Replace IP= in this section
{ print }                                           # Print all other lines unchanged
```

## Why AWK Instead of Sed?

| Feature | Sed (old) | AWK (new) |
|---------|-----------|-----------|
| Section-aware | ❌ Pattern `/\[AI_SERVER\]/,/^\[/` can fail | ✅ State machine tracks sections |
| Default value | ❌ Requires env var to be set | ✅ Uses `${VAR:-default}` |
| Reliability | ❌ Pattern matching fragile | ✅ Predictable state machine |
| Works every time | ❌ Only if env var set | ✅ Always runs |
| Other IP= lines | ⚠️ Could modify wrong sections | ✅ Only modifies [AI_SERVER] section |

## Configuration Files Changed

### 1. docker/server/entrypoint.sh

**Old code (lines 38-45):**
```bash
if [ ! -z "${AI_SERVER_IP}" ]; then
    sed -i "s/^IP=.*/IP=${AI_SERVER_IP}/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
elif grep -q "\[AI_SERVER\]" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null; then
    sed -i "/\[AI_SERVER\]/,/^\[/ s/^IP=.*/IP=aiserver/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
fi
```

**New code:**
```bash
if grep -q "\[AI_SERVER\]" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null; then
    AI_SERVER_TARGET="${AI_SERVER_IP:-aiserver}"
    echo "Updating AI_SERVER IP to: ${AI_SERVER_TARGET}"
    
    awk -v ip="${AI_SERVER_TARGET}" '
        /^\[AI_SERVER\]/ { in_section=1; print; next }
        /^\[/ && in_section { in_section=0 }
        in_section && /^IP=/ { print "IP=" ip; next }
        { print }
    ' "${BIN_DIR}/${CONFIG_FILE}" > "${BIN_DIR}/${CONFIG_FILE}.tmp" && \
    mv "${BIN_DIR}/${CONFIG_FILE}.tmp" "${BIN_DIR}/${CONFIG_FILE}"
fi
```

## Test Cases

### Test Case 1: Fresh Install
**Setup:** No existing volume, clean install

**Expected:**
1. Template copied with `IP=aiserver`
2. AWK script updates it (no change needed)
3. Ebenezer connects successfully

**Verification:**
```bash
docker compose up -d
docker compose logs ebenezer | grep "Updating AI_SERVER"
# Should show: Updating AI_SERVER IP to: aiserver

docker compose logs ebenezer | grep "Connected to AI"
# Should show successful connection
```

### Test Case 2: Old Volume with 127.0.0.1
**Setup:** Existing volume has `IP=127.0.0.1` in Ebenezer.ini

**Expected:**
1. Container starts
2. AWK script detects [AI_SERVER] section
3. Updates `IP=127.0.0.1` to `IP=aiserver`
4. Ebenezer connects successfully

**Verification:**
```bash
# Before fix - verify old config
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 1 AI_SERVER
# Might show: IP=127.0.0.1

# Restart container
docker compose restart ebenezer

# After fix
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 1 AI_SERVER
# Should show: IP=aiserver

docker compose logs ebenezer | tail -20
# Should show successful connection, no errors
```

### Test Case 3: Custom AI_SERVER_IP
**Setup:** User sets custom AI server in `.env` file

**.env:**
```bash
AI_SERVER_IP=my-custom-aiserver
```

**Expected:**
1. Container starts
2. AWK script uses custom value
3. Config updated to `IP=my-custom-aiserver`

**Verification:**
```bash
docker compose up -d
docker compose logs ebenezer | grep "Updating AI_SERVER"
# Should show: Updating AI_SERVER IP to: my-custom-aiserver

docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 1 AI_SERVER
# Should show: IP=my-custom-aiserver
```

## Testing Instructions

### For Users with Existing Installations

If you already have containers running with the old configuration:

```bash
# Option 1: Just restart (volume preserved, config auto-fixed)
docker compose restart ebenezer
docker compose logs -f ebenezer

# Option 2: Clean restart (removes volumes)
docker compose down -v
cd docker
./start_all.sh  # or start_all.ps1 on Windows
docker compose logs -f ebenezer
```

### Expected Log Output

**Success indicators:**
```
Starting Ebenezer...
Updating AI_SERVER IP to: aiserver
[info] Ebenezer logger configured
[info] TcpServerSocketManager(EbenezerSocketManager)::Listen: initialized port=15001
[info] Connected to AI server (zone 0)
[info] Map file loaded
```

**What you should NOT see:**
```
[error] TcpClientSocket(AISocket)::Connect: failed to connect: Connection refused
[error] Failed to connect to AI server (zone 0) (127.0.0.1:10020)
```

### Manual Verification

Check the actual config file inside the container:

```bash
# View AI_SERVER section
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 2 "\[AI_SERVER\]"
```

Expected output:
```ini
[AI_SERVER]
IP=aiserver
```

## Environment Variables

The fix works with or without environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_SERVER_IP` | `aiserver` | Hostname or IP of AI server container |

**In docker-compose.yaml:**
```yaml
ebenezer:
  environment:
    - AI_SERVER_IP=${AI_SERVER_IP:-aiserver}
```

**In .env or default.env:**
```bash
AI_SERVER_IP=aiserver
```

## Benefits of This Fix

1. **✅ Always Works**: No dependency on environment variables being set
2. **✅ Self-Healing**: Automatically fixes old/incorrect configurations
3. **✅ Section-Safe**: Only modifies the correct section, won't break other configs
4. **✅ Transparent**: Logs what it's doing for debugging
5. **✅ Backwards Compatible**: Works with existing templates and configs
6. **✅ User-Friendly**: No manual intervention needed

## Troubleshooting

### Issue: Still getting connection refused

**Check:**
1. Is AIServer container running?
   ```bash
   docker compose ps aiserver
   ```

2. Is AIServer listening on port 10020?
   ```bash
   docker compose logs aiserver | grep "initialized port"
   ```

3. Is the config actually updated?
   ```bash
   docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 2 AI_SERVER
   ```

4. Check network connectivity:
   ```bash
   docker compose exec ebenezer ping -c 3 aiserver
   ```

### Issue: Config not updating

**Check:**
1. Is the entrypoint script running?
   ```bash
   docker compose logs ebenezer | grep "Updating AI_SERVER"
   ```

2. Does the config file have the [AI_SERVER] section?
   ```bash
   docker compose exec ebenezer grep "\[AI_SERVER\]" /app/bin/Ebenezer.ini
   ```

3. Check entrypoint.sh permissions:
   ```bash
   docker compose exec ebenezer ls -la /app/entrypoint.sh
   ```

## Related Files

- `docker/server/entrypoint.sh` - Main startup script with the fix
- `docker/server/Ebenezer.ini` - Configuration template
- `docker-compose.yaml` - Service definitions
- `default.env` / `.env` - Environment variables

## Summary

This fix ensures that Ebenezer will ALWAYS connect to the correct AIServer hostname, regardless of:
- Whether volumes exist from previous runs
- Whether environment variables are set
- What the old configuration contained

The AWK-based approach is more reliable, more transparent, and more maintainable than the previous sed-based solution.
