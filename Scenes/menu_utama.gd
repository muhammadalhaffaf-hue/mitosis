extends Control
## Menu utama MITOSIS: judul, pilihan menu, pilih level, kontrol, dan pengaturan.

const LATAR := preload("res://Assests/homescreen_tanpa_latar.png")
const LATAR_FRAME := Vector2(640, 360)      # 18 frame berjajar
const LATAR_FPS := 8.0
const FONT_JUDUL := preload("res://Assests/font/Kenney Future.ttf")

var _panggung: Control
var _latar: AtlasTexture
var _waktu_latar := 0.0
var _hitam: ColorRect
var _mulai := false
var _tombol: Button            # tombol pertama menu utama
var _panel_utama: Control
var _panel_level: Control
var _panel_kontrol: Control
var _panel_atur: Control
var _tombol_level: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dasar := ColorRect.new()
	dasar.color = Color.BLACK
	dasar.z_index = -2
	dasar.set_anchors_preset(Control.PRESET_FULL_RECT)
	dasar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dasar)
	add_child(load("res://Scenes/latar_lab.tscn").instantiate())

	# Gambar 640x360 diperbesar menutupi layar.
	_panggung = Control.new()
	_panggung.size = LATAR_FRAME
	_panggung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panggung)
	_latar = AtlasTexture.new()
	_latar.atlas = LATAR
	_latar.region = Rect2(Vector2.ZERO, LATAR_FRAME)
	var tr := TextureRect.new()
	tr.texture = _latar
	tr.size = LATAR_FRAME
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panggung.add_child(tr)
	var redup := ColorRect.new()
	redup.color = Color(0, 0, 0, 0.45)
	redup.set_anchors_preset(Control.PRESET_FULL_RECT)
	redup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(redup)

	_buat_judul()
	_buat_panel()
	_hitam = ColorRect.new()
	_hitam.color = Color(0, 0, 0, 0)
	_hitam.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hitam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hitam)
	get_viewport().size_changed.connect(_atur_ukuran)
	_atur_ukuran()
	Suara.musik("menu")
	_tampilkan(_panel_utama)


func _buat_judul() -> void:
	var kotak := VBoxContainer.new()
	kotak.set_anchors_preset(Control.PRESET_TOP_WIDE)
	kotak.offset_top = 34.0
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kotak)
	var judul := Label.new()
	judul.text = "MITOSIS"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_override("font", FONT_JUDUL)
	judul.add_theme_font_size_override("font_size", 92)
	judul.add_theme_color_override("font_color", Color.WHITE)
	judul.add_theme_color_override("font_outline_color", Color.BLACK)
	judul.add_theme_constant_override("outline_size", 18)
	kotak.add_child(judul)
	var sub := Label.new()
	sub.text = "less is more, more is worse"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
	sub.add_theme_color_override("font_outline_color", Color.BLACK)
	sub.add_theme_constant_override("outline_size", 8)
	kotak.add_child(sub)


# Satu kolom di tengah layar, di bawah judul.
func _kolom() -> VBoxContainer:
	var tengah := CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	tengah.anchor_top = 0.3
	tengah.visible = false
	add_child(tengah)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	tengah.add_child(v)
	return v


func _buat_panel() -> void:
	var P := Permainan
	var utama := _kolom()
	_panel_utama = utama.get_parent()
	_tombol = P.buat_tombol("Mulai", func(): _tampilkan(_panel_level))
	utama.add_child(_tombol)
	utama.add_child(P.buat_tombol("Kontrol", func(): _tampilkan(_panel_kontrol)))
	utama.add_child(P.buat_tombol("Pengaturan", func(): _tampilkan(_panel_atur)))
	utama.add_child(P.buat_tombol("Keluar", func(): get_tree().quit()))

	var level := _kolom()
	_panel_level = level.get_parent()
	for i in P.LEVEL.size():
		var b: Button = P.buat_tombol(P.LEVEL[i].nama, _mulai_level.bind(i))
		level.add_child(b)
		_tombol_level.append(b)
	level.add_child(P.buat_tombol("Kembali", func(): _tampilkan(_panel_utama)))

	var kontrol := _kolom()
	_panel_kontrol = kontrol.get_parent()
	kontrol.add_child(P.buat_teks(P.TEKS_KONTROL))
	kontrol.add_child(P.buat_tombol("Kembali", func(): _tampilkan(_panel_utama)))

	var atur := _kolom()
	_panel_atur = atur.get_parent()
	atur.add_child(P.buat_penggeser("Musik", Suara.volume_musik, func(v): Suara.atur_volume(Suara.volume_efek, v)))
	atur.add_child(P.buat_penggeser("Efek suara", Suara.volume_efek, func(v): Suara.atur_volume(v, Suara.volume_musik)))
	atur.add_child(P.buat_tombol("Layar penuh", _ganti_layar_penuh))
	atur.add_child(P.buat_tombol("Kembali", func(): _tampilkan(_panel_utama)))


func _tampilkan(panel: Control) -> void:
	for p in [_panel_utama, _panel_level, _panel_kontrol, _panel_atur]:
		p.visible = p == panel
	var tombol := panel.find_children("*", "Button", true, false)
	if not tombol.is_empty():
		tombol[0].grab_focus()


func _ganti_layar_penuh() -> void:
	var penuh := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if penuh else DisplayServer.WINDOW_MODE_FULLSCREEN)


# Perbesar gambar supaya menutupi layar (bagian pinggir boleh terpotong).
func _atur_ukuran() -> void:
	var layar := get_viewport_rect().size
	var s := maxf(layar.x / LATAR_FRAME.x, layar.y / LATAR_FRAME.y)
	_panggung.scale = Vector2(s, s)
	_panggung.position = (layar - LATAR_FRAME * s) / 2.0


func _process(delta: float) -> void:
	_waktu_latar += delta
	var jumlah := int(LATAR.get_width() / LATAR_FRAME.x)
	_latar.region.position.x = (int(_waktu_latar * LATAR_FPS) % jumlah) * LATAR_FRAME.x


func _mulai_level(i: int) -> void:
	if _mulai:
		return
	_mulai = true
	var tw := create_tween()
	tw.tween_property(_hitam, "color:a", 1.0, 0.4)
	await tw.finished
	Permainan.mulai_level(i)
