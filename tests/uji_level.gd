extends SceneTree
## Tes tutorial, perpindahan level, dan kotak berhasil.
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_level.gd

var gagal := 0
var P: Node
var a


func cek(kondisi: bool, teks: String) -> void:
	print(("  OK    " if kondisi else "  GAGAL ") + teks + ("" if kondisi or not is_instance_valid(a) else "  [x=%d y=%d]" % [a.global_position.x, a.global_position.y]))
	if not kondisi:
		gagal += 1


func tunggu(n: int) -> void:
	for i in n:
		await physics_frame


func aktif():
	return load("res://Scenes/karakter.gd").aktif


func hidup() -> bool:
	return is_instance_valid(a) and not a.mati


func lepas() -> void:
	for n in ["kanan", "kiri", "lompat"]:
		Input.action_release(n)


func tekan(n: String) -> void:
	Input.action_press(n)
	await physics_frame
	await physics_frame
	Input.action_release(n)


func jalan(x_tujuan: float) -> void:
	var arah := 1.0 if x_tujuan > a.global_position.x else -1.0
	Input.action_press("kanan" if arah > 0 else "kiri")
	for i in 900:
		await physics_frame
		if not hidup() or paused or (a.global_position.x - x_tujuan) * arah >= 0:
			break
	lepas()
	await tunggu(20)


func lompat_ke(x_tujuan: float) -> void:
	var aksi := "kanan" if x_tujuan > a.global_position.x else "kiri"
	Input.action_press(aksi)
	await tekan("lompat")
	for i in 150:
		await physics_frame
		if not hidup():
			break
		if absf(a.global_position.x - x_tujuan) < 8.0:
			Input.action_release(aksi)
		if i > 5 and a.is_on_floor():
			break
	lepas()
	await tunggu(12)


func masuk_level(i: int) -> void:
	P.mulai_level(i)
	await process_frame
	await tunggu(12)
	a = aktif()


func siap(i: int) -> void:
	await process_frame
	await tunggu(12)
	a = aktif()
	cek(not paused and P.level_aktif == i and is_instance_valid(P.zona_tujuan), "%s: terbuka" % P.LEVEL[i].nama)


func pegang(k) -> void:
	a = k
	load("res://Scenes/karakter.gd").aktif = k
	await tunggu(15)


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


func lari_lompat(x_tolak: float) -> void:
	Input.action_press("kanan")
	for i in 300:
		await physics_frame
		if not hidup() or a.global_position.x >= x_tolak:
			break
	await tekan("lompat")
	for i in 90:
		await physics_frame
		if not hidup() or (i > 4 and a.is_on_floor()):
			break
	lepas()
	await tunggu(6)


func ke_ruang(k: float) -> void:
	if P._respawn_tertunda:
		for i in 120:
			await physics_frame
			if not P._respawn_tertunda:
				break
	P.respawn()
	await physics_frame
	a = aktif()
	await tunggu(2)
	a.global_position = Vector2(k * 80.0, -90.0)
	a.velocity = Vector2.ZERO
	await tunggu(14)


func belah(n: int) -> void:
	for i in n:
		await tekan("membelah")
		await tunggu(120)


func klon(t: int) -> Array:
	return get_nodes_in_group("pemain").filter(func(p): return p.tingkat == t)


func taruh(k, x_kolom: float, y := -70.0) -> void:
	k.global_position = Vector2(x_kolom * 80.0, y)
	k.velocity = Vector2.ZERO


func satu(c: float, jenis: String, teks: String) -> void:
	await tunggu(6)
	a = aktif()
	cek(hidup() and a.tingkat == 0 and get_nodes_in_group("pemain").size() == 1 and a.global_position.x > c * 80.0, "%s: %s" % [jenis, teks])


func ikut_api(x_akhir: float) -> void:
	for i in 1500:
		var waktu := Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)
		var sasaran := 160.0 * (waktu - 0.3) + 91.0
		sasaran += ceilf((a.global_position.x - sasaran - 40.0) / 384.0) * 384.0
		if i == 0:
			a.global_position.x = sasaran
		if a.global_position.x < sasaran - 4.0:
			Input.action_press("kanan")
		else:
			Input.action_release("kanan")
		await physics_frame
		if not hidup() or a.global_position.x >= x_akhir:
			break
	lepas()
	await tunggu(5)


func lewati_robot(x_akhir: float) -> void:
	Input.action_press("kanan")
	for i in 900:
		await physics_frame
		if not hidup() or a.global_position.x >= x_akhir:
			break
		for r in get_nodes_in_group("robot"):
			if r.sisa_tahan < 0.5 and absf(r.global_position.x - a.global_position.x) < 130.0 and absf(r.global_position.y - a.global_position.y) < 90.0:
				await tekan("menyatu")
	lepas()
	await tunggu(5)


func uji_ruang(jenis: String, c: float, n: int) -> void:
	var X := func(k: float): return (c + k) * 80.0
	var g = null
	for m in current_scene.get_children():
		if m.name.begins_with("gerbang") and m.global_position.x > c * 80.0 and (g == null or m.global_position.x < g.global_position.x):
			g = m
	await ke_ruang(c + 1.0)
	match jenis:
		"lompat":
			await jalan(X.call(3.8)); await lompat_ke(X.call(6.6)); await jalan(X.call(7.4)); await lompat_ke(X.call(8.6))
			await jalan(X.call(11.0)); await jalan(X.call(12.7)); await lompat_ke(X.call(16.6)); await jalan(X.call(17.5))
			await lompat_ke(X.call(18.5)); await lompat_ke(X.call(19.5)); await lompat_ke(X.call(20.5)); await jalan(X.call(22.5))
			cek(hidup() and a.global_position.x > X.call(22.0), "lompat: jurang dan tangga terlewati")
		"tahan":
			await jalan(X.call(2.5)); await belah(1)
			var d: Array = klon(1); taruh(d[0], c + 4.5); taruh(d[1], c + 7.0); await pegang(d[1])
			cek(g.terbuka, "tahan: klon menahan tombol"); await jalan(X.call(13.9)); await satu(c + 13.0, "tahan", "lewat pintu, klon bersatu")
		"api":
			a.global_position.x = X.call(1.5); await tunggu(5); await ikut_api(X.call(3.0 + n + 1.2))
			cek(hidup() and a.global_position.x > X.call(3.0 + n), "api: %d api terlewati" % n)
		"box":
			await jalan(X.call(11.5) - 92.0); await tunggu(20); cek(g.terbuka, "box: box membuka pintu")
			await lompat_ke(X.call(13.5)); await jalan(X.call(19.0)); cek(hidup() and a.global_position.x > X.call(18.0), "box: lewat pintu")
		"lift":
			await jalan(X.call(2.5))
			var l = null
			for m in current_scene.get_children():
				if m.name.begins_with("lift") and absf(m.global_position.x - X.call(6.0)) < 2.0:
					l = m
			cek(l._sudah_aktif, "lift: tombol menyalakan lift"); await naik(l, 1.0); await jalan(X.call(21.0))
			cek(hidup() and a.global_position.x > X.call(20.0), "lift: lewat jalur atas")
		"jurang":
			var pf = null
			for m in current_scene.get_children():
				if m.name.begins_with("platform") and absf(m._awal.x - X.call(4.0)) < 2.0:
					pf = m
			await naik(pf, 1.0); await jalan(X.call(18.5)); cek(hidup() and absf(a.global_position.y + 73.0) < 14, "jurang: platform menyeberang")
		"robot":
			await lewati_robot(X.call(15.0)); cek(hidup() and a.global_position.x >= X.call(15.0), "robot: dilewati dengan E")
		"tiga":
			await jalan(X.call(6.0)); await belah(2)
			var b1 = klon(1)[0]; var kc: Array = klon(2)
			taruh(b1, c + 9.5, -60.0); taruh(kc[0], c + 6.5, -40.0); taruh(kc[1], c + 3.5, -40.0); await tunggu(30)
			cek(g.terbuka, "tiga: tiga tombol bersamaan"); await pegang(b1); await jalan(X.call(16.9)); await satu(c + 16.0, "tiga", "lewat, klon bersatu")
		"tumpuk":
			await jalan(X.call(3.0)); await belah(1)
			var d: Array = klon(1); taruh(d[0], c + 5.75, -60.0); taruh(d[1], c + 5.75, -175.0); await pegang(d[1]); await tunggu(15)
			await lompat_ke(X.call(7.0)); cek(hidup() and a.global_position.y < -340.0, "tumpuk: klon sampai atas tembok")
			await jalan(X.call(13.9)); await satu(c + 13.0, "tumpuk", "checkpoint menyatukan klon")
		"panah":
			for t in current_scene.get_children():
				if t.has_method("tembak"):
					t.sprite.stop()
			for p in get_nodes_in_group("panah"):
				p.queue_free()
			await jalan(X.call(5.0))
			for k in [7.0, 11.0, 15.0]:
				await lari_lompat(X.call(k) - 55.0); cek(hidup(), "panah: lompati duri")
			await jalan(X.call(22.0)); cek(hidup() and a.global_position.x > X.call(21.0), "panah: lorong terlewati")
		"terowongan":
			await jalan(X.call(1.5)); await belah(2)
			var b1 = klon(1)[0]; var kc: Array = klon(2)
			taruh(kc[0], c + 6.5, -40.0); taruh(kc[1], c + 1.0, -40.0); taruh(b1, c + 11.0, -60.0); await tunggu(20)
			cek(g.terbuka, "terowongan: klon kecil menahan tombol"); await pegang(b1); await jalan(X.call(16.9)); await satu(c + 16.0, "terowongan", "lewat, klon bersatu")


func uji_level_baru(i: int) -> void:
	P.mulai_level(i)
	await siap(i)
	await tunggu(20)
	var r: Array = current_scene.get_children().filter(func(m): return m.name.begins_with("r_"))
	r.sort_custom(func(p, q): return p.global_position.x < q.global_position.x)
	cek(current_scene.get_node("ujung_akhir").global_position.x > 7000.0, "%s: cukup panjang" % P.LEVEL[i].nama)
	for m in r:
		var b: PackedStringArray = String(m.name).split("_")
		await uji_ruang(b[2], m.global_position.x / 80.0, int(b[3]))
	await ke_ruang(current_scene.get_node("ujung_akhir").global_position.x / 80.0 - 3.0)
	await jalan(current_scene.get_node("ujung_akhir").global_position.x + 10.0)
	cek(paused and P._panel_berhasil.visible, "%s: selesai" % P.LEVEL[i].nama)


func _initialize() -> void:
	P = root.get_node("Permainan")
	await tunggu(5)
	print("Tutorial")
	await masuk_level(0)
	cek(current_scene.scene_file_path == "res://Scenes/tutorial.tscn" and P.zona_tujuan != null, "tutorial terbuka")
	await tunggu(40)
	await jalan(860)
	await lompat_ke(1180)
	cek(hidup() and a.global_position.x > 1120, "melompati balok")
	await jalan(1500)
	await tekan("membelah")
	await tunggu(120)
	var dua: Array = get_nodes_in_group("pemain")
	cek(dua.size() == 2, "membelah jadi dua")
	dua[0].global_position = Vector2(1720, -70)
	dua[1].global_position = Vector2(1900, -70)
	a = dua[1]
	load("res://Scenes/karakter.gd").aktif = a
	await tunggu(20)
	cek(current_scene.get_node("gerbang_1").terbuka, "klon di tombol: pintu terbuka")
	await jalan(2560)
	await tunggu(5)
	a = aktif()
	cek(get_nodes_in_group("pemain").size() == 1 and a.tingkat == 0, "checkpoint menyatukan klon")
	await jalan(3100)
	await lompat_ke(3280)
	cek(a.global_position.y < -280, "karakter besar naik ke balok tinggi")
	await jalan(3500)
	await jalan(4112)
	await tunggu(20)
	cek(current_scene.get_node("gerbang_2").terbuka, "box di tombol: pintu kedua terbuka")
	await lompat_ke(4360)
	await jalan(4800)
	cek(hidup() and a.global_position.x > 4700, "lewat pintu kedua")
	var r = current_scene.get_node("robot")
	Input.action_press("kanan")
	for i in 900:
		await physics_frame
		if not hidup() or paused:
			break
		var d: Vector2 = r.global_position - a.global_position
		if r.sisa_tahan < 0.5 and absf(d.x) < 140.0:
			await tekan("menyatu")
	lepas()
	await tunggu(5)
	cek(paused and P._panel_berhasil.visible and P._tombol_lanjut.visible, "sampai ujung: kotak berhasil muncul")
	cek("Tutorial" in P._label_level.text and "Area" in P._label_level.text, "HUD menampilkan level dan area")

	print("Level baru, ruang demi ruang")
	for i in [1, 2]:
		await uji_level_baru(i)
	P.ke_menu()
	await process_frame
	await tunggu(5)
	cek(not paused and current_scene.scene_file_path == P.SCENE_MENU, "kembali ke menu")
	print("\nSELESAI: %s" % ("SEMUA LULUS" if gagal == 0 else "%d GAGAL" % gagal))
	quit(gagal)
