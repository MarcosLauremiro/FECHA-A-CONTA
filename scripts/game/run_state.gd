class_name RunState
extends RefCounted
## A partida inteira: 3 meses × (Boleto, Aluguel, Fatura), carteira e progresso.
## Dono das contas (BillRound) e da carteira. A interface só chama métodos daqui.
##
## Estados:
##   "playing"    conta em andamento
##   "bill_paid"  conta paga, mostrando comprovante; chame next_bill()
##   "won"        pagou a última fatura (CONTAS EM DIA)
##   "lost"       falhou uma conta (NOME NEGATIVADO)
##
## Camelô (loja entre contas) ainda não existe: next_bill() vai direto para a próxima conta.

const PLAYING := "playing"
const BILL_PAID := "bill_paid"
const WON := "won"
const LOST := "lost"

var wallet: int = Balance.START_WALLET
var month_index: int = 0
var bill_index: int = 0
var state: String = PLAYING
var max_saldo: int = 0  # maior saldo de uma conta no ano (vai no comprovante final)

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


## Vai para a próxima conta depois do comprovante.
func next_bill() -> bool:
	if state != BILL_PAID:
		return false
	bill_index += 1
	if bill_index >= Balance.BILL_KEYS.size():
		bill_index = 0
		month_index += 1
	state = PLAYING
	_start_bill()
	return true


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
	bill = BillRound.new(Balance.MONTHS[month_index][bill_key()], boss_id(), _rng)
