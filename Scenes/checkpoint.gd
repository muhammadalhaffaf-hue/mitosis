@tool
extends Area2D
## Checkpoint. Taruh titik node ini di permukaan lantai.
## Disentuh klon mana pun = jadi tempat muncul kembali, dan semua klon bersatu.

var aktif := false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	add_to_group("checkpoint")
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(60, 200)
	cs.shape = r
	cs.position = Vector2(0, -100)
	add_child(cs)
	body_entered.connect(_on_body_entered)


## Posisi munculnya karakter (sedikit di atas lantai).
func titik_muncul() -> Vector2:
	return global_position + Vector2(0, -90)


func set_aktif(value: bool) -> void:
	aktif = value
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body is Pemain and not body.mati:
		Permainan.set_checkpoint.call_deferred(self, body)


func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -160), Color.BLACK, 4.0)
	var bendera := PackedVector2Array([Vector2(2, -160), Vector2(60, -140), Vector2(2, -120)])
	draw_colored_polygon(bendera, Color(0.35, 0.85, 0.45) if aktif else Color.WHITE)
	bendera.append(bendera[0])
	draw_polyline(bendera, Color.BLACK, 3.0)
