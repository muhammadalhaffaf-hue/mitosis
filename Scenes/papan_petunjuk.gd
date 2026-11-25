extends Node2D
## Balon petunjuk yang muncul saat karakter aktif mendekat. Dipakai di tutorial.

@export_multiline var teks := ""
@export var jarak := 300.0

var _balon: Balon


func _ready() -> void:
	_balon = Balon.new()
	add_child(_balon)


func _process(_delta: float) -> void:
	var p = Pemain.aktif
	if is_instance_valid(p) and absf(p.global_position.x - global_position.x) < jarak:
		_balon.tampil(teks, global_position)
	else:
		_balon.sembunyi()
