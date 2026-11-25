extends CharacterBody2D
## Robot musuh patroli. Jalan bolak-balik, berbalik di dinding dan di ujung lantai.
## Klon yang tersentuh mati. Klon yang cukup kuat bisa menahannya dengan tombol aksi (E).

@export var kecepatan := 90.0
## -1 = mulai jalan ke kiri, 1 = ke kanan.
@export_range(-1, 1, 2) var arah := -1
## Kekuatan minimal untuk menahan. Karakter: besar = 3, sedang = 2, kecil = 1.
@export var kekuatan_penahan := 3
@export var durasi_tahan := 3.0
## Jarak maksimal klon untuk bisa menahan robot.
@export var jarak_interaksi := 150.0
## Batas patroli dari posisi awal, ke kiri dan kanan. 0 = sampai ujung lantai atau dinding.
@export var jarak_patroli := 0.0

var sisa_tahan := 0.0
var _x_awal := 0.0
var _ukuran := Vector2(56, 56)
var _hitbox: Area2D
var _balon: Balon

const JARAK_BALON := 260.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_x_awal = global_position.x
	add_to_group("robot")
	add_to_group("interaksi")
	collision_layer = 8      # layer 4: musuh (pemain tidak tertahan oleh robot)
	collision_mask = 1 | 4   # dunia + platform tembus
	floor_snap_length = 12.0
	floor_max_angle = deg_to_rad(47)
	_buat_tabrakan()
	sprite.play("lari")
	_balon = Balon.new()
	add_child(_balon)


func _process(_delta: float) -> void:
	var p = Pemain.aktif
	if not is_instance_valid(p) or p.mati or p.global_position.distance_to(global_position) > JARAK_BALON:
		_balon.sembunyi()
		return
	_balon.tampil(petunjuk(p), global_position + Vector2(0, -70))


func _buat_tabrakan() -> void:
	var s := scale
	scale = Vector2.ONE
	sprite.scale *= s
	sprite.position *= s
	_ukuran = Vector2(56, 56) * s
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = _ukuran
	cs.shape = r
	add_child(cs)
	# Hitbox sedikit lebih kecil dari badan: yang menyentuh mati.
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 1
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = _ukuran * Vector2(0.5, 0.6)
	hs.shape = hr
	hs.position.y = _ukuran.y * 0.2      # menempel ke lantai, supaya bisa dilompati
	_hitbox.add_child(hs)
	add_child(_hitbox)


func bisa_interaksi(pemain) -> bool:
	return global_position.distance_to(pemain.global_position) <= jarak_interaksi


## Teks saran saat pemain ada di dekat robot.
func petunjuk(pemain) -> String:
	if sisa_tahan > 0.0:
		return "Robot ditahan, cepat lewati!"
	if pemain.kekuatan_dorong >= kekuatan_penahan:
		return "Tekan E untuk menahan robot"
	return "Lompati robot"


func interaksi(pemain) -> void:
	if pemain.kekuatan_dorong < kekuatan_penahan:
		return
	sisa_tahan = durasi_tahan
	Suara.main_di("robot_tahan", global_position)


func _physics_process(delta: float) -> void:
	# Robot menembus karakter (tidak saling dorong). Sentuhan dicek lewat hitbox.
	for p in get_tree().get_nodes_in_group("pemain"):
		add_collision_exception_with(p)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if sisa_tahan > 0.0:
		sisa_tahan -= delta
		velocity.x = 0.0
		sprite.play("takut")                               # anjing merunduk saat ditahan
		sprite.position.x = sin(sisa_tahan * 60.0) * 2.0   # bergetar saat ditahan
		move_and_slide()
		return
	sprite.play("lari")
	sprite.position.x = 0.0

	if is_on_floor() and _ada_jurang_di_depan():
		arah = -arah
	if jarak_patroli > 0.0 and (global_position.x - _x_awal) * arah >= jarak_patroli:
		arah = -arah
	velocity.x = arah * kecepatan
	move_and_slide()
	if is_on_wall():
		arah = -arah
	sprite.flip_h = arah < 0   # gambar anjing menghadap kanan

	for b in _hitbox.get_overlapping_bodies():
		if b is Pemain and not b.mati:
			b.call_deferred("mati_sekarang")


func _ada_jurang_di_depan() -> bool:
	var dari := global_position + Vector2(arah * (_ukuran.x * 0.5 + 4.0), _ukuran.y * 0.5 - 4.0)
	var q := PhysicsRayQueryParameters2D.create(dari, dari + Vector2(0, 28), 1 | 4, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()
