# kilim

iyi için SDL3 üzerinde sıfırdan yazılmış, retained-mode bir GUI kütüphanesi.
Widget'ları işletim sistemi değil kilim çizer; uygulama her platformda aynı
görünür. Windows, Linux ve macOS'ta çalışır.

```crystal
module main

import github.com/tuntii/kilim
import github.com/tuntii/kilim/kilim/widget::{Widget}

def main : Int32
  count = Kilim.label("0")
  n = 0
  inc = Kilim.button("Artır", -> { n += 1; count.text = n.to_s; nil })
  Kilim.window("Sayaç", 240, 120, Kilim.column([count, inc] of Widget, padding: 12, spacing: 8)).run
  0
end

exit main
```

Daha büyük bir örnek: [`examples/todo.iyi`](examples/todo.iyi) (yapılacaklar
listesi: textbox, buton, checkbox, kaydırma, Türkçe metin).

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

- **Windows:** `. .\scripts\fetch-sdl.ps1` (başındaki nokta şart). VC geliştirme
  paketlerini `vendor/windows/`'a indirir, SHA256'yı doğrular, `IYI_LIBRARY_PATH`'i
  (`.lib` dizinleri) ve `PATH`'i (DLL'ler) bu oturum için ayarlar. Derlenen exe'yi
  başka yere dağıtırken `SDL3.dll` ve `SDL3_ttf.dll` dosyalarını exe'nin yanına koyun.
- **Linux:** `bash scripts/build-sdl-linux.sh`, kaynaktan derler, `/usr/local`'a
  kurar (cmake, ninja ve X11 geliştirme paketleri gerekir; listesi için
  `.github/workflows/ci.yml`).
- **macOS:** `brew install sdl3 sdl3_ttf` ve
  `export IYI_LIBRARY_PATH=$(brew --prefix)/lib`.

iyi, `@[Link("SDL3")]` için `SDL3.lib`'i (Unix'te `libSDL3`) `IYI_LIBRARY_PATH`'teki
dizinlerde arar. Çalıştırırken DLL'lerin `PATH`'te (Windows) olması gerekir.

### Çalıştırma

```sh
iyi test                                 # çekirdek testleri, SDL gerekmez
iyi run examples/todo.iyi                # todo örneği
KILIM_SELFTEST=todo.bmp iyi run examples/todo.iyi   # penceresiz-elsiz kabul testi, todo.bmp yazar
```

CI'da (`SDL_RENDER_DRIVER=software`) pencere açılamazsa `SDL_VIDEO_DRIVER=offscreen`
ile denenir.

## Kendi projenizde kullanma

`iyi.mod`:

```
module example.com/app

require github.com/tuntii/kilim v0.1.0
```

(Yerel denemede `replace github.com/tuntii/kilim => ../GUI` ekleyin.)
Modül yolu küçük harftir: iyi büyük harfe izin vermez.

Kodda:

```crystal
import github.com/tuntii/kilim                           # Kilim.window, Kilim.column, ...
import github.com/tuntii/kilim/kilim/widget::{Widget}    # dizi tipi için
```

`import github.com/tuntii/kilim` kurucu fonksiyonları `Kilim` altında verir:
`window`, `column`, `row`, `label`, `button`, `checkbox`, `textbox`, `scroll`
ve boyut kısayolları `fit`, `fixed(v)`, `fill(weight)`. Widget tipleri kendi
alt modüllerinde durur (`kilim/label`, `kilim/button`, `kilim/checkbox`,
`kilim/textbox`, `kilim/scroll`, `kilim/box`, `kilim/event`, `kilim/window`);
tip adı gerektiğinde `github.com/tuntii/kilim/kilim/<ad>::{Tip}` ile alın.
Çocuk dizileri `[a, b] of Widget` biçiminde yazılır.

Bu yol gerçek bir tüketici projesiyle denendi (iyi 0.20.0, Windows).

## İlk sürümün sınırları

Kapsam dışı: erişilebilirlik (ekran okuyucu), IME (Çince/Japonca giriş),
çok satırlı metin, seçim ve seçili metni kopyalama (yalnızca Ctrl/Cmd+V ile
yapıştırma ve Ctrl/Cmd+C ile tüm metni kopyalama), sürükle-bırak, temalar
(yalnızca açık tema), animasyon, birden çok pencere (süreç başına bir pencere),
mobil ve web, kalıcılık. Çizim her değişiklikte pencerenin tamamını yeniden
çizer; metin her çizimde yeniden rasterleştirilir (önbellek yok). Borderlar HiDPI'da
1 fiziksel piksel inceliğindedir.

## Fontlar ve lisans

Gömülü font [Noto Sans](https://github.com/notofonts/latin-greek-cyrillic)
Regular (v2.015), SIL Open Font License 1.1 altındadır; lisans metni
`assets/fonts/OFL.txt`. Font her derlenen programa gömülür (~620 KB).
