class_name TitleScreen
extends Control
## Tela inicial no estilo de caixa eletrônico.
## 1) Atração: logo centralizada e "clique em qualquer lugar" piscando devagar.
## 2) Ao clicar, a tela sobe e aparece o menu do caixa.
## A arte vem das camadas de art/telas/tela_caixa.aseprite (exportadas em art/telas/camadas_tela_caixa/).

signal started  # primeiro clique na atração: a música já começa aqui, no menu
signal new_game_pressed
signal continue_pressed
signal howto_pressed
signal quit_pressed

const WIN := Rect2(213, 85, 855, 551)   # abertura da moldura, em coordenadas da arte (1280×720)
const TEX_CARCACA := "res://art/telas/camadas_tela_caixa/carcaca.png"
const TEX_MOLDURA := "res://art/telas/camadas_tela_caixa/moldura.png"
const TEX_TELA := "res://art/telas/camadas_tela_caixa/tela.png"
const TEX_BOTOES := "res://art/telas/camadas_tela_caixa/botoes.png"
const TEX_LOGO := "res://art/logo/logo_boletro.png"
const TEX_LOGO_NOME := "res://art/logo/nome_logo.png"
const SHADER := "res://shaders/tela_caixa.gdshader"
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"
const INK := Color("2B2B2B")
const CREAM := Color("F4EDD9")
const GREEN := Color("2A7458")
const HOVER_TINT := Color(1.0, 0.92, 0.6)
const SLIDE_TIME := 0.9
const PHRASE_TIME := 4.5

# Botões na arte (canvas 1280×720). Coluna esquerda: 4 botões. Coluna direita: 3 usados (o 4º fica de fora).
const BTN_SIZE := Vector2(366, 64)
const LEFT_X := 234.0
const RIGHT_X := 682.0
const ROWS := [220.0, 310.0, 400.0, 490.0]

const PHRASES := [
	"Saldo no vermelho? Relaxa, o Boletro não tem prazo de validade.",
	"Juros é só um jeito carinhoso de dizer: pague mais.",
	"O cheque especial é um amigo que sempre empresta… e cobra juros.",
	"Aqui você não paga contas. Você negocia com o sistema.",
	"Cartão aprovado! (provisoriamente)",
	"Toda conta paga é uma pequena vitória. Toda fatura nova, nem tanto.",
	"O caixa nunca fecha. Só você fecha a conta.",
	"O Leão da Receita não tem coração. Não tente argumentar.",
	"Não é golpe, é um investimento que ainda não deu certo.",
]

var _window: Control
var _attract: Control
var _menu: Control
var _blink: Label
var _phrase: Label
var _phrase_index := 0
var _phrase_timer: Timer
var _continue_btn: Button
var _sliding := false
var _has_save := false


func _init(has_save: bool = false) -> void:
	_has_save = has_save


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_art(TEX_CARCACA, Rect2(0, 0, 1280, 720), self)

	# Janela da tela: a atração e o menu sobem e descem dentro dela.
	_window = Control.new()
	_window.position = WIN.position
	_window.size = WIN.size
	_window.clip_contents = true
	add_child(_window)
	_build_attract()
	_build_menu()

	# Moldura por cima (a janela dela é vazada), depois o brilho de tela.
	_add_art(TEX_MOLDURA, Rect2(0, 0, 1280, 720), self)
	_add_glass()

	_phrase_timer = Timer.new()
	_phrase_timer.wait_time = PHRASE_TIME
	_phrase_timer.timeout.connect(_next_phrase)
	add_child(_phrase_timer)


## Só o botão Continuar depende de save; a tela inicial não precisa ser reconstruída.
func set_has_save(value: bool) -> void:
	_has_save = value
	if _continue_btn != null:
		_continue_btn.disabled = not _has_save
		var img: TextureRect = _continue_btn.get_meta("img")
		img.modulate = Color.WHITE if _has_save else Color(1, 1, 1, 0.4)


# --- Atração ----------------------------------------------------------------

func _build_attract() -> void:
	_attract = Control.new()
	_attract.size = WIN.size
	_attract.mouse_filter = Control.MOUSE_FILTER_STOP
	_attract.gui_input.connect(_on_attract_input)
	_window.add_child(_attract)

	var bg := ColorRect.new()
	bg.color = GREEN
	bg.size = WIN.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract.add_child(bg)

	# Logo centralizada na tela (centro da arte: 640, 360).
	var logo := TextureRect.new()
	logo.texture = load(TEX_LOGO) as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = _local(Rect2(320, 180, 640, 360)).position
	logo.size = Vector2(640, 360)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract.add_child(logo)

	# Aviso piscando devagar e quase transparente.
	_blink = Label.new()
	_blink.text = tr("CLIQUE EM QUALQUER LUGAR PARA INICIAR O SERVIÇO")
	_blink.position = Vector2(0, 468)
	_blink.size = Vector2(WIN.size.x, 40)
	_blink.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blink.add_theme_font_override("font", load(FONT_TITLE) as Font)
	_blink.add_theme_font_size_override("font_size", 30)
	_blink.add_theme_color_override("font_color", CREAM)
	_blink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract.add_child(_blink)
	var pulse := _blink.create_tween().set_loops()
	pulse.tween_property(_blink, "modulate:a", 0.45, 1.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_blink, "modulate:a", 0.08, 1.8).set_trans(Tween.TRANS_SINE)


func _on_attract_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _sliding:
			started.emit()
		_slide_to_menu()


## A tela sobe e o menu do caixa entra por baixo.
func _slide_to_menu() -> void:
	if _sliding:
		return
	_sliding = true
	_attract.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_attract, "position:y", -WIN.size.y, SLIDE_TIME)
	tween.tween_property(_menu, "position:y", 0.0, SLIDE_TIME)
	tween.finished.connect(func() -> void:
		_sliding = false
		_phrase_timer.start())


# --- Menu do caixa ----------------------------------------------------------

func _build_menu() -> void:
	_menu = Control.new()
	_menu.position = Vector2(0, WIN.size.y)
	_menu.size = WIN.size
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_window.add_child(_menu)

	# Tela do caixa: cabeçalho de papel e rodapé. A arte é do tamanho da tela inteira, então entra deslocada.
	_add_art(TEX_TELA, Rect2(-WIN.position, Vector2(1280, 720)), _menu)
	_add_art(TEX_LOGO_NOME, _local(Rect2(246, 117, 282, 56)), _menu)

	# Frase que muda, no lado direito do cabeçalho.
	_phrase = Label.new()
	_phrase.position = _local(Rect2(546, 102, 486, 84)).position
	_phrase.size = Vector2(486, 84)
	_phrase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phrase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phrase.add_theme_font_override("font", load(FONT_TERMINAL) as Font)
	_phrase.add_theme_font_size_override("font_size", 26)
	_phrase.add_theme_color_override("font_color", INK)
	_phrase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phrase.text = tr(PHRASES[0])
	_menu.add_child(_phrase)

	# Coluna esquerda.
	_continue_btn = _menu_button(tr("CONTINUAR"), LEFT_X, ROWS[1], true, _on_continue)
	_menu_button(tr("NOVO JOGO"), LEFT_X, ROWS[0], true, _on_new_game)
	_menu_button(tr("COMO JOGAR"), LEFT_X, ROWS[2], true, _on_howto)
	_menu_button(tr("CRÉDITOS"), LEFT_X, ROWS[3], true, _on_coming_soon.bind(tr("Créditos")))

	# Coluna direita.
	_menu_button(tr("COLEÇÃO"), RIGHT_X, ROWS[0], false, _on_coming_soon.bind(tr("Coleção")))
	_menu_button(tr("CONQUISTAS"), RIGHT_X, ROWS[1], false, _on_coming_soon.bind(tr("Conquistas")))
	_menu_button(tr("SAIR"), RIGHT_X, ROWS[2], false, _on_quit)
	# 4º botão da coluna direita (era só enfeite na arte): agora abre as Opções.
	_menu_button(tr("OPÇÕES"), RIGHT_X, ROWS[3], false, _on_options)

	set_has_save(_has_save)


## Botão do caixa: a arte do botão vem do atlas botoes.png; o texto fica sobre a parte livre dela.
## Devolve o botão; a imagem fica guardada nele (meta "img") para o destaque ao passar o mouse.
func _menu_button(text: String, x: float, y: float, left_side: bool, handler: Callable) -> Button:
	var img := _button_art(x, y)

	var btn := Button.new()
	btn.text = text
	btn.position = img.position
	btn.size = BTN_SIZE
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty := StyleBoxEmpty.new()
	# Área do texto: na coluna da esquerda a seta fica à esquerda; na da direita, à direita.
	empty.content_margin_left = 56.0 if left_side else 8.0
	empty.content_margin_right = 8.0 if left_side else 54.0
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, empty)
	btn.add_theme_font_override("font", load(FONT_TITLE) as Font)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.38, 0.34))
	btn.pressed.connect(handler)
	btn.mouse_entered.connect(func() -> void:
		if not btn.disabled:
			img.modulate = HOVER_TINT)
	btn.mouse_exited.connect(func() -> void:
		img.modulate = Color.WHITE if not btn.disabled else Color(1, 1, 1, 0.4))
	btn.set_meta("img", img)
	_menu.add_child(btn)
	return btn


## Só a arte do botão (recorte de botoes.png), sem texto nem clique.
func _button_art(x: float, y: float) -> TextureRect:
	var at := AtlasTexture.new()
	at.atlas = load(TEX_BOTOES) as Texture2D
	at.region = Rect2(x, y, BTN_SIZE.x, BTN_SIZE.y)
	var img := TextureRect.new()
	img.texture = at
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.position = _local(Rect2(x, y, BTN_SIZE.x, BTN_SIZE.y)).position
	img.size = BTN_SIZE
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(img)
	return img


func _on_new_game() -> void:
	new_game_pressed.emit()


func _on_continue() -> void:
	if _has_save:
		continue_pressed.emit()


func _on_howto() -> void:
	howto_pressed.emit()


func _on_quit() -> void:
	quit_pressed.emit()


func _on_options() -> void:
	OptionsScreen.open(self, _on_options_closed)


## Se o idioma mudou, a cena inteira é recarregada para os textos saírem no novo idioma.
func _on_options_closed(language_changed: bool) -> void:
	if language_changed:
		get_tree().reload_current_scene()


## Coleção, Conquistas e Créditos ainda não existem: a frase do cabeçalho mostra "Em breve".
func _on_coming_soon(what: String) -> void:
	_phrase.text = tr("%s: em breve.") % what
	_phrase_timer.start()


func _next_phrase() -> void:
	_phrase_index = (_phrase_index + 1) % PHRASES.size()
	_phrase.text = tr(PHRASES[_phrase_index])
	_phrase.modulate.a = 0.0
	create_tween().tween_property(_phrase, "modulate:a", 1.0, 0.4)


# --- Helpers ----------------------------------------------------------------

## Coordenadas da arte (1280×720) para dentro da janela.
func _local(rect: Rect2) -> Rect2:
	return Rect2(rect.position - WIN.position, rect.size)


func _add_art(path: String, rect: Rect2, parent: Node) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = load(path) as Texture2D
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


func _add_glass() -> void:
	var glass := ColorRect.new()
	glass.position = WIN.position
	glass.size = WIN.size
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER) as Shader
	glass.material = mat
	add_child(glass)
