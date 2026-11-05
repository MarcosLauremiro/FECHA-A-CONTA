class_name BillRound
extends RefCounted
## Uma conta (rodada): dias, trocas, meta de saldo e a mão do jogador.
## Só regra, sem nada visual. A interface chama estes métodos e lê os campos.

const PLAYING := "playing"
const WON := "won"
const LOST := "lost"

var goal: int
var deck: Deck
var hand: Array = []
var selected: Array = []  # Note objects escolhidos na mão
var days_left: int = Balance.DAYS_PER_BILL
var swaps_left: int = Balance.SWAPS_PER_BILL
var saldo: int = 0
var state: String = PLAYING
var boss: String = Boss.NONE  # id do chefe desta conta ("" = conta comum)
var schemes: Array = []       # esquemas ativos nesta conta (ids)
var cunhado_bonus: int = 0    # Juros acumulado do Cunhado (vem da partida)
var levels: Dictionary = {}   # níveis dos investimentos, {transação: nível} (vem da partida)

var _rng: RandomNumberGenerator
var _relampago_used := false  # Relâmpago Errado só duplica uma vez por conta


func _init(p_goal: int, p_boss: String = Boss.NONE, rng: RandomNumberGenerator = null, p_schemes: Array = [], p_cunhado: int = 0, p_levels: Dictionary = {}) -> void:
	goal = p_goal
	boss = p_boss
	schemes = p_schemes.duplicate()
	cunhado_bonus = p_cunhado
	levels = p_levels.duplicate()
	_rng = rng
	deck = Deck.new(rng)
	_refill()


## Liga/desliga a seleção de uma nota da mão. Máximo de MAX_PLAYED notas.
func toggle_select(note: Note) -> bool:
	if state != PLAYING or not hand.has(note):
		return false
	if selected.has(note):
		selected.erase(note)
		return true
	if selected.size() >= Balance.MAX_PLAYED:
		return false
	selected.append(note)
	return true


## PAGAR: pontua as notas escolhidas e gasta 1 dia.
## Notas que o chefe não deixa pontuar saem da conta; o imposto do chefe é descontado do total.
## Devolve {"ok": bool, "reason": String, "score": Dictionary, "state": String, "cash": int}.
## "cash" é o dinheiro que a jogada devolve na carteira (Cashback); quem chama soma na carteira.
func pay() -> Dictionary:
	var refusal := _check_can_act()
	if not refusal.is_empty():
		return refusal

	var played := selected.duplicate()
	var scoring: Array = []
	for n in played:
		if Boss.note_scores(boss, n):
			scoring.append(n)

	var fx := {
		"schemes": schemes,
		"played": played.size(),
		"hand_points": _hand_points_left(played),
		"cunhado_bonus": cunhado_bonus,
		"levels": levels,
		"rifa": _roll_rifa(),
	}
	var score := Scorer.score(HandEvaluator.evaluate(scoring), fx)
	var tax := Boss.play_tax(boss, score["total"])
	score["tax"] = tax
	saldo += score["total"] - tax

	var cash := SchemeRules.cash_from_scoring(schemes, scoring)
	_relampago_copy(played)

	_leave_hand(played)
	deck.discard(played)
	days_left -= 1
	_refill()

	if saldo >= goal:
		state = WON
	elif days_left == 0:
		state = LOST

	return {"ok": true, "reason": "", "score": score, "state": state, "cash": cash}


## TROCAR: descarta as notas escolhidas e compra o mesmo número de novas. Gasta 1 troca.
func swap() -> Dictionary:
	var refusal := _check_can_act()
	if not refusal.is_empty():
		return refusal
	if swaps_left <= 0:
		return {"ok": false, "reason": "no_swaps", "state": state}

	var discarded := selected.duplicate()
	_leave_hand(discarded)
	deck.discard(discarded)
	swaps_left -= 1
	_refill()

	return {"ok": true, "reason": "", "state": state}


## Custo em R$ de cada troca nesta conta (imposto do chefe, se houver).
func swap_cost() -> int:
	return Boss.swap_cost(boss)


## Recompensa ao bater a meta: base da conta + R$ por dia não usado.
func reward(base_reward: int) -> int:
	if state != WON:
		return 0
	return base_reward + days_left * Balance.REWARD_PER_UNUSED_DAY


func is_over() -> bool:
	return state != PLAYING


func _check_can_act() -> Dictionary:
	if state != PLAYING:
		return {"ok": false, "reason": "round_over", "state": state}
	if selected.is_empty():
		return {"ok": false, "reason": "no_selection", "state": state}
	return {}


## Soma dos pontos das notas que ficaram na mão (Vaquinha). Zero sem o esquema.
func _hand_points_left(played: Array) -> int:
	if not schemes.has("vaquinha"):
		return 0
	var total := 0
	for n in hand:
		if not played.has(n):
			total += n.points()
	return total


## Rifa do Bairro: 1 em RIFA_ODDS chance de multiplicar o Juros.
func _roll_rifa() -> bool:
	if not schemes.has("rifa"):
		return false
	return _rand_int(Balance.RIFA_ODDS) == 0


## Relâmpago Errado: a primeira nota de Relâmpago jogada nesta conta é copiada para o baralho.
func _relampago_copy(played: Array) -> void:
	if not schemes.has("relampago_errado") or _relampago_used:
		return
	for n in played:
		if n.suit == Note.Suit.RELAMPAGO:
			deck.draw_pile.append(Note.new(n.value, n.suit))
			deck.shuffle(_rng)
			_relampago_used = true
			return


func _rand_int(n: int) -> int:
	if _rng != null:
		return _rng.randi_range(0, n - 1)
	return randi_range(0, n - 1)


## Estado da conta para salvar. As notas selecionadas são guardadas pela posição na mão.
func to_dict() -> Dictionary:
	var selected_idx: Array = []
	for n in selected:
		selected_idx.append(hand.find(n))
	return {
		"goal": goal,
		"boss": boss,
		"days_left": days_left,
		"swaps_left": swaps_left,
		"saldo": saldo,
		"state": state,
		"schemes": schemes,
		"cunhado_bonus": cunhado_bonus,
		"levels": levels,
		"relampago_used": _relampago_used,
		"deck": deck.to_dict(),
		"hand": Note.list_to_data(hand),
		"selected": selected_idx,
	}


static func from_dict(d: Dictionary) -> BillRound:
	var levels_in: Dictionary = {}
	for k in d["levels"]:
		levels_in[k] = int(d["levels"][k])
	var b := BillRound.new(int(d["goal"]), String(d["boss"]), null, d["schemes"], int(d["cunhado_bonus"]), levels_in)
	b.deck = Deck.from_dict(d["deck"])
	b.hand = Note.list_from_data(d["hand"])
	b.selected = []
	for i in d["selected"]:
		if int(i) >= 0 and int(i) < b.hand.size():
			b.selected.append(b.hand[int(i)])
	b.days_left = int(d["days_left"])
	b.swaps_left = int(d["swaps_left"])
	b.saldo = int(d["saldo"])
	b.state = String(d["state"])
	b._relampago_used = bool(d["relampago_used"])
	return b


func _leave_hand(cards: Array) -> void:
	for c in cards:
		hand.erase(c)
	selected.clear()


func _refill() -> void:
	var missing := Balance.HAND_SIZE - hand.size()
	if missing > 0:
		hand.append_array(deck.draw(missing, _rng))
