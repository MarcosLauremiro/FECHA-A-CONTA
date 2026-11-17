extends SceneTree
## Captura de telas e marcas de tempo para GIFs. Rodar com janela e --write-movie (tempo fixo).
## Saída: PNGs em out=<pasta> e linhas "MARK nome quadro" no console.

var view
var frame := 0
var out := ""
var _shots_bill := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	process_frame.connect(func() -> void: frame += 1)
	_seq()


func wait(s: float) -> void:
	await create_timer(s).timeout


func mark(n: String) -> void:
	print("MARK %s %d" % [n, frame])


func shot(n: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(n + ".png"))
	print("SHOT %s %dx%d" % [n, img.get_width(), img.get_height()])


func _seq() -> void:
	var collection = load("res://scripts/core/collection.gd")
	var achievements = load("res://scripts/core/achievements.gd")
	var balance = load("res://scripts/balance.gd")

	view = load("res://scenes/main.tscn").instantiate()
	root.add_child(view)
	mark("abertura_ini")
	await wait(3.3)
	mark("abertura_fim")
	await wait(0.8)
	await shot("05_tela_inicial")

	mark("menu_ini")
	view._title_screen.started.emit()
	view._title_screen._slide_to_menu()
	await wait(1.8)
	mark("menu_fim")
	await shot("06_menu_caixa")

	# Coleção com parte dos itens já usados (para a vitrine mostrar arte e cinza lado a lado).
	var i := 0
	for id in balance.BOSSES.keys():
		if i % 2 == 0:
			collection._used[collection.key(collection.KIND_BOSS, id)] = true
		i += 1
	for id in balance.SCHEME_ORDER.slice(0, 9):
		collection._used[collection.key(collection.KIND_SCHEME, id)] = true
	for id in balance.INVESTMENT_ORDER.slice(0, 4):
		collection._used[collection.key(collection.KIND_INVESTMENT, id)] = true
	collection._loaded = true
	var col = load("res://scripts/ui/collection_screen.gd").open(view._title_screen)
	await wait(0.5)
	await shot("07_colecao_chefes")
	col._select(collection.KIND_SCHEME)
	await wait(0.3)
	await shot("08_colecao_esquemas")
	col.queue_free()

	for id in ["primeira_conta", "chefe_vencido", "escadinha", "investidor", "golpista"]:
		achievements._done[id] = true
	achievements._loaded = true
	var ach = load("res://scripts/ui/achievements_screen.gd").open(view._title_screen)
	await wait(0.5)
	await shot("09_conquistas")
	ach.queue_free()
	# Volta ao estado real para a partida mostrar o aviso de conquista.
	achievements._done.erase("primeira_conta")
	await wait(0.3)

	# Partida com sorteio fixo.
	view._title_screen.new_game_pressed.emit()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261117
	view.run = load("res://scripts/game/run_state.gd").new(rng)
	view.run.wallet += 40
	view.run.schemes = ["agiota", "coach", "cashback"]
	view.run._start_bill()
	view._refresh()
	await wait(1.0)
	await shot("10_mesa_inicio")

	for bill_n in 4:
		if view.run.state != "playing":
			break
		if view.run.bill.boss != "":
			await wait(0.6)
			await shot("14_chefe_%d" % bill_n)
		await _play_bill(bill_n)
		if view.run.state == "lost" or view.run.state == "won":
			break
		await _shop(bill_n)

	view._open_menu()
	await wait(0.4)
	await shot("16_pausa")
	view._close_menu()
	await wait(0.3)
	mark("fim")
	quit()


func _play_bill(bill_n: int) -> void:
	var first := true
	while view.run.state == "playing":
		while view._busy:
			await wait(0.1)
		var best := _best_subset(view.run.bill)
		if best["cards"].is_empty():
			break
		mark("jogada_ini_%d" % bill_n)
		for c in best["cards"]:
			view._on_card_pressed(c)
			await wait(0.28)
		await wait(0.6)
		if first and bill_n == 0:
			await shot("11_formacao")
		mark("pagar_%d" % bill_n)
		await view._on_pay_pressed()
		mark("jogada_fim_%d" % bill_n)
		await wait(0.5)
		first = false
	if view.run.state == "bill_paid":
		await wait(2.2)
		mark("comprovante_%d" % bill_n)
		if bill_n == 0:
			await shot("12_comprovante")


func _shop(bill_n: int) -> void:
	view._on_next_pressed()
	mark("banca_ini_%d" % bill_n)
	await wait(1.2)
	if bill_n == 0:
		await shot("13_banca")
	for idx in view.run.shop_offer.size():
		var id := str(view.run.shop_offer[idx])
		if id == "":
			continue
		if view.run.wallet >= view.run.price_of(id):
			view._select_offer(idx)
			await wait(0.6)
			view._do_buy(idx)
			await wait(0.8)
			break
	if bill_n == 2:
		await shot("15_banca_compras")
	mark("banca_fim_%d" % bill_n)
	view._on_leave_shop_pressed()
	await wait(1.0)


func _best_subset(bill) -> Dictionary:
	var balance = load("res://scripts/balance.gd")
	var best_cards: Array = []
	var best_total := -1
	var n: int = bill.hand.size()
	for m in range(1, 1 << n):
		var cards: Array = []
		for k in range(n):
			if m & (1 << k):
				cards.append(bill.hand[k])
		if cards.size() > balance.MAX_PLAYED:
			continue
		var p: Dictionary = bill.preview(cards)
		var total := 0 if p.is_empty() else int(p["total"]) - int(p["tax"])
		if total > best_total:
			best_total = total
			best_cards = cards
	return {"cards": best_cards, "total": best_total}
