class_name Balance
extends RefCounted
## Todos os números de regra do jogo em um lugar só (GDD: "Dados de esquemas,
## preços e metas num único balance.gd"). Ajustar aqui, não caçar número no código.

# Valores das notas, em ordem crescente (também define a sequência da Escadinha).
const VALUES: Array = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]

# Pontos de Valor de cada nota.
const VALUE_POINTS := {1: 2, 2: 3, 5: 5, 10: 6, 20: 7, 50: 8, 100: 10, 200: 11, 500: 13, 1000: 15}

# Formas de pagamento ("naipes"). Índice = valor de Note.suit.
const SUIT_NAMES: Array = ["Dinheiro", "Pix", "Débito", "Crédito"]
# Chave usada no nome de arquivo do selo de cada forma de pagamento (selo_<chave>.png).
const SUIT_KEYS: Array = ["dinheiro", "pix", "debito", "credito"]

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

# Meses do ano. Fatura é o chefe do mês. As metas vêm da curva de dificuldade (goal_of).
const MONTHS := [
	{"name": "Janeiro"}, {"name": "Fevereiro"}, {"name": "Março"}, {"name": "Abril"},
	{"name": "Maio"}, {"name": "Junho"}, {"name": "Julho"}, {"name": "Agosto"},
	{"name": "Setembro"}, {"name": "Outubro"}, {"name": "Novembro"}, {"name": "Dezembro"},
]
# Uma partida dura RUN_MONTHS meses (Janeiro a Junho). Quem paga a última fatura vence
# e pode continuar no modo infinito, até perder ou derrotar todos os chefes.
const RUN_MONTHS := 6

# Curva de dificuldade (GDD: "Curva de dificuldade"):
#   D(n) = D0 · R^(n-1), onde n é o número da conta (1 = boleto de janeiro, 18 = fatura de junho).
#   No modo infinito a mesma curva continua, mês a mês, até o último chefe.
const D0 := 180    # dificuldade inicial (meta da primeira conta)
const R := 1.24    # fator de crescimento por conta


## Meta da conta `key` (boleto, aluguel ou fatura) no mês `month_index` (0 = Janeiro da partida).
static func goal_of(month_index: int, key: String) -> int:
	var n := month_index * BILL_KEYS.size() + BILL_KEYS.find(key)
	return roundi(D0 * pow(R, n))

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
# Cheque especial: R$ do limite na partida inteira (não renova; cada R$ usado diminui o limite).
# Gastar o último R$ do limite acaba a partida. Cada R$ usado vira dívida de JUROS_OVERDRAFT vezes.
const OVERDRAFT_START := 10
const OVERDRAFT_JUROS := 3
const OVERDRAFT_JUROS_GERENTE := 2   # com Gerente do Banco (ou Cheque Sem Fundo)
const DEBT_GROWTH_PERCENT := 25
# Cheque Sem Fundo: sem limite, mas a dívida pesa. A cada SEM_FUNDO_DEBT_STEP de dívida, a meta sobe 1%.
const SEM_FUNDO_DEBT_STEP := 4

# Contatos: cartas de uso único (como vouchers). Não ocupam espaço de esquema.
# Aparecem uma vez por mês, na loja que vem depois do boleto, ao lado do SEGUIR.
const CONTACT_ORDER: Array = ["gerente", "sem_fundo"]
const CONTACTS := {
	"gerente": {"name": "Gerente do Banco", "short": "Gerente", "price": 15, "text": "JUROS DO CHEQUE CAIEM PARA 2X", "desc": "Os juros do cheque especial caem de 3x para 2x."},
	"sem_fundo": {"name": "Cheque Sem Fundo", "short": "Sem Fundo", "price": 30, "text": "CHEQUE SEM LIMITE", "desc": "Juros do cheque especial de 2x e sem limite: o limite vira ∞. Mas cada R$ 4 de dívida sobe a meta em 1%."},
}

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

# Chefes: um por mês, só na fatura (a 3ª conta do mês). São sorteados por faixa de peso.
# Faixa de cada mês da partida (meses 1-2 leves, 3-4 médios, 5-6 pesados). No modo infinito, qualquer faixa.
const BOSS_TIER_BY_MONTH: Array = ["leve", "leve", "medio", "medio", "pesado", "pesado"]
const BOSS_TIERS := {
	"leve": ["bolsa_familia", "taxa_manutencao", "julius", "urubu_pix", "curso_primo_rico",
		"maquininha_quebrada", "cartao_clonado", "caixa_sem_troco", "troco_em_bala", "nota_falsa",
		"fila_loterica", "boleto_vencido", "dia_das_maes"],
	"medio": ["banco_fora_do_ar", "ferias_praia", "bandeira_vermelha", "decimo_terceiro",
		"feriadao", "inflacao", "reajuste_aluguel", "apagao", "carnaval", "serasa",
		"golpe_falso_gerente", "black_friday"],
	"pesado": ["janeiro_impostos", "dia_dos_pais", "grosso",
		"fatura_parcelada", "malha_fina", "rotina", "sogra_em_casa", "tigrinho", "wifi_caiu",
		"plano_collor", "copa_do_mundo"],
}
# Chefes com data: só caem no mês deles (0 = Janeiro). Ficam fora do sorteio dos outros meses.
const BOSS_FIXED_MONTH := {"dia_das_maes": 4, "dia_dos_pais": 7, "grosso": 8, "decimo_terceiro": 11}
# Dificuldade adaptativa: número do chefe em cada nível (nível = mês / 2, até BOSS_MAX_LEVEL).
const BOSS_MAX_LEVEL := 3
const BOSS_SCALE := {
	"inflacao": [4, 5, 6, 8],              # % que a meta sobe por jogada
	"reajuste_aluguel": [20, 30, 35, 45],  # % a mais na meta
	"serasa": [30, 40, 50, 60],            # % a mais na meta com carteira negativa
	"golpe_falso_gerente": [20, 25, 30, 40],  # % da carteira que some
	"fatura_parcelada": [50, 45, 40, 35],  # % da meta que uma jogada pode contar
	"wifi_caiu": [2, 2, 2, 3],             # jogadas sem esquemas
	"plano_collor": [60, 70, 80, 90],      # % da carteira confiscada
}
const BOSSES := {
	"janeiro_impostos": {"name": "IPVA + IPTU + Material escolar", "text": "Leão da Receita leva 15% de cada jogada. Cada troca custa R$ 1. Golpe do WhatsApp: 1 esquema seu fica desativado nesta conta."},
	"bolsa_familia": {"name": "Bolsa Família", "text": "+R$ 3 ao pagar esta fatura, mas a meta sobe 15%."},
	"banco_fora_do_ar": {"name": "Banco fora do ar", "text": "Notas de Pix não pontuam."},
	"curso_primo_rico": {"name": "Curso do Primo Rico", "text": "Matrícula de R$ 6. A cada 2 contas pagas depois da matrícula, o Valor sobe 10%."},
	"urubu_pix": {"name": "Urubu do Pix", "text": "No começo da fatura, 1 em 2: a carteira dobra. Se não, perde R$ 5."},
	"taxa_manutencao": {"name": "Taxa de manutenção", "text": "Cada troca custa R$ 1."},
	"ferias_praia": {"name": "Férias na praia", "text": "A mão tem 6 cartas, em vez de 8."},
	"dia_dos_pais": {"name": "Dia dos Pais", "text": "Cada troca consome um dia."},
	"grosso": {"name": "Entrar o Grosso", "text": "As contas custam o dobro, e a recompensa também dobra."},
	"bandeira_vermelha": {"name": "Bandeira vermelha", "text": "Cada dia usado custa R$ 1 de energia. Notas de Débito pontuam 50% a mais."},
	"julius": {"name": "Julius", "text": "Se você não comprou nada na Banca antes da conta, a meta cai 20%."},
	"decimo_terceiro": {"name": "13º salário", "text": "A recompensa sobe R$ 3, mas as metas sobem 25%."},
	# Leves.
	"maquininha_quebrada": {"name": "Maquininha quebrada", "text": "Notas de Débito não pontuam."},
	"cartao_clonado": {"name": "Cartão clonado", "text": "Notas de Crédito não pontuam."},
	"caixa_sem_troco": {"name": "Caixa sem troco", "text": "Notas de Dinheiro não pontuam."},
	"troco_em_bala": {"name": "Troco em bala", "text": "Notas de R$ 1, 2 e 5 não pontuam."},
	"nota_falsa": {"name": "Nota falsa", "text": "Notas de R$ 200, 500 e 1000 não pontuam."},
	"fila_loterica": {"name": "Fila da lotérica", "text": "Uma troca a menos nesta conta."},
	"boleto_vencido": {"name": "Boleto vencido", "text": "A primeira jogada vale metade (multa)."},
	"dia_das_maes": {"name": "Dia das Mães", "text": "A recompensa desta conta cai pela metade: foi no presente."},
	# Médios.
	"feriadao": {"name": "Feriadão", "text": "3 dias, em vez de 4."},
	"inflacao": {"name": "Inflação", "text": "Cada jogada sobe a meta em %d%%."},
	"reajuste_aluguel": {"name": "Reajuste do aluguel", "text": "A meta sobe %d%%, sem nada em troca."},
	"apagao": {"name": "Apagão", "text": "A prévia da jogada fica apagada: você paga sem ver quanto vale."},
	"carnaval": {"name": "Carnaval", "text": "Depois de cada jogada, a mão inteira é descartada e comprada de novo."},
	"serasa": {"name": "Serasa", "text": "Se a carteira estiver negativa, a meta sobe %d%%."},
	"golpe_falso_gerente": {"name": "Golpe do falso gerente", "text": "No começo da conta, some %d%% da carteira."},
	"black_friday": {"name": "Black Friday", "text": "A meta sobe 20%, mas a próxima Banca vende tudo pela metade."},
	# Pesados.
	"fatura_parcelada": {"name": "Fatura parcelada", "text": "Cada jogada conta no máximo %d%% da meta."},
	"malha_fina": {"name": "Malha fina", "text": "A formação que você mais jogou na partida não pontua."},
	"rotina": {"name": "Rotina", "text": "Cada formação só pode ser jogada uma vez nesta conta."},
	"sogra_em_casa": {"name": "Sogra em casa", "text": "Só pontua jogada com 5 notas."},
	"tigrinho": {"name": "Tigrinho", "text": "Cada jogada: 1 em 2 de dobrar. Senão, vale metade."},
	"wifi_caiu": {"name": "Wi-Fi caiu", "text": "Os esquemas não funcionam nas %d primeiras jogadas."},
	"plano_collor": {"name": "Plano Collor", "text": "No começo da conta, %d%% da carteira é confiscada."},
	"copa_do_mundo": {"name": "Copa do Mundo", "text": "2 dias e 1 troca: ninguém trabalha em dia de jogo."},
}
# A partida no modo infinito vai até derrotar todos os chefes (um por mês).
const TOTAL_MONTHS := 36
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
const CURSO_VALOR_PERCENT := 10
const CURSO_STEP_CONTAS := 2
const TROCO_BALA_MAX := 5            # Troco em bala: notas até este valor não pontuam
const NOTA_FALSA_MIN := 200          # Nota falsa: notas a partir deste valor não pontuam
const FERIADAO_DAYS := 3
const COPA_DAYS := 2
const COPA_SWAPS := 1
const MAES_REWARD_PERCENT := 50
const BLACK_FRIDAY_GOAL_PERCENT := 120
const BLACK_FRIDAY_PRICE_PERCENT := 50

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
	"vendedor_consorcio": {"name": "Vendedor de Consórcio", "rarity": "comum", "price": 8, "text": "SUA CARTA SAI NA 60ª PARCELA", "desc": "+5 de Valor por nota de Dinheiro que pontua. Cada conta paga custa R$ 1 de parcela."},
	"tia_do_pix": {"name": "Tia do Pix", "rarity": "comum", "price": 8, "text": "MANDA A CHAVE QUE EU PAGO", "desc": "+1 de Juros por nota de Débito que pontua."},
	"cunhado": {"name": "Cunhado Investidor", "rarity": "incomum", "price": 10, "text": "GANHE 30% AO MÊS SEM RISCO", "desc": "A cada 2 Escadinhas jogadas, ele ganha +1 de Juros, para sempre."},
	"rifa": {"name": "Rifa do Bairro", "rarity": "incomum", "price": 10, "text": "RIFA DE 1 PORCO — R$ 2 O NÚMERO", "desc": "1 em 4 de multiplicar o Juros por 5."},
	"vaquinha": {"name": "Vaquinha", "rarity": "incomum", "price": 12, "text": "AJUDE O JUNINHO A PAGAR O ALUGUEL", "desc": "Soma metade dos pontos das notas que ficaram na mão ao Valor."},
	"bicheiro": {"name": "Bicheiro do Bairro", "rarity": "incomum", "price": 12, "text": "JOGO DO BICHO: SAIU O VEADO", "desc": "1 em 3 de cada jogada render R$ 6 na carteira."},
	"pastor": {"name": "Pastor da Prosperidade", "rarity": "rara", "price": 14, "text": "DEUS É FIEL, PAGUE O DÍZIMO", "desc": "+8 de Valor em cada jogada. Cada conta paga 5% da carteira de dízimo."},
	"piramide": {"name": "Pirâmide", "rarity": "rara", "price": 14, "text": "INDIQUE 3 AMIGOS E FIQUE RICO", "desc": "+1 de Juros por outro esquema ativo. 1 em 6 de colapsar a cada mês."},
	"coach": {"name": "Coach Financeiro", "rarity": "rara", "price": 14, "text": "MENTALIDADE MILIONÁRIA EM 7 DIAS", "desc": "×2 de Juros se as 5 notas jogadas pontuarem. Senão, perde 1 de Juros."},
	"influenciador": {"name": "Influenciador de Finanças", "rarity": "rara", "price": 16, "text": "SEGUE QUE EU TE ENSINO A FICAR RICO", "desc": "+2 de Juros em jogadas com 3 ou mais notas."},
	"nubank": {"name": "Nubank", "rarity": "incomum", "price": 12, "text": "A ROXINHA QUE MELHORA SEU CRÉDITO", "desc": "+3 de Valor por nota de Crédito que pontua."},
	"consignado": {"name": "Consignado", "rarity": "lendaria", "price": 22, "text": "DINHEIRO NA HORA, SEM CONSULTA AO SERASA", "desc": "+1 de Juros em cada jogada. A dívida do cheque especial não cresce."},
}
const AGIOTA_JUROS := 3
const VAQUINHA_PERCENT := 50
const AGIOTA_PERCENT := 10
const COACH_MULT := 2
const CUNHADO_STEP := 2                # Cunhado: Escadinhas jogadas para cada +1 de Juros
const RIFA_ODDS := 4
const RIFA_MULT := 5
const PIRAMIDE_ODDS := 6
const CONSORCIO_VALUE := 5          # Vendedor de Consórcio: Valor por nota de Dinheiro que pontua
const CONSORCIO_PARCELA := 1        # ... e parcela paga a cada conta
const TIA_PIX_JUROS := 1            # Tia do Pix: Juros por nota de Débito que pontua
const BICHEIRO_ODDS := 3            # Bicheiro: 1 em 3 por jogada
const BICHEIRO_PRIZE := 6
const PASTOR_VALUE := 8             # Pastor: Valor por jogada
const PASTOR_PERCENT := 5           # ... e dízimo por conta paga, em % da carteira (só com saldo positivo)
const INFLUENCIADOR_MIN_NOTAS := 3  # Influenciador: notas jogadas para ativar
const INFLUENCIADOR_JUROS := 2
const NUBANK_VALUE := 3              # Nubank: Valor por nota de Crédito que pontua
const CONSIGNADO_JUROS := 1         # Consignado: Juros por jogada (a dívida não cresce)

# Camelô (loja entre as contas).
const SHOP_OFFERS := 2
const HAGGLE_COST := 2

# Investimentos (GDD: "Investimentos"). Cada um sobe o nível de uma transação.
# Cada id bate com art/investimentos/<id>.png.
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

