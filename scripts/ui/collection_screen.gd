class_name CollectionScreen
extends Control
## Coleção: chefes, esquemas, investimentos e contatos. Cada item fica cinza até ser usado uma vez no jogo
## (ver Collection). Aberta por cima da tela de título: CollectionScreen.open(pai).

const PANEL := Rect2(110, 36, 1060, 648)
const TAB_Y := 112.0
const TAB_SIZE := Vector2(236, 44)
const GRID_RECT := Rect2(140, 210, 1000, 410)
const CARD_SIZE := Vector2(184, 214)
const ART_SIZE := Vector2(150, 150)
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const PAPER_HOVER := Color("FFF8E7")
const PAPER_DOWN := Color("D9CCAE")
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"
const TAB_KINDS := [Collection.KIND_BOSS, Collection.KIND_SCHEME, Collection.KIND_INVESTMENT, Collection.KIND_CONTACT]
const TAB_LABELS := {
	Collection.KIND_BOSS: "CHEFES",
	Collection.KIND_SCHEME: "ESQUEMAS",
	Collection.KIND_INVESTMENT: "INVESTIMENTOS",
	Collection.KIND_CONTACT: "CONTATOS",
}
const GRAY_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(g * 0.7 + 0.12), c.a);
}
"""

var _kind := Collection.KIND_BOSS
var _tabs := {}
var _grid: GridContainer
var _count: Label
var _gray: ShaderMaterial


## Abre a coleção por cima de `parent`.
static func open(parent: Node) -> CollectionScreen:
	var screen := CollectionScreen.new()
	parent.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shader := Shader.new()
	shader.code = GRAY_SHADER
	_gray = ShaderMaterial.new()
	_gray.shader = shader
	_build()
	_select(_kind)


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

	_label(panel, tr("COLEÇÃO"), Rect2(0, 22, PANEL.size.x, 50), 40)

	for i in TAB_KINDS.size():
		var kind: String = TAB_KINDS[i]
		var btn := _tab_button(tr(TAB_LABELS[kind]), Vector2(PANEL.size.x / 2.0 - (TAB_KINDS.size() * TAB_SIZE.x + 3 * 12.0) / 2.0 + i * (TAB_SIZE.x + 12.0), TAB_Y - PANEL.position.y))
		btn.pressed.connect(_select.bind(kind))
		panel.add_child(btn)
		_tabs[kind] = btn

	_count = _label(panel, "", Rect2(0, 130, PANEL.size.x, 26), 22)
	_label(panel, tr("Use cada item 1 vez no jogo para desbloquear."), Rect2(0, 152, PANEL.size.x, 22), 18)

	var scroll := ScrollContainer.new()
	scroll.position = GRID_RECT.position - PANEL.position
	scroll.size = GRID_RECT.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)

	var back := _tab_button(tr("VOLTAR"), Vector2(PANEL.size.x / 2.0 - TAB_SIZE.x / 2.0, PANEL.size.y - 60))
	_style_tab(back, true)
	back.pressed.connect(queue_free)
	panel.add_child(back)


func _select(kind: String) -> void:
	_kind = kind
	for k in _tabs:
		_style_tab(_tabs[k], k == kind)
	_rebuild_grid()


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)  # sai já da grade; o queue_free só apaga no fim do quadro
		child.queue_free()
	var items := _items(_kind)
	var ids := []
	for item in items:
		ids.append(item["id"])
	var unlocked := Collection.count(_kind, ids)
	_count.text = tr("%d de %d desbloqueados") % [unlocked, items.size()]
	for item in items:
		_grid.add_child(_card(item, Collection.is_unlocked(_kind, item["id"])))


## Lista de itens de um tipo, na ordem do catálogo: id, nome, texto e arte.
func _items(kind: String) -> Array:
	var list: Array = []
	match kind:
		Collection.KIND_BOSS:
			for tier in ["leve", "medio", "pesado"]:
				for id in Balance.BOSS_TIERS[tier]:
					var boss: Dictionary = Balance.BOSSES[id]
					list.append({"id": id, "name": boss["name"], "text": boss["text"], "art": "res://art/chefes/chefe_%s.png" % id})
		Collection.KIND_SCHEME:
			for id in Balance.SCHEME_ORDER:
				var scheme: Dictionary = Balance.SCHEMES[id]
				list.append({"id": id, "name": scheme["name"], "text": scheme["desc"], "art": "res://art/esquemas/cartaz_%s.png" % id})
		Collection.KIND_INVESTMENT:
			for id in Balance.INVESTMENT_ORDER:
				var inv: Dictionary = Balance.INVESTMENTS[id]
				list.append({"id": id, "name": inv["name"], "text": inv["desc"], "art": "res://art/investimentos/%s.png" % id})
		Collection.KIND_CONTACT:
			for id in Balance.CONTACT_ORDER:
				var contact: Dictionary = Balance.CONTACTS[id]
				list.append({"id": id, "name": contact["name"], "text": contact["desc"], "art": contact["art"]})
	return list


func _card(item: Dictionary, unlocked: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_HOVER if unlocked else Color("E4DDCB")
	style.border_color = INK if unlocked else Color(0.55, 0.55, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	if unlocked and str(item["text"]).find("%") == -1:
		card.tooltip_text = tr(item["text"])

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var art := TextureRect.new()
	art.custom_minimum_size = ART_SIZE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(item["art"]):
		art.texture = load(item["art"]) as Texture2D
	if not unlocked:
		art.material = _gray
	box.add_child(art)

	var title_label := Label.new()
	title_label.text = tr(item["name"]) if unlocked else "???"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.custom_minimum_size = Vector2(CARD_SIZE.x - 20, 40)
	title_label.add_theme_font_override("font", load(FONT_TITLE) as Font)
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", INK if unlocked else Color(0.45, 0.45, 0.45))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_label)
	return card


func _tab_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = TAB_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", load(FONT_TITLE) as Font)
	btn.add_theme_font_size_override("font_size", 20)
	return btn


func _style_tab(btn: Button, active: bool) -> void:
	var bg := INK if active else PAPER_HOVER
	var fg := PAPER if active else INK
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = bg if state != "hover" or active else PAPER_DOWN
		style.border_color = INK
		style.set_border_width_all(3)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)


func _label(parent: Node, text: String, rect: Rect2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(FONT_TITLE if size >= 30 else FONT_TERMINAL) as Font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
