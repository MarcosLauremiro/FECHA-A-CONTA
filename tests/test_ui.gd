extends SceneTree
## Teste de fumaça da interface: monta a cena principal e confere a mão.
##   godot --headless -s res://tests/test_ui.gd

var _frames := 0
var _scene: Node


func _initialize() -> void:
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 2:
		return false

	var box: HBoxContainer = _scene._hand_box
	var failures := 0

	if box.get_child_count() != Balance.HAND_SIZE:
		failures += 1
		printerr("FALHOU: mão tem %d cartas, esperado %d" % [box.get_child_count(), Balance.HAND_SIZE])

	for child in box.get_children():
		if not child.get_child(0) is TextureButton:
			failures += 1
			printerr("FALHOU: carta sem imagem (%s)" % child.get_child(0).get_class())
			break

	print("\n%d falhas na interface" % failures)
	quit(1 if failures > 0 else 0)
	return true
