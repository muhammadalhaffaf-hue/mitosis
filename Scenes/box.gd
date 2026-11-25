extends CharacterBody2D
## Box yang bisa didorong. karakter.gd sudah memanggil bisa_didorong_oleh() dan dorong().

## Kekuatan dorong minimal. Karakter: besar = 3, sedang = 2, kecil = 1.
@export var berat := 2

var _dorong_x := 0.0
var _sisa_dorong := 0.0


var _posisi_awal := Vector2.ZERO


## Dipanggil saat pemain kembali ke checkpoint, supaya box yang salah dorong bisa dipakai lagi.
func kembali_ke_awal() -> void:
	if not _di_atas_tombol():
		_pindah_ke_awal()


func _di_atas_tombol() -> bool:
	for t in get_tree().get_nodes_in_group("tombol"):
		if t.ditekan and t.get_overlapping_bodies().has(self):
			return true
	return false


func _pindah_ke_awal() -> void:
	global_position = _posisi_awal
	velocity = Vector2.ZERO


func _ready() -> void:
	_posisi_awal = global_position
	add_to_group("box")
	add_to_group("dorongan")
	collision_layer = 1
	collision_mask = 1 | 4   # dunia/pemain + platform tembus
	floor_snap_length = 12.0
	floor_max_angle = deg_to_rad(47)
	_buat_tabrakan()


## Bentuk tabrakan dibuat dari ukuran gambar, lalu skala node dipindah ke shape
## (body fisika sebaiknya tidak di-scale).
func _buat_tabrakan() -> void:
	var s := scale
	scale = Vector2.ONE
	var sprite := $Sprite2D as Sprite2D
	sprite.scale *= s
	sprite.position *= s
	var ukuran := sprite.texture.get_size() * sprite.scale
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = ukuran - Vector2(2, 0)
	cs.shape = r
	cs.position = sprite.position
	add_child(cs)


func bisa_didorong_oleh(kekuatan: int) -> bool:
	return kekuatan >= berat


func dorong(kecepatan_x: float) -> void:
	_dorong_x = kecepatan_x
	_sisa_dorong = 0.1


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_sisa_dorong -= delta
	if _sisa_dorong > 0.0:
		velocity.x = _dorong_x
	elif is_on_floor() and absf(_miring_lantai()) > 0.25:
		# Di bidang miring box turun pelan
		velocity.x = move_toward(velocity.x, signf(_miring_lantai()) * 60.0, 600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
	move_and_slide()


# Kemiringan tile tepat di bawah box. Tepi lantai datar tidak dihitung miring.
func _miring_lantai() -> float:
	var q := PhysicsRayQueryParameters2D.create(
		global_position, global_position + Vector2(0, 120), 1, [get_rid()])
	var hasil := get_world_2d().direct_space_state.intersect_ray(q)
	if hasil.is_empty() or not hasil.collider is TileMapLayer:
		return 0.0
	return hasil.normal.x
