extends SceneTree
## Medição de desempenho (não é teste automático): abre o jogo, passa pelo menu e pela mesa,
## e imprime FPS sem limite, tempo de quadro, chamadas de desenho e memória em cada tela.

var view


func _initialize() -> void:
	_seq()


func wait(s: float) -> void:
	await create_timer(s).timeout


func sample(label: String, secs: float) -> void:
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var worst := 0
	var last := t0
	var draws := 0
	while Time.get_ticks_usec() - t0 < int(secs * 1e6):
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		frames += 1
		draws = maxi(draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	var el := (Time.get_ticks_usec() - t0) / 1e6
	print("PERF %-10s fps=%6.0f  pior_quadro=%5.1fms  desenhos=%4d  nos=%5d  objetos=%6d  mem=%5.1fMB  video=%6.1fMB" % [
		label, frames / el, worst / 1000.0, draws,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])


func _seq() -> void:
	var t := Time.get_ticks_msec()
	view = load("res://scenes/main.tscn").instantiate()
	root.add_child(view)
	await process_frame
	print("PERF abrir_cena %dms" % (Time.get_ticks_msec() - t))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await wait(4.0)
	await sample("titulo", 3.0)
	view._title_screen.started.emit()
	view._title_screen._slide_to_menu()
	await wait(2.0)
	await sample("menu", 3.0)
	view._title_screen.new_game_pressed.emit()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261117
	view.run = load("res://scripts/game/run_state.gd").new(rng)
	view.run._start_bill()
	view._refresh()
	await wait(1.5)
	await sample("mesa", 3.0)
	var t2 := Time.get_ticks_usec()
	for i in 20:
		view._refresh()
	print("PERF refresh_mesa %.2fms" % ((Time.get_ticks_usec() - t2) / 20000.0))
	view.run.state = "bill_paid"
	view.run.next_bill()
	view._refresh()
	await wait(1.5)
	await sample("banca", 3.0)
	var t3 := Time.get_ticks_usec()
	for i in 20:
		view._refresh()
	print("PERF refresh_banca %.2fms" % ((Time.get_ticks_usec() - t3) / 20000.0))
	quit()
