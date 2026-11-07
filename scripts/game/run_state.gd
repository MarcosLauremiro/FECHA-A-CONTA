class_name RunState
extends RefCounted
## A partida inteira: 12 meses × (Boleto, Aluguel, Fatura), carteira, esquemas e progresso.
## Dono das contas (BillRound), da carteira e do Camelô. A interface só chama métodos daqui.
##
## Estados:
##   "playing"    conta em andamento
##   "bill_paid"  conta paga, mostrando comprovante; chame next_bill() para ir ao Camelô
##   "shop"       Camelô entre as contas; chame leave_shop() para começar a próxima conta
##   "won"        pagou a última fatura (CONTAS EM DIA)
##   "lost"       falhou uma conta (NOME NEGATIVADO)
##
## Camelô: comprar, vender e pechinchar esquemas. Investimentos ainda não existem.

const PLAYING := "playing"
const BILL_PAID := "bill_paid"
const SHOP := "shop"
const WON := "won"
const LOST := "lost"

var wallet: int = Balance.START_WALLET
var month_index: int = 0
var bill_index: int = 0
var state: String = PLAYING
var max_saldo: int = 0  # maior saldo de uma conta no ano (vai no comprovante final)
var schemes: Array = []       # esquemas ativos (ids), da esquerda para a direita
var cunhado_bonus: int = 0    # Juros acumulado do Cunhado Investidor
var shop_offer: Array = []    # ofertas do Camelô agora: ids de esquemas e de investimentos
var levels: Dictionary = {}   # níveis dos investimentos, {transação: nível}
var curso_matriculado := false  # Curso do Primo Rico: matrícula paga (uma vez na partida)
var curso_contas := 0           # contas pagas depois da matrícula (a cada 2, o Valor sobe)
var bought_last_shop := false   # comprou algo no Camelô antes desta conta (Julius)
var boss_note := ""             # resultado do chefe desta conta (Urubu, matrícula), mostrado na tela

# Último comprovante (preenchido ao pagar uma conta).
var receipt: Dictionary = {}

var bill: BillRound
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng
	_start_bill()


func bill_key() -> String:
	return Balance.BILL_KEYS[bill_index]


func month_name() -> String:
	return tr(Balance.MONTHS[month_index]["name"])


func bill_title() -> String:
	return "%s · %s" % [month_name(), tr(Balance.BILL_LABELS[bill_key()])]


## Chefe do mês: só na fatura (3ª conta do mês). Boleto e Aluguel não têm chefe.
func boss_id() -> String:
	if bill_key() == "fatura":
		return Balance.BOSS_BY_MONTH[month_index]
	return Boss.NONE


## Valor extra do Curso do Primo Rico, em %: CURSO_VALOR_PERCENT a cada CURSO_STEP_CONTAS contas pagas.
func valor_percent() -> int:
	if not curso_matriculado:
		return 0
	return Balance.CURSO_VALOR_PERCENT * (curso_contas / Balance.CURSO_STEP_CONTAS)


func is_last_bill() -> bool:
	return month_index == Balance.MONTHS.size() - 1 and bill_index == Balance.BILL_KEYS.size() - 1


func pay() -> Dictionary:
	if state != PLAYING:
		return {"ok": false, "reason": "run_not_playing", "state": state}
	var result := bill.pay()
	if not result["ok"]:
		return result

	# Cashback devolve na carteira na hora; Cunhado acumula a cada Escadinha.
	wallet += int(result.get("cash", 0))
	# Bandeira vermelha: cada dia usado custa energia.
	wallet -= Boss.day_cost(boss_id())
	if result["score"]["kind"] == "escadinha" and schemes.has("cunhado"):
		cunhado_bonus += 1

	if result["state"] == BillRound.WON:
		_settle_paid_bill()
	elif result["state"] == BillRound.LOST:
		state = LOST
	return result


func swap() -> Dictionary:
	if state != PLAYING:
		return {"ok": false, "reason": "run_not_playing", "state": state}
	var cost := bill.swap_cost()
	# Cheque especial: a carteira pode ir até OVERDRAFT_LIMIT. Sem dinheiro, a troca é recusada.
	if wallet - cost < Balance.OVERDRAFT_LIMIT:
		return {"ok": false, "reason": "no_money", "state": state}
	var result := bill.swap()
	if result["ok"]:
		wallet -= cost
		# Dia dos Pais: a troca pode acabar a conta (último dia).
		if result["state"] == BillRound.LOST:
			state = LOST
	return result


## Depois do comprovante, vai ao Camelô.
func next_bill() -> bool:
	if state != BILL_PAID:
		return false
	state = SHOP
	bought_last_shop = false
	shop_offer = _random_ids(Balance.SCHEME_ORDER, Balance.SHOP_OFFERS, schemes) + _random_ids(Balance.INVESTMENT_ORDER, Balance.SHOP_INVESTMENT_OFFERS, [])
	return true


## Sai do Camelô e começa a próxima conta.
func leave_shop() -> bool:
	if state != SHOP:
		return false
	bill_index += 1
	if bill_index >= Balance.BILL_KEYS.size():
		bill_index = 0
		month_index += 1
		_roll_piramides()
	state = PLAYING
	_start_bill()
	return true


## Compra a oferta de índice `index` (esquema ou investimento). Pode usar o cheque especial.
func buy(index: int) -> Dictionary:
	var refusal := _check_shop(index, shop_offer)
	if not refusal.is_empty():
		return refusal
	var id: String = shop_offer[index]
	if id == "":  # oferta já comprada: o espaço fica vazio até a próxima visita
		return {"ok": false, "reason": "bad_index"}
	var price := price_of(id)
	if wallet - price < Balance.OVERDRAFT_LIMIT:
		return {"ok": false, "reason": "no_money"}

	if Investments.is_investment(id):
		wallet -= price
		var kind := Investments.transaction_of(id)
		var drop := id == "cripto" and _rand_int(Balance.CRIPTO_DROP_ODDS) == 0
		levels[kind] = Investments.level_after_purchase(id, int(levels.get(kind, 0)), drop)
		# A oferta comprada vira espaço vazio: as outras não mudam de lugar.
		shop_offer[index] = ""
		bought_last_shop = true
		return {"ok": true, "reason": "", "id": id, "dropped": drop}

	if schemes.size() >= Balance.MAX_SCHEMES:
		return {"ok": false, "reason": "slots_full"}
	wallet -= price
	schemes.append(id)
	shop_offer[index] = ""
	bought_last_shop = true
	return {"ok": true, "reason": "", "id": id}


func price_of(id: String) -> int:
	if Investments.is_investment(id):
		return Balance.INVESTMENTS[id]["price"]
	return Balance.SCHEMES[id]["price"]


## Vende um esquema ativo pela metade do preço (arredondado para baixo).
func sell(index: int) -> Dictionary:
	if state != SHOP:
		return {"ok": false, "reason": "not_shop"}
	if index < 0 or index >= schemes.size():
		return {"ok": false, "reason": "bad_index"}
	var id: String = schemes[index]
	var refund: int = Balance.SCHEMES[id]["price"] / 2
	wallet += refund
	schemes.remove_at(index)
	return {"ok": true, "reason": "", "id": id, "refund": refund}


## Pechinchar: troca a oferta por outra, por HAGGLE_COST.
func haggle() -> Dictionary:
	if state != SHOP:
		return {"ok": false, "reason": "not_shop"}
	if wallet - Balance.HAGGLE_COST < Balance.OVERDRAFT_LIMIT:
		return {"ok": false, "reason": "no_money"}
	wallet -= Balance.HAGGLE_COST
	shop_offer = _random_ids(Balance.SCHEME_ORDER, Balance.SHOP_OFFERS, schemes + shop_offer) + _random_ids(Balance.INVESTMENT_ORDER, Balance.SHOP_INVESTMENT_OFFERS, [])
	return {"ok": true, "reason": ""}


## Troco vira grana: R$ 1 a cada TROCO_STEP_PERCENT% acima da meta, até TROCO_MAX.
static func troco(saldo: int, goal: int) -> int:
	if saldo <= goal or goal <= 0:
		return 0
	var steps := (saldo - goal) * 100 / (goal * Balance.TROCO_STEP_PERCENT)
	return mini(steps, Balance.TROCO_MAX)


## Dívida do cheque especial cresce DEBT_GROWTH_PERCENT% a cada conta paga (arredonda para cima).
static func debt_growth(debt: int) -> int:
	return (debt * Balance.DEBT_GROWTH_PERCENT + 99) / 100


func _settle_paid_bill() -> void:
	var key := bill_key()
	var base: int = Balance.BILL_REWARDS[key]
	# Recompensa da conta: base + dia não usado, depois o chefe (Grosso dobra; Bolsa e 13º somam).
	var reward := bill.reward(base) * Boss.reward_mult(boss_id()) + Boss.reward_bonus(boss_id()) + Investments.reward_bonus(levels)
	var extra := troco(bill.saldo, bill.goal)
	if curso_matriculado:
		curso_contas += 1

	# Cada passo fica guardado no comprovante, para a conta da carteira aparecer inteira.
	var wallet_before := wallet

	# Dívida cresce antes de receber; a recompensa paga a dívida primeiro (carteira negativa sobe).
	var growth := 0
	if wallet < 0 and not schemes.has("consignado"):
		growth = debt_growth(-wallet)
		wallet -= growth
	wallet += reward + extra

	# Agiota cobra uma porcentagem da carteira a cada conta paga.
	var agiota := 0
	if schemes.has("agiota"):
		agiota = SchemeRules.agiota_charge(wallet)
		wallet -= agiota

	# Parcelas e dízimo dos esquemas (Vendedor de Consórcio, Consignado, Pastor).
	var parcelas := SchemeRules.parcelas_per_bill(schemes)
	var dizimo := SchemeRules.dizimo_charge(schemes, wallet)
	wallet -= parcelas + dizimo

	max_saldo = maxi(max_saldo, bill.saldo)
	receipt = {
		"title": bill_title(),
		"saldo": bill.saldo,
		"goal": bill.goal,
		"reward": reward,
		"troco": extra,
		"wallet_before": wallet_before,
		"growth": growth,
		"agiota": agiota,
		"parcelas": parcelas + dizimo,
		"wallet": wallet,
		"days_left": bill.days_left,
	}
	state = WON if is_last_bill() else BILL_PAID


func _start_bill() -> void:
	var boss := boss_id()
	var active := schemes.duplicate()
	boss_note = ""
	# Golpe do WhatsApp (IPVA de Janeiro): um esquema aleatório fica desativado em cada conta.
	if boss == "janeiro_impostos" and not active.is_empty():
		active.remove_at(_rand_int(active.size()))
	# Curso do Primo Rico: a matrícula é paga uma vez, na primeira conta do mês.
	if boss == "curso_primo_rico" and not curso_matriculado:
		curso_matriculado = true
		wallet -= Balance.CURSO_COST
		boss_note = tr("Matrícula paga: -R$ %d.") % Balance.CURSO_COST
	# Urubu do Pix: no começo de cada conta, 1 em 2 chance de dobrar a carteira.
	if boss == "urubu_pix":
		if _rand_int(2) == 0:
			if wallet > 0:
				wallet *= 2
				boss_note = tr("Urubu: a carteira dobrou!")
			else:
				boss_note = tr("Urubu: não tinha o que dobrar.")
		else:
			wallet -= Balance.URUBU_LOSS
			boss_note = tr("Urubu: golpe, perdeu R$ %d.") % Balance.URUBU_LOSS
	var goal: int = Balance.MONTHS[month_index][bill_key()]
	goal = goal * Boss.goal_percent(boss, bought_last_shop) / 100
	bill = BillRound.new(goal, boss, _rng, active, cunhado_bonus, levels, valor_percent())


## Pirâmide: a cada mês, 1 em PIRAMIDE_ODDS chance de colapsar (sai da lista).
func _roll_piramides() -> void:
	for i in range(schemes.size() - 1, -1, -1):
		if schemes[i] == "piramide" and _rand_int(Balance.PIRAMIDE_ODDS) == 0:
			schemes.remove_at(i)


func _check_shop(index: int, offer: Array) -> Dictionary:
	if state != SHOP:
		return {"ok": false, "reason": "not_shop"}
	if index < 0 or index >= offer.size():
		return {"ok": false, "reason": "bad_index"}
	return {}


## Sorteia até `count` ids distintos de `pool` que não estejam em `exclude`.
## Quanto mais rara a oferta (Balance.RARITY_WEIGHT), menor a chance de sair.
func _random_ids(pool_all: Array, count: int, exclude: Array) -> Array:
	var pool: Array = []
	for id in pool_all:
		if not exclude.has(id):
			pool.append(id)
	var out: Array = []
	while out.size() < count and not pool.is_empty():
		var total := 0
		for id in pool:
			total += _weight_of(id)
		var roll := _rand_int(total)
		var acc := 0
		for i in range(pool.size()):
			acc += _weight_of(pool[i])
			if roll < acc:
				out.append(pool[i])
				pool.remove_at(i)
				break
	return out


## Peso de sorteio de um esquema ou investimento, pela raridade.
static func _weight_of(id: String) -> int:
	var info: Dictionary = Balance.INVESTMENTS[id] if Investments.is_investment(id) else Balance.SCHEMES[id]
	return int(Balance.RARITY_WEIGHT[info["rarity"]])


func _rand_int(n: int) -> int:
	if _rng != null:
		return _rng.randi_range(0, n - 1)
	return randi_range(0, n - 1)


## Partida inteira para salvar (JSON). Ver SaveGame.
func to_dict() -> Dictionary:
	return {
		"wallet": wallet,
		"month_index": month_index,
		"bill_index": bill_index,
		"state": state,
		"max_saldo": max_saldo,
		"schemes": schemes,
		"cunhado_bonus": cunhado_bonus,
		"shop_offer": shop_offer,
		"levels": levels,
		"curso_matriculado": curso_matriculado,
		"curso_contas": curso_contas,
		"bought_last_shop": bought_last_shop,
		"boss_note": boss_note,
		"receipt": receipt,
		"bill": bill.to_dict(),
	}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	r.wallet = int(d["wallet"])
	r.month_index = int(d["month_index"])
	r.bill_index = int(d["bill_index"])
	r.state = String(d["state"])
	r.max_saldo = int(d["max_saldo"])
	r.schemes = d["schemes"]
	r.cunhado_bonus = int(d["cunhado_bonus"])
	r.shop_offer = d["shop_offer"]
	r.levels = {}
	for k in d["levels"]:
		r.levels[k] = int(d["levels"][k])
	r.curso_matriculado = bool(d["curso_matriculado"])
	r.curso_contas = int(d["curso_contas"])
	r.bought_last_shop = bool(d["bought_last_shop"])
	r.boss_note = String(d["boss_note"])
	r.receipt = d["receipt"]
	r.bill = BillRound.from_dict(d["bill"])
	return r
