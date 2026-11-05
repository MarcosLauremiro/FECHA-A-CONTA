# GDD — Fecha a Conta (Game Jam 24h)

Nov 4, 2026 · @miro

## Visão geral

**Fecha a Conta** é um roguelike de cartas em que você paga as contas de um ano com notas de dinheiro e esquemas absurdos. A versão da jam entrega uma partida curta (3 meses, cerca de 15 minutos) jogável do começo ao fim, no estilo visual "papelada brasileira".

**Pitch em uma frase:** você é um brasileiro endividado, a fatura do cartão está chegando, e a única saída é a rifa do bairro, o cunhado investidor e o coach financeiro.

| Item | Definição |
| --- | --- |
| Gênero | Roguelike de construção de baralho, inspirado em pôquer |
| Tom | Sátira leve: rir da própria vida financeira |
| Plataforma | PC (build web HTML5 para a página da jam + Windows) |
| Engine | Godot 4 (2D, exporta web sem custo) |
| Equipe assumida | 1 programador + 1 artista (dev solo: ver cortes na seção de riscos) |
| Duração de uma partida | 10 a 15 minutos |
| Idioma | Português, com cartazes mantidos em PT na futura versão em inglês |

**Pilares (toda decisão passa por eles):**

1. **Pontuação que dá gosto:** número subindo, "AGUARDE… PROCESSANDO", comprovante saindo, som de maquininha. Se só isso ficar bom, o jogo funciona.
2. **Papelada brasileira:** tudo é papel físico sobre uma tela de caixa eletrônico antigo. Nada de pixel art com CRT, para não parecer clone de Balatro.
3. **Piada reconhecível:** cada esquema e cada chefe precisa render um print sozinho.

## Escopo de 24 horas

A jam corta o MVP de 3–4 meses para cerca de um décimo: 3 meses de partida, 5 transações, 8 esquemas, 3 chefes e 1 carteira. O que não está na coluna "Entra" não é começado.

| Sistema | Plano completo | Entra na jam | Fica para depois |
| --- | --- | --- | --- |
| Meses | 8 meses + Janeiro | 3 meses (Março, Junho, Janeiro) | Meses 4 a 8 |
| Contas por mês | 3 (boleto, aluguel, fatura) | 3 (boleto, aluguel, fatura) | — |
| Transações | 8 | 6 (Trocado, Dobradinha, Bolada, Escadinha, Tudo no Relâmpago, Cofrinho) | Parcelado, Relâmpago Premiado |
| Esquemas | 40 | 8 | 32 restantes |
| Chefes (faturas) | 10 | 3 (Banco fora do ar, Taxa de manutenção, Janeiro) | 7 restantes |
| Camelô | Esquemas, investimentos, carimbos, cupons | Esquemas + 3 investimentos | Carimbos, cupons |
| Mecânica própria | Cheque especial, inflação, parcelamento, troco | Troco vira grana + Cheque especial | Inflação, parcelamento |
| Carteiras iniciais | 4 | 1 (Padrão) | Estudante, Herança da Vó, MEI, Concurseiro |
| Dificuldade | Níveis do Serasa | 1 nível | Bom pagador → Nome sujo |
| Save / meta-progressão | — | Nenhum | Desbloqueios |

**Por que esses cortes:** a jam é julgada pelos primeiros 5 minutos. Pontuação satisfatória e 2 ou 3 combos que "quebram o jogo" valem mais que conteúdo em quantidade. Cheque especial fica porque é a mecânica que mais diferencia do Balatro e custa pouco código.

## Regras e loop de jogo

Cada conta é uma rodada: o jogador tem 4 dias (jogadas) e 3 trocas (descartes) para atingir a meta de saldo. Paga a conta, passa no Camelô; falha uma conta, perde a partida.

**Loop de uma partida**

1. Tela de título → "INSIRA SEU CARTÃO" → nova partida.
2. Para cada mês (3 meses): Boleto → Camelô → Aluguel → Camelô → Fatura (chefe) → Camelô.
3. Em cada conta: comprar 8 cartas → escolher até 5 → **Pagar** (usa 1 dia) ou **Trocar** (usa 1 troca) → repetir até bater a meta ou acabar os dias.
4. Meta batida → comprovante com recompensa → Camelô.
5. Dias acabaram sem meta → comprovante "NOME NEGATIVADO" → fim de partida.
6. Pagou a fatura de Janeiro → comprovante final "CONTAS EM DIA" + saldo máximo do ano.

### O baralho de notas

O baralho tem 32 cartas: 8 valores × 4 formas de pagamento, como um baralho de pôquer reduzido. Cada nota soma pontos de Valor quando pontua.

| Nota | R$ 1 | R$ 2 | R$ 5 | R$ 10 | R$ 20 | R$ 50 | R$ 100 | R$ 200 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pontos de Valor | 2 | 3 | 5 | 6 | 7 | 8 | 10 | 11 |

Formas de pagamento ("naipes"): Dinheiro, Relâmpago (o "Pix" do jogo), Débito, Crédito. A sequência de valores segue a ordem das notas: 1-2-5-10-20-50-100-200.

### Transações

| Transação | Combinação | Valor base | Juros base | Juros na tela |
| --- | --- | --- | --- | --- |
| Trocado | 1 carta solta (a maior) | 5 | ×1 | +0% |
| Dobradinha | 2 notas de mesmo valor | 10 | ×2 | +100% |
| Bolada | 3 iguais | 30 | ×3 | +200% |
| Escadinha | 5 valores em sequência | 30 | ×4 | +300% |
| Tudo no Relâmpago | 5 da mesma forma de pagamento | 35 | ×4 | +300% |
| Cofrinho | 4 iguais | 60 | ×7 | +600% |

### Pontuação

```latex
\text{Saldo} = (\text{Valor base} + \sum \text{pontos das notas que pontuam}) \times \text{Juros}
```

Ordem de resolução (importa para a animação e para os esquemas): base da transação → cada nota que pontua, da esquerda para a direita → esquemas da esquerda para a direita (somas de Juros antes, multiplicações depois) → regra do chefe → total.

### Metas e dinheiro

| Mês | Boleto | Aluguel | Fatura (chefe) |
| --- | --- | --- | --- |
| 1 — Março | 300 | 450 | 600 |
| 2 — Junho | 900 | 1.300 | 1.800 |
| 3 — Janeiro | 2.500 | 3.500 | 5.000 |

- Recompensa por conta paga: Boleto R$ 3, Aluguel R$ 4, Fatura R$ 5, + R$ 1 por dia não usado.
- **Troco vira grana:** R$ 1 a cada 25% acima da meta, no máximo R$ 5.
- **Cheque especial:** no Camelô, a carteira pode ir até −R$ 10. A cada conta paga, a dívida cresce 25% (arredonda para cima). Com dívida, a recompensa paga a dívida primeiro.
- Carteira inicial: R$ 4. Máximo de 5 esquemas ativos.
- Os valores de meta são chute inicial; ajustar no playtest da hora 17.

## Conteúdo da jam

A jam tem 8 esquemas, 3 investimentos e 3 chefes. Os esquemas foram escolhidos para formar dois combos claros: "baralho de Relâmpago" (Relâmpago Errado + Cashback + Coach) e "empilhar Juros" (Cunhado + Pirâmide + Agiota).

### Esquemas (cartazes de poste)

| Esquema | Efeito | Preço | Texto do cartaz |
| --- | --- | --- | --- |
| Agiota | +5 de Juros; cobra 10% da carteira a cada conta paga | R$ 4 | EMPRESTO DINHEIRO NA HORA |
| Cunhado Investidor | Cada Escadinha jogada dá +1 de Juros a ele, para sempre | R$ 5 | GANHE 30% AO MÊS SEM RISCO |
| Coach Financeiro | ×2 de Juros se jogar exatamente 5 notas; se jogar menos, perde 1 de Juros | R$ 6 | MENTALIDADE MILIONÁRIA EM 7 DIAS |
| Pirâmide | +1 de Juros por outro esquema ativo; 1 em 6 de colapsar a cada mês | R$ 5 | INDIQUE 3 AMIGOS E FIQUE RICO |
| Cashback | Notas de Crédito que pontuam devolvem R$ 1 | R$ 4 | SEU DINHEIRO DE VOLTA\* |
| Rifa do Bairro | 1 em 4 de multiplicar o Juros por 5 | R$ 5 | RIFA DE 1 PORCO — R$ 2 O NÚMERO |
| Vaquinha | Soma os pontos das notas que ficaram na mão ao Valor | R$ 6 | AJUDE O JUNINHO A PAGAR O ALUGUEL |
| Relâmpago Errado | A primeira nota de Relâmpago jogada em cada conta é duplicada no baralho | R$ 5 | FIZ UM RELÂMPAGO ERRADO, DEVOLVE PFV |

### Camelô (loja entre contas)

- Oferece 2 esquemas aleatórios + 1 investimento aleatório.
- **Pechinchar** (trocar a oferta): R$ 2.
- **Vender esquema:** devolve metade do preço, arredondado para baixo.
- **Pegar no cheque especial:** botão visível sempre que o jogador não tiver dinheiro para um item.

| Investimento | Melhora | Efeito por nível | Preço |
| --- | --- | --- | --- |
| Poupança | Dobradinha | +10 Valor, +1 Juros | R$ 3 |
| Tesouro Direto | Escadinha | +20 Valor, +1 Juros | R$ 3 |
| Cripto | Tudo no Relâmpago | +25 Valor, +2 Juros; 1 em 4 de cair um nível em vez disso | R$ 3 |

### Chefes: as faturas

| Mês | Fatura | Regra |
| --- | --- | --- |
| Março | Banco fora do ar | Notas de Relâmpago não pontuam |
| Junho | Taxa de manutenção | Cada troca custa R$ 1 (pode usar cheque especial) |
| Janeiro | IPVA + IPTU + Material escolar | Três regras juntas: Leão da Receita (27,5% do saldo de cada jogada some), Golpe do WhatsApp (1 esquema aleatório desativado) e Taxa de manutenção |

## Interface e fluxo de telas

O jogo inteiro acontece dentro de um caixa eletrônico dos anos 90/2000: a tela verde do terminal fica no centro e as notas de papel ficam sobre a "bancada" em primeiro plano. Resolução base 1280×720, escalando por múltiplos inteiros.

### Layout da tela de jogo

- **Moldura do caixa** (fixa): carcaça bege, 4 teclas laterais com setinha de cada lado, fenda de cartão e boca da impressora em cima.
- **Tela do terminal** (centro-alto): nome da conta, meta, saldo atual, dias e trocas restantes, transação detectada com nível. Fonte monoespaçada verde.
- **Faixa de esquemas** (topo): até 5 cartazes lambe-lambe colados lado a lado, levemente tortos.
- **Mão** (embaixo): 8 notas em leque; clique sobe a nota; arrastar reordena.
- **Teclas laterais** = botões: PAGAR, TROCAR, ORDENAR POR VALOR, ORDENAR POR FORMA. Teclado: Enter paga, Espaço troca.
- **Carteira** (canto): R$ em fonte de visor de LCD, vermelha quando negativa.

### Sequência de pontuação (o momento mais importante do jogo)

1. Tela mostra "AGUARDE… PROCESSANDO" por 0,4 s.
2. Cada nota que pontua pula e solta seus pontos em Valor, com bipe que sobe de tom.
3. Cada esquema ativo balança e mostra seu efeito sobre o cartaz.
4. Juros aparece em % e cresce com som de maquininha de cartão.
5. Total cai no saldo com caixa registradora; a tela treme proporcional ao tamanho do saldo.
6. Acima de 5× a meta: o comprovante sai gigante, atravessando a tela.

### Telas

1. **Título:** "INSIRA SEU CARTÃO" piscando; clique em qualquer lugar.
2. **Conta:** tela de jogo descrita acima, com o boleto/aluguel/fatura impresso ao lado.
3. **Comprovante de pagamento:** impressora térmica cospe o recibo com saldo, troco e recompensa.
4. **Camelô:** banca de feira com lona azul; itens pendurados com preço em papelão fluorescente.
5. **Fim de partida:** comprovante "NOME NEGATIVADO" ou "CONTAS EM DIA", com botão JOGAR DE NOVO.

Paleta: base verde-terminal e bege-papel apagados; destaques amarelo, vermelho e verde-limão de cartaz, que só aparecem em combos grandes.

## Plano de montagem do game (programação)

O jogo fica jogável com retângulos coloridos na hora 7, com conteúdo completo na hora 14 e congelado na hora 18. A arte entra por cima de placeholders com o mesmo tamanho, então a programação nunca espera pela arte.

### Marcos

| Hora | Marco | Pronto quando |
| --- | --- | --- |
| 7 | Jogável feio | Dá para pagar ou falhar uma conta com retângulos |
| 14 | Conteúdo completo | 3 meses, 8 esquemas, Camelô e chefes funcionando |
| 18 | Congelamento de features | Daqui em diante, só polimento, balanceamento e bugs |
| 22 | Build final | Web e Windows rodando fora do editor |
| 24 | Envio | Página da jam publicada |

### Arquitetura mínima (Godot 4)

- `GameState` (autoload): mês, conta atual, carteira, dívida, baralho, esquemas, níveis das transações.
- `Note` (Resource): valor, forma, pontos. `Deck`: 32 notas, embaralhar, comprar, devolver.
- `HandEvaluator`: função pura que recebe até 5 notas e devolve transação + notas que pontuam.
- `Scorer`: função pura que devolve o resultado e uma **lista de eventos** ("nota X +7", "Coach ×2"). A animação só toca essa lista, o que separa regra de visual.
- `Scheme` (Resource com script): ganchos `on_note_scored`, `on_hand_scored`, `on_bill_paid`, `on_month_start`. Cada esquema é um arquivo pequeno.
- `Boss`: mesmos ganchos + `modify_goal`. Janeiro = lista de 3 regras.
- Dados de esquemas, preços e metas num único `balance.gd`, para ajustar sem caçar números.

### Cronograma hora a hora

**Horas 0–1 · Setup**

- [ ] Projeto Godot 4, resolução 1280×720, pastas `scenes/ scripts/ art/ sfx/`
- [ ] Repositório git e primeiro commit
- [ ] Exportar uma cena vazia para web e abrir no navegador (pega problema de export logo cedo)
- [ ] Combinar com a arte os tamanhos de placeholder (ver seção de artes)

**Horas 1–4 · Cartas e mão**

- [ ] `Note`, `Deck`, embaralhar e comprar 8
- [ ] Cena da mão: notas em leque, clique seleciona (máx. 5)
- [ ] Botões PAGAR e TROCAR, contadores de dias e trocas
- [ ] Ordenar por valor / por forma

**Horas 4–7 · Pontuação e conta**

- [ ] `HandEvaluator` com as 6 transações + testes rápidos de cada uma
- [ ] `Scorer` gerando lista de eventos; saldo somando na tela
- [ ] Meta, vitória e derrota de uma conta
- [ ] **Marco: jogável feio**

**Horas 7–9 · Loop da partida**

- [ ] Sequência de 3 meses × 3 contas, metas da tabela
- [ ] Recompensas, troco vira grana, carteira
- [ ] 3 chefes com suas regras
- [ ] Tela de fim de partida (texto simples)

**Horas 9–12 · Esquemas**

- [ ] Sistema de ganchos e faixa de esquemas (máx. 5)
- [ ] Implementar os 8 esquemas, na ordem: Agiota, Coach, Rifa, Cashback, Vaquinha, Cunhado, Pirâmide, Relâmpago Errado
- [ ] Tooltip ao passar o mouse sobre o cartaz

**Horas 12–14 · Camelô**

- [ ] Oferta de 2 esquemas + 1 investimento, comprar, vender, pechinchar
- [ ] Níveis de transação (investimentos)
- [ ] Cheque especial: limite −R$ 10, dívida crescendo 25% por conta
- [ ] **Marco: conteúdo completo**

**Horas 14–15 · Integrar arte v1**

- [ ] Trocar placeholders pelos assets que já chegaram (moldura, notas, cartazes)

**Horas 15–18 · Sensação (juice)**

- [ ] Tocar a lista de eventos com tweens: nota pula, cartaz balança, números sobem
- [ ] "AGUARDE… PROCESSANDO", tremor de tela, comprovante gigante acima de 5× a meta
- [ ] Ligar todos os sons e a música
- [ ] Hora 17: primeiro playtest com alguém de fora; anotar onde trava
- [ ] **Marco: congelamento de features**

**Horas 18–21 · Telas finais, balanceamento e bugs**

- [ ] Título "INSIRA SEU CARTÃO", tela "Como jogar" (1 imagem), comprovante final
- [ ] Ajustar metas e preços em `balance.gd` a partir do playtest
- [ ] Integrar arte v2 (Camelô, comprovantes, telas)
- [ ] Corrigir bugs que quebram a partida; ignorar os cosméticos

**Horas 21–22 · Build**

- [ ] Export web e Windows; testar no Chrome e no Firefox (áudio só toca após o primeiro clique)
- [ ] **Marco: build final**

**Horas 22–24 · Envio**

- [ ] Página da jam: capa, 3 screenshots, 1 GIF de combo grande, descrição curta
- [ ] Enviar com pelo menos 30 minutos de folga
- [ ] Dormir

## Artes e áudio necessários

São 46 peças de arte, 14 sons e 1 música, em três entregas: P1 até a hora 14 (o jogo não existe sem elas), P2 até a hora 19, P3 só se sobrar tempo. Tudo em PNG com fundo transparente, no tamanho final indicado.

### Como produzir rápido

- **Escanear papel real:** folha sulfite amassada, papel kraft, papelão e uma mancha de café. Essas 4 texturas viram fundo de nota, cartaz e comprovante.
- **Notas montadas no engine:** 8 frentes (uma por valor) + 4 selos de forma de pagamento = 32 cartas. Ninguém desenha 32 notas.
- **Cartazes por template:** um layout xerox único; muda texto, cor e desenho tosco. Cada cartaz leva cerca de 15 minutos.
- **Bichos das notas:** desenho próprio, traço simples de gravura. Nenhum bicho repete o da cédula real do mesmo valor.

### Lista de artes

| # | Asset | Descrição | Tamanho (px) | Qtd | Prioridade | Entrega até |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Moldura do caixa eletrônico | Carcaça bege, fenda de cartão, boca da impressora, área da tela vazada | 1280×720 | 1 | P1 | Hora 6 |
| A2 | Teclas laterais | Tecla com setinha, estados normal e pressionado | 64×48 | 2 | P1 | Hora 6 |
| A3 | Frente das notas | Papel texturizado com bicho: R$ 1 sabiá (moeda), R$ 2 tatu, R$ 5 quati, R$ 10 bicho-preguiça, R$ 20 tamanduá, R$ 50 capivara, R$ 100 boto-cor-de-rosa, R$ 200 jacaré | 120×180 | 8 | P1 | Hora 10 |
| A4 | Selos de forma de pagamento | Carimbo para Dinheiro, Relâmpago, Débito, Crédito | 40×40 | 4 | P1 | Hora 10 |
| A5 | Verso da nota | Padrão de papel-moeda genérico | 120×180 | 1 | P1 | Hora 10 |
| A6 | Cartazes de esquema | Lambe-lambe xerox, cores estouradas, telefone rasgado embaixo (textos na seção de conteúdo) | 200×280 | 8 | P1 | Hora 14 |
| A7 | Contas impressas | Boleto, aluguel (recibo de imobiliária) e fatura de cartão genéricos | 260×360 | 3 | P1 | Hora 14 |
| A8 | Fundo do Camelô | Banca de feira, lona azul, ganchos para pendurar itens | 1280×720 | 1 | P2 | Hora 17 |
| A9 | Plaquinhas de preço | Papelão fluorescente escrito à mão, 3 cores | 80×50 | 3 | P2 | Hora 17 |
| A10 | Investimentos | Ícone de Poupança (porquinho), Tesouro Direto (título carimbado), Cripto (moeda de plástico) | 120×120 | 3 | P2 | Hora 17 |
| A11 | Comprovante térmico | Tira de papel térmico com borda serrilhada, estica na vertical (9-slice) | 240×600 | 1 | P2 | Hora 17 |
| A12 | Selos de chefe | Carimbo grande para cada fatura: Banco fora do ar, Taxa de manutenção, Janeiro | 200×200 | 3 | P2 | Hora 19 |
| A13 | Tela de título | Logo "Fecha a Conta" em letra de cartaz + cartão entrando na fenda | 1280×720 | 1 | P2 | Hora 19 |
| A14 | Carimbos de fim | "NOME NEGATIVADO" e "CONTAS EM DIA" | 400×200 | 2 | P2 | Hora 19 |
| A15 | Tela "Como jogar" | Uma imagem com a tabela de transações desenhada à mão | 1280×720 | 1 | P3 | Hora 20 |
| A16 | Partículas | Nota voando, moeda, fagulha de carimbo | 32×32 | 3 | P3 | Hora 20 |
| A17 | Capa da jam | Capa da página (formato itch.io) | 630×500 | 1 | P3 | Hora 22 |

**Fontes (sem desenhar):** terminal = VT323; cartaz = Anton ou Bebas Neue; letra de mão = Permanent Marker. Todas gratuitas no Google Fonts; confirmar a licença de cada uma antes do envio.

### Lista de áudio

| # | Som | Quando toca | Prioridade |
| --- | --- | --- | --- |
| S1 | Bipe de tecla de caixa eletrônico | Selecionar nota, apertar tecla | P1 |
| S2 | Bipe com tom subindo (5 alturas) | Cada nota que pontua | P1 |
| S3 | Maquininha de cartão processando | Juros crescendo | P1 |
| S4 | Caixa registradora | Saldo cai na conta | P1 |
| S5 | Impressora térmica | Comprovante saindo | P1 |
| S6 | Papel embaralhando | Trocar / comprar cartas | P1 |
| S7 | Moedas caindo | Receber dinheiro | P2 |
| S8 | "Relâmpago recebido" (notificação de celular inventada) | Cashback e troco | P2 |
| S9 | Fita adesiva / cartaz colando | Comprar esquema | P2 |
| S10 | Carimbo batendo | Chefe aparece, fim de partida | P2 |
| S11 | Erro de caixa (bipe grave duplo) | Ação inválida, cheque especial | P2 |
| S12 | Papel rasgando | Pirâmide colapsa, vender esquema | P3 |
| S13 | Grito de feirante curto | Entrar no Camelô | P3 |
| S14 | Plateia "uooh" | Combo acima de 5× a meta | P3 |
| M1 | Loop de samba-jazz lo-fi ou brega instrumental, 1–2 min | Fundo do jogo inteiro | P2 |

Origem do áudio: gravar com o celular (teclado, papel, moedas, carimbo) ou bancos com licença CC0. Para a música, compor um loop simples ou usar faixa com licença que permita uso em jogo, com crédito na página.

### Ordem de trabalho da arte

- **Horas 0–1:** escanear as 4 texturas de papel e fechar paleta e tamanhos com a programação.
- **Horas 1–6:** moldura do caixa e teclas (A1, A2).
- **Horas 6–10:** notas, selos e verso (A3–A5).
- **Horas 10–14:** cartazes e contas (A6, A7), gravar os sons P1.
- **Horas 14–19:** Camelô, comprovante, chefes, título e carimbos de fim (A8–A14), sons P2 e música.
- **Horas 19–22:** P3 e correções pedidas no playtest.
- **Horas 22–24:** capa, screenshots e GIF para a página.

## Riscos, cortes e entrega

O maior risco é chegar na hora 18 sem a sequência de pontuação animada. Se algo atrasar, corte conteúdo na ordem abaixo e proteja a pontuação.

### Cortes de emergência (nesta ordem)

1. Todos os itens P3 de arte e som.
2. Investimentos (Camelô vende só esquemas).
3. Janeiro com 2 regras em vez de 3.
4. Esquemas de 8 para 5 (manter Agiota, Coach, Rifa, Cashback, Vaquinha).
5. Partida de 3 para 2 meses (Março e Janeiro).
6. Cheque especial — último a cair, porque é o que diferencia o jogo.

**Dev solo, sem artista:** faça só a arte P1, usando texturas escaneadas + fontes + formas simples, em blocos de 1 hora intercalados com a programação (horas 6, 10 e 14). O resto da tela fica com fundo liso verde-terminal.

### Riscos

| Risco | Sinal de alerta | Resposta |
| --- | --- | --- |
| Avaliador de transações com bug | Hora 7 sem conta jogável | Lançar só Trocado, Dobradinha, Bolada e Tudo no Relâmpago; Escadinha depois |
| Balanceamento impossível | Ninguém passa do mês 2 no playtest | Baixar metas em 30% no `balance.gd` |
| Export web falha | Áudio mudo ou tela preta no navegador | Testado na hora 1; manter build Windows como plano B |
| Arte atrasa | P1 não entregue na hora 14 | Placeholder fica; arte entra até a hora 19 |
| Cansaço | Erro bobo repetido | Dormir 2 horas entre as horas 18 e 21, depois do congelamento |

### Cuidados legais

- **Notas inventadas:** nada de reproduzir cédulas reais do Real; bichos, cores e layout próprios.
- **"Pix":** é marca do Banco Central, então a jam usa "Relâmpago". Consultar advogado antes de usar o nome numa versão comercial.
- **Bancos e empresas:** nenhum nome ou logo real em cartazes, contas ou faturas.
- **Fontes, sons e música:** só com licença que permita uso em jogo; listar créditos na página.
- **Visual:** nada de pixel art com efeito CRT nem layout parecido com o de Balatro.

### Checklist de entrega

- [ ] Partida completa jogável do título ao comprovante final
- [ ] Build web abre no Chrome e no Firefox, com som após o primeiro clique
- [ ] Build Windows roda fora do editor
- [ ] Tela "Como jogar" ou dica na primeira conta
- [ ] Página com capa, 3 screenshots, 1 GIF de combo e créditos
- [ ] Enviado antes do prazo, com folga de 30 minutos

---

## Versão completa (pós-jam): planejamento

O jogo não é mais uma jam: é um jogo próprio, que será lançado. As seções acima descrevem a versão da jam e continuam valendo como referência do que já está pronto. Esta seção guarda o que vem depois.

### Estrutura em desafios de 3 meses

O ano é dividido em 4 desafios. Cada um tem 3 meses, e o jogo sempre começa em janeiro.

| Desafio | Meses | Status |
| --- | --- | --- |
| 1 | Janeiro, Fevereiro, Março | A versão atual da jam usa Março, Junho e Janeiro; reorganizar |
| 2 | Abril, Maio, Junho | A definir |
| 3 | Julho, Agosto, Setembro | A definir |
| 4 | Outubro, Novembro, Dezembro | A definir |

- O jogador começa sempre em janeiro e só avança para os próximos 3 meses do desafio atual.
- Cada desafio tem chefes, contas e esquemas próprios, para dar profundidade sem misturar as regras.
- Desbloqueio dos desafios: a definir (por exemplo, terminar o desafio anterior).

### Conquistas

- Lista de conquistas com nome, texto e condição (ex.: "Pagou uma conta sem trocar nenhuma nota", "Ficou no Serasa e ganhou mesmo assim").
- Mostradas no menu de pausa e numa tela própria.
- Condições a definir por desafio.

### Raridade dos esquemas

- Cada esquema tem uma raridade (comum, rara, lendária). Afeta o preço, a chance de aparecer no Camelô e, se for o caso, o efeito.
- Mostrada na carta do esquema (cor da borda ou etiqueta).
- Valores a definir.

### Clareza da mão

Hoje o jogador não sabe se a mão vai bater a meta antes de pagar. A ideia é mostrar, ao selecionar as notas:

- o nome da formação (já existe);
- a pontuação estimada da jogada (Valor e Juros), com os esquemas e investimentos que se aplicam;
- quanto falta para a meta, ou se a jogada já bate a meta;
- a explicação de cada esquema e de cada chefe ao passar o mouse (já existe em parte, falta padronizar).

### Tutorial

- Opção "Tutorial" na tela inicial, que pode ser escolhida no começo ou a qualquer momento.
- Passo a passo: notas, formação, pagar, trocar, Camelô, chefes.
- Pode ser refeito quando o jogador quiser.

### Ideias de memes e referências (em aberto)

Nenhuma destas ideias foi aprovada ainda. Ao escolher, cada uma vira uma regra nova ou um texto no jogo.

- **Nazaré Confusa:** chefe ou evento em que as notas da mão aparecem com o valor escondido até pagar ou trocar.
- **Julius (Todo Mundo Odeia o Chris):** se o jogador sair do Camelô sem comprar nada, a próxima loja tem desconto.
- **Stonks:** investimento de risco com seta de subida e descida a cada conta.
- **Calma, calabreso:** botão no Camelô para "prorrogar o boleto" (ganhar 1 dia por um preço), com a frase no texto. Ou aviso de pânico quando o jogador troca demais.
- **Nome no Serasa:** em vez de perder na hora, o jogador entra no Serasa e perde uma troca por conta até o fim do ano.
- **Cartão Nubank:** esquema que aumenta o cheque especial, mas a dívida cresce mais rápido. Pode se ligar à forma Crédito.
- **13º salário:** bônus fixo em uma conta específica, com o valor no comprovante.
- **"Em setembro vai entrar o grosso":** evento no desafio 3 (Julho a Setembro): uma conta com recompensa grande no fim, anunciada antes.
- **Graciovos:** a definir (a referência ainda não foi explicada).
