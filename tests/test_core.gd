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
	_test_chefes_novos()
	_test_previa()
	_test_formacoes_liberadas()
	_test_assets()
	_test_schemes()
	_test_investments()
	_test_score_events()

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
	check(deck.total_cards() == 40, "baralho tem 40 notas")

	var seen := {}
	for c in deck.draw_pile:
		seen["%d-%d" % [c.value, c.suit]] = true
	check(seen.size() == 40, "todas as 40 combinações valor×forma são únicas")

	var drawn := deck.draw(8)
	check(drawn.size() == 8, "compra 8 notas")
	check(deck.draw_pile.size() == 32, "sobram 32 na compra")

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

	t = HandEvaluator.evaluate([n(50), n(50, Note.Suit.DEBITO), n(50, Note.Suit.CREDITO), n(50, Note.Suit.PIX)])
	check(t["kind"] == "cofrinho", "quatro iguais é Cofrinho")

	t = HandEvaluator.evaluate([n(1), n(2, Note.Suit.DEBITO), n(5), n(10, Note.Suit.CREDITO), n(20, Note.Suit.PIX)])
	check(t["kind"] == "escadinha", "1-2-5-10-20 em sequência é Escadinha")

	t = HandEvaluator.evaluate([n(1, Note.Suit.DINHEIRO), n(5, Note.Suit.DEBITO), n(20, Note.Suit.CREDITO), n(100, Note.Suit.PIX), n(200, Note.Suit.DINHEIRO)])
	check(t["kind"] == "trocado", "5 valores sem sequência e formas variadas vira Trocado")

	var same_suit: Array = [n(1, Note.Suit.CREDITO), n(5, Note.Suit.CREDITO), n(20, Note.Suit.CREDITO), n(100, Note.Suit.CREDITO), n(200, Note.Suit.CREDITO)]
	t = HandEvaluator.evaluate(same_suit)
	check(t["kind"] == "tudo_no_pix", "5 da mesma forma é Tudo no Pix")


func _test_priority() -> void:
	# Escadinha (25×3=75) perde para Tudo no Pix (35×4=140) quando as 5 são da mesma forma.
	var both := [n(1, Note.Suit.DEBITO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.DEBITO), n(10, Note.Suit.DEBITO), n(20, Note.Suit.DEBITO)]
	check(HandEvaluator.evaluate(both)["kind"] == "tudo_no_pix", "Pix vence Escadinha quando ambas servem")

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
	s = Scorer.score(HandEvaluator.evaluate([n(50), n(50, Note.Suit.DEBITO), n(50, Note.Suit.CREDITO), n(50, Note.Suit.PIX)]))
	check(s["total"] == 644, "Cofrinho de 50 = 644 (got %s)" % s["total"])

	# Escadinha 1-2-5-10-20: pontos 2+3+5+6+7 = 23; (25 + 23) × 3 = 144
	s = Scorer.score(HandEvaluator.evaluate([n(1), n(2, Note.Suit.DEBITO), n(5), n(10, Note.Suit.CREDITO), n(20, Note.Suit.PIX)]))
	check(s["total"] == 144, "Escadinha = 144 (got %s)" % s["total"])

	# Nenhuma nota: saldo 0 e evento final presente.
	s = Scorer.score(HandEvaluator.evaluate([]))
	check(s["total"] == 0, "mão vazia = 0")
	check(s["events"][-1]["type"] == "total", "último evento é o total")


func _test_bosses() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Banco fora do ar: Pix não pontua. Dobradinha de 10 (Dinheiro + Pix) vira Trocado de 10 (Dinheiro): 11.
	var bill := BillRound.new(999999, "banco_fora_do_ar", rng)
	bill.hand = [n(10, Note.Suit.PIX), n(10, Note.Suit.DINHEIRO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	var r := bill.pay()
	check(r["score"]["total"] == 11, "Pix não pontua no Banco fora do ar (got %s)" % r["score"]["total"])
	check(bill.saldo == 11, "saldo só recebe o que pontua")

	# Sem chefe: a mesma jogada vale Dobradinha = 44.
	bill = BillRound.new(999999, Boss.NONE, rng)
	bill.hand = [n(10, Note.Suit.PIX), n(10, Note.Suit.DINHEIRO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	check(bill.pay()["score"]["total"] == 44, "sem chefe a Dobradinha vale 44")

	# Leão da Receita: Dobradinha de 10 (44) perde 27,5% → 12 (floor de 12,1). Saldo = 32.
	bill = BillRound.new(999999, "janeiro_impostos", rng)
	bill.hand = [n(10), n(10, Note.Suit.DEBITO)]
	bill.selected = [bill.hand[0], bill.hand[1]]
	r = bill.pay()
	var leao: int = 44 * Balance.LEAO_PER_MILLE / 1000
	check(r["score"]["tax"] == leao, "imposto sobre 44 = %d (got %s)" % [leao, r["score"]["tax"]])
	check(bill.saldo == 44 - leao, "saldo com imposto = %d (got %s)" % [44 - leao, bill.saldo])

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
	check(run.bill_title() == "Janeiro · Boleto", "primeira conta é Janeiro · Boleto (got %s)" % run.bill_title())
	check(Balance.BOSS_TIERS["leve"].has(run.month_boss), "o chefe de Janeiro é sorteado entre os leves (got %s)" % run.month_boss)
	check(run.boss_id() == Boss.NONE, "boleto não tem chefe (got %s)" % run.boss_id())

	# Pagar a primeira conta: carteira recebe recompensa + troco do comprovante.
	run.bill.goal = 1
	run.bill.toggle_select(run.bill.hand[0])
	run.pay()
	check(run.state == RunState.BILL_PAID, "conta paga mostra comprovante")
	check(run.wallet == Balance.START_WALLET + run.receipt["reward"] + run.receipt["troco"], "carteira = inicial + recompensa + troco")
	check(run.receipt["reward"] == Balance.REWARD_BOLETO + 3 * Balance.REWARD_PER_UNUSED_DAY, "recompensa do boleto + 3 dias não usados")
	check(run.next_bill() and run.state == RunState.SHOP, "depois do comprovante vem o Camelô")
	check(run.leave_shop(), "sai do Camelô para a próxima conta")
	check(run.bill_title() == "Janeiro · Aluguel", "segunda conta é Aluguel")

	# Cheque especial: R$ 10 por partida. Cada R$ usado vira 3 de dívida e diminui o limite.
	var gate := RunState.new(rng)
	gate.bill = BillRound.new(999999, "taxa_manutencao", rng)
	gate.wallet = 0
	var custo := gate.bill.swap_cost()
	gate.bill.toggle_select(gate.bill.hand[0])
	check(gate.swap()["ok"] and gate.wallet == -3 * custo and gate.overdraft_left == Balance.OVERDRAFT_START - custo, "troca no cheque: dívida 3x e limite diminui (got %d, %d)" % [gate.wallet, gate.overdraft_left])
	var short := RunState.new(rng)
	short.bill = BillRound.new(999999, "taxa_manutencao", rng)
	short.wallet = 0
	short.overdraft_left = custo - 1
	short.bill.toggle_select(short.bill.hand[0])
	check(short.swap()["reason"] == "no_money", "troca recusada se o limite restante não cobre")
	var empty := RunState.new(rng)
	empty.bill = BillRound.new(999999, "taxa_manutencao", rng)
	empty.wallet = 0
	empty.overdraft_left = custo
	empty.bill.toggle_select(empty.bill.hand[0])
	check(empty.swap()["ok"] and empty.state == RunState.LOST and empty.end_reason == "cheque", "gastar o último R$ do cheque acaba a partida")

	# Conta perdida encerra a partida.
	var lost := RunState.new(rng)
	lost.bill = BillRound.new(999999, Boss.NONE, rng)
	for i in range(4):
		lost.bill.toggle_select(lost.bill.hand[0])
		lost.pay()
	check(lost.state == RunState.LOST, "perder uma conta encerra a partida")

	# Partida inteira: 18 contas (6 meses × 3) vencem; continuando no modo infinito, vai até o último chefe.
	# Um chefe por mês, sem repetir; os chefes com data caem no mês deles.
	var full := RunState.new(rng)
	var bosses_seen: Array = []
	var total_bills: int = Balance.TOTAL_MONTHS * 3
	for i in range(total_bills):
		if full.bill_key() == "fatura":
			bosses_seen.append(full.boss_id())
			var fixed_month: int = Balance.BOSS_FIXED_MONTH.get(full.boss_id(), -1)
			if fixed_month >= 0 and full.month_index < 12:
				check(full.month_index % 12 == fixed_month, "chefe com data cai no mês dele: %s" % full.boss_id())
			if full.month_index < Balance.RUN_MONTHS and fixed_month < 0:
				var tier: String = Balance.BOSS_TIER_BY_MONTH[full.month_index]
				check(Balance.BOSS_TIERS[tier].has(full.boss_id()), "mês %d sorteia chefe da faixa %s (got %s)" % [full.month_index + 1, tier, full.boss_id()])
		# Meta de teste 0: qualquer jogada paga, mesmo a que o chefe não deixa pontuar.
		full.bill.goal = 0
		full.bill.toggle_select(full.bill.hand[0])
		full.pay()
		if i == 17:
			check(full.state == RunState.WON, "pagar a fatura de Junho vence a partida")
			check(full.month_index == 5 and full.bills_paid() == 18, "vitória no 6º mês, com 18 contas pagas")
			check(not full.next_bill(), "partida vencida não vai à Banca sem escolher continuar")
			check(full.can_continue(), "depois dos 6 meses dá para continuar")
			check(not RunState.from_dict(full.to_dict()).endless, "save antes de continuar: modo infinito desligado")
			check(full.continue_endless() and full.endless and full.state == RunState.BILL_PAID, "continuar liga o modo infinito e volta à conta paga")
			var saved := RunState.from_dict(full.to_dict())
			check(saved.endless and saved.month_boss == full.month_boss and saved.bosses_done == full.bosses_done, "save guarda o modo infinito e os chefes")
		elif i < total_bills - 1 and full.state != RunState.BILL_PAID:
			check(false, "conta %d paga, a partida segue (estado %s)" % [i + 1, full.state])
		if i < total_bills - 1:
			full.next_bill()
			full.leave_shop()
	check(full.state == RunState.WON, "pagar a última fatura derrota todos os chefes")
	check(not full.can_continue() and not full.continue_endless(), "depois do último chefe não há como continuar")
	check(bosses_seen.size() == Balance.TOTAL_MONTHS and not bosses_seen.has(Boss.NONE), "um chefe por mês (got %d)" % bosses_seen.size())
	var unique := {}
	for id in bosses_seen:
		unique[id] = true
	check(unique.size() == Balance.BOSSES.size(), "os %d chefes saem uma vez cada (got %d)" % [Balance.BOSSES.size(), unique.size()])
	check(full.month_name() == "Dezembro 3", "o terceiro ano mostra o número no mês (got %s)" % full.month_name())
	check(full.max_saldo > 0, "saldo máximo do ano registrado")
	check(not full.next_bill(), "não há próxima conta depois da última")
	# Cheque Sem Fundo: a dívida sobe a meta (1% a cada R$ 4). Sem o contato, a dívida não mexe na meta.
	var sf := RunState.new(rng)
	sf.contacts_owned = ["sem_fundo"]
	sf.wallet = -40
	sf._start_bill()
	check(sf.bill.goal == Balance.D0 + Balance.D0 * 10 / 100, "Sem Fundo com R$ 40 de dívida: meta +10%% (got %d)" % sf.bill.goal)
	var nf := RunState.new(rng)
	nf.wallet = -40
	nf._start_bill()
	check(nf.bill.goal == Balance.D0, "dívida sem o Sem Fundo não muda a meta")
	check(Balance.goal_of(0, "boleto") == Balance.D0, "a primeira meta é D0")
	check(Balance.goal_of(5, "fatura") == roundi(Balance.D0 * pow(Balance.R, 17)), "meta da fatura de Junho segue a curva")


## Chefes do ano de 12 meses: cada regra nova, com números conferidos à mão.
func _test_chefes_novos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	var tiered := {}
	for tier in Balance.BOSS_TIERS:
		for id in Balance.BOSS_TIERS[tier]:
			check(Balance.BOSSES.has(id), "chefe %s tem nome e texto" % id)
			check(not tiered.has(id), "chefe %s está em uma faixa só" % id)
			tiered[id] = true
	check(Balance.BOSSES.size() == 36 and tiered.size() == 36 and Balance.TOTAL_MONTHS == 36, "36 chefes, todos com faixa")
	for id in Balance.BOSS_SCALE:
		check(Balance.BOSSES[id]["text"].contains("%d") and Balance.BOSS_SCALE[id].size() == Balance.BOSS_MAX_LEVEL + 1, "chefe %s tem um número por nível" % id)
	check(Boss.level_of(0) == 0 and Boss.level_of(3) == 1 and Boss.level_of(5) == 2 and Boss.level_of(20) == 3, "nível do chefe sobe a cada 2 meses, até 3")

	# --- Chefes novos ---
	# Formas de pagamento e valores que não pontuam.
	check(not Boss.note_scores("maquininha_quebrada", n(10, Note.Suit.DEBITO)) and Boss.note_scores("maquininha_quebrada", n(10, Note.Suit.PIX)), "Maquininha quebrada: Débito não pontua")
	check(not Boss.note_scores("cartao_clonado", n(10, Note.Suit.CREDITO)), "Cartão clonado: Crédito não pontua")
	check(not Boss.note_scores("caixa_sem_troco", n(10, Note.Suit.DINHEIRO)), "Caixa sem troco: Dinheiro não pontua")
	check(not Boss.note_scores("troco_em_bala", n(5)) and Boss.note_scores("troco_em_bala", n(10)), "Troco em bala: até R$ 5 não pontua")
	check(not Boss.note_scores("nota_falsa", n(200)) and Boss.note_scores("nota_falsa", n(100)), "Nota falsa: de R$ 200 para cima não pontua")
	# Dias e trocas.
	check(BillRound.new(9, "fila_loterica", rng).swaps_left == Balance.SWAPS_PER_BILL - 1, "Fila da lotérica: uma troca a menos")
	check(BillRound.new(9, "feriadao", rng).days_left == 3, "Feriadão: 3 dias")
	var copa := BillRound.new(9, "copa_do_mundo", rng)
	check(copa.days_left == 2 and copa.swaps_left == 1, "Copa do Mundo: 2 dias e 1 troca")
	# Boleto vencido: Trocado de 200 vale 16; a primeira jogada vale 8, a segunda 16.
	var venc := BillRound.new(999999, "boleto_vencido", rng)
	venc.hand = [n(200), n(200, Note.Suit.PIX)]
	venc.selected = [venc.hand[0]]
	check(venc.preview(venc.selected)["total"] == 8, "Boleto vencido: a prévia já mostra a metade")
	check(venc.pay()["score"]["total"] == 8, "Boleto vencido: primeira jogada vale metade")
	venc.hand = [n(200)]
	venc.selected = venc.hand.duplicate()
	check(venc.pay()["score"]["total"] == 16, "Boleto vencido: segunda jogada vale inteira")
	# Inflação (nível 1 = 5%): a meta sobe depois de cada jogada que não paga.
	var infl := BillRound.new(1000, "inflacao", rng)
	infl.boss_level = 1
	infl.selected = [infl.hand[0]]
	infl.pay()
	check(infl.goal == 1050, "Inflação: meta sobe 5%% por jogada (got %d)" % infl.goal)
	# Carnaval: a mão inteira é trocada depois da jogada.
	var carn := BillRound.new(999999, "carnaval", rng)
	var old_hand := carn.hand.duplicate()
	carn.selected = [carn.hand[0]]
	carn.pay()
	var kept := 0
	for c in carn.hand:
		if old_hand.has(c):
			kept += 1
	check(kept == 0 and carn.hand.size() == Balance.HAND_SIZE, "Carnaval: mão nova inteira depois da jogada")
	# Fatura parcelada (nível 2 = 40%): a jogada conta no máximo 40% da meta.
	var parc := BillRound.new(20, "fatura_parcelada", rng)
	parc.boss_level = 2
	parc.hand = [n(200)]
	parc.selected = parc.hand.duplicate()
	check(parc.pay()["score"]["total"] == 8, "Fatura parcelada: jogada de 16 conta 8 (40%% de 20)")
	# Rotina: a mesma formação não pontua de novo.
	var rot := BillRound.new(999999, "rotina", rng)
	rot.hand = [n(200), n(100)]
	rot.selected = [rot.hand[0]]
	check(rot.pay()["score"]["total"] == 16, "Rotina: primeiro Trocado pontua")
	rot.hand = [n(100)]
	rot.selected = rot.hand.duplicate()
	check(rot.pay()["score"]["total"] == 0, "Rotina: segundo Trocado não pontua")
	# Sogra em casa: só jogada com 5 notas.
	var sogra := BillRound.new(999999, "sogra_em_casa", rng)
	sogra.selected = [sogra.hand[0]]
	check(sogra.preview(sogra.selected)["total"] == 0, "Sogra em casa: jogada com 1 nota não pontua")
	sogra.selected = sogra.hand.slice(0, 5)
	check(sogra.preview(sogra.selected)["total"] > 0, "Sogra em casa: jogada com 5 notas pontua")
	# Tigrinho: dobra ou cai pela metade.
	var tig := BillRound.new(999999, "tigrinho", rng)
	tig.hand = [n(200)]
	tig.selected = tig.hand.duplicate()
	var tig_total: int = tig.pay()["score"]["total"]
	check(tig_total == 32 or tig_total == 8, "Tigrinho: 16 vira 32 ou 8 (got %d)" % tig_total)
	# Wi-Fi caiu (2 jogadas): o Agiota (+3 de Juros) só vale a partir da terceira jogada.
	var wifi := BillRound.new(999999, "wifi_caiu", rng, ["agiota"])
	for expected in [16, 16, 64]:
		wifi.hand = [n(200)]
		wifi.selected = wifi.hand.duplicate()
		var got: int = wifi.pay()["score"]["total"]
		check(got == expected, "Wi-Fi caiu: jogada vale %d (got %d)" % [expected, got])
	# Apagão: só a tela muda.
	check(Boss.hides_preview("apagao") and not Boss.hides_preview("carnaval"), "Apagão esconde a prévia")

	# Dia das Mães: recompensa pela metade (fatura 5 + 3 dias = 8, vira 4).
	var maes := RunState.new(rng)
	maes.month_index = 4
	maes.month_boss = "dia_das_maes"
	maes.bill_index = 2
	maes._start_bill()
	maes.bill.goal = 1
	maes.bill.toggle_select(maes.bill.hand[0])
	maes.pay()
	check(maes.receipt["reward"] == 4, "Dia das Mães: recompensa cai pela metade (got %s)" % str(maes.receipt["reward"]))
	# Reajuste do aluguel no mês 4 (nível 1 = +30%).
	var reaj := RunState.new(rng)
	reaj.month_index = 3
	reaj.month_boss = "reajuste_aluguel"
	reaj.bill_index = 2
	reaj._start_bill()
	check(reaj.bill.goal == Balance.goal_of(3, "fatura") * 130 / 100, "Reajuste do aluguel: meta +30%% no nível 1 (got %d)" % reaj.bill.goal)
	# Serasa (nível 1 = +40%): só com carteira negativa.
	var ser := RunState.new(rng)
	ser.month_index = 2
	ser.month_boss = "serasa"
	ser.bill_index = 2
	ser._start_bill()
	check(ser.bill.goal == Balance.goal_of(2, "fatura"), "Serasa: carteira positiva, meta normal")
	ser.wallet = -5
	ser._start_bill()
	check(ser.bill.goal == Balance.goal_of(2, "fatura") * 140 / 100, "Serasa: carteira negativa, meta +40%%")
	# Golpe do falso gerente (nível 1 = 25%) e Plano Collor (nível 2 = 80%).
	var falso := RunState.new(rng)
	falso.month_index = 2
	falso.month_boss = "golpe_falso_gerente"
	falso.bill_index = 2
	falso.wallet = 40
	falso._start_bill()
	check(falso.wallet == 30 and falso.boss_note != "", "Golpe do falso gerente: some 25%% da carteira (got %d)" % falso.wallet)
	var collor := RunState.new(rng)
	collor.month_index = 5
	collor.month_boss = "plano_collor"
	collor.bill_index = 2
	collor.wallet = 50
	collor._start_bill()
	check(collor.wallet == 10, "Plano Collor: 80%% da carteira confiscada (got %d)" % collor.wallet)
	collor.wallet = -8
	collor._start_bill()
	check(collor.wallet == -8, "Plano Collor: carteira negativa não muda")
	# Black Friday: meta +20%; a Banca seguinte vende pela metade, e só ela.
	var bf := RunState.new(rng)
	bf.month_index = 2
	bf.month_boss = "black_friday"
	bf.bill_index = 2
	bf._start_bill()
	check(bf.bill.goal == Balance.goal_of(2, "fatura") * 120 / 100, "Black Friday: meta +20%%")
	bf.bill.goal = 1
	bf.bill.toggle_select(bf.bill.hand[0])
	bf.pay()
	bf.next_bill()
	check(bf.price_of("agiota") == 4 and bf.price_of("gerente") == 8, "Black Friday: Banca pela metade (8 vira 4, 15 vira 8)")
	bf.leave_shop()
	check(bf.price_of("agiota") == 8, "Black Friday: o desconto acaba ao sair da Banca")
	# Malha fina: a formação mais jogada na partida não pontua.
	var malha := RunState.new(rng)
	malha.kind_counts = {"trocado": 5, "dobradinha": 2}
	malha.month_index = 5
	malha.month_boss = "malha_fina"
	malha.bill_index = 2
	malha._start_bill()
	check(malha.bill.blocked_kinds == ["trocado"], "Malha fina bloqueia a formação mais jogada (got %s)" % str(malha.bill.blocked_kinds))
	malha.bill.hand = [n(200), n(10), n(10, Note.Suit.PIX)]
	malha.bill.selected = [malha.bill.hand[0]]
	check(malha.bill.preview(malha.bill.selected)["total"] == 0, "Malha fina: Trocado não pontua")
	malha.bill.selected = [malha.bill.hand[1], malha.bill.hand[2]]
	check(malha.bill.preview(malha.bill.selected)["total"] > 0, "Malha fina: Dobradinha pontua")
	malha.pay()
	check(malha.kind_counts["dobradinha"] == 3, "a partida conta as formações jogadas")

	# Férias na praia: mão de 6 cartas.
	check(BillRound.new(999999, "ferias_praia", rng).hand.size() == 6, "Férias na praia: mão de 6 cartas")
	check(BillRound.new(999999, Boss.NONE, rng).hand.size() == Balance.HAND_SIZE, "sem chefe: mão de 8 cartas")

	# Dia dos Pais: a troca gasta um dia; a troca do último dia acaba a conta.
	var pai := BillRound.new(999999, "dia_dos_pais", rng)
	pai.toggle_select(pai.hand[0])
	pai.swap()
	check(pai.days_left == Balance.DAYS_PER_BILL - 1, "Dia dos Pais: troca gasta um dia")
	var ultimo := BillRound.new(999999, "dia_dos_pais", rng)
	ultimo.days_left = 1
	ultimo.toggle_select(ultimo.hand[0])
	ultimo.swap()
	check(ultimo.state == BillRound.LOST, "Dia dos Pais: a troca do último dia perde a conta")

	# Bandeira vermelha: Débito pontua 50% a mais. Dobradinha de 10 em Débito: (10 + 9 + 9) × 2 = 56.
	var band := BillRound.new(999999, "bandeira_vermelha", rng)
	band.hand = [n(10, Note.Suit.DEBITO), n(10, Note.Suit.DEBITO)]
	band.selected = band.hand.duplicate()
	var band_total: int = band.pay()["score"]["total"]
	check(band_total == 56, "bandeira vermelha: Débito pontua 50%% a mais (got %d)" % band_total)

	# Grosso: meta do boleto de Setembro dobra; recompensa também (base 3 + 3 dias, × 2 = 12).
	var grosso := RunState.new(rng)
	# Os chefes valem só na fatura (3ª conta do mês). Conta de teste: reward da fatura = 5 + 3 dias = 8.
	grosso.month_index = 8
	grosso.month_boss = "grosso"
	grosso.bill_index = 2
	grosso._start_bill()
	check(grosso.bill.goal == Balance.goal_of(8, "fatura") * 2, "Grosso: meta da fatura dobra (got %d)" % grosso.bill.goal)
	grosso.bill.goal = 1
	grosso.bill.toggle_select(grosso.bill.hand[0])
	grosso.pay()
	check(grosso.receipt["reward"] == 16, "Grosso: recompensa da fatura dobra (got %s)" % str(grosso.receipt["reward"]))

	# Bolsa Família (Fevereiro, fatura): meta sobe 15%; +R$3 ao pagar (5 + 3 dias + 3 = 11).
	var bolsa := RunState.new(rng)
	bolsa.month_index = 1
	bolsa.month_boss = "bolsa_familia"
	bolsa.bill_index = 2
	bolsa._start_bill()
	var bolsa_goal: int = Balance.goal_of(1, "fatura") * 115 / 100
	check(bolsa.bill.goal == bolsa_goal, "Bolsa Família: meta da fatura sobe 15%% (got %d)" % bolsa.bill.goal)
	bolsa.bill.goal = 1
	bolsa.bill.toggle_select(bolsa.bill.hand[0])
	bolsa.pay()
	check(bolsa.receipt["reward"] == 11, "Bolsa Família: +R$3 na fatura paga (got %s)" % str(bolsa.receipt["reward"]))

	# 13º (Dezembro, fatura): meta sobe 25%; recompensa +R$3 (11 com a conta de teste).
	var decimo := RunState.new(rng)
	decimo.month_index = 11
	decimo.month_boss = "decimo_terceiro"
	decimo.bill_index = 2
	decimo._start_bill()
	var decimo_goal: int = Balance.goal_of(11, "fatura") * 125 / 100
	check(decimo.bill.goal == decimo_goal, "13º: meta da fatura sobe 25%% (got %d)" % decimo.bill.goal)
	decimo.bill.goal = 1
	decimo.bill.toggle_select(decimo.bill.hand[0])
	decimo.pay()
	check(decimo.receipt["reward"] == 11, "13º: +R$3 na recompensa (got %s)" % str(decimo.receipt["reward"]))

	# Boleto de Dezembro não tem chefe: meta normal, sem o 13º.
	var sem_chefe := RunState.new(rng)
	sem_chefe.month_index = 11
	sem_chefe.bill_index = 0
	sem_chefe._start_bill()
	check(sem_chefe.bill.goal == Balance.goal_of(11, "boleto"), "boleto de Dezembro: meta normal (got %d)" % sem_chefe.bill.goal)

	# Julius (Novembro, fatura): meta cai 20% se não comprou nada no Camelô antes; sem queda se comprou.
	var julius := RunState.new(rng)
	julius.month_index = 10
	julius.month_boss = "julius"
	julius.bill_index = 2
	julius.bought_last_shop = false
	julius._start_bill()
	var julius_base: int = Balance.goal_of(10, "fatura")
	check(julius.bill.goal == julius_base * 80 / 100, "Julius: sem compra, meta cai 20%% (got %d)" % julius.bill.goal)
	julius.bought_last_shop = true
	julius._start_bill()
	check(julius.bill.goal == julius_base, "Julius: com compra, meta normal (got %d)" % julius.bill.goal)

	# Curso do Primo Rico (Abril): matrícula paga uma vez; a cada 2 contas pagas, Valor +20%.
	var curso := RunState.new(rng)
	curso.month_index = 3
	curso.month_boss = "curso_primo_rico"
	curso.bill_index = 2
	var w0 := curso.wallet
	curso._start_bill()
	check(curso.wallet == w0 - Balance.CURSO_COST and curso.curso_matriculado, "Curso: matrícula cobra R$ %d" % Balance.CURSO_COST)
	curso._start_bill()
	check(curso.wallet == w0 - Balance.CURSO_COST, "Curso: matrícula cobrada só uma vez")
	curso.curso_contas = 2
	check(curso.valor_percent() == 10, "Curso: 2 contas dão +10%% de Valor (got %d)" % curso.valor_percent())
	curso.curso_contas = 5
	check(curso.valor_percent() == 20, "Curso: 5 contas dão +20%% (got %d)" % curso.valor_percent())
	curso.curso_contas = 2
	curso._start_bill()
	check(curso.bill.valor_percent == 10, "Curso: a conta recebe o Valor extra")

	# Urubu do Pix (Maio): no começo da conta, dobra a carteira ou perde R$5.
	var urubu := RunState.new(rng)
	urubu.month_index = 4
	urubu.month_boss = "urubu_pix"
	urubu.bill_index = 2
	urubu.wallet = 10
	urubu._start_bill()
	check(urubu.wallet == 20 or urubu.wallet == 10 - Balance.URUBU_LOSS, "Urubu: dobra (20) ou perde R$5 (got %d)" % urubu.wallet)  # 10 → 20 ou 5
	check(urubu.boss_note != "", "Urubu: o resultado aparece na tela")

	# Boleto de Janeiro: sem chefe, meta normal.
	var normal := RunState.new(rng)
	normal.month_index = 0
	normal.bill_index = 0
	normal._start_bill()
	check(normal.bill.goal == Balance.goal_of(0, "boleto"), "mês sem regra de meta: meta normal")


## Prévia da seleção: mesmo valor, Juros e total que o PAGAR dá (sem a sorte da Rifa).
func _test_previa() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var b := BillRound.new(999999, "bandeira_vermelha", rng, ["cashback"], 1, {"dobradinha": 1})
	b.hand = [n(10, Note.Suit.DEBITO), n(10, Note.Suit.DEBITO), n(5)]
	b.selected = [b.hand[0], b.hand[1]]
	var prev: Dictionary = b.preview(b.selected)
	var real: Dictionary = b.pay()["score"]
	check(prev["total"] == real["total"], "prévia = total do PAGAR (%s x %s)" % [prev["total"], real["total"]])
	check(prev["juros"] == real["juros"], "prévia mostra os mesmos Juros")
	check(b.preview([]).is_empty(), "sem notas, sem prévia")
	var so_sem_pontos: BillRound = BillRound.new(999999, "banco_fora_do_ar", rng)
	so_sem_pontos.hand = [n(10, Note.Suit.PIX)]
	check(so_sem_pontos.preview([so_sem_pontos.hand[0]]).is_empty(), "nota que não pontua não tem prévia")


## Dois Carnês e Conta Conjunta: só pontuam depois do investimento; valores conferidos à mão.
func _test_formacoes_liberadas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# Dois pares: 10, 10, 20, 20 (pontos 6+6+7+7 = 26).
	var dois_pares := [n(10), n(10, Note.Suit.DEBITO), n(20), n(20, Note.Suit.CREDITO)]
	check(HandEvaluator.evaluate(dois_pares)["kind"] == "dobradinha", "sem o Carnê, dois pares vale só a Dobradinha")
	check(HandEvaluator.evaluate(dois_pares, ["dois_carnes"])["kind"] == "dois_carnes", "com o Carnê, dois pares é Dois Carnês")

	# Trinca + par (10×3 e 20×2): pontos 6×3 + 7×2 = 32. Base 35 × Juros 3 = 105 → (35 + 32) × 3 = 201.
	var full := [n(10), n(10, Note.Suit.DEBITO), n(10, Note.Suit.CREDITO), n(20), n(20, Note.Suit.DEBITO)]
	check(HandEvaluator.evaluate(full)["kind"] == "bolada", "sem a Conta Conjunta, trinca + par é Bolada")
	check(HandEvaluator.evaluate(full, ["conta_conjunta"])["kind"] == "conta_conjunta", "com a Conta Conjunta, trinca + par é Conta Conjunta")
	var cc := Scorer.score(HandEvaluator.evaluate(full, ["conta_conjunta"]))
	check(cc["total"] == 201, "Conta Conjunta sem nível = (35 + 32) × 3 = 201 (got %s)" % cc["total"])

	# Partida: o nível do investimento libera a formação e soma Valor e Juros.
	var b := BillRound.new(999999, Boss.NONE, rng, [], 0, {"dois_carnes": 1})
	check(b.unlocked() == ["dois_carnes"], "nível 1 do Carnê libera Dois Carnês")
	b.hand = dois_pares.duplicate()
	b.selected = b.hand.duplicate()
	var total: int = b.pay()["score"]["total"]
	# (15 base + 26 pontos + 10 do nível) × (2 + 1 do nível) = 153.
	check(total == 153, "Dois Carnês com nível 1 = (15 + 26 + 10) × 3 = 153 (got %s)" % total)
	var sem := BillRound.new(999999, Boss.NONE, rng)
	sem.hand = dois_pares.duplicate()
	sem.selected = sem.hand.duplicate()
	check(sem.pay()["score"]["kind"] == "dobradinha", "sem investimento a mesma mão pontua como Dobradinha")

	# Investimentos novos aparecem na ordem do Camelô e sobem o nível certo.
	check(Balance.INVESTMENT_ORDER.has("carne") and Balance.INVESTMENT_ORDER.has("conta_conjunta") and Balance.INVESTMENT_ORDER.has("fundo"), "três investimentos novos no Camelô")
	check(Investments.level_effect("bolada", 1)["value"] == 10, "Fundo de Investimento: +10 de Valor na Bolada")


func _test_assets() -> void:
	# Cada valor tem uma cédula neutra 120×180; cada forma de pagamento tem um selo 40×40.
	for value in Balance.VALUES:
		var path := n(value).face_path()
		check(ResourceLoader.exists(path), "cédula existe: %s" % path)
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			check(tex.get_width() == 120 and tex.get_height() == 224, "cédula %s tem 120x224" % path)
	for suit in Note.Suit.values():
		var spath := n(1, suit).stamp_path()
		check(ResourceLoader.exists(spath), "selo existe: %s" % spath)
		if ResourceLoader.exists(spath):
			var stex: Texture2D = load(spath)
			check(stex.get_width() == 40 and stex.get_height() == 40, "selo %s tem 40x40" % spath)


func _test_schemes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var t200 := [n(200)]  # Trocado de 200: (5 + 11) × 1 = 16

	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["agiota"]})["total"] == 64, "Agiota +3 Juros: 16 × 4 = 64")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["cunhado"], "cunhado_bonus": 6})["total"] == 64, "Cunhado com 6 Escadinhas: +3 de Juros, 16 × 4 = 64")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["cunhado"], "cunhado_bonus": 1})["total"] == 16, "Cunhado com 1 Escadinha ainda não soma: 16")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["piramide", "cunhado"]})["total"] == 32, "Pirâmide +1 por outro esquema: 16 × 2 = 32")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["agiota", "piramide"]})["total"] == 80, "Agiota + Pirâmide: 16 × 5 = 80")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["vaquinha"], "hand_points": 10})["total"] == 21, "Vaquinha soma metade (5) dos 10 pontos ao Valor: 16 + 5 = 21")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["rifa"], "rifa": true})["total"] == 80, "Rifa sorteada ×5: 16 × 5 = 80")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["rifa"], "rifa": false})["total"] == 16, "Rifa não sorteada não muda")
	# Esquemas novos (personagens brasileiros): efeitos puros.
	var d10 := Note.new(10, Note.Suit.DINHEIRO)
	var d20 := Note.new(20, Note.Suit.DINHEIRO)
	var deb := Note.new(10, Note.Suit.DEBITO)
	var deb2 := Note.new(20, Note.Suit.DEBITO)
	check(SchemeRules.score_effect("vendedor_consorcio", {"scoring": [d10, d20, deb]})["value"] == 10, "Vendedor de Consórcio: +5 por nota de Dinheiro que pontua (2 notas = 10)")
	check(SchemeRules.score_effect("tia_do_pix", {"scoring": [deb, deb2]})["add"] == 2, "Tia do Pix: +1 de Juros por nota de Débito (2 notas = 2)")
	check(SchemeRules.score_effect("tia_do_pix", {"scoring": [d10]})["add"] == 0, "Tia do Pix: sem nota de Débito não soma")
	check(SchemeRules.score_effect("pastor", {})["value"] == Balance.PASTOR_VALUE, "Pastor: Valor fixo por jogada")
	check(SchemeRules.score_effect("influenciador", {"played": 3})["add"] == 2, "Influenciador: 3 notas ativam +2 de Juros")
	check(SchemeRules.score_effect("influenciador", {"played": 2})["add"] == 0, "Influenciador: 2 notas não ativam")
	check(SchemeRules.parcelas_per_bill(["vendedor_consorcio", "pastor", "consignado"]) == 1, "Parcela fixa: só o Vendedor de Consórcio cobra (1)")
	check(SchemeRules.score_effect("consignado", {})["add"] == Balance.CONSIGNADO_JUROS, "Consignado: +1 de Juros por jogada")
	check(SchemeRules.dizimo_charge(["pastor"], 100) == 5, "Pastor cobra 5% da carteira")
	check(SchemeRules.dizimo_charge(["agiota"], 100) == 0, "Sem Pastor não há dízimo")
	check(SchemeRules.parcelas_per_bill(["agiota"]) == 0, "Esquema sem parcela não cobra")
	check(SchemeRules.score_effect("nubank", {"scoring": [Note.new(10, Note.Suit.CREDITO), Note.new(20, Note.Suit.CREDITO), d10]})["value"] == 6, "Nubank: +3 por nota de Crédito que pontua (2 notas = 6)")
	check(SchemeRules.score_effect("nubank", {"scoring": [d10]})["value"] == 0, "Nubank: sem nota de Crédito não soma")
	check(Investments.reward_bonus({"duolingo": 2}) == 4, "Duolingo: +R$ 2 de recompensa por nível (2 níveis = 4)")
	check(Investments.reward_bonus({}) == 0, "Sem Duolingo não há recompensa extra")
	check(Investments.level_effect("duolingo", 3)["value"] == 0, "Duolingo não muda a pontuação de formação alguma")
	for id in Balance.SCHEME_ORDER:
		check(Balance.RARITY_ORDER.has(Balance.SCHEMES[id]["rarity"]), "Esquema %s tem raridade válida" % id)
	for id in Balance.INVESTMENT_ORDER:
		check(Balance.RARITY_ORDER.has(Balance.INVESTMENTS[id]["rarity"]), "Investimento %s tem raridade válida" % id)
	var kinds := {}
	for id in Balance.INVESTMENT_ORDER:
		var k: String = Balance.INVESTMENTS[id]["transaction"]
		check(not kinds.has(k), "Investimento %s não divide formação com outro" % id)
		kinds[k] = true
	check(SchemeRules.score_effect("coach", {"formed": 5})["mult"] == 2, "Coach: formação de 5 notas dá ×2")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["coach"], "played": 5})["total"] == 0, "Coach: completar com notas que não pontuam não vale (perde 1 de Juros)")
	var esc5 := [n(1, Note.Suit.DINHEIRO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.CREDITO), n(10, Note.Suit.PIX), n(20, Note.Suit.DINHEIRO)]
	check(Scorer.score(HandEvaluator.evaluate(esc5), {"schemes": ["coach"]})["total"] == 2 * Scorer.score(HandEvaluator.evaluate(esc5))["total"], "Coach: Escadinha de 5 notas rende o dobro")
	check(Scorer.score(HandEvaluator.evaluate(t200), {"schemes": ["coach"], "played": 1})["total"] == 0, "Coach com menos de 5 perde 1 de Juros: 0")

	check(SchemeRules.agiota_charge(100) == 10, "Agiota cobra 10% de R$ 100")
	check(SchemeRules.agiota_charge(5) == 0, "Agiota não cobra de carteira baixa")
	check(SchemeRules.agiota_charge(-4) == 0, "Agiota não cobra com dívida")

	# Cashback: notas de Crédito que pontuam devolvem R$ 1 cada.
	var cash_bill := BillRound.new(999999, Boss.NONE, rng, ["cashback"])
	cash_bill.hand = [n(10, Note.Suit.CREDITO), n(20, Note.Suit.CREDITO), n(5, Note.Suit.DINHEIRO)]
	cash_bill.selected = [cash_bill.hand[0], cash_bill.hand[1]]
	check(cash_bill.pay()["cash"] == 2, "Cashback devolve R$1 por nota de Crédito que pontua")

	# Pix Errado: a primeira nota de Pix jogada é copiada para o baralho (uma vez por conta).
	# Baralho controlado: conta as notas em baralho, descarte e mão (não muda com as compras).
	var copy_on := _rel_bill(["relampago_errado"], rng)
	var before := _count_rel10(copy_on)
	copy_on.pay()
	check(_count_rel10(copy_on) - before == 1, "Pix Errado adiciona 1 cópia ao baralho")

	var copy_off := _rel_bill([], rng)
	before = _count_rel10(copy_off)
	copy_off.pay()
	check(_count_rel10(copy_off) - before == 0, "sem o esquema não há cópia")

	# Cunhado: cada Escadinha jogada soma 1 ao acumulado da partida.
	var cun := RunState.new(rng)
	cun.schemes = ["cunhado"]
	cun.bill.hand = [n(1, Note.Suit.DINHEIRO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.CREDITO), n(10, Note.Suit.PIX), n(20, Note.Suit.DINHEIRO)]
	cun.bill.selected = cun.bill.hand.duplicate()
	cun.pay()
	check(cun.cunhado_bonus == 1, "Cunhado conta 1 Escadinha jogada")

	# Golpe do WhatsApp (fatura de Janeiro): 1 esquema some da conta, não da partida.
	var golpe := RunState.new(rng)
	golpe.schemes = ["agiota", "cunhado"]
	golpe.month_index = 0  # Janeiro
	golpe.month_boss = "janeiro_impostos"
	golpe.bill_index = 2
	golpe._start_bill()
	check(golpe.bill.schemes.size() == 1 and golpe.schemes.size() == 2, "Golpe do WhatsApp desativa 1 esquema só nesta conta")

	# Camelô: comprar, vender, pechinchar e cheque especial.
	var shop := RunState.new(rng)
	shop.bill.goal = 1
	shop.bill.toggle_select(shop.bill.hand[0])
	shop.pay()
	check(shop.next_bill() and shop.shop_offer.size() == Balance.SHOP_OFFERS + Balance.SHOP_INVESTMENT_OFFERS, "Camelô abre com 2 esquemas e 1 investimento")
	var offer_id: String = shop.shop_offer[0]
	var price: int = Balance.SCHEMES[offer_id]["price"]
	shop.wallet = 100  # com dinheiro na carteira: sem usar o cheque especial
	var w0 := shop.wallet
	check(shop.buy(0)["ok"] and shop.schemes == [offer_id] and shop.wallet == w0 - price, "compra desconta o preço")
	check(shop.sell(0)["ok"] and shop.schemes.is_empty() and shop.wallet == w0 - price + price / 2, "venda devolve metade do preço")
	var w1 := shop.wallet
	check(shop.haggle()["ok"] and shop.wallet == w1 - Balance.HAGGLE_COST, "pechinchar custa R$ 2")

	# Cheque especial na compra: "cunhado" custa R$ 10. Com R$ 5 na carteira, o cheque cobre R$ 5 (dívida 15).
	shop.shop_offer = ["cunhado", "agiota", "poupanca"]
	shop.schemes = []
	shop.wallet = 5
	shop.overdraft_left = Balance.OVERDRAFT_START
	check(shop.buy(0)["ok"] and shop.wallet == -15 and shop.overdraft_left == 5, "compra no cheque: dívida 3x e limite diminui")
	shop.schemes = []
	shop.shop_offer = ["cunhado", "agiota", "poupanca"]
	shop.wallet = 0
	shop.overdraft_left = 5
	check(shop.buy(0)["reason"] == "no_money", "compra recusada se o limite restante não cobre")

	# Contatos: depois do boleto, um só por vez (sorteado). Gerente baixa o juros; Sem Fundo tira o limite.
	var ct := RunState.new(rng)
	ct.bill.goal = 1
	ct.bill.toggle_select(ct.bill.hand[0])
	ct.pay()
	ct.next_bill()
	check(ct.contact_offer.size() == 1 and Balance.CONTACT_ORDER.has(ct.contact_offer[0]), "depois do boleto, um contato é oferecido (sorteado)")
	var first: String = ct.contact_offer[0]
	ct.wallet = 100
	check(ct.buy_contact(first)["ok"] and ct.wallet == 100 - Balance.CONTACTS[first]["price"] and ct.contacts_owned == [first], "compra o contato pelo preço")
	check(ct.contact_offer.is_empty(), "comprado o contato, a oferta some")
	ct.leave_shop()
	check(ct.contact_offer.is_empty(), "contatos não ficam para a loja seguinte")

	# Próximo mês: só o que falta é oferecido; com os dois comprados, nada.
	var ct2 := RunState.new(rng)
	ct2.contacts_owned = ["gerente"]
	ct2.bill.goal = 1
	ct2.bill.toggle_select(ct2.bill.hand[0])
	ct2.pay()
	ct2.next_bill()
	check(ct2.contact_offer == ["sem_fundo"], "com o Gerente comprado, só o Sem Fundo é oferecido")
	var ct3 := RunState.new(rng)
	ct3.contacts_owned = ["gerente", "sem_fundo"]
	ct3.bill.goal = 1
	ct3.bill.toggle_select(ct3.bill.hand[0])
	ct3.pay()
	ct3.next_bill()
	check(ct3.contact_offer.is_empty(), "com os dois comprados, nenhum é oferecido")

	var gerente_run := RunState.new(rng)
	gerente_run.contacts_owned = ["gerente"]
	check(gerente_run.overdraft_juros() == 2 and not gerente_run.overdraft_unlimited(), "Gerente baixa o juros para 2x")
	var sem_fundo_run := RunState.new(rng)
	sem_fundo_run.contacts_owned = ["sem_fundo"]
	sem_fundo_run.wallet = 0
	check(sem_fundo_run.overdraft_unlimited() and sem_fundo_run.can_spend(500), "Sem Fundo: cheque sem limite")
	sem_fundo_run._spend(500)
	check(sem_fundo_run.wallet == -1000 and sem_fundo_run.overdraft_left == Balance.OVERDRAFT_START, "Sem Fundo: juros 2x e limite intacto")
	var back := RunState.from_dict(ct.to_dict())
	check(back.contacts_owned == ct.contacts_owned and back.overdraft_left == ct.overdraft_left, "contatos e cheque sobrevivem ao salvar")

	shop.wallet = 100
	shop.schemes = ["agiota", "cunhado", "coach", "piramide", "rifa"]
	shop.shop_offer = ["vaquinha"]
	check(shop.buy(0)["reason"] == "slots_full", "no máximo 5 esquemas ativos")


## Conta com baralho e mão conhecidos, para testar duplicação de notas.
func _rel_bill(p_schemes: Array, rng: RandomNumberGenerator) -> BillRound:
	var bill := BillRound.new(999999, Boss.NONE, rng, p_schemes)
	bill.deck.draw_pile = [n(1, Note.Suit.DEBITO), n(2, Note.Suit.CREDITO), n(5, Note.Suit.DINHEIRO)]
	bill.deck.discard_pile = []
	bill.hand = [n(10, Note.Suit.PIX), n(20, Note.Suit.DEBITO)]
	bill.selected = [bill.hand[0]]
	return bill


## Quantas notas R$10 Pix existem na conta (baralho + descarte + mão).
func _count_rel10(bill: BillRound) -> int:
	var total := 0
	for pile in [bill.deck.draw_pile, bill.deck.discard_pile, bill.hand]:
		for c in pile:
			if c.value == 10 and c.suit == Note.Suit.PIX:
				total += 1
	return total


## A animação soma Valor e Juros pelos eventos: o resultado tem que bater com o total.
func _test_score_events() -> void:
	print("\n-- eventos da pontuação --")
	var cards := [n(10, Note.Suit.DINHEIRO), n(10, Note.Suit.CREDITO)]
	var fx := {"schemes": ["agiota", "cunhado"], "levels": {"dobradinha": 2}, "cunhado_bonus": 1}
	var s := Scorer.score({"kind": "dobradinha", "cards": cards}, fx)
	var value := 0
	var juros := 0
	var mult := 1
	for ev in s["events"]:
		match ev["type"]:
			"base":
				value = ev["amount"]
				juros = ev["juros"]
			"note", "invest":
				value += ev["amount"] if ev["type"] == "note" else ev["value"]
				juros += 0 if ev["type"] == "note" else ev["add"]
			"scheme":
				value += ev["value"]
				juros += ev["add"]
				mult *= ev["mult"]
	check(juros == s["juros"], "eventos somam o Juros final")
	check(value * juros * mult == s["total"], "eventos somam o total")


func _test_investments() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	# Níveis somam Valor e Juros só na transação do investimento.
	var pair := [n(10), n(10, Note.Suit.DEBITO)]  # Dobradinha de 10: (10 + 12) × 2 = 44
	check(Scorer.score(HandEvaluator.evaluate(pair), {"levels": {"dobradinha": 1}})["total"] == 96, "Poupança nível 1: (10+12+10) × 3 = 96")
	check(Scorer.score(HandEvaluator.evaluate(pair), {"levels": {"escadinha": 1}})["total"] == 44, "nível de outra transação não muda a Dobradinha")

	var esc := [n(1), n(2, Note.Suit.DEBITO), n(5), n(10, Note.Suit.CREDITO), n(20, Note.Suit.PIX)]  # Escadinha: (25+23) × 3 = 144
	check(Scorer.score(HandEvaluator.evaluate(esc), {"levels": {"escadinha": 1}})["total"] == 340, "Tesouro nível 1: (25+23+20) × 5 = 340")

	var flush := [n(1, Note.Suit.DEBITO), n(2, Note.Suit.DEBITO), n(5, Note.Suit.DEBITO), n(10, Note.Suit.DEBITO), n(20, Note.Suit.DEBITO)]
	check(Scorer.score(HandEvaluator.evaluate(flush), {"levels": {"tudo_no_pix": 1}})["total"] == 686, "Cripto nível 1: (35+23+40) × 7 = 686")

	check(Investments.level_effect("nenhuma", 3) == {"value": 0, "juros": 0}, "transação sem investimento não ganha nada")

	# Compra e queda do Cripto.
	check(Investments.level_after_purchase("poupanca", 2, true) == 3, "Poupança sempre sobe")
	check(Investments.level_after_purchase("cripto", 2, false) == 3, "Cripto sem sorteio sobe")
	check(Investments.level_after_purchase("cripto", 2, true) == 1, "Cripto sorteado cai um nível")
	check(Investments.level_after_purchase("cripto", 0, true) == 0, "nível não fica abaixo de zero")

	# Comprar no Camelô aumenta o nível da transação.
	var shop := RunState.new(rng)
	shop.bill.goal = 1
	shop.bill.toggle_select(shop.bill.hand[0])
	shop.pay()
	shop.next_bill()
	shop.shop_offer = ["poupanca"]
	shop.wallet = 20
	var r := shop.buy(0)
	check(r["ok"] and shop.levels.get("dobradinha", 0) == 1 and shop.wallet == 14, "comprar Poupança sobe Dobradinha e cobra R$ 6")
	check(shop.shop_offer[0] == "", "investimento comprado deixa o espaço vazio (as outras ofertas não se mexem)")
	check(not shop.buy(0)["ok"], "espaço vazio não pode ser comprado de novo")

