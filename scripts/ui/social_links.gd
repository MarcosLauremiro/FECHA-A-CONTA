class_name SocialLinks
extends RefCounted
## Links do jogo nas redes: Discord e Instagram. Os botões aparecem nas telas iniciais e na página de créditos.

const DISCORD_URL := "https://discord.gg/dchstYCe5"
const INSTAGRAM_URL := "https://www.instagram.com/lauremiro.dev/"
const FONT_TITLE := "res://fonts/Anton/Anton-Regular.ttf"
const INK := Color("2B2B2B")
const PAPER := Color("F4EDD9")
const PAPER_HOVER := Color("FFF8E7")
const PAPER_DOWN := Color("D9CCAE")


## Botão pequeno de rede social: texto em caixa de papel. Ao clicar, abre o link no navegador.
## Com `url` vazio, o botão só desenha a caixa (quem chama conecta o clique).
static func make_button(text: String, url: String, size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", load(FONT_TITLE) as Font)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PAPER_HOVER if state == "hover" else (PAPER_DOWN if state == "pressed" else PAPER)
		style.border_color = INK
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override(state, style)
	if url != "":
		btn.pressed.connect(func() -> void: OS.shell_open(url))
	return btn
