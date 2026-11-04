extends Control
## Interface provisória da conta (hora 4–7: "jogável feio"). Toda regra vem de BillRound.

var bill: BillRound

var _info: Label
var _message: Label
var _hand_box: HBoxContainer
var _pay_button: Button
var _swap_button: Button
var _restart_button: Button


func _ready() -> void:
	_build_ui()
	_start_round()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 24)
	column.add_child(_info)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 28)
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

	_pay_button = Button.new()
	_pay_button.text = "PAGAR"
	_pay_button.custom_minimum_size = Vector2(180, 56)
	_pay_button.pressed.connect(_on_pay_pressed)
	actions.add_child(_pay_button)

	_swap_button = Button.new()
	_swap_button.text = "TROCAR"
	_swap_button.custom_minimum_size = Vector2(180, 56)
	_swap_button.pressed.connect(_on_swap_pressed)
	actions.add_child(_swap_button)

	_restart_button = Button.new()
	_restart_button.text = "NOVA CONTA"
	_restart_button.custom_minimum_size = Vector2(180, 56)
	_restart_button.visible = false
	_restart_button.pressed.connect(_start_round)
	actions.add_child(_restart_button)


func _start_round() -> void:
	# Meta da primeira conta da jam: Boleto de Março.
	bill = BillRound.new(Balance.MONTHS[0]["boleto"])
	_message.text = "INSIRA SUAS NOTAS"
	_refresh()


func _refresh() -> void:
	_info.text = "Meta R$ %d   ·   Saldo R$ %d   ·   Dias %d   ·   Trocas %d" % [
		bill.goal, bill.saldo, bill.days_left, bill.swaps_left,
	]

	for child in _hand_box.get_children():
		child.queue_free()
	for note in bill.hand:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(110, 160)
		btn.text = "R$ %d\n%s" % [note.value, note.suit_name()]
		btn.button_pressed = bill.selected.has(note)
		btn.disabled = bill.is_over()
		btn.pressed.connect(_on_card_pressed.bind(note))
		_hand_box.add_child(btn)

	var over := bill.is_over()
	var can_act := not over
	_pay_button.disabled = not can_act
	_swap_button.disabled = not can_act
	_restart_button.visible = over
	if bill.state == BillRound.WON:
		_message.text = "CONTA PAGA! Recompensa R$ %d" % bill.reward(Balance.REWARD_BOLETO)
	elif bill.state == BillRound.LOST:
		_message.text = "NOME NEGATIVADO"


func _on_card_pressed(note: Note) -> void:
	bill.toggle_select(note)
	_refresh()


func _on_pay_pressed() -> void:
	var result := bill.pay()
	if not result["ok"]:
		_message.text = _refusal_text(result["reason"])
	else:
		var score: Dictionary = result["score"]
		_message.text = "%s: +%d" % [Balance.TRANSACTIONS[score["kind"]]["name"], score["total"]] if score["kind"] != "none" else ""
	_refresh()


func _on_swap_pressed() -> void:
	var result := bill.swap()
	_message.text = "" if result["ok"] else _refusal_text(result["reason"])
	_refresh()


func _refusal_text(reason: String) -> String:
	match reason:
		"no_selection":
			return "Escolha de 1 a 5 notas"
		"no_swaps":
			return "Sem trocas sobrando"
		"round_over":
			return "A conta já acabou"
	return ""
