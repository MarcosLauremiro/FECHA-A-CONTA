class_name Boss
extends RefCounted
## Regras das faturas (chefes). Cada função recebe o id do chefe; "" = sem chefe.
## Texto e nome ficam em Balance.BOSSES.

const NONE := ""


## Notas de Relâmpago não pontuam na fatura do Banco fora do ar.
static func note_scores(boss: String, note: Note) -> bool:
	if boss == "banco_fora_do_ar" and note.suit == Note.Suit.RELAMPAGO:
		return false
	return true


## Imposto (Leão da Receita) tirado do total de cada jogada. Devolve o valor a tirar.
static func play_tax(boss: String, total: int) -> int:
	if boss == "janeiro_impostos":
		return total * Balance.LEAO_PER_MILLE / 1000
	return 0


## Quanto custa cada troca em R$.
static func swap_cost(boss: String) -> int:
	if boss == "taxa_manutencao" or boss == "janeiro_impostos":
		return 1
	return 0
