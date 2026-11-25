
extends CharacterBody2D
class_name Pemain

# Karakter yang sedang dikendalikan
static var aktif: Pemain = null
static var frame_switch_terakhir := -1
var mati := false

const WARNA_TIDAK_AKTIF = Color(0.6, 0.6, 0.6)

# 0 = besar, 1 = sedang, 2 = kecil
@export var tingkat: int = 0

const MAKS_TINGKAT = 2
const MAKS_KARAKTER = 4

# Statistik berdasarkan ukuran
const STAT_KECEPATAN = [320.0, 230.0, 160.0]
const STAT_LOMPAT = [-680.0, -510.0, -370.0]
const STAT_DORONG = [3, 2, 1]

const SKALA_PER_BELAH = 0.65
const KECEPATAN_DORONG = 0.5

@export var jarak_menyatu: float = 30.0

var speed: float
var kekuatan_dorong: int
var jump_velocity: float

var sedang_membelah := false
var sedang_menyatu := false
var sedang_mendorong := false
var sedang_mendarat := false
var hasil_gabungan := false
# [MEKANIK] kembaran mati tapi tempat terlalu sempit untuk membesar
var tunda_membesar := false

const TIDAK_ADA_RUANG := Vector2.INF

# [HALUS] Rasa gerak. Percepatan dihitung per detik, dikali kecepatan karakter.
const PERCEPATAN_TANAH := 14.0
const PENGEREMAN_TANAH := 18.0
const PERCEPATAN_UDARA := 30.0   # tinggi supaya jangkauan lompatan tidak berkurang
const WAKTU_COYOTE := 0.1        # masih bisa lompat sesaat setelah lepas dari tepi
const WAKTU_BUFFER_LOMPAT := 0.12 # tombol lompat sesaat sebelum mendarat tetap terhitung
const LANGKAH_PER_DETIK := 1.5   # pengali kecepatan animasi jalan (1 = kecepatan asli)
const MIRING_MAKS := 0.07
const KECEPATAN_TURUN_MIRING := 60.0
const BONUS_TUMPUK := 1.4         # lompat dari atas klon lain jadi lebih tinggi
const WAKTU_ANIMASI_DORONG := 0.15

var _sisa_coyote := 0.0
var _sisa_buffer := 0.0
var _skala_dasar := Vector2.ONE
var _posisi_sprite := Vector2.ZERO
var _regang := Vector2.ONE
var _sisa_tumpuk := 0.0
var _sisa_langkah := 0.0
var _alas: Pemain = null          # klon yang sedang dipijak
var _posisi_alas := Vector2.ZERO
var _sisa_animasi_dorong := 0.0
var _posisi_lalu := Vector2.ZERO

# Mencegah animasi mendarat langsung saat game dimulai
var fisika_sudah_dimulai := false

var skala_sprite_utuh := Vector2.ZERO
var skala_collision_utuh := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


# ============================
# READY
# ============================

func _ready() -> void:
	add_to_group("pemain")
	_posisi_lalu = global_position

	if not is_instance_valid(aktif):
		aktif = self

	# [MEKANIK] daftarkan ke sistem darah & checkpoint
	Permainan.daftar_pemain(self)

	# Ukuran sesuai tingkat
	var ukuran := pow(SKALA_PER_BELAH, tingkat)

	if skala_sprite_utuh == Vector2.ZERO:
		skala_sprite_utuh = sprite.scale / ukuran
		skala_collision_utuh = collision.scale / ukuran

	sprite.scale = skala_sprite_utuh * ukuran
	collision.scale = skala_collision_utuh * ukuran

	# [HALUS] Ukuran dasar untuk efek meregang dan memipih
	_skala_dasar = sprite.scale
	_posisi_sprite = sprite.position

	# Kemampuan sesuai ukuran
	speed = STAT_KECEPATAN[tingkat]
	jump_velocity = STAT_LOMPAT[tingkat]
	kekuatan_dorong = STAT_DORONG[tingkat]

	# Animasi yang hanya dimainkan sekali
	sprite.sprite_frames.set_animation_loop("clone", false)
	sprite.sprite_frames.set_animation_loop("mendarat", false)
	sprite.sprite_frames.set_animation_loop("lompat", false)

	sprite.animation_finished.connect(_on_animation_finished)

	# Karakter hasil gabungan memainkan clone terbalik
	if hasil_gabungan:
		sedang_menyatu = true
		sprite.play_backwards("clone")

# Mencari clone dengan tingkat sama, tanpa batas jarak
func _cari_kembaran() -> Pemain:
	var terdekat: Pemain = null
	var jarak_terdekat := INF

	for node in get_tree().get_nodes_in_group("pemain"):
		var lain := node as Pemain

		if lain == null or lain == self or lain.mati:
			continue
		if lain.is_queued_for_deletion():
			continue
		if lain.tingkat != tingkat:
			continue
		if lain.sedang_membelah or lain.sedang_menyatu:
			continue

		var jarak := global_position.distance_to(lain.global_position)
		if jarak < jarak_terdekat:
			jarak_terdekat = jarak
			terdekat = lain

	return terdekat


# Diri ini diganti dengan versi yang lebih besar (tingkat - 1)
func kembali_membesar() -> Pemain:
	if scene_file_path.is_empty():
		return null

	var scene := load(scene_file_path) as PackedScene
	if scene == null:
		return null

	var besar := scene.instantiate() as Pemain

	besar.tingkat = tingkat - 1
	besar.hasil_gabungan = true   # memainkan animasi clone terbalik

	# Warisi ukuran asli
	besar.scale = scale
	besar.skala_sprite_utuh = skala_sprite_utuh
	besar.skala_collision_utuh = skala_collision_utuh

	# Naikkan posisi supaya kaki tetap di tanah
	var tinggi_sekarang := collision.shape.get_rect().size.y \
			* collision.scale.y * scale.y
	var tinggi_baru := tinggi_sekarang / SKALA_PER_BELAH

	# [MEKANIK] Cari tempat yang cukup luas (jangan membesar di dalam dinding/atap)
	var tujuan := cari_ruang(tingkat - 1, global_position - Vector2(
		0,
		(tinggi_baru - tinggi_sekarang) / 2.0
	))
	if tujuan == TIDAK_ADA_RUANG:
		besar.free()
		return null
	besar.position = get_parent().to_local(tujuan)

	besar.get_node("AnimatedSprite2D").flip_h = sprite.flip_h

	get_parent().add_child(besar)
	queue_free()

	return besar

func mati_sekarang() -> void:
	if mati:
		return
	mati = true
	Suara.main_di("mati", global_position)
	sedang_mendarat = false

	# Cari kembaran SEBELUM keluar dari group
	var kembaran: Pemain = null
	if tingkat > 0:
		kembaran = _cari_kembaran()

	remove_from_group("pemain")

	var tree := get_tree()
	var sisa := tree.get_nodes_in_group("pemain")

	# [MEKANIK] Darah -1. Kalau darah habis atau ini karakter terakhir,
	# Permainan memunculkan karakter lagi di checkpoint.
	if Permainan.klon_mati(sisa.size()):
		var tw := create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tw.finished
		queue_free()
		return

	# Kembaran membesar kembali
	var pengganti: Pemain = null
	if kembaran != null:
		var kembaran_aktif := aktif == kembaran
		pengganti = kembaran.kembali_membesar()

		# [MEKANIK] Terlalu sempit: kembaran membesar nanti begitu ada ruang
		if pengganti == null and is_instance_valid(kembaran):
			kembaran.tunda_membesar = true
			Permainan.pesan("Terlalu sempit untuk membesar, keluar dulu")

		if pengganti != null and (kembaran_aktif or aktif == self):
			aktif = pengganti

	# Pindahkan kontrol jika yang mati adalah clone aktif
	if aktif == self:
		var kandidat := tree.get_nodes_in_group("pemain")
		for p in kandidat:
			if p != self and not p.is_queued_for_deletion():
				aktif = p
				break

	# Menghilang sambil jatuh, lalu dihapus
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

# ============================
# PHYSICS PROCESS
# ============================

func _physics_process(delta: float) -> void:
	_posisi_lalu = global_position

	# Karakter mati: hanya jatuh karena gravitasi
	if mati:
		velocity += get_gravity() * delta
		velocity.x = 0
		move_and_slide()
		return

	var dikendalikan := aktif == self

	# Clone tidak aktif lebih gelap
	sprite.modulate = Color.WHITE if dikendalikan else WARNA_TIDAK_AKTIF

	# Tunggu animasi membelah / menyatu selesai
	if sedang_membelah or sedang_menyatu:
		velocity = Vector2.ZERO
		return

	# [MEKANIK] Membesar yang tertunda: coba lagi setiap beberapa frame
	if tunda_membesar and Engine.get_physics_frames() % 6 == 0:
		var dulu_aktif := aktif == self
		var besar := kembali_membesar()
		if besar != null:
			if dulu_aktif:
				aktif = besar
			return

	_ikut_alas(delta)

	# Simpan kondisi tanah sebelum bergerak
	var sebelumnya_di_tanah := is_on_floor()

	# Gravitasi semua clone
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := 0.0

	# [HALUS] Toleransi waktu lompat
	_sisa_coyote = WAKTU_COYOTE if is_on_floor() else maxf(_sisa_coyote - delta, 0.0)
	_sisa_buffer = maxf(_sisa_buffer - delta, 0.0)

	if dikendalikan:

		# Ganti clone
		if Input.is_action_just_pressed("switch") \
				and Engine.get_physics_frames() != frame_switch_terakhir:

			frame_switch_terakhir = Engine.get_physics_frames()
			_ganti_clone()
			return

		# Lompat
		if Input.is_action_just_pressed("lompat"):
			_sisa_buffer = WAKTU_BUFFER_LOMPAT

		if _sisa_buffer > 0.0 and _sisa_coyote > 0.0:
			velocity.y = jump_velocity * (BONUS_TUMPUK if _sisa_tumpuk > 0.0 else 1.0)
			_sisa_tumpuk = 0.0
			_sisa_buffer = 0.0
			_sisa_coyote = 0.0
			_regang = Vector2(0.84, 1.18)
			Suara.main("lompat")

			# Batalkan animasi mendarat jika melompat lagi
			sedang_mendarat = false
			sprite.play("lompat")

		# Membelah
		if Input.is_action_just_pressed("membelah") \
				and tingkat < MAKS_TINGKAT \
				and is_on_floor():

			var jumlah := get_tree().get_nodes_in_group("pemain").size()

			if jumlah < MAKS_KARAKTER:
				sedang_membelah = true
				Suara.main("belah")
				sedang_mendarat = false
				velocity = Vector2.ZERO
				sprite.play("clone")
				return

		# Menyatu / tombol aksi
		if Input.is_action_just_pressed("menyatu"):
			var pasangan: Pemain = _cari_pasangan() if tingkat > 0 else null

			if pasangan != null:
				sedang_mendarat = false
				_menyatu_dengan(pasangan)
				return

			# [MEKANIK] tidak ada pasangan: aksi ke objek terdekat (contoh: menahan robot)
			_coba_interaksi()

		# [MEKANIK] Turun menembus platform tembus
		if Input.is_action_just_pressed("turun") and is_on_floor():
			_tembus_platform()

		# Jalan kiri / kanan
		direction = Input.get_axis("kiri", "kanan")

	# Mengatur pergerakan horizontal
	# [HALUS] Kecepatan naik dan turun bertahap, tidak langsung penuh
	var percepatan := PERCEPATAN_UDARA
	var sasaran_x := direction * speed
	if is_on_floor():
		percepatan = PERCEPATAN_TANAH if direction != 0 else PENGEREMAN_TANAH
		# Diam di bidang miring: turun pelan
		var miring := _miring_lantai() if direction == 0 else 0.0
		if absf(miring) > 0.25:
			sasaran_x = signf(miring) * KECEPATAN_TURUN_MIRING
	velocity.x = move_toward(velocity.x, sasaran_x, percepatan * speed * delta)

	# Gerakkan karakter
	var kecepatan_jatuh := velocity.y
	move_and_slide()
	_perbarui_tumpuk(delta)

	# Deteksi ketika karakter baru menyentuh tanah
	if fisika_sudah_dimulai \
			and not sebelumnya_di_tanah \
			and is_on_floor():

		sedang_mendarat = true
		sprite.play("mendarat")
		var hentakan := clampf(kecepatan_jatuh / 900.0, 0.25, 1.0)
		_regang = Vector2(1.0 + 0.24 * hentakan, 1.0 - 0.22 * hentakan)
		if aktif == self:
			Suara.main("mendarat")

	fisika_sudah_dimulai = true

	_cek_dorong(direction)
	_suara_gerak(delta, direction)
	_update_animasi(direction)


# ============================
# GANTI CLONE
# ============================

func _ganti_clone() -> void:
	var semua := get_tree().get_nodes_in_group("pemain")

	semua = semua.filter(
		func(p): return not p.is_queued_for_deletion()
	)

	if semua.size() <= 1:
		return

	# Urutkan dari kiri ke kanan
	semua.sort_custom(
		func(a, b): return a.global_position.x < b.global_position.x
	)

	var i := semua.find(self)

	aktif = semua[(i + 1) % semua.size()] as Pemain


# ============================
# [MEKANIK] AKSI & PLATFORM TEMBUS
# ============================

# Objek aksi: masuk grup "interaksi", punya bisa_interaksi(pemain) dan interaksi(pemain).
func _coba_interaksi() -> bool:
	var terdekat: Node2D = null
	for n in get_tree().get_nodes_in_group("interaksi"):
		if not n.bisa_interaksi(self):
			continue
		if terdekat == null or global_position.distance_to(n.global_position) \
				< global_position.distance_to(terdekat.global_position):
			terdekat = n
	if terdekat == null:
		return false
	terdekat.interaksi(self)
	return true


# Cari posisi (global) terdekat dari `pusat` yang cukup luas untuk ukuran `tingkat_baru`.
# Kaki tetap di ketinggian yang sama, hanya digeser ke samping (atau sedikit ke atas
# di tanah miring). Mengembalikan TIDAK_ADA_RUANG kalau tidak ada tempat.
func cari_ruang(tingkat_baru: int, pusat: Vector2) -> Vector2:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = collision.shape
	q.collision_mask = 1   # dunia, gerbang, box (bukan platform tembus)
	var abaikan: Array[RID] = []
	for n in get_parent().get_children():
		if n is Pemain:
			abaikan.append(n.get_rid())
	q.exclude = abaikan
	var skala := skala_collision_utuh * pow(SKALA_PER_BELAH, tingkat_baru) * scale * 0.97
	var ruang := get_world_2d().direct_space_state
	for i in 41:
		var dx := ceilf(i / 2.0) * 6.0 * (1 if i % 2 == 0 else -1)   # 0, -6, 6, -12, 12 ...
		for dy in [0.0, -10.0, -20.0]:
			var p := pusat + Vector2(dx, dy - 2.0)
			q.transform = Transform2D(0.0, skala, 0.0, p + collision.position * scale)
			if ruang.intersect_shape(q, 1).is_empty():
				return p
	return TIDAK_ADA_RUANG


# Platform tembus ada di collision layer 3. Matikan sebentar supaya bisa jatuh lewat.
func _tembus_platform() -> void:
	set_collision_mask_value(3, false)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		set_collision_mask_value(3, true)


# ============================
# MENDORONG
# ============================

# Kemiringan tile tepat di bawah badan. Tepi lantai datar tidak dihitung miring.
func _miring_lantai() -> float:
	var tinggi := collision.shape.get_rect().size.y * collision.scale.y * scale.y
	var q := PhysicsRayQueryParameters2D.create(
		global_position, global_position + Vector2(0, tinggi * 0.5 + 24.0), 1, [get_rid()])
	var hasil := get_world_2d().direct_space_state.intersect_ray(q)
	if hasil.is_empty() or not hasil.collider is TileMapLayer:
		return 0.0
	return hasil.normal.x


func _suara_gerak(delta: float, direction: float) -> void:
	_sisa_langkah -= delta
	if aktif != self or direction == 0.0 or not is_on_floor() or _sisa_langkah > 0.0:
		return
	_sisa_langkah = 0.38 if sedang_mendorong else 0.3
	Suara.main("dorong" if sedang_mendorong else "langkah", -8.0)


# [TUMPUK] Berdiri di atas klon lain memberi lompatan lebih tinggi.
func _perbarui_tumpuk(delta: float) -> void:
	_sisa_tumpuk = maxf(_sisa_tumpuk - delta, 0.0)
	for i in get_slide_collision_count():
		var tabrakan := get_slide_collision(i)
		var benda := tabrakan.get_collider()
		if benda is Pemain and tabrakan.get_normal().y < -0.5:
			_sisa_tumpuk = WAKTU_COYOTE
			if _alas != benda:
				_alas = benda
				_posisi_alas = benda.global_position


# [TUMPUK] Klon di atas ikut bergerak bersama klon di bawahnya (misalnya saat naik lift).
func _ikut_alas(delta: float) -> void:
	if not is_instance_valid(_alas) or _alas.mati or _sisa_tumpuk <= 0.0 or velocity.y < 0.0:
		_alas = null
		return
	global_position += _alas.global_position - _posisi_alas
	_posisi_alas = _alas.global_position
	var ditekan := aktif == self and Input.get_axis("kiri", "kanan") != 0.0
	if not ditekan:
		global_position.x = move_toward(global_position.x, _alas.global_position.x, 40.0 * delta)


func _cek_dorong(direction: float) -> void:
	# [HALUS] Box bergerak menjauh, jadi sentuhannya putus-putus: animasi ditahan sebentar.
	_sisa_animasi_dorong = maxf(_sisa_animasi_dorong - get_physics_process_delta_time(), 0.0)

	for i in get_slide_collision_count():
		var tabrakan := get_slide_collision(i)
		var benda := tabrakan.get_collider()

		if benda and benda.is_in_group("dorongan") \
				and is_on_floor() \
				and abs(tabrakan.get_normal().x) > 0.7 \
				and tabrakan.get_normal().x * direction < 0:

			_sisa_animasi_dorong = WAKTU_ANIMASI_DORONG

			if benda.has_method("bisa_didorong_oleh") \
					and benda.has_method("dorong"):

				if benda.bisa_didorong_oleh(kekuatan_dorong):
					benda.dorong(
						direction * speed * KECEPATAN_DORONG
					)
				elif aktif == self:
					Permainan.pesan("Terlalu kecil untuk mendorong box")

	sedang_mendorong = _sisa_animasi_dorong > 0.0 and direction != 0.0 and is_on_floor()


# ============================
# ANIMASI
# ============================

func _update_animasi(direction: float) -> void:
	# Arah hadap
	if direction != 0 and sprite.flip_h != (direction < 0):
		sprite.flip_h = direction < 0
		_regang.x = minf(_regang.x, 0.86)   # [HALUS] kesan berbalik

	# [HALUS] Mendarat sambil berjalan langsung lanjut berjalan
	if sedang_mendarat and direction != 0:
		sedang_mendarat = false

	# Jangan ganggu animasi mendarat sampai selesai
	if sedang_mendarat:
		return

	# Karakter di udara
	if not is_on_floor():
		_mainkan("lompat")

	# Mendorong objek
	elif sedang_mendorong:
		_mainkan("dorong")

	# Berjalan
	elif direction != 0:
		_mainkan("jalan")

	# Diam
	else:
		_mainkan("idle")



# [HALUS] Posisi yang tampil di layar di antara dua langkah fisika (dipakai kamera).
func posisi_tampil() -> Vector2:
	return _posisi_lalu.lerp(global_position, Engine.get_physics_interpolation_fraction())


# [HALUS] Efek visual dihitung tiap frame layar. Tidak memengaruhi tabrakan.
func _process(delta: float) -> void:
	_regang = _regang.lerp(Vector2.ONE, 1.0 - exp(-14.0 * delta))
	sprite.scale = _skala_dasar * _regang
	# Kaki tetap di tanah saat badan memipih atau meregang
	sprite.position = _posisi_sprite + Vector2(0, 40.0 * _skala_dasar.y * (1.0 - _regang.y) * 0.8)

	var kecepatan_relatif := clampf(velocity.x / speed, -1.0, 1.0) if speed > 0.0 else 0.0
	var miring := kecepatan_relatif * MIRING_MAKS if is_on_floor() and not mati else 0.0
	sprite.rotation = lerp_angle(sprite.rotation, miring, 1.0 - exp(-12.0 * delta))

	match sprite.animation:
		&"jalan":
			sprite.speed_scale = LANGKAH_PER_DETIK * clampf(absf(kecepatan_relatif), 0.4, 1.0)
		&"dorong":
			sprite.speed_scale = 1.6
		&"mendarat":
			sprite.speed_scale = 2.0
		_:
			sprite.speed_scale = 1.0


func _mainkan(nama: String) -> void:
	if sprite.animation != nama:
		sprite.play(nama)

	elif not sprite.is_playing() and nama != "lompat":
		sprite.play(nama)



# ============================
# ANIMASI SELESAI
# ============================

func _on_animation_finished() -> void:

	# Animasi menyatu selesai
	if sedang_menyatu and sprite.animation == "clone":
		sedang_menyatu = false
		_mainkan("idle")

	# Animasi membelah selesai
	elif sedang_membelah and sprite.animation == "clone":
		_belah()

	# Animasi mendarat selesai
	elif sedang_mendarat and sprite.animation == "mendarat":
		sedang_mendarat = false

		# Kembali ke animasi sesuai kondisi karakter
		if not is_on_floor():
			_mainkan("lompat")
		elif aktif == self and Input.get_axis("kiri", "kanan") != 0:
			_mainkan("jalan")
		else:
			_mainkan("idle")


# ============================
# MEMBELAH
# ============================

func _belah() -> void:
	if scene_file_path.is_empty():
		sedang_membelah = false
		_mainkan("idle")
		return

	var scene := load(scene_file_path) as PackedScene

	if scene == null:
		sedang_membelah = false
		_mainkan("idle")
		return

	var jarak := 20.0 * _skala_dasar.x * scale.x
	var arah_hadap := -1 if sprite.flip_h else 1
	var masih_aktif := aktif == self

	for arah in [-1, 1]:
		var anak := scene.instantiate() as Pemain

		anak.tingkat = tingkat + 1

		# Warisi ukuran asli
		anak.scale = scale
		anak.skala_sprite_utuh = skala_sprite_utuh
		anak.skala_collision_utuh = skala_collision_utuh

		# Posisi hasil belahan
		anak.position = position + Vector2(arah * jarak, 0)
		anak.velocity = Vector2(arah * 150, -150)

		anak.get_node("AnimatedSprite2D").flip_h = sprite.flip_h

		get_parent().add_child(anak)

		# Clone depan menjadi karakter aktif
		if masih_aktif and arah == arah_hadap:
			aktif = anak

	queue_free()


# ============================
# MENCARI PASANGAN
# ============================

func _cari_pasangan() -> Pemain:
	var terdekat: Pemain = null
	var jarak_terdekat := jarak_menyatu

	for node in get_tree().get_nodes_in_group("pemain"):
		var lain := node as Pemain

		if lain == null or lain == self:
			continue

		if lain.is_queued_for_deletion():
			continue

		if lain.tingkat != tingkat:
			continue

		if lain.sedang_membelah or lain.sedang_menyatu:
			continue

		var jarak := global_position.distance_to(lain.global_position)

		if jarak <= jarak_terdekat:
			jarak_terdekat = jarak
			terdekat = lain

	return terdekat


# ============================
# MENYATU
# ============================

func _menyatu_dengan(pasangan: Pemain) -> void:
	if scene_file_path.is_empty():
		return

	var scene := load(scene_file_path) as PackedScene

	if scene == null:
		return

	# Kunci kedua karakter
	sedang_menyatu = true
	pasangan.sedang_menyatu = true

	# Buat karakter hasil gabungan
	var gabungan := scene.instantiate() as Pemain

	gabungan.tingkat = tingkat - 1

	# Hasil gabungan memainkan animasi clone terbalik
	gabungan.hasil_gabungan = true

	# Warisi ukuran asli
	gabungan.scale = scale
	gabungan.skala_sprite_utuh = skala_sprite_utuh
	gabungan.skala_collision_utuh = skala_collision_utuh

	# Posisi hasil gabungan
	var tengah := (position + pasangan.position) / 2.0

	var tinggi_sekarang := collision.shape.get_rect().size.y \
			* collision.scale.y * scale.y

	var tinggi_baru := tinggi_sekarang / SKALA_PER_BELAH

	# [MEKANIK] Tolak bergabung kalau tempatnya terlalu sempit
	var tujuan := cari_ruang(tingkat - 1, get_parent().to_global(tengah) - Vector2(
		0,
		(tinggi_baru - tinggi_sekarang) / 2.0
	))
	if tujuan == TIDAK_ADA_RUANG:
		sedang_menyatu = false
		pasangan.sedang_menyatu = false
		gabungan.free()
		Permainan.pesan("Terlalu sempit untuk bergabung")
		return
	gabungan.position = get_parent().to_local(tujuan)
	Suara.main("gabung")

	# Pertahankan arah hadap
	gabungan.get_node("AnimatedSprite2D").flip_h = sprite.flip_h

	# Tambahkan karakter gabungan
	get_parent().add_child(gabungan)

	# Kontrol berpindah ke hasil gabungan
	aktif = gabungan

	# Hapus kedua clone lama
	pasangan.queue_free()
	queue_free()
