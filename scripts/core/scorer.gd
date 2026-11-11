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
##   levels: {transação: nível} dos investimentos (Poupança, Tesouro, Cripto)

## Eventos (para a animação, em ordem): base (com Juros base), note (uma por nota que pontua),
## invest (soma do investimento), scheme (uma por esquema), juros (Juros final), total.
## Somando Valor e Juros desses eventos na ordem, chega-se ao total.
static func score(evaluation: Dictionary, fx: Dictionary = {}) -> Dictionary:
	var kind: String = evaluation["kind"]
	var events: Array = []

	if kind == "none":
		events.append({"type": "total", "value": 0})
		return {"kind": kind, "base": 0, "points": 0, "juros": 0, "total": 0, "events": events}

	var tx: Dictionary = Balance.TRANSACTIONS[kind]
	var base: int = tx["base"]
	var juros: int = tx["juros"]

	events.append({"type": "base", "amount": base, "juros": juros})

	var points := 0
	var cards: Array = evaluation["cards"]
	var debito_bonus: bool = fx.get("debito_bonus", false)
	for i in range(cards.size()):
		var pts: int = cards[i].points()
		# Bandeira vermelha: notas de Débito pontuam a mais.
		if debito_bonus and cards[i].suit == Note.Suit.DEBITO:
			pts += pts * Balance.BANDEIRA_DEBITO_PERCENT / 100
		points += pts
		events.append({"type": "note", "index": i, "amount": pts, "card": cards[i]})

	# Somas (Valor e Juros) primeiro: nível de investimento desta transação.
	var levels: Dictionary = fx.get("levels", {})
	var inv := Investments.level_effect(kind, int(levels.get(kind, 0)))
	var value_add: int = inv["value"]
	var juros_add: int = inv["juros"]
	var mult := 1
	events.append({"type": "invest", "value": inv["value"], "add": inv["juros"]})

	# Esquemas: somas, depois multiplicações.
	var schemes: Array = fx.get("schemes", [])
	var scheme_fx := fx.duplicate()
	scheme_fx["formed"] = cards.size()  # notas que entram na formação (Coach)
	for id in schemes:
		var eff := SchemeRules.score_effect(id, scheme_fx)
		value_add += eff["value"]
		juros_add += eff["add"]
		mult *= eff["mult"]
		events.append({"type": "scheme", "id": id, "value": eff["value"], "add": eff["add"], "mult": eff["mult"]})

	# Curso do Primo Rico: Valor extra em porcentagem, depois das somas e antes dos Juros.
	var pre := base + points + value_add
	var boss_value: int = pre * int(fx.get("valor_percent", 0)) / 100
	if boss_value > 0:
		events.append({"type": "boss", "value": boss_value})

	var juros_final := maxi(0, juros + juros_add)
	events.append({"type": "juros", "value": juros_final})

	var total := (pre + boss_value) * juros_final * mult
	events.append({"type": "total", "value": total})

	return {"kind": kind, "base": base, "points": points, "juros": juros_final, "total": total, "events": events}
