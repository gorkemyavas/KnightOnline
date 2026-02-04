# Ebenezer-AIServer Bağlantı Sorunu Çözümü

## Sorun

Ebenezer server'ı AIServer'a bağlanamıyor ve başlatılamıyor:

```
[error] TcpClientSocket(AISocket)::Connect: failed to connect: Connection refused [socketId=0]
[error] EbenezerApp::AISocketConnect: Failed to connect to AI server (zone 0) (127.0.0.1:10020)
[error] EbenezerApp::OnInitDialog: failed to connect to the AIServer
[error] AppThread::StartupImpl: OnStart() failed.
```

Ebenezer sürekli restart döngüsüne giriyor.

## Hata Analizi

### Docker Networking ve Localhost

**Sorun:** Ebenezer `127.0.0.1:10020` adresine bağlanmaya çalışıyor.

**Docker'da `127.0.0.1` ne anlama gelir?**
- Docker container'larında `127.0.0.1` (localhost) **container'ın kendisini** ifade eder
- Her container'ın kendi network namespace'i vardır
- `127.0.0.1` diğer container'lara erişim sağlamaz

**Örnek:**
```
┌─────────────────────┐    ┌─────────────────────┐
│  Ebenezer Container │    │ AIServer Container  │
│                     │    │                     │
│  127.0.0.1 → SELF  │    │  127.0.0.1 → SELF  │
│                     │    │                     │
│  Bağlanmaya çalışır │╳   │                     │
│  127.0.0.1:10020   │    │  Port 10020 dinliyor│
└─────────────────────┘    └─────────────────────┘
         ❌ Connection Refused!
```

### Docker Compose Networking - Doğru Yöntem

Docker Compose'da container'lar **service name** kullanarak birbirine bağlanır:

```
┌─────────────────────┐    ┌─────────────────────┐
│  Ebenezer Container │    │ AIServer Container  │
│                     │    │                     │
│  aiserver:10020 →  │ ✓  │ ← Service: aiserver │
│                     │    │    Port 10020       │
└─────────────────────┘    └─────────────────────┘
         ✅ Bağlantı Başarılı!
```

Docker Compose otomatik DNS sağlar:
- Service name `aiserver` → AIServer container'ının IP'sine çözümlenir
- Container'lar arası iletişim `backend` network üzerinden olur

### Kök Sebep

**Ebenezer.ini template'i zaten doğru:**
```ini
[AI_SERVER]
IP=aiserver    ← Doğru!
```

**Ama ne yanlış gitti?**

İki olasılık:
1. **Volume'da eski config**: Server ilk kez yanlış config ile çalıştırıldı, volume'a `IP=127.0.0.1` kopyalandı
2. **Config güncellenmiyor**: Entrypoint script'i AI server IP'sini güncellemiyor

Entrypoint script'i sadece ODBC ayarlarını güncelliyor, AI_SERVER IP'sini güncellemiyor:
```bash
# Sadece bunlar güncelleniyor:
- GAME_DSN
- GAME_UID  
- GAME_PWD

# AI_SERVER IP güncellenmiyordu! ❌
```

## Çözüm

### 1. Entrypoint Script'i Güncelle

**docker/server/entrypoint.sh** dosyasına AI_SERVER IP güncelleme mantığı eklendi:

```bash
# Update AI_SERVER IP configuration (for Ebenezer)
# Default to 'aiserver' hostname for Docker networking
if [ ! -z "${AI_SERVER_IP}" ]; then
    sed -i "s/^IP=.*/IP=${AI_SERVER_IP}/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
elif grep -q "\[AI_SERVER\]" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null; then
    # Ensure IP is set to aiserver if not already configured
    sed -i "/\[AI_SERVER\]/,/^\[/ s/^IP=.*/IP=aiserver/" "${BIN_DIR}/${CONFIG_FILE}" 2>/dev/null || true
fi
```

**Mantık:**
1. `AI_SERVER_IP` environment variable varsa → onu kullan
2. Yoksa → `[AI_SERVER]` section'ında `IP=aiserver` olarak ayarla
3. Her container başlangıcında çalışır → eski config'leri düzeltir

### 2. Environment Variable Desteği Ekle

**default.env:**
```bash
# AI Server Configuration
# Hostname/IP for AIServer (used by Ebenezer)
AI_SERVER_IP=aiserver
```

**.env.example:**
```bash
# AI Server hostname/IP (used by Ebenezer to connect to AIServer)
# In Docker Compose, this should be the service name: 'aiserver'
# Default: aiserver
AI_SERVER_IP=aiserver
```

**docker-compose.yaml (Ebenezer service):**
```yaml
ebenezer:
  environment:
    - AI_SERVER_IP=${AI_SERVER_IP:-aiserver}
```

### 3. Nasıl Çalışır

**Başlangıç Akışı:**

```
1. Docker Compose başlar
   ↓
2. Ebenezer container başlar
   ↓
3. Entrypoint script çalışır
   ↓
4. Config yoksa template'den kopyala
   /app/config/Ebenezer.ini → /app/bin/Ebenezer.ini
   ↓
5. ODBC ayarlarını güncelle (GAME_DSN, GAME_UID, GAME_PWD)
   ↓
6. AI_SERVER IP'sini güncelle  ⭐ YENİ!
   - AI_SERVER_IP env var varsa → kullan
   - Yoksa → IP=aiserver olarak ayarla
   ↓
7. Ebenezer başlar
   ↓
8. Ebenezer Ebenezer.ini'yi okur
   IP=aiserver
   ↓
9. Docker DNS çözümleme
   aiserver → AIServer container IP
   ↓
10. Bağlantı başarılı! ✅
```

**Eski Config Senaryosu:**

```
Volume'da eski config var: IP=127.0.0.1
   ↓
Entrypoint çalışır
   ↓
AI_SERVER bölümünü bulur
   ↓
IP=127.0.0.1 → IP=aiserver olarak değiştirir
   ↓
Ebenezer doğru IP'ye bağlanır ✅
```

## Avantajlar

### 1. Otomatik Düzeltme ✅

Volume'da eski/yanlış config olsa bile otomatik düzeltilir:
- Her başlangıçta AI_SERVER IP kontrol edilir
- Yanlışsa düzeltilir

### 2. Özelleştirilebilir ✅

Kullanıcılar `.env` dosyasında özelleştirebilir:

```bash
# Farklı hostname kullan
AI_SERVER_IP=my-custom-aiserver

# IP adresi kullan (test için)
AI_SERVER_IP=192.168.1.100
```

### 3. Geriye Uyumlu ✅

- Mevcut config'ler çalışmaya devam eder
- Template'ler değişmedi
- Sadece runtime'da güncelleme

### 4. Volume Temizleme Gerektirmez ✅

Eski volume'ları silmeye gerek yok:
```bash
# Buna gerek yok artık:
docker compose down -v  ❌

# Bu yeterli:
docker compose restart ebenezer  ✅
```

## Test Etme

### 1. Temiz Kurulum (Clean Install)

```bash
# Volume'ları temizle
docker compose down -v

# Yeniden başlat
cd docker
.\start_all.ps1  # PowerShell
# veya
./start_all.sh   # Linux/macOS

# Log kontrolü
docker compose logs -f ebenezer
```

**Beklenen çıktı:**
```
✅ [info] EbenezerApp::AISocketConnect: Connecting to AI server (aiserver:10020)
✅ [info] EbenezerApp::AISocketConnect: Connected to AI server
✅ [info] EbenezerApp::OnInitDialog: initialization complete
✅ [info] AppThread::StartupImpl: Server started successfully
```

**Olmamalı:**
```
❌ [error] TcpClientSocket(AISocket)::Connect: failed to connect: Connection refused
❌ [error] Failed to connect to AI server (zone 0) (127.0.0.1:10020)
```

### 2. Mevcut Volume ile Test (Existing Volume)

Eski config'i simüle et:

```bash
# 1. Ebenezer'ı durdur
docker compose stop ebenezer

# 2. Config'i manuel boz (test için)
docker compose exec -it aiserver bash
# Container içinde:
echo "[AI_SERVER]" >> /app/bin/Ebenezer.ini
echo "IP=127.0.0.1" >> /app/bin/Ebenezer.ini
exit

# 3. Ebenezer'ı başlat
docker compose start ebenezer

# 4. Log kontrol
docker compose logs -f ebenezer
# IP otomatik aiserver'a güncellenmiş olmalı ✅
```

### 3. Özel IP ile Test (Custom IP)

```bash
# 1. .env dosyası oluştur
echo "AI_SERVER_IP=aiserver" > .env

# 2. Yeniden başlat
docker compose restart ebenezer

# 3. Config'i kontrol et
docker compose exec ebenezer cat /app/bin/Ebenezer.ini
# IP=aiserver görülmeli ✅
```

### 4. Config Doğrulama

Container içinde config'i kontrol et:

```bash
docker compose exec ebenezer cat /app/bin/Ebenezer.ini
```

**Doğru çıktı:**
```ini
[AI_SERVER]
IP=aiserver    ← aiserver olmalı, 127.0.0.1 DEĞİL!
```

### 5. Network Bağlantısı Test

Container içinden bağlantı test et:

```bash
# Ebenezer container'ından aiserver'a ping
docker compose exec ebenezer ping -c 3 aiserver
```

**Başarılı çıktı:**
```
PING aiserver (172.x.x.x) 56(84) bytes of data.
64 bytes from aiserver.backend (172.x.x.x): icmp_seq=1 ttl=64 time=0.123 ms
✅
```

## Sorun Giderme (Troubleshooting)

### Problem: Hala 127.0.0.1'e bağlanmaya çalışıyor

**Kontrol 1: Environment variable geçiyor mu?**
```bash
docker compose exec ebenezer env | grep AI_SERVER_IP
```

Çıktı olmalı:
```
AI_SERVER_IP=aiserver
```

**Kontrol 2: Config güncellenmiş mi?**
```bash
docker compose exec ebenezer cat /app/bin/Ebenezer.ini | grep -A 1 AI_SERVER
```

Çıktı:
```
[AI_SERVER]
IP=aiserver    ← aiserver olmalı!
```

**Kontrol 3: Entrypoint log'u**
```bash
docker compose logs ebenezer | head -20
```

"Copying Ebenezer.ini from template" görülmeli.

**Çözüm:** Container'ı yeniden başlat:
```bash
docker compose restart ebenezer
```

### Problem: AIServer çalışmıyor

**Kontrol: AIServer durumu**
```bash
docker compose ps aiserver
```

**Çözüm:** AIServer'ı başlat:
```bash
docker compose start aiserver
```

### Problem: Network bağlantısı yok

**Kontrol: Container'lar aynı network'te mi?**
```bash
docker network inspect knightonline_backend
```

Her iki container da listede olmalı (ebenezer ve aiserver).

**Çözüm:** Network'ü yeniden oluştur:
```bash
docker compose down
docker compose up -d
```

## Alternatif Çözümler (Karşılaştırma)

### Alternatif 1: Config Template'i Değiştir ❌

Template'de IP'yi hardcode et.

**Dezavantajlar:**
- Esneklik yok
- Özelleştirilemez
- Eski volume'ları düzeltmez

### Alternatif 2: Volume'ları Her Seferinde Sil ❌

```bash
docker compose down -v  # Her seferinde
```

**Dezavantajlar:**
- Kullanıcı verisi kaybolur
- Veritabanı her seferinde sıfırlanır
- Pratik değil

### Alternatif 3: Manuel Config Düzenleme ❌

Kullanıcılar config'i manuel düzeltsin.

**Dezavantajlar:**
- Kullanıcı hatalarına açık
- Dokümantasyon yükü
- Otomatik değil

### Alternatif 4: Environment Variable + Auto-Update (SEÇTIK!) ✅

**Avantajlar:**
- ✅ Otomatik düzeltme
- ✅ Özelleştirilebilir
- ✅ Eski config'leri düzeltir
- ✅ Volume silmeye gerek yok
- ✅ Kullanıcı dostu

## Özet

**Sorun:** Ebenezer `127.0.0.1:10020` adresine bağlanmaya çalışıyor (yanlış!)

**Sebep:** Volume'da eski config veya IP güncellenmemiş

**Çözüm:** 
- Entrypoint script'i AI_SERVER IP'sini otomatik günceller
- Environment variable ile özelleştirilebilir
- Her başlangıçta config düzeltilir

**Sonuç:** Ebenezer başarıyla AIServer'a bağlanıyor! ✅

## İlgili Dosyalar

- `docker/server/entrypoint.sh` - AI_SERVER IP güncelleme mantığı
- `docker/server/Ebenezer.ini` - Template config
- `default.env` - Default AI_SERVER_IP
- `.env.example` - Örnek ve dokümantasyon
- `docker-compose.yaml` - Environment variable geçişi

## Referanslar

- Docker Compose networking: https://docs.docker.com/compose/networking/
- Docker DNS: https://docs.docker.com/config/containers/container-networking/
- OpenKO server architecture
