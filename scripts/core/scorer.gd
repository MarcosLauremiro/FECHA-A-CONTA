class_name Scorer
extends RefCounted
## Função pura: calcula o saldo de uma jogada e devolve uma lista de eventos.
## A animação (fase de "sensação") só toca essa lista; regra e visual ficam separados.
##
## Saldo = (Valor base + pontos das notas + Valor dos esquemas) × Juros × multiplicadores
##
## fx (opcional, todos os campos opcionais):
##   schemes: Array de ids de esquemas ativos, da esquerda para a direita
##   played: quantas notas foram jogadas (inclui as que não pontuam)
##   hand_points: pontos das notas que ficaram na mão (Vaquinha)
##   cunhado_bonus: Juros acumulado do Cunhado Investidor
##   rifa: se a Rifa do Bairro sorteou (decidido por quem chama)

static func score(evaluation: Dictionary, fx: Dictionary = {}) -> Dictionary:
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

	# Esquemas: somas (Valor e Juros) primeiro, multiplicações depois.
	var schemes: Array = fx.get("schemes", [])
	var value_add := 0
	var juros_add := 0
	var mult := 1
	for id in schemes:
		var eff := SchemeRules.score_effect(id, fx)
		value_add += eff["value"]
		juros_add += eff["add"]
		mult *= eff["mult"]
		events.append({"type": "scheme", "id": id, "value": eff["value"], "add": eff["add"], "mult": eff["mult"]})

	var juros_final := maxi(0, juros + juros_add)
	events.append({"type": "juros", "value": juros_final})

	var total := (base + points + value_add) * juros_final * mult
	events.append({"type": "total", "value": total})

	return {"kind": kind, "base": base, "points": points, "juros": juros_final, "total": total, "events": events}
