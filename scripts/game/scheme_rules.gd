class_name SchemeRules
extends RefCounted
## Efeitos dos esquemas (funções puras). Quem sorteia (rifa, pirâmide, golpe) passa
## o resultado pronto no contexto, então aqui não há aleatoriedade.
##
## Ordem na pontuação (GDD): somas (Valor e Juros) antes, multiplicações depois.

## Efeito de um esquema numa jogada.
## fx: {"schemes": Array, "played": int, "hand_points": int, "cunhado_bonus": int, "rifa": bool}
## Devolve {"add": Juros somado, "value": Valor somado, "mult": multiplicador de Juros}.
static func score_effect(id: String, fx: Dictionary) -> Dictionary:
	var eff := {"add": 0, "value": 0, "mult": 1}
	match id:
		"agiota":
			eff["add"] = Balance.AGIOTA_JUROS
		"cunhado":
			eff["add"] = int(fx.get("cunhado_bonus", 0))
		"piramide":
			# +1 para cada outro esquema ativo.
			eff["add"] = fx["schemes"].size() - 1
		"coach":
			if int(fx.get("played", 0)) == Balance.MAX_PLAYED:
				eff["mult"] = Balance.COACH_MULT
			else:
				eff["add"] = -1
		"vaquinha":
			eff["value"] = int(fx.get("hand_points", 0))
		"rifa":
			if bool(fx.get("rifa", false)):
				eff["mult"] = Balance.RIFA_MULT
	return eff


## Dinheiro que a jogada devolve na carteira (Cashback): R$ 1 por nota de Crédito que pontua.
static func cash_from_scoring(schemes: Array, scoring: Array) -> int:
	if not schemes.has("cashback"):
		return 0
	var total := 0
	for n in scoring:
		if n.suit == Note.Suit.CREDITO:
			total += 1
	return total


## Cobrança do Agiota a cada conta paga: % da carteira, só com saldo positivo.
static func agiota_charge(wallet: int) -> int:
	if wallet <= 0:
		return 0
	return wallet * Balance.AGIOTA_PERCENT / 100
