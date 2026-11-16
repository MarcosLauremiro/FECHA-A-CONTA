class_name AchievementToast
extends Control
## Aviso de conquista dentro da partida: uma faixa desce do topo com a medalha e o nome.
## Lê a fila de Achievements (conquistas novas) e mostra uma por vez. Não bloqueia cliques.

const BOX := Rect2(340, 0, 600, 76)
const SHOWN_Y := 14.0
const HIDDEN_Y := -90.0
const IN_TIME := 0.35
const HOLD_TIME := 2.4
const OUT_TIME := 0.3
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"

var _showing := false
var _box: Panel
var _name: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50

	_box = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	_box.add_theme_stylebox_override("panel", style)
	_box.position = Vector2(BOX.position.x, HIDDEN_Y)
	_box.size = BOX.size
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	add_child(_box)

	var medal := AchievementsScreen.Medal.new(true)
	medal.position = Vector2(16, (BOX.size.y - 44) / 2.0)
	_box.add_child(medal)

	var head := Label.new()
	head.text = tr("CONQUISTA DESBLOQUEADA")
	head.position = Vector2(76, 8)
	head.size = Vector2(500, 22)
	head.add_theme_font_override("font", load(FONT_TERMINAL) as Font)
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", INK)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(head)

	_name = Label.new()
	_name.position = Vector2(76, 30)
	_name.size = Vector2(500, 36)
	_name.add_theme_font_override("font", load(FONT_TITLE) as Font)
	_name.add_theme_font_size_override("font_size", 28)
	_name.add_theme_color_override("font_color", INK)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_name)


func _process(_delta: float) -> void:
	if _showing or not Achievements.has_pending():
		return
	_show(Achievements.pop_pending())


func _show(id: String) -> void:
	_showing = true
	_name.text = tr(Achievements.name_of(id))
	_box.visible = true
	_box.position.y = HIDDEN_Y
	var tween := create_tween()
	tween.tween_property(_box, "position:y", SHOWN_Y, IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(_box, "position:y", HIDDEN_Y, OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_box.visible = false
		_showing = false)
