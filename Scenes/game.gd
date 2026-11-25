
extends Node2D

const KECEPATAN_KAMERA := 7.0

@onready var kamera: Camera2D = $Camera2D


func _ready() -> void:
	# Kamera digerakkan di sini setiap frame layar, jadi tidak perlu dihaluskan dua kali.
	kamera.position_smoothing_enabled = false
	kamera.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Suara.musik("game")
	_siapkan_level.call_deferred()


# Level memakai potongan peta: atur titik mulai dan tujuan sesuai daftar level.
func _siapkan_level() -> void:
	var i: int = Permainan.level_aktif
	var ujung := get_node_or_null("ujung_akhir")
	if i >= 0:
		var data: Dictionary = Permainan.LEVEL[i]
		if data.has("mulai") and is_instance_valid(Pemain.aktif):
			Pemain.aktif.global_position = data.mulai
			Permainan.titik_checkpoint = data.mulai
			kamera.global_position = data.mulai
		if data.has("akhir"):
			if ujung != null:
				ujung.queue_free()
			ujung = load("res://Scenes/ujung_zona.tscn").instantiate()
			ujung.position = data.akhir
			add_child(ujung)
		Permainan.zona_tujuan = ujung
	if i <= 1:
		_tampilkan_panduan()


# Panduan kontrol di atas karakter, di tempat mulai.
func _tampilkan_panduan() -> void:
	if not is_instance_valid(Pemain.aktif):
		return
	var balon := Balon.new()
	add_child(balon)
	balon.tampil(
		"A / D atau panah kiri-kanan: jalan\nSpasi, W, atau panah atas: lompat\nQ: membelah     Tab: ganti klon\nE: interaksi     R: kembali ke checkpoint",
		Pemain.aktif.global_position + Vector2(0, -105))


func _process(delta: float) -> void:
	# Ambil karakter yang sedang dikendalikan
	var target = Pemain.aktif

	if is_instance_valid(target) and not target.is_queued_for_deletion():
		# Kamera mengikuti posisi karakter yang tampil di layar
		kamera.global_position = kamera.global_position.lerp(
			target.posisi_tampil(),
			1.0 - exp(-KECEPATAN_KAMERA * delta)
		)
