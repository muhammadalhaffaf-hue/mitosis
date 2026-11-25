extends SceneTree
## Tes menu utama.
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/uji_menu.gd

var gagal := 0


func cek(kondisi: bool, teks: String) -> void:
	print(("  OK    " if kondisi else "  GAGAL ") + teks)
	if not kondisi:
		gagal += 1


func tunggu(n: int) -> void:
	for i in n:
		await process_frame


func _initialize() -> void:
	cek(ProjectSettings.get_setting("application/run/main_scene") == "res://Scenes/menu_utama.tscn",
		"game dimulai dari menu utama")
	var menu = load("res://Scenes/menu_utama.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await tunggu(5)
	var hud = root.get_node("Permainan")
	cek(not hud._hati.visible, "HUD darah tersembunyi di menu")
	cek(menu._panel_utama.visible and not menu._panel_level.visible, "menu utama tampil lebih dulu")
	cek(menu._tombol.has_focus(), "tombol Mulai langsung terpilih")

	var x0: float = menu._latar.region.position.x
	var berubah := false
	for i in 40:
		await process_frame
		if menu._latar.region.position.x != x0:
			berubah = true
	# Tanpa jendela, waktu antar frame bisa sangat kecil: paksa maju kalau perlu.
	if not berubah:
		menu._process(0.2)
		berubah = menu._latar.region.position.x != x0
	cek(berubah, "latar beranimasi")
	cek(menu._latar.region.end.x <= 11520.0, "frame latar tidak keluar dari gambar")

	menu._tombol.pressed.emit()
	cek(menu._panel_level.visible and menu._tombol_level.size() == hud.LEVEL.size(), "Mulai: muncul pilihan level")
	menu._tombol_level[1].pressed.emit()
	await create_timer(0.8).timeout
	await tunggu(5)
	cek(current_scene != null and current_scene.scene_file_path == hud.LEVEL[1].scene,
		"pilih level: masuk ke level")
	await tunggu(5)
	cek(get_nodes_in_group("pemain").size() == 1, "karakter muncul di level")
	cek(hud._hati.visible, "HUD darah muncul di level")

	print("\nSELESAI: %s" % ("SEMUA LULUS" if gagal == 0 else "%d GAGAL" % gagal))
	quit(gagal)
