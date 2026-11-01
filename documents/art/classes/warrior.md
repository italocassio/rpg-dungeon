# Guerreiro: Vanguarda

Folha de conceito: `documents/art/concepts/conceito_guerreiro.png`. Números de referência executáveis: `concepts/blockout/bo_heroes.gd.txt`, função `warrior()`. Regras citadas estão em `documents/art/style_guide.md`.

## Conceito

É quem entra primeiro no Portão e fica entre o grupo e o monstro. Couraça clara e tabardo carmesim, com escudo sempre à frente. Tem jeito de soldado veterano, não de cavaleiro de torneio.

## Silhueta: T

Ombreiras de 0,99 m sobre um corpo reto, escudo redondo de 0,80 m à esquerda, crista carmesim do topo à nuca. De costas, a capa fendida forma uma massa escura contra a neve.

## Paleta

Materiais em `Look.hero` (guia, M4), exceto as peças de sombra.

| Papel | Hex | Material |
|---|---|---|
| Massa clara | `B0AEA8` | Aço, `matte(.42, .35)` |
| Massa escura | `23262E` | Pano, `matte(.75)` |
| Tabardo e crista | `C23A22` | Pano `.85`; crista em laca `.5` |
| Capa | `B3301F` | Pano `.85`, duas faces |
| Escudo | `9A2A1F` | Laca `.5` |
| Couro | `3A2A22` | Couro `.8` |
| Metal de acabamento | Por tier, T0 `C8963F` | Guia, seção 9 |
| Cor de classe | `E0603A` | Selo, `glow(1.0)` |

## Esqueleto e pose

`_biped_skeleton(rig, 1.0, 1.0, 1.15)`. Valores abaixo somam-se ao `_pose_biped` após a OS-003, que acrescenta 0,25 ao cotovelo.

| Joint | Repouso |
|---|---|
| `shoulder_r` | `(0, 0, .14)` |
| `shoulder_l` | `(.25, 0, -.18)` |
| `elbow_l` | `(1.0, .25, 0)` |

`arm_swing_r = .45`, `arm_swing_l = .15`, `stride = .75`, `knee_bend = 1.1`.

## Peças do corpo

Em `loft`, cada anel é `(centro_x, y, raio_x, raio_z)`. Em `lathe`, cada ponto é `(raio, y)`.

| Peça | Joint | Construção | Material |
|---|---|---|---|
| Couraça | `chest` | `loft` 8 lados, `smooth=false`: `(0,-.1,.19,.135) (0,.1,.2,.145) (0,.3,.3,.19) (0,.46,.31,.18) (0,.55,.13,.11)` | Aço |
| Gorjal | `chest` | `lathe` 10 lados: `(.15,.5) (.125,.56) (.1,.58)` | Escuro |
| Faldas | `pelvis` | `lathe` 10 lados, facetado, escala z `.78`: `(.28,-.3) (.27,-.22) (.25,-.22) (.25,-.13) (.23,-.13) (.22,-.04) (.2,-.04) (.21,.05)` | Aço |
| Cinto | `pelvis` | `lathe` 12 lados em `y=.02`, escala z `.78`: `(.215,0) (.225,.07) (.21,.1)` | Metal |
| Tabardo | `pelvis` | `cloth(.26,.32,.78,.05,4,5)` em `(0,0,-.245)`, rot y `PI` | Tabardo, duas faces |
| Capa | `cloth_back` em `chest (0,.52,.17)` | 2 × `cloth(.25,.38,1.2,.26,6,7)` em `(±.125,0,0)`, rot y `±.07` | Capa, duas faces |
| Telha baixa | `chest`, origem `(±.21,.5,0)` | `loft` 8 lados, facetado: `(±.17,-.33,.115,.16) (±.15,-.24,.135,.175) (±.11,-.17,.11,.145)` | Metal |
| Telha média | Mesma origem | `loft` 8 lados, facetado: `(±.14,-.24,.145,.185) (±.11,-.14,.16,.195) (±.07,-.07,.13,.165)` | Aço |
| Telha alta | Mesma origem | `loft` 8 lados, facetado: `(±.09,-.13,.175,.2) (±.05,-.05,.165,.195) (±.01,.05,.13,.17) (∓.02,.115,.075,.11)` | Aço |
| Braço | `shoulder_*` | `_limb(.3,.08,.065)` | Escuro |
| Cotovelo | `elbow_*` | `sphere(.078,8)` | Aço |
| Antebraço | `elbow_*` | `_limb(.3,.08,.062)` | Aço |
| Manopla | `hand_*` | Mão da base comum | Aço |
| Coxa | `hip_*` | `_limb(.46,.105,.08)` | Escuro |
| Joelheira | `knee_*` | `sphere(.085,8)` em `(0,0,-.01)` | Aço |
| Canela | `knee_*` | `_limb(.46,.09,.07)` | Escuro |
| Bota | `knee_*` | Base comum | Aço |
| Selo | `chest` | Base comum, frente `(0,.38,-.205)`, costas `(0,.54,.2)` | Metal e `E0603A` |

## Cabeça e rosto

Rosto da base comum, à mostra do T0 ao T2 (R2).

| Peça | Construção | Material |
|---|---|---|
| Elmo | `lathe` 8 lados, facetado: `(.125,.13) (.128,.2) (.105,.26) (.06,.295) (0,.305)` | Aço |
| Nasal | `box(.03,.14,.02)` em `(0,.15,-.128)` | Metal |
| Jugulares | 2 × `box(.03,.15,.16)` em `(±.115,.07,0)` | Aço |
| Proteção da nuca | `lathe` 8 lados em `(0,0,.03)`, escala z `.9`: `(.125,-.02) (.14,.14)` | Aço |
| Crista | `MeshKit.plate`, espessura `.05`, rot y `-PI/2`: `(-.15,.17) (-.13,.27) (-.06,.36) (.05,.4) (.17,.37) (.25,.28) (.27,.15) (.1,.2)` | Laca `C23A22` |

## Armas e empunhadura

| Arma | Dados | Pose |
|---|---|---|
| Espada (`sword_shield`) | Cabo `cylinder(.022,.026,.2,8)`; guarda `box(.28,.04,.06)` em `y=.11`, metal; lâmina `blade(.98,.095,.026,.14)` em `y=.12`, aço | Em `hand_r`: posição `(0,-.06,-.02)`, rotação `(-2.45,0,0)` |
| Escudo | `lathe` 16 lados `(0,.03) (.2,.025) (.37,0) (.38,-.02) (0,-.02)`, rot x 90°; aro `torus(.35,.4,24)` escala `(1,.6,1)`; umbo `sphere(.08,10)` em `(0,0,-.03)`; miolo em laca, aro e umbo em metal | Em `hand_l`: posição `(-.07,.03,0)`, `rotation_order = EULER_ORDER_XYZ`, rotação `(-1.5,.75,0)` |
| Machado (`greataxe`) | Cabo e cabeça atuais em aço limpo, sem `Look.metal` | Em `hand_r`: posição `(0,-.03,0)`, rotação `(-1.215,0,0)`. Repouso: `shoulder_r (.6,0,.2)`, `elbow_r (1.35,0,0)`, `shoulder_l (.05,0,-.12)`, `elbow_l` zerado |

Com o machado, a cabeça da arma fica acima do ombro direito e reforça o T.

## Viewmodel

Medidas em `documents/art/work_orders/OS-012-viewmodel.md`.

- Manopla de aço, com dedos em anéis de `torus` em volta do cabo, a mesma mão fechada das três classes.
- Antebraço de aço, com faixa de metal de tier no pulso e a 24 cm dele.
- Escudo com a face interna em couro `5A4632` e alça `3A2A22`.
- Em T1 ou mais, soma um punho de pele.

## Tiers

| Tier | Muda | Construção |
|---|---|---|
| T0, variante 0 (Cota de Malha) | Sem telha média, aço `8F8D88` no tronco | Largura de 0,92 m |
| T0, variante 1 (Couraça de Recruta) | Ficha completa | Largura de 0,99 m |
| T1 | **Gola de pele**, canela em aço, metal `C4D2E0` | `lathe` 14 lados em `chest`, escala z `.72`: `(.4,.43) (.39,.5) (.28,.6) (.15,.65)`, `EEF1F6` |
| T2 | **Crista alta, ombreira 10% maior**, lâmina de 1,06 m, metal `D8B464` | Crista com escala y `1.5`. Nas telhas, multiplique `centro_x` e `raio_x` por `1.1` |
| T3 | **Máscara fechada, lâminas nas ombreiras**, capa de 1,42 m, metal `E6ECF5` | Máscara: `loft` 10 lados em `head (0,0,-.006)`: `(0,.02,.06,.08) (0,.1,.098,.112) (0,.19,.103,.116)`. Visor: `box(.11,.012,.02)` em `(0,.135,-.116)`, `0C0E14`, sem brilho. Lâmina: `plate` espessura `.04` `(0,0) (.11,0) (.09,.2) (.03,.32)` em `chest (±.33,.6,0)`, rot z `∓.3`, `E6ECF5` |
