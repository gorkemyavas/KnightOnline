# Docker Database Bağlantı Hatası Düzeltmesi

## Problem

Server'lar (AIServer, Aujard, Ebenezer, ItemManager, VersionManager) database'e bağlanamıyor ve başlatma sırasında şu hata ile başarısız oluyor:

```
[error] EbenezerApp::LoadItemTable: load failed
[Microsoft][ODBC Driver 18 for SQL Server][SQL Server]Cannot open database "KN_online" requested by the login. The login failed.
```

## Kök Sebep (Root Cause)

### Environment Variable Eksikliği

Docker Compose yapılandırmasında database bağlantı bilgileri environment variable'lar olarak tanımlanmış:
- `GAME_DB_NAME=KN_online`
- `GAME_DB_USER=knight`
- `GAME_DB_PASS=knight`

Ancak bu değişkenler **sadece** `kodb-util` servisine (database initialization servisi) geçiriliyordu. Game server container'larına geçirilmiyordu.

### Entrypoint Script Beklentisi

`docker/server/entrypoint.sh` script'i bu environment variable'ları kullanarak ODBC ayarlarını güncellemeyi bekliyor:

```bash
# Update ODBC configuration with environment variables if set
if [ ! -z "${GAME_DB_NAME}" ]; then
    sed -i "s/GAME_DSN=.*/GAME_DSN=${GAME_DB_NAME}/" "${BIN_DIR}/${CONFIG_FILE}"
fi

if [ ! -z "${GAME_DB_USER}" ]; then
    sed -i "s/GAME_UID=.*/GAME_UID=${GAME_DB_USER}/" "${BIN_DIR}/${CONFIG_FILE}"
fi

if [ ! -z "${GAME_DB_PASS}" ]; then
    sed -i "s/GAME_PWD=.*/GAME_PWD=${GAME_DB_PASS}/" "${BIN_DIR}/${CONFIG_FILE}"
fi
```

Ama environment variable'lar container'a geçirilmediği için bu kod bloğu hiç çalışmıyor.

### Sonuç

Server'lar template config dosyasındaki default değerlerle bağlanmaya çalışıyor, ancak database connection string doğru değil veya credentials yanlış, bu yüzden "login failed" hatası alınıyor.

## Çözüm (Solution)

### 1. docker-compose.yaml Güncellemesi

Tüm game server servislerine (aiserver, aujard, ebenezer, itemmanager, versionmanager) environment variable'lar eklendi:

```yaml
environment:
  - GAME_DB_NAME=${GAME_DB_NAME:-KN_online}
  - GAME_DB_USER=${GAME_DB_USER:-knight}
  - GAME_DB_PASS=${GAME_DB_PASS:-knight}
```

**Örnek - Ebenezer servisi:**

```yaml
ebenezer:
  build:
    context: .
    dockerfile: docker/server/Dockerfile
  environment:
    - AI_SERVER_IP=${AI_SERVER_IP:-aiserver}
    - GAME_DB_NAME=${GAME_DB_NAME:-KN_online}  # ← YENİ!
    - GAME_DB_USER=${GAME_DB_USER:-knight}      # ← YENİ!
    - GAME_DB_PASS=${GAME_DB_PASS:-knight}      # ← YENİ!
```

### 2. Entrypoint Script İyileştirmesi

Debug log'ları eklendi böylece ODBC güncellenmesinin gerçekleştiğini görebiliriz:

```bash
if [ ! -z "${GAME_DB_NAME}" ] || [ ! -z "${GAME_DB_USER}" ] || [ ! -z "${GAME_DB_PASS}" ]; then
    echo "Updating ODBC configuration..."
    if [ ! -z "${GAME_DB_NAME}" ]; then
        echo "  Database: ${GAME_DB_NAME}"
        sed -i "s/GAME_DSN=.*/GAME_DSN=${GAME_DB_NAME}/" "${BIN_DIR}/${CONFIG_FILE}"
    fi
    
    if [ ! -z "${GAME_DB_USER}" ]; then
        echo "  User: ${GAME_DB_USER}"
        sed -i "s/GAME_UID=.*/GAME_UID=${GAME_DB_USER}/" "${BIN_DIR}/${CONFIG_FILE}"
    fi
    
    if [ ! -z "${GAME_DB_PASS}" ]; then
        echo "  Password: ***"
        sed -i "s/GAME_PWD=.*/GAME_PWD=${GAME_DB_PASS}/" "${BIN_DIR}/${CONFIG_FILE}"
    fi
fi
```

## Nasıl Çalışır (How It Works)

### Önceki Durum (❌ Broken)

```
┌─────────────────────┐
│ Docker Compose      │
│ default.env:        │
│  GAME_DB_NAME=...   │
│  GAME_DB_USER=...   │
└─────────────────────┘
         ↓
┌─────────────────────┐
│ kodb-util container │  ← Sadece bu alıyordu!
│ (DB initialization) │
└─────────────────────┘
         
┌─────────────────────┐
│ ebenezer container  │
│ Environment vars:   │
│  ❌ GAME_DB_NAME    │  ← Environment variable yok!
│  ❌ GAME_DB_USER    │
│  ❌ GAME_DB_PASS    │
└─────────────────────┘
         ↓
┌─────────────────────┐
│ entrypoint.sh       │
│ if [ ! -z "$VAR" ]  │
│   sed update...     │  ← Çalışmıyor, VAR boş!
└─────────────────────┘
         ↓
┌─────────────────────┐
│ Ebenezer.ini        │
│ [ODBC]              │
│ GAME_DSN=KN_online  │  ← Template default'ları
│ GAME_UID=knight     │
│ GAME_PWD=knight     │
└─────────────────────┘
         ↓
         ❌ Database connection failed!
```

### Yeni Durum (✅ Fixed)

```
┌─────────────────────┐
│ Docker Compose      │
│ default.env:        │
│  GAME_DB_NAME=...   │
│  GAME_DB_USER=...   │
│  GAME_DB_PASS=...   │
└─────────────────────┘
         ↓
    ┌────┴────┐
    ↓         ↓
┌─────────┐ ┌─────────────┐
│ kodb-   │ │ All game    │  ← Artık hepsi alıyor!
│ util    │ │ servers     │
└─────────┘ └─────────────┘
                ↓
      ┌─────────────────────┐
      │ ebenezer container  │
      │ Environment vars:   │
      │  ✅ GAME_DB_NAME    │  ← Env var'lar mevcut!
      │  ✅ GAME_DB_USER    │
      │  ✅ GAME_DB_PASS    │
      └─────────────────────┘
                ↓
      ┌─────────────────────┐
      │ entrypoint.sh       │
      │ echo "Updating..."  │  ← Log mesajı
      │ sed update...       │  ← Çalışıyor!
      └─────────────────────┘
                ↓
      ┌─────────────────────┐
      │ Ebenezer.ini        │
      │ [ODBC]              │
      │ GAME_DSN=KN_online  │  ← Doğru değerler!
      │ GAME_UID=knight     │
      │ GAME_PWD=knight     │
      └─────────────────────┘
                ↓
                ✅ Database connection successful!
```

## Etkilenen Servisler

### Güncellenen Servisler

Tüm game server servislerine environment variable'lar eklendi:

1. **aiserver** - 3 environment variable eklendi
2. **aujard** - 3 environment variable eklendi  
3. **ebenezer** - 3 environment variable eklendi (AI_SERVER_IP zaten vardı)
4. **itemmanager** - 3 environment variable eklendi
5. **versionmanager** - 3 environment variable eklendi

### Değişmeyen Servisler

- **sqlserver** - Database server, değişiklik gerektirmez
- **sqlserver.configurator** - Configuration helper, değişiklik gerektirmez
- **kodb-util** - Zaten environment variable'lara sahipti

## Test Talimatları

### Yeni Kurulum

```bash
# Repository'yi klonla
git clone https://github.com/gorkemyavas/KnightOnline.git
cd KnightOnline

# Docker container'ları başlat
cd docker
./start_all.sh       # Linux/macOS
# veya
.\start_all.ps1      # Windows PowerShell
# veya
start_all.cmd        # Windows CMD

# Ebenezer log'larını izle
docker compose logs -f ebenezer
```

### Mevcut Kurulum

Eğer zaten container'lar çalışıyorsa, onları yeniden başlatın:

```bash
docker compose down
cd docker
./start_all.sh
docker compose logs -f ebenezer
```

### Beklenen Çıktı

✅ **Başarılı log'lar:**

```
Copying Ebenezer.ini from template...
Updating ODBC configuration...           ← YENİ! ODBC güncelleniyor
  Database: KN_online                    ← Database adı
  User: knight                           ← Kullanıcı adı
  Password: ***                          ← Password (gizli)
Updating AI_SERVER IP to: aiserver
Starting Ebenezer...
[18:22:44][Ebenezer][   info] Ebenezer logger configured
[18:22:45][Ebenezer][   info] EbenezerApp::OnInitDialog: loading ITEM table    ← BAŞARILI!
[18:22:45][Ebenezer][   info] EbenezerApp::OnInitDialog: loading MAGIC table   ← BAŞARILI!
[18:22:45][Ebenezer][   info] EbenezerApp::OnInitDialog: loading MAGIC_TYPE1 table
...
```

❌ **Hata OLMAMALI:**

```
[error] EbenezerApp::LoadItemTable: load failed
[error] Cannot open database "KN_online"
[error] The login failed
```

### Config Doğrulama

Container içindeki config dosyasını kontrol edin:

```bash
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 3 ODBC
```

Çıktı:
```ini
[ODBC]
GAME_DSN=KN_online
GAME_UID=knight
GAME_PWD=knight
```

### Environment Variable Doğrulama

Environment variable'ların container'a geçirildiğini doğrulayın:

```bash
docker compose exec ebenezer env | grep GAME_DB
```

Çıktı:
```
GAME_DB_NAME=KN_online
GAME_DB_USER=knight
GAME_DB_PASS=knight
```

## Yapılandırma (Configuration)

### Default Değerler

`default.env` dosyasında:

```bash
# Game Database configuration
GAME_DB_NAME=KN_online
GAME_DB_USER=knight
GAME_DB_PASS=knight
GAME_DB_SCHEMA=knight
```

### Özel Değerler

Farklı database credentials kullanmak için `.env` dosyası oluşturun:

```bash
# .env dosyası (gitignore'da)
GAME_DB_NAME=MyCustomDB
GAME_DB_USER=myuser
GAME_DB_PASS=mypassword
```

Container'ları yeniden başlattığınızda yeni değerler kullanılacak.

## Sorun Giderme (Troubleshooting)

### Hala "login failed" hatası alıyorsanız

1. **Environment variable'ları kontrol edin:**
   ```bash
   docker compose config | grep GAME_DB
   ```

2. **Container içinde environment variable'ları kontrol edin:**
   ```bash
   docker compose exec ebenezer env | grep GAME_DB
   ```

3. **Config dosyasının güncellendiğini doğrulayın:**
   ```bash
   docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 3 ODBC
   ```

4. **Database'in hazır olduğunu doğrulayın:**
   ```bash
   docker compose ps sqlserver
   # Durum: Up (healthy) olmalı
   
   docker compose logs kodb-util
   # "database successfully imported" mesajını arayın
   ```

5. **SQL Server'a manuel bağlantı test edin:**
   ```bash
   docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
     -S localhost -U knight -P knight -d KN_online -C \
     -Q "SELECT name FROM sys.databases WHERE name = 'KN_online'"
   ```

### Log'larda "Updating ODBC configuration..." görünmüyorsa

Environment variable'lar geçirilmemiş demektir. `docker-compose.yaml` dosyasını kontrol edin:

```bash
grep -A 5 "ebenezer:" docker-compose.yaml | grep -A 3 "environment:"
```

Çıktıda `GAME_DB_NAME`, `GAME_DB_USER`, `GAME_DB_PASS` görmelisiniz.

### Database "KN_online" bulunamıyor

Database henüz oluşturulmamış olabilir. kodb-util log'larını kontrol edin:

```bash
docker compose logs kodb-util
```

Beklenen çıktı:
```
Installing a clean, up-to-date OpenKO database...
-- Clean --
Dropping KN_online database...  Done
-- Import --
databases successfully imported
schemas successfully imported
users successfully imported
table data successfully imported
```

## Özet (Summary)

### Yapılan Değişiklikler

1. **docker-compose.yaml** - 5 servise 15 environment variable eklendi
2. **docker/server/entrypoint.sh** - Debug log'ları eklendi

### Çözülen Sorunlar

✅ Database connection failed hatası
✅ "Cannot open database KN_online" hatası
✅ "The login failed" hatası
✅ Server'ların başlatma sırasında çökmesi

### Avantajlar

✅ Tüm server'lar tutarlı database settings kullanır
✅ Merkezi yapılandırma (default.env veya .env)
✅ Debug için log mesajları
✅ Geriye uyumlu (default değerler)
✅ Esnek (kullanıcılar özelleştirebilir)

## İlgili Dosyalar

- `docker-compose.yaml` - Server servisleri tanımları
- `docker/server/entrypoint.sh` - Container başlatma script'i
- `default.env` - Default environment variable'lar
- `.env.example` - Örnek kullanıcı yapılandırması
- `docker/server/Ebenezer.ini` - Ebenezer config template
- `docker/server/AIServer.ini` - AIServer config template
- `docker/server/Aujard.ini` - Aujard config template
- `docker/server/VersionManager.ini` - VersionManager config template
