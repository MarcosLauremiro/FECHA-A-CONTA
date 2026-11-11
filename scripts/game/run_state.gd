class_name RunState
extends RefCounted
## A partida inteira: 6 meses × (Boleto, Aluguel, Fatura), carteira, esquemas e progresso.
## Depois dos 6 meses dá para continuar no modo infinito, até Dezembro (o último chefe).
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
var overdraft_left: int = Balance.OVERDRAFT_START  # R$ do cheque especial que ainda não foi usado (não renova)
var contacts_owned: Array = []   # contatos comprados nesta partida (ids de Balance.CONTACTS)
var contact_offer: Array = []    # contatos à venda agora (só na loja depois do boleto, uma vez por mês)
var end_reason := ""             # por que a partida acabou: "cheque" quando o cheque especial zera
var month_boss := ""             # chefe do mês atual (sorteado quando o mês começa)
var bosses_done: Array = []      # chefes que já saíram nesta partida (não voltam)
var kind_counts: Dictionary = {} # quantas vezes cada formação foi jogada na partida (Malha fina)
var half_price := false          # Black Friday: a Banca seguinte vende pela metade
var endless := false             # modo infinito: já venceu os RUN_MONTHS meses e escolheu continuar

# Último comprovante (preenchido ao pagar uma conta).
var receipt: Dictionary = {}

var bill: BillRound
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng
	_draw_boss()
	_start_bill()


func bill_key() -> String:
	return Balance.BILL_KEYS[bill_index]


func month_name() -> String:
	var name := tr(Balance.MONTHS[month_index % Balance.MONTHS.size()]["name"])
	var year := month_index / Balance.MONTHS.size()
	return name if year == 0 else "%s %d" % [name, year + 1]


func bill_title() -> String:
	return "%s · %s" % [month_name(), tr(Balance.BILL_LABELS[bill_key()])]


## Chefe do mês: só na fatura (3ª conta do mês). Boleto e Aluguel não têm chefe.
func boss_id() -> String:
	if bill_key() == "fatura":
		return month_boss
	return Boss.NONE


## Nível do chefe deste mês (dificuldade adaptativa).
func boss_level() -> int:
	return Boss.level_of(month_index)


## Sorteia o chefe do mês. Chefe com data cai no mês dele; os outros saem por faixa de peso,
## sem repetir. No modo infinito vale qualquer faixa, até acabarem os chefes.
func _draw_boss() -> void:
	var month_of_year := month_index % Balance.MONTHS.size()
	var pick := ""
	for id in Balance.BOSS_FIXED_MONTH:
		if int(Balance.BOSS_FIXED_MONTH[id]) == month_of_year and not bosses_done.has(id):
			pick = id
	if pick == "":
		var tier := ""
		if month_index < Balance.BOSS_TIER_BY_MONTH.size():
			tier = Balance.BOSS_TIER_BY_MONTH[month_index]
		var pool := _boss_pool(tier, false)
		if pool.is_empty():
			pool = _boss_pool("", false)
		if pool.is_empty():
			pool = _boss_pool("", true)  # só sobraram chefes com data: saem fora do mês, para a partida poder acabar
		if not pool.is_empty():
			pick = pool[_rand_int(pool.size())]
	month_boss = pick
	if pick != "":
		bosses_done.append(pick)


## Chefes que ainda não saíram, da faixa `tier` ("" = todas). `with_fixed` inclui os chefes com data.
func _boss_pool(tier: String, with_fixed: bool) -> Array:
	var pool: Array = []
	for t in Balance.BOSS_TIERS:
		if tier != "" and t != tier:
			continue
		for id in Balance.BOSS_TIERS[t]:
			if bosses_done.has(id):
				continue
			if Balance.BOSS_FIXED_MONTH.has(id) and not with_fixed:
				continue
			pool.append(id)
	return pool


## Valor extra do Curso do Primo Rico, em %: CURSO_VALOR_PERCENT a cada CURSO_STEP_CONTAS contas pagas.
func valor_percent() -> int:
	if not curso_matriculado:
		return 0
	return Balance.CURSO_VALOR_PERCENT * (curso_contas / Balance.CURSO_STEP_CONTAS)


## Última conta de todas: a fatura do último chefe. Depois dela não há como continuar.
func is_last_bill() -> bool:
	return month_index >= Balance.TOTAL_MONTHS - 1 and bill_index == Balance.BILL_KEYS.size() - 1


## Última conta da partida normal: a fatura do mês RUN_MONTHS. No modo infinito ela é uma conta comum.
func is_goal_bill() -> bool:
	return not endless and month_index == Balance.RUN_MONTHS - 1 and bill_index == Balance.BILL_KEYS.size() - 1


## Venceu a partida normal e ainda há chefes pela frente: pode seguir no modo infinito.
func can_continue() -> bool:
	return state == WON and not is_last_bill()


## Modo infinito: volta ao comprovante da conta paga e a partida segue, até perder ou acabar os chefes.
func continue_endless() -> bool:
	if not can_continue():
		return false
	endless = true
	state = BILL_PAID
	return true


## Contas pagas até agora, contando a atual quando ela já foi paga.
func bills_paid() -> int:
	var done := month_index * Balance.BILL_KEYS.size() + bill_index
	return done + 1 if state in [BILL_PAID, SHOP, WON] else done


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
	var kind: String = result["score"]["kind"]
	if kind == "escadinha" and schemes.has("cunhado"):
		cunhado_bonus += 1
	if kind != "none":
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1

	if result["state"] == BillRound.WON:
		_settle_paid_bill()
	elif result["state"] == BillRound.LOST:
		state = LOST
	return result


func swap() -> Dictionary:
	if state != PLAYING:
		return {"ok": false, "reason": "run_not_playing", "state": state}
	var cost := bill.swap_cost()
	# Cheque especial: sem dinheiro nem limite, a troca é recusada.
	if not can_spend(cost):
		return {"ok": false, "reason": "no_money", "state": state}
	var result := bill.swap()
	if result["ok"]:
		_spend(cost)
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
	# Contatos: uma vez por mês, na loja que vem depois do boleto. Só um por vez, sorteado entre os que faltam.
	contact_offer = []
	if bill_key() == "boleto":
		var left: Array = []
		for id in Balance.CONTACT_ORDER:
			if not contacts_owned.has(id):
				left.append(id)
		if not left.is_empty():
			contact_offer = [left[_rand_int(left.size())]]
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
		_draw_boss()
	state = PLAYING
	half_price = false
	contact_offer = []
	_start_bill()
	return true


## Cheque especial: quanto um gasto de `amount` passa do dinheiro que há na carteira.
func overdraft_draw(amount: int) -> int:
	return maxi(0, amount - maxi(wallet, 0))


## Cheque sem limite (contato Cheque Sem Fundo): o limite vira ∞.
func overdraft_unlimited() -> bool:
	return contacts_owned.has("sem_fundo")


## Juros do cheque especial: cada R$ usado vira essa dívida. Gerente e Sem Fundo baixam para 2x.
func overdraft_juros() -> int:
	if contacts_owned.has("gerente") or contacts_owned.has("sem_fundo"):
		return Balance.OVERDRAFT_JUROS_GERENTE
	return Balance.OVERDRAFT_JUROS


## Cheque Sem Fundo: quanto a dívida sobe a meta da próxima conta, em %.
func debt_goal_percent() -> int:
	if not overdraft_unlimited() or wallet >= 0:
		return 0
	return -wallet / Balance.SEM_FUNDO_DEBT_STEP


## Pode gastar `amount`? Se faltar dinheiro, o cheque cobre, até o limite que ainda resta.
func can_spend(amount: int) -> bool:
	if wallet - amount >= 0 or overdraft_unlimited():
		return true
	return overdraft_draw(amount) <= overdraft_left


## Gasta `amount`. O que passa da carteira vira dívida (juros) e usa o cheque.
## Gastar o último R$ do cheque acaba a partida. Chame só depois de can_spend().
func _spend(amount: int) -> void:
	var draw := overdraft_draw(amount)
	if draw == 0:
		wallet -= amount
		return
	wallet = wallet - amount - (overdraft_juros() - 1) * draw
	if not overdraft_unlimited():
		overdraft_left -= draw
		if overdraft_left <= 0:
			overdraft_left = 0
			end_reason = "cheque"
			state = LOST


## Compra um contato da loja (uso único: o efeito fica para o resto da partida).
func buy_contact(id: String) -> Dictionary:
	if state != SHOP:
		return {"ok": false, "reason": "not_shop"}
	if not contact_offer.has(id):
		return {"ok": false, "reason": "bad_index"}
	var price := price_of(id)
	if not can_spend(price):
		return {"ok": false, "reason": "no_money"}
	_spend(price)
	contacts_owned.append(id)
	contact_offer.erase(id)
	return {"ok": true, "reason": "", "id": id}


## Compra a oferta de índice `index` (esquema ou investimento). Pode usar o cheque especial.
func buy(index: int) -> Dictionary:
	var refusal := _check_shop(index, shop_offer)
	if not refusal.is_empty():
		return refusal
	var id: String = shop_offer[index]
	if id == "":  # oferta já comprada: o espaço fica vazio até a próxima visita
		return {"ok": false, "reason": "bad_index"}
	var price := price_of(id)
	if not can_spend(price):
		return {"ok": false, "reason": "no_money"}

	if Investments.is_investment(id):
		_spend(price)
		var kind := Investments.transaction_of(id)
		var drop := id == "cripto" and _rand_int(Balance.CRIPTO_DROP_ODDS) == 0
		levels[kind] = Investments.level_after_purchase(id, int(levels.get(kind, 0)), drop)
		# A oferta comprada vira espaço vazio: as outras não mudam de lugar.
		shop_offer[index] = ""
		bought_last_shop = true
		return {"ok": true, "reason": "", "id": id, "dropped": drop}

	if schemes.size() >= Balance.MAX_SCHEMES:
		return {"ok": false, "reason": "slots_full"}
	_spend(price)
	schemes.append(id)
	shop_offer[index] = ""
	bought_last_shop = true
	return {"ok": true, "reason": "", "id": id}


func price_of(id: String) -> int:
	var price: int
	if Balance.CONTACTS.has(id):
		price = Balance.CONTACTS[id]["price"]
	elif Investments.is_investment(id):
		price = Balance.INVESTMENTS[id]["price"]
	else:
		price = Balance.SCHEMES[id]["price"]
	# Black Friday: a Banca depois da fatura vende pela metade (arredonda para cima).
	if half_price:
		price = (price * Balance.BLACK_FRIDAY_PRICE_PERCENT + 99) / 100
	return price


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
	if not can_spend(Balance.HAGGLE_COST):
		return {"ok": false, "reason": "no_money"}
	_spend(Balance.HAGGLE_COST)
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
	reward = reward * Boss.reward_percent(boss_id()) / 100
	half_price = boss_id() == "black_friday"
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
	state = WON if is_last_bill() or is_goal_bill() else BILL_PAID


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
	# Golpe do falso gerente e Plano Collor: parte da carteira some no começo da conta.
	var loss_percent := Boss.wallet_loss_percent(boss, boss_level())
	if loss_percent > 0 and wallet > 0:
		var loss := (wallet * loss_percent + 99) / 100
		wallet -= loss
		boss_note = tr("Sumiu da carteira: R$ %d.") % loss
	var goal: int = Balance.goal_of(month_index, bill_key())
	goal = goal * Boss.goal_percent(boss, bought_last_shop, boss_level(), wallet) / 100
	goal += goal * debt_goal_percent() / 100
	bill = BillRound.new(goal, boss, _rng, active, cunhado_bonus, levels, valor_percent())
	bill.boss_level = boss_level()
	# Malha fina: a formação mais jogada na partida não pontua nesta conta.
	if boss == "malha_fina":
		var top := ""
		for kind in kind_counts:
			if top == "" or int(kind_counts[kind]) > int(kind_counts[top]):
				top = kind
		if top != "":
			bill.blocked_kinds = [top]
			boss_note = tr("Na malha fina: %s.") % tr(Balance.TRANSACTIONS[top]["name"])


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
		"overdraft_left": overdraft_left,
		"contacts_owned": contacts_owned,
		"contact_offer": contact_offer,
		"end_reason": end_reason,
		"endless": endless,
		"month_boss": month_boss,
		"bosses_done": bosses_done,
		"kind_counts": kind_counts,
		"half_price": half_price,
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
	r.overdraft_left = int(d["overdraft_left"])
	r.contacts_owned = d["contacts_owned"]
	r.contact_offer = d["contact_offer"]
	r.end_reason = String(d["end_reason"])
	r.endless = bool(d.get("endless", false))
	r.month_boss = String(d["month_boss"])
	r.bosses_done = d["bosses_done"]
	r.kind_counts = {}
	for k in d["kind_counts"]:
		r.kind_counts[k] = int(d["kind_counts"][k])
	r.half_price = bool(d["half_price"])
	r.curso_matriculado = bool(d["curso_matriculado"])
	r.curso_contas = int(d["curso_contas"])
	r.bought_last_shop = bool(d["bought_last_shop"])
	r.boss_note = String(d["boss_note"])
	r.receipt = d["receipt"]
	r.bill = BillRound.from_dict(d["bill"])
	return r
