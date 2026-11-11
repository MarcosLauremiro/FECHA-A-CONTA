class_name SaveGame
extends RefCounted
## Salvar e carregar a partida (um único slot). Arquivo JSON na pasta de dados do jogo (user://).
## Se o arquivo estiver corrompido ou faltar algo, load() devolve null e o jogo segue sem carregar.

const PATH := "user://partida.json"
const VERSION := 4  # 3: cheque especial com limite e contatos (saves antigos são descartados)
# 2: ano de 12 meses e chefes novos.


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## Grava a partida. Devolve false se não conseguir escrever.
static func write(run: RunState) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	var data := run.to_dict()
	data["version"] = VERSION
	file.store_string(JSON.stringify(data))
	file.close()
	return true


## Carrega a partida salva, ou null se não há save válido.
static func read() -> RunState:
	if not exists():
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY or not data.has("bill") or int(data.get("version", 0)) != VERSION:
		return null
	return RunState.from_dict(data)


## Apaga o save (partida terminada ou save inválido).
static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
