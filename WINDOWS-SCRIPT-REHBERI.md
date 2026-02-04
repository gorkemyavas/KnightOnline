# Windows Kullanıcıları için Docker Script Rehberi

Bu rehber Windows kullanıcılarının Docker script'lerini nasıl çalıştıracağını açıklar.

## 📝 Script Türleri

Docker klasöründe 3 farklı script formatı bulunur:

1. **`.sh` dosyaları** - Linux/macOS için (Windows'da çalışmaz)
2. **`.cmd` dosyaları** - Windows Command Prompt için
3. **`.ps1` dosyaları** - Windows PowerShell için (ÖNERİLEN ✅)

## 🎯 Hangi Script'i Kullanmalıyım?

### PowerShell Script'leri (.ps1) - ÖNERİLEN ✅

**Avantajları:**
- ✅ Daha iyi hata yönetimi
- ✅ Renkli ve okunabilir çıktı
- ✅ Modern ve güçlü
- ✅ Çapraz platform desteği

**Nasıl kullanılır:**
```powershell
cd docker
.\start_all.ps1
```

### Command Prompt Script'leri (.cmd)

**Avantajları:**
- ✅ Eski Windows sürümlerinde çalışır
- ✅ Varsayılan olarak etkin

**Nasıl kullanılır:**
```cmd
cd docker
start_all.cmd
```

## 🚀 PowerShell Kullanımı (Önerilen)

### 1. PowerShell'i Açma

**Yöntem 1 - Dosya Gezgini'nden:**
1. Docker klasörüne gidin
2. Shift tuşuna basılı tutarken boş bir alana sağ tıklayın
3. "PowerShell penceresini burada aç" seçeneğini seçin

**Yöntem 2 - Başlat Menüsünden:**
1. Windows tuşuna basın
2. "PowerShell" yazın
3. "Windows PowerShell" uygulamasını açın
4. `cd` komutu ile docker klasörüne gidin:
   ```powershell
   cd C:\path\to\KnightOnline\docker
   ```

### 2. İlk Kullanımda Execution Policy Ayarlama

PowerShell script'lerini ilk kez çalıştırırken şu hatayı alabilirsiniz:

```
.\start_all.ps1 : File cannot be loaded because running scripts is disabled on this system.
```

**Çözüm:**

PowerShell'i **yönetici olarak** açın ve şu komutu çalıştırın:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Onay için `Y` yazıp Enter'a basın.

> **Not**: Bu işlemi sadece bir kez yapmanız yeterlidir.

### 3. Script'leri Çalıştırma

```powershell
# Tüm servisleri başlat
.\start_all.ps1

# Tüm servisleri durdur
.\stop_all.ps1

# Veritabanını sıfırla
.\reset_database.ps1

# Temiz kurulum
.\clean_setup.ps1
```

## 🔧 Mevcut Script'ler

### Ana Script'ler
- `start_all.ps1` - Tüm servisleri başlatır (veritabanı + oyun sunucuları)
- `stop_all.ps1` - Tüm servisleri durdurur

### Veritabanı Script'leri
- `clean_setup.ps1` - Temiz kurulum (her şeyi sıfırdan kurar)
- `reset_database.ps1` - Sadece veritabanını sıfırlar
- `resume_containers.ps1` - Durdurulmuş container'ları devam ettirir
- `stop_containers.ps1` - Sadece veritabanı container'larını durdurur
- `uninstall.ps1` - Her şeyi tamamen kaldırır (DİKKAT: Tüm veriler silinir!)

## 🆘 Sorun Giderme

### "running scripts is disabled" hatası

**Çözüm**: Yukarıdaki "Execution Policy Ayarlama" bölümüne bakın.

### "docker: command not found" hatası

**Çözüm**: Docker Desktop'ın kurulu ve çalışır durumda olduğundan emin olun.
- Docker Desktop'ı başlatın
- Sistem tepsisinde Docker simgesinin olduğunu kontrol edin

### Script çalışıyor ama hata veriyor

**Çözüm**: 
1. PowerShell penceresindeki hata mesajını okuyun (renkli çıktı ile daha kolay anlaşılır)
2. Gerekirse Docker loglarını kontrol edin:
   ```powershell
   docker compose logs -f
   ```

### Script çift tıklama ile çalışmıyor

**Normal**: PowerShell script'leri güvenlik nedeniyle çift tıklama ile çalışmaz.
- PowerShell'i açıp komut satırından çalıştırmanız gerekir
- Veya `.cmd` dosyalarını kullanabilirsiniz (bunlar çift tıklama ile çalışır)

## 💡 İpuçları

1. **PowerShell kullanın**: Daha iyi hata mesajları ve renkli çıktı için
2. **Tab completion**: Script adını yazmaya başlayıp Tab tuşuna basın, otomatik tamamlar
3. **Geçmiş komutlar**: Yukarı ok tuşu ile önceki komutları geri getirin
4. **Logları izleyin**: `docker compose logs -f` ile servisleri izleyebilirsiniz
5. **Yönetici yetkisi**: Normal script'ler için yönetici yetkisine gerek yok

## 📖 Daha Fazla Bilgi

- [Tam Türkçe Kurulum Rehberi](../DOCKER-KURULUM.md)
- [Hızlı Referans](../DOCKER-QUICKREF.md)
- [Docker README](README.MD)

## 🎓 Örnek Kullanım Senaryosu

```powershell
# 1. Docker klasörüne git
cd C:\Users\YourName\KnightOnline\docker

# 2. İlk kurulum - her şeyi sıfırdan kur
.\clean_setup.ps1

# 3. Oyun sunucularını başlat
.\start_all.ps1

# 4. Logları izle
docker compose logs -f ebenezer

# 5. İşiniz bittiğinde durdur
.\stop_all.ps1
```

## ❓ Yardım

Sorun yaşarsanız:
- [GitHub Issues](https://github.com/Open-KO/KnightOnline/issues)
- [Discord Community](https://discord.gg/Uy73SMMjWS)
