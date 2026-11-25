extends Node
## Autoload "Suara": efek suara dan musik. Daftar sumber ada di Assests/audio/LISENSI.txt.

const FOLDER := "res://Assests/audio/"
const NAMA_EFEK := ["lompat", "mendarat", "langkah", "belah", "gabung", "mati", "tombol", "terkunci",
	"pintu_buka", "pintu_tutup", "lift", "panah", "panah_kena", "api", "robot_tahan", "dorong",
	"checkpoint", "klik", "sorot", "menang"]
const JARAK_DENGAR := 900.0
const VOLUME_EFEK := -6.0
const VOLUME_MUSIK := -15.0
const FILE_PENGATURAN := "user://pengaturan.cfg"

var volume_efek := 1.0
var volume_musik := 1.0

var _efek := {}
var _pemain: Array[AudioStreamPlayer] = []
var _musik: AudioStreamPlayer
var _musik_sekarang := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMA_EFEK:
		_efek[n] = load(FOLDER + "sfx/" + n + ".ogg")
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pemain.append(p)
	_musik = AudioStreamPlayer.new()
	add_child(_musik)
	var cfg := ConfigFile.new()
	if cfg.load(FILE_PENGATURAN) == OK:
		volume_efek = cfg.get_value("audio", "efek", 1.0)
		volume_musik = cfg.get_value("audio", "musik", 1.0)
	_terapkan_musik()


func _terapkan_musik() -> void:
	_musik.volume_db = VOLUME_MUSIK + linear_to_db(maxf(volume_musik, 0.001))


func atur_volume(efek: float, lagu: float) -> void:
	volume_efek = efek
	volume_musik = lagu
	_terapkan_musik()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "efek", efek)
	cfg.set_value("audio", "musik", lagu)
	cfg.save(FILE_PENGATURAN)


func main(nama: String, volume := 0.0) -> void:
	for p in _pemain:
		if not p.playing:
			p.stream = _efek[nama]
			p.volume_db = VOLUME_EFEK + volume + linear_to_db(maxf(volume_efek, 0.001))
			p.play()
			return


## Suara dari benda di dunia: makin jauh dari karakter aktif makin pelan.
func main_di(nama: String, posisi: Vector2) -> void:
	if not is_instance_valid(Pemain.aktif):
		return
	var jarak: float = Pemain.aktif.global_position.distance_to(posisi)
	if jarak < JARAK_DENGAR:
		main(nama, -18.0 * jarak / JARAK_DENGAR)


func musik(nama: String) -> void:
	if nama == _musik_sekarang:
		return
	_musik_sekarang = nama
	var s: AudioStreamOggVorbis = load(FOLDER + "musik/" + nama + ".ogg")
	s.loop = true
	_musik.stream = s
	_musik.play()
