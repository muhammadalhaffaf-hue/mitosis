extends StaticBody2D
## Gerbang. Terbuka selama tombol yang terhubung ditekan (animasi pintu terbelah).

## true = semua tombol yang terhubung harus ditekan bersamaan (cocok untuk puzzle klon).
## false = cukup salah satu tombol.
@export var perlu_semua_tombol := false
## true = sekali terbuka, tetap terbuka (dengan Perlu Semua Tombol: setelah semua pernah tertekan bersamaan).
@export var tetap_terbuka := false
@export var kecepatan_buka := 0.35
## Petunjuk khusus saat pemain mendekat. Kosong = dibuat otomatis dari tombolnya.
@export_multiline var petunjuk_khusus := ""

var terbuka := false
var _sumber: Array = []
var _posisi_tutup := Vector2.ZERO
var _tween: Tween
var _balon: Balon

const JARAK_BALON := 320.0
const FRAME_TERBUKA := 11
const FRAME_TERTUTUP := 0


func _ready() -> void:
	add_to_group("gerbang")
	collision_layer = 1
	_posisi_tutup = global_position
	_balon = Balon.new()
	add_child(_balon)
	var tinggi: float = ($CollisionShape2D.shape as RectangleShape2D).size.y * absf(global_scale.y)
	$Sprite2D.scale = Vector2.ONE * (tinggi / 320.0) / global_scale.abs()


func daftar_sumber(tombol) -> void:
	if not _sumber.has(tombol):
		_sumber.append(tombol)


func sumber_berubah() -> void:
	var jumlah_ditekan := 0
	for t in _sumber:
		if is_instance_valid(t) and t.ditekan:
			jumlah_ditekan += 1
	var buka := jumlah_ditekan == _sumber.size() if perlu_semua_tombol else jumlah_ditekan > 0
	if terbuka and tetap_terbuka:
		return
	if buka != terbuka:
		set_terbuka(buka)


func _process(_delta: float) -> void:
	var p = Pemain.aktif
	if terbuka or not is_instance_valid(p) or p.mati \
			or p.global_position.distance_to(_posisi_tutup) > JARAK_BALON:
		_balon.sembunyi()
		return
	var uk: Vector2 = ($CollisionShape2D.shape as RectangleShape2D).size * global_scale.abs()
	var tinggi := absf(cos(global_rotation)) * uk.y + absf(sin(global_rotation)) * uk.x
	_balon.tampil(petunjuk(), _posisi_tutup - Vector2(0, tinggi * 0.2))   # di badan pintu supaya tetap terlihat di layar


## Teks cara membuka pintu, ditampilkan saat pemain mendekat.
func petunjuk() -> String:
	if petunjuk_khusus != "":
		return petunjuk_khusus
	var tombol: Array = _sumber.filter(func(t): return is_instance_valid(t))
	if tombol.is_empty():
		return "Pintu ini belum punya tombol"

	var semua_box := tombol.all(func(t): return t.jenis == t.Jenis.BOX)
	var benda := "tombol box (dorong box ke atasnya)" if semua_box else "tombol"
	var teks := ""
	if perlu_semua_tombol and tombol.size() > 1:
		var ditekan: int = tombol.filter(func(t): return t.ditekan).size()
		teks = "Tekan %d %s bersamaan (%d/%d)" % [tombol.size(), benda, ditekan, tombol.size()]
	elif tombol.size() > 1:
		teks = "Tekan salah satu dari %d %s" % [tombol.size(), benda]
	else:
		teks = "Tekan %s" % benda
	if not tetap_terbuka:
		teks += "\nPintu terbuka selama tombol ditekan"

	return "%s\nTombol terdekat: %s" % [teks, _arah_terdekat(tombol)]


func _arah_terdekat(tombol: Array) -> String:
	var terdekat = tombol[0]
	var dari: Vector2 = Pemain.aktif.global_position
	for t in tombol:
		if dari.distance_to(t.global_position) < dari.distance_to(terdekat.global_position):
			terdekat = t
	return Permainan.arah_dari_pemain(terdekat.global_position)


func set_terbuka(value: bool) -> void:
	terbuka = value
	$CollisionShape2D.set_deferred("disabled", terbuka)
	Suara.main_di("pintu_buka" if terbuka else "pintu_tutup", global_position)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(f: float): $Sprite2D.frame = int(f), float($Sprite2D.frame),
		float(FRAME_TERBUKA if terbuka else FRAME_TERTUTUP), kecepatan_buka)
