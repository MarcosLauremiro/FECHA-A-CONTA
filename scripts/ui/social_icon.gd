class_name SocialIcon
extends Control
## Ícone de rede social (só a imagem, sem texto). Clique abre o link no navegador.
## Arte em art/ui/redes/ (128 px). Ao passar o mouse, a imagem clareia.

const TEX := {
	"discord": "res://art/ui/redes/discord.png",
	"instagram": "res://art/ui/redes/instagram.png",
}

var kind := ""
var url := ""
var _texture: Texture2D
var _hover := false


func _init(icon_kind: String, link: String, diameter: float) -> void:
	kind = icon_kind
	url = link
	custom_minimum_size = Vector2(diameter, diameter)
	size = Vector2(diameter, diameter)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_texture = load(TEX[kind]) as Texture2D
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(url)


func _draw() -> void:
	if _texture == null:
		return
	var tint := Color(1.15, 1.15, 1.15) if _hover else Color.WHITE
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false, tint)
