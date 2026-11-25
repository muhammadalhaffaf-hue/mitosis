extends Node2D
## Jebakan panah: menembakkan panah lurus ke arah mulutnya. Klon yang kena mati.
## Panah berhenti di dinding, gerbang, dan box. Klon kecil lewat di bawah panah.

const GAMBAR_PANAH := preload("res://Assests/Foozle_2DTR0001_Pixel_Trap_Pack/Arrow Trap/PNGs/Arrow.png")
const FRAME_TEMBAK := 3
const POSISI_PANAH := Vector2(-30, 4)   # panah muncul tepat di depan mulut

## Kecepatan animasi. Lebih kecil = lebih jarang menembak.
@export var kecepatan_animasi := 0.3
@export var kecepatan_panah := 300.0
## Jarak terbang panah sebelum hilang.
@export var jarak_panah := 1800.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.speed_scale = kecepatan_animasi
	sprite.frame_changed.connect(_saat_frame_berubah)
	sprite.play()


func _saat_frame_berubah() -> void:
	if sprite.frame == FRAME_TEMBAK:
		tembak()


func tembak() -> void:
	Suara.main_di("panah", global_position)
	var arah: Vector2 = -sprite.global_transform.x.normalized()
	var panah := Area2D.new()
	panah.set_script(load("res://Scenes/panah.gd"))
	panah.arah = arah
	panah.kecepatan = kecepatan_panah
	panah.umur = jarak_panah / kecepatan_panah
	panah.global_position = sprite.to_global(POSISI_PANAH)
	panah.rotation = arah.angle() + PI
	var gambar := Sprite2D.new()
	gambar.texture = GAMBAR_PANAH
	gambar.scale = sprite.global_scale.abs()   # sama besar dengan gambar jebakan
	panah.add_child(gambar)
	get_parent().add_child(panah)
