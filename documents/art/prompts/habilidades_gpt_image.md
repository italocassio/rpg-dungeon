# Prompts de imagem dos ícones de habilidade (GPT Image)

Versão 1.0, 08/11/2026. Documento de apoio da direção de arte, irmão de `itens_gpt_image.md`. Gera 19 ícones: as 18 habilidades de classe (6 por classe, na ordem do slot) e a Esquiva do hotbar. Segue `documents/art/style_guide.md` e fica abaixo dele; o guia não foi alterado. Fora do escopo: habilidades de monstro e de chefe (`mon_*`, `boss_*`), a Guarda do botão direito (`shield`) e as poções do hotbar, que têm ilustração no documento de itens.

Os textos são em português. Os blocos dentro de caixas de código são prompts em inglês, porque o modelo os segue melhor. Os nomes das habilidades ficam em português nos títulos.

## Formato do ícone (decisão)

**O ícone é um recorte em fundo transparente, e não um quadrado com fundo pintado. Ele é um glifo claro em tons de cinza, sem cor.** O motivo é como a UI desenha:

| Onde | Tamanho | O que a UI pinta | Como o ícone entra |
|---|---|---|---|
| Barra de habilidades e árvore de habilidades (`SkillSlot`) | slot de 58 px, ícone de 42 px (`area.grow(-8)`) | fundo `skill.color × 0,13`, borda de bronze de 1,5 px | `draw_texture_rect` **multiplicado** por `skill.color.lightened(0,3)`, com 40% de opacidade quando falta mana ou Chi |
| Lista de habilidades no saguão (`icon_tile`) | quadro de 38 px, ícone de cerca de 27 px | fundo `skill.color × 0,16`, borda na cor da habilidade | `modulate = skill.color.lightened(0,25)` |
| Cartão de habilidade (`skill_card`) | quadro de 46 px, ícone de cerca de 33 px | igual ao do saguão | igual ao do saguão |

Três consequências, que moldam todos os prompts:

1. **Sem fundo.** A UI já pinta o fundo, a borda e a cor. Um fundo pintado na imagem ficaria duplicado, mudaria de cor ao ser multiplicado e esconderia a borda de bronze.
2. **A cor da habilidade não entra na imagem: entra pela UI.** Como a UI multiplica, uma imagem colorida sairia suja (cor ao quadrado). A imagem é um glifo claro em cinza neutro (massa `F2F4F8`, facetas sombreadas `B4B9C4`, cortes fundos `6B7280`), e a UI o pinta com `skill.color.lightened(0,3)`. Cada entrada traz a cor da habilidade, a cor que o glifo ganha na barra e o fundo do slot, para conferir o resultado. Se um dia a UI deixar de modular o ícone, o bloco "Variante colorida" em "Como usar" troca só o parágrafo de valores.
3. **Leitura com a sobreposição de recarga.** A recarga desenha por cima um setor preto de 68% de opacidade, que varre o slot inteiro, e um número branco de 20 px, com contorno preto, no centro um pouco abaixo da metade. A tecla (13 px, com contorno) fica no canto superior esquerdo. Por isso: a identidade fica no contorno externo e não no miolo; o canto superior esquerdo (30% de largura por 20% de altura) fica sem detalhe fino; e o glifo nunca é mais escuro que 42% da cor da barra, para continuar mais claro que o fundo (13%) mesmo com o setor preto por cima.

## Como usar

1. Monte cada pedido na ordem: **bloco de estilo** (seção 1), depois o **prompt da habilidade**, depois o **bloco de restrições** (seção 2). Os três juntos são autossuficientes: nenhum prompt depende de imagem de referência nem de outro prompt.
2. Configuração no GPT Image: 1024 × 1024, qualidade alta, PNG, fundo transparente (na API, `background: transparent`). Gere de 2 a 3 candidatas por habilidade e escolha a melhor.
3. Plano B se a ferramenta não der canal alfa: acrescente ao fim do pedido `Background: one flat solid pure green #00FF00, no gradient, no shadow.` e recorte o verde depois. O glifo é cinza, então não há conflito de cor.
4. Depois de aprovar, reduza para 128 × 128 (filtro Lanczos); o jogo hoje carrega os SVG de 96 × 96. Nomeie o arquivo com o `id` da habilidade (`w_slash.png`). Este documento não decide onde o arquivo entra no projeto nem como o carregador troca SVG por PNG.
5. Gere as seis de uma classe em sequência e confira as seis lado a lado, a 40 px, em preto sólido (a silhueta tem de distinguir cada uma).
6. O modelo aproxima os valores de cinza. Confira com conta-gotas: nenhum pixel com saturação acima de 5%, a massa principal perto de `F2F4F8` e nada mais escuro que `6B7280`.
7. **Variante colorida** (só se a UI deixar de multiplicar o ícone): troque o parágrafo `VALUES` do bloco de estilo por este, preenchendo `{HEX}` com a cor da habilidade da entrada.

```text
COLOR MODE (replaces only the VALUES paragraph, and only if the game stops tinting the icon; replace {HEX} with the skill color of the entry): draw the glyph in the hue of #{HEX}: main mass that hue lightened 30 percent, shaded facets that hue as is, deepest cuts that hue darkened 45 percent. No other hue, no gradient.
```

## Índice

| # | id | Nome | Grupo |
|---|---|---|---|
| 01 | `w_slash` | Corte | Guerreiro |
| 02 | `w_charge` | Investida | Guerreiro |
| 03 | `w_whirl` | Giro de Lâminas | Guerreiro |
| 04 | `w_warcry` | Grito de Guerra | Guerreiro |
| 05 | `w_seismic` | Corte Sísmico | Guerreiro |
| 06 | `w_monarch` | Lâmina do Portão | Guerreiro |
| 07 | `m_bolt` | Seta Arcana | Mago |
| 08 | `m_fireball` | Bola de Fogo | Mago |
| 09 | `m_icelance` | Lança de Gelo | Mago |
| 10 | `m_meteor` | Meteoro | Mago |
| 11 | `m_blink` | Piscar | Mago |
| 12 | `m_nova` | Nova Elemental | Mago |
| 13 | `p_smite` | Luz Sagrada | Sacerdote |
| 14 | `p_heal` | Cura | Sacerdote |
| 15 | `p_circle` | Círculo Sagrado | Sacerdote |
| 16 | `p_bless` | Bênção | Sacerdote |
| 17 | `p_judgement` | Julgamento | Sacerdote |
| 18 | `p_miracle` | Milagre | Sacerdote |
| 19 | `dodge` | Esquiva | Comum |

## 1. Bloco de estilo comum

Cole este bloco **antes** de qualquer prompt de habilidade.

**Resumo para você:** 1024 × 1024, quadrado, fundo transparente, um glifo centrado a 88% do quadro, em três tons de cinza (`F2F4F8`, `B4B9C4`, `6B7280`), com relevo facetado de luz no alto à esquerda e sem contorno. Detalhe mínimo de 7% do quadro, para ler a 42 px (barra) e a 27 px (saguão). A forma carrega a identidade, e a cor vem da UI. Em relação ao 3D: o glifo não é uma peça do modelo, mas fala a mesma língua do guia (forma antes de cor, facetas retas, acabamento limpo, sem sujeira).

```text
STYLE (applies to the whole image): a single skill icon glyph for the HUD of a dark-fantasy hunter-and-gates RPG. It is a bold, clean, flat-faceted emblem drawn only in light neutral grays, because the game tints it with a color at runtime. Silhouette first: the shape must be recognizable as a plain solid cutout. Inner structure is carved by shading steps, never by outlines or fine lines. Mood: sober, heroic, hunter-gear iconography. Hard-surface faceted planes like a low-poly relief; no painterly noise, no texture, no dirt.
CANVAS: square 1:1, 1024 x 1024 px, transparent background (PNG with alpha), no backdrop, no tile, no frame, no badge, no border. The final use is a 42 px icon, down to 27 px.
FRAMING: exactly one emblem, centered, filling about 88 percent of the canvas along its longest side, margin of about 6 percent, never cropped. Keep the top-left corner (the first 30 percent of the width and 20 percent of the height) free of fine detail: the game writes the key letter there. The identity of the icon must live in its outer silhouette, because a countdown number covers the central band during the cooldown.
VALUES (grayscale only, zero color saturation): main mass #F2F4F8; shaded facets #B4B9C4; deepest cuts and dark secondary shapes #6B7280. The main mass is at least 60 percent of the glyph's area. No pure white, no pure black, nothing darker than #6B7280, no color tint anywhere (the game multiplies the glyph by the skill color). Cut-outs the prompt calls transparent are fully see-through.
SIZE RULES: every stroke, gap, cut and detail is at least 7 percent of the canvas (about 3 px at 42 px); anything smaller must be dropped; separate shapes are at least 7 percent apart; at most 4 separate shapes in total; at most 3 values.
LIGHT: faceted relief lit from the upper left: upper-left planes #F2F4F8, lower-right planes #B4B9C4, flat steps with no gradients, no soft glow, no bloom, no drop shadow.
EDGES: crisp, with slightly rounded corners (radius about 1.5 percent), no outline stroke around the shape.
EMISSION: nothing glows; the glyph is a flat emblem, not a light.
```

## 2. Bloco de restrições comum

Cole este bloco **depois** do prompt da habilidade. Ele cobre O1 e O2, as proibições de cor e de moldura (a UI cuida disso) e o pilar 5 do guia.

```text
DO NOT INCLUDE: any text, letters, numbers, runes, glyphs, labels or watermarks; any background, tile, frame, border, badge, card, plate, vignette, floor or backdrop shape; any color (no hue, no tint, no colored glow: neutral gray values only); any glow, aura, halo, sparkle, particles, light rays, lens flare, motion blur or smoke; any drop shadow or outline stroke; any real religious symbol: no cross of any kind (Latin cross, Greek cross, plus sign, cross inside a ring, two bars crossing at right angles; the plain crossguard of a sword is allowed), no crescent or moon shape, no six-pointed star or Star of David, no om, no dharma wheel, no torii, no yin-yang, no mitre, no dove, no praying hands; no hands, fingers, faces, eyes, skulls, characters, people or animals; no crown; no glossy 3D render, no photorealism, no painterly noise; no thin lines or tiny details under 7 percent of the canvas; no design, character, emblem, weapon or logo from any existing game, anime, comic or film, in particular nothing from Perfect World or Solo Leveling (no shadow soldiers, no purple smoke, no paired daggers, no monarch crown). If the item prompt explicitly asks for something listed here, the item prompt wins for that thing only.
```

## 3. Guerreiro (6 habilidades)

### Abertura: as seis do Guerreiro

Classe: cor de classe `E0603A`, que entra só no Selo; na barra, cada habilidade usa a cor do próprio `.tres`. Linguagem de forma: massa pesada, traço grosso (10% a 16% do quadro), facetas cortadas em linha reta, direção de ação para a direita ou para cima.

| Slot | id | Nome | Silhueta a 40 px | Cor |
|---|---|---|---|---|
| Básico | `w_slash` | Corte | diagonal fina, espada com guarda | `CFE4FF` |
| 1 | `w_charge` | Investida | seta larga na horizontal, com 2 barras atrás | `FF6A3C` |
| 2 | `w_whirl` | Giro de Lâminas | anel de 2 arcos-seta, centro vazio | `FFD27A` |
| 3 | `w_warcry` | Grito de Guerra | cone aberto com 2 arcos à direita | `FFB35A` |
| 4 | `w_seismic` | Corte Sísmico | seta vertical sobre faixa de chão rachado | `FFA34A` |
| Suprema | `w_monarch` | Lâmina do Portão | espada larga atravessando um anel oval alto | `7CC6FF` |

Pares que a cor não separa: Giro de Lâminas e Corte Sísmico (laranjas próximos) se separam por forma (anel contra faixa com seta); Corte e Lâmina do Portão (as duas têm espada) se separam pelo anel, pela largura da lâmina e pela direção (ponta para cima e para a direita, contra ponta para baixo e para a esquerda).

### 01. Corte

- **id:** `w_slash`
- **Nome:** Corte
- **Classe:** Guerreiro
- **Slot:** Básico (botão esquerdo do mouse)
- **No jogo:** Cone corpo a corpo de 110° e 3,6 m, Metal, físico, recarga 0,62 s, gera 14 Chi.
- **Cor da habilidade:** `CFE4FF`. Na barra o glifo fica `DDECFF` (`lightened(0,3)`) sobre o fundo `1B1E21`.
- **O símbolo atual:** Espada diagonal com a ponta no canto superior direito e guarda reta perpendicular à lâmina (`slash.svg`, o ícone padrão: o `.tres` não define `icon`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. A guarda reta da espada é a única travessa permitida da classe.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a single straight longsword drawn on a diagonal, point toward the upper right, with two short straight speed streaks beside it. The warrior's basic slash.
COMPOSITION: square canvas. The sword axis runs at 45 degrees from the pommel at the lower left (about 15 percent from the left, 87 percent from the top) to the point at the upper right (about 90 percent from the left, 10 percent from the top). The top-left corner stays empty.
BLADE: broad flat blade about 12 percent of the canvas wide at its base, tapering to a sharp point, about 55 percent of the sword length; a central ridge splits it in two values: the upper-left half in #F2F4F8 and the lower-right half in #B4B9C4.
HILT: one plain straight crossguard bar, 36 percent of the canvas long and 8 percent thick, perpendicular to the blade, placed at about 30 percent of the way from the pommel to the point, light value #F2F4F8 on its upper face and #B4B9C4 on its lower face; a short grip about 14 percent long and 7 percent wide in #B4B9C4; a round ball pommel about 10 percent across in #F2F4F8.
STREAKS: two short parallel straight bars on the lower-right side of the blade, parallel to it, each 6 percent thick and about 24 percent long, each separated from the blade and from each other by a gap of at least 7 percent, in #B4B9C4. They are plain bars, not curves.
GLOW: nothing glows.
```

### 02. Investida

- **id:** `w_charge`
- **Nome:** Investida
- **Classe:** Guerreiro
- **Slot:** 1
- **No jogo:** Avanço (dash) de até 13 m contra o alvo; atordoa num raio de 2,6 m na chegada; Metal, físico, poder 1,5, recarga 9 s, custa 14 de mana, gera 20 Chi.
- **Cor da habilidade:** `FF6A3C`. Na barra o glifo fica `FF9777` (`lightened(0,3)`) sobre o fundo `210E08`.
- **O símbolo atual:** Seta larga apontando para a direita, com duas barras horizontais de velocidade atrás dela (`charge.svg`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. Direção de ação sempre para a direita ou para cima.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a very bold, wide arrow pointing to the right with two flat speed bars behind it: a shield-first charge.
COMPOSITION: square canvas, everything centered on the horizontal axis at about 52 percent from the top. The arrow shaft is a thick block from 30 percent to 60 percent from the left, 24 percent tall (from 40 to 64 percent from the top), with a squared-off tail end. The arrowhead is a big triangle from 58 percent to 96 percent from the left, 58 percent tall (from 23 to 81 percent from the top), its point at the right edge of the margin at 52 percent from the top.
SPEED BARS: two flat horizontal bars at the left, each 8 percent thick and 22 percent long, from 5 to 27 percent from the left: one at about 32 percent from the top and one at about 72 percent from the top; each separated from the shaft by a gap of at least 7 percent. The top-left corner stays empty.
VALUES: the upper half of the shaft and of the arrowhead in #F2F4F8, the lower half in #B4B9C4, split along the horizontal axis; the two speed bars in #B4B9C4.
GLOW: nothing glows.
```

### 03. Giro de Lâminas

- **id:** `w_whirl`
- **Nome:** Giro de Lâminas
- **Classe:** Guerreiro
- **Slot:** 2
- **No jogo:** Área ao redor do guerreiro, raio de 5,4 m, Metal, físico, poder 1,7, recarga 7 s, custa 16 de mana, gera 18 Chi.
- **Cor da habilidade:** `FFD27A`. Na barra o glifo fica `FFDFA2` (`lightened(0,3)`) sobre o fundo `211B10`.
- **O símbolo atual:** Dois arcos-seta formando um anel quase fechado, com o centro vazio (`whirl.svg`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. As pontas de seta são pontas de lâmina, triangulares e duras.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: two thick circular arrows chasing each other around a ring, clockwise, with an empty open center: a spinning blade attack.
COMPOSITION: square canvas, the ring centered at 50 percent and 50 percent, outer diameter about 88 percent of the canvas, ring thickness about 15 percent, the center completely empty (transparent).
ARCS: arc A runs clockwise from about the 11 o'clock position to about the 4 o'clock position and ends in a sharp, hard triangular arrowhead (blade-tip shaped) pointing clockwise, wider than the ring band by about 8 percent on each side. Arc B runs clockwise from about the 5 o'clock position to about the 10 o'clock position and ends in the same kind of arrowhead. Each arc starts with a flat straight-cut tail. The two gaps between an arrowhead and the next arc's tail are at least 7 percent of the canvas wide. Nothing touches.
VALUES: the outer half of each arc band in #F2F4F8 and the inner half in #B4B9C4, so the band reads as a faceted ridge; the arrowheads in #F2F4F8.
GLOW: nothing glows.
```

### 04. Grito de Guerra

- **id:** `w_warcry`
- **Nome:** Grito de Guerra
- **Classe:** Guerreiro
- **Slot:** 3
- **No jogo:** Área ao redor do guerreiro, raio de 14 m, provoca os inimigos (ameaça x4) e dá bônus de defesa ao grupo; suporte, recarga 14 s, custa 10 de mana, gera 25 Chi.
- **Cor da habilidade:** `FFB35A`. Na barra o glifo fica `FFCA8C` (`lightened(0,3)`) sobre o fundo `21170C`.
- **O símbolo atual:** Corneta de cone aberto para a direita (parece um alto-falante) com duas ondas sonoras em arco (`shout.svg`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. As ondas são arcos de círculo grossos de pontas retas.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a flared war horn blasting to the right, with two concentric sound arcs: the warrior's battle shout.
COMPOSITION: square canvas. The horn: a short squared mouthpiece block at the left (from 5 to 19 percent from the left, 42 to 60 percent from the top) that widens into a big straight-sided cone flaring to the right, ending in a flat vertical rim at 50 percent from the left that spans from 16 to 84 percent from the top; the rim is 8 percent thick. The top-left corner stays empty.
SOUND ARCS: to the right of the rim, two concentric circular arcs centered on the middle of the rim (50 percent, 50 percent): the inner arc with its outer radius at 22 percent of the canvas, the outer arc with its outer radius at 38 percent of the canvas, each arc 8 percent thick and spanning about 80 degrees centered on the horizontal axis, with flat straight-cut ends. The gap between the rim and the inner arc is at least 7 percent, and so is the gap between the two arcs.
VALUES: the upper half of the cone in #F2F4F8 and the lower half in #B4B9C4, split along the horizontal axis; the rim and the mouthpiece in #F2F4F8; both arcs in #F2F4F8.
GLOW: nothing glows.
```

### 05. Corte Sísmico

- **id:** `w_seismic`
- **Nome:** Corte Sísmico
- **Classe:** Guerreiro
- **Slot:** 4
- **No jogo:** Linha reta de 11 m e 3,4 m de largura, Terra, físico, poder 2,5, conjuração 0,3 s, recarga 10 s, custa 22 de mana.
- **Cor da habilidade:** `FFA34A`. Na barra o glifo fica `FFBF80` (`lightened(0,3)`) sobre o fundo `21150A`.
- **O símbolo atual:** Seta grossa para baixo sobre uma faixa de chão rachado e recortado (`quake.svg`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. Peças separadas por vão de 7% ou mais.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a heavy downward arrow driving into broken, jagged ground: the warrior's seismic cut.
COMPOSITION: square canvas. A wide ground band across the bottom, from 4 to 96 percent from the left, reaching down to 96 percent from the top; its top edge is broken into 4 or 5 angular ridges and notches, the highest ridge at about 66 percent from the top; a deep V-shaped crack runs down from the top edge at the center, from 70 to 86 percent from the top. Above it, centered at 50 percent from the left, a thick downward arrow: shaft 14 percent wide from 8 to 36 percent from the top, arrowhead a triangle 36 percent wide from 36 to 58 percent from the top. A gap of at least 7 percent separates the arrow tip from the ground ridges: the arrow does not touch the ground and no bar crosses it. The top-left corner stays empty.
VALUES: the arrow's left half in #F2F4F8 and its right half in #B4B9C4; the ground band in #B4B9C4 with its upper-left-facing ridge facets in #F2F4F8; the V-crack is a transparent cut.
GLOW: nothing glows.
```

### 06. Lâmina do Portão

- **id:** `w_monarch`
- **Nome:** Lâmina do Portão
- **Classe:** Guerreiro
- **Slot:** Suprema (R)
- **No jogo:** Cone corpo a corpo de 150° e 7 m, Metal, físico, poder 5, conjuração 0,35 s, recarga 18 s, custa 100 Chi.
- **Cor da habilidade:** `7CC6FF`. Na barra o glifo fica `A3D7FF` (`lightened(0,3)`) sobre o fundo `101A21`.
- **O símbolo atual:** Coroa de três pontas sobre uma base (`crown.svg`). Reprovada: lembra o Monarca, e o nome mudou para Lâmina do Portão (O1). O desenho novo troca a coroa por uma espada larga atravessando o Portão da masmorra (anel de pedra oval e alto, como o `gate_portal.gd`).
- **Igual nas outras habilidades da classe:** Traço grosso e reto, facetas cortadas em linha reta, sem curva fina; luz no alto à esquerda. É a única do guerreiro com um anel, e a espada larga a domina.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a great broad sword plunged diagonally through a tall oval portal ring: the Gate Blade, the warrior's ultimate. The ring is the dimensional Gate of the game, a thick stone-like oval frame.
COMPOSITION: square canvas. The portal ring is a tall hollow oval about 1.5 times taller than wide, centered at 46 percent from the left and 50 percent from the top, 52 percent wide and 84 percent tall (outer size), its band 9 percent thick, the inside completely empty (transparent). The sword axis runs from the pommel at the upper right (about 90 percent from the left, 8 percent from the top) to the point at the lower left (about 12 percent from the left, 94 percent from the top), about 39 degrees from the vertical. The blade passes in front of the ring and crosses its band cleanly, without weaving. The top-left corner stays empty.
BLADE: very broad blade, 16 percent of the canvas wide at the base, with a central ridge that splits it in two values (upper-left half #F2F4F8, lower-right half #B4B9C4), tapering to a sharp point. One plain straight crossguard bar, 36 percent of the canvas long and 8 percent thick, perpendicular to the blade, placed just outside the ring at the upper right (around 76 percent from the left, 22 percent from the top), in #F2F4F8; short grip 14 percent long in #B4B9C4; ball pommel 10 percent across in #F2F4F8. The guard and pommel stay outside the ring.
RING: the whole ring in the deep value #6B7280, so it reads behind the blade. Not a prohibition sign: the ring is tall and oval and the blade is broad and has a guard.
GLOW: nothing glows.
```

## 4. Mago (6 habilidades)

### Abertura: as seis do Mago

Classe: cor de classe `4F8DFF`, que entra só no Selo e na gola; na barra, cada habilidade usa a cor do próprio `.tres`. Linguagem de forma: traço mais fino que o do guerreiro (7% a 12% do quadro), formas alongadas, pontas afiadas, lados côncavos, diagonais de energia.

| Slot | id | Nome | Silhueta a 40 px | Cor |
|---|---|---|---|---|
| Básico | `m_bolt` | Seta Arcana | zigue-zague vertical e estreito | `8FB8FF` |
| 1 | `m_fireball` | Bola de Fogo | gota de chama, redonda embaixo e pontuda em cima | `FF7A2E` |
| 2 | `m_icelance` | Lança de Gelo | diagonal longa e fina, cabeça de cristal | `9FE3FF` |
| 3 | `m_meteor` | Meteoro | rocha pesada embaixo à esquerda e leque de 3 rastros | `FF5A2E` |
| 4 | `m_blink` | Piscar | estrela grande e uma pequena, lado a lado | `B48CFF` |
| Suprema | `m_nova` | Nova Elemental | estrela redonda de 8 pontas sobre um miolo cheio | `7FE0FF` |

Pares que a cor não separa: Seta Arcana e Lança de Gelo (azuis próximos) se separam por forma (zigue-zague contra reta com cabeça de cristal); Bola de Fogo e Meteoro (laranjas) pela massa (gota vertical contra rocha e leque na diagonal); Piscar e Nova pelo tamanho e pela contagem (2 estrelas de 4 pontas contra 1 de 8).

### 07. Seta Arcana

- **id:** `m_bolt`
- **Nome:** Seta Arcana
- **Classe:** Mago
- **Slot:** Básico (botão esquerdo do mouse)
- **No jogo:** Projétil de 42 m a 34 m/s, Água, mágico, recarga 0,8 s, gera 10 Chi.
- **Cor da habilidade:** `8FB8FF`. Na barra o glifo fica `B1CDFF` (`lightened(0,3)`) sobre o fundo `131821`.
- **O símbolo atual:** Raio em zigue-zague, com o vértice de baixo à esquerda do centro (`bolt.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda. Nada de aro ou chapéu: a identidade do mago é a energia contida.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a single bold zigzag bolt with two sharp bends and a sharp point at the bottom: the mage's arcane bolt.
COMPOSITION: square canvas. A thick zigzag silhouette, about 40 percent of the canvas wide and 94 percent tall, standing slightly left of center. Approximate outline, as percent from the left and from the top: top point (56, 3); down-left to (22, 56); right to (47, 56); down to the bottom point (37, 97); up-right to (78, 38); left to (53, 38); back to the top point. The top-left corner stays empty.
VALUES: the left-facing facets of each segment in #F2F4F8 and the right-facing facets in #B4B9C4, so the bolt looks faceted, with each segment split along its length.
EDGES: all corners are sharp except the two inner bends, which are a little rounded. The bolt is one solid piece with no inner holes.
GLOW: nothing glows.
```

### 08. Bola de Fogo

- **id:** `m_fireball`
- **Nome:** Bola de Fogo
- **Classe:** Mago
- **Slot:** 1
- **No jogo:** Projétil de 42 m a 24 m/s que explode num raio de 3,8 m; Fogo, mágico, poder 2,3, conjuração 1 s, recarga 4 s, custa 22 de mana, gera 16 Chi; queima 4 s.
- **Cor da habilidade:** `FF7A2E`. Na barra o glifo fica `FFA26D` (`lightened(0,3)`) sobre o fundo `211006`.
- **O símbolo atual:** Chama em gota, com a ponta curva para a direita e entalhes nas bordas (`fireball.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a fireball: one large flame with a heavy round base and a tall curling tip, with two smaller tongues peeling off on its left.
COMPOSITION: square canvas. The round base is a circle about 50 percent of the canvas across, centered at 48 percent from the left and 68 percent from the top. The main tongue rises from the base to a sharp tip at about 62 percent from the left and 5 percent from the top, curling to the right at the very top. Two smaller sharp tongues rise from the left side of the base: one to about 22 percent from the left and 36 percent from the top, one to about 36 percent from the left and 20 percent from the top; each separated from the main tongue by a gap of at least 7 percent above the base. The top-left corner stays empty.
INNER CUT: a smaller teardrop-shaped carved cut in the deep value #6B7280, about 20 percent wide and 30 percent tall, inside the lower part of the base, pointing up.
VALUES: the upper-left planes of the flame in #F2F4F8, the lower-right planes in #B4B9C4.
GLOW: nothing glows (the flame is a solid shape, not a light).
```

### 09. Lança de Gelo

- **id:** `m_icelance`
- **Nome:** Lança de Gelo
- **Classe:** Mago
- **Slot:** 2
- **No jogo:** Projétil instantâneo de 42 m a 40 m/s, Água, mágico, poder 1,5, recarga 5 s, custa 16 de mana, gera 12 Chi; reduz a velocidade do alvo por 4 s.
- **Cor da habilidade:** `9FE3FF`. Na barra o glifo fica `BCEBFF` (`lightened(0,3)`) sobre o fundo `151E21`.
- **O símbolo atual:** Lança diagonal, ponta no canto superior direito, com farpas na cabeça (`lance.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda. Separa-se da Seta Arcana por ser reta, e não em zigue-zague.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a slender ice lance flying diagonally: a faceted crystal spear head on a long straight shaft, point toward the upper right. A spell, not a weapon in a hand.
COMPOSITION: square canvas. The lance axis runs at 45 degrees from the tail end at the lower left (about 8 percent from the left, 92 percent from the top) to the point at the upper right (about 94 percent from the left, 6 percent from the top). The top-left corner stays empty.
HEAD: a long diamond-shaped faceted crystal blade about 36 percent of the lance length and 16 percent of the canvas wide at its widest, split by a central ridge into two values (upper-left half #F2F4F8, lower-right half #B4B9C4); two small angular barbs flare from the base of the head, one on each side, about 9 percent long and swept back along the shaft (not perpendicular to it: no crossbar).
SHAFT: a straight shaft 7 percent thick tapering to a sharp point at the tail end, in #B4B9C4 on its lower side and #F2F4F8 on its upper side.
GLOW: nothing glows.
```

### 10. Meteoro

- **id:** `m_meteor`
- **Nome:** Meteoro
- **Classe:** Mago
- **Slot:** 3
- **No jogo:** Área no ponto da mira (até 30 m), raio de 6 m, impacto 0,7 s depois, Fogo, mágico, poder 3,4, conjuração 1,4 s, recarga 12 s, custa 38 de mana, gera 20 Chi.
- **Cor da habilidade:** `FF5A2E`. Na barra o glifo fica `FF8C6D` (`lightened(0,3)`) sobre o fundo `210C06`.
- **O símbolo atual:** Rocha irregular embaixo à esquerda, com três rastros de fogo irregulares para o canto superior direito (`meteor.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda. Massa pesada de rocha contra três rastros finos.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a falling meteor: a large irregular faceted rock at the lower left with three flame streaks trailing to the upper right.
COMPOSITION: square canvas. The rock is an irregular lump of 7 or 8 flat facets, about 40 percent of the canvas wide, centered at 30 percent from the left and 70 percent from the top. From its upper-right side, three flame tongues fan out toward the upper right, each tapering to a sharp tip: the central one to about 94 percent from the left and 6 percent from the top, one lower to about 93 percent from the left and 32 percent from the top, and one higher to about 64 percent from the left and 6 percent from the top; each tongue is about 12 percent thick at its base and separated from its neighbors by gaps of at least 7 percent beyond the rock. The top-left corner stays empty.
VALUES: the rock's upper-left facets in #F2F4F8 and its lower-right facets in #B4B9C4; the three tongues in #F2F4F8 with a lengthwise split: the lower half of each in #B4B9C4.
GLOW: nothing glows.
```

### 11. Piscar

- **id:** `m_blink`
- **Nome:** Piscar
- **Classe:** Mago
- **Slot:** 4
- **No jogo:** Teleporte de até 10 m na direção da mira, sem dano, não aciona a recarga global, recarga 8 s, custa 12 de mana.
- **Cor da habilidade:** `B48CFF`. Na barra o glifo fica `CBAFFF` (`lightened(0,3)`) sobre o fundo `171221`.
- **O símbolo atual:** Estrela fina de 4 pontas voltadas para cima, baixo e os lados (`blink.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda. Aqui a estrela é girada 30° e ganha uma imagem residual menor: assim nenhuma ponta fica na vertical ou na horizontal e a forma não lê como cruz (O2).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a sharp four-pointed sparkle that has just jumped: one large sparkle at the right and one smaller afterimage sparkle at the left. The mage's blink (teleport).
COMPOSITION: square canvas. The large sparkle is centered at 64 percent from the left and 50 percent from the top, about 62 percent wide and tall. The small afterimage is centered at 14 percent from the left and 66 percent from the top, about 22 percent wide and tall. A gap of at least 7 percent separates them. The top-left corner stays empty.
SHAPE: each sparkle has exactly four slim, sharp points with concave curved sides and a narrow waist, rotated 30 degrees clockwise from the vertical, so that no point is vertical or horizontal (it must not read as a cross or a compass).
VALUES: the large sparkle's upper-left half of each point in #F2F4F8 and its lower-right half in #B4B9C4; the small afterimage entirely in #B4B9C4.
GLOW: nothing glows.
```

### 12. Nova Elemental

- **id:** `m_nova`
- **Nome:** Nova Elemental
- **Classe:** Mago
- **Slot:** Suprema (R)
- **No jogo:** Área ao redor do mago, raio de 10 m, Água, mágico, poder 4,2, conjuração 0,5 s, recarga 18 s, custa 100 Chi; congela 2,4 s.
- **Cor da habilidade:** `7FE0FF`. Na barra o glifo fica `A5E9FF` (`lightened(0,3)`) sobre o fundo `111D21`.
- **O símbolo atual:** Explosão de 8 pontas finas e iguais, saindo de um centro cheio (`nova.svg`).
- **Igual nas outras habilidades da classe:** Traço mais fino que o do guerreiro, formas alongadas e pontas afiadas, lados côncavos; luz no alto à esquerda. É a maior forma do mago, e se separa do Círculo Sagrado (anel liso) por ter pontas.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a radiating elemental burst: a big starburst of eight sharp slim points around a solid round core. The mage's ultimate nova.
COMPOSITION: square canvas, centered at 50 percent and 50 percent, about 92 percent across point to point. The core is a solid disc about 30 percent across. Eight equal slim sharp points radiate from it, evenly spaced every 45 degrees, rotated 22 degrees from the vertical so that no point is vertical or horizontal (it must not read as a compass or a cross), each about 31 percent of the canvas long measured from the core's edge and 10 percent wide at its base, gaps between neighboring points open (transparent) all the way to the core. The top-left corner stays free of fine detail (a point may end there).
VALUES: the upper-left half of every point and of the core in #F2F4F8 and the lower-right half in #B4B9C4.
GLOW: nothing glows.
```

## 5. Sacerdote (6 habilidades)

### Abertura: as seis do Sacerdote

Classe: cor de classe `FFD76A`, que entra só no Selo e na lanterna; na barra, cada habilidade usa a cor do próprio `.tres`. Linguagem de forma: formas redondas, fechadas e simétricas, cantos suaves; a chama da lanterna da Vigília, única marca da fé do jogo (O2), é o motivo comum de Luz Sagrada, Cura e Círculo, e as outras três (Bênção, Julgamento, Milagre) ficam como a OS-020 as aprovou, sem chama.

| Slot | id | Nome | Silhueta a 40 px | Cor |
|---|---|---|---|---|
| Básico | `p_smite` | Luz Sagrada | cometa na diagonal, cabeça redonda com chama vazada | `FFE9A8` |
| 1 | `p_heal` | Cura | coração cheio com chama vazada | `8DFFB0` |
| 2 | `p_circle` | Círculo Sagrado | anel liso com chama cheia | `A8FFD0` |
| 3 | `p_bless` | Bênção | cúpula larga de bordas caídas sobre uma haste, com botão em cima | `FFE9A8` |
| 4 | `p_judgement` | Julgamento | pilar alto e estreito com tampa e 2 cacos inclinados | `FFF0B0` |
| Suprema | `p_miracle` | Milagre | estrela gorda de 7 pontas | `FFF6D0` |

Pares que a cor não separa: Luz Sagrada e Bênção (mesma cor `FFE9A8`), e Julgamento e Milagre (amarelos próximos), se separam por forma (diagonal contra cúpula; coluna contra estrela). Cura e Círculo Sagrado (verdes próximos) pela silhueta (coração contra anel). O Círculo Sagrado e a Nova Elemental do mago, que são as duas áreas em volta do conjurador, se separam por anel liso contra estrela de pontas.

### 13. Luz Sagrada

- **id:** `p_smite`
- **Nome:** Luz Sagrada
- **Classe:** Sacerdote
- **Slot:** Básico (botão esquerdo do mouse)
- **No jogo:** Projétil de 38 m, Madeira, mágico, poder 0,95, recarga 0,85 s, gera 10 Chi.
- **Cor da habilidade:** `FFE9A8`. Na barra o glifo fica `FFF0C2` (`lightened(0,3)`) sobre o fundo `211E16`.
- **O símbolo atual:** Cometa na diagonal: cabeça redonda com a chama da lanterna vazada, cauda longa até o canto superior esquerdo e duas faíscas pequenas (OS-020, `smite.svg`).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; a chama da lanterna (ponta torta e uma língua à esquerda) é o motivo comum de Luz Sagrada, Cura e Círculo; luz no alto à esquerda.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a comet of holy light falling diagonally from the upper left to the lower right: a round head with a flame-shaped hollow cut out of it, a long tapering tail, and two small spark ticks. The priest's basic light bolt.
COMPOSITION: square canvas. The head is a solid disc about 50 percent of the canvas across, centered at 67 percent from the left and 67 percent from the top. The tail is a long wedge tapering from the head's upper-left side to a sharp point at about 9 percent from the left and 9 percent from the top (the thin tip may reach into the top-left corner). Two small triangular spark ticks: one above the tail at about 55 percent from the left and 12 percent from the top (about 16 percent long, pointing up), and one to the left of the tail at about 12 percent from the left and 55 percent from the top (about 16 percent long, pointing left); each separated from the tail by a gap of at least 7 percent.
FLAME CUT: inside the head, a lantern flame cut out completely (transparent, see-through): a teardrop flame with a slightly bent tip and one small tongue on its left side, about 22 percent wide and 32 percent tall, its tip pointing toward the tail (upper left). It stays fully inside the head with a solid rim of at least 7 percent all around.
VALUES: the upper-left planes of head and tail in #F2F4F8, the lower-right planes in #B4B9C4; the sparks in #F2F4F8.
GLOW: nothing glows.
```

### 14. Cura

- **id:** `p_heal`
- **Nome:** Cura
- **Classe:** Sacerdote
- **Slot:** 1
- **No jogo:** Cura um aliado (o selecionado ou o mais ferido) a até 34 m, poder 2,0, conjuração 0,9 s, recarga 1,2 s, custa 18 de mana, gera 8 Chi.
- **Cor da habilidade:** `8DFFB0`. Na barra o glifo fica `AFFFC8` (`lightened(0,3)`) sobre o fundo `122117`.
- **O símbolo atual:** Coração cheio, com a chama da lanterna vazada no centro (OS-020, `heal.svg`).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; a chama da lanterna (ponta torta e uma língua à esquerda) é o motivo comum de Luz Sagrada, Cura e Círculo; luz no alto à esquerda.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a plump solid heart with a lantern flame cut out of its center: the priest's heal. It is a heart, never a plus sign or a cross.
COMPOSITION: square canvas. The heart is about 88 percent wide and 83 percent tall (from 8 to 91 percent from the top), centered at 50 percent from the left, with a clear notch at the top center and a rounded point at the bottom. The top-left corner stays free of fine detail.
FLAME CUT: in the center of the heart, a lantern flame cut out completely (transparent, see-through): a teardrop flame with a slightly bent tip and one small tongue on its left side, about 30 percent wide and 40 percent tall, spanning from about 33 to 73 percent from the top, its tip pointing up and ending about 11 percent below the top notch. A solid rim of at least 7 percent remains around it on every side.
VALUES: the upper-left half of each lobe and the left of the heart in #F2F4F8, the lower-right planes in #B4B9C4.
GLOW: nothing glows.
```

### 15. Círculo Sagrado

- **id:** `p_circle`
- **Nome:** Círculo Sagrado
- **Classe:** Sacerdote
- **Slot:** 2
- **No jogo:** Zona de cura no ponto da mira (até 26 m), raio de 6 m, dura 7 s, poder 0,55, conjuração 0,6 s, recarga 13 s, custa 30 de mana.
- **Cor da habilidade:** `A8FFD0`. Na barra o glifo fica `C2FFDE` (`lightened(0,3)`) sobre o fundo `16211B`.
- **O símbolo atual:** Aro grosso com a chama da lanterna sólida no centro (OS-020, `circle.svg`).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; a chama da lanterna (ponta torta e uma língua à esquerda) é o motivo comum de Luz Sagrada, Cura e Círculo; luz no alto à esquerda.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a thick smooth ring with a solid lantern flame in its center: the priest's sacred circle (a healing zone). The ring is smooth and unbroken, with no points.
COMPOSITION: square canvas. The ring is centered at 50 percent and 50 percent, outer diameter about 88 percent of the canvas, band thickness about 11 percent, a perfect circle. The top-left corner stays free of fine detail.
FLAME: in the center, a solid lantern flame: a teardrop with a slightly bent tip and one small tongue on its left side, about 30 percent wide and 42 percent tall, spanning from about 32 to 74 percent from the top, with a clear open gap of at least 7 percent between the flame and the inner edge of the ring on all sides (transparent).
VALUES: the ring's outer half in #F2F4F8 and its inner half in #B4B9C4 (a faceted ridge); the flame's left half in #F2F4F8 and its right half in #B4B9C4.
GLOW: nothing glows.
```

### 16. Bênção

- **id:** `p_bless`
- **Nome:** Bênção
- **Classe:** Sacerdote
- **Slot:** 3
- **No jogo:** Fortalece o grupo (bônus por 22 s) e dá um escudo, alcance 34 m, suporte, conjuração 0,6 s, recarga 26 s, custa 28 de mana.
- **Cor da habilidade:** `FFE9A8`. Na barra o glifo fica `FFF0C2` (`lightened(0,3)`) sobre o fundo `211E16`.
- **O símbolo atual:** Cabeça redonda sobre uma faixa curva de pontas caídas e uma haste afunilada, tudo orgânico (`bless.svg`, aprovado na OS-020: lê como flor ou pássaro de asas abertas).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; luz no alto à esquerda. Não leva a chama da lanterna (a OS-020 manteve este ícone como está). É a única do sacerdote com uma cúpula larga.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a stylized flower in bloom seen from the side, a protective blessing: a small round bud on top, a wide bell-shaped bloom like a dome with two pointed drooping outer tips, held on a tapering stem. Think of a canopy or an umbrella-shaped flower. It must not be a bird, a dove, a person with open arms, or a cross.
COMPOSITION: square canvas, symmetrical, centered at 50 percent from the left. The bud: a rounded drop about 28 percent wide and 22 percent tall, centered at 50 percent from the left and 22 percent from the top. The bloom: a wide dome from about 3 percent to 97 percent from the left, highest at about 30 percent from the top, its two outer tips drooping and pointing down to about 44 percent from the top; its underside curves up and inward to meet the stem at about 74 percent from the top. The stem: 10 percent wide at the top, tapering to a sharp point at 95 percent from the top. A gap of at least 7 percent separates the bud from the bloom. The top-left corner stays free of fine detail.
VALUES: the upper-left half of the bloom and of the bud in #F2F4F8, the lower-right half in #B4B9C4; the stem in #B4B9C4.
GLOW: nothing glows.
```

### 17. Julgamento

- **id:** `p_judgement`
- **Nome:** Julgamento
- **Classe:** Sacerdote
- **Slot:** 4
- **No jogo:** Área no ponto da mira (até 26 m), raio de 4,6 m, impacto 0,25 s depois, Madeira, mágico, poder 2,2, conjuração 0,5 s, recarga 9 s, custa 22 de mana, gera 14 Chi; atordoa 1,4 s.
- **Cor da habilidade:** `FFF0B0`. Na barra o glifo fica `FFF5C8` (`lightened(0,3)`) sobre o fundo `211F17`.
- **O símbolo atual:** Pilar afunilado com uma tampa quadrada em cima e dois cacos inclinados no pé (`judgement.svg`, aprovado na OS-020).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; luz no alto à esquerda. Não leva a chama da lanterna. É a única do sacerdote alta e estreita.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a falling pillar of divine punishment: a heavy tapered column of light that narrows toward the ground, topped by a small square cap, with two slanted shards splashing at its foot.
COMPOSITION: square canvas, symmetrical, centered at 50 percent from the left. The cap: a square 18 percent wide, from 4 to 13 percent from the top. The pillar is one continuous tapered body: 31 percent wide at 20 percent from the top (from about 34 to 66 percent from the left), narrowing smoothly to 20 percent wide at 64 percent from the top, then continuing as a slimmer spike about 12 percent wide that narrows to a sharp point at 96 percent from the top. The cap is separated from the pillar by a gap of at least 7 percent. Two slanted shards flank the lower spike: each a slanted parallelogram about 25 percent long and 8 percent thick, rising toward the pillar at about 25 degrees from the horizontal (the left shard roughly from 9 to 37 percent from the left, the right shard mirrored from 63 to 91), between 72 and 94 percent from the top; each separated from the spike by a gap of at least 7 percent. The shards are clearly slanted, never horizontal and never at a right angle to the pillar (it must not form a cross or an anchor). The top-left corner stays free of fine detail.
VALUES: the pillar's left half (spike included) in #F2F4F8 and its right half in #B4B9C4; the cap in #F2F4F8; the shards in #F2F4F8.
GLOW: nothing glows.
```

### 18. Milagre

- **id:** `p_miracle`
- **Nome:** Milagre
- **Classe:** Sacerdote
- **Slot:** Suprema (R)
- **No jogo:** Cura todo o grupo e revive os caídos, alcance 44 m, poder 4,5, conjuração 0,8 s, recarga 24 s, custa 100 Chi.
- **Cor da habilidade:** `FFF6D0`. Na barra o glifo fica `FFF9DE` (`lightened(0,3)`) sobre o fundo `21201B`.
- **O símbolo atual:** Estrela gorda de 7 pontas, com a ponta de cima voltada para cima (`miracle.svg`, aprovado na OS-020: o O2 só proíbe a de 6).
- **Igual nas outras habilidades da classe:** Formas redondas, fechadas e simétricas; cantos suaves; luz no alto à esquerda. Sem chama. É a única estrela do sacerdote, com pontas grossas e curtas.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a plump star with exactly SEVEN points radiating blessing. Count them: seven, not five, not six, not eight.
COMPOSITION: square canvas, centered at 50 percent from the left and 52 percent from the top, outer radius about 46 percent of the canvas. One point points straight up (12 o'clock); the other six follow evenly every 51.4 degrees, so the bottom has two points (at about 5 and 7 o'clock) and no point at 6 o'clock. The points are fat and short, with shallow inner notches: the inner vertices sit at about 52 percent of the outer radius, and each point is about 22 percent of the canvas wide at its base. The star is one solid piece with no inner holes. Corners slightly rounded. The top-left corner stays free of fine detail.
VALUES: the upper-left half of each point in #F2F4F8 and the lower-right half in #B4B9C4, so each point looks faceted along its center line.
GLOW: nothing glows. It is not a six-pointed star, not a Star of David, not a compass.
```

## 6. Comum (1 habilidade)

### Abertura: a habilidade comum

Não pertence a classe e não tem `.tres`: o slot de Ctrl em `src/ui/hud/hotbar.gd:20` usa `UiKit.icon(&"dodge")` com a cor fixa `9FE3FF`, o texto de ajuda "Esquiva: breve invulnerabilidade" e a recarga de `player.dodge_cooldown_ratio`.

| Slot | id | Nome | Silhueta a 40 px | Cor |
|---|---|---|---|---|
| Ctrl | `dodge` | Esquiva | seta curva em arco com 2 barras de velocidade embaixo | `9FE3FF` |

### 19. Esquiva

- **id:** `dodge`
- **Nome:** Esquiva
- **Classe:** Comum (todas as classes)
- **Slot:** Esquiva (Ctrl)
- **No jogo:** Passo rápido de 6 m em 0,28 s com invulnerabilidade breve, sem custo, recarga 3 s. Não tem `.tres`: a cor `9FE3FF` e o ícone vêm de `hotbar.gd`.
- **Cor da habilidade:** `9FE3FF`. Na barra o glifo fica `BCEBFF` (`lightened(0,3)`) sobre o fundo `151E21`.
- **O símbolo atual:** Seta curva que sobe da esquerda e aponta para a direita, com duas barras de velocidade embaixo à esquerda (`dodge.svg`).
- **Igual nas outras habilidades da classe:** Sem classe: a única forma curva em arco da barra, em azul-gelo `9FE3FF` (a mesma cor da Lança de Gelo; a forma é que as separa). Traço grosso, sem pontas finas.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
SUBJECT: a thick curved sweeping arrow looping up and to the right in a quick sidestep, with two short speed bars at the lower left: a dodge.
COMPOSITION: square canvas. The arrow body is a curved band about 16 percent thick that starts at the left (about 12 percent from the left, 52 percent from the top), arcs upward to its highest point at about 38 percent from the left and 16 percent from the top, then runs to the right into a large triangular arrowhead pointing right: the arrowhead spans from about 72 to 97 percent from the left and from 8 to 48 percent from the top, its point at about 97 percent from the left and 26 percent from the top. The band's outer edge is smooth, the tail end flat-cut. The top-left corner stays free of fine detail (the arc passes below it).
SPEED BARS: two flat horizontal bars at the lower left, each 9 percent thick: the first from 8 to 55 percent from the left at about 70 to 79 percent from the top, the second shorter, from 14 to 38 percent from the left at about 88 to 97 percent from the top. A gap of at least 7 percent separates the bars from each other and from the arrow body.
VALUES: the arrow body's upper edge half in #F2F4F8 and its lower edge half in #B4B9C4; the arrowhead's upper half in #F2F4F8 and its lower half in #B4B9C4; the speed bars in #B4B9C4.
GLOW: nothing glows.
```

## Decisões novas

O guia não cobre ícone de habilidade nem a UI dele. Estas decisões valem só para este documento e não alteram o guia. Se alguma virar regra, ela entra no guia com data e motivo na seção 13.

1. **Recorte transparente em cinza, não quadrado pintado e não colorido.** Pelo que a UI desenha (tabela do topo): fundo, borda e cor vêm do código, e a cor entra multiplicando. Dá a mesma leitura dos SVG brancos de hoje, com relevo facetado em vez de massa chapada.
2. **Três valores e uma regra de tamanho.** Massa `F2F4F8`, facetas `B4B9C4`, cortes `6B7280`; nenhum traço, vão ou detalhe com menos de 7% do quadro (cerca de 3 px a 42 px); no máximo 4 peças soltas. A 27 px (saguão) o mesmo limite dá 2 px, que ainda lê.
3. **Zonas da UI.** Canto superior esquerdo (30% × 20%) sem detalhe fino, por causa da tecla; miolo coberto pelo número de recarga, então a identidade é o contorno externo.
4. **Lâmina do Portão no lugar da coroa (`w_monarch`).** `crown.svg` desenha uma coroa, que lembra o Monarca e quebra o O1 desde que a habilidade mudou de nome. O desenho novo é uma espada larga atravessando um anel oval e alto, como o `gate_portal.gd` desenha o Portão (anel de pedra oval, com 1,42 de proporção). O anel é escuro e a espada leva a guarda reta fora dele, para não formar cruz em aro nem sinal de proibido (O2). A ponta aponta para baixo e para a esquerda, ao contrário do Corte, que aponta para cima e para a direita.
5. **Piscar e Nova giradas.** A estrela de 4 pontas do `blink.svg`, com as pontas para cima, baixo e os lados, lê como cruz ou rosa-dos-ventos. No prompt ela gira 30° e ganha uma imagem residual menor; a Nova (8 pontas) gira 22°. Nenhuma ponta fica na vertical nem na horizontal. A ideia dos símbolos é a mesma.
6. **Corte sem arco.** Um golpe "em arco" desenhado como faixa curva vira crescente (O2). O ícone mantém a espada diagonal do SVG, com duas barras retas de velocidade.
7. **Bênção como flor-cúpula.** O SVG aprovado na OS-020 lê como flor ou pássaro. Para não virar pomba, nem figura de braços abertos, que é uma cruz, o prompt fixa a flor: botão redondo, cúpula larga de pontas caídas e haste afunilada.
8. **Milagre com a contagem travada em 7.** O modelo costuma errar a contagem de pontas, e 6 pontas é a estrela de Davi (O2). O prompt diz "exatamente sete" e dá os ângulos; a conferência conta as pontas.
9. **Chama vazada ou cheia como a OS-020.** Luz Sagrada e Cura têm a chama da lanterna vazada (transparente); o Círculo Sagrado a tem cheia, dentro de um aro liso.
10. **Cor de classe fora da imagem.** A barra pinta cada habilidade com a cor do próprio `.tres` (por exemplo, o Corte do guerreiro é `CFE4FF`, e não o `E0603A` da classe), e a imagem é cinza. A classe se reconhece pela linguagem de forma (massa pesada, traço fino ou forma redonda), registrada na tabela de abertura de cada seção.

### Observações para outras frentes (nada foi alterado)

- O `.tres` de `w_monarch` ainda aponta `icon = &"crown"`. Quando o ícone novo entrar, o campo precisa de um nome novo (sugestão: `gate_blade`), o que é um ajuste de dado.
- `w_slash` não define `icon` e cai no padrão `slash` de `skill_data.gd`.
- `m_nova` tem a cor `7FE0FF`, igual ao `enemy_glow` do tema de gelo (seção 5 do guia). A regra de brilho do guia é de personagem e não vale para ícone, mas a Nova é a única habilidade de herói na cor do inimigo. A cor é de dado e não foi tocada.
- `m_icelance` e a Esquiva usam a mesma cor, `9FE3FF`.
- `UiKit.icon` só carrega `res://assets/icons/<icon>.svg`. Para usar PNG, o carregador precisa aceitar a outra extensão.

## Lista de conferência

Para cada imagem gerada, marque tudo antes de aprovar. Uma falha na seção A reprova a imagem. A seção B vale para as seis de uma classe, lado a lado.

**A. Por imagem**

- [ ] 1024 × 1024, fundo realmente transparente (sem quadriculado desenhado, sem fundo cinza nem borda de cor).
- [ ] Um emblema só, centrado, ocupando cerca de 88% do quadro, sem cortes.
- [ ] Só cinza: nenhum pixel com saturação acima de 5%. Massa principal perto de `F2F4F8`, facetas perto de `B4B9C4`, nada mais escuro que `6B7280`, sem preto nem branco puros.
- [ ] Sem texto, letra, número, moldura, fundo, sombra, brilho, aura, partícula nem contorno.
- [ ] Sem cruz de nenhum tipo (latina, grega, "+", cruz em aro, duas barras em ângulo reto), sem crescente, sem estrela de 6 pontas, sem mitra, sem pomba, sem coroa (O2, O1). A guarda reta da espada é aceita. Olhe com atenção o Corte e a Lâmina do Portão (guarda), o Piscar e a Nova (nenhuma ponta na vertical nem na horizontal), o Julgamento (cacos inclinados, nunca horizontais) e a Bênção (cúpula de bordas caídas, e não braços abertos).
- [ ] Nada de Perfect World ou Solo Leveling: na Lâmina do Portão, nenhuma coroa, nenhum par de adagas, nenhuma fumaça roxa.
- [ ] A forma bate com a ideia do símbolo atual (campo "O símbolo atual" da entrada) e com a descrição do prompt. Contagens: Milagre com **7** pontas, Piscar com 2 estrelas de **4** pontas, Nova com **8** pontas.
- [ ] Sem traço, vão ou detalhe abaixo de 7% do quadro; canto superior esquerdo (30% × 20%) sem detalhe fino.
- [ ] Teste de UI: multiplique o PNG pela cor "glifo na barra" da entrada, sobre o fundo "slot" da entrada, a 42 px e depois a 27 px. A forma continua inteira e legível nos dois tamanhos.
- [ ] Teste de recarga: com um setor preto de 68% cobrindo metade do ícone e o número "14" branco, de 20 px, no centro, o contorno externo ainda identifica a habilidade.

**B. Por classe (6 lado a lado, a 40 px)**

- [ ] Em preto sólido, as seis silhuetas se distinguem sem cor nem legenda, e nenhuma é cópia de outra com pequeno ajuste.
- [ ] Os pares da tabela de abertura (Giro e Sísmico; Seta Arcana e Lança de Gelo; Bola de Fogo e Meteoro; Piscar e Nova; Luz Sagrada e Bênção; Julgamento e Milagre; Cura e Círculo) se leem diferentes só pela forma.
- [ ] A linguagem de classe se mantém: guerreiro com massa pesada e traço grosso; mago com traço fino e pontas afiadas; sacerdote com formas redondas, e a chama da lanterna em Luz Sagrada, Cura e Círculo.
- [ ] Quando o Círculo Sagrado e a Nova Elemental ficam lado a lado, o anel liso e a estrela de pontas não se confundem.
- [ ] A Esquiva, ao lado da Investida do guerreiro, se distingue pela curva em arco.

## Revisão das imagens geradas (08/11/2026)

Os 19 PNGs de `assets/icons/skill_gpt_image/` (128 × 128, cinza com alfa) foram conferidos contra os prompts e a lista de conferência acima. Medido: contorno entre 88% e 95% do quadro, valores perto de `F2F4F8` (massa), `B4B9C4` (facetas) e `6B7280` (cortes), sem cor. Contagem de pontas por varredura polar: Milagre 7, Nova 8, Piscar 4. Conferido também a 42 px na barra (multiplicado por `skill.color.lightened(0,3)` sobre o fundo `cor × 0,13`, com o setor de recarga e o número por cima), a 27 px no saguão e em preto sólido a 40 px.

**Veredito: 16 APROVADO, 1 AJUSTES, 2 REPROVADO.**

**APROVADO (16):** `w_slash`, `w_charge`, `w_seismic`, `m_bolt`, `m_fireball`, `m_icelance`, `m_meteor`, `m_blink`, `m_nova`, `p_smite`, `p_heal`, `p_circle`, `p_bless`, `p_judgement`, `p_miracle`, `dodge`.

As seis silhuetas de cada classe se distinguem a 40 px, e os pares que a cor não separa (Seta Arcana e Lança de Gelo, Nova e Círculo, Corte Sísmico e Giro, Luz Sagrada e Bênção) se separam pela forma. Sem cruz, sem crescente, sem estrela de 6 pontas. Observações aceitas, sem pedir nova imagem: a Nova leva um fio escuro fino em volta do miolo e lê um pouco como sol; a Bênção lê como arraia ou guarda-chuva, e não como flor; a cabeça da Luz Sagrada, com a chama vazada grande, lê como argola.

**AJUSTES (1): `w_monarch`.** A espada larga e o anel do Portão estão certos e o contorno é inconfundível, mas o anel entra no valor escuro `6B7280`, atravessado pela espada no centro, e a silhueta em preto lê como "Ø". Entra no jogo como está. Para regerar, troque o prompt da habilidade por este:

```text
SUBJECT: a great broad sword plunged diagonally through a tall oval portal ring: the Gate Blade, the warrior's ultimate. The ring is the dimensional Gate of the game, a thick stone-like oval frame. It must not read as a prohibition sign or an empty-set symbol: the sword is the dominant shape and the blade crosses the ring off-center.
COMPOSITION: square canvas. The portal ring is a tall hollow oval about 1.5 times taller than wide, centered at 58 percent from the left and 52 percent from the top, 52 percent wide and 84 percent tall (outer size), its band 11 percent thick, the inside completely empty (transparent). The sword axis runs from the pommel at the upper right (about 90 percent from the left, 8 percent from the top) to the point at the lower left (about 12 percent from the left, 94 percent from the top), about 39 degrees from the vertical, so that the blade crosses the left third of the ring, not its center. The blade passes in front of the ring and crosses its band cleanly, without weaving. The top-left corner stays empty.
BLADE: very broad blade, 18 percent of the canvas wide at the base, with a central ridge that splits it in two values (upper-left half #F2F4F8, lower-right half #B4B9C4), tapering to a sharp point. One plain straight crossguard bar, 40 percent of the canvas long and 9 percent thick, perpendicular to the blade, placed just outside the ring at the upper right, in #F2F4F8; short grip 14 percent long in #B4B9C4; ball pommel 11 percent across in #F2F4F8. The guard and pommel stay outside the ring.
RING: the whole ring in the mid value #B4B9C4 with its upper-left half in #F2F4F8, so it reads as a solid frame behind the blade, not as a shadow.
GLOW: nothing glows.
```

**REPROVADO (2): ficam fora da cópia do jogo, que usa o SVG atual até a imagem nova chegar.**

**`w_whirl` (Giro de Lâminas).** Dois arcos-seta fechando um anel, sem nada que diga "lâmina": é o ícone universal de atualizar ou sincronizar, e a 40 px, em preto ou colorido, ninguém lê um golpe giratório. O erro vem do prompt, que descrevia esse símbolo. A nova ideia troca o anel por um cata-vento de quatro lâminas retas em volta de um cubo, que mantém o giro e põe as lâminas à vista. Substitua o prompt da habilidade por este:

```text
SUBJECT: a spinning pinwheel of four straight broad sword blades around a small round hub, like a throwing star or a windmill: a whirling blade attack. It must not look like a refresh, reload or sync icon: no circular arrows, no arrowheads, no ring.
COMPOSITION: square canvas, centered at 50 percent and 50 percent, about 90 percent across. A solid round hub about 24 percent across at the center. Four identical straight blades leave the hub like the vanes of a pinwheel, each leaving the hub tangentially in the clockwise direction: each blade is a flat broad blade about 38 percent of the canvas long measured from the hub, 15 percent wide at its base, tapering in straight lines to a sharp point (no curve, no crossguard), with a central ridge. The blades are spaced every 90 degrees and the whole pinwheel is rotated 20 degrees, so no blade is vertical or horizontal. Every blade tip leads clockwise and is separated from the next blade's body by a gap of at least 7 percent. The top-left corner may hold a blade tip but no fine detail.
VALUES: the upper-left half of each blade (split along its central ridge) and of the hub in #F2F4F8; the lower-right half of each blade and of the hub in #B4B9C4.
GLOW: nothing glows.
```

**`w_warcry` (Grito de Guerra).** Cone com ondas em arco: é o ícone de volume de áudio. O SVG atual já tinha esse defeito, e o prompt, que pedia uma "corneta", não bastou para o modelo sair do alto-falante. As ondas concêntricas e o cone reto precisam sair. Duas opções, na ordem de preferência.

Opção A, a corneta de guerra, com raios em ponta no lugar das ondas:

```text
SUBJECT: a long war horn raised and blown, with three sharp shock rays bursting from its bell: the warrior's battle cry. It must not look like a loudspeaker, a megaphone, a volume or audio icon, and it must not use concentric sound arcs or waves.
COMPOSITION: square canvas. The horn is a long thick tapered animal-horn bugle running diagonally from a small rounded mouthpiece cap at the lower left (about 12 percent from the left and 84 percent from the top) to a wide flared bell at the upper right (the bell rim centered at about 62 percent from the left and 30 percent from the top, about 30 percent across). Its body bends gently, about 20 degrees in total, and never forms a crescent. Two broad metal bands wrap it at one third and two thirds of its length. Three sharp elongated triangular shock rays burst from the bell toward the upper right: the central one reaching about 96 percent from the left and 8 percent from the top, one above reaching about 72 percent from the left and 5 percent from the top, one below reaching about 98 percent from the left and 40 percent from the top. Each ray is separated from the bell and from the others by a gap of at least 7 percent. The top-left corner stays empty.
VALUES: the horn's upper-left side in #F2F4F8 and its lower-right side in #B4B9C4; the two bands in #F2F4F8 with their lower halves in #B4B9C4; the rays in #F2F4F8.
GLOW: nothing glows.
```

Opção B, se a corneta ainda ler como alto-falante, a bandeira de guerra, que também diz "provocar e reforçar a defesa":

```text
SUBJECT: a war banner raised on a spear-tipped pole, flying a swallow-tailed flag: the warrior's rally cry. It must not look like a loudspeaker or an audio icon. The flag hangs from the side of the pole, not from a crossbar, so nothing forms a cross.
COMPOSITION: square canvas. A straight pole 7 percent thick, tilted about 12 degrees clockwise from the vertical, from its foot at about 36 percent from the left and 95 percent from the top to its top at about 46 percent from the left and 6 percent from the top, ending in a small sharp spearhead 12 percent long. The flag is attached along the upper 45 percent of the pole, on its right side, streaming to the right: a rectangle about 46 percent long and 34 percent tall with a V-shaped swallow-tail notch at its free end and two soft waves along its length, plain, with no emblem and no pattern. The top-left corner stays empty.
VALUES: the flag's upper half in #F2F4F8 and its lower half in #B4B9C4; the pole in #B4B9C4; the spearhead in #F2F4F8.
GLOW: nothing glows.
```
