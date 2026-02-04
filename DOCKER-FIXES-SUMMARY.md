# Docker Setup - Complete Fix Summary

This document summarizes all the fixes applied to make the OpenKO project fully functional in Docker.

## Issues Fixed

### 1. Microsoft ODBC GPG Key Error ✅
**File:** `DOCKER-BUILD-FIX.md`

**Problem:**
```
W: GPG error: NO_PUBKEY EB3E94ADBE1229CF
E: The repository is not signed
```

**Solution:**
- Updated from deprecated `apt-key add` to modern `gpg --dearmor`
- Added `signed-by` to repository configuration
- Now compatible with Ubuntu 24.04

**Files Changed:**
- `docker/server/Dockerfile` - GPG key installation method

---

### 2. Entrypoint Script Line Endings ✅
**File:** `DOCKER-ENTRYPOINT-FIX.md`

**Problem:**
```
exec /app/entrypoint.sh: no such file or directory
```

**Solution:**
- Windows line endings (CRLF) broke shebang interpreter
- Added `sed -i 's/\r$//'` to remove carriage returns
- Script now works regardless of line endings

**Files Changed:**
- `docker/server/Dockerfile` - Added line ending cleanup

---

### 3. Server Positional Arguments ✅
**File:** `DOCKER-SERVER-ARGS-FIX.md`

**Problem:**
```
[error] AppThread::parse_commandline: Zero positional arguments expected
```

**Solution:**
- Servers don't accept positional arguments
- Changed entrypoint from `exec "./${SERVER_NAME}" "$@"` to `exec "./${SERVER_NAME}"`
- Servers read config from current directory automatically

**Files Changed:**
- `docker/server/entrypoint.sh` - Removed `"$@"` from exec command

---

### 4. MAP Directory Path ✅
**File:** `DOCKER-MAP-PATH-FIX.md`

**Problem:**
```
[error] EbenezerApp::MapFileLoad: File Open Fail - ../MAP/karus_0730.smd
[error] AIServerApp::MapFileLoad: Failed to open file: ../MAP/karus_0730.smd
```

**Solution:**
- Servers use `../MAP/` relative path (expecting `/app/MAP/`)
- Files were at `/app/bin/MAP/`
- Created symlinks: `/app/MAP -> /app/bin/MAP` and `/app/QUESTS -> /app/bin/QUESTS`

**Files Changed:**
- `docker/server/Dockerfile` - Added symlink creation

---

### 5. AIServer Connection (Version 1) ✅
**File:** `DOCKER-AISERVER-CONNECTION-FIX.md`

**Problem:**
```
[error] Failed to connect to AI server (zone 0) (127.0.0.1:10020)
Connection refused
```

**Solution (Initial):**
- Docker containers can't use `127.0.0.1` to connect to other containers
- Need to use service name: `aiserver`
- Added environment variable support
- Added config update in entrypoint

**Files Changed:**
- `docker/server/entrypoint.sh` - Added AI_SERVER IP update (sed-based)
- `default.env` - Added AI_SERVER_IP variable
- `.env.example` - Added documentation
- `docker-compose.yaml` - Added environment variable

---

### 6. AIServer Connection (Version 2 - Final Fix) ✅
**File:** `DOCKER-AISERVER-FIX-V2.md`

**Problem:**
Version 1 fix didn't work reliably:
- Only ran if environment variable was set
- Sed pattern matching was fragile
- Old volumes weren't being fixed

**Solution (Final):**
- Replaced sed with AWK for section-aware config updates
- Uses `${AI_SERVER_IP:-aiserver}` to always have a default
- Runs on EVERY container startup
- Prints "Updating AI_SERVER IP to: aiserver" for visibility
- Works with or without environment variables
- Automatically fixes old configurations

**Files Changed:**
- `docker/server/entrypoint.sh` - Rewritten with AWK-based replacement

---

## Windows Script Support ✅

**File:** `WINDOWS-SCRIPT-REHBERI.md`

Added PowerShell (.ps1) versions of all Docker management scripts:
- `start_all.ps1`
- `stop_all.ps1`
- `clean_setup.ps1`
- `reset_database.ps1`
- `resume_containers.ps1`
- `stop_containers.ps1`
- `uninstall.ps1`

Features:
- Colorful output
- Better error handling
- User-friendly messages
- Automatic directory management

---

## Architecture & Documentation ✅

**Files:**
- `DOCKER-KURULUM.md` - Turkish installation guide (306 lines)
- `DOCKER-SETUP.md` - English installation guide (306 lines)
- `DOCKER-QUICKREF.md` - Quick reference (bilingual)
- `DOCKER-ARCHITECTURE.md` - System architecture diagrams
- `DOCKER-IMPLEMENTATION-SUMMARY.md` - Implementation summary

---

## Complete File List

### New Files (20+)
**Docker Infrastructure:**
- `docker/server/Dockerfile` (multi-stage build)
- `docker/server/entrypoint.sh` (container startup script)
- `docker/server/*.ini` (4 config templates)
- `docker/start_all.sh|.cmd|.ps1` (start scripts - 3 versions)
- `docker/stop_all.sh|.cmd|.ps1` (stop scripts - 3 versions)
- `docker/clean_setup.sh|.cmd|.ps1`
- `docker/reset_database.sh|.cmd|.ps1`
- `docker/resume_containers.sh|.cmd|.ps1`
- `docker/stop_containers.sh|.cmd|.ps1`
- `docker/uninstall.sh|.cmd|.ps1`

**Documentation (13 files):**
- `DOCKER-KURULUM.md`
- `DOCKER-SETUP.md`
- `DOCKER-QUICKREF.md`
- `DOCKER-ARCHITECTURE.md`
- `DOCKER-IMPLEMENTATION-SUMMARY.md`
- `DOCKER-BUILD-FIX.md`
- `DOCKER-ENTRYPOINT-FIX.md`
- `DOCKER-SERVER-ARGS-FIX.md`
- `DOCKER-MAP-PATH-FIX.md`
- `DOCKER-AISERVER-CONNECTION-FIX.md`
- `DOCKER-AISERVER-FIX-V2.md`
- `DOCKER-FIXES-SUMMARY.md` (this file)
- `WINDOWS-SCRIPT-REHBERI.md`

**Configuration:**
- `.env.example`
- `.dockerignore`

### Modified Files (4)
- `docker-compose.yaml` - Added 5 game server services
- `default.env` - Added server ports and AI_SERVER_IP
- `README.md` - Added Docker setup section
- `docker/README.MD` - Updated with new features

---

## Total Lines of Code/Documentation

- **New Code**: ~1,500 lines (Dockerfile, scripts, configs)
- **Documentation**: ~3,000+ lines (Turkish + English)
- **Total**: ~4,500+ lines

---

## How to Use

### Quick Start

**Linux/macOS:**
```bash
cd docker
./start_all.sh
```

**Windows (PowerShell):**
```powershell
cd docker
.\start_all.ps1
```

**Windows (Command Prompt):**
```cmd
cd docker
start_all.cmd
```

### Check Status

```bash
docker compose ps
docker compose logs -f
```

### Stop Everything

```bash
cd docker
./stop_all.sh      # Linux/macOS
.\stop_all.ps1     # Windows PowerShell
stop_all.cmd       # Windows CMD
```

---

## Services Running

After starting, these containers will be running:

1. **knightonline-sqlserver-1** - SQL Server 2022 database
2. **knightonline-kodb-util-1** - Database utilities (one-time)
3. **knightonline-aiserver-1** - AI Server
4. **knightonline-aujard-1** - Aujard Server
5. **knightonline-ebenezer-1** - Ebenezer Game Server
6. **knightonline-itemmanager-1** - Item Manager
7. **knightonline-versionmanager-1** - Version Manager

---

## Ports

| Service | Port | Description |
|---------|------|-------------|
| SQL Server | 1433 | Database |
| AIServer | 10020 | AI Server |
| Aujard | 10013 | Login Server |
| Ebenezer | 15001 | Game Server |
| ItemManager | 10008 | Item Server |
| VersionManager | 10010 | Version Server |

---

## Volumes

Data is persisted in Docker volumes:
- `sqlserver_data` - Database files
- `server_config` - Server configuration files

To reset everything:
```bash
docker compose down -v  # -v removes volumes
```

---

## Troubleshooting

### Issue: Containers keep restarting

**Check logs:**
```bash
docker compose logs [service-name]
```

**Common causes:**
1. Database not ready → Wait for SQL Server to be healthy
2. Config issues → Check entrypoint logs
3. Port conflicts → Check if ports are already in use

### Issue: AIServer connection failed

**This should be fixed by v2 fix!**

Verify:
```bash
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 2 AI_SERVER
# Should show: IP=aiserver
```

If still failing:
```bash
docker compose restart ebenezer
docker compose logs -f ebenezer
# Should show: "Updating AI_SERVER IP to: aiserver"
```

### Issue: MAP files not found

**This should be fixed by symlink fix!**

Verify:
```bash
docker compose exec ebenezer ls -la /app/MAP
# Should list map files
```

---

## Success Criteria

All fixes are working if:

✅ All containers start successfully
✅ No restart loops
✅ Ebenezer connects to AIServer
✅ MAP files load without errors
✅ Database is accessible
✅ No build errors during image creation

**Check with:**
```bash
docker compose ps
# All should show "Up" or "Up (healthy)"

docker compose logs ebenezer | grep -i error
# Should show minimal/no errors (some warnings are normal)
```

---

## Credits

All fixes developed for the OpenKO project to enable full Docker support.

- Original project: https://github.com/Open-KO/KnightOnline
- Docker implementation: Custom for this fork
- Documentation: Bilingual (Turkish/English)

---

## Next Steps

The Docker setup is now complete and functional. Users can:

1. Clone the repository
2. Run `./docker/start_all.sh` (or Windows equivalent)
3. Wait for all services to start
4. Connect to the game server

No manual configuration needed! 🎉
