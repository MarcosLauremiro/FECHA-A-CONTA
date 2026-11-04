class_name Sfx
extends Node
## Sons e música do jogo. A interface chama play("nome"); os nomes e arquivos estão em PATHS.
## Se o arquivo ainda não existe na pasta, não toca nada e não dá erro (os áudios chegam aos poucos).
## Os arquivos e a ordem de prioridade estão em sfx/README.md e music/README.md.

const PATHS := {
	"bipe_tecla": "res://sfx/caixa/s01_bipe_tecla.ogg",
	"bipe_subindo": "res://sfx/pontuacao/s02_bipe_subindo.ogg",
	"maquininha": "res://sfx/pontuacao/s03_maquininha.ogg",
	"registradora": "res://sfx/pontuacao/s04_caixa_registradora.ogg",
	"impressora": "res://sfx/caixa/s05_impressora_termica.ogg",
	"papel": "res://sfx/caixa/s06_papel_embaralhando.ogg",
	"moedas": "res://sfx/eventos/s07_moedas_caindo.ogg",
	"relampago": "res://sfx/eventos/s08_relampago_recebido.ogg",
	"fita": "res://sfx/loja/s09_fita_cartaz.ogg",
	"carimbo": "res://sfx/eventos/s10_carimbo.ogg",
	"erro": "res://sfx/caixa/s11_erro_caixa.ogg",
	"rasgar": "res://sfx/loja/s12_papel_rasgando.ogg",
	"feirante": "res://sfx/loja/s13_grito_feirante.ogg",
	"plateia": "res://sfx/pontuacao/s14_plateia_uooh.ogg",
}
const MUSIC_PATH := "res://music/m01_samba_jazz_loop.ogg"
const POOL_SIZE := 6
const MUSIC_VOLUME_DB := -8.0

var _players: Array = []
var _music: AudioStreamPlayer
var _cache := {}


func _ready() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)


## Toca um efeito. `pitch` muda a altura (1.0 = normal); usado para o bipe que sobe na pontuação.
func play(id: String, pitch: float = 1.0) -> void:
	var stream := _stream(PATHS.get(id, ""))
	if stream == null:
		return
	# Procura um canal livre; se todos estiverem ocupados, corta o primeiro.
	var chosen: AudioStreamPlayer = _players[0]
	for player in _players:
		if not player.playing:
			chosen = player
			break
	chosen.stream = stream
	chosen.pitch_scale = pitch
	chosen.play()


## Liga a música de fundo em loop (uma vez só). Navegadores exigem um clique antes de tocar áudio.
func play_music() -> void:
	if _music.playing:
		return
	var stream := _stream(MUSIC_PATH)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.play()


func _stream(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path] as AudioStream
