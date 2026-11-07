extends SceneTree
## Testes de idioma e opções: traduções do CSV, tr() nos três idiomas e salvamento das opções.
## Rodar: godot --headless --path . -s res://tests/test_i18n.gd

var _falhas := 0
var _ok := 0


func _initialize() -> void:
	var loc = root.get_node("Loc")
	var settings = root.get_node("Settings")
	var csv := FileAccess.open("res://i18n/textos.csv", FileAccess.READ)
	check(csv != null, "CSV de textos existe")
	var header := csv.get_csv_line()
	check(header.size() == 3 and header[0] == "pt" and header[1] == "en" and header[2] == "es", "cabeçalho do CSV é pt,en,es")

	var linhas := 0
	var faltando := 0
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() < 3 or row[0] == "":
			continue
		linhas += 1
		if row[1] == "" or row[2] == "":
			faltando += 1
	check(linhas > 200, "CSV tem mais de 200 textos (%d)" % linhas)
	check(faltando == 0, "todo texto tem inglês e espanhol (faltam %d)" % faltando)

	loc.set_language("pt")
	check(tr("PAUSA") == "PAUSA", "português devolve o próprio texto")

	loc.set_language("en")
	check(tr("PAUSA") == "PAUSED", "inglês: PAUSA -> PAUSED")
	check(tr("VOLTAR AO MENU") == "BACK TO MENU", "inglês: VOLTAR AO MENU")
	check(tr("BOLSA\nFAMÍLIA") == "BOLSA\nFAMILY", "quebra de linha vira quebra real na chave")
	check(tr("TEXTO QUE NÃO EXISTE") == "TEXTO QUE NÃO EXISTE", "texto sem tradução cai no português")

	loc.set_language("es")
	check(tr("PAUSA") == "PAUSA", "espanhol: PAUSA continua PAUSA (igual ao português)")
	check(tr("VOLTAR AO MENU") == "VOLVER AL MENÚ", "espanhol: VOLTAR AO MENU -> VOLVER AL MENÚ")
	check(tr("Pastor da Prosperidade") == "Pastor de la Prosperidad", "espanhol: nome de esquema")

	loc.set_language("pt")

	# Opções: restaurar padrões, salvar e carregar.
	var antes := {
		"language": settings.language, "music": settings.music_volume, "sfx": settings.sfx_volume,
		"full": settings.fullscreen, "vsync": settings.vsync, "fps": settings.fps_index, "shake": settings.screen_shake,
	}
	settings.music_volume = 35
	settings.sfx_volume = 60
	settings.fullscreen = false
	settings.vsync = false
	settings.fps_index = 2
	settings.screen_shake = false
	settings.set_language("en")
	settings.save()
	settings.music_volume = 0
	settings.sfx_volume = 0
	settings.fps_index = 0
	settings._load()
	check(settings.music_volume == 35 and settings.sfx_volume == 60, "volumes salvos são carregados")
	check(not settings.fullscreen and not settings.vsync and settings.fps_index == 2 and not settings.screen_shake, "tela, VSync, FPS e tremor salvos são carregados")
	check(settings.language == "en", "idioma salvo é carregado")
	settings.reset_defaults()
	check(settings.music_volume == 80 and settings.sfx_volume == 100 and settings.fps_index == 1, "restaurar padrões volta os valores iniciais")
	check(settings.language == "en", "restaurar padrões não mexe no idioma")

	# Devolve o que estava antes (o arquivo de opções do jogo não deve ficar com valores de teste).
	settings.music_volume = antes["music"]
	settings.sfx_volume = antes["sfx"]
	settings.fullscreen = antes["full"]
	settings.vsync = antes["vsync"]
	settings.fps_index = antes["fps"]
	settings.screen_shake = antes["shake"]
	settings.language = antes["language"]
	settings.save()
	loc.set_language(antes["language"])

	print("%d verificações, %d falhas" % [_ok + _falhas, _falhas])
	quit(1 if _falhas > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		_ok += 1
	else:
		_falhas += 1
		print("FALHOU: " + msg)
