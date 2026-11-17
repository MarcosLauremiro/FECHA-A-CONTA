class_name Fx
extends RefCounted
## Efeitos visuais de uma vez só: estouro de fagulhas, moedas pulando, chuva de notas e clarão de tela.
## Cada efeito cria o próprio nó dentro de `layer` e se apaga sozinho quando acaba.
## As partículas usam a arte de art/efeitos (32x32, pixel art: filtro "nearest" para não borrar).

const TEX := {
	"fagulha": "res://art/efeitos/particula_fagulha.png",
	"moeda": "res://art/efeitos/particula_moeda.png",
	"nota": "res://art/efeitos/particula_nota.png",
}
const SCREEN := Vector2(1280, 720)


## Fagulhas que estouram em volta de `pos` (impacto de uma nota que pontua).
static func sparks(layer: Node, pos: Vector2, amount: int = 9) -> void:
	var p := _particles(layer, "fagulha", amount, 0.45)
	p.position = pos
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 300.0
	p.damping_min = 300.0
	p.damping_max = 420.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	_start(p, 0.0)


## Moedas que pulam para cima a partir de `pos` e caem com gravidade (dinheiro entrando).
static func coins(layer: Node, pos: Vector2, amount: int = 14) -> void:
	var p := _particles(layer, "moeda", amount, 1.2)
	p.position = pos
	p.explosiveness = 0.85
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.initial_velocity_min = 280.0
	p.initial_velocity_max = 520.0
	p.gravity = Vector2(0, 1100)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.1
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	_start(p, 0.0)


## Chuva que cai do alto da tela por `duration` segundos: "nota" (comemoração) ou "moeda".
static func rain(layer: Node, kind: String, amount: int, duration: float) -> void:
	var life := 3.2
	var p := _particles(layer, kind, amount, life)
	p.position = Vector2(SCREEN.x / 2.0, -40.0)
	p.one_shot = true
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(SCREEN.x / 2.0, 10.0)
	p.direction = Vector2(0, 1)
	p.spread = 25.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	# Notas balançam de lado, como papel caindo.
	if kind == "nota":
		p.gravity = Vector2(0, 140)
		p.tangential_accel_min = -40.0
		p.tangential_accel_max = 40.0
	# Em one_shot, as partículas saem ao longo de um "lifetime"; esticar o tempo de vida espalha a chuva.
	p.lifetime = maxf(life, duration)
	p.randomness = 0.6
	_start(p, 0.0)


## Clarão que cobre a tela e some (ex.: vermelho na derrota, branco no comprovante gigante).
static func flash(layer: Node, color: Color, time: float = 0.5) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = SCREEN
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var tween := rect.create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(rect.queue_free)


## Soco de escala em um elemento (cresce e volta), a partir do centro dele.
static func punch(node: Control, amount: float = 1.15, time: float = 0.22) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * amount, time * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, time * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Balanço de lado ("não"): usado quando falta dinheiro ou a ação é recusada.
static func nope(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	var x := node.position.x
	var tween := node.create_tween()
	for dx in [10.0, -8.0, 6.0, -4.0, 0.0]:
		tween.tween_property(node, "position:x", x + dx, 0.045)


# --- Montagem ----------------------------------------------------------------

static func _particles(layer: Node, kind: String, amount: int, lifetime: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = load(TEX[kind]) as Texture2D
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.amount = maxi(1, amount)
	p.lifetime = lifetime
	p.one_shot = true
	p.emitting = false
	p.local_coords = false
	# Some no fim da vida (o tamanho fica, só a transparência cai).
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	p.color_ramp = fade
	layer.add_child(p)
	return p


static func _start(p: CPUParticles2D, delay: float) -> void:
	p.emitting = true
	# Apaga o nó depois que a última partícula some.
	p.get_tree().create_timer(delay + p.lifetime * 2.0 + 0.5).timeout.connect(p.queue_free)
