extends SceneTree
## Bateria de partidas inteiras: quanto cada esquema muda a taxa de vitória.
##
## Dois tipos de jogador:
##   - oráculo: sempre joga a melhor combinação entre as notas que pontuam (sem erro) e compra
##     no Camelô ao acaso. É o mesmo bot de tests/test_fuzz.gd, então dá para comparar os números.
##   - humano: erra de vez em quando (joga um conjunto aleatório em vez da melhor combinação)
##     e compra no Camelô só o que pode pagar com folga.
##
## Cada esquema e cada investimento é testado do começo da partida, sozinho, contra a partida sem nada.
## Rodar: godot --headless --path . -s res://tests/sim_esquemas.gd
## Ajuste RUNS para mais ou menos partidas (mais = mais estável, porém mais lento).

const RUNS := 400
const MAX_STEPS := 3000
const HUMAN_ERROR := 0.1      # chance de o jogador humano errar a jogada
const HUMAN_BUY := 0.6         # chance de comprar uma oferta que pode pagar

var _rng_seed_base := 1000


func _initialize() -> void:
	print("")
	print("== Taxa de vitória por esquema (%d partidas cada) ==" % RUNS)
	print("%-24s %10s %10s %12s" % ["cenário", "oráculo", "humano", "contas/partida"])
	var base_o := _batch([], false)
	var base_h := _batch([], true)
	_row("sem esquemas", base_o, base_h)
	for id in Balance.SCHEME_ORDER:
		var o := _batch([id], false)
		var h := _batch([id], true)
		_row(str(Balance.SCHEMES[id]["name"]), o, h)
	print("-- investimentos (nível 1 desde o começo) --")
	for id in Balance.INVESTMENT_ORDER:
		var o := _batch([], false, [id])
		var h := _batch([], true, [id])
		_row(str(Balance.INVESTMENTS[id]["name"]), o, h)
	var all_five: Array = Balance.SCHEME_ORDER.slice(0, Balance.MAX_SCHEMES)
	_row("5 esquemas juntos", _batch(all_five, false), _batch(all_five, true))
	print("")
	print("Cada linha usa as mesmas sementes: a diferença para 'sem esquemas' vem do esquema.")
	quit(0)


func _row(name: String, o: Dictionary, h: Dictionary) -> void:
	print("%-24s %9.1f%% %9.1f%% %12.1f" % [name, o["win_pct"], h["win_pct"], o["bills"]])


## Joga RUNS partidas com os esquemas dados e devolve taxa de vitória e contas pagas em média.
func _batch(start_schemes: Array, humano: bool, start_invests: Array = []) -> Dictionary:
	var wins := 0
	var bills_total := 0
	for i in range(RUNS):
		var result := _play(_rng_seed_base + i, start_schemes, humano, start_invests)
		if result["won"]:
			wins += 1
		bills_total += result["bills"]
	return {"win_pct": 100.0 * wins / RUNS, "bills": float(bills_total) / RUNS}


func _play(seed_value: int, start_schemes: Array, humano: bool, start_invests: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var run := RunState.new(rng)
	if not start_schemes.is_empty() or not start_invests.is_empty():
		run.schemes = start_schemes.duplicate()
		for id in start_invests:
			run.levels[Investments.transaction_of(id)] = 1
		run._start_bill()  # refaz a primeira conta com os esquemas e investimentos ativos
	var bills := 0
	var steps := 0
	while steps < MAX_STEPS and run.state != RunState.WON and run.state != RunState.LOST:
		steps += 1
		match run.state:
			RunState.PLAYING:
				if humano:
					_play_humano(run, rng)
				else:
					_play_oraculo(run)
			RunState.BILL_PAID:
				bills += 1
				run.next_bill()
			RunState.SHOP:
				_shop(run, rng, humano)
	if run.state == RunState.WON:
		bills += 1
	return {"won": run.state == RunState.WON, "bills": bills}


## Notas que pontuam neste chefe (o Banco fora do ar tira o Pix).
func _scoring(bill: BillRound) -> Array:
	var out: Array = []
	for n in bill.hand:
		if Boss.note_scores(bill.boss, n):
			out.append(n)
	return out


func _clear_selection(bill: BillRound) -> void:
	for n in bill.selected.duplicate():
		bill.toggle_select(n)


## Oráculo: melhor combinação. Mão fraca com trocas sobrando: troca o que não entra na combinação.
func _play_oraculo(run: RunState) -> void:
	var bill := run.bill
	_clear_selection(bill)
	var scoring := _scoring(bill)
	var best := HandEvaluator.evaluate(scoring, bill.unlocked())
	var weak: bool = best["kind"] in ["trocado", "dobradinha", "none"]
	if weak and bill.swaps_left > 0:
		for n in bill.hand:
			if not best["cards"].has(n):
				bill.toggle_select(n)
		if not bill.selected.is_empty():
			var swapped: Dictionary = run.swap()
			if swapped["ok"]:
				return
			_clear_selection(bill)
	if best["cards"].is_empty():
		bill.toggle_select(bill.hand[0])
	else:
		for n in best["cards"]:
			bill.toggle_select(n)
	run.pay()


## Humano: às vezes erra (joga um conjunto aleatório de notas que pontuam), senão joga a melhor.
func _play_humano(run: RunState, rng: RandomNumberGenerator) -> void:
	var bill := run.bill
	_clear_selection(bill)
	var scoring := _scoring(bill)
	if not scoring.is_empty() and rng.randf() < HUMAN_ERROR:
		var pool := scoring.duplicate()
		var k := rng.randi_range(1, mini(Balance.MAX_PLAYED, pool.size()))
		for _i in range(k):
			var pick: Note = pool[rng.randi_range(0, pool.size() - 1)]
			pool.erase(pick)
			bill.toggle_select(pick)
		run.pay()
		return
	_play_oraculo(run)


## Camelô: compra o que pode pagar com folga de R$ 2. O oráculo compra sempre; o humano só às vezes.
func _shop(run: RunState, rng: RandomNumberGenerator, humano: bool) -> void:
	var chance := HUMAN_BUY if humano else 1.0
	for idx in range(run.shop_offer.size()):
		var id = run.shop_offer[idx]
		if str(id) == "":
			continue
		if rng.randf() < chance and run.wallet - run.price_of(str(id)) >= 2:
			run.buy(idx)
	run.leave_shop()
