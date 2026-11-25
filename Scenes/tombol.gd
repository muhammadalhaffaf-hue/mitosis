extends Area2D
## Tombol injak. Dipakai oleh tombol.tscn (biasa), tombol box.tscn, dan tombol lift.tscn.
##
## Cara menghubungkan: pilih tombol di editor, lalu isi "Target" dengan gerbang / lift
## yang mau dikendalikan. Kalau Target kosong, tombol otomatis memilih gerbang (atau lift,
## untuk tombol lift) yang paling dekat.

enum Jenis { BIASA, BOX, LIFT }

## BIASA: diinjak pemain atau box. BOX: hanya bisa ditekan box. LIFT: menggerakkan lift.
@export var jenis: Jenis = Jenis.BIASA
## Gerbang / lift yang dikendalikan tombol ini (boleh lebih dari satu).
@export var target: Array[NodePath] = []
## Tombol yang harus menyala lebih dulu. Selama belum, tombol ini terkunci.
@export var syarat: Array[NodePath] = []

const WARNA_MATI := Color(0.45, 0.45, 0.48)
const WARNA_NYALA := Color(0.25, 0.95, 0.35)
const WARNA_TERKUNCI := Color(0.9, 0.2, 0.2)

var ditekan := false
## Lampu hijau: sedang ditekan, atau hasilnya sudah menetap.
var menyala := false
var _syarat_node: Array = []
var _lampu: Polygon2D
var _tadi_terkunci := false
var _target_node: Array = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("tombol")
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	# Area deteksi di atas tombol, sedikit masuk ke lantai supaya kaki yang berdiri ikut terdeteksi.
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 22)
	cs.shape = r
	cs.position = Vector2(0, -2)
	add_child(cs)
	sprite.stop()
	sprite.frame = 0
	_buat_lampu()
	_hubungkan.call_deferred()


func _lingkaran(jari: float) -> PackedVector2Array:
	var titik := PackedVector2Array()
	for i in 16:
		titik.append(Vector2.from_angle(TAU * i / 16.0) * jari)
	return titik


func _buat_lampu() -> void:
	var bingkai := Polygon2D.new()
	bingkai.polygon = _lingkaran(11.0)
	bingkai.color = Color.BLACK
	bingkai.top_level = true
	bingkai.z_index = 6
	bingkai.global_position = global_position + Vector2(0, -42)
	bingkai.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(bingkai)
	_lampu = Polygon2D.new()
	_lampu.polygon = _lingkaran(8.0)
	_lampu.color = WARNA_MATI
	bingkai.add_child(_lampu)


func terkunci() -> bool:
	return _syarat_node.any(func(t): return not t.menyala)


func _hasil_menetap() -> bool:
	for n in _target_node:
		if is_instance_valid(n) and ((n.get("tetap_terbuka") == true and n.terbuka) or n.get("_sudah_aktif") == true):
			return true
	return false


func _hubungkan() -> void:
	for p in syarat:
		var s := get_node_or_null(p)
		if s != null:
			_syarat_node.append(s)
	for p in target:
		var n := get_node_or_null(p)
		if n != null and n.has_method("daftar_sumber"):
			_target_node.append(n)
	if _target_node.is_empty():
		var grup := "lift" if jenis == Jenis.LIFT else "gerbang"
		var terdekat = null
		for n in get_tree().get_nodes_in_group(grup):
			if terdekat == null or global_position.distance_to(n.global_position) < global_position.distance_to(terdekat.global_position):
				terdekat = n
		if terdekat != null:
			_target_node.append(terdekat)
	for n in _target_node:
		n.daftar_sumber(self)


func _menekan(body: Node) -> bool:
	if body.is_in_group("box"):
		return true
	if jenis == Jenis.BOX:
		return false
	return body is Pemain and not body.mati


func _physics_process(_delta: float) -> void:
	var kunci := terkunci()
	var sekarang := false
	var disentuh_terkunci := kunci and get_overlapping_bodies().any(_menekan)
	if disentuh_terkunci and not _tadi_terkunci:
		Suara.main_di("terkunci", global_position)
	_tadi_terkunci = disentuh_terkunci
	if not kunci:
		for b in get_overlapping_bodies():
			if _menekan(b):
				sekarang = true
				break
	menyala = sekarang or _hasil_menetap()
	_lampu.color = WARNA_TERKUNCI if kunci else (WARNA_NYALA if menyala else WARNA_MATI)
	if sekarang == ditekan:
		return
	ditekan = sekarang
	if ditekan:
		Suara.main_di("tombol", global_position)
	sprite.frame = 1 if ditekan else 0
	for n in _target_node:
		if is_instance_valid(n):
			n.sumber_berubah()
