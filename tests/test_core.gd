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
	var bill := BillRound.new(1, rng)
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
	var lost := BillRound.new(999999, rng)
	for day in range(4):
		lost.toggle_select(lost.hand[0])
		lost.pay()
	check(lost.state == BillRound.LOST, "perde ao acabar os 4 dias")
	check(lost.reward(3) == 0, "conta perdida não paga recompensa")

	# Trocas: 3 permitidas, a 4ª é recusada e nenhuma gasta dia.
	var swapper := BillRound.new(999999, rng)
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
