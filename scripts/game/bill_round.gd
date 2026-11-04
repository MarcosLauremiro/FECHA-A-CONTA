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

var _rng: RandomNumberGenerator


func _init(p_goal: int, p_boss: String = Boss.NONE, rng: RandomNumberGenerator = null) -> void:
	goal = p_goal
	boss = p_boss
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
## Devolve {"ok": bool, "reason": String, "score": Dictionary, "state": String}.
func pay() -> Dictionary:
	var refusal := _check_can_act()
	if not refusal.is_empty():
		return refusal

	var played := selected.duplicate()
	var scoring: Array = []
	for n in played:
		if Boss.note_scores(boss, n):
			scoring.append(n)
	var score := Scorer.score(HandEvaluator.evaluate(scoring))
	var tax := Boss.play_tax(boss, score["total"])
	score["tax"] = tax
	saldo += score["total"] - tax

	_leave_hand(played)
	deck.discard(played)
	days_left -= 1
	_refill()

	if saldo >= goal:
		state = WON
	elif days_left == 0:
		state = LOST

	return {"ok": true, "reason": "", "score": score, "state": state}


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


func _leave_hand(cards: Array) -> void:
	for c in cards:
		hand.erase(c)
	selected.clear()


func _refill() -> void:
	var missing := Balance.HAND_SIZE - hand.size()
	if missing > 0:
		hand.append_array(deck.draw(missing, _rng))
