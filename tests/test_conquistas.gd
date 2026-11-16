extends SceneTree
## Conquistas: registro persistente (Achievements), gancho numa compra e a tela (AchievementsScreen).
## Rodar: godot --headless --path . -s res://tests/test_conquistas.gd

var _falhas := 0
var _ok := 0


func _initialize() -> void:
	root.get_node("Loc").set_language("pt")
	_limpa()

	check(not Achievements.is_unlocked("primeira_conta"), "conquista começa bloqueada")
	Achievements.unlock("primeira_conta")
	Achievements.unlock("primeira_conta")
	check(Achievements.is_unlocked("primeira_conta"), "unlock marca a conquista")
	check(Achievements.count_unlocked() == 1, "conta só as conquistadas")
	check(Achievements.has_pending() and Achievements.pop_pending() == "primeira_conta", "conquista nova entra na fila do aviso")
	check(not Achievements.has_pending(), "fila esvazia depois de mostrar")
	Achievements.unlock("primeira_conta")
	check(not Achievements.has_pending(), "conquista repetida não avisa de novo")

	# Persistência: relê o arquivo como se fosse outra sessão.
	Achievements._done = {}
	Achievements._loaded = false
	if DisplayServer.get_name() != "headless":  # no teste (headless) o progresso não é gravado
		check(Achievements.is_unlocked("primeira_conta"), "conquista sobrevive ao reiniciar")

	# Gancho: comprar contato desbloqueia "na_manga".
	var run := RunState.new()
	run._start_bill()
	run.state = RunState.SHOP
	run.wallet = 500
	run.contact_offer = ["gerente"]
	check(run.buy_contact("gerente")["ok"], "compra de contato funciona no teste")
	check(Achievements.is_unlocked("na_manga"), "comprar contato conquista 'Contato na manga'")

	# Tela: uma linha por conquista do catálogo.
	var screen := AchievementsScreen.new()
	root.add_child(screen)
	if screen.get_child_count() == 0:
		screen._ready()
	var linhas := _count_rows(screen)
	check(linhas == Achievements.CATALOG.size(), "a tela mostra uma linha por conquista (%d)" % linhas)
	screen.queue_free()

	_limpa()
	print("test_conquistas: %d ok, %d falhas" % [_ok, _falhas])
	quit(1 if _falhas > 0 else 0)


func _count_rows(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is PanelContainer and child.get_child_count() > 0 and child.get_child(0) is HBoxContainer:
			total += 1
		total += _count_rows(child)
	return total


func _limpa() -> void:
	Achievements._done = {}
	Achievements._loaded = false
	if FileAccess.file_exists(Achievements.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Achievements.PATH))


func check(cond: bool, msg: String) -> void:
	if cond:
		_ok += 1
	else:
		_falhas += 1
		print("FALHOU: " + msg)
