# OS-021: Rei Gélido, modelo novo

- **Agente:** `gameplay-developer`
- **Depende de:** nenhuma ordem aberta. A OS-022 (efeitos) depende desta, por causa das âncoras da seção 5.
- **Arquivos:** `src/visuals/enemies/frost_king_model.gd` (novo), `src/visuals/creature_factory.gd` (só `_frost_king`), `src/visuals/creature_rig.gd` (só os dois tempos da seção 7), `tests/unit_tests.gd`, `tests/visual/monster_metrics.gd` e `tests/visual/hero_review.gd` (só a seção `weapon_poses` do relatório, seção 9)
- **Referência executável:** `documents/art/concepts/frost_king/rei_gelido_blockout.gd.txt` e a sonda `rei_gelido_sonda_poses.gd.txt`. Renders do blockout em `documents/art/review/frost_king_blockout/`. Renders do modelo atual, para comparar, em `documents/art/review/frost_king_atual/`.
- **Fora do escopo:** os outros monstros e `EnemyParts` (o esqueleto e o golem continuam usando), as curvas de animação do `CreatureRig` (swing, overhead, thrust), os efeitos de ataque (OS-022), escala e cápsula (ficam como estão, seção 3), `Look`, heróis, `style_guide.md`.
- **Estado:** Reprovada em 08/11/2026 na primeira revisão, com duas correções numéricas (seção "Revisão 1"). Renders de entrega em `documents/art/review/frost_king_os021/`.

## Problema

Diagnóstico do `game-architect` contra o guia, conferido nos renders e na medição em `report.json`:

| # | Diagnóstico | Conferido |
|---|---|---|
| 1 | J1 e J2 no cotovelo e no joelho | Confirmado. `shoulder_elbow` com vão de +0,0456 m no rig (+0,114 m no mundo), `hip_knee` com 0,0. Em `walk_side.png` os braços e as pernas são cilindros soltos |
| 2 | `Look.metal` com textura de ferrugem | Confirmado: as manchas marrons de `neutral_frost_king.png` são ela, em placa, perna e capacete, e o padrão aparece espelhado nas canelas. Discordo de um detalhe: `look.gd:77` desliga o triplanar de mundo, então a textura anda com a peça e não desliza. O defeito é a sujeira em si (pilar 5), a 1,6 repetições por metro do rig, o que dá manchas de 0,5 m no mundo |
| 3 | Ouro e coroa não lembram o troféu | Confirmado. O "ouro" é `9FB8D0`, um cinza-azulado, e lê como aço fosco. A coroa são 7 lascas de 0,2 a 0,34 m soltas no topo do elmo, sem aro. `boss_crown` ("Estilhaço da Coroa") e `boss_plate` ("Placa Real Congelada") não têm dono visível |
| 4 | Capa no `chest`, sem `cloth_back` | Confirmado. Em `walk_back.png` a perna aparece por cima da capa na altura do joelho: ela fura. A capa também não abre com a velocidade |
| 5 | Espada de uns 5 m | Medido: ponta a 5,16 m à frente e a 3,55 m de altura, 15° para cima, com a mão a 2,18 m. Fora de escala com o corpo (a lâmina sozinha tem 4,6 m no mundo) |
| 6 | E2 | Elmo de 0,34 e coroa até 0,60 acima do joint da cabeça. A coroa dobra a altura da cabeça |
| 7 | Cápsula | Raio horizontal de 1,77 m contra 1,5 m, 95 vértices fora, excesso de 0,533 m, pés a 11 cm abaixo do chão |

Outros defeitos que só os renders mostram: as ombreiras são esferas redondas, que é linguagem de herói (pilar 3); os olhos são dois pontos brancos redondos sobre uma tarja preta; a placa do peito é uma caixa lisa sem relação com o resto; o cristal do peito aponta para fora como um espinho solto em vez de ser o núcleo do corpo.

## Decisões de arte

| Questão | Decisão | Motivo |
|---|---|---|
| Sujeira (pilar 5) | **Não.** O chefe tem acabamento limpo: `Look.matte`, sem textura, placa facetada | O chefe é o modelo mais visto do jogo e o mais próximo dos heróis na escala de detalhe. Sujeira de textura em peça de 0,5 m lê como defeito, não como ferrugem |
| Metal ou fosco | `Look.matte` com `metallic` de até 0,45 (M3). `Look.metal`, `Look.hero` e `DungeonMaterials.iron` ficam fora do arquivo | `Look.hero` traz luz de personagem (M4), que é de herói. `Look.metal` é a textura |
| Cápsula | **O corpo cabe na cápsula atual.** Escala 2,5, `body_radius` 1,5 e `body_height` 5,8 não mudam. Capa, espada e garra da mão esquerda podem sair | Cápsula maior aproxima o chefe de tudo na sala do trono, com raio 27 e colunas, e ele já bloqueia o jogador. O blockout cabe com folga (raio 1,425, excesso de -0,032 m) sem perder a silhueta |
| Letra da silhueta | **M**: pico da coroa no centro, um espinho de gelo em cada ombreira e os dois chifres entre eles. Corpo estreito e capa fechando a base | Herói é T, Y e A. O M é a única letra que o chefe tem, e a escala de 3 vezes já o separa dos heróis |
| Valor | Massa clara em cima (couraça, ombreiras, elmo, antebraços), massa escura embaixo (coxas, canelas, sabatões, saia, braço) | Mesma lógica de V1: o jogador a 5 m vê sobretudo joelho a peito, o fundo do peito é a parede escura e o fundo da perna é a neve. Conferido em `lineup.png` |
| O ouro do rei | **Ouro `D8B464` em acabamento**: aro da coroa, gorjal, cinto, borda das ombreiras, guarda e pomo da espada. Nunca em massa | É o metal do T2 dos heróis (seção 9 do guia), o "ouro do rei" do pilar 4. O troféu `boss_crown` passa a ser o aro de ouro com as pontas de gelo |
| O aço pálido | Massa clara `B4C3D6`, na família da prata `C4D2E0` do T1 e da platina `E6ECF5` do T3 | V5 limita massa a L* 88. A platina fica para pontuação nos heróis. `boss_plate` é esta couraça |
| E2 | A cabeça é medida **sem** coroa, chifre e cristal de cabeça (S3). O elmo tem 0,32 m no rig, 1/7,07 da altura | Ver proposta M2 |
| Capa | Em `cloth_back`, ver seção 8 | J4 passa a valer para o chefe (M3) |
| J9 | **Não vale** para o chefe | A curva do `thrust` leva a lâmina a 61° para cima no fim do golpe (seção 7). Aceito: a habilidade é de comando, e o efeito das estacas vem do chão. A alavanca, se a arte pedir outra coisa, é uma curva por criatura, fora desta ordem |

## Especificação visual

Unidades em metros do rig, antes da escala 2,5. Frente em -Z, mão direita em +X. A espada fica na mão direita. Perfil de `lathe` e anéis de `loft` sobem em y (G1). Toda peça entra por `rig.part` ou `adopt_meshes`, para o `flash_hit` pegar o corpo inteiro, a capa e a espada.

### 1. Esqueleto e passada

`CreatureRig.biped_skeleton(rig, 1.0, 1.1, 1.1)`. Disso saem, em altura absoluta: pelve 0,95, `chest` 1,07, `head` 1,65, ombros `(±0,286, 1,53)`, cotovelo 0,352 abaixo do ombro, mão 0,33 abaixo do cotovelo, quadris `(±0,11, 0,93)`, joelhos a 0,47.

| Variável | Valor |
|---|---|
| `stride` | 0,5 |
| `step_rate` | 1,5 |
| `knee_bend` | 0,85 (padrão) |
| `arm_swing_r` | 0,2: o braço da espada quase não balança, para a ponta não arrastar |
| `arm_swing_l` | 0,5 |

Não chame `set_strike_grip` nem `set_rest`: um teste exige `hand_r` zerado no chefe e o repouso vem só do `_pose_biped`.

### 2. Paleta e materiais

No máximo 11 materiais. `Look.matte(cor, roughness, metallic)`, que tem o `rim` de 0,35 do projeto e nenhuma emissão.

| Nome | Hex | Roughness | Metallic | Sombreamento | Onde |
|---|---|---|---|---|---|
| `light` | `B4C3D6` | 0,42 | 0,35 | Facetado | Couraça, elmo, ombreira alta, antebraço, espinhos do cotovelo e do joelho |
| `dark` | `2B3548` | 0,50 | 0,30 | Facetado | Coxa, canela, sabatão, saia, braço, juntas, mão, ombreira baixa, punho da espada |
| `gold` | `D8B464` | 0,40 | 0,45 | Facetado | Aro da coroa, gorjal, cinto, borda das ombreiras, guarda, pomo, pingente do cinto |
| `bone` | `D9E6F2` | 0,60 | 0 | Facetado | Chifres |
| `cape` | `4468A8` | 0,90 | 0 | Duas faces | Capa. Cópia de `Look.matte(...)` com `cull_mode` desligado (M1) |
| `visor` | `06070B` | 0,40 | 0 | Facetado | Fenda do elmo |
| `ice` | `DungeonMaterials.crystal((0,14, 0,42, 0,72), (0,65, 0,92, 1,0), 2,0)` | Shader | | | Espinhos de ombreira, cristais das costas, garras da mão esquerda. Compartilhado |
| `crown_material` | O mesmo `crystal`, `.duplicate()` | Shader | | | Só as 5 pontas da coroa. Privado, para a OS-022 acender |
| `core_material` | `crystal((0,2, 0,55, 0,9), (0,7, 0,95, 1,0), 2,4)`, `.duplicate()` | Shader | | | Só o núcleo. Privado |
| `blade_material` | `crystal((0,18, 0,46, 0,76), (0,72, 0,94, 1,0), 1,5)`, `.duplicate()` | Shader | | | Só a lâmina. Privado |
| `eye` | `Look.glow(glow, 7.0)` | | | | Olhos. `glow` é o argumento do `assemble` |

A capa foi de `2E4C7C` para `4468A8` no blockout: no render da sala, a primeira escolha sumia contra a parede (V4). Os três `.duplicate()` são necessários: sem eles o brilho de uma peça mudaria todas as que dividem o cache do `crystal` (M1). Cada um vai para o rig com `rig.set_meta(&"core_material", m)` (e `&"crown_material"`, `&"blade_material"`).

### 3. Peças

Nome entre aspas é o `name` do nó, para os testes. `rng` é um único `RandomNumberGenerator` com `seed = 31`, usado na ordem das linhas abaixo; só altura, raio, posição e rotação contam como medida, a inclinação aleatória de cada ponta (`lean` 0) não.

**Tronco (`chest`, `pelvis`)**

| Peça | Joint | Construção | Mat. |
|---|---|---|---|
| Couraça `"couraca"` | `chest` | `loft` de 10 lados, facetado, anéis `(0,-.12,.20,.15) (0,.08,.22,.17) (0,.30,.29,.20) (0,.46,.31,.19) (0,.56,.15,.12)` | `light` |
| Gorjal `"gorjal"` | `chest` | `lathe` de 10 lados, facetado, sem tampas, perfil `(.17,.50) (.19,.55) (.16,.62) (.15,.66)`, escala `(1,1,.9)` | `gold` |
| Saia `"saia"` | `pelvis` | `lathe` de 10 lados, facetado, sem tampas, perfil `(.30,-.26) (.27,-.14) (.23,0) (.21,.06)`, escala `(1,1,.78)` | `dark` |
| Cinto `"cinto"` | `pelvis` | `lathe` de 12 lados, facetado, perfil `(.225,-.01) (.235,.05) (.22,.09)`, escala `(1,1,.78)` | `gold` |
| Pingente do cinto | `pelvis` | `shard(.05,.16,rng,4,0)` em `(0,0,-.19)`, rot x `PI` | `gold` |
| Núcleo `"nucleo"` | `chest` | `lathe` de 6 lados, facetado, perfil `(0,-.16) (.08,-.02) (0,.17)`, em `(0,.28,-.205)`, escala `(1,1,.7)` | `core_material` |
| Ombreira alta `"ombreira_alta_r/l"` | `chest` | `lathe` de 6 lados, facetado, perfil `(0,-.06) (.23,-.05) (.27,.03) (.19,.12) (.09,.19) (0,.21)`, origem `(±.30,.46,0)`, escala `(1,1,1.1)` | `light` |
| Ombreira baixa | `chest` | `lathe` de 6 lados, facetado, perfil `(0,-.2) (.21,-.19) (.26,-.11) (.24,-.05)`, mesma origem e escala | `dark` |
| Borda da ombreira | `chest` | `lathe` de 6 lados, facetado, sem tampas, perfil `(.25,-.2) (.27,-.16) (.26,-.12)`, mesma origem e escala | `gold` |
| Espinho grande da ombreira | `chest` | `shard(.065,.40,rng,5,0)` em origem `+ (±.03,.17,0)`, rot z `∓.35` | `ice` |
| Espinho pequeno da ombreira | `chest` | `shard(.05,.28,rng,5,0)` em origem `+ (±.11,.12,0)`, rot z `∓.5` | `ice` |
| Cristais das costas ×3 | `chest` | `shard(.055, .40-|x|, rng, 4, 0)` em `(x,.40,.20)` com `x` em `-.12, 0, .12`, rot `(.18, 0, -x·1,2)` | `ice` |

Ombreiras ficam no `chest` (J3): o braço se move por baixo delas.

**Cabeça (`head`)**

| Peça | Construção | Mat. |
|---|---|---|
| Elmo `"elmo"` | `loft` de 10 lados, facetado, anéis `(0,-.02,.15,.17) (0,.07,.19,.21) (0,.17,.20,.22) (0,.25,.15,.17) (0,.30,.06,.07)`. Altura 0,32 | `light` |
| Aro da coroa `"coroa_aro"` | `loft` de 10 lados, facetado, anéis `(0,.18,.215,.235) (0,.20,.205,.225) (0,.26,.17,.19) (0,.285,.16,.18)` | `gold` |
| Fenda `"visor"` | `box(.30,.03,.05)` em `(0,.13,-.205)` | `visor` |
| Olhos `"olho_r/l"` | `plate(contorno, .012)` em `(±.085,.13,-.236)`. Contorno do lado `s` (+1 direito, -1 esquerdo): `(-.065s,-.012) (0,.012) (.07s,.02) (0,-.004)`, invertido quando `s < 0`. A ponta de dentro fica mais baixa que a de fora: é o olhar fechado e frio do rei, sem expressão de raiva (R1 só vale para herói) | `eye` |
| Pontas da coroa ×5 | `shard(.05, h, rng, 5, 0)` com `h` em `.34 .27 .20 .20 .27`. Ângulo `a = TAU·i/5`, posição `(sin a·.14, .275, -cos a·.14)`, rot `(-cos a·.1, 0, -sin a·.1)`. A de `h = .34` fica na frente | `crown_material` |
| Chifres ×2 `"chifre_r/l"` | Dois `shard` em cada lado. Base `shard(.06,.2,rng,5,0)` em `(±.17,.15,0)`, rot z `∓1,0`. Ponta `shard(.045,.27,rng,5,0)` em `(±.31,.24,0)`, rot z `∓.3`. O par forma o chifre dobrado para cima | `bone` |

Sem nasal vertical sobre a fenda: fenda horizontal com barra vertical é cruz (O2).

**Braços (`shoulder_*`, `elbow_*`, `hand_*`), cada lado**

| Peça | Joint | Construção | Mat. |
|---|---|---|---|
| Bola do ombro `"junta_ombro"` | `shoulder_*` | `sphere(.12, 8)` | `dark` |
| Braço | `shoulder_*` | `CreatureRig.limb(.39, .095, .085)` | `dark` |
| Cotovelo `"junta_cotovelo"` | `elbow_*` | `sphere(.105, 8)` | `dark` |
| Espinho do cotovelo | `elbow_*` | `shard(.05,.17,rng,4,0)` em `(0,0,.09)`, rot x `PI/2` (aponta para trás) | `light` |
| Antebraço | `elbow_*` | `CreatureRig.limb(.37, .09, .075)` | `light` |
| Punho | `hand_*` | `sphere(.095, 8)` | `dark` |
| Garras de gelo ×3 (só `hand_l`) | `hand_l` | `shard(.03,.2,rng,4,0)` em `((i-1)·.06, -.07, -.08)`, rot `(-1,9, 0, (i-1)·.25)` | `ice` |

**Pernas (`hip_*`, `knee_*`), cada lado**

| Peça | Joint | Construção | Mat. |
|---|---|---|---|
| Coxa | `hip_*` | `loft` de 8 lados, facetado, anéis `(0,-.50,.10,.11) (0,-.25,.115,.13) (0,0,.125,.15)` | `dark` |
| Joelho `"junta_joelho"` | `knee_*` | `sphere(.115, 8)` | `dark` |
| Espinho do joelho | `knee_*` | `shard(.06,.2,rng,4,0)` em `(0,-.03,-.08)`, rot x `-PI/2 + .2` (aponta para a frente e um pouco para baixo) | `light` |
| Canela | `knee_*` | `loft` de 8 lados, facetado, anéis `(0,-.44,.075,.10) (0,-.30,.095,.12) (0,-.10,.105,.125) (0,.02,.10,.12)` | `dark` |
| Sabatão | `knee_*` | `plate(contorno, .17)`, contorno `(-.15,-.47) (.30,-.47) (.40,-.42) (.30,-.36) (.10,-.34) (-.12,-.34) (-.16,-.41)`, rot y **`+PI/2`** (a ponta vai para -Z; com `-PI/2` ela vai para trás, erro que o primeiro blockout teve) | `dark` |

Sola em `y = -.47` no joint do joelho, que fica a 0,47: o pé toca o chão em y 0. As coxas ficam a 4 cm uma da outra, para as pernas lerem como duas de frente.

### 4. Brilho

| Onde | O quê | Energia |
|---|---|---|
| Olhos | `Look.glow(glow, 7.0)`, o teto do chefe. Plano de 1,2 cm de espessura, pontudo | 7,0 |
| Núcleo no peito | `core_material`, cristal. Lê azul, não branco | `glow` 2,4 em repouso |
| Pontas da coroa | `crown_material` | `glow` 2,0 em repouso |
| Espinhos de ombreira, costas, garras | `ice` | `glow` 2,0 |
| Lâmina | `blade_material` | `glow` 1,5 |
| Todo o resto | Nada emite. Nenhum material de placa, ouro, osso ou capa tem emissão | |

Linguagem de inimigo (seção 6 do guia): o brilho está nos olhos e no núcleo, em formas pontudas, na cor do tema. Os cristais não seguem `enemy_glow` hoje, e isso fica como a decisão de 01/11 (OS-006).

### 5. Âncoras e metas (contrato com a OS-022)

Joints sem pose. O `_set_joint` ignora nome que ele não conhece, então nada se move por conta própria. Criar com `rig.joint(nome, pai, posição)`.

| Joint | Pai | Posição | Uso |
|---|---|---|---|
| `weapon_tip` | Raiz da espada | `(0, 1.53, 0)` (base da lâmina 0,27 mais 1,26 de comprimento) | Ponta da lâmina |
| `core` | `chest` | `(0, .28, -.23)` | Centro do núcleo |
| `crown` | `head` | `(0, .30, 0)` | Centro da coroa |
| `cloth_back` | `chest` | `(0, .54, .20)` | Pai da capa (seção 8) |

Metas no rig, lidas pela OS-022: `blade_material`, `core_material`, `crown_material`.

### 6. Espada e repouso

A raiz é um `Node3D` chamado `"Sword"`, filho de `hand_r`, com rotação x **`-PI/2 - 0,6`**. O 0,6 abaixa a ponta em 34° em relação à do modelo atual. Peças no espaço da raiz, com a lâmina em +Y:

| Peça | Construção | Mat. |
|---|---|---|
| Punho | `cylinder(.03,.034,.42,8)` em `(0,.01,0)` | `dark` |
| Pomo | `sphere(.065,6)` em `(0,-.21,0)` | `gold` |
| Guarda `"guarda"` | `plate(contorno, .09)` em `(0,0,0)`, contorno `(-.36,.17) (-.30,.255) (-.08,.285) (.08,.285) (.30,.255) (.36,.17) (.12,.225) (-.12,.225)`. A guarda é horizontal, em X | `gold` |
| Lâmina `"lamina"` | `MeshKit.blade(1.26, .26, .07, .16)` em `(0,.27,0)` | `blade_material` |

Do pomo à ponta são 1,81 no rig, 4,5 m no mundo. Da mão à ponta, 1,53 e 3,83 m. A lâmina sozinha tem 3,15 m e 0,65 m de largura. O cabo tem de ficar dentro do punho (esfera de raio 0,095): conferir no render.

Resultado em repouso, depois de `animate(0, 0)`: ponta a 3,85 m à frente, 0,91 m de altura e lâmina a -19° (a atual era +15°, a 5,16 m). Andando a 3,5 m/s, a ponta fica entre 0,37 e 1,36 m de altura: nunca encosta no chão.

### 7. Poses

As curvas do `_pose_biped` não mudam. O que muda é o encaixe da espada e dois tempos.

**Tempos por criatura.** `STRIKE_TIME` (0,16) e `RECOVER_TIME` (0,32) viram variáveis de `CreatureRig` com esses valores como padrão. O chefe define:

| Variável | Chefe | Padrão |
|---|---|---|
| `strike_time` | **0,18 s** | 0,16 |
| `recover_time` | **0,50 s** | 0,32 |

Golpe mais curto que o preparo e volta lenta dão peso. O golpe do chefe começa no `skill_fired`, depois do dano: 0,18 s é o máximo para não separar visual e dano. A OS-022 toca o efeito de impacto 0,09 s depois do disparo, o ponto médio do golpe, onde a lâmina cruza a frente.

**Leitura de cada animação** (medidas no blockout com a sonda; mão e ponta em metros no mundo, em relação à origem do chefe, frente = +):

| Animação | Quem usa | Preparo (pose segurada o cast inteiro) | Fim do golpe |
|---|---|---|---|
| `swing` | `boss_strike` (0,55 s), `boss_cleave` (1,25 s) | Espada vertical sobre o ombro direito: mão a 4,46 m de altura, ponta a 8,20 m e quase em cima do peito (frente -0,11 m), lâmina a +78° | Varrida para a esquerda, na altura do peito: mão em x -0,34, ponta em x -2,80, 3,73 m à frente e 2,82 m de altura, lâmina a +5° |
| `overhead` | `boss_slam` (1,7 s), `boss_nova` (2,4 s) | As duas mãos no alto: mão esquerda a 5,41 m, mão direita a 3,19 m, ponta a 5,87 m de altura e 3,85 m à frente, lâmina a +45° | Golpe à frente: ponta a 4,81 m, 1,52 m de altura, lâmina a -9° |
| `thrust` | `boss_spikes` (1,15 s) | Braço recuado, ponta a 4,26 m à frente e 4,98 m de altura, lâmina a +32° | Braço estendido à frente na altura da cabeça: mão a 1,81 m à frente e 3,76 m de altura, lâmina a +61° |

O preparo do `strike` tem 0,55 s e o da nova 2,4 s. A curva sobe em raiz (rápido no começo) e a pose fica segurada até o disparo: a nova segura a pose de `overhead` por uns 2 s. É o aviso, e quem o reforça é a OS-022. Não dê mais animação do que isso nesta ordem.

### 8. Capa

`MeshKit.cloth(.6, .98, 1.38, .24)` no joint `cloth_back`, que fica em `chest (0, .54, .20)`. Material `cape`, duas faces, `cast_shadow` desligado (é como o relatório separa a capa do corpo). A capa abre com a velocidade até 0,55 rad, e a perna nunca a atravessa (J4). Medido no blockout: folga mínima de 0,32 m entre os vértices da capa e os da perna, em 400 quadros de passo a 3,5 m/s.

Pode estender `EnemyParts.cape` com um parâmetro opcional de joint, sem mudar os outros chamadores, ou montar a capa direto no modelo.

### 9. Orçamento e relatório

| | Atual | Blockout | Teto desta ordem | Teto do guia |
|---|---|---|---|---|
| Partes | 44 | 63 | 75 | 90 |
| Triângulos | 1.890 | 2.481 | 3.500 | 8.000 |
| Materiais | 9 | 11 | 11 | 12 |

O que sobra de folga fica para a OS-022 (efeitos têm orçamento próprio) e para uma segunda passada de detalhe.

`monster_metrics.gd` ganha `weapon_poses(rig, world_scale)`, e o `hero_review.gd` grava no `report.json` do modo `--monster`, em `weapon_poses`, para repouso e para `swing`, `overhead` e `thrust` (preparo e fim do golpe): posição de `hand_r`, `hand_l`, `weapon_tip` e `pitch_deg` (ângulo da lâmina da mão à ponta). Procedimento igual ao da sonda: `wind_up(anim, 1.0)`, `animate(2.0, 0.0)`; `strike(anim)`, `animate(0.18, 0.0)` (o fim do golpe é depois de `strike_time`). Sem `weapon_tip`, o campo sai nulo.

## Mudança no guia

Aprovadas em 08/11/2026 e aplicadas em `style_guide.md` (E2, J4, seções 7, 8, 9 e 13). Texto como aplicado:

| # | Regra | Texto proposto | Motivo |
|---|---|---|---|
| M1 | Seção 7, primeiro parágrafo | "`Look.metal` fica proibido em herói, em arma de herói e no chefe: a textura dele é a sujeira que aparece nos renders." | O chefe passa a seguir o pilar 5. Monstro comum segue como está até ter ordem própria |
| M2 | E2 | "A cabeça, sem coroa, chifre e cristal de cabeça (S3), nunca passa de 1/7 da altura do corpo. Vale para herói e chefe." | Esclarece o que se mede. Sem isso, a coroa de ponta alta que o chefe precisa reprovaria uma regra escrita para a proporção infantil |
| M3 | J4 | "O joint é opcional: bichos e a maioria dos inimigos não o criam. O chefe com capa o cria, e as pernas nunca a atravessam." | O chefe passa a ter capa em `cloth_back` |
| M4 | Seção 8, abertura | "J1 a J3 e J8 valem para todo modelo bípede, herói ou monstro. A medida é `joint_gaps` do `--monster`." | O diagnóstico 1 só existe porque o guia não dizia isso. Esqueleto e goblin ainda quebram J2 |
| M5 | Seção 9, depois da tabela | "O Rei Gélido veste o que dá: acabamento em ouro `D8B464` (T2 dos heróis) e massa clara em aço pálido `B4C3D6` (família da prata `C4D2E0` e da platina `E6ECF5`). O ícone de `boss_crown` é o aro de ouro com pontas de gelo, e o de `boss_plate` é a couraça pálida." | Pilar 4. Hoje a seção 9 fala do que o herói veste e nunca de quem o largou |
| M6 | Seção 13 | Uma linha de 07/11/2026 com o resumo das decisões desta ordem | Registro |

## Critérios de aceite

Renders: comando abaixo, em cópia descartável. Dados: `report.json` do mesmo comando.

```bash
godot --display-driver x11 --disable-vsync --resolution 1920x1080 --path . res://tests/visual/hero_review.tscn -- --out=DIR --monster=frost_king
godot --display-driver x11 --disable-vsync --resolution 1600x900 --path . res://tests/visual/lineup.tscn -- --out=DIR
```

| # | Verificação | Onde | Alvo |
|---|---|---|---|
| 1 | Orçamento | `report.json` | `parts` até 75, `tris` até 3.500, `materials` até 11 |
| 2 | Cápsula | `body` | `fits` e `fits_radius` verdadeiros, `overflow_m` até -0,02, `vertices_outside` 0, `radial_max_m` até 1,46 |
| 3 | Pés e altura | `body`, `world_height_m` | `box_min_m[1]` entre -0,02 e 0,03; `world_height_m` entre 5,5 e 5,8; `box_size_m[0]` entre 2,6 e 3,0 |
| 4 | J2 | `joint_gaps` | As 8 entradas com `j2_ok` verdadeiro e `gap_m` até -0,03 (blockout: de -0,10 a -0,155) |
| 5 | J1 | Teste | As peças `"junta_ombro"`, `"junta_cotovelo"` e `"junta_joelho"` existem nos dois lados, têm esfera centrada no joint e raio igual ou maior que o do membro (0,12, 0,105, 0,115 contra 0,095, 0,09, 0,10) |
| 6 | Acabamento limpo | Teste | Nenhum material de `StandardMaterial3D` do rig com `albedo_texture` ou `normal_texture`. O código-fonte de `frost_king_model.gd` não contém `Look.metal`, `Look.hero`, `HeroBase`, `WeaponKit` nem `iron` |
| 7 | Brilho | Teste | Entre os `StandardMaterial3D`, só `eye` tem `emission_enabled` (energia 7,0, cor igual a `glow`). Os outros emissivos são os 4 `ShaderMaterial` de cristal (`ice`, `crown_material`, `core_material`, `blade_material`). Núcleo, coroa e lâmina são instâncias privadas: diferentes do material do cache e uma por meta |
| 8 | Âncoras | Teste | Existem `weapon_tip`, `core`, `crown` e `cloth_back`. `weapon_tip` está na raiz da espada, em `(0, 1.53, 0)` com 2 cm de tolerância. As metas existem. `hand_r.rotation == Vector3.ZERO` depois de qualquer animação |
| 9 | `flash_hit` | Teste | Depois de `flash_hit()`, todo `MeshInstance3D` do rig, incluindo espada e capa, tem `material_overlay` |
| 10 | Tempos | Teste | `strike_time` 0,18 e `recover_time` 0,50 no chefe. Qualquer outro monstro e herói seguem com 0,16 e 0,32 |
| 11 | Repouso | `weapon_poses` | `weapon_tip` com altura de 0,6 a 1,3 m, 3,4 a 4,3 m à frente, `pitch_deg` entre -26 e -12. Mão direita em x `0,72 ± 0,1` |
| 12 | Passo | Teste | 400 quadros a 3,5 m/s: altura mínima da ponta de 0,2 m ou mais; nenhum vértice de perna a menos de 0,05 m da capa, medido em z no mesmo trecho de altura; o ponto mais baixo do corpo, em qualquer quadro, não passa de -0,02 m (nada fura o chão) |
| 13 | Preparo | `weapon_poses` | `swing`: ponta de 7,2 a 9,0 m de altura, até 1,5 m à frente, `pitch_deg` 65 ou mais. `overhead`: mão esquerda a 4,5 m ou mais, ponta de 5,0 a 6,8 m, `pitch_deg` de 35 a 60. `thrust`: ponta a 3,5 m ou mais à frente, `pitch_deg` de 20 a 45 |
| 14 | Fim do golpe | `weapon_poses` | `swing`: ponta em x -1,5 ou menos, 3,0 m ou mais à frente, `pitch_deg` de -10 a +15. `overhead`: ponta de 4,2 a 5,5 m à frente, de 0,5 a 2,5 m de altura, `pitch_deg` de -20 a +5. `thrust`: mão a 1,4 m ou mais à frente e de 3,2 a 4,2 m de altura, `pitch_deg` até 75 |
| 15 | Silhueta M | `neutral_frost_king.png`, vista frontal e de costas | Pico da coroa pelo menos 0,4 m acima das pontas das ombreiras; dois chifres visíveis entre os picos; nenhuma peça redonda grande no topo (sem esfera de ombro à mostra) |
| 16 | Acabamento | `neutral_frost_king.png` | Nenhuma mancha marrom, nenhum padrão repetido na placa. Facetas legíveis. Olhos como fenda pontuda, com a ponta de dentro mais baixa |
| 17 | Cruz (O2) | `neutral_frost_king.png` | Sem barra vertical cruzando a fenda ou a faixa do peito. A guarda da espada é objeto reconhecível e fica fora da regra |
| 18 | Rig | `walk_side.png`, `walk_back.png` | Cotovelo e joelho sem falha, capa abre para trás e nenhuma perna aparece por cima dela. Pés apontando para a frente |
| 19 | Poses | `pose_swing`, `pose_overhead`, `pose_thrust` | As três leituras da seção 7. Espada firme na mão, cabo dentro do punho, nada atravessando o capacete |
| 20 | Sala | `lineup.png` | Massa clara sobre a parede escura, pernas escuras sobre a neve, ouro só em pontuação, capa azul legível contra a parede. Comparável ao `lineup.png` do blockout |
| 21 | Orçamento de pontos de ouro | `neutral_frost_king.png` | Ouro menor que 12% da área visível da silhueta |
| 22 | Fábrica | Teste | `CreatureFactory.build(&"frost_king", glow)` devolve o modelo novo, o id não mudou e `_frost_king` só delega |
| 23 | Suítes | `check_scripts`, `unit_tests`, `flow_test` | Sem falhas. O teste que exige `hand_r` zerado no chefe passa sem mudança |

O blockout mede 63 partes, 2.481 triângulos, 11 materiais, `fits` verdadeiro com excesso de -0,032 m, 5,658 m de altura, 2,85 m de largura, J2 entre -0,10 e -0,155.

## Revisão 1 (08/11/2026): REPROVADO, duas correções numéricas

Revisão sobre `documents/art/review/frost_king_os021/` e `report.json`. O modelo entregue é o do blockout: 63 partes, 2.481 triângulos, 11 materiais, `fits` verdadeiro (excesso de -0,032 m), J2 entre -0,10 e -0,155, `weapon_poses` iguais aos da sonda. Dois itens ficam abertos. Os dois são mudança de número, sem peça nova, sem mudança de contagem e sem nova rodada de especificação. A reapreciação é por `report.json`, `neutral_frost_king.png`, `walk_side.png` e `walk_back.png`.

Render de referência da correção, medido numa cópia descartável com as mudanças abaixo: `documents/art/review/frost_king_blockout_rev1/`. O blockout em `concepts/frost_king/rei_gelido_blockout.gd.txt` já traz os valores novos. Onde esta seção divergir das seções 3, 5 e 8, vale esta.

### 1. Sabatão (critério 12): decisão (b), desenho novo

O ponto mais baixo do corpo no passo a 3,5 m/s é -0,059 no rig e -0,146 m no mundo, contra o limite de -0,02 m. Medi o mesmo valor com o modelo entregue. A causa é a do implementador: o pé é uma peça rígida sem tornozelo e a ponta de 0,40 afunda quando a perna vai para trás. No `walk_side.png` a ponta do pé de trás aponta para baixo e fura o piso em 15 cm. No `walk_back.png` o pé de trás vira um punhal que sai por baixo da capa. A 2,5 vezes de escala isso se vê.

Por que não as outras:
- **(a) aceitar como traço do rig:** o guerreiro afunda 4 cm em 1,9 m, e o chefe 14,6 cm em 5,7 m, nas mesmas condições. O corpo dele é o que o jogador vê de perto, de lado, ao contornar.
- **(c) tornozelo no rig:** muda os heróis, que já estão aprovados, para resolver um problema que um número resolve no chefe. Pode ser aberta depois, por outra razão. Não bloqueia esta ordem.

Variantes medidas (mesma sonda, 110 quadros a 3,5 m/s, ponto mais baixo do corpo sem espada nem capa):

| Sabatão | Rig | Mundo |
|---|---|---|
| Entregue | -0,059 | -0,146 |
| Sola curta, ponta levantada 6,5 cm (`(0,12,-.47)`, ponta em `(.34,-.405)`) | -0,007 | -0,018 |
| Curto, ponta em `(.30,-.41)` | -0,001 | -0,003 |
| **Escolhido** | **-0,001** | **-0,003** |
| Ponta a `(.36,-.385)` | -0,006 | -0,014 |

O escolhido mantém o dedo longo e pontudo (linguagem de inimigo) e o pé de 0,48 no rig, 1,2 m no mundo. A sola plana encurta de 0,45 para 0,24 e a ponta sobe 7,5 cm: é o dedo levantado de uma bota de rei, e é o que impede a ponta de entrar no piso quando a perna recua.

Troque a constante e nada mais na peça (rotação em y `+PI/2`, espessura `0,17`, material e joint iguais):

```
SABATON = (-.14,-.47) (.10,-.47) (.34,-.395) (.26,-.355) (.08,-.34) (-.12,-.34) (-.16,-.41)
```

Efeitos: `knee_foot` continua em -0,10 (topo do pé a -0,34), `fits` e `box_min_m[1]` inalterados, partes e triângulos iguais. O teste do critério 12 volta ao limite de **-0,02 m** no mundo (o de regressão de -0,16 sai). Medido: -0,003 m.

### 2. Espinhos do cotovelo furam a capa (seu ponto 4, critérios 16 e 18)

Os pontos claros minúsculos na capa, de costas, são as pontas dos dois espinhos do cotovelo. O espinho tem 0,17 e sai de z 0,09: chega a z 0,26. A capa fica em z 0,20 a 0,22 na altura do cotovelo. A ponta passa 4 cm do rig por dentro do pano, e o esquerdo, que fica atrás da capa, aparece como um ponto claro. O blockout tinha o mesmo defeito, e eu não o vi no render dele: erro meu.

Duas mudanças, as duas juntas (**a segunda foi desfeita na Revisão 2**: ela fazia as pontas superiores da capa furarem as ombreiras de costas):

| Peça | Antes | Agora |
|---|---|---|
| Espinho do cotovelo | `shard(.05,.17,rng,4,0)` em `(0,0,.09)` | `shard(.05,.13,rng,4,0)` em `(0,0,.075)`. A ponta fica em z 0,205 |
| `cloth_back` | `chest (0,.54,.20)` | `chest (0,.54,.22)` |

Com as duas, a ponta fica 3,5 cm do rig (8,75 cm no mundo) à frente do pano em repouso, e os pontos somem do render (conferi na vista de costas). A capa mais atrás também aumenta a folga da perna.

### Itens do implementador que não pedem mudança

- **Preparo do `swing` com a espada na frente do rosto (seu ponto 2):** é paralaxe da câmera lateral. A mão direita fica a 2,04 m do eixo do corpo, para o lado da espada, e a ponta a 2,72 m. Medi em 3D, vértice a vértice, a distância da espada à cabeça (elmo, coroa, chifres e cristais): 1,30 m no preparo do `swing`, com a guarda a 1,38 m. Nas outras seis fases, de 1,28 a 1,59 m. Sem contato e sem risco de furo. No fim do `swing` a espada passa a 0,09 m do tronco (peito e ombreiras): rente, sem tocar. Aceito.
- **Ouro com 11,5% da silhueta de frente e 6,2% de costas (critério 21):** dentro do teto de 12%. Aceito. A margem é de meio ponto: nenhuma ordem futura soma ouro ao chefe sem tirar de outro lugar.
- **Nomes que a ordem não fixava:** `chifre_ponta_r/l`, `ombreira_baixa_*`, `ombreira_borda_*` e `capa`. Aceitos, valem como contrato com os testes.
- **Pés do guerreiro:** a mesma causa e o mesmo traço do rig, sem relação com esta ordem. Não mexer.
- **Peça `plate` do sabatão vista de lado:** a ponta do pé tem facetas que, no fundo cinza do `hero_review`, parecem furos por terem quase a cor dele. É luz, não malha. Na sala (`lineup.png`) o pé lê como uma cunha escura. Sem mudança.

### Critérios da Revisão 1

| # | Verificação | Onde | Alvo |
|---|---|---|---|
| R1 | Pés no chão | Teste do critério 12 | Ponto mais baixo do corpo em 400 quadros a 3,5 m/s de -0,02 m ou mais (medido -0,003) |
| R2 | Sabatão | `walk_side.png` | A ponta do pé de trás não fica abaixo da sola do pé da frente. Pé com ponta levantada, sem ponta apontando para o chão |
| R3 | Capa | `neutral_frost_king.png` (vistas 4 e 5) e `walk_back.png` | Nenhum ponto claro isolado sobre o pano. O pé de trás não sai por baixo da capa como punhal |
| R4 | Contagens | `report.json` | 63 partes, 2.481 triângulos, 11 materiais. `box_min_m[1]` 0,0, `fits` verdadeiro, `joint_gaps` inalterados |
| R5 | Nada mais mudou | `weapon_poses` | Iguais aos do `report.json` entregue, com 0,02 m de tolerância |

Depois de aplicada, a OS-021 só precisa de uma conferência de arte nos três arquivos acima e de `unit_tests`. Não é preciso nova rodada completa.

## Revisão 2 (08/11/2026): REPROVADO, um número a desfazer

Conferência dos itens R1 a R5 sobre `documents/art/review/frost_king_os021/` regenerado. R1 (-0,004 m), R2, R4 e R5 passam. R3 falha, e a causa é um erro da minha Revisão 1.

- **R1:** ponto mais baixo do corpo em -0,004 m no mundo. Passa.
- **R2:** em `walk_side.png` a ponta do pé de trás fica acima da sola do pé da frente, com a ponta levantada. Passa.
- **R4:** 63 partes, 2.481 triângulos, 11 materiais, `fits` verdadeiro com -0,032 m, `box_min_m[1]` 0,0, `joint_gaps` iguais. Passa.
- **R5:** `weapon_poses` sem diferença contra o da cópia de referência (70 valores, diferença máxima 0,0). Passa.
- **R3:** os pontos claros sumiram, mas `cloth_back` em z 0,22 empurrou as quinas de cima da capa para dentro do domo das ombreiras. De costas (`walk_back.png` e vistas 4 e 5 do `neutral_frost_king.png`) aparecem duas fitas azuis atravessando a superfície de cada ombreira. O blockout, com `cloth_back` em z 0,20, não tem isso. Na Revisão 1 conferi só o recorte dos pontos e não olhei o topo da capa.

Correção, com `cloth_back` desfeito e o espinho um pouco mais curto para manter a folga com a capa em z 0,20:

| Peça | Revisão 1 | Agora |
|---|---|---|
| `cloth_back` | `chest (0,.54,.22)` | **`chest (0,.54,.20)`**, como na seção 5 original |
| Espinho do cotovelo | `shard(.05,.13,rng,4,0)` em `(0,0,.075)` | **`shard(.05,.12,rng,4,0)` em `(0,0,.07)`**. A ponta fica em z 0,19, 3 cm do rig (7,5 cm no mundo) à frente da capa na altura do cotovelo (z 0,22) |

Conferido numa cópia descartável: topo da capa limpo nas duas ombreiras, sem pontos claros no pano. Referência atualizada em `documents/art/review/frost_king_blockout_rev1/` e no blockout. Partes, triângulos, `joint_gaps`, `weapon_poses` e `fits` não mudam: o espinho só encurta 1 cm e a capa volta onde estava.

Aceito sem mudança: de costas, o pé de trás ainda aparece abaixo da barra da capa como um bico escuro, porque a bota gira com a perna na pisada. A ponta está acima do piso (-0,004 m) e é um traço do rig. Se no jogo isso incomodar, a alavanca é o tornozelo no rig, em ordem própria.

Critérios da Revisão 2: os da Revisão 1, com R3 lendo "nenhuma fita ou ponto claro sobre o topo da capa e sobre as ombreiras, de costas". Fora isso, só `report.json` (contagens iguais) e `walk_back.png`.

## Resultado

APROVADO em 08/11/2026 depois da Revisão 2. A conferência pedida (`walk_back.png` e `neutral_frost_king.png`, mais unit_tests) foi feita pela sessão principal: a capa fica limpa sobre as duas ombreiras e os pontos claros sumiram; 63 partes, 2.481 triângulos, 11 materiais, `fits` verdadeiro com -0,032 m; unit_tests 2817 ok, 0 falhas. Conferência da Revisão 1: REPROVADO em 08/11/2026, o que gerou a Revisão 2. Primeira revisão: REPROVADO em 08/11/2026. Critérios 1 a 11, 13 a 15, 17, 19 a 23 passam. Os critérios 12 (pés, medido -0,146 m contra o limite de -0,02) e 16/18 (pontas dos espinhos do cotovelo furando a capa) falham, e são resolvidos pela Revisão 1.
