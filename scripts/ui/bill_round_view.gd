extends Control
## Interface da partida sobre a arte do caixa eletrônico (hora 7–12) e do Camelô.
## Toda regra vem de RunState/BillRound. Posições em pixels da resolução base 1280×720.

## Quanto a cédula sobe quando selecionada (px).
const LIFT := 24
const CARD_SIZE := Vector2(120, 180)
const STAMP_POS := Vector2(74, 128)   # canto inferior direito da cédula neutra (ajustar se ficar mal)
const STAMP_SIZE := Vector2(40, 40)
const SORT_NORMAL := "normal"      # ordem em que as notas entraram na mão
const SORT_SUIT := "forma"         # agrupada por forma de pagamento (selo)
const SORT_VALUE := "valor"        # por valor crescente
const LIFT_TIME := 0.12

# Sensação da pontuação (só apresentação; a regra já foi resolvida em RunState.pay()).
const PROCESSING_TIME := 0.4     # "AGUARDE… PROCESSANDO" antes da contagem
const STEP_TIME := 0.14          # pausa entre cada evento da lista
const SHAKE_TIME := 0.3
const SHAKE_STEPS := 6
const SHAKE_MAX := 16.0          # tremor máximo (px)
const BIG_RECEIPT_RATIO := 5     # saldo acima de 5× a meta: comprovante gigante
const BIG_RECEIPT_SCALE := 2.2
const RECEIPT_POS := Vector2(520, 34)  # sai logo abaixo da fenda da impressora (arte)
const PRINT_TIME := 2.0                # tempo para o comprovante sair da impressora (igual ao som)
const HIGHLIGHT := Color("FFE066")
const PLAYED_RAISE := 50.0    # cartas jogadas sobem este tanto acima da mão durante a contagem
const RAISE_TIME := 0.6       # subida das cartas jogadas (lenta, sem solavanco)
const DROP_TIME := 0.45       # cartas jogadas descem para fora da tela depois da contagem
const DROP_DISTANCE := 760.0
const POINTS_RISE := 34.0     # pontuação de cada nota aparece logo acima da carta
# Impacto de cada carta que pontua (estufa e pisca).
const IMPACT_UP := 0.09
const IMPACT_DOWN := 0.18
const IMPACT_FLASH := Color(1.5, 1.4, 1.0)
const IMPACT_SHAKE := 2.0

# Como cada número aparece na arte: o texto é o valor preenchido em %s.
const STAT_FORMAT := {
	"carteira": "%s",
	"meta": "%s",
	"saldo": "SALDO  %s",
	"dias": "DIAS  %s",
	"trocas": "TROCAS  %s",
}

# Janela da tela na mesa (tela_caixa_mesa.aseprite): canto e tamanho da abertura da moldura.
const SCREEN := Rect2(316, 102, 649, 383)
# Mão embaixo da tela, à esquerda da calculadora (que começa em x 1062).
const HAND_POS := Vector2(40, 500)
const HAND_AREA := Vector2(1000, 192)
const HAND_SEPARATION := 4          # 8 cartas cabem nos 1000 px
# Painel do baralho (segurar TAB, ou o botão BARALHO no canto inferior direito): cédulas por forma de pagamento.
const STATUS_POS := Vector2(290, 120)
const STATUS_SIZE := Vector2(700, 480)
const STATUS_BUTTON := Rect2(1096, 640, 156, 48)
const STATUS_ROW_Y := 100.0
const STATUS_ROW_H := 32.0
const STATUS_CELL := Vector2(126, 28)
const STATUS_COL_X := 130.0
const STATUS_COL_STEP := 140.0
const STATUS_SUIT_COLORS := [Color("A8D5A2"), Color("7FD1C4"), Color("9CC4E8"), Color("C9A8E8")]  # Dinheiro, Pix, Débito, Crédito
const STATUS_EMPTY := Color("E4DCC6")
const CONTACT_BUTTON_SIZE := Vector2(160, 50)
const CONTACT_BUTTON_POS := Vector2(95, 448)  # painel da esquerda, embaixo do investimento (só um contato por vez)

# Faixa de esquemas dentro da tela: 5 espaços já desenhados na arte (posição em coordenadas da tela).
const STRIP_POS := Vector2(39, 92)
const STRIP_SLOT := Vector2(98, 136)
const STRIP_GAP := 20
# Camelô: esquemas comprados, na faixa do topo (à direita do título).
const OWNED_X := 260.0
const OWNED_SIZE := Vector2(72, 100)
const OWNED_GAP := 40.0       # espaço entre as cartas compradas (botão VENDER cabe sem sobrepor)
const OWNED_SELL_W := 104.0   # largura do botão VENDER, centrado na carta

# Cores sobre o display da calculadora.
const LCD_INK := Color("1E3B2A")
const DANGER_LCD := Color("B5382C")

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
	"janeiro_impostos": "JANEIRO",
	"bolsa_familia": "BOLSA\nFAMÍLIA",
	"banco_fora_do_ar": "BANCO FORA\nDO AR",
	"curso_primo_rico": "CURSO DO\nPRIMO RICO",
	"urubu_pix": "URUBU\nDO PIX",
	"taxa_manutencao": "TAXA DE\nMANUTENÇÃO",
	"ferias_praia": "FÉRIAS NA\nPRAIA",
	"dia_dos_pais": "DIA DOS\nPAIS",
	"grosso": "ENTRAR O\nGROSSO",
	"bandeira_vermelha": "BANDEIRA\nVERMELHA",
	"julius": "JULIUS",
	"decimo_terceiro": "13º\nSALÁRIO",
}

# Tabela da tela "Como jogar" (valores vêm de Balance.TRANSACTIONS).
const HOWTO_ORDER := ["trocado", "dobradinha", "bolada", "escadinha", "tudo_no_pix", "cofrinho"]
const HOWTO_COMBO := {
	"trocado": "a nota de maior valor",
	"dobradinha": "2 notas de mesmo valor",
	"bolada": "3 notas de mesmo valor",
	"escadinha": "5 notas em sequência",
	"tudo_no_pix": "5 notas do mesmo naipe",
	"cofrinho": "4 notas de mesmo valor",
}

# Mesa do caixa (exportada de art/caixa/tela_caixa_mesa.aseprite): fundo, calculadora e impressora de cima.
const TEX_MESA_FUNDO := "res://art/caixa/mesa/mesa_fundo.png"
const TEX_MESA_CALC := "res://art/caixa/mesa/mesa_calculadora.png"
const TEX_MESA_IMPRESSORA := "res://art/caixa/mesa/mesa_impressora.png"

# Teclas da calculadora: folhas do aseprite (8 quadros de 76x72, na ordem do arquivo).
# Tags: repouso = quadro 0; hover = quadros 1 a 3 (loop); clique = quadros 4 a 7 (uma vez).
const CALC_SHEET_DIR := "res://art/caixa/mesa/ui/calculadora/"
# Botões do jogo (art/ui/botoes): tiras de 9 quadros de 192x58.
const BUTTON_SHEET_DIR := "res://art/ui/botoes/"
const BUTTON_FRAME := Vector2(192, 58)
const BUTTON_FRAME_NORMAL := 0
const BUTTON_FRAME_HOVER := 1
const BUTTON_FRAME_PRESSED := 5
const BUTTON_FRAME_DISABLED := 8
# Carteira do Camelô (art/camelo/carteira.png, 336x160), no canto inferior esquerdo.
# Centros e ângulos dos papéis medidos nos guias da arte (carteira.aseprite, camada TEXTO).
const TEX_WALLET := "res://art/camelo/carteira.png"
const WALLET_POS := Vector2(8, 560)               # 560 + 160 = 720: encosta na borda de baixo
const WALLET_SIZE := Vector2(336, 160)
const WALLET_MONEY_CENTER := Vector2(109, 45)     # papel verde (dinheiro)
const WALLET_MONEY_ANGLE := -0.124                # ≈ -7°
const WALLET_CHEQUE_CENTER := Vector2(248, 51)    # papel vermelho (cheque especial)
const WALLET_CHEQUE_ANGLE := 0.110                # ≈ +6°
const WALLET_TEXT_BOX := Vector2(82, 26)
const CALC_FRAMES := 8
const CALC_FRAME_SIZE := Vector2(76, 72)
const CALC_FRAME_TIMES := [0.1, 0.06, 0.06, 0.12, 0.04, 0.05, 0.06, 0.07]  # segundos por quadro
const CALC_IDLE := [0]
const CALC_HOVER := [1]  # hover: imagem fixa (quadro 1), sem piscar
const CALC_CLICK := [4, 5, 6, 7]
# Tutorial (tela "Como jogar"): páginas passo a passo. "example" escolhe o desenho de apoio.
const TUTORIAL_PAGES := [
	{"title": "O OBJETIVO", "body": "Cada conta tem uma meta de saldo. Você tem 4 dias e 3 trocas para bater a meta. Bateu: a conta está paga. Não bateu até o fim dos dias: a partida acaba. A partida tem 6 meses, e cada mês tem 3 contas: boleto, aluguel e fatura. Pagou os 6 meses: dá para continuar no modo infinito."},
	{"title": "SUAS NOTAS", "body": "Você recebe 8 notas. Escolha de 1 a 5 e aperte PAGAR para jogar, ou TROCAR para trocar as selecionadas por outras (gasta uma troca). A forma de pagamento aparece no selo de cada nota.", "example": "suits"},
	{"title": "AS FORMAÇÕES", "body": "O jogo reconhece a formação pelas notas escolhidas. Cada uma tem um Valor base e Juros. Dois Carnês e Conta Conjunta só aparecem depois de comprar o Carnê e a Conta Conjunta na Banca.", "example": "table"},
	{"title": "COMO SE PONTUA", "body": "Pontos = (Valor base + Valor das notas + Valor dos esquemas e investimentos) × Juros. Ao selecionar as notas, a mesa mostra o Valor e os Juros da jogada antes de pagar.", "example": "formula"},
	{"title": "DIAS E TROCO", "body": "PAGAR gasta 1 dia. Com a meta batida, a sobra vira troco: R$ 1 a cada 25% acima da meta, até R$ 5. Cada dia que sobrou na conta também paga R$ 1. Cada conta começa com 4 dias e 3 trocas novos."},
	{"title": "A BANCA", "body": "Entre as contas, a Banca vende 2 esquemas e 1 investimento. Esquemas mudam a pontuação de todas as jogadas (no máximo 5 ao mesmo tempo). Investimentos sobem o Valor e os Juros de uma formação. PECHINCHAR troca a oferta por R$ 2. Vender devolve metade do preço. O cheque especial tem R$ 10 por partida: cada R$ usado vira R$ 3 de dívida e o limite diminui. Gastar tudo acaba a partida."},
	{"title": "OS CHEFES", "body": "Cada mês tem um chefe. Ele vale só na fatura, que é a 3ª conta do mês. O carimbo no canto mostra o nome dele, e o texto aparece na tela do terminal. Leia antes de jogar a fatura."},
]
const TEX_END_OK :="res://art/telas/fim_contas_em_dia.png"
const TEX_END_BAD := "res://art/telas/fim_negativado.png"
const TEX_RECEIPT := "res://art/comprovante/comprovante_termico.png"
# Banca do Zé (art/banca): o fundo e o balcão são camadas separadas, e o Seu Zé fica entre as duas.
const TEX_SHOP_BG := "res://art/banca/banca_fundo.png"
const TEX_SHOP_FRONT := "res://art/banca/banca_frente.png"
const TEX_ZE := "res://art/banca/seu_ze.png"        # folha com 20 quadros de 128x144, lado a lado
const ZE_FRAMES := 20
const ZE_SCALE := 2.0
const ZE_POS := Vector2(640, 352)                  # centro do quadro: a cintura some atrás do balcão (y = 450)
# Duração de cada quadro, em segundos (igual ao seu_ze.aseprite).
const ZE_DURATIONS := [0.34, 0.34, 0.34, 0.34, 0.11, 0.34, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.09, 0.09, 0.42, 0.30, 0.13, 0.13, 0.13, 0.13]
const ZE_IDLE := [0, 5]                            # parado: fica em laço
const ZE_ACTIONS := [[6, 11], [12, 15], [16, 19]]  # acenar, joinha, rir: uma delas de tempos em tempos
const ZE_WAIT := [4.0, 9.0]                        # segundos parado entre uma animação e outra
# Lugar de cada oferta na banca: centro do cartaz ou ícone, e y do botão de compra.
# 0 e 1: esquemas, na prateleira do meio, um de cada lado do Seu Zé. 2: investimento, no painel da esquerda.
const OFFER_SPOTS := [
	{"c": Vector2(410, 351), "buy_y": 432.0},
	{"c": Vector2(870, 351), "buy_y": 432.0},
	{"c": Vector2(175, 338), "buy_y": 404.0},
]
# Painel da direita (caderneta): investimentos comprados, abertos pelo botão INVESTIMENTOS.
const LEVELS_RECT := Rect2(1028, 262, 154, 326)
const LEVELS_BUTTON := Rect2(1066, 658, 190, 50)
const SCHEME_SIZE := Vector2(110, 150)  # cartaz de esquema na loja
const ICON_SIZE := Vector2(120, 120)    # ícone de investimento na loja (não muda)
const BUY_H := 32.0
const BUY_FONT := 16
const BUY_MIN_W := 100.0                # largura mínima; cresce com o texto
const BUY_PAD := 28.0                   # folga para o texto dentro do botão
const OFFER_ZOOM := 1.12                # zoom da oferta escolhida
const OFFER_ZOOM_TIME := 0.28           # duração da animação de zoom (s)

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
var _header: Label                  # mês (papel creme, à esquerda)
var _bill_label: Label             # tipo de boleto (papel creme, à direita)
var _stats: Control                # saldo, dias e trocas (dentro da tela)
var _stat_values: Dictionary = {}  # {carteira/meta/saldo/dias/trocas: Label com o valor}
var _boss_text: Label
var _boss_art: TextureRect
var _boss_stamp_text: Label
var _levels: Label
var _message: Label
var _strip_slots: Array = []   # [{"slot", "empty", "card"}] por espaço de esquema
var _hand_area: Control
var _hand_box: HBoxContainer
var _sort_key: Button              # tecla FORMA (ordem da mão: por forma de pagamento)
var _sort_value_key: Button        # tecla VALOR (ordem da mão: por valor)
var _sort_mode := SORT_NORMAL      # como a mão é exibida; não muda a regra
var _pay_key: Button
var _swap_key: Button
var _restart_button: Button
var _next_button: Button
var _endless_button: Button
var _end_stamp: TextureRect
var _receipt: NinePatchRect
var _receipt_clip: Control          # janela da impressora: o papel aparece de cima para baixo
var _receipt_title: Label
var _receipt_rows: VBoxContainer

# Interface do Camelô (escondida na partida).
var _shop_root: Control
var _shop_wallet: Label
var _shop_cheque: Label
var _shop_message: Label
var _shop_levels_row: VBoxContainer  # investimentos com nível: canto inferior direito, um sobre o outro
var _shop_offers: Array = []   # [{"card", "icon", "buy"}] por oferta
var _levels_button: Button
var _shop_boss: Label          # aviso do chefe do mês na Banca
var _levels_open := false     # caderneta de investimentos aberta (botão INVESTIMENTOS)
var _ze: Sprite2D
var _ze_range: Array = ZE_IDLE
var _ze_frame_time := 0.0
var _ze_wait := 5.0
var _selected_offer := -1      # oferta escolhida no Camelô (-1 = nenhuma)
var _shop_owned: Array = []    # [{"thumb", "sell"}] por esquema que você tem
var _haggle_button: Button
var _leave_button: Button
var _contact_buttons: Dictionary = {}  # id do contato -> Button (ao lado do SEGUIR; só aparece no mês)

# Painel do baralho (TAB ou botão BARALHO).
var _status_panel: Control
var _status_title: Label
var _status_cells: Array = []  # {"cell", "used"} por (cédula, forma): índice = linha * 4 + forma
var _tab_held := false       # TAB apertado: o painel aparece enquanto segura
var _panel_pinned := false   # aberto pelo botão MÃO: fica até o FECHAR

var _title_screen: TitleScreen  # tela inicial (atração + menu do caixa)
var _sfx: Sfx                  # sons e música (ver scripts/ui/sfx.gd)
var _boss_stamp_key := ""      # última fatura com carimbo tocado
var _end_stamp_played := false
var _howto: Control              # tela tr("Como jogar"): tutorial em páginas
var _tut_index := 0              # página atual do tutorial
var _tut_body: Control           # conteúdo da página atual (refeito a cada troca)
var _menu_root: Control        # menu de pausa (Esc): continuar, salvar, recomeçar
var _menu_save: Button
var _menu_restart: Button
var _menu_back: Button
var _menu_status: Label
var _restart_armed := false    # RECOMEÇAR pede confirmação com um segundo clique
var _back_armed := false       # VOLTAR AO MENU também pede confirmação

# Verdadeiro durante a animação de pontuação: entrada do jogador fica travada.
var _busy := false

# Note -> botão da carta (dentro do wrapper que cuida do espaço da mão).
var _cards: Dictionary = {}


func _ready() -> void:
	_build_ui()


## Esc abre o menu de pausa. F11 alterna tela cheia e janela (útil no desenvolvimento).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_menu()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


## TAB: enquanto segura, mostra o painel da mão. Usa _input (antes do foco dos botões, que usa o próprio Tab).
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or event.keycode != KEY_TAB:
		return
	if run == null or _title_screen.visible or _howto.visible or _menu_root.visible or _busy:
		return
	_tab_held = event.pressed
	_sync_status_panel()
	get_viewport().set_input_as_handled()


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

	# Tela inicial: caixa eletrônico com a atração e o menu (ver scripts/ui/title_screen.gd).
	_title_screen = TitleScreen.new(SaveGame.exists())
	_title_screen.started.connect(_sfx.play_music)
	_title_screen.new_game_pressed.connect(_on_title_pressed)
	_title_screen.continue_pressed.connect(_on_continue_pressed)
	_title_screen.howto_pressed.connect(_on_howto_pressed)
	_title_screen.quit_pressed.connect(func() -> void: get_tree().quit())
	add_child(_title_screen)

	_howto = Control.new()
	_howto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_howto.mouse_filter = Control.MOUSE_FILTER_STOP
	_howto.visible = false
	_howto.draw.connect(_draw_paper.bind(_howto))
	add_child(_howto)
	_build_menu()


## Menu de pausa (Esc): fica por cima de tudo e bloqueia os cliques da partida.
func _build_menu() -> void:
	_menu_root = Control.new()
	_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_root.visible = false
	add_child(_menu_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_root.add_child(dim)

	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _nine("ui_painel", 20, 22, 20, 22))
	panel.position = Vector2(440, 150)
	panel.size = Vector2(400, 510)
	_menu_root.add_child(panel)

	var title := Label.new()
	title.text = tr("PAUSA")
	title.position = Vector2(440, 168)
	title.size = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font(FONT_TITLE))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", INK)
	_menu_root.add_child(title)

	_menu_button(tr("CONTINUAR"), Rect2(490, 250, 300, 56), _close_menu)
	_menu_save = _menu_button(tr("SALVAR PARTIDA"), Rect2(490, 306, 300, 56), _on_save_pressed)
	_menu_button(tr("OPÇÕES"), Rect2(490, 362, 300, 56), _on_pause_options)
	_menu_restart = _menu_button(tr("RECOMEÇAR"), Rect2(490, 418, 300, 56), _on_restart_pressed)
	_menu_back = _menu_button(tr("VOLTAR AO MENU"), Rect2(490, 474, 300, 56), _on_back_pressed)

	_menu_status = Label.new()
	_menu_status.position = Vector2(440, 556)
	_menu_status.size = Vector2(400, 50)
	_menu_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_status.add_theme_font_override("font", _font(FONT_TERMINAL))
	_menu_status.add_theme_font_size_override("font_size", 22)
	_menu_status.add_theme_color_override("font_color", INK)
	_menu_root.add_child(_menu_status)


func _menu_button(text: String, rect: Rect2, handler: Callable) -> Button:
	var btn := _button(_menu_root, text, rect, handler)
	btn.visible = true
	return btn


# --- Partida ---------------------------------------------------------------

func _build_game(root: Control) -> void:
	# Fundo da mesa: carcaça, moldura, tela e espaços dos esquemas. Fica atrás de tudo.
	_texture_rect(TEX_MESA_FUNDO, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)

	_build_screen_content(root)

	_hand_area = Control.new()
	_hand_area.position = HAND_POS
	_hand_area.size = HAND_AREA
	root.add_child(_hand_area)
	_hand_box = HBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", HAND_SEPARATION)
	_hand_area.add_child(_hand_box)

	_restart_button = _button(root, tr("JOGAR DE NOVO"), Rect2(540, 528, 200, 56), _start_run)
	# Embaixo do comprovante impresso: centro do comprovante = RECEIPT_POS.x + 120.
	_next_button = _button(root, tr("IR PARA A BANCA"), Rect2(RECEIPT_POS.x + 120 - 120, 664, 240, 52), _on_next_pressed)
	# Venceu os 6 meses: ao lado do JOGAR DE NOVO, segue no modo infinito.
	_endless_button = _button(root, tr("CONTINUAR ∞"), Rect2(RECEIPT_POS.x + 250, 664, 200, 52), _on_endless_pressed)

	# Carimbo de fim: por cima dos esquemas, no centro da tela.
	_end_stamp = _texture_rect(TEX_END_OK, Rect2(520, 236, 240, 120), root)
	_end_stamp.visible = false

	# Calculadora e mini impressora da arte; as teclas e os números ficam por cima.
	_texture_rect(TEX_MESA_CALC, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)
	_build_calculator(root)

	_build_receipt(root)

	# Impressora de cima por último: o comprovante sai de baixo dela.
	_texture_rect(TEX_MESA_IMPRESSORA, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)

	_build_status_panel(root)


## Painel do baralho: aparece com TAB (enquanto segura) ou pelo botão BARALHO (até o FECHAR).
## Mostra as cédulas que ainda estão na conta (mão + compra), por forma de pagamento e por valor.
func _build_status_panel(root: Control) -> void:
	_status_panel = Panel.new()
	_status_panel.position = STATUS_POS
	_status_panel.size = STATUS_SIZE
	var paper := StyleBoxFlat.new()
	paper.bg_color = RECEIPT_PAPER
	paper.border_color = INK
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(6)
	_status_panel.add_theme_stylebox_override("panel", paper)
	_status_panel.visible = false
	root.add_child(_status_panel)

	_status_title = _label(_status_panel, Rect2(20, 14, 660, 44), 34, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_status_title.add_theme_font_override("font", _font(FONT_TITLE))

	# Cabeçalho: uma coluna por forma de pagamento (nomes de Balance.SUIT_NAMES, na ordem do Note.Suit).
	for s in range(Balance.SUIT_NAMES.size()):
		var head := _label(_status_panel, Rect2(STATUS_COL_X + s * STATUS_COL_STEP, 62, STATUS_CELL.x, 30), 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
		head.text = tr(Balance.SUIT_NAMES[s])

	# Uma linha por cédula; cada célula mostra quantas dessa cédula e forma restam.
	for v in range(Balance.VALUES.size()):
		var row_y := STATUS_ROW_Y + v * STATUS_ROW_H
		var value := _label(_status_panel, Rect2(14, row_y, 104, STATUS_CELL.y), 22, INK, HORIZONTAL_ALIGNMENT_RIGHT)
		value.text = "R$ %d" % Balance.VALUES[v]
		for s in range(Balance.SUIT_NAMES.size()):
			var cell := _label(_status_panel, Rect2(STATUS_COL_X + s * STATUS_COL_STEP, row_y, STATUS_CELL.x, STATUS_CELL.y), 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
			# Canto direito da célula: quantas dessa cédula já foram usadas (jogadas ou trocadas).
			var used := _label(cell, Rect2(STATUS_CELL.x - 44, 0, 40, STATUS_CELL.y), 16, INK, HORIZONTAL_ALIGNMENT_RIGHT)
			_status_cells.append({"cell": cell, "used": used})

	# _button começa escondido: aqui ele aparece (o painel é que decide quando mostrar).
	var close := _button(_status_panel, tr("FECHAR"), Rect2(STATUS_SIZE.x / 2.0 - 100, 436, 200, 36), _on_status_close)
	close.visible = true

	var open := _button(root, tr("BARALHO"), STATUS_BUTTON, _on_status_button)
	open.visible = true


## Mostra ou esconde o painel conforme TAB e o botão BARALHO. Na loja, nunca aparece.
func _sync_status_panel() -> void:
	var show := run != null and _game_root.visible and run.state != RunState.SHOP and (_tab_held or _panel_pinned)
	_status_panel.visible = show
	if show:
		_refresh_status_panel()


func _refresh_status_panel() -> void:
	var remaining: Array = run.bill.hand + run.bill.deck.draw_pile
	var used: Array = run.bill.deck.discard_pile
	_status_title.text = tr("NA CONTA: %d restantes · %d usadas") % [remaining.size(), used.size()]
	var left := _count_by_cell(remaining)
	var spent := _count_by_cell(used)
	for v in range(Balance.VALUES.size()):
		for s in range(Balance.SUIT_NAMES.size()):
			var key := "%d-%d" % [Balance.VALUES[v], s]
			var rem: int = left.get(key, 0)
			var usd: int = spent.get(key, 0)
			var entry: Dictionary = _status_cells[v * Balance.SUIT_NAMES.size() + s]
			var cell: Label = entry["cell"]
			cell.text = "×%d" % rem if rem > 0 else "–"
			cell.add_theme_color_override("font_color", INK if rem > 0 else DIM)
			cell.add_theme_stylebox_override("normal", _status_cell_box(STATUS_SUIT_COLORS[s] if rem > 0 else STATUS_EMPTY))
			(entry["used"] as Label).text = "+%d" % usd if usd > 0 else ""


## Conta notas por "valor-forma" (chave da grade do baralho).
func _count_by_cell(notes: Array) -> Dictionary:
	var counts := {}
	for n in notes:
		var key := "%d-%d" % [n.value, n.suit]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


## Fundo colorido de uma célula do baralho (cor da forma de pagamento; vazio = papel claro).
func _status_cell_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box


func _on_status_button() -> void:
	_panel_pinned = true
	_sync_status_panel()


func _on_status_close() -> void:
	_panel_pinned = false
	_tab_held = false
	_sync_status_panel()


## Calculadora: display com a carteira, teclas por cima dos botões e mini impressora com a meta.
func _build_calculator(root: Control) -> void:
	_stat_values["carteira"] = _label(root, Rect2(1092, 252, 127, 39), 44, LCD_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	# Meta no papel da mini impressora: o nome pequeno em cima, o valor embaixo (como antes).
	var meta_name := _label(root, Rect2(1100, 40, 110, 18), 14, INK, HORIZONTAL_ALIGNMENT_CENTER)
	meta_name.text = tr("META")
	_stat_values["meta"] = _label(root, Rect2(1100, 56, 110, 26), 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	# Quatro teclas, centralizadas um pouco à esquerda do corpo da calculadora.
	# Esquerda: VALOR em cima, FORMA embaixo. Direita: TROCAR em cima, PAGAR embaixo.
	_sort_value_key = _calc_key(root, tr("VALOR"), tr("Organiza a mão por valor, do menor para o maior."), Rect2(1078, 326, 72, 62), _on_sort_value_pressed, false, "tecla_valor.png")
	_sort_key = _calc_key(root, tr("FORMA"), tr("Agrupa a mão por forma de pagamento (selo)."), Rect2(1078, 410, 72, 62), _on_sort_suit_pressed, false, "tecla_forma.png")
	_swap_key = _calc_key(root, tr("TROCAR"), tr("Troca as notas selecionadas por outras. Gasta uma troca."), Rect2(1162, 326, 72, 62), _on_swap_pressed, true, "tecla_subtracao.png")
	_pay_key = _calc_key(root, tr("PAGAR"), tr("Paga a conta com as notas selecionadas."), Rect2(1162, 410, 72, 62), _on_pay_pressed, true, "tecla_soma.png")


## Dentro da janela da tela: cabeçalho (mês e tipo), saldo, mensagens, chefe e a linha de dias e trocas.
func _build_screen_content(root: Control) -> void:
	_screen = Control.new()
	_screen.position = SCREEN.position
	_screen.size = SCREEN.size
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_screen)

	# Cabeçalho sobre o papel creme da arte: mês à esquerda; tipo de boleto à direita, em cima do traço.
	_header = _label(_screen, Rect2(20, 14, 229, 47), 34, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_header.add_theme_font_override("font", _font(FONT_TITLE))
	_bill_label = _label(_screen, Rect2(274, 12, 353, 26), 22, INK, HORIZONTAL_ALIGNMENT_LEFT)
	_bill_label.add_theme_font_override("font", _font(FONT_TITLE))

	# Saldo, dias e trocas: saldo embaixo do traço (direita); dias e trocas na faixa escura de baixo.
	_stats = Control.new()
	_stats.size = SCREEN.size
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_stats)
	_stat_values["saldo"] = _label(_stats, Rect2(274, 40, 353, 22), 22, INK, HORIZONTAL_ALIGNMENT_LEFT)
	_stat_values["dias"] = _label(_stats, Rect2(42, 352, 299, 24), 22, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_stat_values["trocas"] = _label(_stats, Rect2(384, 352, 240, 24), 22, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)

	# Mensagem da jogada, níveis e descrição do chefe: área vazia abaixo dos esquemas.
	_message = _label(_screen, Rect2(24, 240, 500, 30), 26, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_levels = _label(_screen, Rect2(24, 272, 500, 24), 20, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_boss_text = _label(_screen, Rect2(24, 298, 600, 50), 17, TERMINAL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_boss_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# Selo do chefe: fora da tela, no canto superior esquerdo da mesa; só aparece na fatura.
	_boss_art = _texture_rect("", Rect2(60, 60, 110, 110), root)
	_boss_art.visible = false
	_boss_stamp_text = Label.new()
	_boss_stamp_text.size = Vector2(110, 110)
	_boss_stamp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_stamp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_stamp_text.add_theme_font_override("font", _font(FONT_TITLE))
	_boss_stamp_text.add_theme_font_size_override("font_size", 14)
	_boss_stamp_text.add_theme_color_override("font_color", STAMP_INK)
	_boss_stamp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_art.add_child(_boss_stamp_text)

	# Faixa de esquemas: 5 espaços (já desenhados na arte), cada um com tooltip (nome e efeito).
	for i in range(Balance.MAX_SCHEMES):
		var slot := Control.new()
		slot.position = STRIP_POS + Vector2(i * (STRIP_SLOT.x + STRIP_GAP), 0)
		slot.size = STRIP_SLOT
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var empty := Control.new()  # sem desenho: o espaço vazio é o da arte
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
	# O comprovante fica dentro de uma janela que corta o que ainda não saiu da impressora.
	_receipt_clip = Control.new()
	_receipt_clip.position = RECEIPT_POS
	_receipt_clip.size = Vector2(240, 600)
	_receipt_clip.clip_contents = true
	_receipt_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt_clip.visible = false
	root.add_child(_receipt_clip)

	_receipt.size = Vector2(240, 600)
	_receipt_clip.add_child(_receipt)

	# Papel liso por baixo do texto: as linhas pintadas na arte atrapalhavam a leitura.
	var paper := ColorRect.new()
	paper.color = RECEIPT_PAPER
	paper.position = Vector2(28, 56)
	paper.size = Vector2(184, 492)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt.add_child(paper)

	# Cabeçalho do comprovante: escrito sobre a faixa escura da arte.
	_receipt_title = _label(_receipt, Rect2(24, 14, 192, 26), 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_receipt_title.text = tr("COMPROVANTE")

	# Corpo: linhas de texto em colunas (nome à esquerda, valor à direita), separadas por tracejados.
	_receipt_rows = VBoxContainer.new()
	_receipt_rows.position = Vector2(36, 66)
	_receipt_rows.size = Vector2(168, 466)
	_receipt_rows.add_theme_constant_override("separation", 4)
	_receipt_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt.add_child(_receipt_rows)


# --- Camelô ----------------------------------------------------------------

func _build_shop(root: Control) -> void:
	_texture_rect(TEX_SHOP_BG, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)
	# Seu Zé atrás do balcão: desenhado depois do fundo e antes da camada do balcão.
	_ze = Sprite2D.new()
	_ze.texture = _tex(TEX_ZE)
	_ze.hframes = ZE_FRAMES
	_ze.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ze.scale = Vector2.ONE * ZE_SCALE
	_ze.position = ZE_POS
	root.add_child(_ze)
	_texture_rect(TEX_SHOP_FRONT, Rect2(Vector2.ZERO, Vector2(1280, 720)), root)

	# Embaixo à esquerda: a carteira (arte art/camelo/carteira.png). O dinheiro e o cheque especial
	# são escritos sobre os dois papéis, girados no mesmo ângulo deles.
	var wallet_box := Control.new()
	wallet_box.position = WALLET_POS
	wallet_box.size = WALLET_SIZE
	wallet_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wallet_box)
	_texture_rect(TEX_WALLET, Rect2(Vector2.ZERO, WALLET_SIZE), wallet_box)
	_shop_wallet = _wallet_label(WALLET_MONEY_CENTER, WALLET_MONEY_ANGLE, 20)
	wallet_box.add_child(_shop_wallet)
	_shop_cheque = _wallet_label(WALLET_CHEQUE_CENTER, WALLET_CHEQUE_ANGLE, 17)
	wallet_box.add_child(_shop_cheque)

	_shop_message = _shop_label(Rect2(280, 576, 720, 26), 20, false)
	_shop_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_message.add_theme_color_override("font_color", INK)  # sobre o vidro claro do balcão
	root.add_child(_shop_message)

	# Investimentos comprados: na caderneta da direita, só quando o botão INVESTIMENTOS abre.
	_shop_levels_row = VBoxContainer.new()
	_shop_levels_row.position = LEVELS_RECT.position
	_shop_levels_row.size = LEVELS_RECT.size
	_shop_levels_row.add_theme_constant_override("separation", 6)
	_shop_levels_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_levels_row.visible = false
	root.add_child(_shop_levels_row)
	_levels_button = _button(root, tr("INVESTIMENTOS"), LEVELS_BUTTON, _on_levels_button)
	_levels_button.add_theme_font_size_override("font_size", 18)
	_levels_button.visible = true

	# Ofertas: esquemas (cartaz) e investimentos (ícone), cada uma com preço e compra.
	for i in range(Balance.SHOP_OFFERS + Balance.SHOP_INVESTMENT_OFFERS):
		# Cartaz (esquema) e ícone (investimento) centralizados no lugar da oferta.
		var spot: Dictionary = OFFER_SPOTS[i]
		var center: Vector2 = spot["c"]
		var center_x := center.x
		var card := _texture_rect("", Rect2(center - SCHEME_SIZE / 2.0, SCHEME_SIZE), root)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon := _texture_rect("", Rect2(center - ICON_SIZE / 2.0, ICON_SIZE), root)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		# Investimento sem arte ainda: o nome aparece no lugar do desenho.
		var icon_name := _shop_label(Rect2(0, 0, ICON_SIZE.x, ICON_SIZE.y), 22, true)
		icon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_name.add_theme_color_override("font_color", INK)  # sobre o painel claro da esquerda
		icon.add_child(icon_name)
		icon.visible = false
		# Clicar no cartaz ou no ícone escolhe a oferta (ela dá um zoom suave).
		card.pivot_offset = card.size / 2.0
		icon.pivot_offset = icon.size / 2.0
		card.gui_input.connect(_on_offer_gui_input.bind(i))
		icon.gui_input.connect(_on_offer_gui_input.bind(i))
		# Botão pequeno, logo abaixo do cartaz: mostra só o preço; com a oferta escolhida, COMPRAR R$ X.
		# A largura acompanha o texto (ver _fit_buy_button).
		var buy := _button(root, "R$ 0", Rect2(center_x - 60.0, spot["buy_y"], 120, BUY_H), _on_offer_button.bind(i))
		buy.add_theme_font_size_override("font_size", BUY_FONT)
		_shop_offers.append({"card": card, "icon": icon, "icon_name": icon_name, "buy": buy, "cx": center_x, "buy_y": spot["buy_y"]})

	# Esquemas que você já tem: em cima, na faixa do topo; vender pela metade do preço.
	for i in range(Balance.MAX_SCHEMES):
		var x := OWNED_X + i * (OWNED_SIZE.x + OWNED_GAP)
		var thumb := _texture_rect("", Rect2(x, 8, OWNED_SIZE.x, OWNED_SIZE.y), root)
		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.visible = false
		var sell := _button(root, tr("VENDER"), Rect2(x + OWNED_SIZE.x / 2.0 - OWNED_SELL_W / 2.0, 110, OWNED_SELL_W, 20), _on_sell_pressed.bind(i))
		sell.add_theme_font_size_override("font_size", 16)
		_shop_owned.append({"thumb": thumb, "sell": sell})

	# Par centralizado na tela (centro em x = 640): PECHINCHAR 240 px + 16 px de vão + SEGUIR 180 px.
	_haggle_button = _button(root, tr("PECHINCHAR"), Rect2(422, 658, 240, 54), _on_haggle_pressed)
	_leave_button = _button(root, tr("SEGUIR"), Rect2(678, 658, 180, 54), _on_leave_shop_pressed)
	_leave_button.visible = true
	_haggle_button.visible = true
	# Aviso do chefe do mês, na calçada, à direita do SEGUIR. Some depois da fatura (o próximo ainda não saiu).
	_shop_boss = _shop_label(Rect2(868, 656, 190, 58), 14, false)
	_shop_boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_boss.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_boss.add_theme_color_override("font_color", INK)
	_shop_boss.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_shop_boss)

	# Contatos: no painel da esquerda, embaixo do investimento, só no mês (depois do boleto).
	# Só um aparece por vez, então todos usam o mesmo lugar. Mostram o nome curto e o preço.
	for i in range(Balance.CONTACT_ORDER.size()):
		var id: String = Balance.CONTACT_ORDER[i]
		var btn := _button(root, "", Rect2(CONTACT_BUTTON_POS, CONTACT_BUTTON_SIZE), _on_contact_pressed.bind(id))
		btn.add_theme_font_size_override("font_size", 16)
		btn.tooltip_text = _contact_tip(id)
		btn.visible = false
		_contact_buttons[id] = btn


## Cartaz do esquema. Sem arte ainda, o nome aparece num papel no lugar do desenho.
func _set_scheme_art(tr: TextureRect, id: String, font_size: int = 18) -> void:
	tr.texture = _tex("res://art/esquemas/cartaz_%s.png" % id)
	var lbl := tr.get_node_or_null("nome_sem_arte") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "nome_sem_arte"
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", _font(FONT_TITLE))
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_color_override("font_color", INK)
		var paper := StyleBoxFlat.new()
		paper.bg_color = Color("EEE8D7")
		paper.border_color = INK
		paper.set_border_width_all(2)
		lbl.add_theme_stylebox_override("normal", paper)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.add_child(lbl)
	lbl.text = tr(String(Balance.SCHEMES[id]["name"])).to_upper()
	lbl.visible = tr.texture == null


## Botões dos contatos: aparecem só se estão à venda neste mês. Sem dinheiro, ficam apagados.
func _refresh_contacts() -> void:
	for id in _contact_buttons:
		var btn: Button = _contact_buttons[id]
		var offered: bool = run.contact_offer.has(id)
		btn.visible = offered
		if not offered:
			continue
		var price := run.price_of(id)
		btn.text = "%s\nR$ %d" % [tr(Balance.CONTACTS[id]["short"]).to_upper(), price]
		btn.disabled = not run.can_spend(price)


## Texto da dica do contato: nome e o que ele faz.
func _contact_tip(id: String) -> String:
	var info: Dictionary = Balance.CONTACTS[id]
	return "%s\n%s" % [tr(info["name"]), tr(info["desc"])]


func _on_contact_pressed(id: String) -> void:
	if _busy:
		return
	var result := run.buy_contact(id)
	_sfx.play("fita" if result["ok"] else "erro")
	_shop_message.text = "" if result["ok"] else _shop_refusal(result["reason"])
	_refresh()


## Dica da oferta: nome, raridade e descrição.
func _offer_tip(id: String) -> String:
	var info: Dictionary = Balance.INVESTMENTS[id] if Investments.is_investment(id) else Balance.SCHEMES[id]
	return "%s · %s
%s" % [tr(info["name"]), tr(Balance.RARITY_NAMES[info["rarity"]]), tr(info["desc"])]


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
	_selected_offer = -1  # qualquer ação do Camelô (comprar, vender, pechinchar) limpa a escolha
	_shop_wallet.text = "R$ %d" % run.wallet
	_shop_wallet.add_theme_color_override("font_color", WARN if run.wallet < 0 else INK)
	# Cheque especial: mostra o que resta do limite (∞ com o Cheque Sem Fundo).
	_shop_cheque.text = tr("ATÉ ∞") if run.overdraft_unlimited() else tr("ATÉ R$ %d") % run.overdraft_left
	_refresh_shop_levels()
	_refresh_contacts()
	var warn_boss: bool = run.bill_key() != "fatura" and run.month_boss != Boss.NONE
	_shop_boss.visible = warn_boss
	if warn_boss:
		_shop_boss.text = tr("CHEFE DO MÊS: %s") % tr(Balance.BOSSES[run.month_boss]["name"])
		_shop_boss.tooltip_text = _boss_rule(run.month_boss)

	for i in range(_shop_offers.size()):
		var o: Dictionary = _shop_offers[i]
		var has: bool = i < run.shop_offer.size() and str(run.shop_offer[i]) != ""  # "" = já comprada: espaço vazio
		for key in ["card", "icon", "buy"]:
			o[key].visible = has
		if not has:
			continue
		var id: String = run.shop_offer[i]
		var info: Dictionary = Balance.INVESTMENTS[id] if Investments.is_investment(id) else Balance.SCHEMES[id]
		var is_inv := Investments.is_investment(id)
		o["card"].visible = not is_inv
		o["icon"].visible = is_inv
		# Sem nome na tela: ao passar o mouse, só a descrição.
		# Dica: nome (no cabeçalho da dica) e descrição. O nome não aparece na tela da loja.
		if is_inv:
			o["icon"].texture = _tex("res://art/camelo/investimento_%s.png" % id)
			o["icon_name"].text = tr(info["name"])
			o["icon_name"].visible = o["icon"].texture == null
			o["icon"].tooltip_text = _offer_tip(id)
		else:
			_set_scheme_art(o["card"], id)
			o["card"].tooltip_text = _offer_tip(id)
		var price := run.price_of(id)
		var full := not is_inv and run.schemes.size() >= Balance.MAX_SCHEMES
		o["buy"].disabled = full or not run.can_spend(price)
	_update_offer_visuals()

	for i in range(_shop_owned.size()):
		var s: Dictionary = _shop_owned[i]
		var has := i < run.schemes.size()
		s["thumb"].visible = has
		s["sell"].visible = has
		if has:
			var id: String = run.schemes[i]
			var info: Dictionary = Balance.SCHEMES[id]
			_set_scheme_art(s["thumb"], id, 11)
			s["thumb"].tooltip_text = _offer_tip(id)
			s["sell"].text = tr("VENDER R$ %d") % (int(info["price"]) / 2)

	_haggle_button.text = tr("PECHINCHAR R$ %d") % Balance.HAGGLE_COST
	_haggle_button.disabled = not run.can_spend(Balance.HAGGLE_COST)


## Texto escrito sobre um papel da carteira: caixa centrada no papel e girada no ângulo dele.
func _wallet_label(center: Vector2, angle: float, font_size: int) -> Label:
	var label := Label.new()
	label.size = WALLET_TEXT_BOX
	label.pivot_offset = WALLET_TEXT_BOX / 2.0
	label.position = center - WALLET_TEXT_BOX / 2.0
	label.rotation = angle
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font(FONT_TITLE))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Plaquinha de papel com texto (níveis). Devolve o painel; o texto é o filho.
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
		_shop_levels_row.remove_child(child)
		child.queue_free()
	for kind in Balance.TRANSACTIONS:
		var lvl: int = run.levels.get(kind, 0)
		if lvl <= 0:
			continue
		var chip := _chip(14, BUTTON_PAPER_DOWN)
		_chip_label(chip).text = "%s x%d" % [tr(Balance.TRANSACTIONS[kind]["name"]).to_upper(), lvl]
		_chip_label(chip).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_shop_levels_row.add_child(chip)
	# Caderneta vazia: uma linha no lugar da lista.
	if _shop_levels_row.get_child_count() == 0:
		var none := _shop_label(Rect2(0, 0, LEVELS_RECT.size.x, 60), 16, false)
		none.text = tr("nenhum investimento ainda")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.add_theme_color_override("font_color", INK)
		_shop_levels_row.add_child(none)
	_shop_levels_row.visible = _levels_open


## Botão INVESTIMENTOS: abre e fecha a lista na caderneta da direita.
func _on_levels_button() -> void:
	_levels_open = not _levels_open
	_sfx.play("bipe_tecla")
	_shop_levels_row.visible = _levels_open


## Seu Zé: fica parado em laço e, de tempos em tempos, acena, faz joinha ou ri.
func _process(delta: float) -> void:
	if _ze == null or not _shop_root.visible:
		return
	if _ze_range == ZE_IDLE:
		_ze_wait -= delta
	_ze_frame_time += delta
	if _ze_frame_time < float(ZE_DURATIONS[_ze.frame]):
		return
	_ze_frame_time = 0.0
	if _ze.frame < int(_ze_range[1]):
		_ze.frame += 1
		return
	# Fim do trecho: volta ao laço parado, ou começa uma animação quando a espera acaba.
	if _ze_range == ZE_IDLE and _ze_wait <= 0.0:
		_ze_range = ZE_ACTIONS[randi_range(0, ZE_ACTIONS.size() - 1)]
	else:
		if _ze_range != ZE_IDLE:
			_ze_wait = randf_range(ZE_WAIT[0], ZE_WAIT[1])
		_ze_range = ZE_IDLE
	_ze.frame = int(_ze_range[0])


## Níveis atuais dos investimentos, em nomes de transação (ex.: "Dobradinha 1 · Escadinha 0").
func _levels_text() -> String:
	var parts: Array = []
	for kind in Balance.TRANSACTIONS:
		var lvl: int = run.levels.get(kind, 0)
		if lvl > 0:
			parts.append("%s %d" % [tr(Balance.TRANSACTIONS[kind]["name"]), lvl])
	return tr("nenhum investimento ainda") if parts.is_empty() else " · ".join(parts)


## Clique no cartaz ou no ícone: escolhe a oferta (só uma por vez).
func _on_offer_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Clicar de novo na oferta escolhida tira a seleção.
		_select_offer(-1 if index == _selected_offer else index)


## Botão da oferta: se ela não está escolhida, escolhe; se já está, compra.
func _on_offer_button(index: int) -> void:
	if _busy:
		return
	if _selected_offer != index:
		_select_offer(index)
		return
	_on_buy_pressed(index)


func _select_offer(index: int) -> void:
	_selected_offer = index
	_sfx.play("bipe_tecla")
	_update_offer_visuals()


## Zoom e texto do botão: a oferta escolhida cresce suavemente; as outras voltam ao tamanho normal.
## O botão mostra só o preço; a escolhida mostra COMPRAR R$ X.
func _update_offer_visuals() -> void:
	for i in range(_shop_offers.size()):
		var o: Dictionary = _shop_offers[i]
		var has: bool = i < run.shop_offer.size() and str(run.shop_offer[i]) != ""  # "" = já comprada: espaço vazio
		var selected: bool = has and i == _selected_offer
		if not has:
			continue
		var id: String = run.shop_offer[i]
		var is_inv := Investments.is_investment(id)
		var node: Control = o["icon"] if is_inv else o["card"]
		var other: Control = o["card"] if is_inv else o["icon"]
		_zoom(other, Vector2.ONE)
		_zoom(node, Vector2.ONE * OFFER_ZOOM if selected else Vector2.ONE)
		var price := run.price_of(id)
		o["buy"].text = (tr("COMPRAR R$ %d") if selected else "R$ %d") % price
		_style_buy_button(o["buy"], selected)
		_fit_buy_button(o)


## Botão de compra com a arte da caixa do valor; a oferta escolhida usa a versão destacada (amarela).
func _style_buy_button(btn: Button, selected: bool) -> void:
	# Creme normal; a oferta escolhida fica amarela (arte botao_amarelo).
	_skin_button(btn, "botao_amarelo" if selected else "botao_creme")
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", DIM)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.modulate = Color(1, 1, 1, 0.55) if btn.disabled else Color.WHITE


## Largura do botão de compra segue o texto (fica mais largo com "COMPRAR R$ X"), centrado na placa.
func _fit_buy_button(o: Dictionary) -> void:
	var btn: Button = o["buy"]
	var font := btn.get_theme_font("font")
	var text_w := font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, BUY_FONT).x
	var w := maxf(BUY_MIN_W, text_w + BUY_PAD)
	btn.size = Vector2(w, BUY_H)
	btn.position = Vector2(float(o["cx"]) - w / 2.0, float(o["buy_y"]))


## Animação de zoom com retorno elástico; cancela a animação anterior do mesmo item.
func _zoom(node: Control, target: Vector2) -> void:
	if node.scale.is_equal_approx(target) and not node.has_meta("zooming"):
		return
	if node.has_meta("tween"):
		var old: Tween = node.get_meta("tween")
		if old != null and old.is_valid():
			old.kill()
	var tween := node.create_tween()
	node.set_meta("tween", tween)
	node.set_meta("zooming", true)
	tween.tween_property(node, "scale", target, OFFER_ZOOM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void: node.set_meta("zooming", false))


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
			return tr("Sem dinheiro, nem no cheque especial")
		"slots_full":
			return tr("Você já tem %d esquemas. Venda um antes") % Balance.MAX_SCHEMES
	return ""


# --- Fluxo -----------------------------------------------------------------

func _on_title_pressed() -> void:
	_title_screen.visible = false
	_start_run()


func _on_howto_pressed() -> void:
	_show_tutorial(0)
	_howto.visible = true


func _start_run() -> void:
	run = RunState.new()
	_message.text = tr("INSIRA SUAS NOTAS")
	_boss_stamp_key = ""
	_end_stamp_played = false
	_shop_message.text = ""
	_restart_button.visible = false
	_refresh()


func _on_continue_pressed() -> void:
	var saved := SaveGame.read()
	if saved == null:
		_title_screen.set_has_save(false)  # save inválido: o botão deixa de funcionar
		return
	_title_screen.visible = false
	_load_run(saved)


## Retoma uma partida salva. Carimbo da fatura atual não toca de novo; o comprovante fica inteiro.
func _load_run(loaded: RunState) -> void:
	run = loaded
	_message.text = ""
	_boss_stamp_key = "%d-%d" % [run.month_index, run.bill_index]
	_end_stamp_played = false
	_shop_message.text = ""
	_restart_button.visible = false
	_receipt_clip.size = Vector2(240, 600)
	_refresh()


func _toggle_menu() -> void:
	if _title_screen.visible or _howto.visible or _busy:
		return
	if _menu_root.visible:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	_menu_root.visible = true
	_menu_status.text = ""
	_menu_save.disabled = run.state == RunState.WON or run.state == RunState.LOST
	_menu_status.text = tr("Partida terminada não pode ser salva.") if _menu_save.disabled else ""


func _close_menu() -> void:
	_menu_root.visible = false
	_restart_armed = false
	_menu_restart.text = tr("RECOMEÇAR")
	_menu_back.text = tr("VOLTAR AO MENU")
	_back_armed = false
	_menu_status.text = ""


func _on_save_pressed() -> void:
	if SaveGame.write(run):
		_menu_status.text = tr("Partida salva.")
	else:
		_menu_status.text = tr("Não consegui salvar. Tente de novo.")


## Opções dentro da partida. Se o idioma mudou, salva a partida e recarrega a cena (os textos mudam).
func _on_pause_options() -> void:
	OptionsScreen.open(self, _on_game_options_closed)


func _on_game_options_closed(language_changed: bool) -> void:
	if not language_changed:
		return
	var playing := run != null and run.state != RunState.WON and run.state != RunState.LOST
	if playing and not SaveGame.write(run):
		_menu_status.text = tr("Não consegui salvar. Tente de novo.")
		return
	get_tree().reload_current_scene()


## Volta à tela inicial. Pede confirmação, porque a partida não salva se perde.
func _on_back_pressed() -> void:
	if not _back_armed:
		_back_armed = true
		_menu_back.text = tr("TEM CERTEZA?")
		_menu_status.text = tr("O progresso não salvo se perde.")
		return
	_close_menu()
	_title_screen.set_has_save(SaveGame.exists())
	_title_screen.visible = true


## Primeiro clique pede confirmação; o segundo recomeça (o último save não é apagado).
func _on_restart_pressed() -> void:
	if not _restart_armed:
		_restart_armed = true
		_menu_restart.text = tr("TEM CERTEZA?")
		_menu_status.text = tr("O progresso não salvo se perde.")
		return
	_close_menu()
	_start_run()


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
	_sync_status_panel()


## Textos, saldo, teclas, faixa e carimbos. Não mexe na mão (para a animação de seleção não ser interrompida).
func _update_status() -> void:
	var bill := run.bill
	var playing := run.state == RunState.PLAYING
	var over := run.state == RunState.WON or run.state == RunState.LOST
	var paid := run.state == RunState.BILL_PAID
	var won := run.state == RunState.WON

	_header.text = run.month_name()
	_bill_label.text = tr(Balance.BILL_LABELS[run.bill_key()])
	_set_stat("carteira", "R$ %d" % run.wallet, DANGER_LCD if run.wallet < 0 else LCD_INK)
	_set_stat("meta", "R$ %d" % bill.goal, INK)
	_set_stat("saldo", "R$ %d" % bill.saldo, INK)
	_set_stat("dias", str(bill.days_left), TERMINAL_TEXT)
	_set_stat("trocas", str(bill.swaps_left), TERMINAL_TEXT)

	var boss_id := run.boss_id()
	# Com o comprovante por cima, a tela mostra só a mensagem (o comprovante já traz os números).
	var show_boss := not paid and not over and boss_id != Boss.NONE
	_boss_text.visible = show_boss
	_boss_art.visible = show_boss
	if boss_id != Boss.NONE:
		_boss_text.text = _boss_line(boss_id)
		# Chefe sem arte ainda: o selo fica só com o texto escrito por cima.
		_boss_art.texture = _tex(BOSS_ART.get(boss_id, ""))
		_boss_stamp_text.text = tr(BOSS_STAMP[boss_id]) if BOSS_STAMP.has(boss_id) else tr(Balance.BOSSES[boss_id]["name"]).to_upper()

	var levels_text := _levels_text()
	_levels.text = tr("Níveis: ") + levels_text
	_levels.visible = not paid and not won and levels_text != tr("nenhum investimento ainda")
	_set_key_enabled(_pay_key, playing)
	_set_key_enabled(_swap_key, playing)
	_set_key_enabled(_sort_key, playing)
	_set_key_enabled(_sort_value_key, playing)
	_hand_area.visible = playing
	_restart_button.visible = over
	# Vitória: o comprovante final ocupa o meio da tela, e o botão de jogar de novo vai para baixo dele.
	_restart_button.position = Vector2(RECEIPT_POS.x + 120 - 120, 664) if won else Vector2(540, 528)
	_restart_button.size = Vector2(240, 52) if won else Vector2(200, 56)
	_next_button.visible = paid
	_endless_button.visible = run.can_continue()
	_receipt_clip.visible = paid or won
	_header.visible = not (paid or won)
	_bill_label.visible = not (paid or won)
	_stats.visible = not (paid or won)
	_message.visible = not won
	_end_stamp.visible = over and not won
	# Carimbos: a fatura com chefe e o fim da partida batem uma vez cada.
	var stamp_key := "%d-%d" % [run.month_index, run.bill_index]
	if show_boss and _boss_stamp_key != stamp_key:
		_boss_stamp_key = stamp_key
		_sfx.play("carimbo")
	if over and not _end_stamp_played:
		_end_stamp_played = true
		_sfx.play("carimbo")
	if over:
		SaveGame.delete()  # partida terminada não tem o que continuar
		_end_stamp.texture = _tex(TEX_END_OK if run.state == RunState.WON else TEX_END_BAD)

	_update_strip()

	if run.state == RunState.WON:
		_message.text = tr("CONTAS EM DIA   ·   Saldo máximo R$ %d") % run.max_saldo
		_receipt_title.text = tr("COMPROVANTE FINAL")
		_fill_receipt(_final_receipt_lines())
	elif run.state == RunState.LOST:
		_message.text = tr("CHEQUE ESPECIAL ESGOTADO") if run.end_reason == "cheque" else tr("NOME NEGATIVADO")
	elif paid:
		_message.text = tr("CONTA PAGA")
		_receipt_title.text = tr("COMPROVANTE")
		_fill_receipt(_receipt_lines())


## Regra do chefe, já com o número do nível deste mês (dificuldade adaptativa).
func _boss_rule(boss_id: String) -> String:
	var text := tr(Balance.BOSSES[boss_id]["text"])
	if Balance.BOSS_SCALE.has(boss_id):
		return text % Boss.level_value(boss_id, run.boss_level())
	return text


## Linha do chefe na tela: nome, regra, e o resultado do chefe nesta conta (Urubu, matrícula, Valor do Curso).
func _boss_line(boss_id: String) -> String:
	var line := tr("CHEFE: %s. %s") % [tr(Balance.BOSSES[boss_id]["name"]), _boss_rule(boss_id)]
	if run.boss_note != "":
		line += "   " + run.boss_note
	if run.valor_percent() > 0:
		line += tr("   Valor +%d%%.") % run.valor_percent()
	return line


## Faixa de esquemas dentro da tela: uma carta por esquema ativo.
func _update_strip() -> void:
	for i in range(_strip_slots.size()):
		var s: Dictionary = _strip_slots[i]
		var has := i < run.schemes.size()
		s["empty"].visible = not has
		s["card"].visible = has
		if has:
			var id: String = run.schemes[i]
			_set_scheme_art(s["card"], id, 14)
			s["slot"].tooltip_text = _offer_tip(id)
		else:
			s["slot"].tooltip_text = ""


## Recria a mão (ao comprar, trocar ou pagar). Cada carta fica num wrapper com espaço para subir.
func _rebuild_hand() -> void:
	for child in _hand_box.get_children():
		child.queue_free()
	_cards.clear()

	var playing := run.state == RunState.PLAYING
	for note in _hand_order():
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


## Ordem de exibição da mão. Só muda a tela: a regra (quais notas estão na mão) não muda.
func _hand_order() -> Array:
	var notes: Array = run.bill.hand.duplicate()
	match _sort_mode:
		SORT_SUIT:
			notes.sort_custom(func(a: Note, b: Note) -> bool:
				if a.suit != b.suit:
					return a.suit < b.suit
				return a.value < b.value)
		SORT_VALUE:
			notes.sort_custom(func(a: Note, b: Note) -> bool:
				if a.value != b.value:
					return a.value < b.value
				return a.suit < b.suit)
	return notes


func _on_sort_suit_pressed() -> void:
	_set_sort_mode(SORT_NORMAL if _sort_mode == SORT_SUIT else SORT_SUIT)


func _on_sort_value_pressed() -> void:
	_set_sort_mode(SORT_NORMAL if _sort_mode == SORT_VALUE else SORT_VALUE)


func _set_sort_mode(mode: String) -> void:
	if _busy or run.state != RunState.PLAYING:
		return
	_sort_mode = mode
	match mode:
		SORT_SUIT:
			_message.text = tr("Mão organizada por forma de pagamento")
		SORT_VALUE:
			_message.text = tr("Mão organizada por valor")
		_:
			_message.text = tr("Mão na ordem normal")
	_rebuild_hand()


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
		_add_stamp(card, note)
		# Moldura de cantoneira: cinza-claro ao passar o mouse, amarela quando a carta está selecionada.
		var frame := Panel.new()
		frame.position = Vector2(-6, -6)
		frame.size = CARD_SIZE + Vector2(12, 12)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.visible = false
		card.add_child(frame)
		card.set_meta("frame", frame)
		# Só a moldura de hover; a carta selecionada fica apenas levantada (sem moldura amarela).
		card.mouse_entered.connect(func() -> void: _set_card_frame(card, 1))
		card.mouse_exited.connect(func() -> void: _set_card_frame(card, 0))
		return card

	var btn := Button.new()
	btn.toggle_mode = true
	btn.text = "R$ %d\n%s" % [note.value, note.suit_name()]
	return btn


## Selo da forma de pagamento por cima da cédula neutra (sem bloquear o clique na carta).
func _add_stamp(card: Control, note: Note) -> void:
	# Pix: selo provisório desenhado em código (ainda sem arte); troque por selo_pix.png quando houver.
	if note.suit == Note.Suit.PIX:
		_add_pix_stamp(card)
		return
	var path := note.stamp_path()
	if not ResourceLoader.exists(path):
		return
	var stamp := TextureRect.new()
	stamp.texture = load(path)
	stamp.position = STAMP_POS
	stamp.size = STAMP_SIZE
	stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stamp)


## Selo provisório do Pix: círculo verde-água com a palavra PIX (até existir a arte do selo).
func _add_pix_stamp(card: Control) -> void:
	var stamp := Panel.new()
	stamp.position = STAMP_POS
	stamp.size = STAMP_SIZE
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circle := StyleBoxFlat.new()
	circle.bg_color = Color("1F8A7A")
	circle.border_color = INK
	circle.set_border_width_all(2)
	circle.set_corner_radius_all(int(STAMP_SIZE.x / 2.0))
	stamp.add_theme_stylebox_override("panel", circle)
	card.add_child(stamp)
	var word := Label.new()
	word.text = "PIX"
	word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.add_theme_font_override("font", _font(FONT_TITLE))
	word.add_theme_font_size_override("font_size", 15)
	word.add_theme_color_override("font_color", Color("F4EDD9"))
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_child(word)


## Posição da carta dentro do wrapper: selecionada fica no topo, as outras descem LIFT px.
func _lifted_position(selected: bool) -> Vector2:
	return Vector2(0, 0 if selected else LIFT)


## Moldura de uma carta: 0 = sem moldura, 1 = ao passar o mouse, 2 = selecionada.
func _set_card_frame(btn: BaseButton, mode: int) -> void:
	if not btn.has_meta("frame"):
		return
	var frame: Panel = btn.get_meta("frame")
	frame.visible = mode != 0
	if mode == 2:
		frame.add_theme_stylebox_override("panel", _nine("ui_selecao", 22, 24, 22, 24))
	elif mode == 1:
		frame.add_theme_stylebox_override("panel", _nine("ui_selecao_hover", 22, 24, 22, 24))


## Sobe ou desce uma carta com animação curta.
func _lift(btn: BaseButton, selected: bool) -> void:
	btn.button_pressed = selected
	var tween := create_tween()
	tween.tween_property(btn, "position", _lifted_position(selected), LIFT_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Comprovante final (pagou a última fatura de Janeiro): CONTAS EM DIA e o saldo máximo do ano.
## Linhas do comprovante final. Cada linha: [texto à esquerda, valor à direita, estilo].
func _final_receipt_lines() -> Array:
	var months: int = Balance.TOTAL_MONTHS if run.endless else Balance.RUN_MONTHS
	var total := months * Balance.BILL_KEYS.size()
	return [
		[tr("TODOS OS CHEFES DERROTADOS") if run.endless else tr("CONTAS EM DIA"), "", "titulo"],
		["", "", "tracejado"],
		[tr("Contas pagas"), "%d de %d" % [run.bills_paid(), total], ""],
		[tr("Saldo máximo"), "R$ %d" % run.max_saldo, ""],
		["", "", "tracejado"],
		[tr("CARTEIRA"), "R$ %d" % run.wallet, "total"],
	]


## Linhas do comprovante de uma conta paga: a carteira mostra cada passo até o total.
func _receipt_lines() -> Array:
	var r := run.receipt
	# Saves antigos não guardam a carteira de antes: ela é reconstruída a partir do total.
	var before: int = int(r.get("wallet_before", int(r["wallet"]) - int(r["reward"]) - int(r["troco"])))
	var lines: Array = [
		[str(r["title"]), "", "titulo"],
		["", "", "tracejado"],
		[tr("Saldo da conta"), "R$ %d" % int(r["saldo"]), ""],
		[tr("Meta"), "R$ %d" % int(r["goal"]), ""],
		[tr("Dias sobrando"), str(int(r.get("days_left", 0))), ""],
		["", "", "tracejado"],
		[tr("Carteira antes"), "R$ %d" % before, ""],
	]
	if int(r.get("growth", 0)) > 0:
		lines.append([tr("Juros da dívida"), "−R$ %d" % int(r["growth"]), "perda"])
	lines.append([tr("Recompensa"), "+R$ %d" % int(r["reward"]), "ganho"])
	lines.append([tr("Troco"), "+R$ %d" % int(r["troco"]), "ganho"])
	if int(r.get("agiota", 0)) > 0:
		lines.append([tr("Agiota (10%)"), "−R$ %d" % int(r["agiota"]), "perda"])
	if int(r.get("parcelas", 0)) > 0:
		lines.append([tr("Parcelas dos esquemas"), "−R$ %d" % int(r["parcelas"]), "perda"])
	lines.append(["", "", "tracejado"])
	lines.append([tr("CARTEIRA"), "R$ %d" % int(r["wallet"]), "total"])
	return lines


## Monta as linhas do comprovante na tela. Estilos: titulo, tracejado, ganho, perda, total.
func _fill_receipt(lines: Array) -> void:
	for child in _receipt_rows.get_children():
		_receipt_rows.remove_child(child)
		child.queue_free()
	for line in lines:
		var style: String = line[2]
		if style == "tracejado":
			var dashes := Label.new()
			dashes.text = "- - - - - - - - - - - - - - - - -"
			dashes.add_theme_font_size_override("font_size", 14)
			dashes.add_theme_color_override("font_color", DIM)
			dashes.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_receipt_rows.add_child(dashes)
			continue
		if style == "titulo":
			var title := Label.new()
			title.text = line[0]
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_font_size_override("font_size", 22)
			title.add_theme_color_override("font_color", INK)
			title.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_receipt_rows.add_child(title)
			continue
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := 30 if style == "total" else 20
		var color := INK
		if style == "ganho":
			color = LCD_INK
		elif style == "perda":
			color = DANGER_LCD
		elif style == "total":
			color = DANGER_LCD if line[1].begins_with("R$ -") else LCD_INK
		var left := _receipt_text_label(line[0], size, color, HORIZONTAL_ALIGNMENT_LEFT)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		row.add_child(_receipt_text_label(line[1], size, color, HORIZONTAL_ALIGNMENT_RIGHT))
		_receipt_rows.add_child(row)


func _receipt_text_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _on_card_pressed(note: Note) -> void:
	if _busy:
		return
	run.bill.toggle_select(note)
	_sfx.play("bipe_tecla")
	var selected: bool = run.bill.selected.has(note)
	if _cards.has(note):
		_lift(_cards[note], selected)
	_update_status()
	_message.text = _formation_text()


## Combinação que as notas escolhidas formam, mostrada antes de pagar (só informa; não pontua).
## Usa as mesmas regras do PAGAR: notas que o chefe não deixa pontuar ficam de fora.
func _formation_text() -> String:
	if run.bill.selected.is_empty():
		return tr("INSIRA SUAS NOTAS")
	if Boss.hides_preview(run.bill.boss):
		return tr("APAGÃO: sem prévia da jogada")
	var score: Dictionary = run.bill.preview(run.bill.selected)
	if score.is_empty():
		return tr("Nenhuma nota pontua nesta jogada")
	# Mesma linha da contagem: Valor, Juros e cartaz da formação, com o Leão se houver.
	var value: int = score["base"] + score["points"]
	var mult := 1
	for ev in score["events"]:
		match ev["type"]:
			"invest", "boss":
				value += ev["value"]
			"scheme":
				value += ev["value"]
				mult *= ev["mult"]
	var line := _playback_line(tr(Balance.TRANSACTIONS[score["kind"]]["name"]), value, score["juros"], mult)
	if score["tax"] > 0:
		line += tr("   ·   LEÃO -%d") % score["tax"]
	return line


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
	await _raise_played(played)
	_message.text = tr("AGUARDE… PROCESSANDO")
	await get_tree().create_timer(PROCESSING_TIME).timeout
	await _play_score(score)
	await _drop_played(played)
	_busy = false
	_refresh()
	if run.state == RunState.BILL_PAID:
		_print_receipt(run.bill.saldo > run.bill.goal * BIG_RECEIPT_RATIO)
	elif run.state == RunState.WON:
		_print_receipt(false)  # comprovante final: CONTAS EM DIA


## Percorre a lista de eventos do Scorer: notas pulam, cartaz balança, Juros aparece, total cai no saldo.
func _play_score(score: Dictionary) -> void:
	var tx_name: String = tr(Balance.TRANSACTIONS[score["kind"]]["name"])
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
				_impact_card(ev.get("card"))
				_pop_points(ev["amount"], ev.get("card"))
				# Bipe que sobe em 5 alturas, uma por nota.
				_sfx.play("bipe_subindo", 1.0 + 0.125 * (note_index % 5))
				note_index += 1
			"invest":
				value += ev["value"]
				juros += ev["add"]
			"boss":
				value += ev["value"]  # Valor do Curso do Primo Rico
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

	_message.text = tr("%s   ·   TOTAL +%d") % [tx_name, total]
	if tax > 0:
		_message.text += tr("   (Leão da Receita: -%d)") % tax
	_shake(clampf(float(total) / maxf(1.0, run.bill.goal) * 4.0, 0.0, SHAKE_MAX))
	if total > run.bill.goal * BIG_RECEIPT_RATIO:
		_sfx.play("plateia")
	await _count_saldo(run.bill.saldo - (total - tax), run.bill.saldo)


func _playback_line(tx_name: String, value: int, juros: int, mult: int) -> String:
	var line := tr("%s   ·   VALOR %d   ·   JUROS x%d") % [tx_name, value, juros]
	if mult > 1:
		line += tr("   ·   CARTAZ x%d") % mult
	return line


## As cartas jogadas sobem acima da mão e ficam lá durante a contagem.
func _raise_played(played: Array) -> void:
	var tween := create_tween().set_parallel(true)
	var raised := 0
	for note in played:
		if not _cards.has(note):
			continue
		var btn: BaseButton = _cards[note]
		tween.tween_property(btn, "position", Vector2(0, -PLAYED_RAISE), RAISE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		raised += 1
	if raised > 0:
		await tween.finished


## Depois da contagem, as cartas jogadas descem para fora da tela.
func _drop_played(played: Array) -> void:
	var tween := create_tween().set_parallel(true)
	var i := 0
	for note in played:
		if not _cards.has(note):
			continue
		var btn: BaseButton = _cards[note]
		var delay := i * 0.05
		i += 1
		tween.tween_property(btn, "position:y", btn.position.y + DROP_DISTANCE, DROP_TIME) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if i > 0:
		await tween.finished


## Impacto de uma carta que pontua: estufa, pisca de luz e a tela treme de leve.
func _impact_card(note: Note) -> void:
	if note == null or not _cards.has(note):
		return
	var btn: BaseButton = _cards[note]
	btn.pivot_offset = btn.size / 2.0
	var punch := create_tween()
	punch.tween_property(btn, "scale", Vector2(1.18, 1.18), IMPACT_UP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.tween_property(btn, "scale", Vector2.ONE, IMPACT_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var flash := create_tween()
	flash.tween_property(btn, "modulate", IMPACT_FLASH, IMPACT_UP)
	flash.tween_property(btn, "modulate", Color.WHITE, IMPACT_DOWN)
	_shake(IMPACT_SHAKE)


## Pontuação de uma nota: aparece logo acima da própria carta (e sobe um pouco, enquanto some).
func _pop_points(points: int, note: Note) -> void:
	if note == null or not _cards.has(note):
		return
	var btn: BaseButton = _cards[note]
	var label := _terminal_label(40)
	label.text = "+%d" % points
	label.add_theme_color_override("font_color", HIGHLIGHT)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(CARD_SIZE.x / 2.0 - 30.0, -POINTS_RISE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", -POINTS_RISE - 26.0, 0.6)
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
	tween.tween_method(func(v: float) -> void: _set_stat("saldo", "R$ %d" % int(v), INK), float(from), float(to), 0.5)
	await tween.finished


## Tremor da tela: `strength` é o deslocamento máximo em px.
func _shake(strength: float) -> void:
	if strength <= 0.0 or not Settings.screen_shake:
		return
	var tween := create_tween()
	var step_time := SHAKE_TIME / SHAKE_STEPS
	for i in range(SHAKE_STEPS):
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(_game_root, "position", offset, step_time)
	tween.tween_property(_game_root, "position", Vector2.ZERO, step_time)


## Comprovante sai da impressora (aparece de cima para baixo); acima de 5× a meta ele chega gigante e treme.
func _print_receipt(big: bool) -> void:
	_sfx.play("impressora")
	if int(run.receipt.get("reward", 0)) > 0:
		get_tree().create_timer(PRINT_TIME * 0.5).timeout.connect(_sfx.play.bind("moedas"))
	if int(run.receipt.get("troco", 0)) > 0:
		get_tree().create_timer(PRINT_TIME * 0.9).timeout.connect(_sfx.play.bind("relampago"))
	# Papel sai da impressora: a janela cresce de cima para baixo, no ritmo do som.
	_receipt_clip.position = RECEIPT_POS
	_receipt_clip.pivot_offset = Vector2(120, 300)
	_receipt_clip.size = Vector2(240, 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_receipt_clip, "size:y", 600.0, PRINT_TIME).set_trans(Tween.TRANS_LINEAR)
	if big:
		_receipt_clip.scale = Vector2(BIG_RECEIPT_SCALE, BIG_RECEIPT_SCALE)
		tween.tween_property(_receipt_clip, "scale", Vector2.ONE, PRINT_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_shake.bind(SHAKE_MAX))
	else:
		_receipt_clip.scale = Vector2.ONE


func _set_stat(key: String, value: String, color: Color) -> void:
	_stat_values[key].text = tr(STAT_FORMAT[key]) % value
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
	_message.text = ""
	_refresh()


## Modo infinito: a partida vencida segue do Camelô, até perder ou derrotar todos os chefes.
func _on_endless_pressed() -> void:
	if not run.continue_endless():
		return
	_end_stamp_played = false
	_on_next_pressed()


func _refusal_text(reason: String) -> String:
	match reason:
		"no_selection":
			return tr("Escolha de 1 a 5 notas")
		"no_swaps":
			return tr("Sem trocas sobrando")
		"no_money":
			return tr("Sem dinheiro nem no cheque especial")
		"round_over", "run_not_playing":
			return tr("Esta conta já acabou")
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
	# Dica: papelão com fita da arte ui_tooltip. O cabeçalho da arte (30 px) fica em cima; o texto começa abaixo dele.
	var tip := _nine("ui_tooltip", 10, 16, 30, 16)
	tip.content_margin_left = 16
	tip.content_margin_right = 16
	tip.content_margin_top = 4      # o nome cai no cabeçalho da arte; a descrição logo abaixo
	tip.content_margin_bottom = 12
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font("font", "TooltipLabel", _font(FONT_TERMINAL))
	t.set_font_size("font_size", "TooltipLabel", 22)
	# Nome e descrição (separados por \n): a fonte VT323 tem entrelinha alta; apertar um pouco.
	t.set_constant("line_spacing", "TooltipLabel", 6)
	return t


## Caixa desenhada a partir de uma arte de art/ui (9-slice): cantos fixos, centro estica.
## left/right/top/bottom são as margens da arte em px.
func _nine(file: String, left: int, right: int, top: int, bottom: int) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _tex("res://art/ui/%s.png" % file)
	sb.texture_margin_left = left
	sb.texture_margin_right = right
	sb.texture_margin_top = top
	sb.texture_margin_bottom = bottom
	return sb


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


## Papel de caderno de fundo do tutorial (desenhado em código: pauta fina, margem e furos).
func _draw_paper(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("EEE8D7"))
	var line := Color(0.55, 0.65, 0.75, 0.22)
	for y in range(0, 720, 24):
		c.draw_line(Vector2(0, y), Vector2(1280, y), line)
	c.draw_line(Vector2(96, 0), Vector2(96, 720), Color(0.85, 0.45, 0.45, 0.5), 2.0)
	for y in range(40, 720, 64):
		c.draw_circle(Vector2(40, y), 9.0, Color(0.66, 0.63, 0.55))


## Mostra a página `index` do tutorial (0 a N-1), com botões de navegação.
func _show_tutorial(index: int) -> void:
	_tut_index = clampi(index, 0, TUTORIAL_PAGES.size() - 1)
	if _tut_body != null:
		_tut_body.queue_free()
	_tut_body = Control.new()
	_tut_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tut_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_howto.add_child(_tut_body)

	var page: Dictionary = TUTORIAL_PAGES[_tut_index]
	_tut_body.add_child(_hand_label(Rect2(0, 36, 1280, 50), tr("COMO JOGAR"), 30, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))
	_tut_body.add_child(_hand_label(Rect2(150, 90, 980, 66), tr(page["title"]), 52, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))
	_tut_body.add_child(_hand_label(Rect2(170, 165, 940, 170), tr(page["body"]), 26, HAND_INK, HORIZONTAL_ALIGNMENT_LEFT))

	match str(page.get("example", "")):
		"suits":
			_tut_cards([Note.new(10, Note.Suit.DINHEIRO), Note.new(10, Note.Suit.PIX), Note.new(20, Note.Suit.DEBITO), Note.new(50, Note.Suit.CREDITO)], 370.0)
			_tut_body.add_child(_hand_label(Rect2(0, 570, 1280, 40), tr("Dinheiro · Pix · Débito · Crédito"), 22, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))
		"table":
			_tut_table(345.0)
		"formula":
			_tut_cards([Note.new(10, Note.Suit.DINHEIRO), Note.new(10, Note.Suit.DEBITO)], 370.0)
			_tut_body.add_child(_hand_label(Rect2(0, 570, 1280, 50), tr("Dobradinha: (10 base + 6 + 6 pontos) × 2 de Juros = 44"), 26, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))

	var last := _tut_index == TUTORIAL_PAGES.size() - 1
	var prev := _tut_button(tr("ANTERIOR"), Rect2(120, 640, 220, 52), func() -> void: _show_tutorial(_tut_index - 1))
	prev.disabled = _tut_index == 0
	_tut_body.add_child(_hand_label(Rect2(480, 644, 320, 44), "%d / %d" % [_tut_index + 1, TUTORIAL_PAGES.size()], 26, HAND_INK, HORIZONTAL_ALIGNMENT_CENTER))
	if last:
		_tut_button(tr("CONCLUIR"), Rect2(940, 640, 220, 52), _close_tutorial)
	else:
		_tut_button(tr("PRÓXIMO"), Rect2(940, 640, 220, 52), func() -> void: _show_tutorial(_tut_index + 1))
	_tut_button(tr("FECHAR"), Rect2(1040, 20, 200, 48), _close_tutorial)


## Botão do tutorial (o _button vem escondido por padrão).
func _tut_button(text: String, rect: Rect2, handler: Callable) -> Button:
	var btn := _button(_tut_body, text, rect, handler)
	btn.visible = true
	return btn


func _close_tutorial() -> void:
	_howto.visible = false


## Cédulas de exemplo (arte real da nota, com o selo da forma de pagamento), centralizadas na página.
func _tut_cards(notes: Array, top: float) -> void:
	var factor := 0.85
	var width := CARD_SIZE.x * factor
	var gap := 40.0
	var x := (1280.0 - (notes.size() * width + (notes.size() - 1) * gap)) / 2.0
	for n in notes:
		var holder := Control.new()
		holder.custom_minimum_size = CARD_SIZE
		holder.size = CARD_SIZE
		holder.scale = Vector2(factor, factor)
		holder.position = Vector2(x, top)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.texture = _tex(n.face_path())
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.size = CARD_SIZE
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(face)
		_add_stamp(holder, n)
		_tut_body.add_child(holder)
		x += width + gap


## Tabela das formações (mesmos valores de Balance.TRANSACTIONS), escrita à mão.
func _tut_table(top: float) -> void:
	var cell_x := [150, 430, 800, 1010]
	var cell_w := [280, 370, 210, 130]
	var heads := [tr("Formação"), tr("Combinação"), tr("Valor base"), tr("Juros")]
	for c in range(4):
		var align := HORIZONTAL_ALIGNMENT_LEFT if c < 2 else HORIZONTAL_ALIGNMENT_CENTER
		_tut_body.add_child(_hand_label(Rect2(cell_x[c] + 12, top, cell_w[c] - 24, 40), heads[c], 22, HAND_INK, align))
	for r in range(HOWTO_ORDER.size()):
		var kind: String = HOWTO_ORDER[r]
		var tx: Dictionary = Balance.TRANSACTIONS[kind]
		var y := top + 44.0 + r * 36.0
		var cells := [tr(tx["name"]), tr(HOWTO_COMBO[kind]), "R$ %d" % tx["base"], "x%d" % tx["juros"]]
		for c in range(4):
			var align := HORIZONTAL_ALIGNMENT_LEFT if c < 2 else HORIZONTAL_ALIGNMENT_CENTER
			_tut_body.add_child(_hand_label(Rect2(cell_x[c] + 12, y, cell_w[c] - 24, 36), cells[c], 20, HAND_INK, align))


## Texto escrito à mão (Permanent Marker), usado sobre a arte da tela "Como jogar".
func _hand_label(rect: Rect2, text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	# Quebra de linha antes do texto: sem ela, o tamanho mínimo vira a linha inteira e o rótulo não quebra.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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


## Texto solto sobre a arte (cabeçalho, display, papel da impressora, mensagens).
func _label(parent: Node, rect: Rect2, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Tecla da calculadora: desenho animado (folha do aseprite em ui/calculadora) por cima do botão da arte.
## Repouso = quadro 0; ao passar o mouse, quadros 1 a 3 em loop; ao clicar, quadros 4 a 7 uma vez.
## O nome e a descrição saem na dica (tooltip). Apagada quando não pode ser usada.
func _calc_key(root: Control, name: String, desc: String, rect: Rect2, handler: Callable, enabled: bool, sheet: String) -> Button:
	var frames: Array = []
	for i in range(CALC_FRAMES):
		var at := AtlasTexture.new()
		at.atlas = _tex(CALC_SHEET_DIR + sheet)
		at.region = Rect2(i * CALC_FRAME_SIZE.x, 0, CALC_FRAME_SIZE.x, CALC_FRAME_SIZE.y)
		frames.append(at)
	var visual := TextureRect.new()
	visual.texture = frames[0]
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP
	visual.size = CALC_FRAME_SIZE
	visual.position = rect.get_center() - CALC_FRAME_SIZE / 2.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(visual)

	var key := Button.new()
	key.tooltip_text = "%s\n%s" % [name, desc]
	key.position = rect.position
	key.size = rect.size
	key.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		key.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var anim := {"visual": visual, "frames": frames, "key": key, "hovered": false, "tween": null}
	key.set_meta("anim", anim)
	key.mouse_entered.connect(func() -> void:
		anim["hovered"] = true
		if not key.disabled:
			_key_play(anim, CALC_HOVER, false))
	key.mouse_exited.connect(func() -> void:
		anim["hovered"] = false
		_key_rest(anim))
	key.pressed.connect(_key_click.bind(anim))
	key.pressed.connect(handler)
	key.disabled = not enabled
	root.add_child(key)
	return key


func _set_key_enabled(key: Button, enabled: bool) -> void:
	key.disabled = not enabled
	if not enabled:
		_key_rest(key.get_meta("anim"))


## Toca uma sequência de quadros da tecla (loop para o hover). Devolve a animação para encadear.
func _key_play(anim: Dictionary, seq: Array, loop: bool) -> Tween:
	if anim["tween"] != null and anim["tween"].is_valid():
		anim["tween"].kill()
	var tween := create_tween()
	if loop:
		tween.set_loops()
	for i in seq:
		tween.tween_callback(_set_key_frame.bind(anim, i))
		tween.tween_interval(CALC_FRAME_TIMES[i])
	anim["tween"] = tween
	return tween


func _set_key_frame(anim: Dictionary, index: int) -> void:
	anim["visual"].texture = anim["frames"][index]


func _key_click(anim: Dictionary) -> void:
	var tween := _key_play(anim, CALC_CLICK, false)
	tween.tween_callback(_key_rest.bind(anim))


## Volta ao repouso: quadro 0, ou o hover em loop se o mouse ainda estiver na tecla.
func _key_rest(anim: Dictionary) -> void:
	if anim["hovered"] and not anim["key"].disabled:
		_key_play(anim, CALC_HOVER, false)
	else:
		_key_play(anim, CALC_IDLE, false)


func _button(root: Control, text: String, rect: Rect2, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = rect.position
	btn.size = rect.size
	btn.pressed.connect(handler)
	btn.visible = false
	_skin_button(btn, "botao_creme")
	root.add_child(btn)
	return btn


## Botão da arte de art/ui/botoes: uma tira com 9 quadros (normal, brilho, pressionado, desativado).
## Só vale para os botões do jogo (partida, Camelô, comprovante, menu de pausa): a tela inicial não usa isto.
func _skin_button(btn: Button, sheet: String) -> void:
	var sb_normal := _sheet_box(sheet, BUTTON_FRAME_NORMAL, btn.size)
	var sb_hover := _sheet_box(sheet, BUTTON_FRAME_HOVER, btn.size)
	var sb_pressed := _sheet_box(sheet, BUTTON_FRAME_PRESSED, btn.size)
	var sb_disabled := _sheet_box(sheet, BUTTON_FRAME_DISABLED, btn.size)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Um quadro da tira como caixa de botão (cantos fixos, centro estica).
func _sheet_box(sheet: String, frame: int, size: Vector2) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _tex(BUTTON_SHEET_DIR + sheet + ".png")
	atlas.region = Rect2(frame * BUTTON_FRAME.x, 0, BUTTON_FRAME.x, BUTTON_FRAME.y)
	var sb := StyleBoxTexture.new()
	sb.texture = atlas
	# Cantos com 10 px; em botões baixos a margem vertical diminui para caber.
	var mx := 10.0
	var my := minf(10.0, floorf(size.y / 2.0) - 1.0)
	sb.texture_margin_left = mx
	sb.texture_margin_right = mx
	sb.texture_margin_top = my
	sb.texture_margin_bottom = my
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb
