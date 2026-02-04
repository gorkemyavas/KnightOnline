# Server Pozisyonel Argüman Hatası Çözümü

## Sorun

Tüm game server'lar başlatılırken aynı hata ile çöküyor:

```
[error] AppThread::parse_commandline: Zero positional arguments expected, did you mean --telnet-address VAR
```

Bu hata şu server'ları etkiliyor:
- AIServer
- Aujard  
- Ebenezer
- ItemManager
- VersionManager

Server'lar başlıyor ama hemen kapanıyorlar ve restart döngüsüne giriyorlar.

## Hata Analizi

### Command-Line Argument Beklentileri

OpenKO server'ları **hiç pozisyonel argüman beklemiyorlar**. Yani:

✅ Doğru: `./AIServer`
❌ Yanlış: `./AIServer AIServer.ini`
❌ Yanlış: `./AIServer AIServer AIServer.ini`

Server'lar yapılandırma dosyalarını bulunduğu dizinden otomatik okur:
- `/app/bin/AIServer.ini`
- `/app/bin/Aujard.ini`
- `/app/bin/Ebenezer.ini`
- vb.

### Neden Hata Oluştu?

#### 1. Docker Compose Yapılandırması

docker-compose.yaml dosyasında server'lar şöyle başlatılıyor:

```yaml
aiserver:
  command: ["AIServer", "AIServer.ini"]
```

Bu command, container'ı şu şekilde başlatır:
```bash
/app/entrypoint.sh AIServer AIServer.ini
```

#### 2. Entrypoint Script'i (Eski - Hatalı)

```bash
#!/bin/bash
SERVER_NAME="${1:-Ebenezer}"  # $1 = "AIServer"
CONFIG_FILE="${SERVER_NAME}.ini"

# ... config kopyalama ve güncelleme ...

exec "./${SERVER_NAME}" "$@"  # ❌ HATA BURADA!
```

`$@` tüm argümanları içerir: `"AIServer" "AIServer.ini"`

Yani exec şunu çalıştırır:
```bash
./AIServer AIServer AIServer.ini
```

#### 3. Server'ın Yorumu

Server iki pozisyonel argüman alır:
1. `"AIServer"` - İstenmeyen pozisyonel argüman
2. `"AIServer.ini"` - İstenmeyen pozisyonel argüman

Server bu argümanları parse etmeye çalışır ve hata verir:
```
Zero positional arguments expected, did you mean --telnet-address VAR
```

## Çözüm

### Düzeltilmiş Entrypoint Script'i

```bash
#!/bin/bash
SERVER_NAME="${1:-Ebenezer}"  # $1 = "AIServer"
CONFIG_FILE="${SERVER_NAME}.ini"

# ... config kopyalama ve güncelleme ...

# Pozisyonel argüman geçirme - server config'i otomatik bulur
exec "./${SERVER_NAME}"  # ✅ DÜZELTME
```

Artık sadece şu çalıştırılır:
```bash
./AIServer
```

Server pozisyonel argüman almaz ve kendi config dosyasını `/app/bin/AIServer.ini` konumundan okur.

## Argüman Akışı (Düzeltmeden Önce vs Sonra)

### Öncesi (❌ Broken)

```
Docker Compose
  ↓ command: ["AIServer", "AIServer.ini"]
  ↓
Entrypoint
  ↓ $1="AIServer", $2="AIServer.ini", $@="AIServer AIServer.ini"
  ↓ SERVER_NAME="AIServer"
  ↓ exec "./AIServer" "$@"
  ↓
Server Executable
  ↓ argv[1]="AIServer" ❌
  ↓ argv[2]="AIServer.ini" ❌
  ↓ ERROR: Zero positional arguments expected
  ↓
EXIT CODE 1
```

### Sonrası (✅ Fixed)

```
Docker Compose
  ↓ command: ["AIServer", "AIServer.ini"]
  ↓
Entrypoint
  ↓ $1="AIServer", $2="AIServer.ini"
  ↓ SERVER_NAME="AIServer"
  ↓ CONFIG_FILE="AIServer.ini"
  ↓ Copy config to /app/bin/AIServer.ini
  ↓ exec "./AIServer"
  ↓
Server Executable
  ↓ argc=1 (sadece program adı)
  ↓ Config oku: /app/bin/AIServer.ini
  ↓ Başarıyla başlat ✅
  ↓
RUNNING
```

## Docker Compose Komut Yapılandırması

Docker compose'da `command` parametresi neden hala `["AIServer", "AIServer.ini"]` şeklinde?

Bu yapılandırma şu nedenlerle mantıklı:

1. **Server Adı Belirleme**: İlk argüman (`AIServer`) entrypoint'e hangi server'ı çalıştıracağını söyler
2. **Config Dosyası Adı**: İkinci argüman entrypoint'e hangi config dosyasını kopyalayacağını gösterir
3. **Esneklik**: Farklı server'lar için aynı Dockerfile ve entrypoint kullanılabilir

Entrypoint bu argümanları **kendi işlemi için** kullanır (server adını belirlemek, config'i kopyalamak), ama server executable'a **geçirmez**.

## Alternatif Çözümler

### Alternatif 1: Sadece İlk Argümanı Atla

```bash
# İlk argümanı atla, geri kalanları geçir
shift
exec "./${SERVER_NAME}" "$@"
```

Bu durumda:
- `$1` shift ile atlanır
- `$@` artık sadece "AIServer.ini" içerir
- Server "AIServer.ini" argümanı alır

Ancak server'lar pozisyonel argüman istemediği için bu da çalışmaz.

### Alternatif 2: Config Dosyasını Argüman Olarak Geçir

Server'ların config dosyasını argüman olarak kabul etmesi için kod değişikliği gerekir. Bu mevcut server davranışını değiştirir ve kapsamlı bir değişikliktir.

### Alternatif 3: Mevcut Çözüm (Seçilen) ✅

Hiç pozisyonel argüman geçirme. Server'lar config'i bulunduğu dizinden otomatik okur.

- ✅ Minimal değişiklik
- ✅ Server koduna dokunulmaz
- ✅ Mevcut server davranışı ile uyumlu
- ✅ Tüm server'lar için çalışır

## Test Etme

### 1. Container'ları Temizle ve Yeniden Başlat

```bash
docker compose down
cd docker
.\start_all.ps1  # PowerShell
# veya
./start_all.sh   # Linux/macOS
```

### 2. Log'ları Kontrol Et

```bash
docker compose logs -f aiserver
```

**Başarılı çıktı:**
```
aiserver-1 | Starting AIServer...
aiserver-1 | [2026-02-04 16:10:00] [info] AIServer starting...
aiserver-1 | [2026-02-04 16:10:00] [info] Loading configuration from AIServer.ini
aiserver-1 | [2026-02-04 16:10:00] [info] Successfully connected to database
```

**Hata olmamalı:**
```
❌ [error] AppThread::parse_commandline: Zero positional arguments expected
```

### 3. Container Durumunu Kontrol Et

```bash
docker compose ps
```

Tüm server'lar `Up` durumunda olmalı, `Restarting` olmamalı:

```
NAME                          STATUS
knightonline-aiserver-1       Up
knightonline-aujard-1         Up
knightonline-ebenezer-1       Up
knightonline-itemmanager-1    Up
knightonline-versionmanager-1 Up
```

## Özet

**Sorun**: Server'lar pozisyonel argüman almak istemiyorlar ama entrypoint geçiriyordu

**Sebep**: `exec "./${SERVER_NAME}" "$@"` tüm argümanları geçiriyordu

**Çözüm**: `exec "./${SERVER_NAME}"` hiç argüman geçirmiyor

**Sonuç**: Server'lar config dosyalarını otomatik bulup başarıyla başlıyorlar ✅

## İlgili Dosyalar

- `docker/server/entrypoint.sh` - Düzeltildi
- `docker-compose.yaml` - Değişiklik gerekmedi
- Server source code - Değişiklik gerekmedi

## Referanslar

- AppThread command-line parsing implementation
- Server configuration file loading mechanism
- Docker ENTRYPOINT ve CMD davranışı
