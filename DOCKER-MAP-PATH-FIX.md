# MAP Dosyaları Path Sorunu Çözümü

## Sorun

AIServer ve Ebenezer server'ları MAP dosyalarını bulamıyor ve başlatılamıyor:

```
[error] AIServerApp::MapFileLoad: Failed to open file: ../MAP/karus_0730.smd
[error] EbenezerApp::MapFileLoad: File Open Fail - ../MAP/karus_0730.smd
[error] AIServerApp::OnStart: failed to load maps, closing server
[error] EbenezerApp::OnInitDialog: failed to load maps, closing
```

Server'lar sürekli restart döngüsüne giriyor.

## Hata Analizi

### Path Beklentileri

OpenKO server'ları MAP dosyalarını **relative path** kullanarak ararlar:

```c++
// Server kodunda (örnek)
std::string mapPath = "../MAP/karus_0730.smd";
```

Bu path, server'ın working directory'sine göre çözülür.

### Docker Container Yapısı

**Dockerfile'da:**
```dockerfile
WORKDIR /app/bin                                      # Working directory
COPY --from=builder /build/build/bin/MAP /app/bin/MAP  # MAP dosyaları
```

**Sonuç:**
- Working directory: `/app/bin`
- MAP dosyaları: `/app/bin/MAP/`

**Server'ların arama yolu:**
- Kod: `../MAP/karus_0730.smd`
- Çözümlenen path: `/app/bin/../MAP/` = `/app/MAP/` ❌

**Sorun:**
- Server arar: `/app/MAP/karus_0730.smd`
- Dosya konumu: `/app/bin/MAP/karus_0730.smd`
- Dosya bulunamıyor! ❌

### Neden Bu Yapı?

Server'lar geleneksel olarak şu dizin yapısını bekler:

```
/path/to/server/
├── bin/
│   ├── AIServer           (executable)
│   ├── Ebenezer           (executable)
│   └── ...
├── MAP/                   (map dosyaları)
│   ├── karus_0730.smd
│   └── ...
└── QUESTS/                (quest dosyaları)
```

Server executable'lar `bin/` dizininden çalıştırılır ve `../MAP/` ile üst dizindeki MAP klasörüne erişir.

## Çözüm

### Seçenek 1: Symlink (Seçilen) ✅

Symbolic link oluşturarak server'ların beklediği path'i sağlarız:

```dockerfile
# MAP ve QUESTS dosyalarını kopyala
COPY --from=builder /build/build/bin/MAP /app/bin/MAP
COPY --from=builder /build/build/bin/QUESTS /app/bin/QUESTS

# Symlink'ler oluştur
RUN ln -s /app/bin/MAP /app/MAP && \
    ln -s /app/bin/QUESTS /app/QUESTS
```

**Nasıl çalışır:**
```
/app/
├── bin/
│   ├── MAP/          (gerçek dosyalar)
│   └── QUESTS/       (gerçek dosyalar)
├── MAP -> bin/MAP    (symlink)
└── QUESTS -> bin/QUESTS  (symlink)
```

**Server arama:**
1. Working directory: `/app/bin`
2. Path: `../MAP/karus_0730.smd`
3. Çözümlenen: `/app/MAP/karus_0730.smd`
4. Symlink takip: `/app/bin/MAP/karus_0730.smd` ✅
5. Dosya bulundu! ✅

**Avantajlar:**
- ✅ Disk kullanımı artmaz (symlink sadece referans)
- ✅ Minimal değişiklik
- ✅ Server koduna dokunulmaz
- ✅ Working directory değişmez
- ✅ Temiz ve standart Linux çözümü

### Seçenek 2: Dosyaları Kopyala ❌

```dockerfile
COPY --from=builder /build/build/bin/MAP /app/bin/MAP
COPY --from=builder /build/build/bin/MAP /app/MAP  # Duplicate!
```

**Dezavantajlar:**
- ❌ Disk kullanımı ikiye katlanır
- ❌ Gereksiz veri duplikasyonu
- ❌ Update işlemlerinde iki yeri güncellemek gerekir

### Seçenek 3: Working Directory Değiştir ❌

```dockerfile
WORKDIR /app  # /app/bin yerine
```

**Dezavantajlar:**
- ❌ Server'ların diğer path beklentilerini bozabilir
- ❌ Config dosyaları yanlış yerde aranabilir
- ❌ Binary'ler farklı dizinde olabilir
- ❌ Tahmin edilemeyen yan etkiler

### Seçenek 4: Server Kodunu Değiştir ❌

MAP path'ini `MAP/` olarak değiştir (relative path'siz).

**Dezavantajlar:**
- ❌ Upstream kod değişikliği gerekir
- ❌ Maintenance yükü artar
- ❌ Orijinal server davranışından sapma
- ❌ Kapsamlı değişiklik

## Uygulama Detayları

### Symlink Komutu

```bash
ln -s /app/bin/MAP /app/MAP
```

**Parametreler:**
- `-s`: Symbolic link oluştur (hard link değil)
- `/app/bin/MAP`: Hedef (gerçek dosyaların konumu)
- `/app/MAP`: Link konumu (server'ların beklediği yer)

### Dockerfile Konumu

Symlink'ler, MAP ve QUESTS kopyalandıktan sonra ama working directory değiştirilmeden önce oluşturulmalı:

```dockerfile
# 1. Dosyaları kopyala
COPY --from=builder /build/build/bin/MAP /app/bin/MAP
COPY --from=builder /build/build/bin/QUESTS /app/bin/QUESTS

# 2. Symlink'leri oluştur
RUN ln -s /app/bin/MAP /app/MAP && \
    ln -s /app/bin/QUESTS /app/QUESTS

# 3. Working directory'yi ayarla
WORKDIR /app/bin
```

## Test Etme

### 1. Container'ı Yeniden Oluştur

```bash
# Mevcut container'ları temizle
docker compose down --rmi all -v

# Yeniden başlat
cd docker
.\start_all.ps1  # PowerShell
# veya
./start_all.sh   # Linux/macOS
```

### 2. Log'ları Kontrol Et

**Ebenezer:**
```bash
docker compose logs -f ebenezer
```

**Başarılı çıktı:**
```
✅ [info] EbenezerApp::OnInitDialog: loading maps
✅ [info] Map file loaded: karus_0730.smd
✅ [info] Map file loaded: elmorad_1212.smd
✅ [info] All maps loaded successfully
```

**Hata olmamalı:**
```
❌ [error] EbenezerApp::MapFileLoad: File Open Fail - ../MAP/karus_0730.smd
❌ [error] EbenezerApp::OnInitDialog: failed to load maps, closing
```

**AIServer:**
```bash
docker compose logs -f aiserver
```

**Başarılı çıktı:**
```
✅ [info] AIServerApp::OnStart: starting...
✅ [info] Map file loaded successfully
✅ [info] AIServer ready
```

**Hata olmamalı:**
```
❌ [error] AIServerApp::MapFileLoad: Failed to open file: ../MAP/karus_0730.smd
❌ [error] AIServerApp::OnStart: failed to load maps, closing server
```

### 3. Container Durumunu Kontrol Et

```bash
docker compose ps
```

**Beklenen:**
```
NAME                          STATUS
knightonline-aiserver-1       Up
knightonline-ebenezer-1       Up
```

**Olmamalı:**
```
knightonline-aiserver-1       Restarting
knightonline-ebenezer-1       Exited (1)
```

### 4. Symlink'leri Doğrula

Container içinde symlink'leri kontrol edin:

```bash
docker compose exec ebenezer ls -la /app/
```

**Beklenen çıktı:**
```
drwxr-xr-x   bin
lrwxrwxrwx   MAP -> bin/MAP
lrwxrwxrwx   QUESTS -> bin/QUESTS
drwxr-xr-x   config
-rwxr-xr-x   entrypoint.sh
```

```bash
docker compose exec ebenezer ls -la /app/MAP/ | head -5
```

**Beklenen çıktı:**
```
-rw-r--r-- karus_0730.smd
-rw-r--r-- elmorad_1212.smd
-rw-r--r-- moradon_0826.smd
...
```

## Etkilenen Server'lar

### AIServer ✅

AIServer MAP dosyalarını NPC ve monster yerleşimi için kullanır.

**Gerekli MAP dosyaları:**
- Tüm zone map'leri (.smd dosyaları)

**Etki:**
- ✅ Server artık başarıyla başlıyor
- ✅ MAP dosyalarını okuyabiliyor
- ✅ NPC'ler ve monster'lar spawn olabiliyor

### Ebenezer ✅

Ebenezer ana game server'ıdır ve MAP dosyalarını world geometry için kullanır.

**Gerekli MAP dosyaları:**
- Tüm zone map'leri (.smd dosyaları)

**Etki:**
- ✅ Server artık başarıyla başlıyor
- ✅ MAP dosyalarını okuyabiliyor
- ✅ Oyuncular haritada hareket edebiliyor

### Diğer Server'lar

Aujard, ItemManager, VersionManager MAP dosyalarına ihtiyaç duymazlar ve bu değişiklikten etkilenmezler.

## Özet

**Sorun:** Server'lar MAP dosyalarını `../MAP/` yolunda arıyor ama dosyalar `/app/bin/MAP/` konumunda

**Çözüm:** `/app/MAP -> /app/bin/MAP` symlink oluşturuldu

**Sonuç:** Server'lar MAP dosyalarını başarıyla buluyor ve yüklüyor ✅

## İlgili Dosyalar

- `docker/server/Dockerfile` - Symlink'ler eklendi
- `assets/Server/MAP/` - MAP dosyalarının kaynak konumu

## Referanslar

- Linux symbolic links: `man ln`
- Docker COPY command: https://docs.docker.com/engine/reference/builder/#copy
- OpenKO server directory structure
