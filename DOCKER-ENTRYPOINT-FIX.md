# Container Entrypoint Hatası Çözümü

## Sorun

Docker container'ları başlatılırken şu hata ile sürekli restart döngüsüne giriyor:

```
exec /app/entrypoint.sh: no such file or directory
```

Bu hata tüm game server container'larında görülüyor:
- knightonline-aiserver-1
- knightonline-aujard-1
- knightonline-ebenezer-1
- knightonline-itemmanager-1
- knightonline-versionmanager-1

## Hata Analizi

### "no such file or directory" Neden Oluşur?

Bu hata mesajı genellikle şu durumlarda görülür:

1. **Dosya gerçekten yok**: `/app/entrypoint.sh` dosyası image'da bulunmuyor
2. **Shebang yorumlayıcısı yok**: `#!/bin/bash` satırındaki `/bin/bash` bulunamıyor
3. **Satır sonu karakterleri**: Dosya Windows satır sonları (CRLF) içeriyor

### Gerçek Sebep: Windows Satır Sonları (CRLF)

Dosya Docker image'a kopyalandığında Windows satır sonları (`\r\n`) ile kopyalanmış olabilir. Bu durumda:

```bash
#!/bin/bash\r
```

Bash şunu aramaya çalışır: `/bin/bash\r`

Bu dosya mevcut olmadığı için "no such file or directory" hatası verir.

## Çözüm

Dockerfile'a `sed` komutu eklenerek Windows carriage return karakterleri (`\r`) kaldırıldı:

```dockerfile
# Copy entrypoint script
COPY docker/server/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    sed -i 's/\r$//' /app/entrypoint.sh
```

### sed Komutu Açıklaması

```bash
sed -i 's/\r$//' /app/entrypoint.sh
```

- `-i`: Dosyayı yerinde düzenle (in-place)
- `s/\r$//`: Her satır sonundaki (`$`) carriage return (`\r`) karakterini sil
- `'`: Tek tırnak, shell'in özel karakterleri yorumlamasını engeller

## Neden Bu Sorun Oluştu?

### Git Satır Sonu Dönüşümleri

Git, farklı işletim sistemleri arasında çalışırken satır sonlarını otomatik dönüştürebilir:

- **Windows**: `\r\n` (CRLF)
- **Linux/Mac**: `\n` (LF)

Eğer bir kullanıcı Windows'ta Git kullanıyorsa ve `core.autocrlf=true` ayarı varsa:
1. Check-in sırasında: CRLF → LF
2. Check-out sırasında: LF → CRLF

Ancak bazen bu dönüşüm tam olarak çalışmaz veya kullanıcı ayarları farklıdır.

### Docker ve Satır Sonları

Docker COPY komutu dosyaları olduğu gibi kopyalar. Eğer kaynak dosya CRLF içeriyorsa, image'daki dosya da CRLF içerir. Linux container'larında CRLF, shebang yorumlayıcısının çalışmamasına neden olur.

## Benzer Örnekler

Bu düzeltme, repoda zaten kullanılan bir pattern:

### sqlserver/Dockerfile
```dockerfile
COPY healthcheck.sh .
RUN chmod +x healthcheck.sh
RUN sed -i 's/\r$//' healthcheck.sh

COPY configurator.sh .
RUN chmod +x configurator.sh
RUN sed -i 's/\r$//' configurator.sh
```

### kodb-util/Dockerfile
```dockerfile
COPY cleanImport.sh /usr/local/bin/cleanImport.sh
RUN chmod +x /usr/local/bin/cleanImport.sh
RUN sed -i 's/\r$//' /usr/local/bin/cleanImport.sh
```

Aynı düzeltme artık `docker/server/Dockerfile`'da da uygulandı.

## Test Etme

### 1. Mevcut Container'ları Temizle

```bash
docker compose down --rmi all -v
```

### 2. Yeniden Build ve Başlat

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

### 3. Container Durumlarını Kontrol Et

```bash
docker compose ps
```

Tüm container'lar `Up` durumunda olmalı:
```
NAME                          STATUS
knightonline-aiserver-1       Up
knightonline-aujard-1         Up
knightonline-ebenezer-1       Up
knightonline-itemmanager-1    Up
knightonline-versionmanager-1 Up
knightonline-sqlserver-1      Up (healthy)
knightonline-kodb-util-1      Up
```

### 4. Logları Kontrol Et

```bash
docker compose logs aiserver
```

"Starting AIServer..." mesajını görmelisiniz, "exec: no such file" hatası olmamalı.

## Önleme

### Git Yapılandırması

Repository'de `.gitattributes` dosyası oluşturarak shell script'lerin her zaman LF ile saklanmasını garanti edebilirsiniz:

```gitattributes
*.sh text eol=lf
```

Ancak mevcut çözüm (Dockerfile'da sed kullanımı) daha sağlam çünkü:
- Kullanıcıların Git yapılandırmasından bağımsız
- Build zamanında garanti eder
- Diğer Dockerfile'larla tutarlı

## Özet

**Sorun**: Windows satır sonları (CRLF) shebang yorumlayıcısının çalışmamasına neden oluyor

**Çözüm**: Dockerfile'da `sed -i 's/\r$//'` ile CRLF'i LF'e dönüştür

**Sonuç**: Container'lar başarıyla başlıyor ve restart döngüsüne girmiyor

## Referanslar

- [Shebang Line Explanation](https://en.wikipedia.org/wiki/Shebang_(Unix))
- [Git Line Ending Handling](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#_formatting_and_whitespace)
- [Docker COPY Command](https://docs.docker.com/engine/reference/builder/#copy)
