extends Control
## Interface da partida sobre a arte do caixa eletrônico (hora 7–12) e do Camelô.
## Toda regra vem de RunState/BillRound. Posições em pixels da resolução base 1280×720.

## Quanto a cédula sobe quando selecionada (px).
const LIFT := 24
const CARD_SIZE := Vector2(120, 180)
const LIFT_TIME := 0.12

# Sensação da pontuação (só apresentação; a regra já foi resolvida em RunState.pay()).
const PROCESSING_TIME := 0.4     # "AGUARDE… PROCESSANDO" antes da contagem
const STEP_TIME := 0.14          # pausa entre cada evento da lista
const SHAKE_TIME := 0.3
const SHAKE_STEPS := 6
const SHAKE_MAX := 16.0          # tremor máximo (px)
const BIG_RECEIPT_RATIO := 5     # saldo acima de 5× a meta: comprovante gigante
const BIG_RECEIPT_SCALE := 2.2
const RECEIPT_POS := Vector2(520, 60)
const HIGHLIGHT := Color("FFE066")
const FLY_TIME := 0.35  # cartas indo para a máquina ao pagar

# Números do caixa, na ordem da linha de cima (cada um vira um bloco com nome e valor).
const STAT_ORDER := ["carteira", "meta", "saldo", "dias", "trocas"]
const STAT_CAPTIONS := {"carteira": "CARTEIRA", "meta": "META", "saldo": "SALDO", "dias": "DIAS", "trocas": "TROCAS"}

# Janela vazada da moldura (A1) e área da mão embaixo, sobre a bancada.
const SCREEN := Rect2(240, 60, 800, 360)
const HAND_POS := Vector2(118, 506)
const HAND_AREA := Vector2(1044, 204)

# Faixa de esquemas dentro da tela (embaixo).
const STRIP_POS := Vector2(0, 188)
const STRIP_SLOT := Vector2(96, 134)
const STRIP_GAP := 8

const TERMINAL_BG := Color("0F2A1A")
const TERMINAL_TEXT := Color("9BFFB0")
const WARN := Color("FF6B5B")
const INK := Color("2B2B2B")
const DIM := Color(0.6, 0.6, 0.6)

# Botões de papel com borda de tinta (todas as telas usam este visual).
const BUTTON_PAPER := Color("F4EDD9")
const BUTTON_PAPER_HOVER := Color("FFF8E7")
const BUTTON_PAPER_DOWN := Color("D9CCAE")
const BUTTON_DISABLED := Color("BDB6A4")
const BUTTON_DISABLED_INK := Color("6B6457")

const RECEIPT_PAPER := Color("F7F3E8")
const STAMP_INK := Color("B5382C")
const HAND_INK := Color("24304F")  # caneta da tabela desenhada à mão
const FONT_HAND := "res://fonts/Permanent_Marker/PermanentMarker-Regular.ttf"

# Texto escrito dentro do selo de chefe (a arte traz só o carimbo vazio).
const BOSS_STAMP := {
	"banco_fora_do_ar": "BANCO FORA\nDO AR",
	"taxa_manutencao": "TAXA DE\nMANUTENÇÃO",
	"janeiro_impostos": "JANEIRO",
}

# Tabela da tela "Como jogar" (valores vêm de Balance.TRANSACTIONS).
const HOWTO_ORDER := ["trocado", "dobradinha", "bolada", "escadinha", "tudo_no_relampago", "cofrinho"]
const HOWTO_COMBO := {
	"trocado": "a nota de maior valor",
	"dobradinha": "2 notas de mesmo valor",
	"bolada": "3 notas de mesmo valor",
	"escadinha": "5 notas em sequência",
	"tudo_no_relampago": "5 notas do mesmo naipe",
	"cofrinho": "4 notas de mesmo valor",
}

const TEX_FRAME := "res://art/caixa/caixa_moldura.png"
const TEX_KEY := "res://art/caixa/caixa_tecla.png"
const TEX_KEY_DOWN := "res://art/caixa/caixa_tecla_pressionada.png"
const TEX_TITLE := "res://art/telas/titulo.png"
const TEX_HOWTO := "res://art/telas/como_jogar.png"
const TEX_END_OK :="res://art/telas/fim_contas_em_dia.png"
const TEX_END_BAD := "res://art/telas/fim_negativado.png"
const TEX_RECEIPT := "res://art/comprovante/comprovante_termico.png"
const TEX_SHOP_BG := "res://art/camelo/camelo_fundo.png"
const TEX_PRICE := "res://art/camelo/plaquinha_1.png"

# Fontes (pasta fonts/): VT323 = terminal e comprovante, Anton = títulos e botões.
const FONT_TERMINAL := "res://fonts/VT323/VT323-Regular.ttf"
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"

const BOSS_ART := {
	"banco_fora_do_ar": "res://art/chefes/chefe_banco_fora.png",
	"taxa_manutencao": "res://art/chefes/chefe_taxa_manutencao.png",
	"janeiro_impostos": "res://art/chefes/chefe_janeiro.png",
}

var run: RunState

# Interface da partida (escondida no Camelô).
var _game_root: Control
var _screen: Control
var _header: Label
var _stats: HBoxContainer
var _stat_values: Dictionary = {}  # {carteira/meta/saldo/dias/trocas: Label com o valor}
var _boss_text: Label
var _boss_art: TextureRect
var _boss_stamp_text: Label
var _levels: Label
var _message: Label
var _strip_slots: Array = []   # [{"slot", "empty", "card"}] por espaço de esquema
var _hand_area: Control
var _hand_box: HBoxContainer
var _pay_key: TextureButton
var _swap_key: TextureButton
var _restart_button: Button
var _next_button: Button
var _end_stamp: TextureRect
var _receipt: NinePatchRect
var _receipt_label: Label

# Interface do Camelô (escondida na partida).
var _shop_root: Control
var _shop_wallet: Label
var _shop_cheque: Label
var _shop_message: Label
var _shop_levels_row: HBoxContainer
var _shop_offers: Array = []   # [{"card", "plate", "price", "text", "buy"}] por oferta
var _shop_owned: Array = []    # [{"thumb", "sell"}] por esquema que você tem
var _haggle_button: Button
var _leave_button: Button

var _title: TextureButton
var _sfx: Sfx                  # sons e música (ver scripts/ui/sfx.gd)
var _boss_stamp_key := ""      # última fatura com carimbo tocado
var _end_stamp_played := false
var _title_extras: Array = []  # textos e botões do título (somem ao começar)
var _howto: TextureButton      # tela "Como jogar" (clique fecha)

# Verdadeiro durante a animação de pontuação: entrada do jogador fica travada.
var _busy := false

# Note -> botão da carta (dentro do wrapper que cuida do espaço da mão).
var _cards: Dictionary = {}


func _ready() -> void:
	_build_ui()


## F11 alterna tela cheia e janela (útil no desenvolvimento).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _build_ui() -> void:
	_sfx = Sfx.new()
	add_child(_sfx)
	# Tema do jogo inteiro: VT323 como fonte padrão (terminal, comprovante).
	theme = _make_theme()

	_game_root = Control.new()
	_game_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_game_root)

	_shop_root = Control.new()
	_shop_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shop_root.visible = false
	add_child(_shop_root)

	_build_game(_game_root)
	_build_shop(_shop_root)

	# Título por cima de tudo: clicar nele começa a partida.
	_title = TextureButton.new()
	_title.texture_normal = _tex(TEX_TITLE)
	_title.ignore_texture_size = true
	_title.stretch_mode = TextureButton.STRETCH_SCALE
	_title.position = Vector2.ZERO
	_title.size = Vector2(1280, 720)
	_title.pressed.connect(_on_title_pressed)
	add_child(_title)

	# Por cima do título: aviso piscando e botão "Como jogar" (no quadro-negro).
	var prompt := Label.new()
	prompt.text = "INSIRA SEU CARTÃO"
	prompt.position = Vector2(340, 450)
	prompt.size = Vector2(600, 60)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", _font(FONT_TITLE))
	prompt.add_theme_font_size_override("font_size", 40)
	prompt.add_theme_color_override("font_color", INK)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	var blink := create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 0.2, 0.6)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.6)

	var howto_button := Button.new()
	howto_button.text = "COMO JOGAR"
	howto_button.position = Vector2(520, 300)
	howto_button.size = Vector2(240, 60)
	howto_button.add_theme_font_override("font", _font(FONT_TITLE))
	howto_button.add_theme_font_size_override("font_size", 28)
	howto_button.pressed.connect(_on_howto_pressed)
	add_child(howto_button)

	_howto = TextureButton.new()
	_howto.texture_normal = _tex(TEX_HOWTO)
	_howto.ignore_texture_size = true
	_howto.stretch_mode = TextureButton.STRETCH_SCALE
	_howto.position = Vector2.ZERO
	_howto.size = Vector2(1280, 720)
	_howto.visible = false
	_howto.pressed.connect(func() -> void: _howto.visible = false)
	add_child(_howto)
	_build_howto_text()

	_title_extras = [prompt, howto_button]


# --- Partida ---------------------------------------------------------------

func _build_game(root: Control) -> void:
	# Fundo verde do terminal: aparece pela janela vazada da moldura.
	var screen_bg := ColorRect.new()
	screen_bg.color = TERMINAL_BG
	screen_bg.position = SCREEN.position
	screen_bg.size = SCREEN.size
	screen_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen_bg)

	_texture_rect(TEX_FRAME, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)

	_build_screen_content(root)

	_pay_key = _key(root, "PAGAR", Vector2(1184, 150), _on_pay_pressed)
	_swap_key = _key(root, "TROCAR", Vector2(1184, 250), _on_swap_pressed)
	_key(root, "VALOR", Vector2(24, 150), Callable(), false)
	_key(root, "FORMA", Vector2(24, 250), Callable(), false)

	_hand_area = Control.new()
	_hand_area.position = HAND_POS
	_hand_area.size = HAND_AREA
	root.add_child(_hand_area)
	_hand_box = HBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", 12)
	_hand_area.add_child(_hand_box)

	_restart_button = _button(root, "JOGAR DE NOVO", Rect2(540, 436, 200, 56), _start_run)
	_next_button = _button(root, "IR AO CAMELÔ", Rect2(392, 664, 240, 52), _on_next_pressed)

	# Carimbo de fim fica na área vazia ao lado da faixa de esquemas (não cobre o texto).
	_end_stamp = _texture_rect(TEX_END_OK, Rect2(800, 296, 240, 120), root)
	_end_stamp.visible = false

	_build_receipt(root)


func _build_screen_content(root: Control) -> void:
	_screen = Control.new()
	_screen.position = SCREEN.position + Vector2(16, 16)
	_screen.size = SCREEN.size - Vector2(32, 32)
	root.add_child(_screen)

	# Cabeçalho: nome da conta. Abaixo, uma linha de blocos com carteira, meta, saldo, dias e trocas.
	_header = _terminal_label(32)
	_header.add_theme_font_override("font", _font(FONT_TITLE))
	_header.position = Vector2(0, 0)
	_header.size = Vector2(620, 40)
	_screen.add_child(_header)

	_stats = HBoxContainer.new()
	_stats.position = Vector2(0, 44)
	_stats.size = Vector2(620, 58)
	_stats.add_theme_constant_override("separation", 10)
	_screen.add_child(_stats)
	for key in STAT_ORDER:
		var block := VBoxContainer.new()
		block.custom_minimum_size = Vector2(116, 58)
		var caption := _terminal_label(16)
		caption.text = STAT_CAPTIONS[key]
		caption.add_theme_color_override("font_color", Color(TERMINAL_TEXT, 0.6))
		block.add_child(caption)
		var value := _terminal_label(34)
		block.add_child(value)
		_stats.add_child(block)
		_stat_values[key] = value

	# Mensagem da jogada (uma linha), depois os níveis dos investimentos.
	_message = _terminal_label(26)
	_message.position = Vector2(0, 108)
	_message.size = Vector2(620, 30)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_screen.add_child(_message)

	_levels = _terminal_label(22)
	_levels.position = Vector2(0, 140)
	_levels.size = Vector2(620, 26)
	_screen.add_child(_levels)

	# Descrição do chefe no canto direito, ao lado da faixa de esquemas.
	_boss_text = _terminal_label(18)
	_boss_text.position = Vector2(530, 186)
	_boss_text.size = Vector2(238, 140)
	_boss_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_screen.add_child(_boss_text)

	# Imagem do chefe no canto direito da tela, só quando a fatura está ativa.
	_boss_art = _texture_rect("", Rect2(_screen.size.x - 120, 0, 120, 120), _screen)
	_boss_art.visible = false
	_boss_stamp_text = Label.new()
	_boss_stamp_text.size = Vector2(120, 120)
	_boss_stamp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_stamp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_stamp_text.add_theme_font_override("font", _font(FONT_TITLE))
	_boss_stamp_text.add_theme_font_size_override("font_size", 15)
	_boss_stamp_text.add_theme_color_override("font_color", STAMP_INK)
	_boss_stamp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_art.add_child(_boss_stamp_text)

	# Faixa de esquemas: 5 espaços, cada um com tooltip (nome e efeito).
	for i in range(Balance.MAX_SCHEMES):
		var slot := Control.new()
		slot.position = STRIP_POS + Vector2(i * (STRIP_SLOT.x + STRIP_GAP), 0)
		slot.size = STRIP_SLOT
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var empty := ColorRect.new()
		empty.color = Color(TERMINAL_TEXT, 0.12)
		empty.size = STRIP_SLOT
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(empty)
		var card := _texture_rect("", Rect2(Vector2.ZERO, STRIP_SLOT), slot)
		card.visible = false
		_screen.add_child(slot)
		_strip_slots.append({"slot": slot, "empty": empty, "card": card})


func _build_receipt(root: Control) -> void:
	_receipt = NinePatchRect.new()
	_receipt.texture = _tex(TEX_RECEIPT)
	_receipt.patch_margin_left = 24
	_receipt.patch_margin_right = 24
	_receipt.patch_margin_top = 40
	_receipt.patch_margin_bottom = 40
	_receipt.position = Vector2(520, 60)
	_receipt.size = Vector2(240, 600)
	_receipt.visible = false
	root.add_child(_receipt)

	# Papel liso por baixo do texto: as linhas pintadas na arte atrapalhavam a leitura.
	var paper := ColorRect.new()
	paper.color = RECEIPT_PAPER
	paper.position = Vector2(28, 56)
	paper.size = Vector2(184, 492)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt.add_child(paper)

	_receipt_label = Label.new()
	_receipt_label.position = Vector2(36, 64)
	_receipt_label.size = Vector2(168, 470)
	_receipt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_receipt_label.add_theme_font_size_override("font_size", 20)
	_receipt_label.add_theme_color_override("font_color", INK)
	_receipt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt.add_child(_receipt_label)


# --- Camelô ----------------------------------------------------------------

func _build_shop(root: Control) -> void:
	_texture_rect(TEX_SHOP_BG, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)

	var ribbon := ColorRect.new()
	ribbon.color = Color(0, 0, 0, 0.55)
	ribbon.position = Vector2(0, 20)
	ribbon.size = Vector2(1280, 124)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ribbon)

	# Topo: título e as plaquinhas de carteira e cheque especial.
	var top := HBoxContainer.new()
	top.position = Vector2(32, 26)
	top.size = Vector2(1216, 48)
	top.add_theme_constant_override("separation", 14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var title := _shop_label(Rect2(0, 0, 200, 48), 40, true)
	title.text = "CAMELÔ"
	top.add_child(title)
	var wallet_chip := _chip(30, BUTTON_PAPER)
	_shop_wallet = _chip_label(wallet_chip)
	top.add_child(wallet_chip)
	var cheque_chip := _chip(20, BUTTON_PAPER_DOWN)
	_shop_cheque = _chip_label(cheque_chip)
	top.add_child(cheque_chip)

	_shop_message = _shop_label(Rect2(32, 80, 1216, 28), 24, false)
	root.add_child(_shop_message)

	# Níveis dos investimentos: uma plaquinha por transação com nível.
	_shop_levels_row = HBoxContainer.new()
	_shop_levels_row.position = Vector2(32, 112)
	_shop_levels_row.size = Vector2(1216, 30)
	_shop_levels_row.add_theme_constant_override("separation", 8)
	_shop_levels_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_shop_levels_row)

	# Ofertas: esquemas (cartaz) e investimentos (ícone), cada uma com preço e compra.
	for i in range(Balance.SHOP_OFFERS + Balance.SHOP_INVESTMENT_OFFERS):
		var x := 180.0 + i * 360.0
		var card := _texture_rect("", Rect2(x, 150, 200, 280), root)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon := _texture_rect("", Rect2(x + 40, 170, 120, 120), root)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.visible = false
		_texture_rect(TEX_PRICE, Rect2(x + 150, 162, 80, 50), root)
		var price := _shop_label(Rect2(x + 150, 162, 80, 50), 22, true)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.add_theme_color_override("font_color", INK)
		root.add_child(price)
		# Nome do esquema numa linha só, em etiqueta de papel colada sobre o cartaz.
		var tag := Panel.new()
		tag.add_theme_stylebox_override("panel", _tag_box())
		tag.position = Vector2(x + 8, 216)
		tag.size = Vector2(184, 26)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tag)
		var text := _shop_label(Rect2(x + 10, 218, 180, 22), 14, true)
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		text.clip_text = true
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_color", INK)
		root.add_child(text)
		var buy := _button(root, "COMPRAR", Rect2(x, 440, 200, 44), _on_buy_pressed.bind(i))
		_shop_offers.append({"card": card, "icon": icon, "price": price, "tag": tag, "text": text, "buy": buy})

	# Esquemas que você já tem: vender pela metade do preço.
	for i in range(Balance.MAX_SCHEMES):
		var x := 368.0 + i * 112.0
		var thumb := _texture_rect("", Rect2(x, 490, STRIP_SLOT.x, STRIP_SLOT.y), root)
		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.visible = false
		var sell := _button(root, "VENDER", Rect2(x, 630, STRIP_SLOT.x, 30), _on_sell_pressed.bind(i))
		sell.add_theme_font_size_override("font_size", 16)
		_shop_owned.append({"thumb": thumb, "sell": sell})

	_haggle_button = _button(root, "PECHINCHAR", Rect2(390, 670, 240, 42), _on_haggle_pressed)
	_leave_button = _button(root, "SEGUIR", Rect2(650, 670, 240, 42), _on_leave_shop_pressed)
	_leave_button.visible = true
	_haggle_button.visible = true


func _shop_label(rect: Rect2, font_size: int, title_font: bool) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	if title_font:
		label.add_theme_font_override("font", _font(FONT_TITLE))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _refresh_shop() -> void:
	_shop_wallet.text = "CARTEIRA R$ %d" % run.wallet
	_shop_wallet.add_theme_color_override("font_color", WARN if run.wallet < 0 else INK)
	_shop_cheque.text = "CHEQUE ESPECIAL ATÉ R$ %d" % -Balance.OVERDRAFT_LIMIT
	_refresh_shop_levels()

	for i in range(_shop_offers.size()):
		var o: Dictionary = _shop_offers[i]
		var has := i < run.shop_offer.size()
		for key in ["card", "icon", "price", "tag", "text", "buy"]:
			o[key].visible = has
		if not has:
			continue
		var id: String = run.shop_offer[i]
		var info: Dictionary = Balance.INVESTMENTS[id] if Investments.is_investment(id) else Balance.SCHEMES[id]
		var is_inv := Investments.is_investment(id)
		# Nome do investimento fica abaixo do ícone; o texto do cartaz fica na etiqueta de papel.
		o["text"].position = Vector2(o["text"].position.x, 296.0 if is_inv else 218.0)
		o["tag"].position = Vector2(o["tag"].position.x, 216.0)
		o["tag"].visible = not is_inv
		o["card"].visible = not is_inv
		o["icon"].visible = is_inv
		if is_inv:
			o["icon"].texture = _tex("res://art/camelo/investimento_%s.png" % id)
			o["icon"].tooltip_text = "%s
%s" % [info["name"], info["desc"]]
			o["text"].text = info["name"]
		else:
			o["card"].texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
			o["card"].tooltip_text = "%s
%s" % [info["name"], info["desc"]]
			o["text"].text = info["name"]
		var price := run.price_of(id)
		o["price"].text = "R$ %d" % price
		o["buy"].text = "COMPRAR R$ %d" % price
		var full := not is_inv and run.schemes.size() >= Balance.MAX_SCHEMES
		o["buy"].disabled = full or run.wallet - price < Balance.OVERDRAFT_LIMIT

	for i in range(_shop_owned.size()):
		var s: Dictionary = _shop_owned[i]
		var has := i < run.schemes.size()
		s["thumb"].visible = has
		s["sell"].visible = has
		if has:
			var id: String = run.schemes[i]
			var info: Dictionary = Balance.SCHEMES[id]
			s["thumb"].texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
			s["thumb"].tooltip_text = "%s
%s" % [info["name"], info["desc"]]
			s["sell"].text = "VENDER R$ %d" % (int(info["price"]) / 2)

	_haggle_button.text = "PECHINCHAR R$ %d" % Balance.HAGGLE_COST
	_haggle_button.disabled = run.wallet - Balance.HAGGLE_COST < Balance.OVERDRAFT_LIMIT


## Plaquinha de papel com texto (carteira, cheque, níveis). Devolve o painel; o texto é o filho.
func _chip(font_size: int, bg: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := _tag_box()
	box.bg_color = bg
	box.set_content_margin_all(4)
	box.content_margin_left = 14
	box.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.add_theme_font_override("font", _font(FONT_TITLE))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel


func _chip_label(panel: PanelContainer) -> Label:
	return panel.get_child(0) as Label


## Uma plaquinha por investimento com nível (ex.: "DOBRADINHA x2"). Sem nível, uma frase.
func _refresh_shop_levels() -> void:
	for child in _shop_levels_row.get_children():
		child.queue_free()
	var any := false
	for kind in Balance.TRANSACTIONS:
		var lvl: int = run.levels.get(kind, 0)
		if lvl <= 0:
			continue
		any = true
		var chip := _chip(18, BUTTON_PAPER_DOWN)
		_chip_label(chip).text = "%s x%d" % [Balance.TRANSACTIONS[kind]["name"].to_upper(), lvl]
		_shop_levels_row.add_child(chip)
	if not any:
		var none := _shop_label(Rect2(0, 0, 400, 30), 22, false)
		none.text = "Nenhum investimento ainda"
		_shop_levels_row.add_child(none)


## Níveis atuais dos investimentos, em nomes de transação (ex.: "Dobradinha 1 · Escadinha 0").
func _levels_text() -> String:
	var parts: Array = []
	for kind in Balance.TRANSACTIONS:
		var lvl: int = run.levels.get(kind, 0)
		if lvl > 0:
			parts.append("%s %d" % [Balance.TRANSACTIONS[kind]["name"], lvl])
	return "nenhum investimento ainda" if parts.is_empty() else " · ".join(parts)


func _on_buy_pressed(index: int) -> void:
	var result := run.buy(index)
	_sfx.play("fita" if result["ok"] else "erro")
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_sell_pressed(index: int) -> void:
	var result := run.sell(index)
	_sfx.play("rasgar" if result["ok"] else "erro")
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_haggle_pressed() -> void:
	var result := run.haggle()
	_sfx.play("papel" if result["ok"] else "erro")
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_leave_shop_pressed() -> void:
	var piramides_before := run.schemes.count("piramide")
	run.leave_shop()
	if run.schemes.count("piramide") < piramides_before:
		_sfx.play("rasgar")  # pirâmide colapsou ao começar o mês
	_shop_message.text = ""
	_refresh()


func _shop_refusal(reason: String) -> String:
	match reason:
		"no_money":
			return "Sem dinheiro, nem no cheque especial"
		"slots_full":
			return "Você já tem %d esquemas. Venda um antes" % Balance.MAX_SCHEMES
	return ""


# --- Fluxo -----------------------------------------------------------------

func _on_title_pressed() -> void:
	_title.visible = false
	_sfx.play_music()
	for node in _title_extras:
		node.visible = false
	_start_run()


func _on_howto_pressed() -> void:
	_howto.visible = true


func _start_run() -> void:
	run = RunState.new()
	_message.text = "INSIRA SUAS NOTAS"
	_boss_stamp_key = ""
	_end_stamp_played = false
	_shop_message.text = ""
	_restart_button.visible = false
	_refresh()


func _refresh() -> void:
	if run == null:
		return
	var shopping := run.state == RunState.SHOP
	_game_root.visible = not shopping
	_shop_root.visible = shopping
	if shopping:
		_refresh_shop()
	else:
		_update_status()
		_rebuild_hand()


## Textos, saldo, teclas, faixa e carimbos. Não mexe na mão (para a animação de seleção não ser interrompida).
func _update_status() -> void:
	var bill := run.bill
	var playing := run.state == RunState.PLAYING
	var over := run.state == RunState.WON or run.state == RunState.LOST
	var paid := run.state == RunState.BILL_PAID

	_header.text = run.bill_title()
	_set_stat("carteira", "R$ %d" % run.wallet, WARN if run.wallet < 0 else TERMINAL_TEXT)
	_set_stat("meta", "R$ %d" % bill.goal, TERMINAL_TEXT)
	_set_stat("saldo", "R$ %d" % bill.saldo, TERMINAL_TEXT)
	_set_stat("dias", str(bill.days_left), TERMINAL_TEXT)
	_set_stat("trocas", str(bill.swaps_left), TERMINAL_TEXT)

	var boss_id := run.boss_id()
	# Com o comprovante por cima, a tela mostra só a mensagem (o comprovante já traz os números).
	var show_boss := not paid and not over and boss_id != Boss.NONE
	_boss_text.visible = show_boss
	_boss_art.visible = show_boss
	if boss_id != Boss.NONE:
		_boss_text.text = "CHEFE: %s. %s" % [Balance.BOSSES[boss_id]["name"], Balance.BOSSES[boss_id]["text"]]
		_boss_art.texture = _tex(BOSS_ART[boss_id])
		_boss_stamp_text.text = BOSS_STAMP.get(boss_id, "")

	var levels_text := _levels_text()
	_levels.text = "Níveis: " + levels_text
	_levels.visible = not paid and levels_text != "nenhum investimento ainda"
	_set_key_enabled(_pay_key, playing)
	_set_key_enabled(_swap_key, playing)
	_hand_area.visible = playing
	_restart_button.visible = over
	_next_button.visible = paid
	_receipt.visible = paid
	_header.visible = not paid
	_stats.visible = not paid
	_end_stamp.visible = over
	# Carimbos: a fatura com chefe e o fim da partida batem uma vez cada.
	var stamp_key := "%d-%d" % [run.month_index, run.bill_index]
	if show_boss and _boss_stamp_key != stamp_key:
		_boss_stamp_key = stamp_key
		_sfx.play("carimbo")
	if over and not _end_stamp_played:
		_end_stamp_played = true
		_sfx.play("carimbo")
	if over:
		_end_stamp.texture = _tex(TEX_END_OK if run.state == RunState.WON else TEX_END_BAD)

	_update_strip()

	if run.state == RunState.WON:
		_message.text = "CONTAS EM DIA   ·   Saldo máximo R$ %d" % run.max_saldo
	elif run.state == RunState.LOST:
		_message.text = "NOME NEGATIVADO"
	elif paid:
		_message.text = "CONTA PAGA"
		_receipt_label.text = _receipt_text()


## Faixa de esquemas dentro da tela: uma carta por esquema ativo.
func _update_strip() -> void:
	for i in range(_strip_slots.size()):
		var s: Dictionary = _strip_slots[i]
		var has := i < run.schemes.size()
		s["empty"].visible = not has
		s["card"].visible = has
		if has:
			var id: String = run.schemes[i]
			var info: Dictionary = Balance.SCHEMES[id]
			s["card"].texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
			s["slot"].tooltip_text = "%s\n%s" % [info["name"], info["desc"]]
		else:
			s["slot"].tooltip_text = ""


## Recria a mão (ao comprar, trocar ou pagar). Cada carta fica num wrapper com espaço para subir.
func _rebuild_hand() -> void:
	for child in _hand_box.get_children():
		child.queue_free()
	_cards.clear()

	var playing := run.state == RunState.PLAYING
	for note in run.bill.hand:
		var wrap := Control.new()
		wrap.custom_minimum_size = CARD_SIZE + Vector2(0, LIFT)
		var btn := _card_button(note)
		btn.size = CARD_SIZE
		btn.disabled = not playing
		btn.pressed.connect(_on_card_pressed.bind(note))
		wrap.add_child(btn)
		_hand_box.add_child(wrap)
		_cards[note] = btn
		btn.position = _lifted_position(run.bill.selected.has(note))


## Uma nota da mão: a frente em PNG. Se a arte ainda não existir, cai num botão de texto.
func _card_button(note: Note) -> BaseButton:
	var path := note.face_path()
	if ResourceLoader.exists(path):
		var card := TextureButton.new()
		var tex: Texture2D = load(path)
		card.toggle_mode = true
		card.ignore_texture_size = true
		card.stretch_mode = TextureButton.STRETCH_SCALE
		card.texture_normal = tex
		card.texture_pressed = tex
		return card

	var btn := Button.new()
	btn.toggle_mode = true
	btn.text = "R$ %d\n%s" % [note.value, note.suit_name()]
	return btn


## Posição da carta dentro do wrapper: selecionada fica no topo, as outras descem LIFT px.
func _lifted_position(selected: bool) -> Vector2:
	return Vector2(0, 0 if selected else LIFT)


## Sobe ou desce uma carta com animação curta.
func _lift(btn: BaseButton, selected: bool) -> void:
	btn.button_pressed = selected
	var tween := create_tween()
	tween.tween_property(btn, "position", _lifted_position(selected), LIFT_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _receipt_text() -> String:
	var r := run.receipt
	return "COMPROVANTE\n%s\n\nSaldo R$ %d\nMeta R$ %d\n\nRecompensa +R$ %d\nTroco +R$ %d\n\nCarteira R$ %d" % [
		r["title"], r["saldo"], r["goal"], r["reward"], r["troco"], r["wallet"],
	]


func _on_card_pressed(note: Note) -> void:
	if _busy:
		return
	run.bill.toggle_select(note)
	_sfx.play("bipe_tecla")
	var selected: bool = run.bill.selected.has(note)
	if _cards.has(note):
		_lift(_cards[note], selected)
	_update_status()


func _on_pay_pressed() -> void:
	if _busy:
		return
	# A regra roda já; a tela só mostra o resultado depois da animação.
	var played: Array = run.bill.selected.duplicate()
	_sfx.play("bipe_tecla")
	var result := run.pay()
	if not result["ok"]:
		_sfx.play("erro")
		_message.text = _refusal_text(result["reason"])
		return
	var score: Dictionary = result["score"]
	if score["kind"] == "none":
		_refresh()
		return

	_busy = true
	if int(result.get("cash", 0)) > 0:
		_sfx.play("relampago")  # cashback: dinheiro voltando na carteira
	_fly_played(played)
	_message.text = "AGUARDE… PROCESSANDO"
	await get_tree().create_timer(PROCESSING_TIME).timeout
	await _play_score(score)
	_busy = false
	_refresh()
	if run.state == RunState.BILL_PAID:
		_print_receipt(run.bill.saldo > run.bill.goal * BIG_RECEIPT_RATIO)


## Percorre a lista de eventos do Scorer: notas pulam, cartaz balança, Juros aparece, total cai no saldo.
func _play_score(score: Dictionary) -> void:
	var tx_name: String = Balance.TRANSACTIONS[score["kind"]]["name"]
	var value := 0
	var juros := 0
	var mult := 1
	var note_index := 0
	var total: int = score["total"]
	var tax: int = score["tax"]
	for ev in score["events"]:
		match ev["type"]:
			"base":
				value = ev["amount"]
				juros = ev["juros"]
			"note":
				value += ev["amount"]
				_pop_points(ev["amount"])
				# Bipe que sobe em 5 alturas, uma por nota.
				_sfx.play("bipe_subindo", 1.0 + 0.125 * (note_index % 5))
				note_index += 1
			"invest":
				value += ev["value"]
				juros += ev["add"]
			"scheme":
				value += ev["value"]
				juros += ev["add"]
				mult *= ev["mult"]
				_sway_scheme(ev["id"])
			"juros":
				juros = ev["value"]
				_sfx.play("maquininha")
			"total":
				pass  # o total é mostrado depois do laço
		if ev["type"] != "total":
			_message.text = _playback_line(tx_name, value, juros, mult)
			await get_tree().create_timer(STEP_TIME).timeout

	_message.text = "%s   ·   TOTAL +%d" % [tx_name, total]
	if tax > 0:
		_message.text += "   (Leão da Receita: -%d)" % tax
	_shake(clampf(float(total) / maxf(1.0, run.bill.goal) * 4.0, 0.0, SHAKE_MAX))
	if total > run.bill.goal * BIG_RECEIPT_RATIO:
		_sfx.play("plateia")
	await _count_saldo(run.bill.saldo - (total - tax), run.bill.saldo)


func _playback_line(tx_name: String, value: int, juros: int, mult: int) -> String:
	var line := "%s   ·   VALOR %d   ·   JUROS x%d" % [tx_name, value, juros]
	if mult > 1:
		line += "   ·   CARTAZ x%d" % mult
	return line


## As cartas jogadas voam para a tela da máquina e somem (a conta é mostrada depois, na própria tela).
func _fly_played(played: Array) -> void:
	var target := _screen.get_global_rect().get_center()
	for i in range(played.size()):
		if not _cards.has(played[i]):
			continue
		var btn: BaseButton = _cards[played[i]]
		btn.pivot_offset = btn.size / 2.0
		var delay := i * 0.06
		var tween := create_tween().set_parallel(true)
		tween.tween_property(btn, "global_position", target - btn.size / 2.0, FLY_TIME) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(btn, "scale", Vector2(0.4, 0.4), FLY_TIME).set_delay(delay)
		tween.tween_property(btn, "modulate:a", 0.0, FLY_TIME * 0.5).set_delay(delay + FLY_TIME * 0.5)


## Pontos de uma nota: sobem da tela da máquina em amarelo e somem.
func _pop_points(points: int) -> void:
	var label := _terminal_label(40)
	label.text = "+%d" % points
	label.add_theme_color_override("font_color", HIGHLIGHT)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(randf_range(120.0, 320.0), 196.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", 110.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.finished.connect(label.queue_free)


## Cartaz do esquema balança (índice na faixa = índice em run.schemes).
func _sway_scheme(id: String) -> void:
	var i := run.schemes.find(id)
	if i < 0 or i >= _strip_slots.size():
		return
	var card: TextureRect = _strip_slots[i]["card"]
	card.pivot_offset = card.size / 2.0
	var tween := create_tween()
	tween.tween_property(card, "rotation", 0.12, 0.08)
	tween.tween_property(card, "rotation", -0.1, 0.12)
	tween.tween_property(card, "rotation", 0.0, 0.1)


## Saldo sobe de `from` até `to` (contagem da caixa registradora).
func _count_saldo(from: int, to: int) -> void:
	var tween := create_tween()
	_sfx.play("registradora")
	tween.tween_method(func(v: float) -> void: _stat_values["saldo"].text = "R$ %d" % int(v), float(from), float(to), 0.5)
	await tween.finished


## Tremor da tela: `strength` é o deslocamento máximo em px.
func _shake(strength: float) -> void:
	if strength <= 0.0:
		return
	var tween := create_tween()
	var step_time := SHAKE_TIME / SHAKE_STEPS
	for i in range(SHAKE_STEPS):
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(_game_root, "position", offset, step_time)
	tween.tween_property(_game_root, "position", Vector2.ZERO, step_time)


## Comprovante sai da impressora (desce); acima de 5× a meta ele chega gigante e treme.
func _print_receipt(big: bool) -> void:
	_sfx.play("impressora")
	if int(run.receipt.get("reward", 0)) > 0:
		get_tree().create_timer(0.5).timeout.connect(_sfx.play.bind("moedas"))
	if int(run.receipt.get("troco", 0)) > 0:
		get_tree().create_timer(0.9).timeout.connect(_sfx.play.bind("relampago"))
	_receipt.pivot_offset = _receipt.size / 2.0
	var tween := create_tween()
	if big:
		_receipt.position = RECEIPT_POS
		_receipt.scale = Vector2(BIG_RECEIPT_SCALE, BIG_RECEIPT_SCALE)
		tween.tween_property(_receipt, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_shake(SHAKE_MAX)
	else:
		_receipt.scale = Vector2.ONE
		_receipt.position = Vector2(RECEIPT_POS.x, -_receipt.size.y)
		tween.tween_property(_receipt, "position", RECEIPT_POS, 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_stat(key: String, text: String, color: Color) -> void:
	_stat_values[key].text = text
	_stat_values[key].add_theme_color_override("font_color", color)


func _on_swap_pressed() -> void:
	if _busy:
		return
	var result := run.swap()
	_sfx.play("papel" if result["ok"] else "erro")
	_message.text = "" if result["ok"] else _refusal_text(result["reason"])
	_refresh()


func _on_next_pressed() -> void:
	run.next_bill()
	_sfx.play("feirante")
	_message.text = ""
	_refresh()


func _refusal_text(reason: String) -> String:
	match reason:
		"no_selection":
			return "Escolha de 1 a 5 notas"
		"no_swaps":
			return "Sem trocas sobrando"
		"no_money":
			return "Sem dinheiro nem no cheque especial"
		"round_over", "run_not_playing":
			return "Esta conta já acabou"
	return ""


# --- helpers de construção -------------------------------------------------

## Tema do jogo: VT323 como fonte padrão e botões de papel com borda de tinta (mesmo visual em todas as telas).
func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = _font(FONT_TERMINAL)
	t.set_font("font", "Button", _font(FONT_TITLE))
	t.set_font_size("font_size", "Button", 24)
	for prop in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(prop, "Button", INK)
	t.set_color("font_disabled_color", "Button", BUTTON_DISABLED_INK)
	t.set_stylebox("normal", "Button", _button_box(BUTTON_PAPER, INK, 4, 0))
	t.set_stylebox("hover", "Button", _button_box(BUTTON_PAPER_HOVER, INK, 4, 0))
	t.set_stylebox("pressed", "Button", _button_box(BUTTON_PAPER_DOWN, INK, 0, 3))
	t.set_stylebox("disabled", "Button", _button_box(BUTTON_DISABLED, BUTTON_DISABLED_INK, 0, 0))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# Dica ao passar o mouse: papel e texto escuro, legível sobre qualquer fundo.
	var tip := _tag_box()
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font("font", "TooltipLabel", _font(FONT_TERMINAL))
	t.set_font_size("font_size", "TooltipLabel", 22)
	return t


## Etiqueta de papel colada sobre o cartaz do Camelô.
func _tag_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = RECEIPT_PAPER
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	return box


## Caixa de um botão: papel, borda de tinta, sombra leve. `press_offset` desce o texto (botão apertado).
func _button_box(bg: Color, border: Color, shadow: int, press_offset: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = shadow
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6 + press_offset
	box.content_margin_bottom = 6 - press_offset
	return box


## Tela "Como jogar": a arte traz só a tabela desenhada; título e células são escritos por cima, à mão.
func _build_howto_text() -> void:
	_howto.add_child(_hand_label(Rect2(0, 34, 1280, 70), "COMO JOGAR", 56, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))

	var cell_x := [140, 470, 760, 950]
	var cell_w := [330, 290, 190, 190]
	var heads := ["Transação", "Combinação", "Valor base", "Juros"]
	for c in range(4):
		var align := HORIZONTAL_ALIGNMENT_LEFT if c < 2 else HORIZONTAL_ALIGNMENT_CENTER
		_howto.add_child(_hand_label(Rect2(cell_x[c] + 12, 170, cell_w[c] - 24, 70), heads[c], 26, HAND_INK, align))

	for r in range(HOWTO_ORDER.size()):
		var kind: String = HOWTO_ORDER[r]
		var tx: Dictionary = Balance.TRANSACTIONS[kind]
		var y := 240.0 + r * 68.0
		var cells := [tx["name"], HOWTO_COMBO[kind], "R$ %d" % tx["base"], "x%d" % tx["juros"]]
		for c in range(4):
			var align := HORIZONTAL_ALIGNMENT_LEFT if c < 2 else HORIZONTAL_ALIGNMENT_CENTER
			_howto.add_child(_hand_label(Rect2(cell_x[c] + 12, y, cell_w[c] - 24, 68), cells[c], 22, HAND_INK, align))

	_howto.add_child(_hand_label(Rect2(0, 668, 1280, 36), "Clique em qualquer lugar para fechar", 22, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))


## Texto escrito à mão (Permanent Marker), usado sobre a arte da tela "Como jogar".
func _hand_label(rect: Rect2, text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", _font(FONT_HAND))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _tex(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _texture_rect(path: String, rect: Rect2, parent: Node) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = _tex(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


func _terminal_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TERMINAL_TEXT)
	return label


## Tecla do caixa (A2) com rótulo logo abaixo. Teclas sem função ficam apagadas.
func _key(root: Control, text: String, pos: Vector2, handler: Callable, enabled: bool = true) -> TextureButton:
	var key := TextureButton.new()
	key.texture_normal = _tex(TEX_KEY)
	key.texture_pressed = _tex(TEX_KEY_DOWN)
	key.ignore_texture_size = true
	key.stretch_mode = TextureButton.STRETCH_SCALE
	key.position = pos
	key.size = Vector2(64, 48)

	# Rótulo abaixo da tecla (a setinha da arte fica no meio da tecla).
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-8, 52)
	label.size = Vector2(80, 22)
	label.add_theme_font_override("font", _font(FONT_TITLE))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)

	if handler.is_valid():
		key.pressed.connect(handler)
	key.disabled = not enabled
	if not enabled:
		key.modulate = DIM
		label.modulate = DIM
	root.add_child(key)
	return key


func _set_key_enabled(key: TextureButton, enabled: bool) -> void:
	key.disabled = not enabled
	key.modulate = Color.WHITE if enabled else DIM


func _button(root: Control, text: String, rect: Rect2, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.pressed.connect(handler)
	btn.visible = false
	root.add_child(btn)
	return btn
