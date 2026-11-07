class_name OptionsScreen
extends Control
## Tela de opções, aberta por cima da tela atual (título ou menu de pausa).
## Use OptionsScreen.open(pai, função). A função recebe true se o idioma mudou,
## porque a cena precisa ser recarregada para refazer os textos.

signal closed(language_changed: bool)

const PANEL := Rect2(340, 80, 600, 560)
const ROW_Y := 172.0
const ROW_H := 48.0
const LABEL_X := 370.0
const CONTROL_X := 680.0
const CONTROL_W := 170.0
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const PAPER_HOVER := Color("FFF8E7")
const PAPER_DOWN := Color("D9CCAE")
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"

var _start_language := ""
var _language_pick: OptionButton
var _music: HSlider
var _music_value: Label
var _sfx: HSlider
var _sfx_value: Label
var _fullscreen: CheckButton
var _vsync: CheckButton
var _fps: OptionButton
var _shake: CheckButton


## Abre as opções por cima de `parent`. `on_closed` recebe true se o idioma mudou.
static func open(parent: Node, on_closed: Callable) -> OptionsScreen:
	var screen := OptionsScreen.new()
	screen.closed.connect(on_closed)
	parent.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_start_language = Settings.language
	_build()
	_refresh()


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
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = PANEL.position
	panel.size = PANEL.size
	add_child(panel)

	_text(Rect2(PANEL.position.x, PANEL.position.y + 12, PANEL.size.x, 60), tr("OPÇÕES"), _font(FONT_TITLE), 44, HORIZONTAL_ALIGNMENT_CENTER)

	_language_pick = OptionButton.new()
	for code in Loc.LANGUAGES:
		_language_pick.add_item(Loc.LANGUAGE_NAMES[code])
	_language_pick.item_selected.connect(_on_language_picked)
	_row(0, tr("Idioma"), _language_pick)

	_music = _slider(Settings.music_volume)
	_music_value = _value_label()
	_music.value_changed.connect(func(v: float) -> void:
		Settings.music_volume = int(v)
		_music_value.text = "%d%%" % int(v)
		Settings.apply()
		Settings.save())
	_row(1, tr("Música"), _music, _music_value)

	_sfx = _slider(Settings.sfx_volume)
	_sfx_value = _value_label()
	_sfx.value_changed.connect(func(v: float) -> void:
		Settings.sfx_volume = int(v)
		_sfx_value.text = "%d%%" % int(v)
		Settings.apply()
		Settings.save())
	_row(2, tr("Efeitos sonoros"), _sfx, _sfx_value)

	_fullscreen = CheckButton.new()
	_fullscreen.toggled.connect(func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply()
		Settings.save())
	_row(3, tr("Tela cheia"), _fullscreen)

	_vsync = CheckButton.new()
	_vsync.toggled.connect(func(on: bool) -> void:
		Settings.vsync = on
		Settings.apply()
		Settings.save())
	_row(4, tr("Sincronizar (VSync)"), _vsync)

	_fps = OptionButton.new()
	for choice in Settings.FPS_CHOICES:
		_fps.add_item(str(choice) if choice > 0 else tr("Sem limite"))
	_fps.item_selected.connect(func(index: int) -> void:
		Settings.fps_index = index
		Settings.apply()
		Settings.save())
	_row(5, tr("Limite de FPS"), _fps)

	_shake = CheckButton.new()
	_shake.toggled.connect(func(on: bool) -> void:
		Settings.screen_shake = on
		Settings.save())
	_row(6, tr("Tremor da tela"), _shake)

	_text(Rect2(PANEL.position.x + 20, 514, PANEL.size.x - 40, 32), tr("O idioma muda ao fechar as opções."), _font(FONT_TERMINAL), 22, HORIZONTAL_ALIGNMENT_CENTER)

	_button(Rect2(PANEL.position.x + 60, 562, 200, 46), tr("PADRÕES"), _on_defaults)
	_button(Rect2(PANEL.position.x + 340, 562, 200, 46), tr("VOLTAR"), _close)


## Atualiza os controles com os valores atuais (usado ao abrir e ao restaurar padrões).
func _refresh() -> void:
	_language_pick.select(maxi(Loc.LANGUAGES.find(Settings.language), 0))
	_music.set_value_no_signal(Settings.music_volume)
	_music_value.text = "%d%%" % Settings.music_volume
	_sfx.set_value_no_signal(Settings.sfx_volume)
	_sfx_value.text = "%d%%" % Settings.sfx_volume
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_vsync.set_pressed_no_signal(Settings.vsync)
	_fps.select(Settings.fps_index)
	_shake.set_pressed_no_signal(Settings.screen_shake)


func _on_language_picked(index: int) -> void:
	Settings.set_language(Loc.LANGUAGES[index])


func _on_defaults() -> void:
	Settings.reset_defaults()
	_refresh()


func _close() -> void:
	closed.emit(Settings.language != _start_language)
	queue_free()


# --- Montagem ----------------------------------------------------------------

func _row(index: int, label_text: String, control: Control, extra: Control = null) -> void:
	var y := ROW_Y + index * ROW_H
	_text(Rect2(LABEL_X, y, 300, 40), label_text, _font(FONT_TERMINAL), 26, HORIZONTAL_ALIGNMENT_LEFT)
	control.position = Vector2(CONTROL_X, y + 4)
	control.size = Vector2(CONTROL_W, 40)
	add_child(control)
	if extra != null:
		extra.position = Vector2(CONTROL_X + CONTROL_W + 8, y + 4)
		add_child(extra)


func _slider(value: int) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = value
	slider.custom_minimum_size = Vector2(CONTROL_W, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return slider


func _value_label() -> Label:
	var lbl := Label.new()
	lbl.size = Vector2(60, 40)
	lbl.add_theme_font_override("font", _font(FONT_TERMINAL))
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", INK)
	return lbl


func _text(rect: Rect2, text: String, font: Font, size: int, align: HorizontalAlignment) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", INK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	return lbl


func _button(rect: Rect2, text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", _font(FONT_TITLE))
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PAPER_HOVER if state == "hover" else (PAPER_DOWN if state == "pressed" else PAPER)
		box.border_color = INK
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		btn.add_theme_stylebox_override(state, box)
	btn.pressed.connect(handler)
	add_child(btn)
	return btn


func _font(path: String) -> Font:
	return load(path) as Font
