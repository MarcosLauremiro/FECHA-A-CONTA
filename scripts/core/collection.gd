class_name Collection
extends RefCounted
## Coleção: chefes, esquemas, investimentos e contatos que o jogador já usou pelo menos uma vez.
## É progresso de conta, não da partida: sobrevive a novos jogos (user://colecao.json).
## Chave de cada item: "<tipo>:<id>", por exemplo "chefe:bolsa_familia" ou "esquema:agiota".
## Enquanto não é usado, o item aparece cinza na tela da coleção.

const PATH := "user://colecao.json"

const KIND_BOSS := "chefe"
const KIND_SCHEME := "esquema"
const KIND_INVESTMENT := "investimento"
const KIND_CONTACT := "contato"

static var _used: Dictionary = {}
static var _loaded := false


static func key(kind: String, id: String) -> String:
	return "%s:%s" % [kind, id]


## Marca o item como usado. Só grava no disco quando é novidade.
static func unlock(kind: String, id: String) -> void:
	_ensure_loaded()
	var k := key(kind, id)
	if _used.has(k):
		return
	_used[k] = true
	_save()


static func is_unlocked(kind: String, id: String) -> bool:
	_ensure_loaded()
	return _used.has(key(kind, id))


## Quantos itens de um tipo já foram usados, dentre os `ids` dados.
static func count(kind: String, ids: Array) -> int:
	var total := 0
	for id in ids:
		if is_unlocked(kind, str(id)):
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
	for k in data.get("usados", []):
		_used[str(k)] = true


static func _save() -> void:
	# Testes e simulações rodam sem tela: não gravam o progresso de verdade.
	if DisplayServer.get_name() == "headless":
		return
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"usados": _used.keys()}))
	file.close()
