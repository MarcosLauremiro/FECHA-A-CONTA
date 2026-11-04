class_name RunState
extends RefCounted
## A partida inteira: 3 meses × (Boleto, Aluguel, Fatura), carteira, esquemas e progresso.
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
var shop_offer: Array = []    # esquemas à venda no Camelô agora

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
	return Balance.MONTHS[month_index]["name"]


func bill_title() -> String:
	return "%s · %s" % [month_name(), Balance.BILL_LABELS[bill_key()]]


func boss_id() -> String:
	if bill_key() == "fatura":
		return Balance.BOSS_BY_MONTH[month_index]
	return Boss.NONE


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
	return result


## Depois do comprovante, vai ao Camelô.
func next_bill() -> bool:
	if state != BILL_PAID:
		return false
	state = SHOP
	shop_offer = _random_schemes(Balance.SHOP_OFFERS, schemes)
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


## Compra o esquema da oferta de índice `index`. Pode usar o cheque especial.
func buy(index: int) -> Dictionary:
	var refusal := _check_shop(index, shop_offer)
	if not refusal.is_empty():
		return refusal
	var id: String = shop_offer[index]
	var price: int = Balance.SCHEMES[id]["price"]
	if schemes.size() >= Balance.MAX_SCHEMES:
		return {"ok": false, "reason": "slots_full"}
	if wallet - price < Balance.OVERDRAFT_LIMIT:
		return {"ok": false, "reason": "no_money"}
	wallet -= price
	schemes.append(id)
	shop_offer.remove_at(index)
	return {"ok": true, "reason": "", "id": id}


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
	shop_offer = _random_schemes(Balance.SHOP_OFFERS, schemes + shop_offer)
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
	var reward := bill.reward(base)
	var extra := troco(bill.saldo, bill.goal)

	# Dívida cresce antes de receber; a recompensa paga a dívida primeiro (carteira negativa sobe).
	if wallet < 0:
		wallet -= debt_growth(-wallet)
	wallet += reward + extra

	# Agiota cobra uma porcentagem da carteira a cada conta paga.
	if schemes.has("agiota"):
		wallet -= SchemeRules.agiota_charge(wallet)

	max_saldo = maxi(max_saldo, bill.saldo)
	receipt = {
		"title": bill_title(),
		"saldo": bill.saldo,
		"goal": bill.goal,
		"reward": reward,
		"troco": extra,
		"wallet": wallet,
		"days_left": bill.days_left,
	}
	state = WON if is_last_bill() else BILL_PAID


func _start_bill() -> void:
	var active := schemes.duplicate()
	# Golpe do WhatsApp (fatura de Janeiro): um esquema aleatório fica desativado nesta conta.
	if boss_id() == "janeiro_impostos" and not active.is_empty():
		active.remove_at(_rand_int(active.size()))
	bill = BillRound.new(Balance.MONTHS[month_index][bill_key()], boss_id(), _rng, active, cunhado_bonus)


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


## Sorteia `count` esquemas distintos que não estejam em `exclude`.
func _random_schemes(count: int, exclude: Array) -> Array:
	var pool: Array = []
	for id in Balance.SCHEME_ORDER:
		if not exclude.has(id):
			pool.append(id)
	# Embaralha (Fisher–Yates com o mesmo RNG da partida).
	for i in range(pool.size() - 1, 0, -1):
		var j := _rand_int(i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, mini(count, pool.size()))


func _rand_int(n: int) -> int:
	if _rng != null:
		return _rng.randi_range(0, n - 1)
	return randi_range(0, n - 1)
