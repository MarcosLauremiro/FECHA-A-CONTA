extends "res://tests/sim_esquemas.gd"
## Bateria de balanceamento da partida de 6 meses: perfis de jogador, cheque especial e contatos.
##
## Perfis:
##   - novato:  o "humano" da sim_esquemas (erra 10% das jogadas, compra 60% do que pode pagar).
##   - oráculo: melhor combinação da mão, compra o que pode pagar com folga.
##   - esperto: testa todos os conjuntos de 1 a 5 notas na prévia (conta esquemas, chefe e imposto)
##              e joga o que mais rende; troca quando o ritmo não bate a meta; compra tudo que pode.
## Opções do esperto: usar o cheque especial, comprar contatos, pechinchar várias vezes com cheque sem limite.
## Rodar: godot --headless --path . -s res://tests/sim_balance.gd

const N := 200

var _policy: Dictionary = {}
var _lost_at: Dictionary = {}
# Varredura da curva (argumento "curva"): troca D0 e R sem mexer no balance.gd. R = 0 usa a curva do jogo.
var _d0 := 0.0
var _r := 0.0


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("curva"):
		print("%-12s %8s %8s %8s %8s" % ["D0/R", "novato", "oráculo", "esperto", "contas"])
		for pair in [[180, 1.22], [180, 1.24], [180, 1.26], [210, 1.22]]:
			_d0 = pair[0]
			_r = pair[1]
			var a := _measure({"play": "novato"})
			var b := _measure({"play": "oraculo"})
			var c := _measure({"play": "esperto"})
			print("%-12s %7.1f%% %7.1f%% %7.1f%% %8.1f" % ["%d/%.2f" % [_d0, _r], a["win"], b["win"], c["win"], c["bills"]])
		quit(0)
		return
	print("")
	print("== Balanceamento, partida de %d meses (%d partidas por linha) ==" % [Balance.RUN_MONTHS, N])
	print("%-44s %8s %8s  %s" % ["cenário", "vitória", "contas", "onde mais perde"])
	if OS.get_cmdline_user_args().has("base"):
		_line("novato", {"play": "novato"})
		_line("oráculo", {"play": "oraculo"})
		_line("esperto", {"play": "esperto"})
		quit(0)
		return
	_line("novato", {"play": "novato"})
	_line("oráculo", {"play": "oraculo"})
	_line("esperto", {"play": "esperto"})
	_line("esperto + cheque", {"play": "esperto", "cheque": true})
	_line("esperto + cheque + contatos", {"play": "esperto", "cheque": true, "contatos": true})
	_line("esperto + cheque + contatos + pechincha x8", {"play": "esperto", "cheque": true, "contatos": true, "haggles": 8})
	print("-- contato desde o começo (esperto + cheque) --")
	_line("Gerente do Banco", {"play": "esperto", "cheque": true, "start_contacts": ["gerente"]})
	_line("Cheque Sem Fundo", {"play": "esperto", "cheque": true, "start_contacts": ["sem_fundo"]})
	_line("Cheque Sem Fundo + pechincha x8", {"play": "esperto", "cheque": true, "start_contacts": ["sem_fundo"], "haggles": 8})
	if OS.get_cmdline_user_args().has("chefes"):
		# Cada chefe forçado no último mês da faixa dele (leve: mês 2, médio: mês 4, pesado: mês 6).
		print("-- esperto: cada chefe forçado num mês da faixa dele --")
		var month_of := {"leve": 1, "medio": 3, "pesado": 5}
		for tier in Balance.BOSS_TIERS:
			for id in Balance.BOSS_TIERS[tier]:
				_line("%s (%s, mês %d)" % [Balance.BOSSES[id]["name"], tier, month_of[tier] + 1], {"play": "esperto", "force_boss": [month_of[tier], id]})
	if OS.get_cmdline_user_args().has("itens"):
		print("-- esperto: cada esquema desde o começo --")
		for id in Balance.SCHEME_ORDER:
			_line(str(Balance.SCHEMES[id]["name"]), {"play": "esperto", "schemes": [id]})
		print("-- esperto: cada investimento no nível 1 desde o começo --")
		for id in Balance.INVESTMENT_ORDER:
			_line(str(Balance.INVESTMENTS[id]["name"]), {"play": "esperto", "invests": [id]})
	quit(0)


func _measure(policy: Dictionary) -> Dictionary:
	_policy = policy
	_lost_at = {}
	var wins := 0
	var bills := 0
	for i in range(N):
		var r := _run_one(_rng_seed_base + i)
		if r["won"]:
			wins += 1
		bills += r["bills"]
	return {"win": 100.0 * wins / N, "bills": float(bills) / N}


func _line(name: String, policy: Dictionary) -> void:
	var m := _measure(policy)
	# As três contas em que mais se perde.
	var keys := _lost_at.keys()
	keys.sort_custom(func(a, b): return _lost_at[a] > _lost_at[b])
	var top: Array = []
	for k in keys.slice(0, 3):
		top.append("%s %d" % [k, _lost_at[k]])
	print("%-44s %7.1f%% %8.1f  %s" % [name, m["win"], m["bills"], ", ".join(top)])


func _run_one(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var run := RunState.new(rng)
	run.schemes = Array(_policy.get("schemes", [])).duplicate()
	for id in _policy.get("invests", []):
		run.levels[Investments.transaction_of(id)] = 1
	run.contacts_owned = Array(_policy.get("start_contacts", [])).duplicate()
	run._start_bill()
	var bills := 0
	var steps := 0
	var play: String = _policy["play"]
	var last_n := -1
	while steps < MAX_STEPS and run.state != RunState.WON and run.state != RunState.LOST:
		steps += 1
		match run.state:
			RunState.PLAYING:
				var n: int = run.month_index * 3 + run.bill_index
				var forced: Array = _policy.get("force_boss", [])
				if not forced.is_empty() and run.month_index == int(forced[0]) and run.bill_index == 0:
					run.month_boss = forced[1]
				if _r > 0.0 and n != last_n:
					last_n = n
					run.bill.goal = roundi(float(run.bill.goal) / Balance.goal_of(run.month_index, run.bill_key()) * _d0 * pow(_r, n))
				if play == "novato":
					_play_humano(run, rng)
				elif play == "oraculo":
					_play_oraculo(run)
				else:
					_play_esperto(run)
			RunState.BILL_PAID:
				bills += 1
				run.next_bill()
			RunState.SHOP:
				if play == "esperto":
					_shop_esperto(run)
				else:
					_shop(run, rng, play == "novato")
	if run.state == RunState.WON:
		bills += 1
	else:
		var where := "%s/%s" % [Balance.MONTHS[run.month_index]["name"].substr(0, 3), run.bill_key().substr(0, 3)]
		if run.end_reason == "cheque":
			where = "cheque"
		_lost_at[where] = int(_lost_at.get(where, 0)) + 1
	return {"won": run.state == RunState.WON, "bills": bills}


## Melhor conjunto de 1 a 5 notas pela prévia (já com esquemas, chefe e imposto).
func _best_subset(bill: BillRound) -> Dictionary:
	var best_cards: Array = []
	var best_total := -1
	var n := bill.hand.size()
	for mask in range(1, 1 << n):
		var cards: Array = []
		for i in range(n):
			if mask & (1 << i):
				cards.append(bill.hand[i])
		if cards.size() > Balance.MAX_PLAYED:
			continue
		var p := bill.preview(cards)
		var total := 0 if p.is_empty() else int(p["total"]) - int(p["tax"])
		if total > best_total:
			best_total = total
			best_cards = cards
	return {"cards": best_cards, "total": best_total}


func _play_esperto(run: RunState) -> void:
	var bill := run.bill
	_clear_selection(bill)
	var best := _best_subset(bill)
	# Troca quando o ritmo desta mão não bate a meta nos dias que restam.
	var short: bool = bill.saldo + int(best["total"]) * bill.days_left < bill.goal
	var can_swap := bill.swaps_left > 0 and not Boss.swap_costs_day(bill.boss) and run.wallet >= bill.swap_cost()
	if short and can_swap:
		var keep: Array = HandEvaluator.evaluate(_scoring(bill), bill.unlocked())["cards"]
		for c in bill.hand:
			if not keep.has(c) and bill.selected.size() < Balance.MAX_PLAYED:
				bill.toggle_select(c)
		if not bill.selected.is_empty() and run.swap()["ok"]:
			return
		_clear_selection(bill)
	for c in best["cards"]:
		bill.toggle_select(c)
	run.pay()


## Pode pagar `price`? Com a opção cheque, usa o limite sem nunca gastar o último R$.
func _afford(run: RunState, price: int) -> bool:
	if run.wallet >= price:
		return true
	if not _policy.get("cheque", false):
		return false
	if run.overdraft_unlimited():
		return true
	return run.overdraft_draw(price) < run.overdraft_left


func _shop_esperto(run: RunState) -> void:
	if _policy.get("contatos", false):
		for id in run.contact_offer.duplicate():
			if _afford(run, run.price_of(id)):
				run.buy_contact(id)
	var rounds := 1
	if run.overdraft_unlimited():
		rounds += int(_policy.get("haggles", 0))
	for r in range(rounds):
		for idx in range(run.shop_offer.size()):
			var id := str(run.shop_offer[idx])
			if id == "":
				continue
			if not Investments.is_investment(id) and run.schemes.size() >= Balance.MAX_SCHEMES:
				continue
			if _afford(run, run.price_of(id)):
				run.buy(idx)
		if r < rounds - 1:
			if not _afford(run, Balance.HAGGLE_COST):
				break
			run.haggle()
	run.leave_shop()
