class_name Note
extends RefCounted
## Uma nota do baralho: valor em R$ e forma de pagamento (naipe).

enum Suit { DINHEIRO, RELAMPAGO, DEBITO, CREDITO }

var value: int
var suit: int


func _init(p_value: int = 1, p_suit: int = Suit.DINHEIRO) -> void:
	value = p_value
	suit = p_suit


## Posição do valor na sequência 1-2-5-10-20-50-100-200 (0 a 7).
func rank() -> int:
	return Balance.VALUES.find(value)


## Pontos de Valor que esta nota soma quando pontua.
func points() -> int:
	return Balance.VALUE_POINTS[value]


func suit_name() -> String:
	return Balance.SUIT_NAMES[suit]


## Caminho da frente desta nota (nota já com a forma de pagamento impressa).
func face_path() -> String:
	return "res://art/notas/frentes/frente_%d_%s.png" % [value, Balance.SUIT_KEYS[suit]]


func _to_string() -> String:
	return "R$%d·%s" % [value, suit_name()]
