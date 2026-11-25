extends Node
## Autoload "Permainan": darah, checkpoint, ujung zona, dan HUD.
##  - Klon mati saat masih ada klon lain: darah -1.
##  - Darah habis, atau karakter terakhir mati: muncul lagi di checkpoint.
##  - Lewat ujung zona: semua klon bersatu jadi satu karakter utuh, darah penuh.

## Jumlah darah (3 sampai 5).
@export_range(3, 5) var maks_darah := 3
## Jeda sebelum muncul lagi di checkpoint (detik).
@export var jeda_respawn := 0.8

var darah := 3
var titik_checkpoint := Vector2.ZERO
var checkpoint_aktif = null

var _scene_pemain := ""
var _induk: Node = null
var _skala := Vector2.ONE
var _respawn_tertunda := false

const SCENE_GAME := "res://Scenes/game.tscn"
const SCENE_MENU := "res://Scenes/menu_utama.tscn"
## Urutan dari yang paling mudah.
const LEVEL := [
	{"nama": "Tutorial", "scene": "res://Scenes/tutorial.tscn"},
	{"nama": "Level 1: Lab Bawah", "scene": "res://Scenes/level_lab_bawah.tscn"},
	{"nama": "Level 2: Jalur Lift", "scene": "res://Scenes/level_jalur_lift.tscn"},
	{"nama": "Level 3: Laboratorium Utama", "scene": SCENE_GAME},
]

## -1 = scene dibuka langsung, bukan dari menu.
var level_aktif := -1
var zona_tujuan = null
var _panel_berhasil: Control
var _judul_berhasil: Label
var _tombol_lanjut: Button

const TEKS_KONTROL := "A / D atau panah kiri-kanan: jalan\nSpasi, W, atau panah atas: lompat\nS atau panah bawah: turun dari platform tipis\nQ: membelah\nTab: ganti klon\nE: bergabung dan interaksi\nR: kembali ke checkpoint"

var _label_level: Label
var _tombol_menu: Button
var _panel_jeda: Control
var _teks_kontrol: Control

const HATI_PENUH := preload("res://Assests/hati_penuh.png")
const HATI_KOSONG := preload("res://Assests/hati_kosong.png")

var _hati: HBoxContainer
var _label_pesan: Label
var _sisa_pesan := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	darah = maks_darah
	_buat_hud()


## Dipanggil oleh setiap karakter di _ready(). Karakter pertama di sebuah level
## menentukan posisi awal (checkpoint pertama).
func daftar_pemain(p: Node) -> void:
	if _induk != null and is_instance_valid(_induk) and _induk == p.get_parent():
		return
	_induk = p.get_parent()
	_scene_pemain = p.scene_file_path
	_skala = p.scale
	titik_checkpoint = p.global_position
	checkpoint_aktif = null
	darah = maks_darah
	_respawn_tertunda = false


func set_checkpoint(cp, masuk = null) -> void:
	if cp == checkpoint_aktif:
		return
	if checkpoint_aktif != null and is_instance_valid(checkpoint_aktif):
		checkpoint_aktif.set_aktif(false)
	checkpoint_aktif = cp
	cp.set_aktif(true)
	Suara.main("checkpoint")
	titik_checkpoint = cp.titik_muncul()
	if masuk != null and get_tree().get_nodes_in_group("pemain").size() > 1:
		_satukan(masuk)
		pesan("Checkpoint! Semua klon bersatu kembali")
	else:
		pesan("Checkpoint!")


## Dipanggil saat sebuah klon mati.
## `sisa` = jumlah klon yang masih hidup setelah klon ini mati.
## Hasil true = permainan akan kembali ke checkpoint.
func klon_mati(sisa: int) -> bool:
	if _respawn_tertunda:
		return true
	if sisa <= 0:
		pesan("Jatuh! Kembali ke checkpoint")
		_minta_respawn()
		return true
	darah -= 1
	if darah <= 0:
		darah = 0
		pesan("Darah habis! Kembali ke checkpoint")
		_minta_respawn()
		return true
	pesan("Klon mati! Darah -1")
	return false


func _minta_respawn() -> void:
	_respawn_tertunda = true
	await get_tree().create_timer(jeda_respawn).timeout
	respawn()


func respawn() -> void:
	_respawn_tertunda = false
	if _induk == null or not is_instance_valid(_induk) or _scene_pemain.is_empty():
		get_tree().reload_current_scene()
		return
	for p in get_tree().get_nodes_in_group("pemain"):
		p.remove_from_group("pemain")
		p.queue_free()
	var baru = load(_scene_pemain).instantiate()
	baru.tingkat = 0
	baru.scale = _skala
	baru.position = _induk.to_local(titik_checkpoint) if _induk is Node2D else titik_checkpoint
	_induk.add_child(baru)
	Pemain.aktif = baru
	get_tree().call_group("box", "kembali_ke_awal")
	darah = maks_darah


func selesai_zona(zona, masuk) -> void:
	if zona.selesai or not is_instance_valid(masuk) or masuk.mati:
		return
	zona.selesai = true
	_satukan(masuk)
	if checkpoint_aktif != null and is_instance_valid(checkpoint_aktif):
		checkpoint_aktif.set_aktif(false)
	checkpoint_aktif = zona
	titik_checkpoint = zona.titik_muncul()
	zona.set_aktif(true)
	pesan("Zona selesai! Semua klon bersatu kembali")
	if zona == zona_tujuan:
		_tampilkan_berhasil()


## Semua klon hilang, tersisa satu karakter utuh di tempat `masuk`.
func _satukan(masuk) -> void:
	if not is_instance_valid(masuk) or masuk.mati:
		return
	for p in get_tree().get_nodes_in_group("pemain"):
		if p != masuk:
			p.remove_from_group("pemain")
			p.queue_free()
	var utuh = masuk
	if masuk.tingkat > 0:
		utuh = _jadikan_utuh(masuk)
	Pemain.aktif = utuh
	darah = maks_darah


## Ganti klon kecil dengan karakter ukuran penuh di tempat yang sama.
func _jadikan_utuh(p) -> Node:
	var baru = load(p.scene_file_path).instantiate()
	baru.tingkat = 0
	baru.hasil_gabungan = true   # mainkan animasi clone terbalik
	baru.scale = p.scale
	baru.skala_sprite_utuh = p.skala_sprite_utuh
	baru.skala_collision_utuh = p.skala_collision_utuh
	var tinggi_sekarang: float = p.collision.shape.get_rect().size.y * p.collision.scale.y * p.scale.y
	var tinggi_baru: float = tinggi_sekarang / pow(Pemain.SKALA_PER_BELAH, p.tingkat)
	var tujuan: Vector2 = p.global_position - Vector2(0, (tinggi_baru - tinggi_sekarang) / 2.0)
	var lega: Vector2 = p.cari_ruang(0, tujuan)   # hindari muncul di dalam atap
	if lega != Pemain.TIDAK_ADA_RUANG:
		tujuan = lega
	baru.position = p.get_parent().to_local(tujuan)
	baru.get_node("AnimatedSprite2D").flip_h = p.sprite.flip_h
	p.remove_from_group("pemain")
	p.get_parent().add_child(baru)
	p.queue_free()
	return baru


# ---------------------------------------------------------------- HUD

func pesan(teks: String) -> void:
	_label_pesan.text = teks
	_sisa_pesan = 2.5


func buat_teks(isi: String) -> PanelContainer:
	var p := PanelContainer.new()
	var g := StyleBoxFlat.new()
	g.bg_color = Color.WHITE
	g.border_color = Color.BLACK
	g.set_border_width_all(3)
	g.set_corner_radius_all(6)
	g.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", g)
	var l := Label.new()
	l.text = isi
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color.BLACK)
	p.add_child(l)
	return p


func buat_penggeser(judul: String, nilai: float, saat_ubah: Callable) -> PanelContainer:
	var p := buat_teks(judul)
	var l: Label = p.get_child(0)
	p.remove_child(l)
	l.custom_minimum_size.x = 110
	var b := HBoxContainer.new()
	b.add_child(l)
	p.add_child(b)
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(190, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.max_value = 1.0
	s.step = 0.05
	s.value = nilai
	s.value_changed.connect(saat_ubah)
	b.add_child(s)
	return p


func _buat_panel_jeda(layer: CanvasLayer) -> void:
	_tombol_menu = buat_tombol("Menu", buka_jeda)
	_tombol_menu.custom_minimum_size = Vector2(90, 34)
	_tombol_menu.focus_mode = Control.FOCUS_NONE
	_tombol_menu.add_theme_font_size_override("font_size", 18)
	_tombol_menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_tombol_menu.position += Vector2(-104, 10)
	_tombol_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_tombol_menu)
	_panel_jeda = ColorRect.new()
	_panel_jeda.color = Color(0, 0, 0, 0.65)
	_panel_jeda.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_jeda.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel_jeda.visible = false
	layer.add_child(_panel_jeda)
	var tengah := CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_jeda.add_child(tengah)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	tengah.add_child(v)
	v.add_child(buat_tombol("Lanjutkan", tutup_jeda))
	v.add_child(buat_penggeser("Musik", Suara.volume_musik, func(x): Suara.atur_volume(Suara.volume_efek, x)))
	v.add_child(buat_penggeser("Efek suara", Suara.volume_efek, func(x): Suara.atur_volume(x, Suara.volume_musik)))
	v.add_child(buat_tombol("Kontrol", func(): _teks_kontrol.visible = not _teks_kontrol.visible))
	_teks_kontrol = buat_teks(TEKS_KONTROL)
	_teks_kontrol.visible = false
	v.add_child(_teks_kontrol)
	v.add_child(buat_tombol("Kembali ke menu", ke_menu))
	v.add_child(buat_tombol("Keluar dari game", func(): get_tree().quit()))


func buka_jeda() -> void:
	_teks_kontrol.visible = false
	_panel_jeda.visible = true
	get_tree().paused = true
	_panel_jeda.find_children("*", "Button", true, false)[0].grab_focus()


func tutup_jeda() -> void:
	_panel_jeda.visible = false
	get_tree().paused = false


# Nama level dan nomor area: area naik setiap melewati checkpoint baru.
func _teks_level() -> String:
	var nama: String = LEVEL[level_aktif].nama if level_aktif >= 0 else "Mode uji"
	var semua := get_tree().get_nodes_in_group("checkpoint")
	var area := 1
	if is_instance_valid(checkpoint_aktif):
		area += semua.filter(func(c): return c.global_position.x <= checkpoint_aktif.global_position.x).size()
	return "%s  |  Area %d/%d" % [nama, mini(area, semua.size() + 1), semua.size() + 1]


func mulai_level(i: int) -> void:
	level_aktif = i
	zona_tujuan = null
	_panel_jeda.visible = false
	_panel_berhasil.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL[i].scene)


func ke_menu() -> void:
	level_aktif = -1
	zona_tujuan = null
	_panel_jeda.visible = false
	_panel_berhasil.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MENU)


## Tombol bergaya sama untuk menu dan kotak berhasil.
func buat_tombol(teks: String, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(340, 46)
	b.add_theme_font_size_override("font_size", 22)
	for w in [["font_color", Color.BLACK], ["font_focus_color", Color.WHITE], ["font_hover_color", Color.WHITE], ["font_pressed_color", Color.WHITE]]:
		b.add_theme_color_override(w[0], w[1])
	for g in [["normal", Color.WHITE], ["hover", Color.BLACK], ["focus", Color.BLACK], ["pressed", Color(0.25, 0.25, 0.25)]]:
		var s := StyleBoxFlat.new()
		s.bg_color = g[1]
		s.border_color = Color.BLACK
		s.set_border_width_all(3)
		s.set_corner_radius_all(6)
		b.add_theme_stylebox_override(g[0], s)
	b.pressed.connect(func():
		Suara.main("klik")
		aksi.call())
	return b


func _buat_panel_berhasil(layer: CanvasLayer) -> void:
	_panel_berhasil = CenterContainer.new()
	_panel_berhasil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_berhasil.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel_berhasil.visible = false
	layer.add_child(_panel_berhasil)
	var kotak := PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color.WHITE
	gaya.border_color = Color.BLACK
	gaya.set_border_width_all(4)
	gaya.set_corner_radius_all(10)
	gaya.set_content_margin_all(24)
	kotak.add_theme_stylebox_override("panel", gaya)
	_panel_berhasil.add_child(kotak)
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	kotak.add_child(isi)
	_judul_berhasil = Label.new()
	_judul_berhasil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul_berhasil.add_theme_font_size_override("font_size", 28)
	_judul_berhasil.add_theme_color_override("font_color", Color.BLACK)
	isi.add_child(_judul_berhasil)
	_tombol_lanjut = buat_tombol("Lanjut ke level berikutnya", func(): mulai_level(level_aktif + 1))
	isi.add_child(_tombol_lanjut)
	isi.add_child(buat_tombol("Kembali ke menu", ke_menu))


func _tampilkan_berhasil() -> void:
	Suara.main("menang")
	_judul_berhasil.text = "%s selesai!" % LEVEL[level_aktif].nama
	_tombol_lanjut.visible = level_aktif + 1 < LEVEL.size()
	_panel_berhasil.visible = true
	get_tree().paused = true
	if _tombol_lanjut.visible:
		_tombol_lanjut.grab_focus()


## Arah sebuah posisi dilihat dari karakter aktif, contoh: "di kanan atas".
func arah_dari_pemain(posisi: Vector2) -> String:
	if not is_instance_valid(Pemain.aktif):
		return ""
	var d: Vector2 = posisi - Pemain.aktif.global_position
	var kata: Array[String] = []
	if absf(d.x) > 120.0:
		kata.append("kanan" if d.x > 0.0 else "kiri")
	if absf(d.y) > 120.0:
		kata.append("bawah" if d.y > 0.0 else "atas")
	return "di dekatmu" if kata.is_empty() else "di " + " ".join(kata)


func _buat_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_hati = HBoxContainer.new()
	_hati.position = Vector2(14, 10)
	layer.add_child(_hati)
	_buat_panel_berhasil(layer)
	_buat_panel_jeda(layer)
	_label_level = _buat_label(layer, 18)
	_label_level.position = Vector2(112, 12)
	for i in maks_darah:
		var t := TextureRect.new()
		t.custom_minimum_size = Vector2(26, 26)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hati.add_child(t)
	_label_pesan = _buat_label(layer, 24)
	_label_pesan.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_pesan.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_pesan.position.y = 60


func _buat_label(induk: Node, ukuran: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	induk.add_child(l)
	return l


func _process(delta: float) -> void:
	var jumlah := get_tree().get_nodes_in_group("pemain").size()
	var di_level := jumlah > 0 or _respawn_tertunda
	_hati.visible = di_level   # sembunyi di menu
	_label_level.visible = di_level
	_tombol_menu.visible = di_level
	if di_level:
		_label_level.text = _teks_level()
	if di_level and Input.is_action_just_pressed("ui_cancel") and not _panel_berhasil.visible:
		if _panel_jeda.visible:
			tutup_jeda()
		else:
			buka_jeda()
	for i in _hati.get_child_count():
		_hati.get_child(i).texture = HATI_PENUH if i < darah else HATI_KOSONG
	# R: kembali ke checkpoint kalau tersangkut.
	if jumlah > 0 and Input.is_action_just_pressed("ulang") and not _respawn_tertunda and not get_tree().paused:
		pesan("Kembali ke checkpoint")
		respawn()
	_sisa_pesan -= delta
	_label_pesan.modulate.a = clampf(_sisa_pesan, 0.0, 1.0)
