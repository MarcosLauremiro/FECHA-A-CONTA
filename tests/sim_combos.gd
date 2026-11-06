extends SceneTree
## Simulação de balanceamento: com que frequência cada combinação aparece numa mão de 8 notas.
##
## - A "melhor jogada" usa HandEvaluator, ou seja, as regras reais do jogo, em todas as
##   combinações de 1 a 5 notas da mão (o melhor jogo possível de quem sabe jogar).
## - As combinações PROPOSTAS (Conta Conjunta, Cesta Básica, Dois Carnês, PIX) ainda não existem
##   no jogo. Os detectores ficam só aqui, para medir a frequência antes de implementar.
##
## Rodar: godot --headless --path . -s res://tests/sim_combos.gd
## Ajuste HANDS para mais ou menos mãos (mais mãos = resultado mais estável, porém mais lento).

const HANDS := 50000
const SEED := 12345
const HAND_SIZE := 8       # Balance.HAND_SIZE
const MAX_PLAYED := 5      # Balance.MAX_PLAYED


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var best_count := {}      # melhor jogada (regras atuais) -> nº de mãos
	var proposed := {"conta_conjunta": 0, "dois_carnes": 0, "cesta_basica": 0, "cesta_basica_baixa": 0, "pix": 0, "algum_par": 0}
	var points_sum := 0

	for _h in range(HANDS):
		var hand := _deal(rng)
		var subs := _subsets(hand)

		var best := _best_play(subs)
		best_count[best["kind"]] = best_count.get(best["kind"], 0) + 1
		points_sum += best["points"]

		# Combinações propostas: a mão conta se ALGUMA jogada de 5 notas tiver a combinação.
		var found := {}
		for sub in subs:
			if sub.size() != MAX_PLAYED:
				continue
			var shape := _shape(sub)
			if shape == [3, 2]:
				found["conta_conjunta"] = true
			if shape == [2, 2, 1]:
				found["dois_carnes"] = true
			if shape == [1, 1, 1, 1, 1] and not HandEvaluator._is_sequence(sub):
				found["cesta_basica"] = true
				if _cheap_count(sub) >= 3:
					found["cesta_basica_baixa"] = true
			if HandEvaluator._is_sequence(sub) and HandEvaluator._is_same_suit(sub):
				found["pix"] = true
		if _has_pair(hand):
			found["algum_par"] = true
		for k in found:
			proposed[k] += 1

	_report(best_count, proposed, points_sum)
	quit()


## Quantas notas da jogada têm valor até 10 (variante "cesta barata" da Cesta Básica).
func _cheap_count(sub: Array) -> int:
	var total := 0
	for n in sub:
		if n.value <= 10:
			total += 1
	return total


## Compra HAND_SIZE notas de um baralho completo (32 notas), embaralhado com o RNG da simulação.
func _deal(rng: RandomNumberGenerator) -> Array:
	var deck: Array = []
	for suit in Note.Suit.values():
		for value in Balance.VALUES:
			deck.append(Note.new(value, suit))
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
	return deck.slice(0, HAND_SIZE)


## Todas as jogadas possíveis: subconjuntos de 1 a MAX_PLAYED notas da mão.
func _subsets(hand: Array) -> Array:
	var out: Array = []
	for mask in range(1, 1 << hand.size()):
		var picked: Array = []
		for i in range(hand.size()):
			if mask & (1 << i):
				picked.append(hand[i])
		if picked.size() <= MAX_PLAYED:
			out.append(picked)
	return out


## Melhor jogada da mão pelas regras atuais (mesma força que o jogo usa para ordenar).
func _best_play(subs: Array) -> Dictionary:
	var best := {"kind": "none", "points": 0, "strength": -1}
	for sub in subs:
		var ev := HandEvaluator.evaluate(sub)
		var s := HandEvaluator._strength(ev)
		if s > best["strength"]:
			best = {"kind": ev["kind"], "points": _points(ev["cards"]), "strength": s}
	return best


func _points(cards: Array) -> int:
	var total := 0
	for n in cards:
		total += n.points()
	return total


## Quantidade de notas de cada valor, em ordem decrescente. Ex.: [3, 2] para trinca + par.
func _shape(sub: Array) -> Array:
	var by_value := {}
	for n in sub:
		by_value[n.value] = by_value.get(n.value, 0) + 1
	var counts: Array = by_value.values()
	counts.sort()
	counts.reverse()
	return counts


func _has_pair(hand: Array) -> bool:
	var by_value := {}
	for n in hand:
		by_value[n.value] = by_value.get(n.value, 0) + 1
	for v in by_value:
		if by_value[v] >= 2:
			return true
	return false


func _report(best_count: Dictionary, proposed: Dictionary, points_sum: int) -> void:
	print("")
	print("Mãos simuladas: %d  (semente %d)" % [HANDS, SEED])
	print("")
	print("-- Melhor jogada, regras atuais --")
	var kinds: Array = best_count.keys()
	kinds.sort_custom(func(a, b) -> bool: return best_count[a] > best_count[b])
	for kind in kinds:
		print("  %-20s %6.2f%%" % [kind, 100.0 * best_count[kind] / HANDS])
	print("  pontos médios da melhor jogada: %.1f" % (float(points_sum) / HANDS))
	print("")
	print("-- Combinações propostas (presentes em alguma jogada de 5 notas da mão) --")
	for k in ["algum_par", "conta_conjunta", "dois_carnes", "cesta_basica", "cesta_basica_baixa", "pix"]:
		print("  %-20s %6.2f%%" % [k, 100.0 * proposed[k] / HANDS])
	print("")
