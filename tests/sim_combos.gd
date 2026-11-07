extends SceneTree
## Simulação de balanceamento: com que frequência cada combinação é a melhor jogada numa mão de 8 notas.
##
## - Usa HandEvaluator, ou seja, as regras reais do jogo, em todas as combinações de 1 a 5 notas da mão.
## - Roda duas vezes: sem formações liberadas, e com Dois Carnês e Conta Conjunta liberadas.
##   Na segunda, é como se o jogador já tivesse os dois investimentos.
##
## Rodar: godot --headless --path . -s res://tests/sim_combos.gd
## Ajuste HANDS para mais ou menos mãos (mais mãos = resultado mais estável, porém mais lento).

const HANDS := 30000
const SEED := 12345
const HAND_SIZE := 8       # Balance.HAND_SIZE
const MAX_PLAYED := 5      # Balance.MAX_PLAYED


func _initialize() -> void:
	_run("sem formações liberadas", [])
	_run("com Dois Carnês e Conta Conjunta liberadas", Balance.UNLOCKABLE_KINDS)
	quit()


func _run(title: String, unlocked: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var best_count := {}
	var points_sum := 0
	for _h in range(HANDS):
		var hand := _deal(rng)
		var best := _best_play(_subsets(hand), unlocked)
		best_count[best["kind"]] = best_count.get(best["kind"], 0) + 1
		points_sum += best["points"]
	print("")
	print("-- Melhor jogada, %s (%d mãos) --" % [title, HANDS])
	var kinds: Array = best_count.keys()
	kinds.sort_custom(func(a, b) -> bool: return best_count[a] > best_count[b])
	for kind in kinds:
		print("  %-20s %6.2f%%" % [kind, 100.0 * best_count[kind] / HANDS])
	print("  pontos médios da melhor jogada: %.1f" % (float(points_sum) / HANDS))


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


## Melhor jogada da mão pelas regras (mesma força que o jogo usa para ordenar).
func _best_play(subs: Array, unlocked: Array) -> Dictionary:
	var best := {"kind": "none", "points": 0, "strength": -1}
	for sub in subs:
		var ev := HandEvaluator.evaluate(sub, unlocked)
		var s := HandEvaluator._strength(ev)
		if s > best["strength"]:
			best = {"kind": ev["kind"], "points": _points(ev["cards"]), "strength": s}
	return best


func _points(cards: Array) -> int:
	var total := 0
	for n in cards:
		total += n.points()
	return total
