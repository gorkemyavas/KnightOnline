# OpenKO Docker Architecture / Docker Mimarisi

## System Overview / Sistem Genel Bakış

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                    │
│                         (backend)                            │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │            │  │            │  │            │            │
│  │  AIServer  │  │  Aujard    │  │ Ebenezer   │◄───┐      │
│  │            │  │            │  │            │    │      │
│  │  (AI/NPC)  │  │  (Auth)    │  │  (Game)    │    │      │
│  │            │  │            │  │            │    │      │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘    │      │
│        │               │               │           │      │
│        │               │               │     Port: 15100 │
│        │               │               │           │      │
│        └───────────────┴───────────────┘           │      │
│                        │                           │      │
│                        │                           │      │
│  ┌────────────┐  ┌─────▼──────┐  ┌────────────┐  │      │
│  │            │  │            │  │            │  │      │
│  │ItemManager │  │ SQL Server │  │VersionMgr  │  │      │
│  │            │  │            │  │            │  │      │
│  │  (Items)   │  │  (KN_DB)   │  │ (Version)  │  │      │
│  │            │  │            │  │            │  │      │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  │      │
│        │               │               │         │      │
│        │         Port: 1433            │         │      │
│        │               │               │         │      │
│        └───────────────┴───────────────┘         │      │
│                        │                         │      │
│                        │                         │      │
│                  ┌─────▼──────┐                  │      │
│                  │            │                  │      │
│                  │ kodb-util  │                  │      │
│                  │            │                  │      │
│                  │  (DB Mgmt) │                  │      │
│                  │            │                  │      │
│                  └────────────┘                  │      │
│                                                  │      │
└──────────────────────────────────────────────────┼──────┘
                                                   │
                                                   │
                                        ┌──────────▼────────┐
                                        │                   │
                                        │  Game Client      │
                                        │  (localhost:15100)│
                                        │                   │
                                        └───────────────────┘
```

## Components / Bileşenler

### Database Tier / Veritabanı Katmanı
- **SQL Server 2022**: Main database server / Ana veritabanı sunucusu
- **kodb-util**: Database initialization and management / Veritabanı başlatma ve yönetim
- **Volume**: Persistent storage for data / Veriler için kalıcı depolama

### Game Server Tier / Oyun Sunucu Katmanı
- **AIServer**: AI and NPC logic / AI ve NPC mantığı
- **Aujard**: Authentication and account management / Kimlik doğrulama ve hesap yönetimi
- **Ebenezer**: Main game server / Ana oyun sunucusu
- **ItemManager**: Item and inventory management / Eşya ve envanter yönetimi
- **VersionManager**: Client version management / İstemci versiyon yönetimi

## Data Flow / Veri Akışı

1. **Client connects** to Ebenezer (port 15100)
   - **İstemci** Ebenezer'a bağlanır (port 15100)

2. **Ebenezer** communicates with:
   - SQL Server for game data / Oyun verileri için SQL Server
   - AIServer for NPC behavior / NPC davranışları için AIServer
   - Aujard for authentication / Kimlik doğrulama için Aujard
   - ItemManager for items / Eşyalar için ItemManager

3. **All servers** share the same database (KN_online)
   - **Tüm sunucular** aynı veritabanını paylaşır (KN_online)

## Configuration Files / Yapılandırma Dosyaları

```
docker/
├── server/
│   ├── Dockerfile              # Server build configuration
│   ├── entrypoint.sh          # Container startup script
│   ├── AIServer.ini           # AI server config
│   ├── Aujard.ini            # Auth server config
│   ├── Ebenezer.ini          # Game server config
│   └── VersionManager.ini    # Version manager config
├── sqlserver/
│   ├── Dockerfile            # Database container config
│   └── ...                   # SQL Server scripts
└── scripts...                # Management scripts
```

## Volumes / Depolama Birimleri

- `sqlserver_data`: Database files / Veritabanı dosyaları
- `sqlserver_scripts`: SQL scripts / SQL script'leri
- `kodb_util_data`: Database utility data / Veritabanı yönetim verileri
- `server_config`: Server configurations / Sunucu yapılandırmaları

## Network / Ağ

All services communicate on the `backend` Docker network
Tüm servisler `backend` Docker ağında iletişim kurar

## Build Process / Derleme Süreci

### Multi-stage Docker Build:

**Stage 1: Builder**
```dockerfile
1. Install build tools (clang-18, cmake, etc.)
2. Copy source code
3. Build all servers with CMake
```

**Stage 2: Runtime**
```dockerfile
1. Install runtime dependencies (ODBC, etc.)
2. Copy compiled binaries from builder
3. Configure ODBC connection
4. Set up entrypoint
```

This reduces final image size significantly!
Bu, son imaj boyutunu önemli ölçüde azaltır!

## Health Checks / Sağlık Kontrolleri

Each service has a health check that monitors:
Her servis sağlık kontrolüne sahiptir:

- Process is running / İşlem çalışıyor mu
- Service responds / Servis yanıt veriyor mu
- Dependencies are ready / Bağımlılıklar hazır mı

## Startup Sequence / Başlatma Sırası

```
1. SQL Server starts
   └─> Waits to be healthy

2. SQL Server Configurator runs
   └─> Creates database

3. kodb-util initializes database
   └─> Loads game data

4. Game servers start in parallel:
   ├─> AIServer
   ├─> Aujard
   ├─> Ebenezer (depends on AI & Auth)
   ├─> ItemManager
   └─> VersionManager
```

## Resource Requirements / Kaynak Gereksinimleri

Minimum:
- CPU: 4 cores / çekirdek
- RAM: 8 GB
- Disk: 20 GB

Recommended / Önerilen:
- CPU: 8 cores / çekirdek
- RAM: 16 GB
- Disk: 50 GB

## Security Notes / Güvenlik Notları

⚠️ **Development Only / Sadece Geliştirme**

- Default passwords / Varsayılan şifreler
- No SSL/TLS encryption / SSL/TLS şifreleme yok
- All ports exposed / Tüm portlar açık
- No authentication on some services / Bazı servislerde kimlik doğrulama yok

**DO NOT USE IN PRODUCTION!**
**PRODUCTION'DA KULLANMAYIN!**

---

For more information / Daha fazla bilgi için:
- [Quick Reference / Hızlı Referans](DOCKER-QUICKREF.md)
- [Setup Guide / Kurulum Rehberi](DOCKER-KURULUM.md)
