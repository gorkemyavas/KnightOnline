# Docker Build Fix - Microsoft ODBC GPG Key Issue

## Sorun (Problem)

Docker build sırasında Microsoft ODBC Driver kurulumunda GPG anahtar hatası:

```
W: GPG error: https://packages.microsoft.com/ubuntu/24.04/prod noble InRelease: 
   The following signatures couldn't be verified because the public key is not available: 
   NO_PUBKEY EB3E94ADBE1229CF
E: The repository 'https://packages.microsoft.com/ubuntu/24.04/prod noble InRelease' is not signed.
```

## Sebep (Root Cause)

Ubuntu 24.04'te `apt-key` komutu kullanımdan kaldırıldı (deprecated). Bu komut artık GPG anahtarlarını doğru şekilde trusted keyring'e eklemiyor.

## Düzeltme (Fix)

### Önceki Kod (Broken)

```dockerfile
# Eski, çalışmayan metod
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/24.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*
```

**Sorunlar:**
- ❌ `apt-key` deprecated
- ❌ GPG anahtarı doğru konuma kaydedilmiyor
- ❌ Repository yapılandırması anahtarı referans etmiyor

### Yeni Kod (Fixed)

```dockerfile
# Modern, Ubuntu 24.04 uyumlu metod
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*
```

**İyileştirmeler:**
- ✅ `gpg --dearmor` ile modern GPG yönetimi
- ✅ Anahtar `/usr/share/keyrings/` dizinine kaydediliyor
- ✅ Repository yapılandırmasında `signed-by` parametresi
- ✅ `curl -fsSL` ile daha güvenli indirme

## Teknik Detaylar

### 1. GPG Anahtarını İndirme ve Dönüştürme

```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
```

**Parametreler:**
- `-f, --fail`: HTTP hataları durumunda sessizce başarısız ol
- `-s, --silent`: İlerleme çubuğu gösterme
- `-S, --show-error`: Sessiz modda bile hataları göster
- `-L, --location`: HTTP yönlendirmelerini takip et
- `gpg --dearmor`: ASCII GPG anahtarını binary formata dönüştür

### 2. Repository Yapılandırması

```bash
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] \
    https://packages.microsoft.com/ubuntu/24.04/prod noble main" \
    > /etc/apt/sources.list.d/mssql-release.list
```

**Önemli noktalar:**
- `[arch=amd64]`: Sadece amd64 mimarisi için
- `signed-by=...`: Bu repository için kullanılacak GPG anahtarı
- Repository URL'si doğrudan belirtiliyor (config dosyası indirme yok)

## Etkilenen Servisler

Bu düzeltme aşağıdaki tüm servisleri etkiler (hepsi aynı Dockerfile'ı kullanır):

- ✅ **aiserver** - AI Server
- ✅ **aujard** - Authentication Server
- ✅ **ebenezer** - Main Game Server
- ✅ **itemmanager** - Item Manager
- ✅ **versionmanager** - Version Manager

## Test Etme

### 1. Temiz Başlangıç

```bash
# Mevcut imajları ve volume'ları temizle
docker compose down --rmi all -v
```

### 2. Yeniden Build

**PowerShell:**
```powershell
cd docker
.\start_all.ps1
```

**Command Prompt:**
```cmd
cd docker
start_all.cmd
```

**Linux/macOS:**
```bash
cd docker
./start_all.sh
```

### 3. Başarı Kontrolü

Build sürecinde şu mesajları görmelisiniz:

```
✔ Image knightonline-aiserver       Built
✔ Image knightonline-aujard         Built
✔ Image knightonline-ebenezer       Built
✔ Image knightonline-itemmanager    Built
✔ Image knightonline-versionmanager Built
```

GPG hata mesajı **OLMAMALI**.

## Ubuntu Keyring Sistemi

### Eski Sistem (Deprecated)

```
/etc/apt/trusted.gpg       # Tek, merkezi anahtar deposu
/etc/apt/trusted.gpg.d/    # Ek anahtarlar
```

**Sorunlar:**
- Tüm anahtarlar tüm repository'ler için geçerli
- Güvenlik riski
- Anahtar yönetimi zor

### Yeni Sistem (Modern)

```
/usr/share/keyrings/       # Repository'ye özel anahtarlar
```

**Avantajlar:**
- Her repository kendi anahtarını kullanır
- Daha güvenli
- `signed-by` ile açıkça belirtilir
- Anahtar yönetimi kolay

## Referanslar

- [Debian Wiki - SecureApt](https://wiki.debian.org/SecureApt)
- [Ubuntu apt-key deprecation](https://itsfoss.com/apt-key-deprecated/)
- [Microsoft ODBC Driver for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server)

## Sorun Giderme

### "gpg: command not found"

**Çözüm:** `gnupg` paketinin kurulu olduğundan emin olun:
```dockerfile
RUN apt-get update && apt-get install -y gnupg
```

### "Permission denied" hatası

**Çözüm:** Script'in root olarak çalıştığından emin olun (Dockerfile'da varsayılan).

### Repository hala imzalanmamış görünüyor

**Çözüm:**
1. GPG anahtarının doğru konumda olduğunu kontrol edin:
   ```bash
   ls -la /usr/share/keyrings/microsoft-prod.gpg
   ```
2. Repository yapılandırmasında `signed-by` parametresinin doğru olduğunu kontrol edin

## Özet

Bu düzeltme, Ubuntu 24.04'ün modern güvenlik standartlarına uyumlu bir şekilde Microsoft ODBC Driver'ın kurulumunu sağlar. Deprecated `apt-key` yerine `gpg --dearmor` ve `/usr/share/keyrings/` dizini kullanılarak daha güvenli ve sürdürülebilir bir çözüm uygulandı.
