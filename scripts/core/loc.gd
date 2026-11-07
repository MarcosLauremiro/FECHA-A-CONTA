extends Node
## Idiomas do jogo (português, inglês e espanhol).
## Os textos ficam em i18n/textos.csv: colunas pt, en, es. A chave é o texto em português.
## Na interface, cada texto passa por tr("texto em português"): sem tradução, aparece o português.
## Os idiomas são registrados no TranslationServer ao iniciar; trocar o idioma só vale depois
## que as telas são refeitas (o jogo recarrega a cena ao fechar as opções).

const CSV_PATH := "res://i18n/textos.csv"
const LANGUAGES := ["pt", "en", "es"]
const LANGUAGE_NAMES := {"pt": "Português", "en": "English", "es": "Español"}


func _init() -> void:
	_register()


func _register() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("Arquivo de textos não encontrado: %s" % CSV_PATH)
		return
	var header := file.get_csv_line()
	var by_code := {}
	for i in range(header.size()):
		var code := header[i].strip_edges()
		if LANGUAGES.has(code):
			var translation := Translation.new()
			translation.locale = code
			by_code[i] = translation
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		var source := row[0].replace("\\n", "\n")
		for i in by_code:
			if i < row.size() and row[i] != "":
				by_code[i].add_message(source, row[i].replace("\\n", "\n"))
	for i in by_code:
		TranslationServer.add_translation(by_code[i])


## Troca o idioma da interface (vale para os tr() feitos a partir de agora).
func set_language(code: String) -> void:
	if not LANGUAGES.has(code):
		code = "pt"
	TranslationServer.set_locale(code)
