extends Control
## Interface provisória da partida (hora 7–9: "jogável feio"). Toda regra vem de RunState/BillRound.

## Quanto a cédula sobe quando selecionada (px).
const LIFT := 24
const CARD_SIZE := Vector2(120, 180)
const LIFT_TIME := 0.12

var run: RunState

var _header: Label
var _boss: Label
var _info: Label
var _message: Label
var _hand_box: HBoxContainer
var _pay_button: Button
var _swap_button: Button
var _next_button: Button
var _restart_button: Button

# Note -> botão da carta (dentro do wrapper que cuida do espaço da mão).
var _cards: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_start_run()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 28)
	column.add_child(_header)

	_boss = Label.new()
	_boss.add_theme_font_size_override("font_size", 20)
	_boss.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))
	column.add_child(_boss)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 22)
	column.add_child(_info)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 24)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var center := CenterContainer.new()
	column.add_child(center)
	_hand_box = HBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", 12)
	center.add_child(_hand_box)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	column.add_child(actions)

	_pay_button = _make_button("PAGAR", actions, _on_pay_pressed)
	_swap_button = _make_button("TROCAR", actions, _on_swap_pressed)
	_next_button = _make_button("PRÓXIMA CONTA", actions, _on_next_pressed)
	_restart_button = _make_button("JOGAR DE NOVO", actions, _start_run)


func _make_button(text: String, parent: Control, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 56)
	btn.pressed.connect(handler)
	parent.add_child(btn)
	return btn


func _start_run() -> void:
	run = RunState.new()
	_message.text = "INSIRA SUAS NOTAS"
	_refresh()


func _refresh() -> void:
	_update_status()
	_rebuild_hand()


## Textos, saldo e botões. Não mexe na mão (para a animação de seleção não ser interrompida).
func _update_status() -> void:
	var bill := run.bill
	var playing := run.state == RunState.PLAYING

	_header.text = "%s   ·   Carteira R$ %d" % [run.bill_title(), run.wallet]
	_header.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2) if run.wallet < 0 else Color(1, 1, 1))

	var boss_id := run.boss_id()
	_boss.visible = boss_id != Boss.NONE
	if _boss.visible:
		_boss.text = "CHEFE: %s. %s" % [Balance.BOSSES[boss_id]["name"], Balance.BOSSES[boss_id]["text"]]

	_info.text = "Meta R$ %d   ·   Saldo R$ %d   ·   Dias %d   ·   Trocas %d" % [
		bill.goal, bill.saldo, bill.days_left, bill.swaps_left,
	]

	_pay_button.visible = playing
	_swap_button.visible = playing
	_next_button.visible = run.state == RunState.BILL_PAID
	_restart_button.visible = run.state == RunState.WON or run.state == RunState.LOST

	if run.state == RunState.WON:
		_message.text = "CONTAS EM DIA   ·   Saldo máximo R$ %d" % run.max_saldo
	elif run.state == RunState.LOST:
		_message.text = "NOME NEGATIVADO"
	elif run.state == RunState.BILL_PAID:
		_message.text = _receipt_text()


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
	return "COMPROVANTE · %s\nSaldo R$ %d (meta R$ %d)   ·   Recompensa +R$ %d   ·   Troco +R$ %d   ·   Carteira R$ %d" % [
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
