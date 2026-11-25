# Panduan Mekanik

Semua mekanik bisa dicoba di **`Scenes/contoh_mekanik.tscn`** (buka scene ini, lalu tekan F6).
Gambar tombol, gerbang, robot, dan tile miring masih placeholder. Desainer cukup mengganti file PNG-nya; mekaniknya tidak perlu diubah.

## Kontrol
| Tombol | Fungsi |
|---|---|
| A/D, ←/→ | jalan |
| Space, ↑, W | lompat |
| Q | membelah |
| Tab | ganti klon |
| Enter, Spasi (di menu) | mulai game |
| E | gabung (dekat kembaran) / aksi (contoh: menahan robot) |
| S, ↓ | turun menembus platform tembus *(baru)* |
| R | kembali ke checkpoint terakhir (box ikut kembali ke posisi awal) |

## Objek
| Scene | Cara pakai |
|---|---|
| `tombol.tscn` (biasa) | Ditekan klon atau box. Gerbang terbuka **selama** tombol ditekan, jadi tinggalkan satu klon di tombol. |
| `tombol box.tscn` | Hanya bisa ditekan **box**. |
| `tombol lift.tscn` | Ditekan klon atau box. Lift naik selama tombol ditekan, lalu turun lagi saat dilepas. |
| `gerbang.tscn` | Bergeser ke atas saat terbuka. Opsi: **Perlu Semua Tombol** (semua tombol yang terhubung harus ditekan bersamaan), **Tetap Terbuka**. |
| `box.tscn` | Didorong dengan berjalan ke arahnya. **Berat** = kekuatan minimal (besar = 3, sedang = 2, kecil = 1). Bawaan 2. |
| `platform_bergerak.tscn` | Atur **Jarak** (garis oranye di editor), **Kecepatan**, **Lebar**. Tanpa tombol: bolak-balik sendiri. Dihubungkan ke tombol lift: jadi lift. Opsi **Tembus Dari Bawah**. |
| `platform_tembus.tscn` | Bisa dilompati dari bawah, turun dengan S. Atur **Lebar**. |
| `robot.tscn` | Musuh patroli: berbalik di dinding dan di ujung lantai. Klon yang tersentuh mati. Klon besar menekan **E** di dekatnya = robot diam 3 detik dan tidak berbahaya. Opsi: Kecepatan, Arah, Kekuatan Penahan, Durasi Tahan. |
| `checkpoint.tscn` | Taruh di permukaan lantai. Disentuh klon mana pun = titik muncul baru. |
| `ujung_zona.tscn` | Taruh di permukaan lantai. Semua klon bersatu jadi satu karakter utuh, darah penuh, dan tempat ini jadi checkpoint. |
| Tile miring | Tabrakannya sudah segitiga, jadi karakter bisa jalan naik-turun. Untuk miring ke arah sebaliknya, pakai **flip horizontal** di TileMap. |

### Menghubungkan tombol ke gerbang / lift
Pilih tombol, lalu di Inspector isi **Target** dengan gerbang atau lift yang dikendalikan. Satu tombol boleh punya beberapa target, dan satu gerbang boleh dikendalikan beberapa tombol.
Kalau **Target kosong**, tombol otomatis memilih gerbang terdekat (tombol lift: lift terdekat). Ini hanya tebakan, jadi sebaiknya selalu diisi.
Sambungan di `game.tscn` saat ini:

| Gerbang | Tombol yang tersambung |
|---|---|
| gerbang | tombol biasa (tahan dengan klon kecil, checkpoint setelah pintu menyatukan klon) |
| gerbang2 | tombol biasa2 (tahan dengan satu klon) |
| gerbang3 | tombol biasa3 (tahan dengan klon kecil) |
| gerbang4 | tombol biasa4 (sumur bawah), biasa5 (pijakan tengah), biasa6 (celah atas, hanya klon kecil). Ketiganya **ditekan bersamaan**, lalu pintu tetap terbuka. Tekan R untuk kembali jadi karakter besar. |
| gerbang5 | tombol biasa7 (tahan dengan satu klon; juga menggerakkan `platform_api`) |
| gerbang6 | tombol box2 (hanya box; panah tetap menembak dan box di tombol menahannya) |
| gerbang7 | tombol box3, box4, box5 di tiga tanjakan (**ditekan bersamaan** oleh 3 klon, lalu pintu tetap terbuka) |
| gerbang9 (gerbang 4) | tombol biasa12 |
| gerbang10 (pintu atap) | tombol biasa12 |
| gerbang12 (gerbang utama) | tombol box6: tombol terakhir, ditekan dengan `box_utama` |
| gerbang11 (gerbang 1) | tombol biasa9 |


## Darah & checkpoint (autoload `Permainan`)
- Checkpoint baru yang disentuh menyatukan semua klon jadi satu karakter utuh (aturan sketsa).
- Klon mati saat masih ada klon lain: **darah −1**, dan kembarannya membesar (logika asli dari `karakter.gd`).
- **Darah habis**, atau **karakter terakhir mati**: muncul lagi di checkpoint terakhir dengan darah penuh. Level **tidak** di-reset (gerbang dan box tetap di posisinya).
- Jumlah darah: `maks_darah` di `Scenes/permainan.gd` (3–5).
- HUD di kiri atas: darah dan jumlah klon.

## Perubahan di file lama
- `karakter.gd`: bagian yang diubah ditandai `[MEKANIK]` (daftar ke sistem darah, darah/checkpoint saat mati, tombol E untuk aksi, turun dari platform tembus).
- `karakter.tscn`: `collision_mask = 5` (supaya bisa berdiri di platform tembus) dan pengaturan lantai miring.
- `gerbang`, `box`, `robot`, dan ketiga `tombol`: tipe node utama diganti (StaticBody2D / CharacterBody2D / Area2D) dan diberi script. Gambar tetap sama.
- `game.tscn`: bentuk tabrakan tile miring jadi segitiga; `tombol biasa` → Target `gerbang`; `tombol biasa2` → Target `gerbang2`; `tombol biasa3` → Target `gerbang3`; `tombol biasa4/5/6` → Target `gerbang4`; `gerbang` sampai `gerbang4` → Tetap Terbuka; ditambah `LatarLab` dan `checkpoint_api` (x = 5500).
- `tests/uji_awal_level.gd`: tes awal level utama.
- `project.godot`: autoload `Permainan`, input `turun`, dan nama layer fisika.

## Layer fisika
1 = dunia & pemain, 3 = platform tembus, 4 = musuh (robot).

## Objek aksi baru (tombol E)
Masukkan node ke grup `interaksi`, lalu buat fungsi `bisa_interaksi(pemain) -> bool` dan `interaksi(pemain)`. Contohnya ada di `robot.gd`.

## Tes otomatis
```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_mekanik.gd
```

## Tempat sempit
- Karakter tidak pernah membesar di dalam atap/dinding. Saat membesar (kembaran mati, bergabung, ujung zona), dicari tempat lega terdekat (geser ke samping maks. ±120 px).
- Kembaran mati tapi tempatnya terlalu sempit: klon tetap kecil dulu dan **otomatis membesar begitu keluar** ke tempat lega.
- Bergabung (E) di tempat terlalu sempit ditolak dengan pesan.

## Catatan untuk desain level (`game.tscn`)
Ukuran karakter: tinggi badan besar 152 px, sedang 99 px, kecil 64 px. tinggi lompat: besar ±241 px (3 tile pas-pasan), sedang ±137 px, kecil ±70 px (belum bisa naik 1 tile).
- **Awal level:** tombol pertama ada di terowongan setinggi 1 tile (hanya klon kecil yang muat), dan setelah gerbang ada blok 3 tile yang hanya bisa dilompati karakter besar. Karena itu gerbang pertama dibuat **tetap terbuka** setelah ditekan sekali: klon penekan bisa ikut, lalu semua klon bergabung jadi besar.
- **Ruang antara gerbang dan gerbang2 (x ≈ 2520–5320):** `tombol biasa2` (di atas atap, y ≈ −735) sekarang membuka `gerbang2`, dan gerbang2 tetap terbuka. Jalurnya khusus karakter besar: naik blok 3 tile → lompat ke tangga menggantung (y −400 → −480 → −560) → platform y −720 → platform y −880 → turun ke atas atap → injak tombol → turun lagi → lewat gerbang2. Sudah diuji otomatis di `tests/uji_awal_level.gd`.

## Menu utama
`Scenes/menu_utama.tscn` adalah scene pertama saat game dijalankan (F5). Latar: `homescreen.png` (18 frame 640×360). Tombol: `START BUTTON.png` (6 frame 230×200). Posisi tombol diatur lewat `TOMBOL_TENGAH` di `menu_utama.gd`. Untuk mencoba level langsung, buka `game.tscn` lalu tekan F6.

## Jebakan api
`jebakan api.tscn` menyala 0,9 detik dan padam ±1,5 detik secara bergantian. Klon yang tersentuh api mati. Jebakan berjajar menyala bergelombang ke kanan (160 px/detik), jadi deretan panjang bisa dilewati dengan mengikuti celahnya. Opsi: **Lama Padam**, **Lama Nyala**, **Kecepatan Gelombang**, **Geser Waktu**.
`jebakan duri.tscn` juga mematikan. `jebakan panah.tscn` menembak panah setinggi badan: klon kecil lewat di bawahnya, dan box atau dinding menghentikannya.

## Background lab & kredit
`Scenes/latar_lab.tscn` dipasang di `game.tscn` (3 lapisan parallax + tabung). Warnanya diubah jadi abu-abu lewat `latar_lab.gdshader`: atur `gelap` dan `terang` untuk kontras. `tile.png` memakai versi Drive (sudut transparan) supaya sudutnya tidak menutupi background.
Kredit: **Warped Sci-Fi Lab oleh ansimuz (Luis Zuno)**, https://ansimuz.itch.io/warped-sci-fi-lab. Lisensi ada di `Assests/lab/LISENSI_ansimuz.txt`.

## Petunjuk pintu
Saat karakter aktif berada dalam 320 px dari pintu tertutup, cara membukanya muncul di bawah layar, termasuk arah tombol terdekat. Teksnya dibuat otomatis dari tombol yang tersambung. Untuk teks sendiri, isi **Petunjuk Khusus** pada gerbang. Saat tombol ditekan, muncul pesan arah pintu yang terbuka.
Pintu tanpa **Tetap Terbuka** menutup begitu tidak ada lagi tombol yang tertekan, termasuk kalau klon penekannya mati atau berpindah.

## Jalur utama setelah gerbang4
Diuji dari awal sampai ujung level oleh `tests/uji_seluruh_level.gd`.
1. Turun ke lantai bawah, injak `tombol lift`: `lift_jurang` menyeberangi jurang panjang.
2. Naik tangga ke `tombol biasa7`: `gerbang5` terbuka dan `platform_api` bergerak. Lewati deretan api mengikuti gelombangnya.
3. Naik ke platform, dorong `box2` ke lubang sampai jatuh ke tombol: gerbang6 terbuka. Belah sampai kecil, klon kecil lewat di atas box dan di bawah panah, lalu checkpoint setelah pintu menyatukan klon.
4. Injak `tombol lift4`. `lift_miring` membawa ke tingkat atas. Belah jadi 3 klon, turunkan klon ke tiap tanjakan, lalu tekan ketiga tombol bersamaan untuk `gerbang7`.
5. Lorong api atap: ikuti gelombang. Duri: tiga duri bisa dilompati karakter besar sambil berlari (lorongnya rendah, jadi lompatannya pendek).
6. Zona akhir, urutan tombol mengikuti jalan pemain: tombol dasar poros (`biasa11`, lift poros) → tombol abu (`biasa8`, lift aula) → tombol ruang api (`biasa10`, gerbang 2) → tombol lorong duri (`biasa9`, gerbang 1 dan `lift_atas`) → tombol di balik gerbang 1 (`biasa12`, pintu atap dan gerbang 4) → tombol ungu (`box6`, gerbang utama).
7. Tombol ungu paling akhir dan ditekan dengan box. Box tidak hancur kena panah.

Platform dengan **Tetap Aktif** terus bolak-balik setelah tombolnya ditekan sekali. Gerbang dengan **Perlu Semua Tombol** + **Tetap Terbuka** terbuka setelah semua tombol tertekan bersamaan, lalu tetap terbuka.
Aturan sketsa sudah diterapkan. Pengecualian: gerbang 4 dan 7 (tiga tombol bersamaan) serta pintu atap dan `gerbang9` di zona akhir tetap terbuka setelah dibuka, karena tidak ada klon tersisa yang bisa melanjutkan jalur kalau pintunya harus terus ditahan.

## Kehalusan gerak & gambar
- `project.godot`: physics interpolation aktif, jadi gerak tetap halus di layar 60/120/144 Hz.
- `karakter.gd` (ditandai `[HALUS]`): percepatan dan pengereman, toleransi lompat (coyote time dan buffer), animasi jalan mengikuti kecepatan, efek memipih/meregang, dan sedikit miring saat berlari. Nilainya ada di konstanta atas file.
- `game.gd`: kamera mengikuti karakter tiap frame layar.

## Tumpuk klon
Klon bisa berdiri di atas klon lain. Lompat dari atas klon memakai `BONUS_TUMPUK` (1,3× kecepatan lompat, di `karakter.gd`). Satu klon sedang tetap kalah tinggi dari karakter besar, tapi tumpukan dua klon sedang bisa lebih tinggi.

## Musuh robot anjing
`robot.tscn` memakai `Assests/robot_anjing.png`: "Meca Dog" oleh Blind Harpy Gamedev (CC0, https://opengameart.org/content/meca-dog), dirapikan dan diberi garis tepi. Animasi: `lari`, dan `takut` saat ditahan dengan E.

## Tambahan lift dan robot
- Klon yang ditumpuk ikut bergerak bersama klon di bawahnya, termasuk saat naik lift.
- `robot_setelah_gerbang4` berpatroli di lantai setelah gerbang4. Batasnya diatur lewat **Jarak Patroli**.

## Robot dan panah
- Hanya karakter besar yang bisa menahan robot dengan E. Klon sedang dan kecil harus melompatinya. Saran muncul sebagai balon di atas robot.
- Jebakan panah menembak sekitar tiap 4 detik. Atur dengan **Kecepatan Animasi** dan **Kecepatan Panah**.
- Lubang setelah deretan api sekarang mematikan. Lift dan tombol di dasar lubang sudah dihapus.

## Lampu, balon, dan HUD
- Lampu di atas tombol: abu-abu = siap ditekan, hijau = menyala, merah = terkunci karena tombol sebelumnya belum menyala.
- Cara membuka pintu muncul sebagai balon percakapan di pintu saat karakter mendekat (`balon.gd`).
- Darah memakai gambar hati: "Simple Pixel Hearts" (CC0), https://opengameart.org/content/simple-pixel-hearts.
- Panduan kontrol ada di balon di tempat mulai (`game.gd`).

## Level, menu, dan audio
- Nama game: **MITOSIS**. Daftar level ada di `LEVEL` pada `Scenes/permainan.gd`: Tutorial, Lab Bawah, Jalur Lift, dan Laboratorium Utama (`game.tscn` utuh) sebagai level terakhir. Saat bermain, tombol Menu atau Esc membuka menu jeda.
- Menu utama berisi Mulai, Kontrol, Pengaturan (volume dan layar penuh), dan Keluar. Mulai membuka pilihan level. Di tujuan level muncul kotak berhasil: lanjut ke level berikutnya atau kembali ke menu.
- Pintu memakai `Assests/pintu_lab.png`: "Scifi Door sprite" oleh davididev (CC0), warnanya disesuaikan dengan tile. Saat terbuka, panel pintu bergeser dan bingkainya tetap terlihat.
- Audio diputar lewat autoload `Suara` (`Scenes/suara.gd`). Sumber dan lisensi ada di `Assests/audio/LISENSI.txt`.
- Tes level: `tests/uji_level.gd`.
- Ujung zona memakai kapsul lift hitam-putih (`Assests/ujung_lift.png`), sumber dan lisensi ada di `Assests/ujung_lift_LISENSI.txt`.
