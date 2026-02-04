# OpenKO Docker Scripts
### ⚠️⚠️ **DO NOT use this to run a database for a public server - do a manual installation instead.** ⚠️⚠️

## What's Included

This Docker setup provides a complete development environment for OpenKO:

1. **Database Services**:
   - SQL Server 2022
   - Database initialization and management utilities

2. **Game Server Services**:
   - AIServer - Handles AI logic for NPCs
   - Aujard - Authentication and account management
   - Ebenezer - Main game server
   - ItemManager - Item management
   - VersionManager - Version management and updates

## Docker Requirements
You must install Docker yourself and ensure it is available on the command line (try `docker version` in a terminal.)

Docker isn't for everyone.  It takes time to learn and troubleshoot issues.  If you're uncomfortable with the potential learning curve, you can check [SQL Server Manual Setup](https://github.com/Open-KO/KnightOnline/wiki/SQL-Server-2022-Manual-Setup) for manual database install instructions.

## Purpose: Local Development Database
These Docker services are only meant to be used for local development enviroments.
No precautions have been taken to make any of the containers secure.

⚠️ **DO NOT use this to run a database for a public server - do a manual installation instead.** ⚠️

## Configuration
If you feel compelled to change the default configuration: 
* Make a copy of the file `default.env` in the root project directory (KnightOnline/), and name the new copy `.env`. 
* Make sure `default.env` does not get deleted, as this is a reference file available for everyone.  If you push a PR with
this file missing the PR will be rejected until you restore the file.
* This `.env` file is on .gitignore, so you do not need to worry about accidentally
commiting your personal configuration.

Absent a local port conflict there should be no need to change default config. It is recommended
to just use the defaults.

## Scripts in this folder

This folder contains several helper scripts to help you create and manage OpenKO services using Docker. Depending on your platform, use scripts ending in `.sh` for Linux/macOS, and `.cmd` for Windows.

### Complete Environment Scripts

* `start_all`: **[NEW]** Complete setup that starts database AND all game servers. Best for quick start!
* `stop_all`: **[NEW]** Stops all services (database and game servers).

### Database-Only Scripts (Legacy)

* `clean_setup`: Use this for a first-time setup. Removes any existing sqlserver/kodb-util images/volumes, then creates/starts new versions of them. Before the script completes, the script to create an up-to-date OpenKO database will be invoked.
* `reset_database`: Performs a clean import of the OpenKO database.  This will remove any existing OpenKO database instance matching the DB_NAME from the .env file (default: KN_online), then create a replacement database with the latest data from the OpenKO-db project.
* `stop_containers`: Stops only the database services (sqlserver and kodb-util). 
* `resume_containers`: Resumes only the database services (sqlserver and kodb-util).
* `uninstall`: Removes all sqlserver and kodb-util containers, images, and volumes.

## Quick Start

For a complete guide, see:
- [Turkish Docker Setup Guide (DOCKER-KURULUM.md)](../DOCKER-KURULUM.md)
- [English Docker Setup Guide (DOCKER-SETUP.md)](../DOCKER-SETUP.md)

### Start Everything

```bash
cd docker
./start_all.sh  # Linux/macOS
start_all.cmd   # Windows
```

This will:
1. Build and start SQL Server
2. Initialize the database
3. Build and start all game servers

### Stop Everything

```bash
cd docker
./stop_all.sh  # Linux/macOS
stop_all.cmd   # Windows
```

## What Services Are Running?

Check service status:
```bash
docker compose ps
```

View logs:
```bash
docker compose logs -f
# Or for a specific service:
docker compose logs -f ebenezer
```

Most IDEs will allow you to right click and run these scripts from a context menu; otherwise call them from your terminal
application.  Linux users may need to run `chmod +x *.sh` in the `KnightOnline/docker` folder to make the scripts executable.
