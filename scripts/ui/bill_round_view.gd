extends Control
## Interface da partida sobre a arte do caixa eletrônico (hora 7–12) e do Camelô.
## Toda regra vem de RunState/BillRound. Posições em pixels da resolução base 1280×720.

## Quanto a cédula sobe quando selecionada (px).
const LIFT := 24
const CARD_SIZE := Vector2(120, 180)
const LIFT_TIME := 0.12

# Janela vazada da moldura (A1) e área da mão embaixo, sobre a bancada.
const SCREEN := Rect2(240, 60, 800, 360)
const HAND_POS := Vector2(118, 516)
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

const TEX_FRAME := "res://art/caixa/caixa_moldura.png"
const TEX_KEY := "res://art/caixa/caixa_tecla.png"
const TEX_KEY_DOWN := "res://art/caixa/caixa_tecla_pressionada.png"
const TEX_TITLE := "res://art/telas/titulo.png"
const TEX_END_OK := "res://art/telas/fim_contas_em_dia.png"
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
var _boss_text: Label
var _boss_art: TextureRect
var _info: Label
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
var _shop_header: Label
var _shop_message: Label
var _shop_offers: Array = []   # [{"card", "plate", "price", "text", "buy"}] por oferta
var _shop_owned: Array = []    # [{"thumb", "sell"}] por esquema que você tem
var _haggle_button: Button
var _leave_button: Button

var _title: TextureButton

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
	# Tema do jogo inteiro: VT323 como fonte padrão (terminal, comprovante).
	var theme_jogo := Theme.new()
	theme_jogo.default_font = _font(FONT_TERMINAL)
	theme = theme_jogo

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
	_next_button = _button(root, "IR AO CAMELÔ", Rect2(412, 664, 200, 52), _on_next_pressed)

	_end_stamp = _texture_rect(TEX_END_OK, Rect2(440, 120, 400, 200), root)
	_end_stamp.visible = false

	_build_receipt(root)


func _build_screen_content(root: Control) -> void:
	_screen = Control.new()
	_screen.position = SCREEN.position + Vector2(16, 16)
	_screen.size = SCREEN.size - Vector2(32, 32)
	root.add_child(_screen)

	var column := VBoxContainer.new()
	column.size = Vector2(600, 184)
	column.add_theme_constant_override("separation", 6)
	_screen.add_child(column)

	_header = _terminal_label(34)
	_header.add_theme_font_override("font", _font(FONT_TITLE))
	column.add_child(_header)
	_boss_text = _terminal_label(18)
	_boss_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_boss_text)
	_info = _terminal_label(26)
	column.add_child(_info)
	_message = _terminal_label(28)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)

	# Imagem do chefe no canto direito da tela, só quando a fatura está ativa.
	_boss_art = _texture_rect("", Rect2(_screen.size.x - 120, 0, 120, 120), _screen)
	_boss_art.visible = false

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

	_receipt_label = Label.new()
	_receipt_label.position = Vector2(36, 60)
	_receipt_label.size = Vector2(168, 480)
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
	ribbon.size = Vector2(1280, 90)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ribbon)

	_shop_header = Label.new()
	_shop_header.position = Vector2(32, 28)
	_shop_header.size = Vector2(1216, 40)
	_shop_header.add_theme_font_override("font", _font(FONT_TITLE))
	_shop_header.add_theme_font_size_override("font_size", 32)
	_shop_header.add_theme_color_override("font_color", Color.WHITE)
	_shop_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_shop_header)

	_shop_message = Label.new()
	_shop_message.position = Vector2(32, 72)
	_shop_message.size = Vector2(1216, 30)
	_shop_message.add_theme_font_size_override("font_size", 24)
	_shop_message.add_theme_color_override("font_color", Color.WHITE)
	_shop_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_shop_message)

	# Duas ofertas, cada uma com cartaz, plaquinha de preço e botão de compra.
	for i in range(Balance.SHOP_OFFERS):
		var x := 260.0 + i * 460.0
		var card := _texture_rect("", Rect2(x, 130, 200, 280), root)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		_texture_rect(TEX_PRICE, Rect2(x + 150, 142, 80, 50), root)
		var price := Label.new()
		price.position = Vector2(x + 150, 142)
		price.size = Vector2(80, 50)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.add_theme_font_override("font", _font(FONT_TITLE))
		price.add_theme_font_size_override("font_size", 22)
		price.add_theme_color_override("font_color", INK)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(price)
		var text := Label.new()
		text.position = Vector2(x + 10, 230)
		text.size = Vector2(180, 90)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_override("font", _font(FONT_TITLE))
		text.add_theme_font_size_override("font_size", 20)
		text.add_theme_color_override("font_color", INK)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(text)
		var buy := _button(root, "COMPRAR", Rect2(x, 420, 200, 44), _on_buy_pressed.bind(i))
		_shop_offers.append({"card": card, "price": price, "text": text, "buy": buy})

	# Esquemas que você já tem: vender pela metade do preço.
	for i in range(Balance.MAX_SCHEMES):
		var x := 368.0 + i * 112.0
		var thumb := _texture_rect("", Rect2(x, 480, STRIP_SLOT.x, STRIP_SLOT.y), root)
		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.visible = false
		var sell := _button(root, "VENDER", Rect2(x, 618, STRIP_SLOT.x, 34), _on_sell_pressed.bind(i))
		sell.add_theme_font_size_override("font_size", 16)
		_shop_owned.append({"thumb": thumb, "sell": sell})

	_haggle_button = _button(root, "PECHINCHAR", Rect2(430, 662, 200, 44), _on_haggle_pressed)
	_leave_button = _button(root, "SEGUIR", Rect2(650, 662, 200, 44), _on_leave_shop_pressed)
	_leave_button.visible = true
	_haggle_button.visible = true


func _refresh_shop() -> void:
	_shop_header.text = "CAMELÔ   ·   Carteira R$ %d   ·   Cheque especial até R$ %d" % [run.wallet, -Balance.OVERDRAFT_LIMIT]

	for i in range(_shop_offers.size()):
		var o: Dictionary = _shop_offers[i]
		var has := i < run.shop_offer.size()
		for key in ["card", "price", "text", "buy"]:
			o[key].visible = has
		if not has:
			continue
		var id: String = run.shop_offer[i]
		var info: Dictionary = Balance.SCHEMES[id]
		o["card"].texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
		o["card"].tooltip_text = "%s\n%s" % [info["name"], info["desc"]]
		o["price"].text = "R$ %d" % info["price"]
		o["text"].text = info["text"]
		o["buy"].text = "COMPRAR R$ %d" % info["price"]
		var price: int = info["price"]
		o["buy"].disabled = run.schemes.size() >= Balance.MAX_SCHEMES or run.wallet - price < Balance.OVERDRAFT_LIMIT

	for i in range(_shop_owned.size()):
		var s: Dictionary = _shop_owned[i]
		var has := i < run.schemes.size()
		s["thumb"].visible = has
		s["sell"].visible = has
		if has:
			var id: String = run.schemes[i]
			var info: Dictionary = Balance.SCHEMES[id]
			s["thumb"].texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
			s["thumb"].tooltip_text = "%s\n%s" % [info["name"], info["desc"]]
			s["sell"].text = "VENDER R$ %d" % (int(info["price"]) / 2)

	_haggle_button.text = "PECHINCHAR R$ %d" % Balance.HAGGLE_COST
	_haggle_button.disabled = run.wallet - Balance.HAGGLE_COST < Balance.OVERDRAFT_LIMIT


func _on_buy_pressed(index: int) -> void:
	var result := run.buy(index)
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_sell_pressed(index: int) -> void:
	var result := run.sell(index)
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_haggle_pressed() -> void:
	var result := run.haggle()
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


func _on_leave_shop_pressed() -> void:
	run.leave_shop()
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
	_start_run()


func _start_run() -> void:
	run = RunState.new()
	_message.text = "INSIRA SUAS NOTAS"
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

	_header.text = "%s   ·   Carteira R$ %d" % [run.bill_title(), run.wallet]
	_header.add_theme_color_override("font_color", WARN if run.wallet < 0 else TERMINAL_TEXT)

	var boss_id := run.boss_id()
	# Com o comprovante por cima, a tela mostra só a mensagem (o comprovante já traz os números).
	var show_boss := not paid and boss_id != Boss.NONE
	_boss_text.visible = show_boss
	_boss_art.visible = show_boss
	if boss_id != Boss.NONE:
		_boss_text.text = "CHEFE: %s. %s" % [Balance.BOSSES[boss_id]["name"], Balance.BOSSES[boss_id]["text"]]
		_boss_art.texture = _tex(BOSS_ART[boss_id])

	_info.text = "Meta R$ %d   ·   Saldo R$ %d   ·   Dias %d   ·   Trocas %d" % [
		bill.goal, bill.saldo, bill.days_left, bill.swaps_left,
	]

	_set_key_enabled(_pay_key, playing)
	_set_key_enabled(_swap_key, playing)
	_hand_area.visible = playing
	_restart_button.visible = over
	_next_button.visible = paid
	_receipt.visible = paid
	_header.visible = not paid
	_info.visible = not paid
	_end_stamp.visible = over
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
	run.bill.toggle_select(note)
	var selected: bool = run.bill.selected.has(note)
	if _cards.has(note):
		_lift(_cards[note], selected)
	_update_status()


func _on_pay_pressed() -> void:
	var result := run.pay()
	if not result["ok"]:
		_message.text = _refusal_text(result["reason"])
	elif result.has("score") and result["score"]["kind"] != "none":
		var score: Dictionary = result["score"]
		var tx_name: String = Balance.TRANSACTIONS[score["kind"]]["name"]
		_message.text = "%s: +%d" % [tx_name, score["total"] - score["tax"]]
		if score["tax"] > 0:
			_message.text += "   (Leão da Receita: -%d)" % score["tax"]
	_refresh()


func _on_swap_pressed() -> void:
	var result := run.swap()
	_message.text = "" if result["ok"] else _refusal_text(result["reason"])
	_refresh()


func _on_next_pressed() -> void:
	run.next_bill()
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
	label.size = Vector2(80, 18)
	label.add_theme_font_override("font", _font(FONT_TITLE))
	label.add_theme_font_size_override("font_size", 14)
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
	btn.add_theme_font_override("font", _font(FONT_TITLE))
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(handler)
	btn.visible = false
	root.add_child(btn)
	return btn
