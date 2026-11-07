class_name Boss
extends RefCounted
## Regras dos chefes (um por mês, só na fatura). Cada função recebe o id do chefe;
## "" = sem chefe. Nome e texto ficam em Balance.BOSSES; os números ficam em Balance.

const NONE := ""


## Notas de Pix não pontuam no mês do Banco fora do ar.
static func note_scores(boss: String, note: Note) -> bool:
	if boss == "banco_fora_do_ar" and note.suit == Note.Suit.PIX:
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


## Dia dos Pais: cada troca também consome um dia.
static func swap_costs_day(boss: String) -> bool:
	return boss == "dia_dos_pais"


## Férias na praia: a mão tem menos cartas.
static func hand_size(boss: String) -> int:
	if boss == "ferias_praia":
		return Balance.FERIAS_HAND
	return Balance.HAND_SIZE


## Bandeira vermelha: notas de Débito pontuam mais.
static func debito_bonus(boss: String) -> bool:
	return boss == "bandeira_vermelha"


## Bandeira vermelha: cada dia usado custa R$ na carteira.
static func day_cost(boss: String) -> int:
	if boss == "bandeira_vermelha":
		return Balance.BANDEIRA_DAY_COST
	return 0


## Meta da conta em porcentagem da meta do mês. `shopped` = o jogador comprou algo no Camelô antes.
static func goal_percent(boss: String, shopped: bool) -> int:
	match boss:
		"grosso":
			return Balance.GROSSO_PERCENT
		"bolsa_familia":
			return Balance.BOLSA_GOAL_PERCENT
		"decimo_terceiro":
			return Balance.DECIMO_GOAL_PERCENT
		"julius":
			return Balance.JULIUS_PERCENT if not shopped else 100
	return 100


## Recompensa da conta: multiplicador e bônus fixo em R$ (aplicados quando a conta é paga).
static func reward_mult(boss: String) -> int:
	if boss == "grosso":
		return 2
	return 1


static func reward_bonus(boss: String) -> int:
	if boss == "bolsa_familia":
		return Balance.BOLSA_BONUS
	if boss == "decimo_terceiro":
		return Balance.DECIMO_BONUS
	return 0
