extends SceneTree
## Testes headless do núcleo de regras. Rodar a partir da pasta do projeto:
##   godot --headless -s res://tests/test_core.gd
## Sai com código 0 se tudo passar, 1 se algo falhar.

var failures := 0
var checks := 0


func _init() -> void:
	_test_deck()
	_test_transactions()
	_test_priority()
	_test_scoring()
	_test_bill_round()
	_test_bosses()
	_test_run_state()
	_test_assets()
	_test_schemes()

	print("\n%d verificações, %d falhas" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FALHOU: ", msg)


func n(value: int, suit: int = Note.Suit.DINHEIRO) -> Note:
	return Note.new(value, suit)


func _test_deck() -> void:
	var deck := Deck.new(RandomNumberGenerator.new())
	check(deck.total_cards() == 32, "baralho tem 32 notas")

	var seen := {}
	for c in deck.draw_pile:
		seen["%d-%d" % [c.value, c.suit]] = true
	check(seen.size() == 32, "todas as 32 combinações valor×forma são únicas")

	var drawn := deck.draw(8)
	check(drawn.size() == 8, "compra 8 notas")
	check(deck.draw_pile.size() == 24, "sobram 24 na compra")

	deck.discard(drawn)
	check(deck.discard_pile.size() == 8, "descarte recebe 8 notas")
	deck.draw_pile.clear()
	var refilled := deck.draw(3)
	check(refilled.size() == 3, "compra depois de esvaziar reembaralha o descarte")


func _test_transactions() -> void:
	var t := HandEvaluator.evaluate([n(10)])
	check(t["kind"] == "trocado", "uma carta solta é Trocado")

	t = HandEvaluator.evaluate([n(10), n(10, Note.Suit.DEBITO)])
	check(t["kind"] == "dobradinha", "dois iguais é Dobradinha")

	t = HandEvaluator.evaluate([n(20), n(20, Note.Suit.DEBITO), n(20, Note.Suit.CREDITO)])
	check(t["kind"] == "bolada", "três iguais é Bolada")

	t = HandEvaluator.evaluate([n(50), n(50, Note.Suit.DEBITO), n(50, Note.Suit.CREDITO), n(50, Note.Suit.RELAMPAGO)])
	check(t["kind"] == "cofrinho", "quatro iguais é Cofrinho")

	t = HandEvaluator.evaluate([n(1), n(2, Note.Suit.DEBITO), n(5), n(10, Note.Suit.CREDITO), n(20, Note.Suit.RELAMPAGO)])
	check(t["kind"] == "escadinha", "1-2-5-10-20 em sequência é Escadinha")

	t = HandEvaluator.evaluate([n(1, Note.Suit.DINHEIRO), n(5, Note.Suit.DEBITO), n(20, Note.Suit.CREDITO), n(100, Note.Suit.RELAMPAGO), n(200, Note.Suit.DINHEIRO)])
	check(t["kind"] == "trocado", "5 valores sem sequência e formas variadas vira Trocado")

	var same_suit: Array = [n(1, Note.Suit.CREDITO), n(5, Note.Suit.CREDITO), n(20, Note.Suit.CREDITO), n(100, Note.Suit.CREDITO), n(200, Note.Suit.CREDITO)]
	t = HandEvaluator.evaluate(same_suit)
	check(t["kind"] == "tudo_no_relampago", "5 da mesma forma é Tudo no Relâmpago")


func _test_priority() -> void:
	# Escadinha (30×4=120) perde para Tudo no Relâmpago (35×4=140) quando as 5 são da mesma forma.
	var both := [n(1, Note.Suit.DEBITO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.DEBITO), n(10, Note.Suit.DEBITO), n(20, Note.Suit.DEBITO)]
	check(HandEvaluator.evaluate(both)["kind"] == "tudo_no_relampago", "Relâmpago vence Escadinha quando ambas servem")

	# Dobradinha (10×2=20) vence Trocado (5×1=5) mesmo com carta maior na mão.
	var pair_and_high := [n(2), n(2, Note.Suit.DEBITO), n(100)]
	check(HandEvaluator.evaluate(pair_and_high)["kind"] == "dobradinha", "Dobradinha vence Trocado")

	# Mão vazia.
	check(HandEvaluator.evaluate([])["kind"] == "none", "mão vazia não pontua")


func _test_bill_round() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Pagar sem escolher nada é recusado e não gasta dia.
	var bill := BillRound.new(1, Boss.NONE, rng)
	check(bill.hand.size() == 8, "conta começa com 8 notas na mão")
	check(bill.pay()["reason"] == "no_selection", "pagar sem seleção é recusado")
	check(bill.days_left == 4, "recusa não gasta dia")

	# Seleção limitada a 5 notas.
	for i in range(5):
		check(bill.toggle_select(bill.hand[i]), "seleciona nota %d" % i)
	check(not bill.toggle_select(bill.hand[5]), "não seleciona a 6ª nota")
	bill.toggle_select(bill.hand[0])
	check(bill.selected.size() == 4, "desmarcar libera vaga")

	# Pagar com meta de R$ 1: vence de primeira.
	var r := bill.pay()
	check(r["ok"] and r["state"] == BillRound.WON, "meta de R$1 é batida na primeira jogada")
	check(bill.reward(3) == 3 + 3, "recompensa = base + 3 dias não usados (R$ %d)" % bill.reward(3))
	check(bill.pay()["reason"] == "round_over", "conta encerrada não aceita mais jogadas")

	# Conta impossível: perde ao acabar os 4 dias.
	var lost := BillRound.new(999999, Boss.NONE, rng)
	for day in range(4):
		lost.toggle_select(lost.hand[0])
		lost.pay()
	check(lost.state == BillRound.LOST, "perde ao acabar os 4 dias")
	check(lost.reward(3) == 0, "conta perdida não paga recompensa")

	# Trocas: 3 permitidas, a 4ª é recusada e nenhuma gasta dia.
	var swapper := BillRound.new(999999, Boss.NONE, rng)
	for i in range(3):
		swapper.toggle_select(swapper.hand[0])
		check(swapper.swap()["ok"], "troca %d aceita" % (i + 1))
	swapper.toggle_select(swapper.hand[0])
	check(swapper.swap()["reason"] == "no_swaps", "4ª troca é recusada")
	check(swapper.days_left == 4, "trocar não gasta dia")
	check(swapper.hand.size() == 8, "mão continua com 8 notas depois de trocar")


func _test_scoring() -> void:
	# Trocado de R$ 10: (5 + 6) × 1 = 11
	var s := Scorer.score(HandEvaluator.evaluate([n(10)]))
	check(s["total"] == 11, "Trocado R$10 = 11 (got %s)" % s["total"])

	# Dobradinha de 10s: (10 + 6 + 6) × 2 = 44
	s = Scorer.score(HandEvaluator.evaluate([n(10), n(10, Note.Suit.DEBITO)]))
	check(s["total"] == 44, "Dobradinha de 10 = 44 (got %s)" % s["total"])

	# Bolada de 20s: (30 + 7×3) × 3 = 153
	s = Scorer.score(HandEvaluator.evaluate([n(20), n(20, Note.Suit.DEBITO), n(20, Note.Suit.CREDITO)]))
	check(s["total"] == 153, "Bolada de 20 = 153 (got %s)" % s["total"])

	# Cofrinho de 50s: (60 + 8×4) × 7 = 644
	s = Scorer.score(HandEvaluator.evaluate([n(50), n(50, Note.Suit.DEBITO), n(50, Note.Suit.CREDITO), n(50, Note.Suit.RELAMPAGO)]))
	check(s["total"] == 644, "Cofrinho de 50 = 644 (got %s)" % s["total"])

	# Escadinha 1-2-5-10-20: pontos 2+3+5+6+7 = 23; (30 + 23) × 4 = 212
	s = Scorer.score(HandEvaluator.evaluate([n(1), n(2, Note.Suit.DEBITO), n(5), n(10, Note.Suit.CREDITO), n(20, Note.Suit.RELAMPAGO)]))
	check(s["total"] == 212, "Escadinha = 212 (got %s)" % s["total"])

	# Nenhuma nota: saldo 0 e evento final presente.
	s = Scorer.score(HandEvaluator.evaluate([]))
	check(s["total"] == 0, "mão vazia = 0")
	check(s["events"][-1]["type"] == "total", "último evento é o total")


func _test_bosses() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Banco fora do ar: Relâmpago não pontua. Dobradinha de 10 (Dinheiro + Relâmpago) vira Trocado de 10 (Dinheiro): 11.
	var bill := BillRound.new(999999, "banco_fora_do_ar", rng)
	bill.hand = [n(10, Note.Suit.RELAMPAGO), n(10, Note.Suit.DINHEIRO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	var r := bill.pay()
	check(r["score"]["total"] == 11, "Relâmpago não pontua no Banco fora do ar (got %s)" % r["score"]["total"])
	check(bill.saldo == 11, "saldo só recebe o que pontua")

	# Sem chefe: a mesma jogada vale Dobradinha = 44.
	bill = BillRound.new(999999, Boss.NONE, rng)
	bill.hand = [n(10, Note.Suit.RELAMPAGO), n(10, Note.Suit.DINHEIRO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	check(bill.pay()["score"]["total"] == 44, "sem chefe a Dobradinha vale 44")

	# Leão da Receita: Dobradinha de 10 (44) perde 27,5% → 12 (floor de 12,1). Saldo = 32.
	bill = BillRound.new(999999, "janeiro_impostos", rng)
	bill.hand = [n(10), n(10, Note.Suit.DEBITO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	r = bill.pay()
	check(r["score"]["tax"] == 12, "imposto de 27,5%% sobre 44 = 12 (got %s)" % r["score"]["tax"])
	check(bill.saldo == 32, "saldo com imposto = 32 (got %s)" % bill.saldo)

	check(BillRound.new(1, "taxa_manutencao", rng).swap_cost() == 1, "troca custa R$1 na taxa de manutenção")
	check(BillRound.new(1, "banco_fora_do_ar", rng).swap_cost() == 0, "troca é grátis no banco fora do ar")


func _test_run_state() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99

	# Troco: R$1 a cada 25% acima da meta, máximo R$5.
	check(RunState.troco(100, 100) == 0, "sem troco na meta exata")
	check(RunState.troco(124, 100) == 0, "sem troco abaixo de 25%")
	check(RunState.troco(125, 100) == 1, "R$1 de troco com 25% acima")
	check(RunState.troco(150, 100) == 2, "R$2 de troco com 50% acima")
	check(RunState.troco(1000, 100) == 5, "troco limitado a R$5")

	# Dívida cresce 25% arredondando para cima.
	check(RunState.debt_growth(10) == 3, "dívida de 10 cresce para 3 (2,5 arredondado)")
	check(RunState.debt_growth(4) == 1, "dívida de 4 cresce 1")

	var run := RunState.new(rng)
	check(run.wallet == Balance.START_WALLET, "carteira começa em R$4")
	check(run.bill_title() == "Março · Boleto", "primeira conta é Março · Boleto (got %s)" % run.bill_title())
	check(run.boss_id() == Boss.NONE, "boleto não tem chefe")

	# Pagar a primeira conta: carteira recebe recompensa + troco do comprovante.
	run.bill.goal = 1
	run.bill.toggle_select(run.bill.hand[0])
	run.pay()
	check(run.state == RunState.BILL_PAID, "conta paga mostra comprovante")
	check(run.wallet == Balance.START_WALLET + run.receipt["reward"] + run.receipt["troco"], "carteira = inicial + recompensa + troco")
	check(run.receipt["reward"] == Balance.REWARD_BOLETO + 3 * Balance.REWARD_PER_UNUSED_DAY, "recompensa do boleto + 3 dias não usados")
	check(run.next_bill() and run.state == RunState.SHOP, "depois do comprovante vem o Camelô")
	check(run.leave_shop(), "sai do Camelô para a próxima conta")
	check(run.bill_title() == "Março · Aluguel", "segunda conta é Aluguel")

	# Cheque especial: troca recusada se passar de -R$10.
	var gate := RunState.new(rng)
	gate.bill = BillRound.new(999999, "taxa_manutencao", rng)
	gate.wallet = -9
	gate.bill.toggle_select(gate.bill.hand[0])
	check(gate.swap()["ok"] and gate.wallet == -10, "troca desce a carteira até -R$10")
	gate.bill.toggle_select(gate.bill.hand[0])
	check(gate.swap()["reason"] == "no_money", "troca recusada abaixo de -R$10")

	# Conta perdida encerra a partida.
	var lost := RunState.new(rng)
	lost.bill = BillRound.new(999999, Boss.NONE, rng)
	for i in range(4):
		lost.bill.toggle_select(lost.bill.hand[0])
		lost.pay()
	check(lost.state == RunState.LOST, "perder uma conta encerra a partida")

	# Partida inteira: 9 contas pagas (3 meses × 3). Chefes certos nas faturas.
	var full := RunState.new(rng)
	var bosses_seen: Array = []
	for i in range(9):
		if full.bill_key() == "fatura":
			bosses_seen.append(full.boss_id())
		full.bill.goal = 1
		# Escolhe uma nota que pontua (no Banco fora do ar, Relâmpago não conta).
		for c in full.bill.hand:
			if Boss.note_scores(full.boss_id(), c):
				full.bill.toggle_select(c)
				break
		full.pay()
		if i < 8:
			full.next_bill()
			full.leave_shop()
	check(full.state == RunState.WON, "pagar a última fatura vence a partida")
	check(bosses_seen == ["banco_fora_do_ar", "taxa_manutencao", "janeiro_impostos"], "chefes das faturas na ordem (got %s)" % str(bosses_seen))
	check(full.max_saldo > 0, "saldo máximo do ano registrado")
	check(not full.next_bill(), "não há próxima conta depois da última")


func _test_assets() -> void:
	# Cada uma das 32 cartas (8 valores × 4 formas) precisa de frente 120×180.
	for suit in Note.Suit.values():
		for value in Balance.VALUES:
			var note := n(value, suit)
			var path := note.face_path()
			check(ResourceLoader.exists(path), "frente existe: %s" % path)
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path)
				check(tex.get_width() == 120 and tex.get_height() == 180, "frente %s tem 120x180" % path)


func _test_schemes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var t200 := [n(200)]  # Trocado de 200: (5 + 11) × 1 = 16

	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["agiota"]})["total"] == 96, "Agiota +5 Juros: 16 × 6 = 96")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["cunhado"], "cunhado_bonus": 3})["total"] == 64, "Cunhado acumulado +3: 16 × 4 = 64")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["piramide", "cunhado"]})["total"] == 32, "Pirâmide +1 por outro esquema: 16 × 2 = 32")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["agiota", "piramide"]})["total"] == 112, "Agiota + Pirâmide: 16 × 7 = 112")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["vaquinha"], "hand_points": 10})["total"] == 26, "Vaquinha soma 10 ao Valor: (16 + 10) = 26")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["rifa"], "rifa": true})["total"] == 80, "Rifa sorteada ×5: 16 × 5 = 80")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["rifa"], "rifa": false})["total"] == 16, "Rifa não sorteada não muda")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["coach"], "played": 5})["total"] == 32, "Coach com 5 notas ×2: 32")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["coach"], "played": 1})["total"] == 0, "Coach com menos de 5 perde 1 de Juros: 0")

	check(SchemeRules.agiota_charge(100) == 10, "Agiota cobra 10% de R$ 100")
	check(SchemeRules.agiota_charge(5) == 0, "Agiota não cobra de carteira baixa")
	check(SchemeRules.agiota_charge(-4) == 0, "Agiota não cobra com dívida")

	# Cashback: notas de Crédito que pontuam devolvem R$ 1 cada.
	var cash_bill := BillRound.new(999999, Boss.NONE, rng, ["cashback"])
	cash_bill.hand = [n(10, Note.Suit.CREDITO), n(20, Note.Suit.CREDITO), n(5, Note.Suit.DINHEIRO)]
	cash_bill.selected = [cash_bill.hand[0], cash_bill.hand[1]]
	check(cash_bill.pay()["cash"] == 2, "Cashback devolve R$1 por nota de Crédito que pontua")

	# Relâmpago Errado: a primeira nota de Relâmpago jogada é copiada para o baralho (uma vez por conta).
	# Baralho controlado: conta as notas em baralho, descarte e mão (não muda com as compras).
	var copy_on := _rel_bill(["relampago_errado"], rng)
	var before := _count_rel10(copy_on)
	copy_on.pay()
	check(_count_rel10(copy_on) - before == 1, "Relâmpago Errado adiciona 1 cópia ao baralho")

	var copy_off := _rel_bill([], rng)
	before = _count_rel10(copy_off)
	copy_off.pay()
	check(_count_rel10(copy_off) - before == 0, "sem o esquema não há cópia")

	# Cunhado: cada Escadinha jogada soma 1 ao acumulado da partida.
	var cun := RunState.new(rng)
	cun.schemes = ["cunhado"]
	cun.bill.hand = [n(1, Note.Suit.DINHEIRO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.CREDITO), n(10, Note.Suit.RELAMPAGO), n(20, Note.Suit.DINHEIRO)]
	cun.bill.selected = cun.bill.hand.duplicate()
	cun.pay()
	check(cun.cunhado_bonus == 1, "Cunhado acumula +1 após uma Escadinha")

	# Golpe do WhatsApp (fatura de Janeiro): 1 esquema some da conta, não da partida.
	var golpe := RunState.new(rng)
	golpe.schemes = ["agiota", "cunhado"]
	golpe.month_index = 2
	golpe.bill_index = 2
	golpe._start_bill()
	check(golpe.bill.schemes.size() == 1 and golpe.schemes.size() == 2, "Golpe do WhatsApp desativa 1 esquema só nesta conta")

	# Camelô: comprar, vender, pechinchar e cheque especial.
	var shop := RunState.new(rng)
	shop.bill.goal = 1
	shop.bill.toggle_select(shop.bill.hand[0])
	shop.pay()
	check(shop.next_bill() and shop.shop_offer.size() == Balance.SHOP_OFFERS, "Camelô abre com 2 esquemas à venda")
	var offer_id: String = shop.shop_offer[0]
	var price: int = Balance.SCHEMES[offer_id]["price"]
	var w0 := shop.wallet
	check(shop.buy(0)["ok"] and shop.schemes == [offer_id] and shop.wallet == w0 - price, "compra desconta o preço")
	check(shop.sell(0)["ok"] and shop.schemes.is_empty() and shop.wallet == w0 - price + price / 2, "venda devolve metade do preço")
	var w1 := shop.wallet
	check(shop.haggle()["ok"] and shop.wallet == w1 - Balance.HAGGLE_COST, "pechinchar custa R$ 2")

	shop.wallet = Balance.OVERDRAFT_LIMIT + price
	check(shop.buy(0)["ok"] and shop.wallet == Balance.OVERDRAFT_LIMIT, "compra pode usar o cheque especial até -R$ 10")
	shop.wallet = Balance.OVERDRAFT_LIMIT + price - 1
	check(shop.buy(0)["reason"] == "no_money", "compra recusada abaixo de -R$ 10")

	shop.wallet = 100
	shop.schemes = ["agiota", "cunhado", "coach", "piramide", "rifa"]
	check(shop.buy(0)["reason"] == "slots_full", "no máximo 5 esquemas ativos")


## Conta com baralho e mão conhecidos, para testar duplicação de notas.
func _rel_bill(p_schemes: Array, rng: RandomNumberGenerator) -> BillRound:
	var bill := BillRound.new(999999, Boss.NONE, rng, p_schemes)
	bill.deck.draw_pile = [n(1, Note.Suit.DEBITO), n(2, Note.Suit.CREDITO), n(5, Note.Suit.DINHEIRO)]
	bill.deck.discard_pile = []
	bill.hand = [n(10, Note.Suit.RELAMPAGO), n(20, Note.Suit.DEBITO)]
	bill.selected = [bill.hand[0]]
	return bill


## Quantas notas R$10 Relâmpago existem na conta (baralho + descarte + mão).
func _count_rel10(bill: BillRound) -> int:
	var total := 0
	for pile in [bill.deck.draw_pile, bill.deck.discard_pile, bill.hand]:
		for c in pile:
			if c.value == 10 and c.suit == Note.Suit.RELAMPAGO:
				total += 1
	return total

