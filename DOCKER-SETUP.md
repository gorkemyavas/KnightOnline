# OpenKO Docker Setup Guide

This guide explains how to run the Knight Online (OpenKO) project using Docker.

## ⚠️ Important Warnings

> **This Docker setup is designed for local development environments only.**
> 
> **NEVER use this setup for a production/public server!**

This project is developed strictly for academic purposes. It cannot currently be used for a real server and is still in a very early developmental state.

## Requirements

### 1. Docker Installation

You must have Docker and Docker Compose installed on your system:

- **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- **Linux**: [Docker Engine](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)

Verify installation by running in terminal:

```bash
docker version
docker compose version
```

### 2. System Requirements

- **RAM**: Minimum 8 GB (16 GB recommended)
- **Disk Space**: Minimum 20 GB free space
- **CPU**: 4 cores or more

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/gorkemyavas/KnightOnline.git
cd KnightOnline
```

### 2. Start All Services

#### Linux/macOS:

```bash
cd docker
./start_all.sh
```

#### Windows (PowerShell - Recommended):

```powershell
cd docker
.\start_all.ps1
```

#### Windows (Command Prompt):

```cmd
cd docker
start_all.cmd
```

> **Note**: PowerShell scripts provide better error handling and colored output. If you get an execution policy warning on first run, open PowerShell as administrator and run:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

This script will:
1. Start the SQL Server database
2. Initialize the database with OpenKO schema
3. Start all game servers (AIServer, Aujard, Ebenezer, ItemManager, VersionManager)

On first run, downloading and building all Docker images may take **15-30 minutes**.

### 3. Check Services Status

To check if all services are running:

```bash
docker compose ps
```

You should see these services:
- `sqlserver` - SQL Server database
- `kodb-util` - Database management utility
- `aiserver` - AI server
- `aujard` - Authentication server
- `ebenezer` - Main game server
- `itemmanager` - Item management server
- `versionmanager` - Version management server

### 4. View Logs

To view logs from all services:

```bash
docker compose logs -f
```

To view logs from a specific service:

```bash
docker compose logs -f ebenezer
```

## Configuration

### Environment Variables

To customize default settings:

1. Create a `.env` file in the project root:

```bash
cp default.env .env
```

2. Edit the `.env` file:

```env
# Database password
MSSQL_SA_PASSWORD=YourStrongPassword123!

# SQL Server port
SQL_PORT=1433

# Database configuration
GAME_DB_NAME=KN_online
GAME_DB_USER=knight
GAME_DB_PASS=knight

# Game server port
EBENEZER_PORT=15100
```

### Server Configurations

Configuration files for each server are located in `docker/server/`:

- `AIServer.ini` - AI server settings
- `Aujard.ini` - Authentication server settings
- `Ebenezer.ini` - Main game server settings
- `VersionManager.ini` - Version management settings

Edit these files to customize server behavior.

## Management Commands

### Stop Services

**Linux/macOS:**
```bash
cd docker
./stop_all.sh
```

**Windows (PowerShell):**
```powershell
cd docker
.\stop_all.ps1
```

**Windows (Command Prompt):**
```cmd
cd docker
stop_all.cmd
```

**Or directly with Docker Compose:**

```bash
docker compose down
```

### Restart Services

```bash
docker compose restart
```

To restart a specific service:

```bash
docker compose restart ebenezer
```

### Reset Database

To clean and reload the database:

**Linux/macOS:**
```bash
cd docker
./reset_database.sh
```

**Windows (PowerShell):**
```powershell
cd docker
.\reset_database.ps1
```

**Windows (Command Prompt):**
```cmd
cd docker
reset_database.cmd
```

### Remove All Services and Data

**⚠️ WARNING: This will delete all database data!**

```bash
docker compose down -v --rmi all
```

## Port Configuration

By default, these ports are used:

| Service | Port | Description |
|---------|------|-------------|
| SQL Server | 1433 | Database connection port |
| Ebenezer | 15100 | Main game server |

To change ports, edit the `.env` file.

## Troubleshooting

### 1. "Port already in use" Error

If a port is already in use, change it in the `.env` file:

```env
SQL_PORT=1434
EBENEZER_PORT=15101
```

### 2. Docker Build Errors

Clear cache and rebuild:

```bash
docker compose build --no-cache
```

### 3. Database Connection Issues

Check if SQL Server is healthy:

```bash
docker compose ps sqlserver
```

It should be in `healthy` state. If not, check logs:

```bash
docker compose logs sqlserver
```

### 4. Server Crashes Immediately

Check server logs:

```bash
docker compose logs ebenezer
```

Look for configuration errors or database connection issues.

### 5. Memory Issues

Allocate more memory in Docker Desktop settings:
- Windows/macOS: Docker Desktop → Settings → Resources → Memory

## Developer Notes

### Testing Source Code Changes

After making changes to source code:

```bash
# Rebuild only server images
docker compose build aiserver aujard ebenezer itemmanager versionmanager

# Apply changes
docker compose up -d
```

### Database Access

To connect to the database using SQL Server Management Studio or another tool:

```
Server: localhost,1433
Username: sa
Password: D0ckeIzKn!ght (or password from .env file)
Database: KN_online
```

### Accessing Containers

To enter a container:

```bash
# Access Ebenezer server
docker compose exec ebenezer bash

# Access database
docker compose exec sqlserver bash
```

## Additional Resources

- [Main Project Documentation](README.md)
- [Turkish Docker Setup Guide](DOCKER-KURULUM.md)
- [GitHub Wiki](https://github.com/Open-KO/KnightOnline/wiki)
- [Discord Community](https://discord.gg/Uy73SMMjWS)

## Contributing

If you have suggestions for improving the Docker configuration, please open a pull request!

## License

This project is licensed under the MIT license. See [LICENSE](LICENSE) file for details.
