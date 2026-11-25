extends SceneTree
## Tes bagian awal level utama (Scenes/game.tscn): terowongan tombol, gerbang pertama,
## membesar di tempat sempit, dan blok tinggi setelah gerbang.
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_awal_level.gd

const LANTAI := 0.0
var gagal := 0
var lv: Node


func cek(kondisi: bool, teks: String) -> void:
	print(("  OK    " if kondisi else "  GAGAL ") + teks)
	if not kondisi:
		gagal += 1


func tunggu(n: int) -> void:
	for i in n:
		await physics_frame


func tekan(aksi: String) -> void:
	Input.action_press(aksi)
	await physics_frame
	await physics_frame
	Input.action_release(aksi)


func pemain() -> Array:
	return get_nodes_in_group("pemain")


func aktif():
	return load("res://Scenes/karakter.gd").aktif


func ukuran(t: int) -> Array:
	return pemain().filter(func(p): return p.tingkat == t)


# Taruh karakter dengan kaki di lantai pada x tertentu.
func taruh(p, x: float, lantai := LANTAI) -> void:
	var tinggi: float = p.collision.shape.get_rect().size.y * p.collision.scale.y * p.scale.y
	p.global_position = Vector2(x, lantai - tinggi / 2.0 - 4.0)
	p.velocity = Vector2.ZERO


func kaki(p) -> float:
	return p.global_position.y + 73.0


# Tahan arah sampai x_target; kalau `lompat`, lompat setiap kali menyentuh lantai.
func lari(p, arah: int, x_target: float, lompat := true) -> void:
	Input.action_press("kanan" if arah > 0 else "kiri")
	for i in 600:
		if lompat and p.is_on_floor() and not Input.is_action_pressed("lompat"):
			Input.action_press("lompat")
		else:
			Input.action_release("lompat")
		await physics_frame
		if not is_instance_valid(p) or p.mati or (p.global_position.x - x_target) * arah >= 0:
			break
	Input.action_release("kanan")
	Input.action_release("kiri")
	Input.action_release("lompat")
	await tunggu(60)


# Satu lompatan terarah: tahan arah sampai x tujuan, lalu mendarat.
func lompat_ke(p, x_tujuan: float) -> void:
	var aksi := "kanan" if x_tujuan > p.global_position.x else "kiri"
	Input.action_press(aksi)
	Input.action_press("lompat")
	await physics_frame
	await physics_frame
	Input.action_release("lompat")
	for i in 150:
		await physics_frame
		if not is_instance_valid(p) or p.mati:
			break
		if absf(p.global_position.x - x_tujuan) < 8.0:
			Input.action_release(aksi)
		if i > 5 and p.is_on_floor():
			break
	Input.action_release(aksi)
	await tunggu(15)


# Badan karakter menembus dinding/atap?
func nyangkut(p) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = p.collision.shape
	q.collision_mask = 1
	q.transform = p.collision.global_transform.scaled_local(Vector2(0.9, 0.9))
	var ex: Array[RID] = []
	for o in pemain():
		ex.append(o.get_rid())
	q.exclude = ex
	return not p.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _initialize() -> void:
	lv = load("res://Scenes/game.tscn").instantiate()
	root.add_child(lv)
	await tunggu(40)

	print("Kontrol")
	var kode := InputMap.action_get_events("lompat").map(func(e): return e.physical_keycode)
	cek(KEY_SPACE in kode and KEY_UP in kode and KEY_W in kode, "lompat: Spasi, panah atas, W")

	print("Membelah sampai kecil")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	cek(pemain().size() == 3 and ukuran(2).size() == 2, "jadi 3 klon: 1 sedang + 2 kecil")

	print("Terowongan tombol & gerbang pertama")
	var g = lv.get_node("gerbangg/gerbang")
	var kecil: Array = ukuran(2)
	taruh(kecil[0], 1559)          # di dalam terowongan, di atas tombol
	taruh(kecil[1], 2200)
	taruh(ukuran(1)[0], 2300)
	await tunggu(40)
	cek(not nyangkut(kecil[0]), "klon kecil muat di terowongan")
	cek(g.terbuka, "klon kecil menekan tombol: gerbang terbuka")
	taruh(kecil[0], 2100)          # klon penekan keluar dari terowongan
	await tunggu(40)
	cek(not g.terbuka, "tombol dilepas: gerbang tertutup lagi")

	print("Kembaran mati saat yang lain di terowongan")
	taruh(kecil[0], 1680)          # jauh di dalam terowongan
	await tunggu(10)
	kecil[1].mati_sekarang()
	await tunggu(60)
	var sisa := ukuran(2)
	cek(sisa.size() == 1 and sisa[0] == kecil[0] and sisa[0].tunda_membesar,
		"terlalu sempit: klon tetap kecil dulu (tidak membesar di dalam atap)")
	cek(pemain().all(func(p): return not nyangkut(p)), "tidak ada karakter yang nyangkut")
	taruh(kecil[0], 2050)          # keluar dari terowongan
	await tunggu(60)
	cek(ukuran(2).is_empty() and ukuran(1).size() == 2, "keluar dari terowongan: langsung membesar")
	cek(pemain().all(func(p): return not nyangkut(p)), "hasil membesar tidak nyangkut")

	print("Bergabung di tempat sempit ditolak")
	var sedang := ukuran(1)
	taruh(sedang[0], 2300)
	taruh(sedang[1], 2310)
	load("res://Scenes/karakter.gd").aktif = sedang[0]
	await tunggu(20)
	await tekan("menyatu")
	await tunggu(90)
	cek(pemain().size() == 1 and aktif().tingkat == 0 and not nyangkut(aktif()),
		"di tempat lega: bergabung jadi karakter besar")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var dua := ukuran(2)
	taruh(dua[0], 1640)
	taruh(dua[1], 1650)
	load("res://Scenes/karakter.gd").aktif = dua[0]
	await tunggu(20)
	await tekan("menyatu")
	await tunggu(60)
	cek(ukuran(2).size() == 2 and pemain().all(func(p): return not nyangkut(p)),
		"di terowongan: bergabung ditolak, tidak nyangkut")

	print("Blok tinggi setelah gerbang")
	for p in pemain():
		if p != aktif():
			p.queue_free()
	await tunggu(2)
	var a = aktif()
	taruh(a, 2300)
	a.tunda_membesar = false
	await tunggu(5)
	# ganti dengan karakter besar
	var besar = load("res://Scenes/karakter.tscn").instantiate()
	a.get_parent().add_child(besar)
	load("res://Scenes/karakter.gd").aktif = besar
	a.queue_free()
	await tunggu(5)
	taruh(besar, 4200)
	await tunggu(20)
	Input.action_press("kanan")
	await tunggu(4)
	await tekan("lompat")
	await tunggu(70)
	Input.action_release("kanan")
	await tunggu(20)
	cek(besar.is_on_floor() and besar.global_position.y < -240 and besar.global_position.x > 4320,
		"karakter besar bisa naik ke blok 3 tile setelah gerbang")

	print("Jalur ke tombol biasa2 lalu gerbang2 (karakter besar)")
	var g2 = lv.get_node("gerbangg/gerbang2")
	besar.global_position = Vector2(4330, -240 - 77)   # ujung kiri blok
	besar.velocity = Vector2.ZERO
	await tunggu(10)
	await lari(besar, -1, 3700)                 # blok -> tangga menggantung
	cek(kaki(besar) <= -555, "naik tangga menggantung (atas y = -560)")
	await lari(besar, 1, 4100)                  # -> platform y = -720
	await lari(besar, -1, 3600)                 # -> platform y = -880
	cek(kaki(besar) <= -875, "naik ke platform paling atas (y = -880)")
	cek(not g2.terbuka, "gerbang2 masih tertutup")
	await lari(besar, -1, 2601, false)          # turun ke atas atap, injak tombol biasa2
	cek(g2.terbuka, "tombol biasa2 di atas atap membuka gerbang2")
	taruh(besar, 5500)                          # checkpoint setelah gerbang2
	await tunggu(15)

	print("Lubang tombol biasa3 lalu gerbang3")
	const DASAR := 400.0               # lantai lubang
	var g3 = lv.get_node("gerbangg/gerbang3")
	taruh(besar, 6440, DASAR)
	await tunggu(20)
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var c: Array = ukuran(2)
	var b_sisa = ukuran(1)[0]
	cek(c.size() == 2 and not g3.terbuka, "gerbang3 masih tertutup")
	taruh(c[0], 5878, DASAR)
	await tunggu(30)
	cek(g3.terbuka, "klon kecil di tombol biasa3: gerbang3 (di depan) terbuka")
	taruh(c[0], 6425, DASAR)
	taruh(c[1], 6435, DASAR)
	load("res://Scenes/karakter.gd").aktif = c[0]
	await tunggu(20)
	cek(not g3.terbuka, "tombol dilepas: gerbang3 tertutup lagi")
	await tekan("menyatu")
	await tunggu(90)
	var b_baru = aktif()
	taruh(b_baru, 6430, DASAR)
	taruh(b_sisa, 6440, DASAR)
	await tunggu(20)
	await tekan("menyatu")
	await tunggu(90)
	var a3 = aktif()
	cek(pemain().size() == 1 and a3.tingkat == 0 and not nyangkut(a3), "semua klon bersatu di dasar lubang")
	await lari(a3, 1, 6520)            # naik anak tangga kanan
	await lompat_ke(a3, 6360)          # ke pijakan kiri
	cek(kaki(a3) <= 165, "naik ke pijakan tengah lubang")
	await lari(a3, 1, 6600)            # keluar lubang
	cek(kaki(a3) <= 5, "keluar dari lubang")

	print("Checkpoint sebelum api")
	var P = root.get_node("Permainan")
	cek(lv.get_node("checkpoint_api").global_position.x < 5650, "checkpoint ada sebelum api pertama")
	cek(P.titik_checkpoint.x > 6000 or P.checkpoint_aktif != null, "checkpoint sudah pernah aktif saat dilewati")

	print("Ruang api: pintu tiga tombol (gerbang4)")
	var g4 = lv.get_node("gerbangg/gerbang4")
	cek(g4._sumber.size() == 3, "ketiga tombol tersambung ke gerbang4")
	a3.global_position = Vector2(8900, -880 - 77)
	a3.velocity = Vector2.ZERO
	await tunggu(15)
	await process_frame
	var hint: String = g4._balon._label.text
	cek("bersamaan" in hint and "Tombol terdekat" in hint, "dekat pintu: muncul petunjuk (%s)" % hint.replace("\n", " / "))
	taruh(a3, 7150)
	await tunggu(15)
	await lompat_ke(a3, 7430)          # pijakan y -160
	await lari(a3, 1, 7735, false)
	await lompat_ke(a3, 7900)          # pijakan y -320
	await lari(a3, 1, 8215, false)
	await lompat_ke(a3, 8400)          # pijakan y -480
	cek(kaki(a3) <= -475, "naik ke pijakan y -480")
	await lari(a3, -1, 8335, false)
	await lompat_ke(a3, 8180)          # pijakan y -720
	cek(kaki(a3) <= -715 and not g4.terbuka, "sampai di pijakan tombol, pintu masih tertutup")
	await lari(a3, -1, 8039, false)    # injak satu tombol
	cek(lv.get_node("tombol_biasa/tombol biasa5").ditekan and not g4.terbuka, "satu tombol saja: pintu belum terbuka")
	var KR = load("res://Scenes/karakter.gd")
	taruh(a3, 7340, -1360.0)
	await tunggu(15)
	await lompat_ke(a3, 7240)
	cek(kaki(a3) <= -1590, "naik ke atas ruang tombol paling tinggi")
	await tekan("membelah")
	await tunggu(120)
	await tekan("membelah")
	await tunggu(120)
	var kcl: Array = ukuran(2)
	var sdg = ukuran(1)[0]
	cek(kcl.size() == 2, "membelah jadi 3 klon")
	sdg.global_position = Vector2(7265, -1680)
	kcl[1].global_position = Vector2(7245, -1650)
	kcl[0].global_position = Vector2(7215, -1650)
	KR.aktif = kcl[0]
	await tunggu(15)
	await lari(kcl[0], -1, 6996, false)
	cek(lv.get_node("tombol_biasa/tombol biasa6").ditekan and not g4.terbuka, "klon kecil di celah atas: 1 tombol")
	KR.aktif = sdg
	for i in 3:
		if is_instance_valid(sdg) and not sdg.mati:
			await lari(sdg, 1, 9080, false)
	cek(is_instance_valid(sdg) and not sdg.mati and lv.get_node("tombol_biasa/tombol biasa4").ditekan and not g4.terbuka, "klon sedang turun ke sumur: 2 tombol [%s]" % (sdg.global_position if is_instance_valid(sdg) else "mati"))
	KR.aktif = kcl[1]
	for i in 2:
		await lari(kcl[1], 1, 8039, false)
	cek(g4.terbuka, "tiga tombol bersamaan: pintu terbuka")
	P.respawn()
	await tunggu(5)
	a3 = aktif()
	await tunggu(5)
	cek(g4.terbuka and a3.tingkat == 0, "R: kembali jadi karakter besar, pintu tetap terbuka")
	taruh(a3, 8700, -880.0)
	await tunggu(15)
	await lompat_ke(a3, 8960)          # pijakan depan pintu
	cek(kaki(a3) <= -875, "sampai di depan pintu")
	await lari(a3, 1, 9300, false)
	cek(not a3.mati and a3.global_position.x > 9250 and g4.terbuka, "pintu tetap terbuka: bisa lewat")
	await process_frame
	cek(not g4._balon.visible, "pintu terbuka: balon hilang")

	print("Jebakan api")
	var api =lv.get_node("Jebakan api/jebakan api")
	var x_api: float = api.get_node("AnimatedSprite2D").global_position.x
	for i in 300:
		if api.menyala:
			break
		await physics_frame
	cek(api.menyala and api.sprite.frame != 0, "api menyala dan gambarnya berubah")
	for i in 300:
		if not api.menyala:
			break
		await physics_frame
	cek(not api.menyala, "api padam lagi")
	taruh(a3, x_api)
	await tunggu(20)
	cek(not a3.mati, "api padam: aman diinjak")
	for i in 200:
		if not is_instance_valid(a3) or a3.mati:
			break
		a3.global_position.x = x_api
		await physics_frame
	cek(not is_instance_valid(a3) or a3.mati, "api menyala: karakter terbakar")
	await tunggu(120)
	cek(aktif() != null and absf(aktif().global_position.x - 5500) < 40,
		"terbakar: muncul lagi di checkpoint sebelum api")

	print("\nSELESAI: %s" % ("SEMUA LULUS" if gagal == 0 else "%d GAGAL" % gagal))
	quit(gagal)
