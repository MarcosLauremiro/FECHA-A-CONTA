class_name IntroScreen
extends Control
## Abertura do jogo: o logo BOLETRO aparece num fundo verde, fica um pouco e some,
## mostrando a tela inicial. Clique ou tecla pula a animação.

const GREEN := Color("2A7458")
const LOGO := "res://art/logo/logo_boletro.png"
const JINGLE := "res://sfx/jingle_boletro.mp3"
const FADE_IN := 0.7
const HOLD := 1.6
const FADE_OUT := 0.6

var _logo: TextureRect
var _finishing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

	var bg := ColorRect.new()
	bg.color = GREEN
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_logo = TextureRect.new()
	_logo.texture = load(LOGO) as Texture2D
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.position = Vector2(320, 180)
	_logo.size = Vector2(640, 360)
	_logo.modulate.a = 0.0
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	# Jingle de abertura (um toque só).
	var jingle := AudioStreamPlayer.new()
	jingle.stream = load(JINGLE) as AudioStream
	jingle.bus = Settings.BUS_SFX
	add_child(jingle)
	jingle.play()

	var tween := create_tween()
	tween.tween_property(_logo, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	tween.tween_callback(_finish_fade)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish_fade()
	elif event is InputEventKey and event.pressed and not event.echo:
		_finish_fade()


## Some com o logo e revela a tela inicial. Só uma vez.
func _finish_fade() -> void:
	if _finishing:
		return
	_finishing = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(queue_free)
