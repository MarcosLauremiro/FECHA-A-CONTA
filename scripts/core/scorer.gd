class_name Scorer
extends RefCounted
## Função pura: calcula o saldo de uma jogada e devolve uma lista de eventos.
## A animação (fase de "sensação") só toca essa lista; regra e visual ficam separados.
##
## Saldo = (Valor base + soma dos pontos das notas que pontuam) × Juros
## Esquemas ainda não entram aqui (virão com o sistema de ganchos, hora 9–12).

static func score(evaluation: Dictionary) -> Dictionary:
	var kind: String = evaluation["kind"]
	var events: Array = []

	if kind == "none":
		events.append({"type": "total", "value": 0})
		return {"kind": kind, "base": 0, "points": 0, "juros": 0, "total": 0, "events": events}

	var tx: Dictionary = Balance.TRANSACTIONS[kind]
	var base: int = tx["base"]
	var juros: int = tx["juros"]

	events.append({"type": "base", "amount": base})

	var points := 0
	var cards: Array = evaluation["cards"]
	for i in range(cards.size()):
		var pts: int = cards[i].points()
		points += pts
		events.append({"type": "note", "index": i, "amount": pts})

	# Esquemas somariam Juros aqui (antes) e multiplicariam depois.
	events.append({"type": "juros", "value": juros})

	var total := (base + points) * juros
	events.append({"type": "total", "value": total})

	return {"kind": kind, "base": base, "points": points, "juros": juros, "total": total, "events": events}
