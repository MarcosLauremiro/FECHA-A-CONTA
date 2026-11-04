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

	t = HandEvaluator.evaluate([n(1), n(5), n(20), n(100), n(200)])
	check(t["kind"] == "trocado", "5 valores sem sequência e mesma forma ausente vira Trocado")

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
