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
| Aço escuro | `6F6D69`, L* 46 | Aço, `matte(.42, .35)`. Só o gorjal. Peça escura em plano vertical, vista de costas, vira laje preta sob a cúpula |
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

`arm_swing_r = .45`, `arm_swing_l = .15`, `stride = .75`, `knee_bend = .85`.

## Peças do corpo

Em `loft`, cada anel é `(centro_x, y, raio_x, raio_z)`. Em `lathe`, cada ponto é `(raio, y)`.

| Peça | Joint | Construção | Material |
|---|---|---|---|
| Couraça | `chest` | `loft` 8 lados, `smooth=false`: `(0,-.1,.19,.135) (0,.1,.2,.145) (0,.3,.3,.19) (0,.46,.31,.18) (0,.55,.13,.11)` | Aço |
| Gorjal | `chest` | `lathe` 10 lados, facetado, escala z `.85`: `(.14,.5) (.122,.55) (.1,.58) (.06,.585)` | Aço escuro |
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
| Joelheira | `knee_*` | `sphere(.098,8)` em `(0,0,-.012)` | Aço |
| Canela | `knee_*` | `_limb(.46,.09,.07)` | Escuro |
| Bota | `knee_*` | Base comum | Aço |
| Selo | `chest` | Base comum, frente `(0,.38,-.205)`, costas `(0,.54,.2)` | Metal e `E0603A` |

## Cabeça e rosto

Rosto da base comum, à mostra do T0 ao T2 (R2). O vão vai da aba do elmo, em `y=.172`, até o queixo, e de `x=-.1` a `x=.1` entre as jugulares. Só a nasal cruza esse volume. Nesta seção e no gorjal vale esta ficha, não o blockout nem a folha de conceito, que cobriam o rosto.

| Peça | Construção | Material |
|---|---|---|
| Elmo | `lathe` 8 lados, facetado: `(.12,.172) (.128,.205) (.105,.26) (.06,.295) (0,.305)` | Aço |
| Nasal | `box(.024,.11,.02)` em `(0,.165,-.128)` | Metal |
| Jugulares | 2 × `box(.03,.185,.16)` em `(±.115,.0875,0)` | Aço |
| Proteção da nuca | `loft` 8 lados, facetado, em `(0,0,.075)`: `(0,-.02,.11,.075) (0,.18,.125,.08)`. Fica toda atrás do rosto. De costas é a peça mais vista da cabeça, por isso é aço claro | Aço |
| Crista | `MeshKit.plate`, espessura `.05`, rot y `-PI/2`: `(-.15,.17) (-.13,.27) (-.06,.36) (.05,.4) (.17,.37) (.25,.28) (.27,.15) (.1,.2)` | Laca `C23A22` |

## Armas e empunhadura

| Arma | Dados | Pose |
|---|---|---|
| Espada (`sword_shield`) | Cabo `cylinder(.022,.026,.2,8)`, couro; guarda `box(.28,.04,.06)` em `y=.11`, metal; lâmina `blade(.98,.095,.026,.14)` em `y=.12`, aço; pomo `sphere(.04,8)` em `y=-.13`, metal | Em `hand_r`: posição `(0,-.06,-.02)`, rotação `(-2.45,0,0)` |
| Escudo | `lathe` 16 lados, facetado, `(0,-.02) (.38,-.02) (.37,0) (.2,.025) (0,.03)`, rot x `-PI/2`, com a abóbada em -Z, a face externa; aro `torus(.35,.4,24)` escala `(1,.6,1)`; umbo `sphere(.08,10)` em `(0,0,-.03)`; miolo em laca, aro e umbo em metal | Em `hand_l`: posição `(-.104,-.007,-.003)`, `rotation_order = EULER_ORDER_XYZ`, rotação `(-1.5,.75,0)` |
| Machado (`greataxe`) | Forma atual, sem `Look.metal`: cabo em couro `3A2A22`, cabeça em aço, colar no metal do tier | Em `hand_r`: posição `(0,-.03,0)`, rotação `(-1.215,0,0)`. Repouso: `shoulder_r (.6,0,.2)`, `elbow_r (1.35,0,0)`, `shoulder_l (.05,0,-.12)`, `elbow_l` zerado |

Com o machado, a cabeça da arma fica acima do ombro direito e reforça o T.

No golpe vale J10: `strike_wrist` zero na espada e `(-1.235,0,0)` no machado, que faz o mesmo arco dela. Encaixes de raridade na OS-008. Encaixe só existe aceso; o pomo existe sempre.

## Viewmodel

Medidas em `documents/art/work_orders/OS-012-viewmodel.md`.

- Manopla de aço, com dedos em anéis de `torus` em volta do cabo, a mesma mão fechada das três classes.
- Antebraço de aço, com faixa de metal de tier no pulso e a 24 cm dele.
- Escudo com a face interna em couro `5A4632` e alça `3A2A22`.
- Em T1 ou mais, soma um punho de pele.
- O machado é de uma mão: com ele, braço e mão esquerdos não aparecem no viewmodel.

## Tiers

| Tier | Muda | Construção |
|---|---|---|
| T0, variante 0 (Cota de Malha) | Sem telha média, aço `8F8D88` na couraça e na telha alta. Faldas, braços, botas e cabeça seguem na ficha | Largura de 0,92 m. Telha alta: `(±.0855,-.13,.1662,.2) (±.0475,-.05,.1568,.195) (±.0095,.05,.1235,.17) (∓.019,.115,.0712,.11)`. Telha baixa, em metal: `(±.1496,-.22,.1012,.16) (±.132,-.15,.1188,.175) (±.0968,-.09,.0968,.145)`. Mesma origem. O metal aparece em 9 cm, como na variante 1 |
| T0, variante 1 (Couraça de Recruta) | Ficha completa | Largura de 0,99 m |
| T1 | **Gola de pele**, metal `C4D2E0` | `lathe` 14 lados em `chest`, escala z `.62`: `(.3,.5) (.29,.53) (.23,.57) (.17,.585)`, `EEF1F6`. A de antes (`(.4,.43)` a `(.15,.65)`, z `.72`) cobria o queixo e a boca, `.65` passa dos `.60` do queixo, e engolia os dois Selos: o frontal de `y` .30 a .46 e o traseiro, em `z .2`, de `y` .46 a .62, ficavam sob o pelo. Esta começa em `y .5`, acaba 1,5 cm abaixo do queixo e fica a 1,4 cm do Selo traseiro. Canela: a `_limb(.46,.09,.07)` fica escura (`23262E`) nos 4 tiers: com aço claro a zona baixa deixava de ser escura (V1) e a massa trocava de cor com o tier (P2, V2) |
| T2 | **Crista alta, ombreira 10% maior**, lâmina de 1,06 m, com o fio da OS-008 acompanhando, metal `D8B464` | Crista com escala y `1.5`. Nas telhas, multiplique `centro_x` e `raio_x` por `1.1` |
| T3 | **Máscara fechada, lâminas nas ombreiras**, capa de 1,42 m, metal `E6ECF5` | Máscara: `loft` 10 lados em `head (0,0,-.006)`: `(0,.02,.06,.08) (0,.1,.098,.112) (0,.19,.103,.116)`. Visor: `box(.11,.012,.02)` em `(0,.135,-.116)`, `0C0E14`, sem brilho. **Sem nasal no T3**: a barra vertical cruzando o visor desenha uma cruz (O2). A máscara e o visor dela, marcados `face_cover`, são as únicas peças que cobrem o rosto (R2, P8). Lâmina direita: `plate` espessura `.04` `(0,0) (.11,0) (.09,.2) (.03,.32)` em `chest (.33,.6,0)`, rot z `-.3`, `E6ECF5`. Lâmina esquerda: o perfil espelhado em x, na ordem inversa (`(.03,.32) (.09,.2) (.11,0) (0,0)` com x negativo) em `chest (-.33,.6,0)`, rot z `+.3`, para a malha não ficar do avesso (G1). A capa vai de 1,2 m para 1,42 m, sem peça nova |
