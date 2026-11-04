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

var _rng: RandomNumberGenerator


func _init(p_goal: int, rng: RandomNumberGenerator = null) -> void:
	goal = p_goal
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
## Devolve {"ok": bool, "reason": String, "score": Dictionary, "state": String}.
func pay() -> Dictionary:
	var refusal := _check_can_act()
	if not refusal.is_empty():
		return refusal

	var played := selected.duplicate()
	var score := Scorer.score(HandEvaluator.evaluate(played))
	saldo += score["total"]

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
