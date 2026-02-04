# Docker Quick Reference / Hızlı Referans

## 🚀 Quick Start / Hızlı Başlangıç

### Start Everything / Her Şeyi Başlat
```bash
cd docker

# Linux/macOS
./start_all.sh

# Windows PowerShell (Önerilen/Recommended)
.\start_all.ps1

# Windows Command Prompt
start_all.cmd
```

### Stop Everything / Her Şeyi Durdur
```bash
cd docker

# Linux/macOS
./stop_all.sh

# Windows PowerShell (Önerilen/Recommended)
.\stop_all.ps1

# Windows Command Prompt
stop_all.cmd
```

> **Windows Kullanıcıları / Windows Users**: PowerShell script'leri (.ps1) daha iyi hata yönetimi ve renkli çıktı sağlar. İlk kullanımda execution policy ayarlamanız gerekebilir.
> PowerShell scripts (.ps1) provide better error handling and colored output. You may need to set execution policy on first use.

## 📋 Common Commands / Sık Kullanılan Komutlar

### Check Status / Durum Kontrolü
```bash
docker compose ps
```

### View Logs / Logları Görüntüle
```bash
# All services / Tüm servisler
docker compose logs -f

# Specific service / Belirli bir servis
docker compose logs -f ebenezer
```

### Restart a Service / Bir Servisi Yeniden Başlat
```bash
docker compose restart ebenezer
```

### Enter a Container / Container İçine Gir
```bash
docker compose exec ebenezer bash
```

### Reset Database / Veritabanını Sıfırla
```bash
cd docker

# Linux/macOS
./reset_database.sh

# Windows PowerShell
.\reset_database.ps1

# Windows Command Prompt
reset_database.cmd
```

## 🔧 Services / Servisler

| Service | Description | Port |
|---------|-------------|------|
| sqlserver | SQL Server 2022 | 1433 |
| aiserver | AI Server / NPC Mantığı | - |
| aujard | Authentication / Kimlik Doğrulama | - |
| ebenezer | Main Game Server / Ana Oyun Sunucusu | 15100 |
| itemmanager | Item Management / Eşya Yönetimi | - |
| versionmanager | Version Management / Versiyon Yönetimi | - |

## 📖 Full Documentation / Tam Dokümantasyon

- 🇹🇷 [Turkish Guide / Türkçe Rehber](DOCKER-KURULUM.md)
- 🇬🇧 [English Guide / İngilizce Rehber](DOCKER-SETUP.md)

## ⚙️ Configuration / Yapılandırma

1. Create `.env` file / `.env` dosyası oluştur:
```bash
cp .env.example .env
```

2. Edit settings / Ayarları düzenle:
```env
MSSQL_SA_PASSWORD=YourPassword123!
EBENEZER_PORT=15100
```

## 🛠️ Troubleshooting / Sorun Giderme

### Rebuild Everything / Her Şeyi Yeniden İnşa Et
```bash
docker compose build --no-cache
docker compose up -d
```

### Remove Everything / Her Şeyi Sil
**⚠️ WARNING: Deletes all data! / UYARI: Tüm verileri siler!**
```bash
docker compose down -v --rmi all
```

### Check Container Logs / Container Loglarını Kontrol Et
```bash
docker compose logs --tail=50 ebenezer
```

## 💾 Database Access / Veritabanı Erişimi

```
Server: localhost,1433
User: sa
Password: D0ckeIzKn!ght  (from .env / .env'den)
Database: KN_online
```

## 🎯 Development Workflow / Geliştirme İş Akışı

1. Make code changes / Kod değişikliği yap
2. Rebuild servers / Sunucuları yeniden derle:
   ```bash
   docker compose build aiserver aujard ebenezer itemmanager versionmanager
   ```
3. Restart services / Servisleri yeniden başlat:
   ```bash
   docker compose up -d
   ```
4. Check logs / Logları kontrol et:
   ```bash
   docker compose logs -f ebenezer
   ```

---

For help, visit / Yardım için: [Discord](https://discord.gg/Uy73SMMjWS)
