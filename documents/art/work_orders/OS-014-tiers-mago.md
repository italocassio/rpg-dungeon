# OS-014: Tiers do mago

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-010, OS-012, OS-019 (com os ajustes da revisão de 02/11/2026: o núcleo do foco, de `glow`, só passa em P9 pela emissão)
- **Arquivos:** `src/visuals/heroes/mage_model.gd`, `src/visuals/creature_rig.gd`, `src/visuals/weapon_kit.gd` (só `_staff`, para o aro interno), `tests/unit_tests.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/mage.md` (corrigida em 02/11/2026) e as regras P1 a P11 do guia
- **Fora do escopo:** balanceamento, novos itens, T0 e as duas variantes, o orbe.

## Trabalho

Peças cumulativas. Marque toda parte nova com `set_meta(&"tier", N)`; em T2 e T3 marque também as 4 placas da gola, para entrarem em P8 e P9. `look.head_tier` controla a gola, `look.armor_tier` o resto do corpo e os focos, `look.weapon_tier` o aro interno.

**Nome e marca.** `rig.part` não dá nome: sem `instance.name`, o `report.json` lista `@MeshInstance3D@N` e o aceite de posição (P11) não acha a peça. Toda peça marcada com `set_meta(&"tier", N)` recebe também `instance.name` com os nomes da tabela abaixo, únicos no rig inteiro (o `report.json` só lista o nome, não o caminho). Teste em `unit_tests.gd`: para `--tier` de 1 a 3, o conjunto de nomes de `tier_pieces` é exatamente o da tabela até aquele tier, sem repetição e sem nome começando em `@`.

| Tier | Nome (`tier` marcado) |
|---|---|
| T1 | `t1_barra` |
| T2 | `t2_foco_r_anel`, `t2_foco_r_nucleo`, `t2_foco_l_anel`, `t2_foco_l_nucleo` (o "foco 1" da tabela de posição). As 4 placas da gola, `t2_gola_placa_0` a `t2_gola_placa_3`, marcadas com `tier` 2 enquanto `head_tier >= 2` (inclusive no T3) |
| T3 | `t3_foco_r_anel`, `t3_foco_r_nucleo`, `t3_foco_l_anel`, `t3_foco_l_nucleo` (o "foco 2"), `t3_aro_interno` (em `WeaponKit._staff`, no cajado da mão) |

As placas da gola não são peça nova, e `p1_ok` já passa pelos anéis de 18 cm. Os dois lados têm nomes distintos (`r` e `l`) porque o `report.json` lista só o nome, não o caminho.

| Tier | Muda | Partes | Material novo |
|---|---|---|---|
| T1 | Barra de pele na capa, metal `C4D2E0` | +1 | pele `EEF1F6`, o mesmo `Look.hero` do viewmodel |
| T2 | Gola com escala y `1.22`, 2 focos, metal `D8B464` | +4 | nenhum: o núcleo do foco **reusa** o material do núcleo do cajado |
| T3 | 2 focos a mais, aro interno no cajado, painéis da frente em `.94`, metal `E6ECF5` | +5 | nenhum |

1. **T1.** `loft` 12 lados em `chest`: `(0,.255,.285,.19) (0,.325,.268,.178)`, `EEF1F6`. Se T0 e T1 não se distinguirem a 120 px, a alavanca é alargar a barra para `(0,.205,.295,.2) (0,.325,.268,.178)`. O Selo traseiro fica em `y` .35 a .51 e não é tocado.
2. **T2.** Gola: escala y `1.22` nas 4 placas, sem mudar x. Cada foco é um `Node3D` filho de `chest` com 2 partes: anel `torus(.06,.09,12)` (12 lados, não 18: com 18 o T3 passa de 6.000 tris), `rotation.x = PI/2`, `scale = (1,.6,1)`, metal de `Look.trim`; e `sphere(.05,10)` com escala `(1,1,.45)`, no material do núcleo do cajado (`glow(8A7BFF,.9)`, mesma chamada de `WeaponKit._staff`, para o cache devolver a mesma instância). Posições em `chest`: `(±.66,.42,.1)` (revisão 2 de 02/11/2026: era `±.5`, e a haste do cajado passa em `x` .49 nessa altura, então o foco ficava enfiado nela como conta de rosário). A escala do Godot é local e vem antes da rotação: o `.6` achata o anel ao longo do eixo que vira o z do mundo.
3. **T3.** Mais 2 focos, iguais, em `chest (±.66,.74,.14)` (revisões de 02/11/2026: `y` era `.82`, e de costas o foco do lado do cajado entrava 2,6 cm no aro externo; `x` era `±.48`, e a haste passa em `x` .50 a .51 nessa altura, então o foco ficava enfiado nela). A ficha antiga dava `±.42`, e com a gola em y `1.22` o foco ficava a 3,5 cm da asa na fase alta da oscilação; em `±.66` o vão até a asa sobe para cerca de `.28`. **Aro interno** no cajado: `torus(.103,.125,20)` (era `.09`; revisão de 02/11/2026) em `y=1.11`, `rotation.x = PI/2`, mesmo plano do aro do cajado, metal do tier, somente com `weapon_tier >= 3`, em `WeaponKit._staff` (vale também no viewmodel, +1 parte, dentro das 38). **No mesmo `weapon_tier >= 3`, o núcleo do cajado passa de escala y `1.45` para `1.15`** (meia-altura de `.123` para `.098`; nos outros tiers fica `1.45`, e é a mesma instância de material). Sem isso o núcleo atravessa o aro interno em cima e embaixo, porque entre o topo do núcleo (`.123`) e o aro do cajado (`.135`) há só 12 mm. O aro externo da ficha antiga, `torus(.205,.24,24)`, fica fora: sobe o raio externo de `.185` para `.24`, o topo do cajado passa de 2,45 m e a ponta da asa fica quase em contato de costas, em 2D. Painéis da frente: `cloth(.15,.2,.94,.04,3,5)`, no lugar de `.86`. **A aba traseira fica em 1,0**: com 1,14 ela desce 13 cm abaixo do piso (`pelvis` em .969, ponto de fixação em 1,009).
4. **Oscilação.** Em `CreatureRig`, `add_float(node: Node3D, amplitude: float, frequency: float, phase: float)`, chamado de `animate`: `node.position.y = base_y + amplitude * sin(TAU * frequency * time + phase)`, com `amplitude .03`, `frequency .5` e fases `0`, `PI/2`, `PI`, `3*PI/2` (T3; no T2, `0` e `PI`). Sem `_process` por foco. O tempo só avança dentro de `animate(delta, ...)`: pausado o jogo não chama `animate`, e o foco para. Rig morto também não oscila.

A massa não muda: ameixa `6E2470`, prata `D5D9E4`, pernas `1B1830` nos 4 tiers (P2).

## Números esperados, `--rarity=4`, `staff`, variante 0

Medido no T0: 57 partes, 4.144 tris, 17 materiais, `height_m` 2.439, `key_width_m` .60.

| Tier | Partes | Tris | Materiais | `key_width_m` | `height_m` |
|---|---|---|---|---|---|
| T1 | 58 | 4.192 (medido) | 18 | .60 ± .02 | até 2.45 |
| T2 | 62 | 4.816 (medido) | 18 | .60 ± .02 | até 2.45 |
| T3 | 67 | 5.760 (medido; o aro interno de 20 lados soma 320) | 18 | .60 ± .02 | até 2.45 |

Ceilings: 67, 68 e 70 partes; 5.200, 5.600 e 6.000 tris; 18 materiais. **O mago fecha com zero folga em materiais.** Se T2 der 19, o foco criou um `glow` próprio. Focos não têm `set_meta(&"measure", true)`: a largura de 0,60 m é a da gola.

## Posição medida (P11)

`tier_pieces.center_m`, no espaço do modelo, com `chest` em `y = 1,091 m`, tolerância de 3 cm mais a oscilação (`y` ± .03):

| Peça | `center_m` esperado | `size_m` |
|---|---|---|
| Barra de pele | `(0, 1,38, 0)` | x de .54 a .60 |
| Foco 1, anel | `(±.66, 1,51, .10)` | `(.18, .18, .02)`, ± .01 |
| Foco 2, anel | `(±.66, 1,83, .14)` | `(.18, .18, .02)`, ± .01 |
| Aro interno | no eixo do aro do cajado | diâmetro .25, ± .01 |

A haste do cajado, no repouso, passa em `x` cerca de .49 em `y` 1,51 e .50 a .51 em `y` 1,83 (raio .02 a .03): o foco do lado do cajado fica com a borda de dentro (`x` .57) a 3 a 5 cm dela. Um anel de foco com `size_m` `(.18, .11, .03)` está com a escala no eixo errado. O `chest` guina até 0,08 rad no passo, o que move um foco a 50 cm do eixo em cerca de 4 cm no z: meça no repouso, e os vãos abaixo em movimento.

## Critérios de aceite

`--tier=0` a `--tier=3`, `--rarity=4`. Renders: `tiers_mage.png`, `tiers_mage_room10.png`, `silhouettes.png` de cada tier, `turn_mage.png`, `walk_side.png`, `walk_back.png`, `pose_cast.png`, `vm_mage_staff.png` do run `--weapon=staff --tier=3` (o `hero_review.gd` não acrescenta o tier ao nome), `report.json`.

- Os 4 tiers se distinguem de frente em `tiers_mage_room10.png`, a 120 px.
- Letra Y mantida em preto, nos 4 tiers e nas 3 vistas (S5). Os focos ficam fora da letra: não somam largura de gola.
- Focos redondos, com aro, em `8A7BFF` com energia .9, sem estilhaço (B2).
- Rosto à mostra (R2): olhos e boca visíveis de frente e de 3/4. `p8_ok`.
- Selo a 70% ou mais do T0 na frente e nas costas, `p7_ok`.
- Nada escuro e vertical nas costas: `p9_ok`. A gola de dentro, `4F8DFF`, tem L* de cerca de 58 e passa.
- `p1_ok` nos 3 tiers.
- **Vão (P10)**, medido com `_min_gap` em repouso, nas 4 fases do passo, em `cast` e nas 4 fases da oscilação (avance `animate` de meio período, 0,5 s):
  - cada foco contra as 4 placas da gola, a haste, os aros do cajado, os dois braços, a cabeça, o cabelo e a aba traseira: 5 cm ou mais;
  - aros do cajado (o externo e o interno) contra as placas da gola: 6 cm ou mais, e o T3 não fica mais de 0,5 cm abaixo do T0 (mais longe é aceito). Medido: `.344` no T0 e `.362` no T3. O cajado está 31 cm à frente da gola em z, e os 7 cm e 1,5 cm da ficha antiga eram contas em 2D, sem o z;
  - aro interno contra o núcleo: 4 mm ou mais (esperado 5 mm com o núcleo em `1.15`), e contra o aro externo: 8 mm ou mais (esperado 10 mm);
  - barra dos painéis da frente: `y` de 0,04 m ou mais em todas as fases do passo (medido `.048` em repouso, `walk_25`, `walk_75` e `cast`; `.098` em `walk_0` e `walk_50`), e `walk_side.png` sem bota atravessando painel ou aba;
  - em 2D, de costas (`walk_back.png` e `turn_mage.png`), o foco 2 do lado do cajado não toca o aro externo do cajado: vão de 3 cm ou mais com a oscilação em `+.03`. Em `vm_mage_staff.png` do run T3 o núcleo não atravessa o aro interno.
  - em 2D, de costas e de frente, em repouso (`turn_mage.png`, `tiers_mage.png`) e no passo (`walk_back.png`): a haste não cruza nenhum foco, com 2 cm ou mais em 2D entre a borda do anel do foco e a haste, em repouso e nas fases 0, 25 e 50 do passo. **Na fase 75 do passo, a de maior balanço lateral da haste, a haste pode entrar até 1,5 cm no anel** (medido: foco 1 a 1,8 cm, foco 2 com 1,0 cm de sobreposição). O `cast` fica fora deste critério: a haste fica quase na horizontal e o vão 3D até ela é de .44 m. Isto é linha de visão, não vão 3D: os focos estão em z +.10 e +.14 e a haste em cerca de -.31, e o aliado é visto de costas o tempo todo (E3).
- Pausado, os focos param: dois `animate(0.0, 0.0)` seguidos deixam a posição igual. Rig morto não oscila. Teste em `unit_tests.gd`.
- `v1_ok` e `v4_ok` nos 4 tiers, `limit_ok` com `HERO_BUDGETS`. Sem `legacy_tint`, `EnemyParts` nem material fora da tabela.

## Revisão de 02/11/2026 (AJUSTES)

Julgada sobre os renders de T0 a T3 e `vm_mage_staff.png` do T3, sem rodar o Godot.

- **Aceito:** tris de T2 e T3 (4.816 e 5.760, dentro de 5.600 e 6.000); barra dos painéis em `.048` (critério agora 0,04 m); critério dos aros do cajado contra as placas reescrito; fases da oscilação (T2 em `0` e `PI`, T3 em `PI/2` e `3*PI/2`, as quatro distintas; o relatório mostra o foco 2 em `1,941` e `1,881`); S5, letra Y e progressão contra `conceito_mago.png`.
- **T1 aceito como está, alavanca recusada.** A 120 px o T1 se distingue do T0 pela prata no aro e no cinto e pelo lábio claro na barra da capa, o mesmo grau da faixa de progressão do conceito. Alargar a barra para `(0,.205,.295,.2)` leva a borda a cerca de 3 cm do cotovelo (esfera de `.06` em `x` .35, `y` .18 no `chest`) em repouso, e o passo atravessa a barra. Conta feita à mão na ficha, não medida.
- **R1 (pendente), núcleo e aro interno no T3.** Em `WeaponKit._staff`, com `weapon_tier >= 3`: núcleo com escala y `1.15` e aro interno `torus(.103,.125,20)`. Sem tocar em T0 a T2. Teste em `unit_tests.gd`: escala y do núcleo é `1.45` com `weapon_tier < 3` e `1.15` com `weapon_tier == 3`. Vão esperado: 5 mm até o núcleo, 10 mm até o aro externo, e o vão até a gola não muda (`.362`).
- **R1 conferido** (5,2 mm até o núcleo, 10,0 mm até o aro externo, núcleo sem corte no `vm_mage_staff.png`, barra dos painéis `.0484`).
- **R2 (concluído, aceito em `±.66`), focos de T2 e T3.** O `y` `.74` do foco 2 tirou o foco do aro do cajado, mas a haste continua atravessando os dois pares do lado do cajado: de costas e de frente, em repouso, o foco 1 e o foco 2 estão com a haste no centro do anel (`x` do foco .50 e .48, da haste .49 e .50 a .51). Em `silhouettes.png` a haste vira um fio de contas e o par do lado do cajado deixa de ler como foco flutuante, ao contrário do par do outro lado. O conceito não faz isso: `conceito_mago.png` põe os focos em cerca de .56 a .62 m, fora da haste, e a ficha antiga (`±.5`) é que divergia. **Novo:** `x` `±.66` nos dois pares, nos dois lados, `y` e `z` como estão (foco 1 `(±.66,.42,.10)`, foco 2 `(±.66,.74,.14)`). Efeito esperado: vão do foco 2 até a gola sobe de `.1239` para cerca de `.28`; foco 1 e foco 2 contra os braços sobem de `.124` para mais de `.20`; contra a haste e os aros do cajado nada piora (já .43 e .35). P11: foco 1 `(±.66,1,51,.10)` e foco 2 `(±.66,1,83,.14)`. Largura com os focos passa de cerca de 1,2 m para 1,5 m: confira o enquadramento do `lobby_mage.png` e do `lineup.png`, que não pode cortar os anéis. Remeça P10 e P11.
- Rerrodar: `tiers_mage.png`, `silhouettes.png` e `walk_back.png` do T3, `turn_mage.png` e `vm_mage_staff.png` do run T3, `report.json`.
- **Decisão final, aceito.** Medido: P11 em 1,511 e 1,831 ± .03; foco 2 até a gola .302, braços .249 e .342, haste .531 e .442, aros do cajado .510 e .384; 2D da borda do anel à haste, repouso .051 e .023, passo 0 e 50 .050 e .022, passo 25 .081 e .058, passo 75 .018 e -.010. Só a fase 75 falha o 2 cm, por uma fração do ciclo e com a haste cruzando o anel por um instante, e o aliado se move o tempo todo. Não se move `x` de novo: `±.66` já dá 1,5 m de largura e o `lobby_mage.png` em 3/4 chega perto da borda. A OS-014 está encerrada, sem nova rodada de ajuste de posição.
