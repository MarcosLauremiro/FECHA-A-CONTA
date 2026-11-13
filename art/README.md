# Arte

Todas as artes são PNG com fundo transparente, no tamanho indicado. Use os nomes de arquivo abaixo (minúsculas, sem acento) para o Godot achar tudo sem configurar nada.

Status: `[ ]` pendente · `[x]` pronto e colocado na pasta.

## caixa/ (A1, A2): P1, até a hora 6

- [ ] `caixa/caixa_moldura.png`: moldura do caixa, 1280×720, área da tela vazada (A1)
- [ ] `caixa/caixa_tecla.png`: tecla lateral normal, 64×48 (A2)
- [ ] `caixa/caixa_tecla_pressionada.png`: tecla lateral pressionada, 64×48 (A2)

## notas/ (A3, A4, A5): P1, até a hora 10

Frentes das notas, 120×224. **Feitas como 32 cartas prontas** (8 valores × 4 formas), com a forma de pagamento já impressa, então não há selos separados. Os originais estão em `notas/frentes/*.aseprite` e os PNGs foram gerados a partir deles.

Nomes: `frente_<valor>_<forma>.png`, com forma em `dinheiro`, `relampago`, `debito` ou `credito`.

- [x] `notas/frentes/frente_{1,2,5,10,20,50,100,200}_dinheiro.png` (verde)
- [x] `notas/frentes/frente_{1,2,5,10,20,50,100,200}_relampago.png` (verde-água, o "Pix" do jogo)
- [x] `notas/frentes/frente_{1,2,5,10,20,50,100,200}_debito.png` (azul)
- [x] `notas/frentes/frente_{1,2,5,10,20,50,100,200}_credito.png` (roxo)

Bichos: 1 sabiá, 2 tatu, 5 quati, 10 bicho-preguiça, 20 tamanduá, 50 capivara, 100 boto-cor-de-rosa, 200 jacaré.

~~Selos de forma de pagamento (A4)~~: não são necessários, a forma já está na carta.

Verso, 120×224 (A5):

- [ ] `notas/verso/verso.png`

## esquemas/ (A6): P1, até a hora 14

Cartazes lambe-lambe, 200×280. Um por esquema.

- [ ] `esquemas/cartaz_agiota.png`
- [ ] `esquemas/cartaz_cunhado.png`
- [ ] `esquemas/cartaz_coach.png`
- [ ] `esquemas/cartaz_piramide.png`
- [ ] `esquemas/cartaz_cashback.png`
- [ ] `esquemas/cartaz_rifa.png`
- [ ] `esquemas/cartaz_vaquinha.png`
- [ ] `esquemas/cartaz_relampago_errado.png`

## contas/ (A7): P1, até a hora 14

Contas impressas, 260×360.

- [ ] `contas/conta_boleto.png`
- [ ] `contas/conta_aluguel.png`
- [ ] `contas/conta_fatura.png`

## camelo/ (A8, A9, A10): P2, até a hora 17

- [ ] `camelo/camelo_fundo.png`: banca de feira com lona azul, 1280×720 (A8)
- [ ] `camelo/plaquinha_1.png`: plaquinha de preço, 80×50, cor 1 (A9)
- [ ] `camelo/plaquinha_2.png`: plaquinha de preço, 80×50, cor 2 (A9)
- [ ] `camelo/plaquinha_3.png`: plaquinha de preço, 80×50, cor 3 (A9)
- [x] `investimentos/poupanca.png`: porquinho, 120×120 (A10)
- [x] `investimentos/tesouro.png`: título carimbado, 120×120 (A10)
- [x] `investimentos/cripto.png`: moeda de plástico, 120×120 (A10)

## comprovante/ (A11): P2, até a hora 17

- [ ] `comprovante/comprovante_termico.png`: tira serrilhada, 240×600, usar 9-slice

## chefes/ (A12): P2, até a hora 19

- [ ] `chefes/chefe_banco_fora.png`: carimbo, 200×200
- [ ] `chefes/chefe_taxa_manutencao.png`: carimbo, 200×200
- [ ] `chefes/chefe_janeiro.png`: carimbo, 200×200

## telas/ (A13, A14, A15): P2 e P3

- [ ] `telas/titulo.png`: logo e cartão entrando na fenda, 1280×720 (A13, P2)
- [ ] `telas/fim_negativado.png`: carimbo "NOME NEGATIVADO", 400×200 (A14, P2)
- [ ] `telas/fim_contas_em_dia.png`: carimbo "CONTAS EM DIA", 400×200 (A14, P2)
- [ ] `telas/como_jogar.png`: tabela de transações desenhada à mão, 1280×720 (A15, P3)

## efeitos/ (A16): P3, até a hora 20

- [ ] `efeitos/particula_nota.png`: nota voando, 32×32
- [ ] `efeitos/particula_moeda.png`: moeda, 32×32
- [ ] `efeitos/particula_fagulha.png`: fagulha de carimbo, 32×32

## jam/ (A17): P3, até a hora 22

Não entra no jogo, só na página do itch.io.

- [ ] `jam/capa_jam.png`: capa, 630×500

## Fontes

Ficam em `fonts/` (não precisam ser desenhadas):

- VT323: terminal
- Anton ou Bebas Neue: cartazes
- Permanent Marker: letra de mão

Confirme a licença de cada uma antes do envio.
