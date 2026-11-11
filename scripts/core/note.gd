class_name Note
extends RefCounted
## Uma nota do baralho: valor em R$ e forma de pagamento (naipe).

enum Suit { DINHEIRO, PIX, DEBITO, CREDITO }

var value: int
var suit: int


func _init(p_value: int = 1, p_suit: int = Suit.DINHEIRO) -> void:
	value = p_value
	suit = p_suit


## Posição do valor na sequência 1-2-5-10-20-50-100-200-500-1000 (0 a 9).
func rank() -> int:
	return Balance.VALUES.find(value)


## Pontos de Valor que esta nota soma quando pontua.
func points() -> int:
	return Balance.VALUE_POINTS[value]


func suit_name() -> String:
	return tr(Balance.SUIT_NAMES[suit])


## Caminho da frente desta nota: cédula neutra, sem forma de pagamento.
func face_path() -> String:
	return "res://art/notas/neutras/nota_%d.png" % value


## Caminho do selo da forma de pagamento (carimbo desenhado por cima da cédula).
func stamp_path() -> String:
	return "res://art/notas/selos/selo_%s.png" % Balance.SUIT_KEYS[suit]


func _to_string() -> String:
	return "R$%d·%s" % [value, suit_name()]


## Versão guardável (salvar partida): [valor, forma].
static func list_to_data(notes: Array) -> Array:
	var out: Array = []
	for n in notes:
		out.append([n.value, n.suit])
	return out


static func list_from_data(data: Array) -> Array:
	var out: Array = []
	for d in data:
		out.append(Note.new(int(d[0]), int(d[1])))
	return out
