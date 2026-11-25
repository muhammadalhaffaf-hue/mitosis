extends SceneTree
## Tes otomatis semua mekanik di Scenes/contoh_mekanik.tscn.
## Jalankan dari folder project:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_mekanik.gd

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


func tahan(aksi: String, n: int) -> void:
	Input.action_press(aksi)
	await tunggu(n)
	Input.action_release(aksi)


func pemain() -> Array:
	return get_nodes_in_group("pemain")


func aktif():
	return lv.get_script().get_base_script() if false else load("res://Scenes/karakter.gd").aktif


func taruh(n: Node2D, pos: Vector2) -> void:
	n.global_position = pos
	if "velocity" in n:
		n.velocity = Vector2.ZERO


func _initialize() -> void:
	lv = load("res://Scenes/contoh_mekanik.tscn").instantiate()
	root.add_child(lv)
	var P = root.get_node("Permainan")
	await tunggu(40)

	print("Awal")
	cek(pemain().size() == 1 and P.darah == P.maks_darah, "1 karakter, darah penuh")
	var a = aktif()
	cek(a != null and a.is_on_floor(), "karakter berdiri di lantai")

	print("Checkpoint")
	taruh(a, Vector2(560, -80))
	await tunggu(5)
	cek(P.checkpoint_aktif == lv.get_node("checkpoint"), "menyentuh checkpoint mengaktifkannya")

	print("Tombol biasa + gerbang")
	var g1 = lv.get_node("gerbang_1")
	var y_tutup: float = g1.global_position.y
	taruh(a, Vector2(900, -80))
	await tunggu(40)
	cek(g1.terbuka and g1.get_node("CollisionShape2D").disabled, "diinjak: gerbang terbuka")
	taruh(a, Vector2(650, -80))
	await tunggu(40)
	cek(not g1.terbuka and is_equal_approx(g1.global_position.y, y_tutup), "dilepas: gerbang tertutup lagi")

	print("Box")
	var box = lv.get_node("box")
	cek(box.bisa_didorong_oleh(3) and box.bisa_didorong_oleh(2) and not box.bisa_didorong_oleh(1),
		"box bisa didorong klon besar/sedang, tidak oleh klon kecil")
	var x_box: float = box.global_position.x
	taruh(a, Vector2(1600, -80))
	await tunggu(5)
	await tahan("kanan", 60)
	cek(box.global_position.x > x_box + 40, "karakter besar mendorong box")
	var g2 = lv.get_node("gerbang_2")
	taruh(box, Vector2(2250, -90))
	await tunggu(30)
	cek(g2.terbuka, "box di tombol box: gerbang 2 terbuka")
	taruh(a, Vector2(2150, -80))
	await tunggu(5)
	taruh(box, Vector2(2000, -90))
	await tunggu(30)
	cek(not g2.terbuka, "tombol box tidak tertekan oleh karakter")

	print("Platform tembus")
	taruh(a, Vector2(3050, -300))
	await tunggu(40)
	cek(a.is_on_floor() and a.global_position.y < -250, "bisa berdiri di atas platform tembus")
	await tekan("turun")
	await tunggu(40)
	cek(a.global_position.y > -120, "tekan S: turun menembus platform")
	taruh(a, Vector2(3050, -80))
	await tunggu(10)
	await tekan("lompat")
	await tunggu(80)
	cek(a.global_position.y < -250, "lompat dari bawah: tembus lalu mendarat di atas platform")

	print("Lift")
	var lift = lv.get_node("lift")
	taruh(box, Vector2(3600, -90))     # box menindih tombol lift
	taruh(a, Vector2(3920, -110))
	await tunggu(220)
	cek(lift.global_position.y < -380 and a.global_position.y < -420, "tombol lift ditekan: lift naik membawa karakter")
	taruh(a, Vector2(4280, -480))      # turun di tebing
	taruh(box, Vector2(3300, -90))
	await tunggu(220)
	cek(lift.global_position.y > -30, "tombol lift dilepas: lift turun lagi")

	print("Platform bergerak otomatis")
	var mp = lv.get_node("platform_bergerak")
	var x_mp: float = mp.global_position.x
	await tunggu(60)
	cek(absf(mp.global_position.x - x_mp) > 50, "platform bergerak sendiri")

	print("Tanah miring")
	taruh(a, Vector2(5200, -80))
	await tunggu(10)
	var y_min := 0.0
	Input.action_press("kanan")
	for i in 150:
		await physics_frame
		y_min = minf(y_min, a.global_position.y)
	Input.action_release("kanan")
	cek(a.global_position.x > 5850 and y_min < -220, "bisa jalan naik-turun bukit miring tanpa lompat")

	print("Robot")
	var robot = lv.get_node("robot")
	var x_r: float = robot.global_position.x
	await tunggu(30)
	cek(absf(robot.global_position.x - x_r) > 20, "robot berpatroli")
	taruh(a, robot.global_position + Vector2(-110, -20))
	await tekan("menyatu")
	cek(robot.sisa_tahan > 0.0, "tombol E di dekat robot: robot ditahan (karakter besar)")
	var x_tahan: float = robot.global_position.x
	taruh(a, robot.global_position + Vector2(0, -20))
	await tunggu(20)
	cek(not a.mati and absf(robot.global_position.x - x_tahan) < 2, "robot yang ditahan diam dan tidak membunuh")
	await tunggu(200)
	cek(not is_instance_valid(a) or a.mati, "setelah tahanan habis, robot membunuh karakter")
	await tunggu(90)
	a = aktif()
	cek(pemain().size() == 1 and a.global_position.distance_to(Vector2(560, -90)) < 120 and P.darah == P.maks_darah,
		"karakter terakhir mati: muncul lagi di checkpoint, darah tidak berkurang")

	print("Darah & membelah")
	await tunggu(20)
	await tekan("membelah")
	await tunggu(120)
	cek(pemain().size() == 2, "membelah jadi 2")
	await tekan("membelah")
	await tunggu(120)
	cek(pemain().size() == 3, "membelah lagi jadi 3 (B, C, C)")
	var kecil = pemain().filter(func(p): return p.tingkat == 2)[0]
	kecil.mati_sekarang()
	await tunggu(60)
	cek(P.darah == P.maks_darah - 1, "klon kecil mati: darah -1")
	cek(pemain().size() == 2 and pemain().all(func(p): return p.tingkat == 1), "kembarannya membesar lagi (jadi 2 klon sedang)")

	print("Ujung zona")
	await tunggu(30)
	var sedang = pemain()[0]
	taruh(sedang, Vector2(6960, -80))
	await tunggu(30)
	a = aktif()
	cek(pemain().size() == 1 and a.tingkat == 0 and P.darah == P.maks_darah, "masuk ujung zona: bersatu jadi 1 karakter utuh, darah penuh")
	cek(P.checkpoint_aktif == lv.get_node("ujung_zona"), "ujung zona jadi checkpoint")

	print("Darah habis")
	await tunggu(90)   # tunggu animasi menyatu selesai
	for i in P.maks_darah:
		await tunggu(30)
		await tekan("membelah")
		await tunggu(120)
		if pemain().size() < 2:
			cek(false, "membelah (putaran %d)" % i)
			break
		pemain()[0].mati_sekarang()
		await tunggu(60)
	await tunggu(60)
	a = aktif()
	cek(pemain().size() == 1 and P.darah == P.maks_darah and a.global_position.distance_to(Vector2(6960, -90)) < 150,
		"darah habis: kembali ke checkpoint terakhir dengan darah penuh")

	print("\nSELESAI: %s" % ("SEMUA LULUS" if gagal == 0 else "%d GAGAL" % gagal))
	quit(gagal)
