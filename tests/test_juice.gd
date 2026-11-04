extends SceneTree
## Teste de fumaça da sensação: aperta PAGAR, espera a animação terminar e confere que a tela destrava.
##   godot --headless -s res://tests/test_juice.gd

var _frames := 0
var _scene: Node
var _paid := false
var _checked_busy := false


func _initialize() -> void:
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_scene._on_title_pressed()
		return false
	if _frames == 3:
		var bill: BillRound = _scene.run.bill
		bill.toggle_select(bill.hand[0])
		_scene._on_pay_pressed()  # corotina: roda até o primeiro await
		return false

	if not _paid and _scene._busy:
		_paid = true
		# Enquanto a animação roda, uma nova entrada (PAGAR de novo) não pode mexer no jogo.
		var before: int = _scene.run.bill.days_left
		_scene._on_pay_pressed()
		_checked_busy = _scene.run.bill.days_left == before
		return false

	if _paid and not _scene._busy:
		var failures := 0
		if not _checked_busy:
			failures += 1
			printerr("FALHOU: PAGAR durante a animação mudou o jogo")
		if _scene.run.bill.days_left == Balance.DAYS_PER_BILL:
			failures += 1
			printerr("FALHOU: a conta não gastou dia algum")
		print("\n%d falhas na sensação" % failures)
		quit(1 if failures > 0 else 0)
		return true

	if _frames > 1200:
		printerr("FALHOU: animação não terminou")
		quit(1)
		return true
	return false
