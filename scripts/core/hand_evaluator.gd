class_name HandEvaluator
extends RefCounted
## Função pura: recebe de 1 a 5 notas e devolve a transação e as notas que pontuam.
## Resultado: {"kind": String (id em Balance.TRANSACTIONS, ou "none"), "cards": Array[Note]}


static func evaluate(hand: Array) -> Dictionary:
	if hand.is_empty():
		return _result("none", [])

	# Todas as combinações possíveis; a melhor vence.
	var candidates: Array = []

	# Trocado: sempre existe, pontua a carta de maior valor.
	var highest: Note = hand[0]
	for n in hand:
		if n.value > highest.value:
			highest = n
	candidates.append(_result("trocado", [highest]))

	# Dobradinha / Bolada / Cofrinho: grupos de mesmo valor.
	var by_value := {}
	for n in hand:
		if not by_value.has(n.value):
			by_value[n.value] = []
		by_value[n.value].append(n)
	for v in by_value:
		var group: Array = by_value[v]
		if group.size() >= 2:
			candidates.append(_result("dobradinha", group.slice(0, 2)))
		if group.size() >= 3:
			candidates.append(_result("bolada", group.slice(0, 3)))
		if group.size() >= 4:
			candidates.append(_result("cofrinho", group.slice(0, 4)))

	if hand.size() == 5:
		if _is_sequence(hand):
			candidates.append(_result("escadinha", hand.duplicate()))
		if _is_same_suit(hand):
			candidates.append(_result("tudo_no_relampago", hand.duplicate()))

	var best: Dictionary = candidates[0]
	for c in candidates:
		if _strength(c) > _strength(best):
			best = c
	return best


static func _result(kind: String, cards: Array) -> Dictionary:
	return {"kind": kind, "cards": cards}


static func _is_sequence(hand: Array) -> bool:
	var ranks: Array = []
	for n in hand:
		ranks.append(n.rank())
	ranks.sort()
	for i in range(ranks.size() - 1):
		if ranks[i + 1] != ranks[i] + 1:
			return false
	return true


static func _is_same_suit(hand: Array) -> bool:
	for n in hand:
		if n.suit != hand[0].suit:
			return false
	return true


## Ordena candidatas: primeiro pelo base × Juros base, depois pela soma de pontos.
## Pontos somam no máximo 55 (5 notas de 11), por isso ×1000 não colide.
static func _strength(evaluation: Dictionary) -> int:
	var kind: String = evaluation["kind"]
	if kind == "none":
		return 0
	var tx: Dictionary = Balance.TRANSACTIONS[kind]
	var points := 0
	for n in evaluation["cards"]:
		points += n.points()
	return int(tx["base"]) * int(tx["juros"]) * 1000 + points
