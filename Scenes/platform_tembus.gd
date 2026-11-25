@tool
extends StaticBody2D
## Platform yang bisa ditembus dari bawah. Tekan S / panah bawah untuk turun menembusnya.

@export var lebar := 240.0:
	set(v):
		lebar = v
		queue_redraw()
@export var tebal := 20.0:
	set(v):
		tebal = v
		queue_redraw()


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 4   # layer 3: layer khusus platform tembus
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(lebar, tebal)
	cs.shape = r
	cs.one_way_collision = true
	add_child(cs)


func _draw() -> void:
	var r := Rect2(-lebar * 0.5, -tebal * 0.5, lebar, tebal)
	draw_rect(r, Color.WHITE)
	draw_line(r.position, r.position + Vector2(lebar, 0), Color.BLACK, 3.0)
	# garis putus-putus di bawah = tanda bisa ditembus
	draw_dashed_line(r.position + Vector2(0, tebal), r.end, Color.BLACK, 2.0, 10.0)
	draw_line(r.position, r.position + Vector2(0, tebal), Color.BLACK, 2.0)
	draw_line(r.position + Vector2(lebar, 0), r.end, Color.BLACK, 2.0)
