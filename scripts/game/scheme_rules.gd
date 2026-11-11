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
			eff["add"] = int(fx.get("cunhado_bonus", 0)) / Balance.CUNHADO_STEP
		"piramide":
			# +1 para cada outro esquema ativo.
			eff["add"] = fx["schemes"].size() - 1
		"coach":
			# Só vale quando a formação usa as 5 notas (não adianta completar com nota que não pontua).
			if int(fx.get("formed", 0)) == Balance.MAX_PLAYED:
				eff["mult"] = Balance.COACH_MULT
			else:
				eff["add"] = -1
		"vaquinha":
			eff["value"] = int(fx.get("hand_points", 0)) * Balance.VAQUINHA_PERCENT / 100
		"rifa":
			if bool(fx.get("rifa", false)):
				eff["mult"] = Balance.RIFA_MULT
		"vendedor_consorcio":
			eff["value"] = Balance.CONSORCIO_VALUE * _count_suit(fx, Note.Suit.DINHEIRO)
		"tia_do_pix":
			eff["add"] = Balance.TIA_PIX_JUROS * _count_suit(fx, Note.Suit.DEBITO)
		"consignado":
			eff["add"] = Balance.CONSIGNADO_JUROS
		"nubank":
			eff["value"] = Balance.NUBANK_VALUE * _count_suit(fx, Note.Suit.CREDITO)
		"pastor":
			eff["value"] = Balance.PASTOR_VALUE
		"influenciador":
			if int(fx.get("played", 0)) >= Balance.INFLUENCIADOR_MIN_NOTAS:
				eff["add"] = Balance.INFLUENCIADOR_JUROS
	return eff


## Notas que pontuam de um naipe (fx["scoring"], as notas da jogada que pontuam).
static func _count_suit(fx: Dictionary, suit: int) -> int:
	var total := 0
	for n in fx.get("scoring", []):
		if n.suit == suit:
			total += 1
	return total


## Parcelas fixas que os esquemas cobram a cada conta paga (Vendedor de Consórcio).
static func parcelas_per_bill(schemes: Array) -> int:
	var total := 0
	if schemes.has("vendedor_consorcio"):
		total += Balance.CONSORCIO_PARCELA
	return total


## Dízimo do Pastor a cada conta paga: % da carteira, só com saldo positivo.
static func dizimo_charge(schemes: Array, wallet: int) -> int:
	if not schemes.has("pastor") or wallet <= 0:
		return 0
	return wallet * Balance.PASTOR_PERCENT / 100


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
