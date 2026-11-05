# Briefing: selos das formas de pagamento (asset A4 do GDD)

## O que falta

Dos 46 assets da lista do GDD, todos estão em `art/` com o tamanho certo, **exceto** os 4 selos de forma de pagamento (A4). A pasta `art/notas/selos/` está vazia.

Decisão: **cédula neutra com selo** (plano do GDD: 8 frentes + 4 selos). As 32 cédulas coloridas em `art/notas/frentes/` deixam de ser usadas quando a troca for feita no código. Até lá, elas continuam no projeto.

## Cédulas neutras (8 novas, faltando)

Uma cédula por valor, sem cor de forma de pagamento. O bicho e o número ficam; a cor vira papel neutro.

| Arquivo de saída | Valor | Bicho |
| --- | --- | --- |
| `art/notas/neutras/nota_1.png` | R$ 1 | sabiá |
| `art/notas/neutras/nota_2.png` | R$ 2 | tatu |
| `art/notas/neutras/nota_5.png` | R$ 5 | quati |
| `art/notas/neutras/nota_10.png` | R$ 10 | bicho-preguiça |
| `art/notas/neutras/nota_20.png` | R$ 20 | tamanduá |
| `art/notas/neutras/nota_50.png` | R$ 50 | capivara |
| `art/notas/neutras/nota_100.png` | R$ 100 | boto-cor-de-rosa |
| `art/notas/neutras/nota_200.png` | R$ 200 | jacaré |

- Tamanho: 120×180 px, fundo transparente fora do contorno (mesmo formato das frentes atuais).
- Ponto de partida sugerido: uma das frentes coloridas já existentes do mesmo valor (ex.: `art/notas/frentes/frente_1_dinheiro.png`). Trocar as cores da forma de pagamento por um papel neutro creme (`F4EDD9`), mantendo o desenho do bicho, a moldura e os números em tinta escura. Assim não é preciso redesenhar os bichos.
- Não colocar nenhum selo na cédula neutra: o selo é um asset separado (abaixo) e é colocado pelo código.
- Relâmpago, Débito, Crédito e Dinheiro passam a ser identificados só pelo selo.

## Entregáveis dos selos

| Arquivo de saída | Forma | Tamanho |
| --- | --- | --- |
| `art/notas/selos/selo_dinheiro.png` | Dinheiro | 40×40 |
| `art/notas/selos/selo_relampago.png` | Relâmpago | 40×40 |
| `art/notas/selos/selo_debito.png` | Débito | 40×40 |
| `art/notas/selos/selo_credito.png` | Crédito | 40×40 |

Cada um também com a fonte editável: `art/notas/selos/selo_<forma>.aseprite`.

Nomes das formas (chaves usadas no código): `dinheiro`, `relampago`, `debito`, `credito`. Não usar o nome "Pix" (marca do Banco Central; o jogo usa "Relâmpago").

## Estilo geral

- Canvas 40×40, RGBA, fundo totalmente transparente.
- Selo redondo: disco de 36 px de diâmetro centrado, com contorno de 2 px na cor `1E1E1E`.
- Dentro do disco, um ícone simples de 16 a 20 px, em cor de papel `FFF8E7`, com contorno de 1 px em `1E1E1E` para leitura sobre a cor do disco.
- Traço de carimbo: bordas levemente irregulares (sem anti-aliasing), como nos outros assets pixel do projeto. Ruído de tinta leve opcional.
- Sem texto escrito dentro do selo (40 px não comporta letra legível). O significado vem do ícone.

## Cada selo

| Forma | Cor do disco | Ícone | Descrição |
| --- | --- | --- | --- |
| Dinheiro | `3F8F4E` (verde) | Moeda: círculo com cifrão `$` estilizado | Moeda de bronze com cifrão no centro. |
| Relâmpago | `E8B923` (amarelo) | Raio: zigue-zague em forma de raio | Raio grande e inclinado, no centro. Cor amarela ajuda a diferenciar do verde do Dinheiro. |
| Débito | `2F6FB0` (azul) | Cartão: retângulo com faixa escura no topo e um chip pequeno | Cartão de plástico visto de frente, com faixa magnética. |
| Crédito | `7A4FA3` (roxo) | Cartão: retângulo com duas listras horizontais | Cartão de plástico com duas listras, uma escura e uma clara. |

Observação: Dinheiro e Débito ficam bem separados por cor e ícone. Se Relâmpago continuar parecido com Dinheiro, use o amarelo da tabela.

## Script Lua (para o agente)

Seguir o mesmo padrão dos scripts existentes em `aseprite/` (ex.: `05_cartaz_agiota.lua`):

- Arquivo novo: `aseprite/35_selos_formas_pagamento.lua`. Gera os 4 selos em uma só execução.
- Cabeçalho com comentário: saída, tamanho e descrição (como nos outros scripts).
- Caminhos relativos à raiz do projeto (`art/notas/selos/...`), criando a pasta se não existir.
- Desenho só com `Image:drawPixel` e laços (sem arquivos externos, sem texto por código).
- Para cada selo: `Sprite(40, 40, ColorMode.RGB)` com fundo transparente, desenhar, salvar `.aseprite` e exportar `.png` com `saveCopyAs`.
- Terminar com `print` de cada arquivo gerado.

## Critérios de aceite

- 4 PNGs de exatamente 40×40, com canal alfa (fundo transparente de verdade, sem fundo branco).
- Cada selo identificável sem legenda: ícone diferente e cor diferente das outras três.
- Contorno de 2 px legível em tamanho real (40×40), não só ampliado.
- Arquivos `.aseprite` editáveis gerados junto.
- Rodar o script de novo gera o mesmo resultado (sem aleatoriedade sem semente).

## Depois que as artes estiverem prontas (código, não é tarefa do agente)

- `scripts/core/note.gd`: `face_path()` passa a apontar para `art/notas/neutras/nota_<valor>.png`, sem a forma de pagamento no nome.
- `scripts/ui/bill_round_view.gd`: a carta na mão ganha o selo da forma de pagamento (canto da cédula).
- `GDD.md`: atualizar a seção de notas e a lista de artes (A3 e A4).
- Só então apagar as 32 cédulas coloridas, se não forem mais usadas.
