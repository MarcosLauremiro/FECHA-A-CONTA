class_name Achievements
extends RefCounted
## Conquistas da conta: marcadas uma vez e guardadas em user://conquistas.json (valem para todas as partidas).
## Cada conquista tem nome e texto (a condição) no catálogo CATALOG. Enquanto não é conquistada, aparece cinza.

const PATH := "user://conquistas.json"

## id, nome (chave de tradução) e texto: a condição para conquistar.
const CATALOG: Array = [
	{"id": "primeira_conta", "name": "Primeira conta", "text": "Pague a primeira conta da partida."},
	{"id": "chefe_vencido", "name": "Chefe derrotado", "text": "Pague uma conta com chefe."},
	{"id": "escadinha", "name": "Escadinha", "text": "Pontue uma escadinha."},
	{"id": "investidor", "name": "Investidor", "text": "Compre um investimento no Camelô."},
	{"id": "na_manga", "name": "Contato na manga", "text": "Compre um contato na Banca."},
	{"id": "golpista", "name": "Golpista", "text": "Compre um esquema no Camelô."},
	{"id": "seis_meses", "name": "Seis meses", "text": "Vença a partida de 6 meses."},
	{"id": "alem_dos_seis", "name": "Além dos seis meses", "text": "Continue a partida no modo infinito."},
	{"id": "no_vermelho", "name": "No vermelho", "text": "Perca a partida por estourar o cheque especial."},
]

static var _done: Dictionary = {}
static var _loaded := false
static var _pending: Array = []   # conquistas feitas e ainda não mostradas no aviso da partida


## Marca a conquista como feita. Só grava no disco e entra na fila do aviso quando é novidade.
static func unlock(id: String) -> void:
	_ensure_loaded()
	if _done.has(id):
		return
	_done[id] = true
	_pending.append(id)
	_save()


static func has_pending() -> bool:
	return not _pending.is_empty()


## Próxima conquista nova para mostrar no aviso ("" se não há nenhuma).
static func pop_pending() -> String:
	if _pending.is_empty():
		return ""
	return String(_pending.pop_front())


static func name_of(id: String) -> String:
	for item in CATALOG:
		if item["id"] == id:
			return item["name"]
	return id


static func is_unlocked(id: String) -> bool:
	_ensure_loaded()
	return _done.has(id)


static func count_unlocked() -> int:
	_ensure_loaded()
	var total := 0
	for item in CATALOG:
		if _done.has(item["id"]):
			total += 1
	return total


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	for k in data.get("feitas", []):
		_done[str(k)] = true


static func _save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"feitas": _done.keys()}))
	file.close()
