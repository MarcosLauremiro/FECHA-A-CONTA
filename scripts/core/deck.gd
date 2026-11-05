class_name Deck
extends RefCounted
## Baralho de 32 notas: 8 valores × 4 formas de pagamento.

var draw_pile: Array = []
var discard_pile: Array = []


func _init(rng: RandomNumberGenerator = null) -> void:
	reset_full(rng)


## Monta o baralho completo, embaralhado, com todas as cartas na compra.
func reset_full(rng: RandomNumberGenerator = null) -> void:
	draw_pile.clear()
	discard_pile.clear()
	for suit in Note.Suit.values():
		for value in Balance.VALUES:
			draw_pile.append(Note.new(value, suit))
	shuffle(rng)


func shuffle(rng: RandomNumberGenerator = null) -> void:
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = tmp


## Compra até `count` notas. Se a compra acabar, o descarte volta embaralhado.
func draw(count: int, rng: RandomNumberGenerator = null) -> Array:
	var drawn: Array = []
	while drawn.size() < count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile
			discard_pile = []
			shuffle(rng)
		drawn.append(draw_pile.pop_back())
	return drawn


## Devolve notas ao descarte (notas jogadas ou trocadas).
func discard(notes: Array) -> void:
	discard_pile.append_array(notes)


func total_cards() -> int:
	return draw_pile.size() + discard_pile.size()


func to_dict() -> Dictionary:
	return {"draw": Note.list_to_data(draw_pile), "discard": Note.list_to_data(discard_pile)}


static func from_dict(d: Dictionary) -> Deck:
	var deck := Deck.new()
	deck.draw_pile = Note.list_from_data(d.get("draw", []))
	deck.discard_pile = Note.list_from_data(d.get("discard", []))
	return deck
