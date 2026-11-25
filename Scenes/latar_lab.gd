extends Node2D
## Background lab bergerak parallax. Gambar: "Warped Sci-Fi Lab" oleh ansimuz.
## Ditaruh di z_index -1, setelah TileMapLayer2, jadi menutupi latar abu-abu polos.

const SKALA := 3.0
const UKURAN := Vector2(320, 240)
const FOLDER := "res://Assests/lab/"
const SHADER := preload("res://Scenes/latar_lab.gdshader")

var _bahan: ShaderMaterial


func _ready() -> void:
	z_index = -1
	_bahan = ShaderMaterial.new()
	_bahan.shader = SHADER

	_tambah_gambar(_lapisan(0.15), "back.png")

	# Mesin, tabung, dan alasnya harus sejajar, jadi bergerak sebagai satu lapisan.
	var depan := _lapisan(0.35)
	_tambah_gambar(depan, "middle.png")
	_tambah_gambar(depan, "support.png", Vector2(16, 0))
	_tambah_gambar(depan, "support.png", Vector2(192, 0))
	_tambah_gambar(depan, "tank-1.png", Vector2(41, 85))
	_tambah_gambar(depan, "tank-2.png", Vector2(119, 85))
	_tambah_gambar(depan, "tank-3.png", Vector2(230, 85))
	_tambah_gambar(depan, "front.png")


func _lapisan(kecepatan: float) -> Parallax2D:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(kecepatan, kecepatan)
	p.repeat_size = UKURAN * SKALA
	p.repeat_times = 3
	add_child(p)
	return p


func _tambah_gambar(induk: Node, nama: String, posisi := Vector2.ZERO) -> void:
	var s := Sprite2D.new()
	s.texture = load(FOLDER + nama)
	s.centered = false
	s.scale = Vector2(SKALA, SKALA)
	s.position = posisi * SKALA
	s.material = _bahan
	induk.add_child(s)
