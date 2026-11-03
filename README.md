# kilim

iyi için SDL3 üzerinde sıfırdan yazılmış, retained-mode bir GUI kütüphanesi.
Taslak: şu an yalnızca toolchain spike'ı (`examples/smoke.iyi`) var.

## Kurulum

### iyi 0.20.0

kilim iyi **0.20.0**'a sabittir. Resmî installer'lar sürümü `IYI_VERSION`
ortam değişkeniyle sabitler (yoksa en son sürümü kurar); installer'ın kendisi
de aynı etiketten alınır:

```powershell
# Windows (Visual C++ build tools gerekir: "Desktop development with C++")
$env:IYI_VERSION = '0.20.0'
irm https://raw.githubusercontent.com/iyilang/iyi/v0.20.0/install.ps1 | iex
```

```sh
# Linux / macOS (cc gerekir)
curl -fsSL https://raw.githubusercontent.com/iyilang/iyi/v0.20.0/install.sh | IYI_VERSION=0.20.0 sh
```

### SDL3 ve SDL3_ttf

Sürümler `scripts/sdl-versions.txt`'te sabittir.

- **Windows:** `. .\scripts\fetch-sdl.ps1` — VC geliştirme paketlerini
  `vendor/windows/`'a indirir, SHA256'yı doğrular, `IYI_LIBRARY_PATH`'i
  (`.lib` dizinleri) ve `PATH`'i (DLL'ler) bu oturum için ayarlar.
- **Linux:** `scripts/build-sdl-linux.sh` — kaynaktan derler, `/usr/local`'a kurar.
- **macOS:** `brew install sdl3 sdl3_ttf` ve
  `export IYI_LIBRARY_PATH=$(brew --prefix)/lib`.

### Smoke

```sh
SDL_RENDER_DRIVER=software iyi run examples/smoke.iyi   # -> smoke ok, smoke.bmp (mavi)
```

## Notlar

- **Kütüphane yolu:** iyi, `@[Link("SDL3")]` için `SDL3.lib`'i (Unix'te
  `libSDL3`) `IYI_LIBRARY_PATH`'teki dizinlerde arar ve linkleyiciye verir.
  Windows'ta `LIB` ortam değişkeni ve `--link-flags "/LIBPATH:..."` da çalışır.
- **Modül yolu küçük harftir:** iyi modül yollarında büyük harfe izin vermez,
  bu yüzden `iyi.mod` `module github.com/tuntii/kilim` der (GitHub URL'leri
  büyük/küçük harfe duyarsız, `https://github.com/tuntii/kilim.git` aynı depoya gider).
- **Tüketici:** paketin kök modülü `kilim.iyi`'dir (`module kilim`). Bir uygulama:

  ```
  # iyi.mod
  require github.com/tuntii/kilim v0.1.0
  ```

  ```
  import github.com/tuntii/kilim
  ```

  Bu satır `kilim.iyi`'yi yükler; isimleri `Kilim` altındadır. Paketin diğer
  modülleri `github.com/tuntii/kilim/kilim/<ad>` yolundadır.
  (iyi SPEC.md III.7'den çıkarıldı; bir tüketici projesiyle henüz denenmedi.)
