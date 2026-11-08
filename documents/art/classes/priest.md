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

O ombro aberto em `.32` e a rotação z de `-.42` na haste deixam a lanterna fora do disco do chapéu de frente. De lado a base da lanterna encostava na ponta da aba, a 0 cm, e de frente ficava a 4 cm. A haste sobe 8 cm na mão (`posição y .06`, medido na OS-011): de frente o vão entre a lanterna e a ponta da aba é de 6,4 cm; de lado a base da lanterna fica a 0,6 cm da copa do chapéu, e isso é aceito de propósito. A 60 px um pixel vale cerca de 3,6 cm, então nenhum `y` abaixo de `.14` separaria a lanterna de lado (1,2 cm em `.10`, 0,7 cm em `.14`), e só a rotação do bastão resolveria. A letra A é o disco e o sino, não a lanterna (S2). A haste toca a ponta da aba no contorno de frente, sem apagar o disco. A altura com bastão vai de 2,13 m a 2,174 m.

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
| Estola | `pelvis` | `cloth(.11,.13,.36,.1,1,4)` em `(0,0,-.22)`, rot y `PI` | Metal, duas faces |
| Selo | `chest` | Base comum, frente `(0,.33,-.14)`, costas `(0,.42,.14)` | Metal e `FFD76A` |
| Braço | `shoulder_*` | `_limb(.3,.07,.075)` | Jade |
| Cotovelo | `elbow_*` | `sphere(.075,8)` | Jade |
| Manga de sino | `elbow_*` | `loft` 12 lados: `(0,-.32,.115,.12) (0,-.2,.105,.11) (0,.02,.08,.085)` | Creme |
| Punho | `elbow_*` | `lathe` 12 lados, `close_ends=false`: `(.12,-.325) (.122,-.29)` | Metal |
| Fundo da manga | `elbow_*` | `loft` 12 lados: `(0,-.322,.108,.112) (0,-.316,.108,.112)` | Fundo |
| Mão | `hand_*` | Base comum | Pele |
| Pernas | Nenhuma | Não modelar (J5). Os joints continuam | |

`close_ends=false` no punho é obrigatório. Com a tampa, a boca da manga vira uma bola de metal vista de costas.

A estola tem uma coluna só: com duas, a dobra de `MeshKit.cloth` afunda o centro 4,5 cm e a sobreveste (que chega a `z -.26` na barra) cobre o meio e deixa um recorte creme. De uma coluna e em `z -.22`, ela fica 1,2 cm ou mais à frente da sobreveste em todo o comprimento.

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
| Bastão-lanterna (`scepter`) | Haste `cylinder(.02,.026,1.5,8)` em `y=.2`. Lanterna na origem `y=.98`: teto `lathe` 6 lados, facetado, `(.09,.08) (.125,.08) (.115,.1) (.03,.14)`; base `lathe` 6 lados `(.08,-.16) (.115,-.11) (.11,-.13)`; 6 barras `box(.012,.2,.012)` no raio `.105`; núcleo `sphere(.075,10)`, escala `(1,1.3,1)`, em `y=-.02`, `glow(FFD76A,.9)` | Em `hand_r`: posição `(0,.06,0)`, rotação `(-.95,0,-.42)` |
| Tomo (`tome`) | Capa `5A2A22`, páginas `E8DFCA`, com as páginas em **+Z**, voltadas para quem segura. Luz na mão direita: `sphere(.06,12)`, `glow(FFD76A,.9)` em `(0,-.2,-.02)`. Lanterna pequena no cinto: núcleo `sphere(.05,10)`, teto `lathe` 6 lados `(.08,.06) (.07,.07) (.02,.1)`, em `pelvis (.31,-.2,-.06)` | Livro em `hand_l`: posição `(.02,-.12,-.03)`, `EULER_ORDER_XYZ`, rotação `(-1.55,0,0)`. Repouso: `shoulder_l (.45,0,-.1)`, `elbow_l (1.35,0,0)`, `shoulder_r (.3,0,.14)`, `elbow_r (1.0,0,0)` |

O bastão é carregado, sem tocar o chão, ao contrário do cajado do mago.

A luz do tomo não tem cabo: flutua além dos dedos, seguindo a mão, com folga de cerca de 4,5 cm. A lanterna de cinto é do corpo e entra na OS-011, não na OS-008. Ela fica 7 cm mais para fora do que o blockout: a sobreveste chega a `x=.277` na altura dela e, em `.24`, a esfera ficava embutida e só aparecia um disco de 2 cm no contorno. Em `.31` aparece inteira, de frente e de costas, que é como o aliado costuma ser visto (E3).

No golpe vale J10: `strike_wrist` `(-.8,0,.5)` no bastão e zero no tomo.

**Luz real da lanterna:** `OmniLight3D` criada em `WeaponKit._scepter`, junto da malha, `FFD76A`, energia `.55`, alcance `3.0`, sem sombra, em todas as qualidades e raridades. Ela clareia o próprio sacerdote no escuro (testado no motor) e é a marca dele em corredores. Limite de uma por sacerdote (C3). A luz segue a arma: com o tomo não há luz real, e a lanterna de cinto fica só com o núcleo emissivo.

## Viewmodel

Medidas em `documents/art/work_orders/OS-012-viewmodel.md`.

- Manga de sino creme com punho de metal, cobrindo o pulso.
- Mão direita fechada na haste, com a lanterna acima do meio da tela. Mão esquerda aberta.
- Com `scepter`, a `OmniLight3D` é a do modelo, criada pela mesma função de `WeaponKit`. O viewmodel não cria outra.
- No tomo, a página aparece para o jogador. Hoje ele vê a capa.
- Em T1 ou mais, o punho ganha barra de pele `EEF1F6`, de `.02` a `.05` acima do pulso e com raio `.115`, logo acima do punho de metal. Com o raio `.09` da ordem original ela ficava dentro do sino e T2 não se distinguia de T0.

## Tiers

| Tier | Muda | Construção |
|---|---|---|
| T0, variante 0 (Veste do Noviço) | Ficha completa | |
| T0, variante 1 (Vestes do Peregrino) | **Alforje** | `box(.16,.12,.06)` em `pelvis (-.26,-.1,0)`, `3A2A22` |
| T1 | **Manto curto**, metal `C4D2E0` | `loft` 12 lados em `chest`: `(0,.3,.27,.17) (0,.38,.26,.165) (0,.5,.2,.135) (0,.56,.1,.09)`, `D5D9E4`. Os dois Selos saem para fora do manto: frontal em `(0,.4,-.18)` e traseiro em `(0,.42,.18)`. O manto passa em `z .155` a `y .42`, e o Selo traseiro de T0, em `z .14`, ficava 1,5 cm por dentro |
| T2 | **Pingentes largos na aba**, metal `D8B464` | 2 × `cylinder(.005,.005,.2,6)` em `head (±.4,.13,.05)` e `sphere(.06,10)`, escala `(1,1.25,1)`, em `(±.4,.02,.05)`. O `z .05` tira o pingente da linha do rosto no perfil e a 3/4 (o rosto fica em `z` -.09 a -.11). Se o direito ficar a menos de 5 cm da haste, os dois vão para `x ±.34` |
| T3 | **Aba dupla, véu em duas fitas, segunda lanterna**, metal `E6ECF5` | Segunda aba: `lathe` 16 lados em `head (0,.335,0)`: `(.22,0) (.21,.015) (.09,.095) (0,.13)`, cor do chapéu. Com `.27` de raio ela chegava a 3 cm da lanterna do bastão, e a lanterna cresce 18%; com `.22` o vão fica em 8 cm. Fitas: o véu de `.26` fica, e somam-se 2 × `cloth(.07,.08,.5,.04,1,4)` em `head (±.15,.22,.125)`, creme duas faces. Um véu único de 0,50 m cobriria o Selo traseiro (`y` .34 a .50). Lanterna do bastão com escala `1.18` (vão até a primeira aba de 4,5 cm no pior ponto do passo, 3 cm abaixo do T0, aceito em 02/11/2026). Lanterna de cinto como a do tomo, em `pelvis (-.31,-.2,-.06)`, sem luz real |
