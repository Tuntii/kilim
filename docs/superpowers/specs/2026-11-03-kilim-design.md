# kilim: iyi için GUI kütüphanesi (tasarım)

Tarih: 2026-11-03 · Durum: taslak, onay bekliyor

Belgede iki tür karar var. "Kullanıcı" diye işaretlenenleri kullanıcı verdi. "(benim kararım)" diye işaretlenenleri tasarımı yazan kişi verdi; kullanıcı bunları okurken değiştirebilir.

## 1. Amaç ve gerekçe

[iyi](https://iyi.dev) (v0.20.0, Crystal derleyicisi üzerine kurulu, LLVM ile native derleniyor) ile masaüstü GUI uygulaması yazmayı sağlayan bir kütüphane. Model V dilinin `ui` modülü: widget'ları işletim sisteminin kontrolleri çizmez, kütüphane kendisi çizer. Bu yüzden uygulama her platformda aynı görünür (kullanıcı).

Bugün packs.iyi.dev'deki 50 paketin hiçbiri GUI, grafik ya da pencere kütüphanesi değil. kilim bu alandaki ilk paket olacak.

## 2. Hedefler

- **Sıfırdan widget'lar:** widget ağacını, layout'u, olay dağıtımını ve çizimi kilim kendisi yapar. Altında yalnızca SDL3 bulunur (kullanıcı).
- **Baştan üç platform:** Windows, Linux ve macOS'ta aynı kod çalışır (kullanıcı).
- **V benzeri bildirimsel API:** uygulama, iç içe çağrılarla kurulan bir widget ağacıdır (kullanıcı: "V lang'te olduğu gibi").
- **İlk sürümün bitiş ölçütü:** bölüm 6'daki todo uygulaması üç platformda çalışır (kullanıcı: "basit bir todo yapabilelim").

## 3. Hedef dışı (ilk sürümde yok)

Menü çubuğu, birden fazla pencere, resim widget'ı, ekran okuyucu ve erişilebilirlik desteği, HiDPI ince ayarı, tema sistemi, animasyon, sürükle-bırak, pano (clipboard) dışında sistem entegrasyonu, React/Flutter tarzı "state değişince ağacı baştan kur" modeli. (Benim kararım. Kullanıcıya gösterildi, itiraz gelmedi.)

## 4. Anti-hedefler (çalışsa bile başarısız sayılacak durumlar)

- **Başka bir GUI kütüphanesine binding olmak.** raygui, microui, Dear ImGui, libui, GTK gibi hazır widget katmanları kullanılmaz. Kullanıcı açıkça "sıfırdan" dedi.
- **`--crystal` gerektirmek.** kilim düz iyi modülü olarak (`.iyi` dosyaları, `iyi.mod`) derlenmeli ve Crystal'ın standart kütüphanesini ya da shard'larını programa sokmamalı. iyi'nin küçük binary avantajı kaybolmamalı. (Benim kararım.)
- **Sadece Windows'ta çalışan bir ilk sürüm.** Linux ve macOS testsiz kalırsa iş bitmiş sayılmaz.
- **Boşta CPU yakmak.** Hiçbir şey değişmezken uygulama sürekli yeniden çizim yapmamalı (bölüm 5.4).

## 5. Kısıtlar ve verilen kararlar

### 5.1 Dil ve platform

- iyi 0.20.0, sürüm 1.0'dan önce. Dil sürümler arasında değişebilir. Kullanılan iyi sürümü `iyi.mod`/README'de sabitlenir.
- iyi'nin resmi olarak desteklediği masaüstü hedefleri: **Windows x86-64** (Visual C++ build tools gerekir), **Linux x86-64** (glibc) ve **macOS arm64** (14.4 ve üstü). kilim'in "üç platform" hedefi tam olarak bu üçüdür. Intel Mac ve Linux aarch64 hedef dışıdır.
- **C FFI:** `.iyi` dosyalarında `@[Link("...")] lib LibX ... fun ... end` yazılabiliyor. iyi'nin std'si de böyle bağlanıyor (örnek: `src/std/random.iyi`). SDL3 ve SDL3_ttf bu yolla bağlanır. Sadece kullanılan fonksiyonlar bağlanır.
- **C'den iyi'ye tek bir callback var.** Olaylar normalde `SDL_PollEvent`/`SDL_WaitEvent` döngüsüyle çekilir. Windows ve macOS'ta pencere fareyle sürüklenerek boyutlandırılırken bu döngü durur. Layout'un sürükleme sırasında da canlı güncellenmesi için yalnızca pencere boyutu ve yeniden çizim olaylarına bakan bir `SDL_AddEventWatch` callback'i kullanılır. iyi'de proc'lar C fonksiyon işaretçisine çevrilebiliyor (`src/iyi/thread.iyi`). Kullanıcı verisi `std/box` ile taşınır. Başka callback eklenmez. (Benim kararım.)
- **Erken doğrulanacak riskler:** (1) iyi'nin `main`'i macOS'ta ana thread'de çalıştırıp çalıştırmadığı. SDL bunu gerektirir. (2) `SDL_AddEventWatch` callback'inin iyi'nin çöp toplayıcısıyla güvenli çalışıp çalışmadığı. İkisi de planın ilk adımlarında küçük denemelerle kontrol edilir.
- **iyi sürümü:** ilk sürüm boyunca iyi 0.20.0'a sabitlenir. Yeni bir iyi sürümüne bilinçli bir kararla geçilir. iyi'de bir hata kilim'i engellerse önce kilim içinde etrafından dolaşılır ve yapılan şey koda `shortcut:` yorumuyla yazılır. iyilang/iyi'ye issue açmak ya da PR göndermek her seferinde kullanıcıya sorulur. (Benim kararım.)

### 5.2 Katmanlar

| Katman | Ne yapar | Karar |
|---|---|---|
| SDL3 | Pencere, olaylar, metin girişi (`SDL_StartTextInput`, `SDL_EVENT_TEXT_INPUT` ile UTF-8), pano | kullanıcı |
| Çizim | `SDL_Renderer`: dolu ve kenarlıklı dikdörtgen, kırpma (`SDL_SetRenderClipRect`) | benim kararım |
| Metin | SDL3_ttf, programa gömülü açık lisanslı bir font. Türkçe karakterler (ç ğ ı İ ö ş ü) görünür ve yazılabilir | benim kararım |
| kilim | Widget ağacı, layout, odak, olay dağıtımı, varsayılan tema | sıfırdan yazılır |

OpenGL ve Vulkan kullanılmaz. `SDL_Renderer` arkada zaten GPU kullanıyor.

**Koordinatlar ve HiDPI (benim kararım):** layout, tıklama tespiti ve kırpma mantıksal birimlerle (SDL'in pencere koordinatlarıyla) yapılır. Pencere `SDL_WINDOW_HIGH_PIXEL_DENSITY` ile açılır, renderer pencerenin piksel yoğunluğuna göre ölçeklenir, metin de bu yoğunlukta rasterleştirilir. Böylece Retina ekranlarda metin bulanık görünmez. Ekranlar arasında taşınınca ölçeğin değişmesi gibi ince ayarlar hedef dışıdır.

### 5.3 API modeli (benim kararım)

- **Retained-mode, kalıcı widget nesneleri.** Ağaç bir kez kurulur. Uygulama widget'ları doğrudan değiştirir (`list.add(row)`, `label.text = "..."`, `list.remove(row)`) ve kilim değişen ağacı yeniden düzenleyip çizer.
- **Bildirimsel kurulum, V tarzı.** Hedeflenen kullanım hissi aşağıda. Tam sözdizimi iyi'nin isimli argüman, proc ve blok kurallarına göre builder'a bırakılmıştır:

```
import kilim

input = kilim.textbox(placeholder: "Yapılacak iş...")
list  = kilim.column(spacing: 4)

app = kilim.window(title: "Todo", width: 420, height: 560,
  child: kilim.column(padding: 12, spacing: 8, children: [
    kilim.row(spacing: 8, children: [
      input,
      kilim.button("Ekle", on_click: -> { ... })
    ]),
    kilim.scroll(child: list)
  ]))
app.run
```

- Olay işleyiciler iyi `Proc`'larıdır ve tamamen iyi içinde çağrılır.

### 5.4 Döngü ve çizim (benim kararım)

- Olay odaklı çalışır. Olay yokken `SDL_WaitEvent` ile beklenir. Bir olay ya da widget değişikliği ekranı "kirli" işaretler ve bir sonraki turda ekran yeniden çizilir.
- İlk sürümde her çizim tüm pencereyi baştan çizer. Kısmi yeniden çizim yoktur.
  - `shortcut: tam yeniden çizim, ancak çok büyük ağaçlarda yavaşlarsa kısmi çizime geçilir.`
- Textbox imleci yanıp sönecekse bunun için bir zamanlayıcı gerekir. Zamanlayıcı yalnızca bir textbox odaktayken çalışır.

### 5.5 İlk sürümün widget seti

`window`, `column`, `row`, `label`, `button`, `textbox`, `checkbox`, `scroll`.

- **Layout:** satır ve sütun, `padding`, `spacing`, her çocuk için "içeriği kadar", "sabit" ya da "kalan alanı paylaş" boyutlandırması. Pencere yeniden boyutlanınca layout güncellenir.
- **Odak:** tıklanan textbox klavyeyi alır, Tab/Shift+Tab ile odaklanabilir widget'lar arasında geçilir, odaktaki widget görsel olarak belli olur.
- **textbox:** UTF-8 metin girişi, imleç, sol/sağ ok, Home/End, Backspace/Delete, Enter ile `on_submit`, pano ile yapıştırma (Ctrl/Cmd+V, imlecin olduğu yere). İlk sürümde metin seçimi yoktur. Bu yüzden Ctrl/Cmd+C textbox'taki metnin tamamını kopyalar. (Benim kararım. Seçim gelince kopyalama seçili kısma daraltılır.)
- **scroll:** fare tekerleği ile dikey kaydırma ve görsel bir kaydırma çubuğu. Taşan içerik kırpılır.
- **button:** üzerine gelme (hover) ve basılı olma durumları ile `on_click`. Klavyede odaktayken Space/Enter da tıklama sayılır.
- **checkbox:** `checked` durumu ve `on_change`.

### 5.6 Tema (benim kararım)

Tek bir sade, açık renkli varsayılan tema olacak. Renkler ve ölçüler tek bir yerde sabit olarak durur, böylece ileride tema sistemine geçmek kolaylaşır. İlk sürümde değiştirme API'si yoktur.

### 5.7 Paket ve repo

- **Ad:** `kilim` (kullanıcı).
- **Repo:** şimdilik bu `GUI` klasörü bir git reposu olur. Daha sonra kullanıcının GitHub hesabına (`Tuntii`) yüklenir ve `iyi get github.com/Tuntii/kilim` ile kurulur (benim kararım).
- Paket iyi'nin `iyi.mod` kurallarına uyar. Modüller `kilim` adının altında yaşar.

### 5.8 Test ve doğrulama (benim kararım)

- **CI:** GitHub Actions üzerinde Windows, Ubuntu ve macOS arm64 runner'ları kullanılır. Her değişiklikte örnek uygulamalar derlenir, sanal ya da gizli pencerede başlatılır, bir kare çizilir ve PNG ekran görüntüsü artifact olarak saklanır. Linux'ta Xvfb ya da SDL'in offscreen sürücüsü kullanılabilir.
- **Birim testleri:** layout hesabı, odak sırası, textbox düzenleme mantığı (UTF-8 imleç hareketi dahil) ve olay yönlendirme (hangi widget'ın tıklandığını bulma) SDL olmadan test edilebilecek şekilde yazılır.
- **Kayıtlı olay testi:** todo örneğine sahte olaylar (tıklama, metin girişi, Enter) verilir ve ağacın beklenen hâle geldiği doğrulanır.
- **Linux ve macOS için kanıt CI'dır (kullanıcı).** Derlenme, açılma, çizim ve sahte olay testleri CI'da geçerse ilk sürüm için yeterlidir. Gerçek klavye, tekerlek ve boşta CPU, Windows'ta elle denenir. Linux'ta elle deneme ileride kullanıcının VBOT sunucusunda, macOS'ta ise bir arkadaşının Mac'inde yapılabilir. Sorun çıkarsa issue olarak ele alınır.
- **Ekran görüntüleri insanların bakması içindir.** Platformlar arasında piksel piksel karşılaştırma (golden image) yapılmaz.
- **Linux:** CI'da X11 (Xvfb) kullanılır. Wayland SDL3 tarafından desteklendiği için çalışması beklenir, ama CI'da test edilmez.

## 6. Kabul ölçütü: todo örneği

`examples/todo.iyi` üç platformda aynı koddan derlenir ve çalışır:

1. Pencerenin üstünde bir textbox ve bir "Ekle" butonu vardır.
2. Metin yazılıp "Ekle"ye basılınca ya da Enter'a basılınca yeni bir satır eklenir ve textbox temizlenir. Boş metin eklenmez.
3. Her satırda bir checkbox, metin ve bir "Sil" butonu vardır. Checkbox işaretlenince metin farklı görünür (örneğin soluk ya da üstü çizili). "Sil" satırı kaldırır.
4. Liste pencereye sığmayınca tekerlekle kaydırılabilir.
5. "Çalışma şöğüt ılık İzmir" gibi Türkçe metin yazılabilir ve doğru görünür.
6. Pencere yeniden boyutlandırılınca layout doğru şekilde uyum sağlar.
7. Boştayken CPU kullanımı yaklaşık sıfırdır.

Kalıcılık (todo'ları dosyaya kaydetme) ilk sürümde yoktur.

## 7. Builder'a bırakılanlar

- Modül ve dosya yapısı, widget'ların iyi'de nasıl modellendiği (`class` ve kalıtım, `trait` ve `impl` ya da ikisinin karışımı).
- İsimli argümanların, varsayılan değerlerin ve proc'ların tam sözdizimi (bölüm 5.3'teki örnek bir his örneğidir, birebir sözdizimi değildir).
- Hangi açık lisanslı fontun gömüleceği (Türkçe karakterleri kapsamalı, lisansı yeniden dağıtıma izin vermeli) ve gömme yöntemi.
- Kullanıcının SDL3 ve SDL3_ttf'yi nasıl edineceği (Windows'ta DLL'leri exe'nin yanına koymak, Linux'ta paket yöneticisi, macOS'ta Homebrew). Bu, README'de açıkça yazılmalıdır.
- Layout algoritmasının ayrıntıları ve tema renkleri/ölçüleri.
