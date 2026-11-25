@tool
extends Area2D
## Ujung zona. Taruh titik node ini di permukaan lantai.
## Klon pertama yang masuk: semua klon bersatu jadi satu karakter utuh,
## darah penuh lagi, dan tempat ini jadi checkpoint.

const GAMBAR_LIFT := preload("res://Assests/ujung_lift.png")
const GAMBAR_REL := preload("res://Assests/ujung_rel.png")
const SKALA := 3.0

var selesai := false:
	set(v):
		selesai = v
		if v and is_inside_tree():
			create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(self, "_naik", 420.0, 1.6)
var _naik := 0.0:
	set(v):
		_naik = v
		queue_redraw()


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(80, 240)
	cs.shape = r
	cs.position = Vector2(0, -120)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func titik_muncul() -> Vector2:
	return global_position + Vector2(0, -90)


func set_aktif(_value: bool) -> void:
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not selesai and body is Pemain and not body.mati:
		Permainan.selesai_zona.call_deferred(self, body)


func _draw() -> void:
	# Rel menjulang dari lantai, kapsul lift naik saat zona selesai.
	var ukuran_rel := GAMBAR_REL.get_size() * SKALA
	for i in 3:
		draw_texture_rect(GAMBAR_REL, Rect2(-ukuran_rel.x * 0.5, -ukuran_rel.y * (i + 1), ukuran_rel.x, ukuran_rel.y), false)
	var ukuran := GAMBAR_LIFT.get_size() * SKALA
	draw_texture_rect(GAMBAR_LIFT, Rect2(-ukuran.x * 0.5, -ukuran.y - _naik, ukuran.x, ukuran.y), false)
