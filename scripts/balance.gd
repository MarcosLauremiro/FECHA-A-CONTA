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
	"janeiro_impostos": {"name": "IPVA + IPTU + Material escolar", "text": "Leão da Receita leva 27,5% de cada jogada. Taxa de manutenção: cada troca custa R$ 1. Golpe do WhatsApp: 1 esquema seu fica desativado nesta conta"},
}
# Leão da Receita, em milésimos (275 = 27,5%).
const LEAO_PER_MILLE := 275

# Esquemas (GDD: "Esquemas"). Cada id bate com art/esquemas/cartaz_<id>.png.
const SCHEME_ORDER: Array = ["agiota", "cunhado", "coach", "piramide", "cashback", "rifa", "vaquinha", "relampago_errado"]
const SCHEMES := {
	"agiota": {"name": "Agiota", "price": 4, "text": "EMPRESTO DINHEIRO NA HORA", "desc": "+5 de Juros. Cobra 10% da carteira a cada conta paga."},
	"cunhado": {"name": "Cunhado Investidor", "price": 5, "text": "GANHE 30% AO MÊS SEM RISCO", "desc": "Cada Escadinha jogada dá +1 de Juros a ele, para sempre."},
	"coach": {"name": "Coach Financeiro", "price": 6, "text": "MENTALIDADE MILIONÁRIA EM 7 DIAS", "desc": "×2 de Juros se jogar exatamente 5 notas. Se jogar menos, perde 1 de Juros."},
	"piramide": {"name": "Pirâmide", "price": 5, "text": "INDIQUE 3 AMIGOS E FIQUE RICO", "desc": "+1 de Juros por outro esquema ativo. 1 em 6 de colapsar a cada mês."},
	"cashback": {"name": "Cashback", "price": 4, "text": "SEU DINHEIRO DE VOLTA*", "desc": "Cada nota de Crédito que pontua devolve R$ 1 na carteira."},
	"rifa": {"name": "Rifa do Bairro", "price": 5, "text": "RIFA DE 1 PORCO — R$ 2 O NÚMERO", "desc": "1 em 4 de multiplicar o Juros por 5."},
	"vaquinha": {"name": "Vaquinha", "price": 6, "text": "AJUDE O JUNINHO A PAGAR O ALUGUEL", "desc": "Soma os pontos das notas que ficaram na mão ao Valor."},
	"relampago_errado": {"name": "Relâmpago Errado", "price": 5, "text": "FIZ UM RELÂMPAGO ERRADO, DEVOLVE PFV", "desc": "A primeira nota de Relâmpago jogada em cada conta é duplicada no baralho."},
}
const AGIOTA_JUROS := 5
const AGIOTA_PERCENT := 10
const COACH_MULT := 2
const RIFA_ODDS := 4
const RIFA_MULT := 5
const PIRAMIDE_ODDS := 6

# Camelô (loja entre as contas).
const SHOP_OFFERS := 2
const HAGGLE_COST := 2

# Investimentos (GDD: "Investimentos"). Cada um sobe o nível de uma transação.
# Cada id bate com art/camelo/investimento_<id>.png.
const INVESTMENT_ORDER: Array = ["poupanca", "tesouro", "cripto"]
const INVESTMENTS := {
	"poupanca": {"name": "Poupança", "price": 3, "transaction": "dobradinha", "per_value": 10, "per_juros": 1, "desc": "Dobradinha: +10 de Valor e +1 de Juros por nível."},
	"tesouro": {"name": "Tesouro Direto", "price": 3, "transaction": "escadinha", "per_value": 20, "per_juros": 1, "desc": "Escadinha: +20 de Valor e +1 de Juros por nível."},
	"cripto": {"name": "Cripto", "price": 3, "transaction": "tudo_no_relampago", "per_value": 25, "per_juros": 2, "desc": "Tudo no Relâmpago: +25 de Valor e +2 de Juros por nível. Às vezes cai um nível em vez de subir."},
}
const CRIPTO_DROP_ODDS := 4
const SHOP_INVESTMENT_OFFERS := 1

