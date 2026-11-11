class_name Boss
extends RefCounted
## Regras dos chefes (um por mês, só na fatura). Cada função recebe o id do chefe;
## "" = sem chefe. Nome e texto ficam em Balance.BOSSES; os números ficam em Balance.
##
## Nível do chefe (0 a 3): cresce com o mês em que ele cai. Os chefes de Balance.BOSS_SCALE
## usam um número diferente em cada nível (dificuldade adaptativa).

const NONE := ""


## Nível do chefe no mês `month_index` (0 = Janeiro da partida): sobe a cada 2 meses, até 3.
static func level_of(month_index: int) -> int:
	return mini(month_index / 2, Balance.BOSS_MAX_LEVEL)


## Número do chefe no nível dado (ex.: Inflação = % que a meta sobe por jogada). 0 se o chefe não escala.
static func level_value(boss: String, level: int) -> int:
	if not Balance.BOSS_SCALE.has(boss):
		return 0
	var values: Array = Balance.BOSS_SCALE[boss]
	return int(values[clampi(level, 0, values.size() - 1)])


## Notas que o chefe não deixa pontuar: uma forma de pagamento ou uma faixa de valor.
static func note_scores(boss: String, note: Note) -> bool:
	match boss:
		"banco_fora_do_ar":
			return note.suit != Note.Suit.PIX
		"maquininha_quebrada":
			return note.suit != Note.Suit.DEBITO
		"cartao_clonado":
			return note.suit != Note.Suit.CREDITO
		"caixa_sem_troco":
			return note.suit != Note.Suit.DINHEIRO
		"troco_em_bala":
			return note.value > Balance.TROCO_BALA_MAX
		"nota_falsa":
			return note.value < Balance.NOTA_FALSA_MIN
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


## Dias da conta (Feriadão e Copa do Mundo têm menos).
static func days(boss: String) -> int:
	match boss:
		"feriadao":
			return Balance.FERIADAO_DAYS
		"copa_do_mundo":
			return Balance.COPA_DAYS
	return Balance.DAYS_PER_BILL


## Trocas da conta (Fila da lotérica e Copa do Mundo têm menos).
static func swaps(boss: String) -> int:
	match boss:
		"fila_loterica":
			return Balance.SWAPS_PER_BILL - 1
		"copa_do_mundo":
			return Balance.COPA_SWAPS
	return Balance.SWAPS_PER_BILL


## Bandeira vermelha: notas de Débito pontuam mais.
static func debito_bonus(boss: String) -> bool:
	return boss == "bandeira_vermelha"


## Bandeira vermelha: cada dia usado custa R$ na carteira.
static func day_cost(boss: String) -> int:
	if boss == "bandeira_vermelha":
		return Balance.BANDEIRA_DAY_COST
	return 0


## Meta da conta em porcentagem da meta do mês.
## `shopped` = o jogador comprou algo na Banca antes; `wallet` = carteira ao começar a conta.
static func goal_percent(boss: String, shopped: bool, level: int = 0, wallet: int = 0) -> int:
	match boss:
		"grosso":
			return Balance.GROSSO_PERCENT
		"bolsa_familia":
			return Balance.BOLSA_GOAL_PERCENT
		"decimo_terceiro":
			return Balance.DECIMO_GOAL_PERCENT
		"julius":
			return Balance.JULIUS_PERCENT if not shopped else 100
		"reajuste_aluguel":
			return 100 + level_value(boss, level)
		"serasa":
			return 100 + level_value(boss, level) if wallet < 0 else 100
		"black_friday":
			return Balance.BLACK_FRIDAY_GOAL_PERCENT
	return 100


## Parte da carteira (em %) que o chefe leva no começo da conta. Só com carteira positiva.
static func wallet_loss_percent(boss: String, level: int) -> int:
	if boss == "golpe_falso_gerente" or boss == "plano_collor":
		return level_value(boss, level)
	return 0


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


## Recompensa final em % (Dia das Mães fica com metade).
static func reward_percent(boss: String) -> int:
	if boss == "dia_das_maes":
		return Balance.MAES_REWARD_PERCENT
	return 100


## Sogra em casa: só pontua jogada com exatamente MAX_PLAYED notas.
static func needs_full_play(boss: String) -> bool:
	return boss == "sogra_em_casa"


## Rotina: cada formação só pode ser jogada uma vez na conta.
static func one_kind_each(boss: String) -> bool:
	return boss == "rotina"


## Wi-Fi caiu: os esquemas ficam desligados na jogada de número `plays` (0 = primeira)?
static func schemes_off(boss: String, level: int, plays: int) -> bool:
	return boss == "wifi_caiu" and plays < level_value(boss, level)


## Carnaval: depois de cada jogada, a mão inteira é trocada.
static func redraws_hand(boss: String) -> bool:
	return boss == "carnaval"


## Apagão: a prévia da jogada não aparece.
static func hides_preview(boss: String) -> bool:
	return boss == "apagao"


## Tigrinho: a jogada é sorteada (dobra ou cai pela metade).
static func rolls_play(boss: String) -> bool:
	return boss == "tigrinho"


## Total da jogada depois da regra do chefe.
## `plays` = jogadas já feitas na conta; `roll` = sorteio do Tigrinho (1 ganhou, 0 perdeu, -1 sem sorteio, na prévia).
static func adjust_total(boss: String, level: int, total: int, plays: int, goal: int, roll: int = -1) -> int:
	match boss:
		"boleto_vencido":
			return total / 2 if plays == 0 else total
		"tigrinho":
			if roll == 1:
				return total * 2
			if roll == 0:
				return total / 2
			return total
		"fatura_parcelada":
			return mini(total, goal * level_value(boss, level) / 100)
	return total


## Inflação: quanto a meta sobe (em %) depois de cada jogada que não paga a conta.
static func goal_growth_percent(boss: String, level: int) -> int:
	if boss == "inflacao":
		return level_value(boss, level)
	return 0
