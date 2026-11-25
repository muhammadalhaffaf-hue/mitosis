@tool
extends AnimatableBody2D
## Platform bergerak / lift.
## - Tidak ada tombol lift yang terhubung: bergerak bolak-balik sendiri.
## - Ada tombol lift yang terhubung: bergerak ke titik akhir selama tombol ditekan,
##   lalu kembali ke titik awal saat tombol dilepas.

## Jarak dari posisi awal ke titik akhir (garis tipis di editor).
@export var jarak := Vector2(0, -320):
	set(v):
		jarak = v
		queue_redraw()
@export var kecepatan := 140.0
## Waktu berhenti di ujung (mode bolak-balik).
@export var jeda := 0.6
@export var lebar := 160.0:
	set(v):
		lebar = v
		queue_redraw()
@export var tebal := 24.0:
	set(v):
		tebal = v
		queue_redraw()
## true = bisa dilompati dari bawah, seperti platform tembus.
@export var tembus_dari_bawah := false
## true = setelah tombol ditekan sekali, platform terus bergerak bolak-balik sendiri.
@export var tetap_aktif := false

var _sudah_aktif := false
var _awal := Vector2.ZERO
var _t := 0.0          # 0 = di titik awal, 1 = di titik akhir
var _arah := 1.0
var _tunggu := 0.0
var _sumber: Array = []


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	add_to_group("lift")
	sync_to_physics = true
	collision_layer = 4 if tembus_dari_bawah else 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(lebar, tebal)
	cs.shape = r
	cs.one_way_collision = tembus_dari_bawah
	add_child(cs)
	_awal = position


func daftar_sumber(tombol) -> void:
	if not _sumber.has(tombol):
		_sumber.append(tombol)


func sumber_berubah() -> void:
	pass   # dicek tiap frame di _physics_process


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var panjang := maxf(jarak.length(), 1.0)
	var langkah := kecepatan * delta / panjang
	if tetap_aktif and not _sudah_aktif:
		for t in _sumber:
			if is_instance_valid(t) and t.ditekan:
				_sudah_aktif = true
				Suara.main_di("lift", global_position)
	if _sumber.is_empty() or _sudah_aktif:
		if _tunggu > 0.0:
			_tunggu -= delta
			return
		_t += langkah * _arah
		if _t >= 1.0 or _t <= 0.0:
			_t = clampf(_t, 0.0, 1.0)
			_arah = -_arah
			_tunggu = jeda
	else:
		var aktif := false
		for t in _sumber:
			if is_instance_valid(t) and t.ditekan:
				aktif = true
		_t = move_toward(_t, 1.0 if aktif else 0.0, langkah)
	position = _awal + jarak * _t


func _draw() -> void:
	var r := Rect2(-lebar * 0.5, -tebal * 0.5, lebar, tebal)
	draw_rect(r, Color.WHITE)
	draw_rect(r, Color.BLACK, false, 3.0)
	if tembus_dari_bawah:
		draw_line(r.position + Vector2(0, tebal), r.end, Color(0, 0, 0, 0.4), 2.0)
	if Engine.is_editor_hint():
		draw_dashed_line(Vector2.ZERO, jarak, Color(1, 0.6, 0.1), 2.0, 8.0)
		draw_rect(Rect2(r.position + jarak, r.size), Color(1, 0.6, 0.1), false, 2.0)
