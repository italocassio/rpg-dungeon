# Mago: Arcanista do Portão

Folha de conceito: `documents/art/concepts/conceito_mago.png`. Números de referência executáveis: `concepts/blockout/bo_heroes.gd.txt`, função `mage()`. Regras citadas estão em `documents/art/style_guide.md`.

## Conceito

Estudioso que aprendeu a dobrar a energia dos Portões e a mantém presa num aro. Elegante, seco, sempre ereto. Nada de capuz, de chapéu pontudo ou de olhos acesos: o que se vê é uma pessoa, não uma criatura. Isso separa o mago do xamã inimigo, que hoje tem o mesmo corpo.

## Silhueta: Y

Tronco estreito, gola em duas asas que abre atrás da cabeça e uma haste de 2,40 m com aro no topo. De perfil é uma linha fina ao lado de outra. Sem o cajado, a gola mantém o Y (S2).

## Paleta

Materiais em `Look.hero` (guia, M4), exceto as peças de sombra.

`6E2470` foi escolhido para ler violeta na masmorra. No saguão, com luz quente, ele puxa para o magenta.

| Papel | Hex | Material |
|---|---|---|
| Massa clara: capa | `D5D9E4` | Pano `.75` |
| Massa clara: gola, por fora | `D5D9E4` | Laca `.5` |
| Cabelo | `CBD2E2` | Cabelo `.55` |
| Casaco | `6E2470` | Pano `.8` |
| Massa escura: pernas | `1B1830` | Pano `.8` |
| Botas e haste | `2A2038` | Couro `.6`; haste em laca `.5` |
| Cor de classe | `4F8DFF` | Gola por dentro, forro, Selo em `glow(1.0)` |
| Núcleo do foco | `8A7BFF` | `glow(.9)` |
| Metal de acabamento | Por tier, T0 `C8963F` | Guia, seção 9 |

## Esqueleto e pose

`_biped_skeleton(rig, 1.02, .98, .86)`. Os valores somam-se ao `_pose_biped` após a OS-003.

| Joint | Repouso |
|---|---|
| `shoulder_r` | `(.32, 0, .3)` |
| `elbow_r` | `(.4, 0, 0)` |

`arm_swing_r = .2`, `arm_swing_l = .6`, `stride = .75`.

O ombro aberto em `.3` afasta o aro da asa da gola, e a rotação z de `-.32` na haste compensa esse giro do braço: sem ela a haste pende para a cabeça e metade do Y some.

## Peças do corpo

Em `loft`, cada anel é `(centro_x, y, raio_x, raio_z)`. Em `lathe`, cada ponto é `(raio, y)`.

| Peça | Joint | Construção | Material |
|---|---|---|---|
| Tronco | `chest` | `loft` 12 lados: `(0,-.08,.16,.115) (0,.14,.145,.105) (0,.34,.195,.12) (0,.5,.205,.115) (0,.56,.09,.08)` | Casaco |
| Capa curta | `chest` | `loft` 12 lados: `(0,.28,.255,.165) (0,.36,.25,.16) (0,.5,.2,.135) (0,.585,.085,.08)` | Prata |
| Cinto | `pelvis` | `lathe` 12 lados, escala z `.72`: `(.165,0) (.175,.08) (.165,.1)` | Metal |
| Aba traseira | `cloth_back` em `pelvis (0,.04,.12)` | `cloth(.34,.66,1.0,.2,6,7)` | Casaco, duas faces |
| Painéis da frente | `pelvis` | 2 × `cloth(.15,.2,.86,.04,3,5)` em `(±.14,.04,-.11)`, rot y `PI ± .28` | Casaco, duas faces |
| Forro | `pelvis` | 2 × `cloth(.02,.022,.84,.04,1,5)` em `(±.05,.04,-.125)`, rot y `PI` | `4F8DFF`, laca |
| Selo | `chest` | Base comum, frente `(0,.41,-.165)`, costas `(0,.43,.16)` | Metal e `4F8DFF` |
| Gola, asa externa | `chest` | 2 × `plate`, espessura `.03`, em `(0,.55,.1)`, rot x `.28`: `(.03,0) (.19,0) (.27,.2) (.3,.44) (.12,.3) (.03,.12)` e o espelho | Laca `D5D9E4` |
| Gola, asa interna | `chest` | 2 × `plate`, espessura `.04`, em `(0,.55,.09)`, rot x `.28`: `(.05,.03) (.17,.03) (.245,.2) (.27,.37) (.125,.26) (.05,.13)` e o espelho | Laca `4F8DFF` |
| Braço | `shoulder_*` | `_limb(.3,.065,.058)` | Casaco |
| Cotovelo | `elbow_*` | `sphere(.06,8)` | Casaco |
| Manga | `elbow_*` | `cylinder(.095,.06,.28,10)` em `y=-.15` | Casaco |
| Punho | `elbow_*` | `cylinder(.1,.098,.03,10)` em `y=-.285` | Prata |
| Mão | `hand_*` | Base comum | Pele |
| Coxa | `hip_*` | `_limb(.46,.085,.062)` | Pernas |
| Joelho | `knee_*` | `sphere(.065,8)` | Pernas |
| Canela | `knee_*` | `_limb(.46,.066,.052)` | Pernas |
| Bota | `knee_*` | Base comum | Botas |

## Cabeça e rosto

Rosto da base comum, sempre à mostra. `loft` não cobre a nuca sem cobrir o rosto, então o cabelo é feito de duas peças: casquete acima da sobrancelha e nuca deslocada para trás.

| Peça | Construção | Material |
|---|---|---|
| Casquete | `loft` 10 lados em `(0,0,.008)`: `(0,.185,.106,.122) (0,.235,.09,.106) (0,.28,.03,.04)` | Cabelo |
| Nuca | `loft` 10 lados em `(0,0,.045)`: `(0,.03,.075,.07) (0,.12,.105,.09) (0,.2,.1,.09)` | Cabelo |
| Coque | `sphere(.058,8)` em `(0,.3,.05)` | Cabelo |
| Grampo | `cylinder(.008,.008,.2,6)` em `(0,.3,.05)`, rot z `PI/2.3` | Metal |
| Trança | `cloth(.1,.04,.62,.03,2,4)` em `(0,.22,.125)` | Cabelo, duas faces |
| Mechas | 2 × `cloth(.05,.02,.22,0,1,3)` em `(±.108,.2,-.03)`, rot y `PI/2` | Cabelo, duas faces |

## Armas e empunhadura

| Arma | Dados | Pose |
|---|---|---|
| Cajado (`staff`) | Haste `cylinder(.022,.03,2.1,8)` em `y=-.03`; aro `torus(.135,.185,20)` em `y=1.11`, rot x 90°, metal; núcleo `sphere(.085,12)` em `y=1.11`, escala `(1,1.45,1)`, `glow(8A7BFF,.9)` | Em `hand_r`: posição `(0,-.02,0)`, rotação `(-.97,0,-.32)` |
| Orbe (`orb`) | `sphere(.1,16)`, `glow(8A7BFF,.9)`; aro `torus(.13,.155,24)` rot `(.6,0,.4)`, metal | Em `hand_r`: posição `(0,-.2,-.02)`. Repouso: `shoulder_r (.35,0,.1)`, `elbow_r (1.2,0,0)` |

O pé da haste toca o chão: o aro fica a 2,22 m e o topo a 2,40 m. Luz aliada é redonda, então o cristal `shard` atual sai (B2).

## Viewmodel

Medidas em `documents/art/work_orders/OS-012-viewmodel.md`.

- Manga ameixa, punho prata, e logo acima dele um aro fino com `glow(4F8DFF)`, de 2,5 cm.
- Mão direita fechada na haste. Mão esquerda aberta, sempre a mesma pose de conjuração.
- O núcleo ocupa o centro-direita da tela e mantém o violeta: energia `.9`, nunca disco branco.
- Em T1 ou mais, o punho prata ganha barra de pele.

## Tiers

| Tier | Muda | Construção |
|---|---|---|
| T0, variante 0 (Túnica de Aprendiz) | Ficha completa | Capa de 0,30 m |
| T0, variante 1 (Manto do Novato) | Capa mais longa | Primeiro anel da capa desce para `y=.16` |
| T1 | **Barra de pele na capa**, metal `C4D2E0` | `loft` 12 lados: `(0,.255,.285,.19) (0,.325,.268,.178)`, `EEF1F6` |
| T2 | **Gola alta, 2 focos flutuantes**, metal `D8B464` | Gola com escala y `1.22`. Foco: `torus(.06,.09,18)` rot x 90°, escala `(1,.6,1)`, e `sphere(.05,10)` escala `(1,1,.45)`, `glow(8A7BFF,.9)`, em `chest (±.5,.42,.1)`. Oscilação de `±.03` m em y |
| T3 | **4 focos, aro duplo, casaco longo**, metal `E6ECF5` | Mais 2 focos em `chest (±.42,.82,.14)`. Segundo aro `torus(.205,.24,24)` em `y=1.11`. Aba traseira com `length=1.14` |

Focos ficam em `chest`, com fase distinta em cada um. A largura com focos não conta para os 0,60 m, que são da gola.
