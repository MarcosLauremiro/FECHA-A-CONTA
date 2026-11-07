extends Node
## Opções do jogo: idioma, volumes, tela cheia, VSync, limite de quadros e tremor da tela.
## Guardadas em user://config.cfg. Cada mudança vale na hora (ver apply()).
## Os barramentos de áudio "Musica" e "Efeitos" são criados aqui, antes de qualquer som tocar.

const PATH := "user://config.cfg"
const BUS_MUSIC := "Musica"
const BUS_SFX := "Efeitos"
const FPS_CHOICES := [30, 60, 120, 0]   # 0 = sem limite (índice nas opções)

var language := "pt"
var music_volume := 80      # 0 a 100
var sfx_volume := 100       # 0 a 100
var fullscreen := true
var vsync := true
var fps_index := 1          # índice em FPS_CHOICES (60 por padrão)
var screen_shake := true


func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_load()
	Loc.set_language(language)
	apply()


## Aplica tudo ao motor (áudio, janela, VSync e limite de quadros).
func apply() -> void:
	_set_bus_percent(BUS_MUSIC, music_volume)
	_set_bus_percent(BUS_SFX, sfx_volume)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_CHOICES[fps_index]


func set_language(code: String) -> void:
	language = code
	Loc.set_language(code)
	save()


func reset_defaults() -> void:
	music_volume = 80
	sfx_volume = 100
	fullscreen = true
	vsync = true
	fps_index = 1
	screen_shake = true
	apply()
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("opcoes", "idioma", language)
	cfg.set_value("opcoes", "musica", music_volume)
	cfg.set_value("opcoes", "efeitos", sfx_volume)
	cfg.set_value("opcoes", "tela_cheia", fullscreen)
	cfg.set_value("opcoes", "vsync", vsync)
	cfg.set_value("opcoes", "fps", fps_index)
	cfg.set_value("opcoes", "tremor", screen_shake)
	cfg.save(PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	language = str(cfg.get_value("opcoes", "idioma", language))
	music_volume = clampi(int(cfg.get_value("opcoes", "musica", music_volume)), 0, 100)
	sfx_volume = clampi(int(cfg.get_value("opcoes", "efeitos", sfx_volume)), 0, 100)
	fullscreen = bool(cfg.get_value("opcoes", "tela_cheia", fullscreen))
	vsync = bool(cfg.get_value("opcoes", "vsync", vsync))
	fps_index = clampi(int(cfg.get_value("opcoes", "fps", fps_index)), 0, FPS_CHOICES.size() - 1)
	screen_shake = bool(cfg.get_value("opcoes", "tremor", screen_shake))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _set_bus_percent(bus_name: String, percent: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, percent <= 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(percent, 1) / 100.0))
