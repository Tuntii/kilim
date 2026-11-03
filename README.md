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

require github.com/tuntii/kilim v0.0.0
replace github.com/tuntii/kilim => ../GUI
```

Henüz yayımlanmış bir sürüm etiketi yok; şimdilik `replace` ile yerel yolu
gösterin (`../GUI` yerine klonun yolu). v0.1.0 etiketi çıkınca `require` o sürümü
adlandırır ve `replace` gerekmez.
Modül yolu küçük harftir: iyi büyük harfe izin vermez.

Kodda:

```crystal
import github.com/tuntii/kilim                           # Kilim.window, Kilim.column, ...
import github.com/tuntii/kilim/kilim/widget::{Widget}    # isteğe bağlı: kısa ad için
```

`import github.com/tuntii/kilim` kurucu fonksiyonları `Kilim` altında verir:
`window`, `column`, `row`, `label`, `button`, `checkbox`, `textbox`, `scroll`
ve boyut kısayolları `fit`, `fixed(v)`, `fill(weight)`. Widget tipleri kendi
alt modüllerinde durur (`kilim/label`, `kilim/button`, `kilim/checkbox`,
`kilim/textbox`, `kilim/scroll`, `kilim/box`, `kilim/event`, `kilim/window`);
yalnızca `import github.com/tuntii/kilim` yeter, tipler nitelikli adla yazılır
(`Kilim::Widget::Widget`, `Kilim::Box::Box`). Kısa ad (`Widget`) istenirse
`github.com/tuntii/kilim/kilim/<ad>::{Tip}` ayrıca içe aktarılır.
Çocuk dizileri `[a, b] of Kilim::Widget::Widget` (veya `of Widget`) biçiminde yazılır.

Not: `fill` boyutlu bir Textbox `row` içine konur; doğrudan `column` içinde
boyutlandırma dikey olur.

Bu yol gerçek bir tüketici projesiyle denendi (iyi 0.20.0, Windows).

## İlk sürümün sınırları

Kapsam dışı: menü çubuğu, birden çok pencere (süreç başına bir pencere), resim
widget'ı, erişilebilirlik (ekran okuyucu), HiDPI ince ayarı, tema sistemi
(yalnızca açık tema), animasyon, sürükle-bırak; ayrıca IME, çok satırlı metin,
seçim ve seçimli kopyalama (yalnızca Ctrl/Cmd+V ile yapıştırma ve Ctrl/Cmd+C ile
tüm metni kopyalama), mobil ve web, kalıcılık. Çizim her değişiklikte pencerenin tamamını yeniden
çizer; metin her çizimde yeniden rasterleştirilir (önbellek yok). Borderlar HiDPI'da
1 fiziksel piksel inceliğindedir.

## Elle kontrol listesi

CI penceresiz çalışır; şunlar gerçek ekranda elle bakılmalıdır:

- Windows'ta %125-150 ekran ölçeklemesinde arayüz fiziksel olarak fazla küçük mü?
  SDL piksel yoğunluğunu 1 bildirip ölçeği `SDL_GetWindowDisplayScale`'e
  koyuyor olabilir.
- AltGr'li düzenlerde (Lehçe AltGr+C, Macarca AltGr+V) kopyala/yapıştır tetiklenmiyor,
  karakter yazılıyor.

CI ekran görüntüleri BMP'dir (tasarım belgesi PNG demişti).

## Fontlar ve lisans

Gömülü font [Noto Sans](https://github.com/notofonts/latin-greek-cyrillic)
Regular (v2.015), SIL Open Font License 1.1 altındadır; lisans metni
`assets/fonts/OFL.txt`. Font her derlenen programa gömülür (~620 KB).
