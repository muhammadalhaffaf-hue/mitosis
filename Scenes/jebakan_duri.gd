extends Node2D
## Jebakan duri: klon yang menyentuhnya mati. Hitbox mengikuti bagian gambar yang terisi.

var _hitbox: Area2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var isi := Rect2(sprite.texture.get_image().get_used_rect())
	var ukuran := sprite.texture.get_size()
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 1
	var bentuk := CollisionShape2D.new()
	var kotak := RectangleShape2D.new()
	kotak.size = isi.size * Vector2(0.55, 0.45)    # lebih kecil dari gambar supaya adil
	bentuk.shape = kotak
	bentuk.position = isi.get_center() - ukuran / 2.0 + Vector2(0, isi.size.y * 0.27)
	_hitbox.add_child(bentuk)
	sprite.add_child(_hitbox)


func _physics_process(_delta: float) -> void:
	for b in _hitbox.get_overlapping_bodies():
		if b is Pemain and not b.mati:
			b.call_deferred("mati_sekarang")
