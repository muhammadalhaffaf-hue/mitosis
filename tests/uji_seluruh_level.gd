extends SceneTree
## Tes jalur utama setelah gerbang4 sampai ujung level (Scenes/game.tscn).
## Tiap bagian dimulai dari titik tertentu dengan karakter besar dan memakai input sungguhan.
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_seluruh_level.gd

var gagal := 0
var lv: Node
var P: Node
var a


func cek(kondisi: bool, teks: String) -> void:
	print(("  OK    " if kondisi else "  GAGAL ") + teks + ("" if kondisi else "  [x=%d kaki=%d hidup=%s]" % [x(), kaki(), hidup()]))
	if not kondisi:
		gagal += 1


func tunggu(n: int) -> void:
	for i in n:
		await physics_frame


func hidup() -> bool:
	return is_instance_valid(a) and not a.mati


func kaki() -> float:
	return a.global_position.y + 73.0 if is_instance_valid(a) else 99999.0


func x() -> float:
	return a.global_position.x if is_instance_valid(a) else -99999.0


func taruh(px: float, lantai: float) -> void:
	a.global_position = Vector2(px, lantai - 77.0)
	a.velocity = Vector2.ZERO


func mulai(px: float, lantai: float) -> void:
	while P._respawn_tertunda:
		await physics_frame
	P.respawn()
	await physics_frame
	a = load("res://Scenes/karakter.gd").aktif
	await tunggu(3)
	taruh(px, lantai)
	await tunggu(12)


func lepas() -> void:
	for aksi in ["kanan", "kiri", "lompat"]:
		Input.action_release(aksi)


func jalan(x_tujuan: float, maks := 900) -> void:
	var arah := 1 if x_tujuan > x() else -1
	Input.action_press("kanan" if arah > 0 else "kiri")
	for i in maks:
		await physics_frame
		if not hidup() or (x() - x_tujuan) * arah >= 0:
			break
	lepas()
	await tunggu(25)


func lompat_ke(x_tujuan: float) -> void:
	var aksi := "kanan" if x_tujuan > x() else "kiri"
	Input.action_press(aksi)
	Input.action_press("lompat")
	await physics_frame
	await physics_frame
	Input.action_release("lompat")
	for i in 170:
		await physics_frame
		if not hidup():
			for ar in lv.find_children("*", "Area2D", true, false):
				if is_instance_valid(a) and ar.get_overlapping_bodies().has(a):
					print("    kena: ", ar.get_parent().get_parent().name, " di ", ar.global_position)
			break
		if absf(x() - x_tujuan) < 8.0:
			Input.action_release(aksi)
		if i > 5 and a.is_on_floor():
			break
	lepas()
	await tunggu(12)


# Lari lalu lompat saat melewati x_tolak, berhenti setelah mendarat.
func lompat_lari(x_tolak: float) -> void:
	Input.action_press("kanan")
	for i in 300:
		await physics_frame
		if not hidup() or x() >= x_tolak:
			break
	await tekan("lompat")
	for i in 90:
		await physics_frame
		if not hidup() or (i > 4 and a.is_on_floor()):
			break
	lepas()
	await tunggu(6)


func tekan(aksi: String) -> void:
	Input.action_press(aksi)
	await physics_frame
	await physics_frame
	Input.action_release(aksi)


# Naik ke platform saat berada di titik awal, tunggu sampai t tercapai.
func naik(pf, t_tujuan: float) -> void:
	for i in 1800:
		if pf._t < 0.03:
			break
		await physics_frame
	a.global_position = pf.global_position + Vector2(0, -12.0 - 77.0)
	a.velocity = Vector2.ZERO
	for i in 1800:
		await physics_frame
		if not hidup() or pf._t >= t_tujuan:
			break


# Berjalan mengikuti gelombang api, tetap di fase padam.
func ikut_api(x_akhir: float, geser: float) -> void:
	for i in 1800:
		var waktu := Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)
		var sasaran := 160.0 * (waktu - 0.3) + geser
		sasaran += ceilf((x() - sasaran - 40.0) / 384.0) * 384.0
		if i == 0:
			a.global_position.x = sasaran
		var kanan := x() < sasaran - 4.0
		if kanan: Input.action_press("kanan")
		else: Input.action_release("kanan")
		await physics_frame
		if not hidup() or x() >= x_akhir:
			break
	lepas()
	await tunggu(5)


func _initialize() -> void:
	lv = load("res://Scenes/game.tscn").instantiate()
	root.add_child(lv)
	current_scene = lv
	P = root.get_node("Permainan")
	await tunggu(30)
	var G := func(n: String): return lv.get_node("gerbangg/" + n)

	print("HUD dan panduan")
	cek(P._hati.get_child_count() == P.maks_darah and P._hati.get_child(0).texture != null, "darah tampil sebagai gambar hati")
	var ada_panduan := false
	for n in lv.get_children():
		if n is Balon and "kembali ke checkpoint" in n._label.text:
			ada_panduan = true
	cek(ada_panduan, "panduan kontrol ada di tempat mulai")
	var t_lampu = lv.get_node("tombol_biasa/tombol biasa")
	cek(t_lampu._lampu.color == t_lampu.WARNA_MATI, "lampu tombol mati sebelum ditekan")

	print("Tombol R")
	await mulai(5000, 0)
	var lama = a
	await tekan("ulang")
	await tunggu(5)
	a = load("res://Scenes/karakter.gd").aktif
	cek(a != lama and pemain_satu(), "R: kembali ke checkpoint")

	print("Ruang lift jurang")
	var l1 = lv.get_node("lift_jurang")
	await mulai(11798, 640)
	cek(l1._sudah_aktif, "tombol lift mengaktifkan platform")
	await naik(l1, 0.97)
	await jalan(14200)
	cek(hidup() and absf(kaki() - 720) < 6, "platform menyeberangi jurang panjang")

	print("Tangga ke tombol biasa7")
	await lompat_ke(14400)
	await jalan(14620)
	await lompat_ke(14790)
	cek(absf(kaki() - 400) < 6, "naik ke pijakan y 400")
	await lompat_ke(14560)
	await jalan(14440)
	cek(G.call("gerbang5").terbuka and lv.get_node("platform_api")._sudah_aktif, "tombol biasa7: gerbang5 terbuka, platform aktif")

	print("Deretan api panjang")
	await mulai(15000, 400)
	await naik(lv.get_node("platform_api"), 0.97)
	cek(hidup() and x() > 16200, "platform membawa ke atas deretan api")
	await mulai(16380, 720)
	await ikut_api(17745, 91.0)
	cek(hidup() and x() >= 17745, "deretan api bisa dilewati mengikuti gelombang")
	await lompat_ke(18150)
	await jalan(18400)
	cek(hidup() and x() > 18300, "lompati lubang sampai depan gerbang5")

	print("Tumpuk klon")
	await mulai(9400, 720)
	var puncak_besar := 0.0
	var y0 := kaki()
	await tekan("lompat")
	for i in 70:
		await physics_frame
		puncak_besar = maxf(puncak_besar, y0 - kaki())
	await tunggu(20)
	await tekan("membelah")
	await tunggu(120)
	var K2 = load("res://Scenes/karakter.gd")
	var dua_t: Array = get_nodes_in_group("pemain")
	dua_t[0].global_position = Vector2(9300, 660)
	dua_t[1].global_position = Vector2(9450, 660)
	a = dua_t[1]
	K2.aktif = a
	await tunggu(15)
	var lantai_y: float = a.global_position.y
	await tekan("lompat")
	var puncak_sedang := 0.0
	for i in 70:
		await physics_frame
		puncak_sedang = maxf(puncak_sedang, lantai_y - a.global_position.y)
	cek(puncak_sedang < puncak_besar, "lompatan satu klon sedang tetap kalah dari karakter besar")
	a.global_position = dua_t[0].global_position + Vector2(0, -115)
	a.velocity = Vector2.ZERO
	await tunggu(25)
	cek(a.is_on_floor() and a.global_position.y < lantai_y - 80, "klon bisa berdiri di atas klon lain")
	await tekan("lompat")
	var puncak_tumpuk := 0.0
	for i in 80:
		await physics_frame
		puncak_tumpuk = maxf(puncak_tumpuk, lantai_y - a.global_position.y)
	cek(puncak_tumpuk > puncak_besar + 30, "tumpukan melompat lebih tinggi dari karakter besar (%d vs %d)" % [puncak_tumpuk, puncak_besar])

	print("Lubang setelah deretan api")
	await mulai(17920, 720)
	a.global_position = Vector2(18000, 1000)
	for i in 200:
		if not hidup():
			break
		await physics_frame
	cek(not hidup(), "jatuh ke lubang: karakter mati")

	print("Box ke gerbang6")
	var box = lv.get_node("box2")
	var g6 = G.call("gerbang6")
	await mulai(18760, 560)
	await lompat_ke(19110)
	cek(absf(kaki() - 400) < 6, "naik ke platform box")
	await jalan(19420)
	await lompat_ke(19800)
	await jalan(20000)
	await lompat_ke(20320)
	await jalan(19690)
	await tunggu(40)
	cek(box.global_position.y > 600 and g6.terbuka, "box jatuh ke tombol: gerbang6 terbuka")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var kc6: Array = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 2)
	for p in get_nodes_in_group("pemain"):
		if p.tingkat == 1:
			p.global_position = Vector2(19800, 340)
	kc6[1].global_position = Vector2(19900, 360)
	kc6[0].global_position = Vector2(19710, 360)
	await tunggu(15)
	a = kc6[0]
	load("res://Scenes/karakter.gd").aktif = a
	await jalan(19640)
	await tunggu(20)
	var trap_box = lv.get_node("jebakan panah")
	for i in 420:                      # turun tepat setelah panah menabrak box
		if trap_box.sprite.frame == 4 and get_nodes_in_group("panah").filter(func(p): return absf(p.global_position.y - 640.0) < 30.0 and p.global_position.x < 20100.0).size() == 1 and get_nodes_in_group("panah").filter(func(p): return absf(p.global_position.y - 640.0) < 30.0).front().global_position.x < 19760.0:
			break
		await physics_frame
	await tunggu(12)
	await jalan(20700)
	a = load("res://Scenes/karakter.gd").aktif
	cek(hidup() and x() > 20550 and pemain_satu() and a.tingkat == 0, "klon kecil lewat atas box, checkpoint menyatukan semua")

	print("Ruang miring (3 tombol bersamaan)")
	var g7 = G.call("gerbang7")
	var l3 = lv.get_node("lift_miring")
	var KM = load("res://Scenes/karakter.gd")
	await mulai(21479, 640)
	cek(l3._sudah_aktif, "tombol lift aktif")
	await naik(l3, 0.985)
	await lompat_ke(21800)
	await jalan(22000)
	cek(absf(kaki() + 320) < 8, "lift sampai tingkat paling atas")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var semua: Array = get_nodes_in_group("pemain")
	var bsr = semua.filter(func(p): return p.tingkat == 1)[0]
	var kc: Array = semua.filter(func(p): return p.tingkat == 2)
	bsr.global_position = Vector2(21850, -375)
	kc[1].global_position = Vector2(21950, -360)
	kc[0].global_position = Vector2(22050, -360)
	await tunggu(15)
	a = bsr
	KM.aktif = a
	await jalan(21735)
	await jalan(21650)
	await jalan(22100)
	cek(not g7.terbuka, "tombol bawah saja: pintu belum terbuka")
	a = kc[1]
	KM.aktif = a
	await jalan(21735)
	await jalan(22100)
	cek(not g7.terbuka, "dua tombol: pintu belum terbuka")
	a = kc[0]
	KM.aktif = a
	await jalan(22100)
	cek(g7.terbuka, "tiga tombol bersamaan: pintu terbuka")
	for r in get_nodes_in_group("robot"):
		r.sisa_tahan = 6000.0
	await mulai(22500, 720)
	await jalan(22880)
	cek(hidup() and x() > 22800, "lewat gerbang7")

	print("Lorong api atap, duri, robot")
	await mulai(23000, 720)
	await ikut_api(24640, -91.0)
	cek(hidup() and x() >= 24640, "lorong api atap bisa dilewati")
	for r in get_nodes_in_group("robot"):
		r.sisa_tahan = 600.0
	for duri_x in [24690.0, 24935.0, 25175.0]:
		await lompat_lari(duri_x)
		cek(hidup(), "karakter besar melompati duri (tolakan x=%d)" % duri_x)
	await jalan(25500)
	cek(hidup() and x() >= 25480, "lorong duri terlewati tanpa membelah")
	for r in get_nodes_in_group("robot"):
		r.sisa_tahan = 0.0
	await lewati_robot(27100)
	cek(hidup() and x() >= 27100, "melewati robot (ditahan dengan E)")

	print("Lift akhir dan lorong atas")
	var l5 = lv.get_node("lift_akhir")
	await mulai(27320, 640)
	cek(l5._sudah_aktif, "tombol lift akhir aktif")
	await naik(l5, 1.0)
	await lompat_ke(27150)
	cek(hidup() and absf(kaki() + 1600) < 8, "lift sampai ke atap")
	for r in get_nodes_in_group("robot"):
		r.sisa_tahan = 6000.0
	lv.get_node("jebakan panah2").sprite.stop()   # panah diuji terpisah
	for p in get_nodes_in_group("panah"):
		p.queue_free()
	var g1 = G.call("gerbang11")
	var g2 = G.call("gerbang8")
	var g3 = G.call("gerbang10")
	var g4 = G.call("gerbang9")
	var g_utama = G.call("gerbang12")
	var poros = lv.get_node("lift_poros")
	await jalan(24360)
	await tunggu(40)
	cek(hidup() and absf(kaki() + 1360) < 8, "turun lewat celah atap")
	await jalan(25200)
	await tunggu(30)
	cek(hidup() and absf(kaki() + 1120) < 8, "turun ke lorong tengah")

	print("Zona akhir: urutan tombol")
	var T = func(n: String): return lv.get_node(n)
	var t_a = T.call("tombol_biasa/tombol biasa11")
	var t_b = T.call("tombol_biasa/tombol biasa8")
	var t_c = T.call("tombol_biasa/tombol biasa10")
	var t_d = T.call("tombol_biasa/tombol biasa9")
	var t_e = T.call("tombol_biasa/tombol biasa12")
	var t_ungu = T.call("tombol_box/tombol box6")
	var L = func(n: String): return lv.get_node(n)
	cek(not t_a.terkunci() and not t_b.terkunci() and not t_c.terkunci() and t_e.terkunci(), "tombol di jalur pertama tidak terkunci")
	await mulai(25600, -1120)
	await naik(L.call("platform_lorong2"), 1.0)
	await jalan(25900)
	cek(hidup() and absf(kaki() + 1120) < 8, "platform kecil menyeberangi celah pertama")
	await mulai(26000, -1120)
	await naik(L.call("platform_lorong"), 1.0)
	await jalan(26700)
	cek(hidup() and absf(kaki() + 1120) < 8, "platform bergerak menyeberangi lorong")

	await mulai(26960, 400)
	var K = load("res://Scenes/karakter.gd")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var kecil: Array = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 2)
	kecil[0].global_position = Vector2(26860, 360)
	await tunggu(15)
	a = kecil[0]
	K.aktif = a
	await jalan(26278)
	cek(t_a.ditekan and poros._sudah_aktif, "1. tombol di dasar poros bisa ditekan: lift poros menyala")
	await mulai(27000, 400)
	await naik(poros, 1.0)
	cek(hidup() and absf(kaki() + 1360) < 8, "lift poros naik ke lorong atas")
	await jalan(26119)
	cek(L.call("lift_tengah")._sudah_aktif, "2. tombol abu menyalakan lift aula bawah")
	await mulai(24680, 320)
	cek(L.call("lift_aula")._sudah_aktif, "tombol biru di aula menyalakan lift keluar")
	await naik(L.call("lift_tengah"), 1.0)
	await jalan(25239)
	cek(g2.terbuka and not g1.terbuka, "3. tombol ruang api membuka gerbang 2")
	await mulai(25680, 400)
	await naik(L.call("lift_aula"), 1.0)
	await jalan(25800)
	cek(hidup() and absf(kaki() + 80) < 8, "lift aula keluar ke lantai tengah")
	await naik(L.call("lift_ruang"), 1.0)
	await jalan(26220)
	cek(hidup() and absf(kaki() + 400) < 8, "lift ruang naik ke lantai atas")
	await mulai(23960, -480)
	cek(L.call("lift_kiri")._sudah_aktif, "tombol lift kiri aktif")
	await naik(L.call("lift_kiri"), 1.0)
	await jalan(24220)
	cek(hidup() and absf(kaki() + 800) < 8, "lift kiri sampai lorong gerbang 2")
	await jalan(24760)
	for t_x in [24850.0, 25090.0]:
		await lompat_lari(t_x)
	await jalan(25559)
	cek(hidup() and g1.terbuka and L.call("lift_atas")._sudah_aktif, "4. tombol lorong duri membuka gerbang 1 dan lift atas")
	await mulai(24005, -800)
	await naik(L.call("lift_atas"), 1.0)
	await jalan(24165)
	cek(hidup() and g3.terbuka and g4.terbuka, "5. tombol di balik gerbang 1 membuka pintu atap dan gerbang 4")
	await jalan(24520)
	cek(hidup() and x() > 24450, "lewat gerbang 1 ke lorong")
	cek(not g_utama.terbuka, "gerbang utama masih tertutup")
	await mulai(27000, 400)
	await naik(poros, 1.0)
	await lompat_ke(27170)
	cek(hidup() and kaki() < -1590, "lewat pintu atap ke atap")
	await lompat_ke(26800)
	await jalan(24360)
	await tunggu(40)
	await jalan(23865)
	cek(hidup() and t_ungu.ditekan and g_utama.terbuka, "6. tombol terakhir: box di tombol ungu membuka gerbang utama")
	await mulai(26800, -1600)
	await lompat_ke(27170)
	await jalan(27300)
	await tunggu(150)
	await jalan(28450)
	cek(hidup() and x() > 28300, "lewat gerbang utama")
	await tunggu(10)
	cek(lv.get_node("ujung_akhir").selesai, "sampai ujung level")

	await uji_tambahan()

	print("\nSELESAI: %s" % ("SEMUA LULUS" if gagal == 0 else "%d GAGAL" % gagal))
	quit(gagal)


func pemain_satu() -> bool:
	return get_nodes_in_group("pemain").size() == 1


# Jalan ke kanan; kalau robot dekat di depan, tahan dengan E lalu lewati.
func lewati_robot(x_tujuan: float) -> void:
	Input.action_press("kanan")
	for i in 1800:
		await physics_frame
		if not hidup() or x() >= x_tujuan:
			break
		for r in get_nodes_in_group("robot"):
			var d: Vector2 = r.global_position - a.global_position
			if r.sisa_tahan < 0.5 and absf(d.y) < 90.0 and d.x > -40.0 and d.x < 140.0:
				await tekan("menyatu")
	lepas()
	await tunggu(5)


# Bagian tambahan dipanggil dari _initialize lewat uji_tambahan().
func belah(kali: int) -> void:
	for i in kali:
		await tekan("membelah")
		await tunggu(120)


func kendalikan(k) -> void:
	a = k
	load("res://Scenes/karakter.gd").aktif = k
	await tunggu(15)


func cek_bersatu(batas_x: float, teks: String) -> void:
	await tunggu(5)
	a = load("res://Scenes/karakter.gd").aktif
	cek(hidup() and pemain_satu() and a.tingkat == 0 and x() > batas_x, teks)


func uji_tambahan() -> void:
	print("Tombol box, panah, bidang miring")
	var tombol = lv.get_node("tombol_box/tombol box2")
	var trap = lv.get_node("jebakan panah")
	var box = lv.get_node("box2")
	var g6 = lv.get_node("gerbangg/gerbang6")
	box._pindah_ke_awal()
	await tunggu(10)
	for p in get_nodes_in_group("panah"):
		p.queue_free()
	await mulai(19560, 720)
	cek(not tombol.ditekan and not g6.terbuka, "tombol box tidak bisa ditekan orang")
	var ada_panah := false
	for i in 320:
		await physics_frame
		if not get_nodes_in_group("panah").is_empty():
			ada_panah = true
			break
	cek(ada_panah, "jebakan panah menembak")
	var kena := false
	for i in 420:
		await physics_frame
		if not hidup():
			kena = true
			break
	cek(kena, "panah membunuh karakter di jalurnya")
	await mulai(18300, 720)
	box.global_position = Vector2(19300, 630)
	box.velocity = Vector2.ZERO
	await tunggu(320)
	cek(box.global_position.y > 600.0, "box menahan panah dan tidak hancur")
	box.global_position = Vector2(19560, 630)
	box.velocity = Vector2.ZERO
	await tunggu(20)
	await tunggu(20)
	cek(tombol.ditekan and g6.terbuka, "box di tombol: gerbang terbuka")
	await tunggu(320)
	cek(tombol.ditekan and g6.terbuka and box.global_position.y > 600.0, "box tetap di tombol walau kena panah")
	box._pindah_ke_awal()
	await tunggu(10)
	await mulai(20000, 400)
	Input.action_press("kanan")
	var dorong := 0
	for i in 40:
		await physics_frame
		if a.sprite.animation == "dorong":
			dorong += 1
	lepas()
	cek(dorong > 25, "animasi dorong terus tampil saat mendorong box (%d dari 40 frame)" % dorong)
	await mulai(21000, 720)
	a.global_position = Vector2(22300, 100)
	a.velocity = Vector2.ZERO
	await tunggu(25)
	var x_miring := x()
	await tunggu(60)
	cek(x() < x_miring - 30, "diam di bidang miring: karakter turun pelan")

	print("Tumpukan klon di lift")
	var l_kiri = lv.get_node("lift_miring")
	await mulai(21240, 720)
	await belah(1)
	var tp: Array = get_nodes_in_group("pemain")
	for i in 900:
		if l_kiri._t < 0.03:
			break
		await physics_frame
	tp[0].global_position = l_kiri.global_position + Vector2(0, -62)
	tp[0].velocity = Vector2.ZERO
	tp[1].global_position = l_kiri.global_position + Vector2(0, -175)
	tp[1].velocity = Vector2.ZERO
	await kendalikan(tp[1])
	for i in 900:
		await physics_frame
		if l_kiri._t >= 0.6:
			break
	cek(absf(tp[1].global_position.x - tp[0].global_position.x) < 12 and tp[1].global_position.y < tp[0].global_position.y - 80,
		"tumpukan klon tidak bergeser saat naik lift")

	print("Robot setelah gerbang4")
	var rb = lv.get_node("robot_setelah_gerbang4")
	rb.sisa_tahan = 0.0
	var xmin: float = rb.global_position.x
	var xmax: float = xmin
	for i in 900:
		await physics_frame
		xmin = minf(xmin, rb.global_position.x)
		xmax = maxf(xmax, rb.global_position.x)
	cek(xmax - xmin > 400 and xmin > 9950 and xmax < 11250, "robot mondar-mandir di lantai depan (%d..%d)" % [xmin, xmax])

	print("Melewati robot")
	rb.kecepatan = 0.0
	rb.sisa_tahan = 0.0
	rb.global_position = Vector2(10300, 675)
	await mulai(10080, 720)
	await belah(2)
	var kc_r: Array = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 2)
	var sd_r = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 1)[0]
	sd_r.global_position = Vector2(10175, 660)
	kc_r[1].global_position = Vector2(9950, 680)
	kc_r[0].global_position = Vector2(10100, 680)
	await kendalikan(sd_r)
	await process_frame
	cek(rb._balon.visible and "Lompati" in rb._balon._label.text, "dekat robot: balon menyarankan melompat")
	await tekan("menyatu")
	cek(rb.sisa_tahan <= 0.0, "klon sedang tidak bisa menahan robot")
	rb.sisa_tahan = 0.0
	sd_r.global_position = Vector2(9850, 660)
	await tunggu(10)
	await kendalikan(kc_r[0])
	await lompat_lari(10238)
	cek(hidup() and x() > 10335, "klon kecil bisa melompati robot")
	rb.kecepatan = 90.0

	print("Patroli robot lorong")
	var r3 = lv.get_node("robot3")
	var r4 = lv.get_node("robot4")
	r3.sisa_tahan = 0.0
	r4.sisa_tahan = 0.0
	var maks3: float = r3.global_position.x
	var maks4: float = r4.global_position.x
	for i in 1500:
		await physics_frame
		maks3 = maxf(maks3, r3.global_position.x)
		maks4 = maxf(maks4, r4.global_position.x)
	cek(maks3 < 25620 and maks4 < 26860 and absf(r3.global_position.y + 1168) < 40, "robot lorong tidak mendekati platform bergerak (%d, %d)" % [maks3, maks4])

	print("Gerbang hanya terbuka selama tombol ditekan")
	var g1 = lv.get_node("gerbangg/gerbang")
	await mulai(2200, 0)
	await belah(2)
	var kc: Array = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 2)
	var sd = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 1)[0]
	kc[0].global_position = Vector2(1559, -40)
	kc[1].global_position = Vector2(2100, -40)
	sd.global_position = Vector2(2350, -60)
	await kendalikan(sd)
	await tunggu(15)
	cek(g1.terbuka, "klon kecil menahan tombol: gerbang 1 terbuka")
	await jalan(2760)
	await cek_bersatu(2600, "lewat gerbang, checkpoint menyatukan semua klon")
	await tunggu(30)
	cek(not g1.terbuka, "penahan hilang: gerbang tertutup lagi")

	await mulai(2601, -720)
	await belah(1)
	var dua: Array = get_nodes_in_group("pemain")
	dua[0].global_position = Vector2(2601, -790)
	dua[1].global_position = Vector2(2800, -790)
	await kendalikan(dua[1])
	cek(lv.get_node("gerbangg/gerbang2").terbuka, "klon menahan tombol atap: gerbang2 terbuka")
	await jalan(3900)
	await jalan(4060)
	await lompat_ke(4390)
	await jalan(4628)
	await lompat_ke(4985)
	await jalan(5600)
	await cek_bersatu(5400, "klon sedang sampai checkpoint setelah gerbang2")

	await mulai(6100, 0)
	await belah(2)
	kc = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 2)
	sd = get_nodes_in_group("pemain").filter(func(p): return p.tingkat == 1)[0]
	kc[0].global_position = Vector2(5878, 360)
	sd.global_position = Vector2(6640, -60)
	await kendalikan(sd)
	await tunggu(15)
	cek(lv.get_node("gerbangg/gerbang3").terbuka, "klon kecil di lubang: gerbang3 terbuka")
	await jalan(7120)
	await cek_bersatu(7000, "lewat gerbang3, checkpoint menyatukan semua klon")

	await mulai(14440, 240)
	await belah(1)
	dua = get_nodes_in_group("pemain")
	dua[0].global_position = Vector2(14440, 180)
	dua[1].global_position = Vector2(17920, 640)
	await kendalikan(dua[1])
	cek(lv.get_node("gerbangg/gerbang5").terbuka, "klon di tombol biasa7: gerbang5 terbuka")
	await lompat_ke(18120)
	await jalan(18680)
	await cek_bersatu(18600, "lewat gerbang5, checkpoint menyatukan semua klon")
