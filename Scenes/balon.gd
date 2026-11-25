class_name Balon
extends Node2D
## Balon percakapan di dunia game. Titik node ini adalah ujung ekor balon.

var _panel: PanelContainer
var _label: Label


func _init() -> void:
	top_level = true
	z_index = 60
	visible = false
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color.WHITE
	gaya.border_color = Color.BLACK
	gaya.set_border_width_all(3)
	gaya.set_corner_radius_all(10)
	gaya.set_content_margin_all(10)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", gaya)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_panel.add_child(_label)
	add_child(_panel)


func tampil(teks: String, posisi: Vector2) -> void:
	global_position = posisi
	visible = true
	if _label.text != teks:
		_label.text = teks
		var ukuran := _panel.get_combined_minimum_size()
		_panel.size = ukuran
		_panel.position = Vector2(-ukuran.x * 0.5, -ukuran.y - 16.0)


func sembunyi() -> void:
	visible = false


func _draw() -> void:
	var ekor := PackedVector2Array([Vector2(-12, -19), Vector2(12, -19), Vector2(0, -1)])
	draw_colored_polygon(ekor, Color.WHITE)
	draw_line(ekor[0], ekor[2], Color.BLACK, 3.0)
	draw_line(ekor[1], ekor[2], Color.BLACK, 3.0)
