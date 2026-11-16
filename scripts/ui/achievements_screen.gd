class_name AchievementsScreen
extends Control
## Tela de conquistas, aberta por cima da tela de título: AchievementsScreen.open(pai).
## Cada conquista mostra o nome e a condição. Enquanto não foi feita, a medalha e o texto ficam cinza.

const PANEL := Rect2(240, 70, 800, 580)
const LIST_RECT := Rect2(40, 150, 720, 330)
const ROW_HEIGHT := 64.0
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const PAPER_ROW := Color("FFF8E7")
const GOLD := Color("E0B040")
const GREY := Color("B5B0A3")
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"


## Abre as conquistas por cima de `parent`.
static func open(parent: Node) -> AchievementsScreen:
	var screen := AchievementsScreen.new()
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

	_label(panel, tr("CONQUISTAS"), Rect2(0, 22, PANEL.size.x, 50), FONT_TITLE, 40)
	_label(panel, tr("%d de %d conquistadas") % [Achievements.count_unlocked(), Achievements.CATALOG.size()], Rect2(0, 96, PANEL.size.x, 30), FONT_TERMINAL, 26)

	var scroll := ScrollContainer.new()
	scroll.position = LIST_RECT.position
	scroll.size = LIST_RECT.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(LIST_RECT.size.x, 0)
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for item in Achievements.CATALOG:
		list.add_child(_row(item, Achievements.is_unlocked(item["id"])))

	var back := SocialLinks.make_button(tr("VOLTAR"), "", Vector2(260, 52))
	back.position = Vector2(PANEL.size.x / 2.0 - 130, PANEL.size.y - 70)
	back.pressed.connect(queue_free)
	panel.add_child(back)


func _row(item: Dictionary, unlocked: bool) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(LIST_RECT.size.x, ROW_HEIGHT)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_ROW if unlocked else Color("E4DDCB")
	style.border_color = INK if unlocked else Color(0.55, 0.55, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", style)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)

	var medal := Medal.new(unlocked)
	box.add_child(medal)

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(texts)
	var name_label := Label.new()
	name_label.text = tr(item["name"])
	name_label.add_theme_font_override("font", load(FONT_TITLE) as Font)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", INK if unlocked else Color(0.45, 0.45, 0.45))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(name_label)
	var text_label := Label.new()
	text_label.text = tr(item["text"])
	text_label.add_theme_font_override("font", load(FONT_TERMINAL) as Font)
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", INK if unlocked else Color(0.5, 0.5, 0.5))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(text_label)
	return row


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


## Medalha desenhada em código: dourada quando conquistada, cinza quando não.
class Medal extends Control:
	var _unlocked := false

	func _init(unlocked: bool) -> void:
		_unlocked = unlocked
		custom_minimum_size = Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 20.0, GOLD if _unlocked else GREY)
		draw_arc(c, 19.0, 0.0, TAU, 32, INK, 2.5)
		draw_arc(c, 12.0, 0.0, TAU, 24, INK if _unlocked else Color(0.55, 0.55, 0.55), 2.0)
