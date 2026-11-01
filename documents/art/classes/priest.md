# Sacerdote: Guia da Vigília

Folha de conceito: `documents/art/concepts/conceito_sacerdote.png`. Números de referência executáveis: `concepts/blockout/bo_heroes.gd.txt`, função `priest()`. Regras citadas estão em `documents/art/style_guide.md`.

## Conceito

A Vigília é uma ordem ficcional de guias que levam luz para dentro dos Portões. O sacerdote é um andarilho de chapéu largo, com uma lanterna acesa na mão. Nada de mitra, batina, casula ou cruz (O2). Veste jade e creme, cores que na neve ainda têm contraste.

## Silhueta: A

Disco largo do chapéu, cintura fina e saia em sino. A lanterna fica fora do disco, em cima. De qualquer ângulo o chapéu é um disco, por isso é a leitura mais forte do elenco.

## Paleta

Materiais em `Look.hero` (guia, M4), exceto as peças de sombra: sob a aba e fundo da manga.

| Papel | Hex | Material |
|---|---|---|
| Chapéu | `E2D6B6` | Laca `.45` |
| Sob a aba | `3A2E25` | Pano `.7` |
| Massa clara: sobreveste, manga, véu, turbante | `E6DCC0` | Pano `.75` |
| Massa escura: veste e saia | `247050` | Pano `.8` |
| Fundo da manga | `14231F` | Pano `.9` |
| Haste | `2B211B` | Laca `.55` |
| Metal de acabamento | Por tier, T0 `C8963F` | Guia, seção 9 |
| Cor de classe | `FFD76A` | Selo e núcleo, `glow(.9)` |

## Esqueleto e pose

`_biped_skeleton(rig, .95, .95, 1.0)`. Os valores somam-se ao `_pose_biped` após a OS-003.

| Joint | Repouso |
|---|---|
| `shoulder_r` | `(.2, 0, .32)` |
| `elbow_r` | `(.5, 0, 0)` |
| `shoulder_l` | `(.1, 0, -.08)` |
| `elbow_l` | `(.2, 0, 0)` |

`arm_swing_r = .2`, `arm_swing_l = .4`, `stride = .4`.

O ombro aberto em `.32` e a rotação z de `-.42` na haste deixam a lanterna fora do disco do chapéu.

## Peças do corpo

Em `loft`, cada anel é `(centro_x, y, raio_x, raio_z)`. Em `lathe`, cada ponto é `(raio, y)`.

| Peça | Joint | Construção | Material |
|---|---|---|---|
| Tronco | `chest` | `loft` 12 lados: `(0,-.08,.17,.125) (0,.16,.17,.125) (0,.34,.215,.135) (0,.47,.22,.13) (0,.54,.1,.09)` | Jade |
| Gola | `chest` | `lathe` 12 lados, escala z `.75`: `(.17,.44) (.13,.52) (.08,.56)` | Creme |
| Saia | `pelvis` | `lathe` 20 lados, escala z `.86`: `(.41,-.885) (.405,-.85) (.325,-.5) (.235,-.18) (.195,.06)` | Jade |
| Barra | `pelvis` | `lathe` 20 lados, escala z `.86`: `(.42,-.89) (.413,-.82) (.39,-.82)` | Metal |
| Sobreveste | `pelvis` | `lathe` 20 lados, escala z `.86`: `(.305,-.3) (.3,-.27) (.245,-.1) (.21,.06)` | Creme |
| Faixa | `pelvis` | `lathe` 14 lados, escala z `.72`: `(.2,-.03) (.205,.1) (.19,.13)` | Metal |
| Estola | `pelvis` | `cloth(.11,.13,.36,.1,2,4)` em `(0,0,-.21)`, rot y `PI` | Metal, duas faces |
| Selo | `chest` | Base comum, frente `(0,.33,-.14)`, costas `(0,.42,.14)` | Metal e `FFD76A` |
| Braço | `shoulder_*` | `_limb(.3,.07,.075)` | Jade |
| Cotovelo | `elbow_*` | `sphere(.075,8)` | Jade |
| Manga de sino | `elbow_*` | `loft` 12 lados: `(0,-.32,.115,.12) (0,-.2,.105,.11) (0,.02,.08,.085)` | Creme |
| Punho | `elbow_*` | `lathe` 12 lados, `close_ends=false`: `(.12,-.325) (.122,-.29)` | Metal |
| Fundo da manga | `elbow_*` | `loft` 12 lados: `(0,-.322,.108,.112) (0,-.316,.108,.112)` | Fundo |
| Mão | `hand_*` | Base comum | Pele |
| Pernas | Nenhuma | Não modelar (J5). Os joints continuam | |

`close_ends=false` no punho é obrigatório. Com a tampa, a boca da manga vira uma bola de metal vista de costas.

## Cabeça e rosto

Rosto da base comum, sempre à mostra. O turbante segue o mesmo truque de duas peças do cabelo do mago.

| Peça | Construção | Material |
|---|---|---|
| Turbante | `loft` 10 lados em `(0,0,.008)`: `(0,.185,.106,.122) (0,.215,.1,.116) (0,.25,.08,.09)` | Creme |
| Nuca | `loft` 10 lados em `(0,0,.04)`: `(0,.03,.075,.07) (0,.12,.105,.09) (0,.2,.1,.09)` | Creme |
| Chapéu | `lathe` 16 lados, facetado, em `(0,.215,0)`: `(.45,0) (.44,.02) (.2,.125) (.05,.195) (0,.2)` | Chapéu |
| Forro da aba | `lathe` 16 lados, facetado, em `(0,.215,0)`: `(.44,0) (0,.05)` | Sob a aba |
| Fita | `torus(.12,.145,16)` em `(0,.27,0)`, escala `(1,.45,1)` | Metal |
| Véu | `cloth(.24,.3,.26,.06,4,3)` em `(0,.22,.125)` | Creme, duas faces |

## Armas e empunhadura

| Arma | Dados | Pose |
|---|---|---|
| Bastão-lanterna (`scepter`) | Haste `cylinder(.02,.026,1.5,8)` em `y=.2`. Lanterna na origem `y=.98`: teto `lathe` 6 lados, facetado, `(.03,.14) (.115,.1) (.125,.08) (.09,.08)`; base `lathe` 6 lados `(.11,-.13) (.115,-.11) (.08,-.16)`; 6 barras `box(.012,.2,.012)` no raio `.105`; núcleo `sphere(.075,10)`, escala `(1,1.3,1)`, em `y=-.02`, `glow(FFD76A,.9)` | Em `hand_r`: posição `(0,-.02,0)`, rotação `(-.95,0,-.42)` |
| Tomo (`tome`) | Capa `5A2A22`, páginas `E8DFCA`, com as páginas em **+Z**, voltadas para quem segura. Luz na mão direita: `sphere(.06,12)`, `glow(FFD76A,.9)` em `(0,-.2,-.02)`. Lanterna pequena no cinto: núcleo `sphere(.05,10)`, teto `lathe` 6 lados `(.02,.1) (.07,.07) (.08,.06)`, em `pelvis (.24,-.2,-.06)` | Livro em `hand_l`: posição `(.02,-.12,-.03)`, `EULER_ORDER_XYZ`, rotação `(-1.55,0,0)`. Repouso: `shoulder_l (.45,0,-.1)`, `elbow_l (1.35,0,0)`, `shoulder_r (.3,0,.14)`, `elbow_r (1.0,0,0)` |

O bastão é carregado, sem tocar o chão, ao contrário do cajado do mago.

**Luz real da lanterna:** `OmniLight3D` na lanterna, `FFD76A`, energia `.55`, alcance `3.0`, sem sombra, em todas as qualidades. Ela clareia o próprio sacerdote no escuro (testado no motor) e é a marca dele em corredores. Limite de uma por sacerdote (C3).

## Viewmodel

Medidas em `documents/art/work_orders/OS-012-viewmodel.md`.

- Manga de sino creme com punho de metal, cobrindo o pulso.
- Mão direita fechada na haste, com a lanterna acima do meio da tela. Mão esquerda aberta.
- `OmniLight3D` igual à do modelo, presa à lanterna.
- No tomo, a página aparece para o jogador. Hoje ele vê a capa.
- Em T1 ou mais, o punho ganha barra de pele.

## Tiers

| Tier | Muda | Construção |
|---|---|---|
| T0, variante 0 (Veste do Noviço) | Ficha completa | |
| T0, variante 1 (Vestes do Peregrino) | **Alforje** | `box(.16,.12,.06)` em `pelvis (-.26,-.1,0)`, `3A2A22` |
| T1 | **Manto curto**, metal `C4D2E0` | `loft` 12 lados em `chest`: `(0,.3,.27,.17) (0,.38,.26,.165) (0,.5,.2,.135) (0,.56,.1,.09)`, `D5D9E4`. Selo frontal vai para `(0,.4,-.18)` |
| T2 | **Pingentes largos na aba**, metal `D8B464` | 2 × `cylinder(.005,.005,.2,6)` em `head (±.4,.13,0)` e `sphere(.06,10)`, escala `(1,1.25,1)`, em `(±.4,.02,0)` |
| T3 | **Aba dupla, véu longo, segunda lanterna**, metal `E6ECF5` | Segunda aba: `lathe` 16 lados em `head (0,.35,0)`: `(.27,0) (.26,.015) (.1,.1) (0,.14)`, cor do chapéu. Véu com `length=.5`. Lanterna do bastão com escala `1.18`. Lanterna de cinto como a do tomo, em `pelvis (-.2,-.2,-.08)`, sem luz real |
