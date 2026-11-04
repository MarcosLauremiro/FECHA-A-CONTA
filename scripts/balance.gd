class_name Balance
extends RefCounted
## Todos os números de regra do jogo em um lugar só (GDD: "Dados de esquemas,
## preços e metas num único balance.gd"). Ajustar aqui, não caçar número no código.

# Valores das notas, em ordem crescente (também define a sequência da Escadinha).
const VALUES: Array = [1, 2, 5, 10, 20, 50, 100, 200]

# Pontos de Valor de cada nota.
const VALUE_POINTS := {1: 2, 2: 3, 5: 5, 10: 6, 20: 7, 50: 8, 100: 10, 200: 11}

# Formas de pagamento ("naipes"). Índice = valor de Note.suit.
const SUIT_NAMES: Array = ["Dinheiro", "Relâmpago", "Débito", "Crédito"]
# Chave usada nos nomes de arquivo das frentes (frente_<valor>_<chave>.png).
const SUIT_KEYS: Array = ["dinheiro", "relampago", "debito", "credito"]

# Transações: valor base e Juros base (multiplicador inicial).
const TRANSACTIONS := {
	"trocado": {"name": "Trocado", "base": 5, "juros": 1},
	"dobradinha": {"name": "Dobradinha", "base": 10, "juros": 2},
	"bolada": {"name": "Bolada", "base": 30, "juros": 3},
	"escadinha": {"name": "Escadinha", "base": 30, "juros": 4},
	"tudo_no_relampago": {"name": "Tudo no Relâmpago", "base": 35, "juros": 4},
	"cofrinho": {"name": "Cofrinho", "base": 60, "juros": 7},
}

# Metas por mês (GDD: "Metas e dinheiro"). Fatura é o chefe do mês.
const MONTHS := [
	{"name": "Março", "boleto": 300, "aluguel": 450, "fatura": 600},
	{"name": "Junho", "boleto": 900, "aluguel": 1300, "fatura": 1800},
	{"name": "Janeiro", "boleto": 2500, "aluguel": 3500, "fatura": 5000},
]

# Recompensas por conta paga.
const REWARD_BOLETO := 3
const REWARD_ALUGUEL := 4
const REWARD_FATURA := 5
const REWARD_PER_UNUSED_DAY := 1

# Regras de partida.
const DAYS_PER_BILL := 4
const SWAPS_PER_BILL := 3
const HAND_SIZE := 8
const MAX_PLAYED := 5
const START_WALLET := 4
const MAX_SCHEMES := 5
const OVERDRAFT_LIMIT := -10
const DEBT_GROWTH_PERCENT := 25

# Ordem das contas dentro de um mês e a recompensa de cada uma.
const BILL_KEYS: Array = ["boleto", "aluguel", "fatura"]
const BILL_LABELS := {"boleto": "Boleto", "aluguel": "Aluguel", "fatura": "Fatura"}
const BILL_REWARDS := {
	"boleto": REWARD_BOLETO,
	"aluguel": REWARD_ALUGUEL,
	"fatura": REWARD_FATURA,
}

# Troco vira grana: R$ 1 a cada TROCO_STEP_PERCENT% acima da meta, até TROCO_MAX.
const TROCO_STEP_PERCENT := 25
const TROCO_MAX := 5

# Chefe de cada mês (é a Fatura daquele mês).
const BOSS_BY_MONTH: Array = ["banco_fora_do_ar", "taxa_manutencao", "janeiro_impostos"]
const BOSSES := {
	"banco_fora_do_ar": {"name": "Banco fora do ar", "text": "Notas de Relâmpago não pontuam"},
	"taxa_manutencao": {"name": "Taxa de manutenção", "text": "Cada troca custa R$ 1"},
	"janeiro_impostos": {"name": "IPVA + IPTU + Material escolar", "text": "Leão da Receita leva 27,5% de cada jogada. Taxa de manutenção: cada troca custa R$ 1. Golpe do WhatsApp: pendente (precisa de esquemas)"},
}
# Leão da Receita, em milésimos (275 = 27,5%).
const LEAO_PER_MILLE := 275
