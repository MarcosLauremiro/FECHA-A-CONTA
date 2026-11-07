class_name Balance
extends RefCounted
## Todos os números de regra do jogo em um lugar só (GDD: "Dados de esquemas,
## preços e metas num único balance.gd"). Ajustar aqui, não caçar número no código.

# Valores das notas, em ordem crescente (também define a sequência da Escadinha).
const VALUES: Array = [1, 2, 5, 10, 20, 50, 100, 200]

# Pontos de Valor de cada nota.
const VALUE_POINTS := {1: 2, 2: 3, 5: 5, 10: 6, 20: 7, 50: 8, 100: 10, 200: 11}

# Formas de pagamento ("naipes"). Índice = valor de Note.suit.
const SUIT_NAMES: Array = ["Dinheiro", "Pix", "Débito", "Crédito"]
# Chave usada nos nomes de arquivo das frentes (frente_<valor>_<chave>.png) e dos selos (selo_<chave>.png).
# "relampago" é o nome da arte atual (selo com raio). O Pix ainda usa esse selo até ganhar arte nova.
const SUIT_KEYS: Array = ["dinheiro", "relampago", "debito", "credito"]

# Transações: valor base e Juros base (multiplicador inicial).
const TRANSACTIONS := {
	"trocado": {"name": "Trocado", "base": 5, "juros": 1},
	"dobradinha": {"name": "Dobradinha", "base": 10, "juros": 2},
	"bolada": {"name": "Bolada", "base": 30, "juros": 3},
	"escadinha": {"name": "Escadinha", "base": 25, "juros": 3},
	"tudo_no_pix": {"name": "Tudo no Pix", "base": 35, "juros": 4},
	# Não é formação: é o nível do Duolingo (investimento que dá recompensa). Nunca é pontuada.
	"duolingo": {"name": "Duolingo", "base": 0, "juros": 0},
	"cofrinho": {"name": "Cofrinho", "base": 60, "juros": 7},
	# Liberadas pelo investimento do Camelô (ver INVESTMENTS): só pontuam depois da compra.
	"dois_carnes": {"name": "Dois Carnês", "base": 15, "juros": 2},
	"conta_conjunta": {"name": "Conta Conjunta", "base": 35, "juros": 3},
}

# Metas por mês (GDD: "Metas e dinheiro"). Fatura é o chefe do mês.
const MONTHS := [
	{"name": "Janeiro", "boleto": 210, "aluguel": 320, "fatura": 425},
	{"name": "Fevereiro", "boleto": 285, "aluguel": 425, "fatura": 565},
	{"name": "Março", "boleto": 355, "aluguel": 535, "fatura": 720},
	{"name": "Abril", "boleto": 470, "aluguel": 705, "fatura": 925},
	{"name": "Maio", "boleto": 600, "aluguel": 900, "fatura": 1200},
	{"name": "Junho", "boleto": 785, "aluguel": 1175, "fatura": 1565},
	{"name": "Julho", "boleto": 990, "aluguel": 1500, "fatura": 1995},
	{"name": "Agosto", "boleto": 1290, "aluguel": 1925, "fatura": 2565},
	{"name": "Setembro", "boleto": 1635, "aluguel": 2455, "fatura": 3275},
	{"name": "Outubro", "boleto": 2130, "aluguel": 3210, "fatura": 4270},
	{"name": "Novembro", "boleto": 2700, "aluguel": 4065, "fatura": 5415},
	{"name": "Dezembro", "boleto": 3565, "aluguel": 5340, "fatura": 7125},
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
# Chefe de cada mês. Ele aparece só na fatura (a 3ª conta do mês).
const BOSS_BY_MONTH: Array = [
	"janeiro_impostos",
	"bolsa_familia",
	"banco_fora_do_ar",
	"curso_primo_rico",
	"urubu_pix",
	"taxa_manutencao",
	"ferias_praia",
	"dia_dos_pais",
	"grosso",
	"bandeira_vermelha",
	"julius",
	"decimo_terceiro",
]
const BOSSES := {
	"janeiro_impostos": {"name": "IPVA + IPTU + Material escolar", "text": "Leão da Receita leva 15% de cada jogada. Cada troca custa R$ 1. Golpe do WhatsApp: 1 esquema seu fica desativado nesta conta."},
	"bolsa_familia": {"name": "Bolsa Família", "text": "+R$ 3 ao pagar esta fatura, mas a meta sobe 15%."},
	"banco_fora_do_ar": {"name": "Banco fora do ar", "text": "Notas de Pix não pontuam."},
	"curso_primo_rico": {"name": "Curso do Primo Rico", "text": "Matrícula de R$ 6. A cada 2 contas pagas depois da matrícula, o Valor sobe 20%."},
	"urubu_pix": {"name": "Urubu do Pix", "text": "No começo da fatura, 1 em 2: a carteira dobra. Se não, perde R$ 5."},
	"taxa_manutencao": {"name": "Taxa de manutenção", "text": "Cada troca custa R$ 1."},
	"ferias_praia": {"name": "Férias na praia", "text": "A mão tem 6 cartas, em vez de 8."},
	"dia_dos_pais": {"name": "Dia dos Pais", "text": "Cada troca consome um dia."},
	"grosso": {"name": "Entrar o Grosso", "text": "As contas custam o dobro, e a recompensa também dobra."},
	"bandeira_vermelha": {"name": "Bandeira vermelha", "text": "Cada dia usado custa R$ 1 de energia. Notas de Débito pontuam 50% a mais."},
	"julius": {"name": "Julius", "text": "Se você não comprou nada no Camelô antes da conta, a meta cai 20%."},
	"decimo_terceiro": {"name": "13º salário", "text": "A recompensa sobe R$ 3, mas as metas sobem 25%."},
}
# Leão da Receita, em milésimos (275 = 27,5%).
const LEAO_PER_MILLE := 150

# Regras dos chefes (números que o boss.gd e a partida usam).
const FERIAS_HAND := 6
const BOLSA_BONUS := 3
const BOLSA_GOAL_PERCENT := 115
const DECIMO_BONUS := 3
const DECIMO_GOAL_PERCENT := 125
const GROSSO_PERCENT := 200
const JULIUS_PERCENT := 80
const BANDEIRA_DAY_COST := 1
const BANDEIRA_DEBITO_PERCENT := 50
const URUBU_LOSS := 5
const CURSO_COST := 6
const CURSO_VALOR_PERCENT := 20
const CURSO_STEP_CONTAS := 2

# Raridade (vale para esquemas e investimentos). Quanto mais rara, menos aparece no Camelô.
# Peso = chance relativa de a oferta sair num sorteio do Camelô.
const RARITY_ORDER: Array = ["comum", "incomum", "rara", "lendaria"]
const RARITY_NAMES := {"comum": "Comum", "incomum": "Incomum", "rara": "Rara", "lendaria": "Lendária"}
const RARITY_WEIGHT := {"comum": 50, "incomum": 30, "rara": 15, "lendaria": 5}

# Esquemas (GDD: "Esquemas"). Cada id bate com art/esquemas/cartaz_<id>.png.
# Personagens e referências brasileiras: Vendedor de Consórcio, Tia do Pix, Bicheiro, Pastor, Influenciador, Consignado.
const SCHEME_ORDER: Array = ["agiota", "cunhado", "coach", "piramide", "cashback", "rifa", "vaquinha", "relampago_errado", "vendedor_consorcio", "tia_do_pix", "bicheiro", "pastor", "influenciador", "consignado", "nubank"]
const SCHEMES := {
	"agiota": {"name": "Agiota", "rarity": "comum", "price": 8, "text": "EMPRESTO DINHEIRO NA HORA", "desc": "+3 de Juros. Cobra 10% da carteira a cada conta paga."},
	"cashback": {"name": "Cashback", "rarity": "comum", "price": 8, "text": "SEU DINHEIRO DE VOLTA*", "desc": "Cada nota de Crédito que pontua devolve R$ 1 na carteira."},
	"relampago_errado": {"name": "Pix Errado", "rarity": "comum", "price": 10, "text": "FIZ UM PIX ERRADO, DEVOLVE PFV", "desc": "A primeira nota de Pix jogada em cada conta é duplicada no baralho."},
	"vendedor_consorcio": {"name": "Vendedor de Consórcio", "rarity": "comum", "price": 8, "text": "SUA CARTA SAI NA 60ª PARCELA", "desc": "+3 de Valor por nota de Dinheiro que pontua. Cada conta paga custa R$ 1 de parcela."},
	"tia_do_pix": {"name": "Tia do Pix", "rarity": "comum", "price": 8, "text": "MANDA A CHAVE QUE EU PAGO", "desc": "+1 de Juros por nota de Débito que pontua."},
	"cunhado": {"name": "Cunhado Investidor", "rarity": "incomum", "price": 10, "text": "GANHE 30% AO MÊS SEM RISCO", "desc": "Cada Escadinha jogada dá +1 de Juros a ele, para sempre."},
	"rifa": {"name": "Rifa do Bairro", "rarity": "incomum", "price": 10, "text": "RIFA DE 1 PORCO — R$ 2 O NÚMERO", "desc": "1 em 4 de multiplicar o Juros por 5."},
	"vaquinha": {"name": "Vaquinha", "rarity": "incomum", "price": 12, "text": "AJUDE O JUNINHO A PAGAR O ALUGUEL", "desc": "Soma metade dos pontos das notas que ficaram na mão ao Valor."},
	"bicheiro": {"name": "Bicheiro do Bairro", "rarity": "incomum", "price": 12, "text": "JOGO DO BICHO: SAIU O VEADO", "desc": "1 em 3 de cada jogada render R$ 6 na carteira."},
	"pastor": {"name": "Pastor da Prosperidade", "rarity": "rara", "price": 14, "text": "DEUS É FIEL, PAGUE O DÍZIMO", "desc": "+8 de Valor em cada jogada. Cada conta paga 5% da carteira de dízimo."},
	"piramide": {"name": "Pirâmide", "rarity": "rara", "price": 14, "text": "INDIQUE 3 AMIGOS E FIQUE RICO", "desc": "+1 de Juros por outro esquema ativo. 1 em 6 de colapsar a cada mês."},
	"coach": {"name": "Coach Financeiro", "rarity": "rara", "price": 14, "text": "MENTALIDADE MILIONÁRIA EM 7 DIAS", "desc": "×2 de Juros se jogar exatamente 5 notas. Se jogar menos, perde 1 de Juros."},
	"influenciador": {"name": "Influenciador de Finanças", "rarity": "rara", "price": 16, "text": "SEGUE QUE EU TE ENSINO A FICAR RICO", "desc": "+3 de Juros em jogadas com 3 ou mais notas."},
	"nubank": {"name": "Nubank", "rarity": "incomum", "price": 12, "text": "A ROXINHA QUE MELHORA SEU CRÉDITO", "desc": "+3 de Valor por nota de Crédito que pontua."},
	"consignado": {"name": "Consignado", "rarity": "lendaria", "price": 22, "text": "DINHEIRO NA HORA, SEM CONSULTA AO SERASA", "desc": "+1 de Juros em cada jogada. A dívida do cheque especial não cresce."},
}
const AGIOTA_JUROS := 3
const VAQUINHA_PERCENT := 50
const AGIOTA_PERCENT := 10
const COACH_MULT := 2
const RIFA_ODDS := 4
const RIFA_MULT := 5
const PIRAMIDE_ODDS := 6
const CONSORCIO_VALUE := 3          # Vendedor de Consórcio: Valor por nota de Dinheiro que pontua
const CONSORCIO_PARCELA := 1        # ... e parcela paga a cada conta
const TIA_PIX_JUROS := 1            # Tia do Pix: Juros por nota de Débito que pontua
const BICHEIRO_ODDS := 3            # Bicheiro: 1 em 3 por jogada
const BICHEIRO_PRIZE := 6
const PASTOR_VALUE := 8             # Pastor: Valor por jogada
const PASTOR_PERCENT := 5           # ... e dízimo por conta paga, em % da carteira (só com saldo positivo)
const INFLUENCIADOR_MIN_NOTAS := 3  # Influenciador: notas jogadas para ativar
const INFLUENCIADOR_JUROS := 3
const NUBANK_VALUE := 3              # Nubank: Valor por nota de Crédito que pontua
const CONSIGNADO_JUROS := 1         # Consignado: Juros por jogada (a dívida não cresce)

# Camelô (loja entre as contas).
const SHOP_OFFERS := 2
const HAGGLE_COST := 2

# Investimentos (GDD: "Investimentos"). Cada um sobe o nível de uma transação.
# Cada id bate com art/camelo/investimento_<id>.png.
const INVESTMENT_ORDER: Array = ["poupanca", "consorcio", "tesouro", "previdencia", "carne", "fundo", "conta_conjunta", "cripto", "duolingo"]
const INVESTMENTS := {
	"poupanca": {"name": "Poupança", "rarity": "comum", "price": 6, "transaction": "dobradinha", "per_value": 10, "per_juros": 1, "desc": "Dobradinha: +10 de Valor e +1 de Juros por nível. A caderneta do seu Zé, rendendo pouco e sempre."},
	"consorcio": {"name": "Consórcio", "rarity": "comum", "price": 6, "transaction": "trocado", "per_value": 8, "per_juros": 1, "desc": "Trocado: +8 de Valor e +1 de Juros por nível. A carta contemplada chega na 60ª parcela."},
	"tesouro": {"name": "Tesouro Direto", "rarity": "incomum", "price": 6, "transaction": "escadinha", "per_value": 20, "per_juros": 2, "desc": "Escadinha: +20 de Valor e +2 de Juros por nível. Título do governo, o tio sempre fala dele no churrasco."},
	"previdencia": {"name": "Previdência Privada", "rarity": "incomum", "price": 8, "transaction": "cofrinho", "per_value": 30, "per_juros": 2, "desc": "Cofrinho: +30 de Valor e +2 de Juros por nível. Só resgata quando você já não precisa."},
	"carne": {"name": "Carnê", "rarity": "incomum", "price": 16, "transaction": "dois_carnes", "per_value": 10, "per_juros": 1, "desc": "Libera Dois Carnês (2 pares, 4 notas). Cada nível: +10 de Valor e +1 de Juros."},
	"fundo": {"name": "Fundo de Investimento", "rarity": "rara", "price": 16, "transaction": "bolada", "per_value": 10, "per_juros": 1, "desc": "Bolada (3 iguais): +10 de Valor e +1 de Juros por nível. Gestor cobra taxa, mas o rendimento aparece."},
	"conta_conjunta": {"name": "Conta Conjunta", "rarity": "rara", "price": 20, "transaction": "conta_conjunta", "per_value": 10, "per_juros": 1, "desc": "Libera Conta Conjunta (trinca + par, 5 notas). Cada nível: +10 de Valor e +1 de Juros."},
	"duolingo": {"name": "Duolingo", "rarity": "incomum", "price": 10, "transaction": "duolingo", "per_value": 0, "per_juros": 0, "per_reward": 2, "desc": "Curso de inglês: cada nível dá +R$ 2 de recompensa em toda conta paga. Os ganhos sobem, a coruja cobra o streak."},
	"cripto": {"name": "Cripto", "rarity": "lendaria", "price": 8, "transaction": "tudo_no_pix", "per_value": 40, "per_juros": 3, "desc": "Tudo no Pix: +40 de Valor e +3 de Juros por nível. Às vezes cai um nível em vez de subir."},
}
# Formações liberadas por investimento: só são consideradas depois que o nível fica acima de zero.
const UNLOCKABLE_KINDS: Array = ["dois_carnes", "conta_conjunta"]
const CRIPTO_DROP_ODDS := 4
const SHOP_INVESTMENT_OFFERS := 1

