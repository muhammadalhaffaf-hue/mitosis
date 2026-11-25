extends Node2D
## Jebakan api: menyala dan padam bergantian. Klon yang tersentuh api mati.
## Jebakan yang berjajar menyala bergelombang ke kanan, jadi deretan panjang tetap bisa
## dilewati dengan mengikuti celah di antara api.

## Detik padam sebelum menyala.
@export var lama_padam := 1.1
## Detik api berbahaya.
@export var lama_nyala := 0.9
## Kecepatan gelombang (px/detik). 0 = semua jebakan menyala bersamaan.
@export var kecepatan_gelombang := 160.0
## Geser waktu jebakan ini (detik), kalau perlu mengatur urutan manual.
@export var geser_waktu := 0.0

const LAMA_ASAP := 0.4
# Frame animasi "default": 0 = padam, 1 = api tinggi, 2 = bola api, 3-4 = asap.
const FRAME_PADAM := 0
const FRAME_API := 1
const FRAME_BOLA := 2
const FRAME_ASAP := 3

var menyala := false
var _hitbox: Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.stop()
	sprite.frame = FRAME_PADAM
	# Hitbox mengikuti bentuk api di gambar (koordinat piksel frame 32x64).
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 1
	var bentuk := CollisionShape2D.new()
	var kotak := RectangleShape2D.new()
	kotak.size = Vector2(9, 29)
	bentuk.shape = kotak
	bentuk.position = Vector2(0, 16)
	_hitbox.add_child(bentuk)
	sprite.add_child(_hitbox)


func _physics_process(_delta: float) -> void:
	var sekarang := Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)
	var periode := lama_padam + lama_nyala + LAMA_ASAP
	var tunda := global_position.x / kecepatan_gelombang if kecepatan_gelombang > 0.0 else 0.0
	var t := fposmod(sekarang - tunda + geser_waktu, periode) - lama_padam

	var nyala_baru := t >= 0.0 and t < lama_nyala
	if nyala_baru and not menyala:
		Suara.main_di("api", sprite.global_position)
	menyala = nyala_baru
	if t < 0.0:
		sprite.frame = FRAME_PADAM
	elif t < lama_nyala * 0.75:
		sprite.frame = FRAME_API
		sprite.flip_h = int(t * 12.0) % 2 == 0   # api berkedip
	elif t < lama_nyala:
		sprite.frame = FRAME_BOLA
	else:
		sprite.frame = FRAME_ASAP + int((t - lama_nyala) / LAMA_ASAP * 2.0)

	if menyala:
		for b in _hitbox.get_overlapping_bodies():
			if b is Pemain and not b.mati:
				b.call_deferred("mati_sekarang")
