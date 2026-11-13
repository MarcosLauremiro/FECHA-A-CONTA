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
| Transações | 8 | 6 (Trocado, Dobradinha, Bolada, Escadinha, Tudo no Pix, Cofrinho) | Parcelado, Pix Premiado |
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

Formas de pagamento ("naipes"): Dinheiro, Pix (o "Pix" do jogo), Débito, Crédito. A sequência de valores segue a ordem das notas: 1-2-5-10-20-50-100-200.

### Transações

| Transação | Combinação | Valor base | Juros base | Juros na tela |
| --- | --- | --- | --- | --- |
| Trocado | 1 carta solta (a maior) | 5 | ×1 | +0% |
| Dobradinha | 2 notas de mesmo valor | 10 | ×2 | +100% |
| Bolada | 3 iguais | 30 | ×3 | +200% |
| Escadinha | 5 valores em sequência | 25 | ×3 | +200% |
| Tudo no Pix | 5 da mesma forma de pagamento | 35 | ×4 | +300% |
| Cofrinho | 4 iguais | 60 | ×7 | +600% |

### Pontuação

```latex
\text{Saldo} = (\text{Valor base} + \sum \text{pontos das notas que pontuam}) \times \text{Juros}
```

Ordem de resolução (importa para a animação e para os esquemas): base da transação → cada nota que pontua, da esquerda para a direita → esquemas da esquerda para a direita (somas de Juros antes, multiplicações depois) → regra do chefe → total.

### Metas e dinheiro

Metas das contas (3 por mês) vêm da curva de dificuldade (ver "Curva de dificuldade" abaixo). Começam em R$ 180 (boleto de janeiro) e crescem 24% a cada conta.

- Recompensa por conta paga: Boleto R$ 3, Aluguel R$ 4, Fatura R$ 5, + R$ 1 por dia não usado.
- **Troco vira grana:** R$ 1 a cada 25% acima da meta, no máximo R$ 5.
- **Cheque especial:** R$ 10 por partida, sem renovar. Cada R$ que passa da carteira vira dívida de 3x e diminui o limite. Gastar o último R$ acaba a partida ("CHEQUE ESPECIAL ESGOTADO"). A cada conta paga, a dívida cresce 25% (arredonda para cima). Com dívida, a recompensa paga a dívida primeiro.
- **Contatos (cartas de uso único):** a cada mês, na loja depois do boleto, aparece um contato por vez, sorteado entre os que faltam, ao lado do SEGUIR. Não ocupam espaço de esquema.
  - **Gerente do Banco** (R$ 15): juros do cheque caem de 3x para 2x.
  - **Cheque Sem Fundo** (R$ 30): juros de 2x e cheque sem limite (o limite vira ∞). Em troca, a dívida pesa: cada R$ 4 de dívida sobe a meta da conta em 1% (`SEM_FUNDO_DEBT_STEP`). Sem essa regra o contato quebrava o jogo: pechinchando e comprando sem parar, o bot vencia 100% das partidas.
- **Painel do baralho:** segurar TAB mostra a grade de cédulas por forma de pagamento e valor. A cor e o número grande são as cédulas que restam (mão e compra); o número pequeno no canto (+n) são as já usadas (jogadas ou trocadas). O botão BARALHO, no canto inferior direito, abre o mesmo painel até o FECHAR.
- Carteira inicial: R$ 4. Máximo de 5 esquemas ativos.
- Os valores de meta são chute inicial; ajustar no playtest da hora 17.

## Conteúdo da jam

A jam tem 8 esquemas, 3 investimentos e 3 chefes. Os esquemas foram escolhidos para formar dois combos claros: "baralho de Pix" (Pix Errado + Cashback + Coach) e "empilhar Juros" (Cunhado + Pirâmide + Agiota).

### Esquemas (cartazes de poste)

Raridade: Comum, Incomum, Rara, Lendária (ver "Raridade dos itens"). Personagens e referências brasileiras em negrito no nome.

| Esquema | Raridade | Efeito | Preço | Texto do cartaz |
| --- | --- | --- | --- | --- |
| Agiota | Comum | +3 de Juros; cobra 10% da carteira a cada conta paga | R$ 8 | EMPRESTO DINHEIRO NA HORA |
| Cashback | Comum | Notas de Crédito que pontuam devolvem R$ 1 | R$ 8 | SEU DINHEIRO DE VOLTA\* |
| Pix Errado | Comum | A primeira nota de Pix jogada em cada conta é duplicada no baralho | R$ 10 | FIZ UM PIX ERRADO, DEVOLVE PFV |
| **Vendedor de Consórcio** | Comum | +5 de Valor por nota de Dinheiro que pontua; cada conta paga custa R$ 1 de parcela | R$ 8 | SUA CARTA SAI NA 60ª PARCELA |
| **Tia do Pix** | Comum | +1 de Juros por nota de Débito que pontua | R$ 8 | MANDA A CHAVE QUE EU PAGO |
| Cunhado Investidor | Incomum | A cada 2 Escadinhas jogadas, +1 de Juros, para sempre | R$ 10 | GANHE 30% AO MÊS SEM RISCO |
| Rifa do Bairro | Incomum | 1 em 4 de multiplicar o Juros por 5 | R$ 10 | RIFA DE 1 PORCO — R$ 2 O NÚMERO |
| Vaquinha | Incomum | Soma metade dos pontos das notas que ficaram na mão ao Valor | R$ 12 | AJUDE O JUNINHO A PAGAR O ALUGUEL |
| **Bicheiro do Bairro** | Incomum | 1 em 3 de cada jogada render R$ 6 na carteira | R$ 12 | JOGO DO BICHO: SAIU O VEADO |
| **Nubank** | Incomum | +3 de Valor por nota de Crédito que pontua | R$ 12 | A ROXINHA QUE MELHORA SEU CRÉDITO |
| **Pastor da Prosperidade** | Rara | +8 de Valor em cada jogada; cada conta paga 5% da carteira de dízimo | R$ 14 | DEUS É FIEL, PAGUE O DÍZIMO |
| Pirâmide | Rara | +1 de Juros por outro esquema ativo; 1 em 6 de colapsar a cada mês | R$ 14 | INDIQUE 3 AMIGOS E FIQUE RICO |
| Coach Financeiro | Rara | ×2 de Juros se as 5 notas jogadas pontuarem; senão, perde 1 de Juros | R$ 14 | MENTALIDADE MILIONÁRIA EM 7 DIAS |
| **Influenciador de Finanças** | Rara | +2 de Juros em jogadas com 3 ou mais notas | R$ 16 | SEGUE QUE EU TE ENSINO A FICAR RICO |
| **Consignado** | Lendária | +1 de Juros em cada jogada; a dívida do cheque especial não cresce | R$ 22 | DINHEIRO NA HORA, SEM CONSULTA AO SERASA |

### Camelô (loja entre contas)

- Oferece 2 esquemas aleatórios + 1 investimento aleatório.
- **Pechinchar** (trocar a oferta): R$ 2.
- **Vender esquema:** devolve metade do preço, arredondado para baixo.
- **Pegar no cheque especial:** botão visível sempre que o jogador não tiver dinheiro para um item.

| Investimento | Raridade | Melhora | Efeito por nível | Preço |
| --- | --- | --- | --- | --- |
| **Poupança** | Comum | Dobradinha | +10 Valor, +1 Juros | R$ 6 |
| **Consórcio** | Comum | Trocado | +8 Valor, +1 Juros | R$ 6 |
| **Tesouro Direto** | Incomum | Escadinha | +20 Valor, +2 Juros | R$ 6 |
| **Previdência Privada** | Incomum | Cofrinho | +30 Valor, +2 Juros | R$ 8 |
| **Carnê** | Incomum | Libera Dois Carnês | +10 Valor, +1 Juros por nível (depois da compra, a formação pontua) | R$ 16 |
| **Fundo de Investimento** | Rara | Bolada | +10 Valor, +1 Juros | R$ 16 |
| **Conta Conjunta** | Rara | Libera Conta Conjunta | +10 Valor, +1 Juros por nível (depois da compra, a formação pontua) | R$ 20 |
| **Duolingo** | Incomum | Recompensa: +R$ 2 por nível em cada conta paga (não muda a pontuação) | R$ 10 |
| **Cripto** | Lendária | Tudo no Pix | +40 Valor, +3 Juros; 1 em 4 de cair um nível em vez disso | R$ 8 |

Investimentos com personagens ou referências: a caderneta do seu Zé (Poupança), o Consórcio da carta contemplada, o Tesouro do tio do churrasco, a Previdência que só resgata na aposentadoria, o Fundo com taxa de gestão, e a Cripto do primo que vive no grupo da família.

### Bateria de esquemas (`tests/sim_esquemas.gd`)

Dois jogadores simulados, com as mesmas sementes:
- **oráculo**: sempre joga a melhor combinação das notas que pontuam e compra no Camelô sempre que pode pagar com folga de R$ 2.
- **humano**: erra 10% das vezes (joga um conjunto aleatório) e compra só 60% das vezes.

Taxa de vitória, ao começar a partida com um item (linha) contra a partida sem nada. Rodada depois de adicionar os 6 esquemas e 2 investimentos novos:

| Cenário | Oráculo | Humano |
| --- | --- | --- |
| Sem nada | 10,8% | 4,0% |
| Agiota | 21,3% | 10,3% |
| Cunhado Investidor | 8,0% | 2,3% |
| Coach Financeiro | 2,8% | 1,3% |
| Pirâmide | 18,8% | 6,5% |
| Cashback | 14,0% | 5,8% |
| Rifa do Bairro | 32,8% | 16,8% |
| Vaquinha | 17,8% | 12,8% |
| Pix Errado | 8,8% | 2,8% |
| Vendedor de Consórcio | 8,3% | 3,0% |
| Tia do Pix | 14,0% | 5,0% |
| Bicheiro do Bairro | 25,0% | 8,5% |
| Pastor da Prosperidade | 11,5% | 6,3% |
| Influenciador de Finanças | 27,3% | 17,8% |
| Consignado | 12,8% | 7,3% |
| Poupança | 16,5% | 7,0% |
| Consórcio | 8,3% | 5,0% |
| Tesouro Direto | 8,3% | 3,8% |
| Previdência Privada | 8,3% | 4,5% |
| Carnê | 23,5% | 10,3% |
| Fundo de Investimento | 15,8% | 9,8% |
| Conta Conjunta | 23,3% | 13,8% |
| Cripto | 8,3% | 3,8% |
| Nubank | 9,0% | 2,3% |
| Duolingo | 17,3% | 6,0% |
| 5 esquemas juntos | 29,3% | 21,3% |

Leitura:
- O "sem nada" caiu de 20% para 11% (oráculo) e de 9% para 4% (humano). A causa: esquemas comprados ao acaso gastam o dinheiro que faria falta para investimentos, e os investimentos são o que mais ajuda (sem nenhum, o oráculo perde tudo). Decidir se a dificuldade deve voltar para algo perto de 20%.
- Tesouro, Consórcio, Previdência e Cripto ficam em 8%: o oráculo escolhe a formação pelo valor base, sem olhar o investimento, então quase nunca joga Escadinha, Cofrinho, Tudo no Pix ou Trocado com o nível. Para medir esses, o bot precisaria escolher a formação pela pontuação final.
- Duolingo é o investimento mais forte da rodada (+10 pontos sobre o sem nada): a recompensa entra em toda conta, então o efeito é grande. Nubank fica perto do sem nada, porque só vale para notas de Crédito. Números desta rodada: sem nada 6,8% (oráculo) e 2,5% (humano); a mudança do Camelô (dois itens novos) mudou a base.
- Influenciador, Rifa e Bicheiro são os mais fortes entre os esquemas. Coach continua armadilha.

### Raridade dos itens

Implementada em `balance.gd` (campo `rarity`, em esquemas e investimentos). No Camelô, a oferta é sorteada com peso pela raridade, sem repetir:

| Raridade | Peso no sorteio |
| --- | --- |
| Comum | 50 |
| Incomum | 30 |
| Rara | 15 |
| Lendária | 5 |

A dica da oferta mostra a raridade ("Pastor da Prosperidade · Rara"). Ainda não há cor de borda por raridade no cartaz.

Arte: os cartazes e ícones dos itens novos ainda não existem em `art/`. Enquanto isso, o esquema aparece como papel com o nome escrito no lugar do desenho, e o investimento aparece como nome no lugar do ícone.

### Chefes: as faturas

Os 3 chefes da jam (Banco fora do ar, Taxa de manutenção e IPVA de janeiro) continuam no jogo, agora dentro do ano de 12 meses. Os 12 chefes, um por mês, e suas regras estão na seção "Partida de 6 meses, 36 chefes sorteados", na parte de planejamento.

## Interface e fluxo de telas

O jogo inteiro acontece dentro de um caixa eletrônico dos anos 90/2000: a tela verde do terminal fica no centro e as notas de papel ficam sobre a "bancada" em primeiro plano. Resolução base 1280×720, escalando por múltiplos inteiros.

### Idiomas e opções

- Idiomas: português (padrão), inglês e espanhol. Os textos ficam em `i18n/textos.csv` (colunas `pt`, `en`, `es`). A chave é o texto em português, e a interface chama `tr("texto em português")`. Sem tradução, aparece o português.
- Valores com moeda continuam "R$" em todos os idiomas, de propósito (o jogo é sobre contas brasileiras).
- Dados em `balance.gd` (nomes, descrições, chefes, meses) são traduzidos no ponto de exibição, com `tr(...)`.
- A arte (cartazes, logo, carimbos) continua com texto em português. Nenhum texto dentro de imagem foi traduzido.
- Opções (botão OPÇÕES no título e no menu de pausa): idioma, música, efeitos sonoros, tela cheia, VSync, limite de quadros por segundo (30, 60, 120 ou sem limite), tremor da tela, e PADRÕES. Ficam em `user://config.cfg`.
- Ao trocar o idioma, o jogo recarrega a cena quando as opções fecham. Dentro de uma partida, a partida é salva antes da recarga.
- Teste: `tests/test_i18n.gd` (todo texto tem os três idiomas; opções salvam e carregam).

### Layout da tela de jogo

- **Moldura do caixa** (fixa): carcaça bege, 4 teclas laterais com setinha de cada lado, fenda de cartão e boca da impressora em cima.
- **Tela do terminal** (centro-alto): nome da conta, meta, saldo atual, dias e trocas restantes, transação detectada com nível. Fonte monoespaçada verde.
- **Faixa de esquemas** (topo): até 5 cartazes lambe-lambe colados lado a lado, levemente tortos.
- **Mão** (embaixo): 8 notas em leque; clique sobe a nota; arrastar reordena.
- **Teclas laterais** = botões: PAGAR, TROCAR, ORDENAR POR VALOR, ORDENAR POR FORMA. Teclado: Enter paga, Espaço troca.
- **Carteira** (canto): R$ em fonte de visor de LCD, vermelha quando negativa.

### Sequência de pontuação (o momento mais importante do jogo)

1. As cartas jogadas sobem acima da mão e ficam lá. Tela mostra "AGUARDE… PROCESSANDO" por 0,4 s.
2. Cada nota que pontua solta seus pontos logo acima dela, com bipe que sobe de tom.
3. Cada esquema ativo balança e mostra seu efeito sobre o cartaz.
4. Juros aparece em % e cresce com som de maquininha de cartão.
5. Total cai no saldo com caixa registradora; a tela treme proporcional ao tamanho do saldo.
6. As cartas jogadas descem para fora da tela, e a mão é reposta.
7. Acima de 5× a meta: o comprovante sai gigante, atravessando a tela.

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
- [ ] Implementar os 8 esquemas, na ordem: Agiota, Coach, Rifa, Cashback, Vaquinha, Cunhado, Pirâmide, Pix Errado
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
| A3 | Frente das notas | Papel texturizado com bicho: R$ 1 sabiá (moeda), R$ 2 tatu, R$ 5 quati, R$ 10 bicho-preguiça, R$ 20 tamanduá, R$ 50 capivara, R$ 100 boto-cor-de-rosa, R$ 200 jacaré | 120×224 | 8 | P1 | Hora 10 |
| A4 | Selos de forma de pagamento | Carimbo para Dinheiro, Pix, Débito, Crédito | 40×40 | 4 | P1 | Hora 10 |
| A5 | Verso da nota | Padrão de papel-moeda genérico | 120×224 | 1 | P1 | Hora 10 |
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
| S8 | "Pix recebido" (notificação de celular inventada) | Cashback e troco | P2 |
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
| Avaliador de transações com bug | Hora 7 sem conta jogável | Lançar só Trocado, Dobradinha, Bolada e Tudo no Pix; Escadinha depois |
| Balanceamento impossível | Ninguém passa do mês 2 no playtest | Baixar metas em 30% no `balance.gd` |
| Export web falha | Áudio mudo ou tela preta no navegador | Testado na hora 1; manter build Windows como plano B |
| Arte atrasa | P1 não entregue na hora 14 | Placeholder fica; arte entra até a hora 19 |
| Cansaço | Erro bobo repetido | Dormir 2 horas entre as horas 18 e 21, depois do congelamento |

### Cuidados legais

- **Notas inventadas:** nada de reproduzir cédulas reais do Real; bichos, cores e layout próprios.
- **"Pix":** é marca do Banco Central, então a jam usa "Pix". Consultar advogado antes de usar o nome numa versão comercial.
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

### Partida de 6 meses, 36 chefes sorteados

O ano tem 12 meses, mas uma partida dura 6 (`RUN_MONTHS`): começa em janeiro e é vencida ao pagar a fatura de junho. Quem vence pode continuar no modo infinito (botão CONTINUAR ∞ no comprovante final), até perder ou derrotar os 36 chefes (`TOTAL_MONTHS`, 3 anos de jogo; a partir do segundo ano o mês aparece com o número, ex.: "Janeiro 2").

- A partida tem 6 meses × 3 contas (Boleto, Aluguel, Fatura) = 18 contas.
- Cada mês tem **um chefe**, que aparece só na fatura (a 3ª conta do mês). Boleto e Aluguel são contas comuns.
- O chefe é sorteado quando o mês começa e não se repete na partida. A Banca mostra o chefe do mês (CHEFE DO MÊS) antes da fatura.
- **Faixas de peso** (`BOSS_TIERS`): meses 1 e 2 sorteiam chefes leves, 3 e 4 médios, 5 e 6 pesados. No modo infinito vale qualquer faixa.
- **Chefes com data** (`BOSS_FIXED_MONTH`) só caem no mês deles: Dia das Mães (maio), Dia dos Pais (agosto), Entrar o Grosso (setembro) e 13º salário (dezembro). Na partida de 6 meses, maio é sempre Dia das Mães.
- **Dificuldade adaptativa** (`BOSS_SCALE`): o nível do chefe é o mês dividido por 2 (0 a 3). Sete chefes usam um número por nível, mostrado no texto da regra.
- O jogo salva a cada conta (save único), então a partida pode ser retomada em sessões de qualquer tamanho.

| Faixa | Chefe | Regra |
| --- | --- | --- |
| Leve | Bolsa Família | +R$ 3 ao pagar a fatura, mas a meta sobe 15% |
| Leve | Taxa de manutenção | Cada troca custa R$ 1 |
| Leve | Julius | Se você não comprou nada na Banca antes da conta, a meta cai 20% |
| Leve | Urubu do Pix | No começo da conta, 1 em 2: a carteira dobra. Se não, perde R$ 5 |
| Leve | Curso do Primo Rico | Matrícula de R$ 6, uma vez. A cada 2 contas pagas depois, o Valor sobe 10% |
| Leve | Maquininha quebrada | Notas de Débito não pontuam |
| Leve | Cartão clonado | Notas de Crédito não pontuam |
| Leve | Caixa sem troco | Notas de Dinheiro não pontuam |
| Leve | Troco em bala | Notas de R$ 1, 2 e 5 não pontuam |
| Leve | Nota falsa | Notas de R$ 200, 500 e 1000 não pontuam |
| Leve | Fila da lotérica | Uma troca a menos |
| Leve | Boleto vencido | A primeira jogada vale metade |
| Leve | Dia das Mães (só em maio) | A recompensa da conta cai pela metade |
| Médio | Banco fora do ar | Notas de Pix não pontuam |
| Médio | Férias na praia | A mão tem 6 cartas, em vez de 8 |
| Médio | Bandeira vermelha | Cada dia usado custa R$ 1. Notas de Débito pontuam 50% a mais |
| Médio | 13º salário (só em dezembro) | A recompensa sobe R$ 3, mas a meta sobe 25% |
| Médio | Feriadão | 3 dias, em vez de 4 |
| Médio | Inflação | Cada jogada sobe a meta em 4 / 5 / 6 / 8% (por nível) |
| Médio | Reajuste do aluguel | A meta sobe 20 / 30 / 35 / 45% |
| Médio | Apagão | A prévia da jogada não aparece |
| Médio | Carnaval | Depois de cada jogada, a mão inteira é descartada e comprada de novo |
| Médio | Serasa | Com carteira negativa, a meta sobe 30 / 40 / 50 / 60% |
| Médio | Golpe do falso gerente | No começo da conta, some 20 / 25 / 30 / 40% da carteira |
| Médio | Black Friday | A meta sobe 20%, mas a próxima Banca vende tudo pela metade |
| Pesado | IPVA + IPTU + Material escolar | Leão leva 15% de cada jogada. Cada troca custa R$ 1. Um esquema desativado na conta |
| Pesado | Dia dos Pais (só em agosto) | Cada troca consome um dia |
| Pesado | Entrar o Grosso (só em setembro) | A meta dobra e a recompensa dobra |
| Pesado | Fatura parcelada | Cada jogada conta no máximo 50 / 45 / 40 / 35% da meta |
| Pesado | Malha fina | A formação mais jogada na partida não pontua |
| Pesado | Rotina | Cada formação só pode ser jogada uma vez na conta |
| Pesado | Sogra em casa | Só pontua jogada com 5 notas |
| Pesado | Tigrinho | Cada jogada: 1 em 2 de dobrar; senão, vale metade |
| Pesado | Wi-Fi caiu | Os esquemas não funcionam nas 2 / 2 / 2 / 3 primeiras jogadas |
| Pesado | Plano Collor | No começo da conta, 60 / 70 / 80 / 90% da carteira é confiscada |
| Pesado | Copa do Mundo | 2 dias e 1 troca |

### Curva de dificuldade

A meta de cada conta segue `D(n) = D0 · R^(n-1)` (em `scripts/balance.gd`, `goal_of`):

- `D0` = 180: meta da primeira conta (boleto de janeiro).
- `R` = 1,24: fator de crescimento por conta. A fatura de junho fica em R$ 6.980.
- `n` = número da conta, de 1 (boleto de janeiro) a 18 (fatura de junho). No modo infinito a mesma curva continua até a 36 (fatura de dezembro).

Ajuste feito pela bateria `tests/sim_balance.gd` (200 partidas por linha), com três perfis de jogador:

- **novato**: erra 10% das jogadas e compra 60% do que pode pagar. Vence 0% (5 contas pagas em média).
- **oráculo**: joga a melhor formação da mão, sem olhar os esquemas. Vence 0% (6 contas).
- **esperto**: testa todos os conjuntos de 1 a 5 notas na prévia e joga o que mais rende; compra tudo que pode. Vence 12,5% (12 contas).

Objetivo: quem joga pela primeira vez não fecha os 6 meses, e quem domina o jogo vence uma em cada oito partidas. A curva é sensível: com R = 1,20 o esperto vencia 31%, e com 1,26, menos de 1%.

Com um esquema desde o começo, o esperto vence entre 8% e 27% (Agiota 27%, Cunhado 25%, Influenciador 23%; Pix Errado 8%, Coach 10%). Antes do ajuste, Coach (93%), Cunhado (81%) e Influenciador (80%) dominavam. Mudanças:

- Coach: o ×2 só vale quando as 5 notas jogadas pontuam (antes bastava completar a jogada com notas quaisquer).
- Cunhado: +1 de Juros a cada 2 Escadinhas (antes, a cada uma).
- Influenciador: +2 de Juros (antes +3).
- Vendedor de Consórcio: +5 de Valor por nota de Dinheiro (antes +3).

Cheque especial e contatos: o bot que usa o cheque sempre que pode vence 0%, então o cheque é um recurso de emergência, não um plano. O Cheque Sem Fundo sem a regra da dívida vencia 100% (pechinchando sem parar); com a regra, o abuso cai para 4,5%. O bot não sabe usar o cheque com moderação, então o valor real dos contatos depende de teste com jogadores.

### Conquistas

- Lista de conquistas com nome, texto e condição (ex.: "Pagou uma conta sem trocar nenhuma nota", "Ficou no Serasa e ganhou mesmo assim").
- Mostradas no menu de pausa e numa tela própria.
- Condições a definir por desafio.

### Raridade dos esquemas

- Implementada: ver "Raridade dos itens" acima. Falta só a cor da borda ou etiqueta no cartaz.

### Clareza da mão

Hoje o jogador não sabe se a mão vai bater a meta antes de pagar. A ideia é mostrar, ao selecionar as notas:

- o nome da formação (já existe);
- Valor e Juros da formação, no formato da contagem (ex.: "Dobradinha · VALOR 24 · JUROS x2", com cartaz e Leão quando houver). Já implementado: a prévia usa as mesmas regras do PAGAR;
- a pontuação estimada da jogada (Valor e Juros), com os esquemas e investimentos que se aplicam;
- quanto falta para a meta, ou se a jogada já bate a meta;
- a explicação de cada esquema e de cada chefe ao passar o mouse (já existe em parte, falta padronizar).

### Tutorial

- Botão "COMO JOGAR" na tela inicial abre um tutorial em 7 páginas (antes era uma tela só com a tabela de formações). Ainda não é possível abrir pelo menu de pausa (Esc); fica como pendente.
- Páginas: O objetivo, Suas notas (com exemplo de selos), As formações (tabela), Como se pontua (exemplo com conta), Dias e troco, O Camelô, Os chefes.
- Navegação: ANTERIOR, PRÓXIMO, CONCLUIR e FECHAR (sempre visível). Texto e tabela escritos à mão, sobre papel de caderno desenhado em código.

### Combinações e cartas que mudam a regra (em planejamento)

Decisões tomadas:

- **Conta Conjunta** é o full house (trinca + par, 5 notas). Assim não conflita com o Par, que é a Dobradinha.
- **Cesta Básica** é 5 valores diferentes, sem sequência. Não aparece como jogada comum: fica ativável por cartas no meio da partida, e tem raridade maior.
- **Dois Carnês** (dois pares, 4 notas, base 15 × Juros 2) e **Conta Conjunta** (trinca + par, base 35 × Juros 3) são formações liberadas por investimento no Camelô: **Carnê** (R$ 16) e **Conta Conjunta** (R$ 20). Antes da compra, não pontuam.
- **Fundo de Investimento** (R$ 16): sobe a Bolada (+10 de Valor e +1 de Juros por nível).
- **PIX** (sequência da mesma forma, topo da tabela) continua como proposta, não aprovada.
- Simulação (`tests/sim_combos.gd`, 30 mil mãos): com as duas formações liberadas, Dois Carnês vira a melhor jogada em 41% das mãos (dois pares são comuns), e a Conta Conjunta em 21%. A Bolada cai para 6%, porque a Conta Conjunta assume as mãos de trinca com par. Isso é esperado, já que a Conta Conjunta vale mais que a Bolada.
- Bateria de partidas inteiras (`tests/sim_esquemas.gd`, 400 partidas por cenário): ver a seção "Bateria de esquemas" abaixo. O número antigo do bot guloso não vale mais como referência.
- **Truco mineiro:** descartado.

Cartas que mudam a dinâmica (aprovadas para desenho, valores a definir):

- **Nota Falsa:** vale como qualquer valor e forma, mas rende menos pontos.
- **Cheque Pré-datado:** os pontos da jogada só entram na conta seguinte.
- **Mutirão:** combinação de 4 notas conta como se tivesse 5.
- **Fiador:** protege da negativação uma vez por partida.
- **Juros Compostos:** cada combinação feita aumenta o Juros de forma permanente, na partida.

Resultados da simulação (`tests/sim_combos.gd`, 50 mil mãos de 8 notas, regras atuais, melhor jogada possível):

Antes do ajuste (Escadinha 30×4 = 120):

- Melhor jogada: Dobradinha 43,7%, Escadinha 25,2%, Bolada 25,0%, Tudo no Pix 4,6%, Cofrinho 1,5%, Trocado 0%.

Depois do ajuste (Escadinha 25×3 = 75, abaixo da Bolada 90):

- Melhor jogada: Dobradinha 43,7%, Bolada 28,2%, Escadinha 22,0%, Tudo no Pix 4,6%, Cofrinho 1,5%, Trocado 0%. Pontos médios da melhor jogada: 22,7.
- Presença em alguma jogada de 5 notas: algum par 99,4%, Conta Conjunta 23,0%, Dois Carnês 78,9%, Cesta Básica 90,1%, Cesta Básica barata 64,3%, PIX 0,4%.

Decisões do ajuste de balanceamento:

- **Escadinha** agora perde para a Bolada (3 iguais) e só vence a Dobradinha. Antes ela ganhava da Bolada em todas as mãos com sequência e trinca.
- **Trocado** nunca é a melhor jogada porque quase toda mão de 8 notas tem par (99,4%). Fica como fallback: uma carta solta só se o jogador escolher jogar uma nota.
- **Cesta Básica** sai da mão comum. Ela só é ativada por carta no meio da partida, então a frequência natural não define o jogo. A variante "cesta barata" (64%) continua alta demais para ser regra fixa, e fica para decidir com a carta que a ativa.
- **Conta Conjunta** ainda não tem base e Juros. Proposta: base 35, Juros ×3 (105), acima da Bolada (90) por exigir 5 notas, e abaixo do Cofrinho (420). Não aplicada ainda.
- Para rodar: `godot --headless --path . -s res://tests/sim_combos.gd` (cerca de 2 minutos com 50 mil mãos).

### Ideias de memes e referências (em aberto)

Ideias que já viraram chefe (Julius, 13º salário, Entrar o Grosso) estão na seção "Partida de 6 meses, 36 chefes sorteados". As outras seguem em aberto: ao escolher, cada uma vira uma regra nova ou um texto no jogo.

- **Nazaré Confusa:** chefe ou evento em que as notas da mão aparecem com o valor escondido até pagar ou trocar.
- **Julius (Todo Mundo Odeia o Chris):** se o jogador sair do Camelô sem comprar nada, a próxima loja tem desconto.
- **Stonks:** investimento de risco com seta de subida e descida a cada conta.
- **Calma, calabreso:** botão no Camelô para "prorrogar o boleto" (ganhar 1 dia por um preço), com a frase no texto. Ou aviso de pânico quando o jogador troca demais.
- **Nome no Serasa:** em vez de perder na hora, o jogador entra no Serasa e perde uma troca por conta até o fim do ano.
- **Cartão Nubank:** esquema que aumenta o cheque especial, mas a dívida cresce mais rápido. Pode se ligar à forma Crédito.
- **13º salário:** bônus fixo em uma conta específica, com o valor no comprovante.
- **"Em setembro vai entrar o grosso":** evento no desafio 3 (Julho a Setembro): uma conta com recompensa grande no fim, anunciada antes.
- **Graciovos:** a definir (a referência ainda não foi explicada).
