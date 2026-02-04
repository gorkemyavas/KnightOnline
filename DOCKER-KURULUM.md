# OpenKO Docker Kurulum Rehberi

Bu rehber, Knight Online (OpenKO) projesinin Docker üzerinde nasıl çalıştırılacağını açıklar.

## ⚠️ Önemli Uyarılar

> **Bu Docker kurulumu yalnızca yerel geliştirme ortamları için tasarlanmıştır.**
> 
> **ASLA bu kurulumu canlı/production sunucu için kullanmayın!**

Bu proje tamamen akademik amaçlarla geliştirilmektedir. Gerçek bir sunucu için kullanılabilir durumda değildir ve hala erken geliştirme aşamasındadır.

## Gereksinimler

### 1. Docker Kurulumu

Sisteminize Docker ve Docker Compose kurulu olmalıdır:

- **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- **Linux**: [Docker Engine](https://docs.docker.com/engine/install/) ve [Docker Compose](https://docs.docker.com/compose/install/)

Kurulumu doğrulamak için terminalde şu komutu çalıştırın:

```bash
docker version
docker compose version
```

### 2. Sistem Gereksinimleri

- **RAM**: Minimum 8 GB (16 GB önerilir)
- **Disk Alanı**: Minimum 20 GB boş alan
- **İşlemci**: 4 çekirdek veya daha fazla

## Hızlı Başlangıç

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/gorkemyavas/KnightOnline.git
cd KnightOnline
```

### 2. Tüm Servisleri Başlatın

#### Linux/macOS:

```bash
cd docker
./start_all.sh
```

#### Windows:

```cmd
cd docker
start_all.cmd
```

Bu script şunları yapar:
1. SQL Server veritabanını başlatır
2. Veritabanını OpenKO şemasıyla hazırlar
3. Tüm oyun sunucularını (AIServer, Aujard, Ebenezer, ItemManager, VersionManager) başlatır

İlk çalıştırmada tüm Docker imajlarının indirilmesi ve derlenmesi **15-30 dakika** sürebilir.

### 3. Servisleri Kontrol Edin

Tüm servislerin çalışıp çalışmadığını kontrol etmek için:

```bash
docker compose ps
```

Çıktıda şu servisler görünmelidir:
- `sqlserver` - SQL Server veritabanı
- `kodb-util` - Veritabanı yönetim aracı
- `aiserver` - AI sunucusu
- `aujard` - Kimlik doğrulama sunucusu
- `ebenezer` - Ana oyun sunucusu
- `itemmanager` - Eşya yönetim sunucusu
- `versionmanager` - Versiyon yönetim sunucusu

### 4. Logları İzleyin

Tüm servislerin loglarını izlemek için:

```bash
docker compose logs -f
```

Belirli bir servisin loglarını izlemek için:

```bash
docker compose logs -f ebenezer
```

## Yapılandırma

### Ortam Değişkenleri

Varsayılan ayarları değiştirmek isterseniz:

1. Proje kök dizininde `.env` dosyası oluşturun:

```bash
cp default.env .env
```

2. `.env` dosyasını düzenleyin:

```env
# Veritabanı şifresi
MSSQL_SA_PASSWORD=YourStrongPassword123!

# SQL Server portu
SQL_PORT=1433

# Veritabanı yapılandırması
GAME_DB_NAME=KN_online
GAME_DB_USER=knight
GAME_DB_PASS=knight

# Oyun sunucusu portu
EBENEZER_PORT=15100
```

### Sunucu Yapılandırmaları

Her sunucunun yapılandırma dosyaları `docker/server/` dizininde bulunur:

- `AIServer.ini` - AI sunucusu ayarları
- `Aujard.ini` - Kimlik doğrulama sunucusu ayarları
- `Ebenezer.ini` - Ana oyun sunucusu ayarları
- `VersionManager.ini` - Versiyon yönetim ayarları

Bu dosyaları düzenleyerek sunucu davranışlarını özelleştirebilirsiniz.

## Yönetim Komutları

### Servisleri Durdurma

```bash
cd docker
# Linux/macOS:
./stop_all.sh

# Windows:
stop_all.cmd
```

Veya:

```bash
docker compose down
```

### Servisleri Yeniden Başlatma

```bash
docker compose restart
```

Belirli bir servisi yeniden başlatmak için:

```bash
docker compose restart ebenezer
```

### Veritabanını Sıfırlama

Veritabanını temiz hale getirmek ve yeniden yüklemek için:

#### Linux/macOS:

```bash
cd docker
./reset_database.sh
```

#### Windows:

```cmd
cd docker
reset_database.cmd
```

### Tüm Servisleri ve Verileri Silme

**⚠️ DİKKAT: Bu komut tüm veritabanı verilerini siler!**

```bash
docker compose down -v --rmi all
```

## Port Yapılandırması

Varsayılan olarak şu portlar kullanılır:

| Servis | Port | Açıklama |
|--------|------|----------|
| SQL Server | 1433 | Veritabanı bağlantı portu |
| Ebenezer | 15100 | Ana oyun sunucusu |

Portları değiştirmek için `.env` dosyasını düzenleyin.

## Sorun Giderme

### 1. "Port already in use" Hatası

Bir port zaten kullanılıyorsa, `.env` dosyasında portu değiştirin:

```env
SQL_PORT=1434
EBENEZER_PORT=15101
```

### 2. Docker Build Hataları

Önbelleği temizleyip yeniden derleyin:

```bash
docker compose build --no-cache
```

### 3. Veritabanı Bağlantı Sorunları

SQL Server'ın sağlıklı çalıştığını kontrol edin:

```bash
docker compose ps sqlserver
```

`healthy` durumunda olmalıdır. Değilse, logları kontrol edin:

```bash
docker compose logs sqlserver
```

### 4. Sunucu Hemen Kapanıyor

Sunucu loglarını kontrol edin:

```bash
docker compose logs ebenezer
```

Yapılandırma hatalarını veya veritabanı bağlantı sorunlarını arayın.

### 5. Bellek Sorunları

Docker Desktop ayarlarından daha fazla bellek ayırın:
- Windows/macOS: Docker Desktop → Settings → Resources → Memory

## Geliştirici Notları

### Kaynak Kodu Değişikliklerini Test Etme

Kaynak kodda değişiklik yaptıktan sonra:

```bash
# Sadece server imajını yeniden derle
docker compose build aiserver aujard ebenezer itemmanager versionmanager

# Değişiklikleri uygula
docker compose up -d
```

### Veritabanına Erişim

SQL Server Management Studio veya başka bir araçla veritabanına bağlanmak için:

```
Server: localhost,1433
Username: sa
Password: D0ckeIzKn!ght (veya .env dosyasındaki şifre)
Database: KN_online
```

### Docker İçine Giriş

Bir container'ın içine girmek için:

```bash
# Ebenezer sunucusuna giriş
docker compose exec ebenezer bash

# Veritabanına giriş
docker compose exec sqlserver bash
```

## Ek Kaynaklar

- [Ana Proje Dokümantasyonu](../README.md)
- [İngilizce Docker Kurulum Rehberi](./DOCKER-SETUP.md)
- [GitHub Wiki](https://github.com/Open-KO/KnightOnline/wiki)
- [Discord Topluluğu](https://discord.gg/Uy73SMMjWS)

## Katkıda Bulunma

Docker yapılandırmasını geliştirmek için önerileriniz varsa, lütfen bir pull request açın!

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](../LICENSE) dosyasına bakın.
