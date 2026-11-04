class_name Investments
extends RefCounted
## Investimentos do Camelô: cada um sobe o nível de uma transação (Dobradinha, Escadinha
## ou Tudo no Relâmpago). Funções puras; o sorteio do Cripto é passado por quem chama.
##
## Níveis ficam em um Dictionary {transação: nível}, na partida toda.

static func is_investment(id: String) -> bool:
	return Balance.INVESTMENTS.has(id)


## Valor e Juros que o nível de uma transação soma numa jogada dela.
static func level_effect(kind: String, level: int) -> Dictionary:
	for id in Balance.INVESTMENTS:
		var inv: Dictionary = Balance.INVESTMENTS[id]
		if inv["transaction"] == kind:
			return {"value": level * int(inv["per_value"]), "juros": level * int(inv["per_juros"])}
	return {"value": 0, "juros": 0}


## Novo nível depois de comprar o investimento `id`.
## drop: true quando o Cripto sorteou a queda (cai um nível em vez de subir). Nunca abaixo de zero.
static func level_after_purchase(id: String, level: int, drop: bool) -> int:
	if id == "cripto" and drop:
		return maxi(0, level - 1)
	return level + 1


static func transaction_of(id: String) -> String:
	return Balance.INVESTMENTS[id]["transaction"]
