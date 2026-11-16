class_name CreditsScreen
extends Control
## Página de créditos, aberta por cima da tela de título: CreditsScreen.open(pai).

const PANEL := Rect2(340, 110, 600, 500)
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const PAPER_HOVER := Color("FFF8E7")
const PAPER_DOWN := Color("D9CCAE")
const AUTHOR := "Lauremiro"
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"


## Abre os créditos por cima de `parent`.
static func open(parent: Node) -> CreditsScreen:
	var screen := CreditsScreen.new()
	parent.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = INK
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = PANEL.position
	panel.size = PANEL.size
	add_child(panel)

	_label(panel, tr("CRÉDITOS"), Rect2(0, 24, PANEL.size.x, 50), FONT_TITLE, 40)
	_label(panel, "BOLETRO", Rect2(0, 96, PANEL.size.x, 80), FONT_TITLE, 64)
	_label(panel, tr("Desenvolvido por %s") % AUTHOR, Rect2(0, 186, PANEL.size.x, 40), FONT_TERMINAL, 32)

	var discord := SocialLinks.make_button("DISCORD", SocialLinks.DISCORD_URL, Vector2(260, 52))
	discord.position = Vector2(PANEL.size.x / 2.0 - 130, 262)
	panel.add_child(discord)
	var instagram := SocialLinks.make_button("INSTAGRAM", SocialLinks.INSTAGRAM_URL, Vector2(260, 52))
	instagram.position = Vector2(PANEL.size.x / 2.0 - 130, 330)
	panel.add_child(instagram)

	var back := SocialLinks.make_button(tr("VOLTAR"), "", Vector2(260, 52))
	back.position = Vector2(PANEL.size.x / 2.0 - 130, PANEL.size.y - 80)
	back.pressed.connect(queue_free)
	panel.add_child(back)


func _label(parent: Node, text: String, rect: Rect2, font_path: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(font_path) as Font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
