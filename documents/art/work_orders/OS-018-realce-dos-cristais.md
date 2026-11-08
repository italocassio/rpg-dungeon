# OS-018: Realce dos cristais

- **Agente:** `gameplay-developer`
- **Depende de:** OS-002
- **Arquivos:** `assets/shaders/ice_crystal.gdshader`, linhas 21 e 23
- **Fora do escopo:** `EMISSION`, `ROUGHNESS`, `ALBEDO`, `pulse`, cores, `glow`, os parâmetros de `DungeonMaterials.crystal`, as luzes de `dungeon_props.gd` e a forma dos cristais. As OS-006 e 008 não tocam neste shader.
- **Estado:** aprovada na rodada 2, com `METALLIC` 0, `ROUGHNESS` 0,3 e `SPECULAR` 0,1. Falta aplicar as linhas 21 e 23 no repositório: o teste só alterou a cópia do render, e o repositório segue em 0,35 e 0,9.

## Problema

Com as normais corretas da OS-002, os cristais passaram a refletir as luzes de verdade. O herói é quente e o Portão é frio (pilar 3). Fogo refletido no gelo quebra essa leitura, e um branco chapado vira a coisa mais forte do quadro.

## Rodada 1: `ROUGHNESS` 0,3

Resolveu a saturação do golem e do cristal do peito do rei, e tirou o ponto estourado da base. Não resolveu a ponta. Alargou o reflexo de fogo em um degradê salmão, e o reflexo frio em uma lavagem pálida na frente do cristal do peito do rei.

Os critérios originais saem. Os 133 pixels do golem não se reproduziram, e a luminância máxima da imagem inteira é inalcançável, porque a chama do braseiro satura em qualquer valor do cristal.

## Diagnóstico

A ponta branca vem do reflexo especular, não da emissão:

- O pixel `(1168,456)`, na mesma face da ponta, vai de `(121,163,208)` com `ROUGHNESS` 0,08 para `(238,248,255)` com 0,3. A emissão não depende desse valor.
- A faixa clara do cristal da direita, em `x = 1404`, é quase só emissão e fica igual: `(142,185,215)` e `(140,184,214)`.
- Pelo ACES do ambiente (exposição 1,05, branco 6), a emissão deste material chega no máximo a cerca de `(185,216,233)`, com `fresnel`, `glow` e `pulse` em 1. O teto bate com a faixa clara medida.
- A parcela da altura pesa pouco: no máximo `(0,005, 0,024, 0,074)` em linear, contra `(0,26, 0,60, 1,0)` vezes `fresnel` na borda.

`ROUGHNESS` não bastou porque o reflexo estava muito acima do branco. O pico caiu, mas o lóbulo cresceu: com 0,08 o branco para em `y ≈ 450`, e com 0,3 ele cobre a face até a aresta, por isso a aresta dura. Na beira da face, o reflexo ainda vale cerca de `(0,63, 2,0, 5,2)` em linear. A fonte provável é a luz fria que fica dentro do conjunto (`dungeon_props.gd:249`), mas isso não foi provado, e a correção não depende disso.

O salmão é o mesmo lóbulo vindo do fogo, estimado em `(0,34, 0,18, 0,11)` em linear. A parte dielétrica do reflexo não recebe a cor do gelo, então a cor da chama passa inteira.

`SPECULAR` sozinho não resolve. Com `METALLIC` 0,35, o reflexo rasante continua forte, porque ele depende do albedo e tem o próprio `METALLIC` como piso. Por isso os dois mudam juntos.

## Mudança

Só estas duas linhas do shader:

```glsl
METALLIC = 0.0;   // linha 21
SPECULAR = 0.1;   // linha 23
```

`ROUGHNESS = 0.3` fica. Pela conta, que é aproximada, o reflexo cai de 15 a 90 vezes, conforme o ângulo. O salmão de `(1240,625)` passaria a cerca de `(57,59,93)`. Com `SPECULAR` 0,2, a queda seria de 5 a 20 vezes, e esse pixel ficaria roxo, em `(98,83,105)`.

Custo aceito: o reflexo do céu quase some, e sobra só um brilho leve nas faces de raspão. O gelo já brilha por dentro, e é a emissão que desenha a face e a borda. Sem `METALLIC`, o difuso sobe 54%, o que não traz calor, porque o albedo é azul.

## Teste

Comparação única com a rodada 1, sem pasta de referência: os números da tabela bastam. Renderize em cópia descartável com a ferramenta da OS-001 e gere `lineup.png`, `world/view_2.png` e `tour/11_combat_crystal_golem.png`. As caixas só valem com o mesmo enquadramento. Se a câmera ou a sala mudarem, pare e avise.

Definições, sobre os valores de 0 a 255 do PNG:

- **Saturado:** `min(R,G,B) >= 250`.
- **Quente:** `R > B + 10`.
- **Azul:** `B >= R + 40` e `B >= 140`.
- **Pálido:** `B >= 190`, `G >= 150` e `R < B`.
- **Caixa:** `(x0,y0,x1,y1)`, com `x1` e `y1` de fora, como no `crop` do PIL.

| Render | Caixa | Medida | 0,08 | Rodada 1 | Rodada 2 | Papel |
|---|---|---|---|---|---|---|
| `view_2` | Ponta `(1150,400,1215,480)` | Saturados | 424 | 349 | Até 20 | Alvo |
| `view_2` | Base `(1190,580,1270,650)` | Quentes | 351 | 955 | Até 50 | Alvo |
| `view_2` | Pixel `(1240,625)` | `B - R` | -36 | -40 | 20 ou mais | Alvo |
| `view_2` | Cristal do meio `(1260,490,1330,570)` | Saturados | 8 | 13 | Até 5 | Alvo |
| `view_2` | Faixa clara `(1398,530,1412,670)` | Pálidos | 1473 | 1470 | 1250 ou mais | Guarda |
| `lineup` | Golem `(1060,325,1205,585)` | Saturados | 10 | 0 | Até 5 | Guarda |
| `lineup` | Golem `(1060,325,1205,585)` | Azuis | 4051 | 4133 | 3500 ou mais | Guarda |
| `lineup` | Peito do rei `(1321,370,1356,393)` | Saturados | 178 | 0 | Até 5 | Guarda |
| `lineup` | Peito do rei `(1321,370,1356,393)` | Azuis | 271 | 220 | 185 ou mais | Guarda |
| `lineup` | Coroa do rei `(1205,215,1395,280)` | Azuis | 1259 | 2207 | 1900 ou mais | Guarda |

Nenhuma caixa inclui o braseiro ou os olhos do rei. Critérios de leitura, em recortes ampliados 3 vezes, a partir de `(1100,380,1480,700)` em `view_2` e `(1200,210,1420,420)` em `lineup`:

- A face da ponta lê como azul, sem branco chapado.
- A face direita do cristal central fica azul do alto à base, sem salmão nem roxo.
- As facetas seguem distintas: face escura, face média e borda clara.
- A frente do cristal do peito do rei fica azul, não lavada.
- Em `tour/11_combat_crystal_golem.png`, os cristais do golem seguem azuis e brilhantes.

Entregue a tabela preenchida e os recortes para a revisão de arte.

## Fechamento

Esta rodada encerra a ordem, sem rodada 3:

- **Alvos e guardas atendidos:** fecha com `METALLIC` 0 e `SPECULAR` 0,1.
- **Guardas atendidas, alvos não, mas ponta abaixo de 349 e base abaixo de 955:** fecha com os mesmos valores e o resíduo fica registrado no guia.
- **Alguma guarda falhou, ou ponta e base não melhoraram:** volte as duas linhas para `METALLIC = 0.35` e `SPECULAR = 0.9`, e feche com a rodada 1. Salmão e ponta branca ficam como resíduo aceito, e o guia registra isso.

## Resultado da rodada 2

**APROVADO, no primeiro caso do fechamento.** Os 4 alvos e as 6 guardas passaram:

| Render | Caixa | Medida | Alvo | Medido |
|---|---|---|---|---|
| `view_2` | Ponta | Saturados | Até 20 | 0 |
| `view_2` | Base | Quentes | Até 50 | 0 |
| `view_2` | Pixel `(1240,625)` | `B - R` | 20 ou mais | 104 |
| `view_2` | Cristal do meio | Saturados | Até 5 | 0 |
| `view_2` | Faixa clara | Pálidos | 1250 ou mais | 1476 |
| `lineup` | Golem | Saturados | Até 5 | 0 |
| `lineup` | Golem | Azuis | 3500 ou mais | 4212 |
| `lineup` | Peito do rei | Saturados | Até 5 | 0 |
| `lineup` | Peito do rei | Azuis | 185 ou mais | 622 |
| `lineup` | Coroa do rei | Azuis | 1900 ou mais | 2228 |

Leitura nos recortes:

- **Ponta:** azul médio, `(34,76,146)` em `(1168,440)`, sem branco. O critério original pedia azul pálido e estava errado: ele veio de um pixel que ainda tinha a cauda do reflexo. Esse azul é o nível real da face sem reflexo, e o texto do critério foi corrigido.
- **Face da frente do cristal grande:** não escureceu. O pixel `(1360,600)` era `(0,13,48)` com 0,08 e na rodada 1, e agora é `(0,12,51)`. É a face escura prevista nos critérios, e não fica como resíduo. O pixel `(1240,625)` é de outra face, a direita do cristal central.
- **Rei:** a lavagem pálida saiu do peito e da coroa, e a borda clara ficou.
- **Ponto claro no `lineup`:** fica em `(1371,259)`, sobre a parede e fora do cristal. Só aparece em um dos renders, e os dois têm pontos claros soltos em lugares diferentes, então é partícula de neve.
- **Golem:** vale `tour_rerun/11_combat_crystal_golem.png`, com cristais azuis e brilhantes. A primeira execução pegou o flash de dano e não serve para cor.

Custo real: os cristais de corredor em `view_0` e `view_4` perderam o reflexo do céu e ficaram um pouco mais escuros. Silhueta e borda clara continuam legíveis, então o custo fica aceito.

Pendência única: aplicar as duas linhas no repositório e rodar `check_scripts`, sem nova revisão de arte.
