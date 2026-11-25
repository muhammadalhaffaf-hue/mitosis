extends Area2D
## Panah yang ditembakkan jebakan panah.

var arah := Vector2.LEFT
var kecepatan := 420.0
var umur := 6.0


func _ready() -> void:
	add_to_group("panah")
	collision_layer = 0
	collision_mask = 1
	var bentuk := CollisionShape2D.new()
	var kotak := RectangleShape2D.new()
	kotak.size = Vector2(150, 14)
	bentuk.shape = kotak
	add_child(bentuk)
	body_entered.connect(_kena)


func _physics_process(delta: float) -> void:
	global_position += arah * kecepatan * delta
	umur -= delta
	if umur <= 0.0:
		queue_free()


func _kena(benda: Node) -> void:
	Suara.main_di("panah_kena", global_position)
	if benda is Pemain:
		if benda.mati:
			return
		benda.call_deferred("mati_sekarang")
	queue_free()
