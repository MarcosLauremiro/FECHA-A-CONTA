extends SceneTree
## Coleção: desbloqueio por uso (Collection), gancho nas compras e tela (CollectionScreen).
## Rodar: godot --headless --path . -s res://tests/test_colecao.gd

var _falhas := 0
var _ok := 0


func _initialize() -> void:
	var loc = root.get_node("Loc")
	loc.set_language("pt")
	_limpa()

	# Registro: começa vazio, marca uma vez e não grava de novo.
	check(not Collection.is_unlocked(Collection.KIND_BOSS, "bolsa_familia"), "chefe começa bloqueado")
	Collection.unlock(Collection.KIND_BOSS, "bolsa_familia")
	check(Collection.is_unlocked(Collection.KIND_BOSS, "bolsa_familia"), "unlock marca o chefe")
	check(not Collection.is_unlocked(Collection.KIND_SCHEME, "bolsa_familia"), "tipos não se misturam")
	Collection.unlock(Collection.KIND_BOSS, "bolsa_familia")
	check(Collection.count(Collection.KIND_BOSS, ["bolsa_familia", "julius"]) == 1, "conta só os usados")

	# Persistência: relê o arquivo como se fosse outra sessão.
	if DisplayServer.get_name() != "headless":  # no teste (headless) o progresso não é gravado, então só relê fora dele
		Collection._used = {}
		Collection._loaded = false
		check(Collection.is_unlocked(Collection.KIND_BOSS, "bolsa_familia"), "desbloqueio sobrevive ao reiniciar")

	# Gancho da loja: comprar esquema e contato desbloqueia.
	var run := RunState.new()
	run._start_bill()
	run.state = RunState.SHOP
	run.schemes = []
	run.shop_offer = ["agiota", "", ""]
	run.wallet = 500
	var comprou: Dictionary = run.buy(0)
	check(comprou["ok"], "compra de esquema funciona no teste")
	check(Collection.is_unlocked(Collection.KIND_SCHEME, "agiota"), "comprar esquema desbloqueia")

	run.contact_offer = ["gerente"]
	check(run.buy_contact("gerente")["ok"], "compra de contato funciona no teste")
	check(Collection.is_unlocked(Collection.KIND_CONTACT, "gerente"), "comprar contato desbloqueia")

	# Tela: 4 abas, cartas conforme o catálogo, cinza antes do uso.
	var screen := CollectionScreen.new()
	root.add_child(screen)
	if screen._grid == null:  # em _initialize o _ready pode ainda não ter rodado
		screen._ready()
	check(screen._items(Collection.KIND_BOSS).size() == Balance.BOSSES.size(), "chefes: todos aparecem na coleção")
	check(screen._items(Collection.KIND_SCHEME).size() == Balance.SCHEMES.size(), "esquemas: todos aparecem")
	check(screen._items(Collection.KIND_INVESTMENT).size() == Balance.INVESTMENTS.size(), "investimentos: todos aparecem")
	check(screen._items(Collection.KIND_CONTACT).size() == Balance.CONTACTS.size(), "contatos: todos aparecem")
	screen._select(Collection.KIND_BOSS)
	check(screen._grid.get_child_count() == Balance.BOSSES.size(), "grade de chefes tem uma carta por chefe")
	var bloqueados := 0
	for card in screen._grid.get_children():
		if card.get_child(0).get_child(1).text == "???":
			bloqueados += 1
	var usados := Collection.count(Collection.KIND_BOSS, Balance.BOSSES.keys())
	check(usados >= 1 and bloqueados == Balance.BOSSES.size() - usados, "só os chefes usados aparecem com nome")
	screen._select(Collection.KIND_SCHEME)
	check(screen._count.text == "1 de %d desbloqueados" % Balance.SCHEMES.size(), "contador de esquemas: 1 usado")
	screen.queue_free()

	_limpa()
	print("test_colecao: %d ok, %d falhas" % [_ok, _falhas])
	quit(1 if _falhas > 0 else 0)


func _limpa() -> void:
	Collection._used = {}
	Collection._loaded = false
	if FileAccess.file_exists(Collection.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Collection.PATH))


func check(cond: bool, msg: String) -> void:
	if cond:
		_ok += 1
	else:
		_falhas += 1
		print("FALHOU: " + msg)
