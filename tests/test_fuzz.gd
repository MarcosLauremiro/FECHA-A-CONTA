extends SceneTree
## Simulador: joga muitas partidas inteiras com escolhas aleatórias e confere as regras a cada passo.
##   godot --headless -s res://tests/test_fuzz.gd
## Não mede balanceamento. Serve para achar travamentos e estados que não deveriam existir.
## O bot guloso (mesmo código que a simulação de balanceamento usa) também dá um número de referência.

const RUNS := 300
const MAX_STEPS := 3000
const EXPECTED_REFUSALS := ["no_selection", "round_over", "run_not_playing", "no_swaps", "no_money", "not_shop", "slots_full", "bad_index"]

var failures := 0
var wins := 0
var losses := 0
var stuck := 0
var bills_paid_total := 0
var max_saldo_seen := 0
var lost_at := {}  # conta em que a partida acabou -> quantas vezes
var _greedy := false  # bot guloso: sempre joga a melhor combinação da mão


func _initialize() -> void:
	for greedy in [false, true]:
		_greedy = greedy
		wins = 0
		losses = 0
		stuck = 0
		bills_paid_total = 0
		max_saldo_seen = 0
		lost_at = {}
		for seed_i in range(RUNS):
			_play_run(seed_i + 1)
		var bot := "guloso" if greedy else "aleatório"
		print("\n[%s] %d partidas: %d vitórias, %d derrotas, %d travadas" % [bot, RUNS, wins, losses, stuck])
		print("[%s] contas pagas em média: %.1f   maior saldo visto: %d" % [bot, float(bills_paid_total) / RUNS, max_saldo_seen])
		print("[%s] derrotas por conta: %s" % [bot, str(lost_at)])
	print("%d falhas" % failures)
	quit(1 if failures > 0 else 0)


func _fail(msg: String) -> void:
	failures += 1
	if failures <= 20:
		printerr("FALHOU: ", msg)


func _play_run(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var run := RunState.new(rng)
	var bills := 0
	var steps := 0
	while steps < MAX_STEPS and run.state != RunState.WON and run.state != RunState.LOST:
		steps += 1
		match run.state:
			RunState.PLAYING:
				_play_bill_step(run, rng)
			RunState.BILL_PAID:
				bills += 1
				_check_bill_pieces(run, "conta paga")
				if not run.next_bill():
					_fail("next_bill recusado em BILL_PAID")
			RunState.SHOP:
				_shop_step(run, rng)
		_check_run(run, seed_value)

	if run.state == RunState.WON:
		bills += 1
		wins += 1
	elif run.state == RunState.LOST:
		losses += 1
		lost_at[run.bill_title()] = int(lost_at.get(run.bill_title(), 0)) + 1
	else:
		stuck += 1
		_fail("partida %d travada em %s após %d passos" % [seed_value, run.state, steps])
	bills_paid_total += bills
	max_saldo_seen = maxi(max_saldo_seen, run.max_saldo)


## Uma jogada: ora seleciona cartas, ora troca, ora paga.
func _play_bill_step(run: RunState, rng: RandomNumberGenerator) -> void:
	var bill := run.bill
	if bill.hand.is_empty():
		_fail("mão vazia numa conta em andamento (%s)" % run.bill_title())
		return
	if _greedy:
		_greedy_step(run)
		return
	if bill.selected.is_empty() or rng.randf() < 0.2:
		var picks := rng.randi_range(1, Balance.MAX_PLAYED)
		for i in range(picks):
			var card: Note = bill.hand[rng.randi_range(0, bill.hand.size() - 1)]
			bill.toggle_select(card)
	if rng.randf() < 0.1:
		var swap := run.swap()
		_check_refusal(swap, "swap")
	else:
		var pay := run.pay()
		_check_refusal(pay, "pay")


## Bot guloso: joga a melhor combinação entre as notas que pontuam neste mês (o chefe pode tirar algumas).
## Mão fraca (só trocado, dobradinha ou nada) e com trocas sobrando: troca as cartas fora da combinação.
func _greedy_step(run: RunState) -> void:
	var bill := run.bill
	for n in bill.selected.duplicate():
		bill.toggle_select(n)
	var scoring: Array = []
	for n in bill.hand:
		if Boss.note_scores(bill.boss, n):
			scoring.append(n)
	var best := HandEvaluator.evaluate(scoring, bill.unlocked())
	var weak: bool = best["kind"] in ["trocado", "dobradinha", "none"]
	if weak and bill.swaps_left > 0:
		for n in bill.hand:
			if not best["cards"].has(n):
				bill.toggle_select(n)
		if not bill.selected.is_empty():
			var swapped: Dictionary = run.swap()
			_check_refusal(swapped, "swap")
			if swapped["ok"]:
				return
			# Troca recusada (sem dinheiro para o custo do chefe): o bot segue para pagar.
			for n in bill.selected.duplicate():
				bill.toggle_select(n)
	if best["cards"].is_empty():
		bill.toggle_select(bill.hand[0])
	else:
		for n in best["cards"]:
			bill.toggle_select(n)
	_check_refusal(run.pay(), "pay")


func _check_refusal(result: Dictionary, what: String) -> void:
	if not result["ok"] and not EXPECTED_REFUSALS.has(result["reason"]):
		_fail("%s recusado com motivo inesperado: %s" % [what, result["reason"]])


func _shop_step(run: RunState, rng: RandomNumberGenerator) -> void:
	var actions := rng.randi_range(0, 4)
	for i in range(actions):
		var roll := rng.randf()
		if roll < 0.45 and not run.shop_offer.is_empty():
			_check_refusal(run.buy(rng.randi_range(0, run.shop_offer.size() - 1)), "buy")
		elif roll < 0.6 and not run.schemes.is_empty():
			_check_refusal(run.sell(rng.randi_range(0, run.schemes.size() - 1)), "sell")
		elif roll < 0.7:
			_check_refusal(run.haggle(), "haggle")
		elif not run.contact_offer.is_empty():
			_check_refusal(run.buy_contact(run.contact_offer[rng.randi_range(0, run.contact_offer.size() - 1)]), "buy_contact")
		if run.state == RunState.LOST:
			return  # o cheque especial zerou no Camelô: a partida acabou
	if not run.leave_shop():
		_fail("leave_shop recusado no Camelô")


## Cartas da conta: 40 do baralho (mais 1 se o Pix Errado copiou uma), sem repetir nenhuma.
func _check_bill_pieces(run: RunState, when: String) -> void:
	var seen := {}
	var total := 0
	for pile in [run.bill.hand, run.bill.deck.draw_pile, run.bill.deck.discard_pile]:
		for note in pile:
			total += 1
			if seen.has(note):
				_fail("nota repetida (%s) em %s" % [when, run.bill_title()])
			seen[note] = true
	if total != 40 and total != 41:
		_fail("%d cartas na conta (%s), esperado 40 ou 41" % [total, when])


func _check_run(run: RunState, seed_value: int) -> void:
	var tag := "partida %d, %s" % [seed_value, run.state]
	if run.schemes.size() > Balance.MAX_SCHEMES:
		_fail("%d esquemas, máximo %d (%s)" % [run.schemes.size(), Balance.MAX_SCHEMES, tag])
	var seen_schemes := {}
	for id in run.schemes:
		if seen_schemes.has(id):
			_fail("esquema repetido: %s (%s)" % [id, tag])
		seen_schemes[id] = true
	for kind in run.levels:
		if int(run.levels[kind]) < 0:
			_fail("nível negativo em %s (%s)" % [kind, tag])
	if run.state == RunState.PLAYING:
		var bill := run.bill
		if bill.hand.size() > Boss.hand_size(bill.boss):
			_fail("mão com %d cartas (%s)" % [bill.hand.size(), tag])
		if bill.selected.size() > Balance.MAX_PLAYED:
			_fail("%d notas selecionadas (%s)" % [bill.selected.size(), tag])
		for n in bill.selected:
			if not bill.hand.has(n):
				_fail("nota selecionada fora da mão (%s)" % tag)
		if bill.days_left < 0 or bill.swaps_left < 0:
			_fail("dias ou trocas negativos (%s)" % tag)
		_check_bill_pieces(run, "em jogo")
	if run.state == RunState.WON and run.bill.saldo < run.bill.goal:
		_fail("venceu com saldo abaixo da meta (%s)" % tag)
	if run.state == RunState.LOST and run.end_reason != "cheque" and run.bill.days_left != 0:
		_fail("perdeu com dias sobrando (%s)" % tag)
