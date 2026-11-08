# OS-019: Ferramenta de tiers

- **Agente:** `gameplay-developer`
- **Depende de:** OS-012 (aprovada)
- **Bloqueia:** OS-013, OS-014, OS-015
- **Arquivos:** `tests/visual/hero_review.gd`, `tests/unit_tests.gd`, `src/visuals/heroes/hero_base.gd` (só uma chamada `set_meta` no Selo)
- **Fora do escopo:** modelos de tier, dados de item, balanceamento.

## Problema

Hoje `AVAILABLE_TIERS = [0]` (`hero_review.gd:14`), `_check_arguments` recusa `--tier` diferente de 0, `_make_hero` ignora o tier (`_hero_tier` não é lido) e `_review_tiers` só desenha o T0. O orçamento é um só, `HERO_T0_BUDGET` de 56 partes, 4.500 tris e 18 materiais, e `limit_ok` dá falso no T0 em raridade 4 (guerreiro 62 partes e 4.730 tris, mago 57 e 4.144). As OS-013 a 015 não conseguem ser aprovadas sem renders e medidas por tier.

## Trabalho

1. **Tier no look.** `_look_of(class_id, weapon_index, tier)` parte de `HeroLook.from_items(...)` e fixa `armor_tier = head_tier = boots_tier = weapon_tier = tier`. `_make_hero` e `_spawn_hero` passam o tier. `AVAILABLE_TIERS = [0, 1, 2, 3]`, e `--tier=N` vale para todo render e para o `report.json` do run. A variante (`--variant`) só vale com `--tier=0`: com outro tier, recuse com a mensagem "variante só existe em T0".
2. **`tiers_<classe>.png`.** Sempre os 4 tiers, qualquer que seja `--tier`: 4 colunas (T0 a T3) e 2 linhas (frente, costas), palco neutro, a arma da raridade do run. Novo `tiers_<classe>_room10.png`: a mesma grade no enquadramento de `room_10`, recorte de 220 por 280 px centrado no herói, sem reescalar (o herói fica com cerca de 120 px). É a imagem do critério "se distinguem a 120 px".
3. **Orçamento por tier.** `HERO_BUDGETS`, indexado pelo tier: `{parts 66, tris 5000}`, `{67, 5200}`, `{68, 5600}`, `{70, 6000}`, materiais 18 nos quatro (seção 11 do guia). `_mesh_stats` usa o do `_tier` do run. O aceite das ordens de tier roda com `--rarity=4`.
4. **`tier_pieces`.** Cada ordem de classe marca com `set_meta(&"tier", N)` as partes novas do tier N. A ferramenta lista em `report.json`, em `models.<classe>.tier_pieces`, uma entrada por parte marcada: `name`, `tier`, `size_m` (AABB dos vértices no espaço do modelo, como `_mesh_stats` já faz), `center_m`, `lstar` (L* do `albedo_color` do material) e `back_area_m2` (extensão em x vezes extensão em y). Em `--tier=0` a lista é vazia e as quatro verificações abaixo valem `true`.
5. **Verificações no `report.json`**, por classe, para `--tier=N` de 1 a 3:

| Campo | Verdadeiro quando |
|---|---|
| `p1_ok` | alguma parte de tier N tem `size_m` com um eixo de 0,09 m ou mais |
| `p8_ok` | nenhum vértice de parte de tier, no frame do joint `head`, cai em `\|x\| <= .1`, `.02 <= y <= .2`, `z <= -.05` (o queixo começa em `y .02`). Parte com `set_meta(&"face_cover", true)` fica de fora (só a máscara do guerreiro T3) |
| `p9_ok` | toda parte de tier com `back_area_m2 >= .01` tem `lstar >= 46` |
| `p7_ok` | o Selo da frente e o das costas mantêm 70% ou mais dos pixels do T0 |

   Para `p7_ok`, `HeroBase.seal` marca o disco de luz com `set_meta(&"seal", &"front")` ou `&"back"`. A ferramenta projeta o centro do disco e conta os pixels, num círculo de raio .055 m projetado, a menos de 0,12 (distância euclidiana em sRGB, de 0 a 1) da cor lida no centro do Selo no render do T0, na frente e nas costas. O T0 é renderizado primeiro, no mesmo run. Relate `seal_front_ratio` e `seal_back_ratio`.
6. **Vão entre peças.** Em `tests/unit_tests.gd`, o auxiliar `_min_gap(a: Array[MeshInstance3D], b: Array[MeshInstance3D]) -> float`: menor distância entre vértices no espaço do mundo, força bruta (as listas têm poucas centenas de vértices). E `_gap_samples(rig)`, que devolve as poses a medir: repouso, 4 fases do passo (0, 1/4, 1/2 e 3/4 do ciclo), `cast` e o golpe da classe (`swing` do guerreiro). As OS de classe listam os pares.
7. **Testes.** Em `unit_tests.gd`: as 3 classes × 4 tiers montam sem erro, sem `push_error`, e o T0 das duas variantes segue igual; `HERO_BUDGETS` tem 4 entradas crescentes; `--tier=4` e `--tier=-1` são recusados.

## Critérios de aceite

Com as OS de classe ainda não aplicadas, os tiers 1 a 3 saem iguais ao T0 (menos metal e arma). A ferramenta tem de relatar isso, sem travar:

- `hero_review --class=warrior --tier=0 --rarity=4 --weapon=sword_shield` dá `limit_ok = true` (variante 0: 62 partes, 4.730 tris, 16 materiais contra 66, 5.000 e 18; a variante 1 soma cerca de 2 partes e 120 tris). O mesmo para o mago com `staff` (57, 4.144, 17).
- `--tier=3` roda nas 3 classes, e `report.json` mostra `p1_ok = false` e `tier_pieces = []` (nada foi marcado), sem erro.
- `tiers_warrior.png` tem 4 colunas e 2 linhas, e `tiers_warrior_room10.png` o recorte de 220 por 280 px.
- Um teste com uma parte de teste marcada `tier` dentro do volume do rosto faz `p8_ok` falhar, e uma parte escura de 0,1 m² de costas faz `p9_ok` falhar. Sem esses dois casos negativos a ferramenta não vale.
- `check_scripts`, `unit_tests` e `flow_test` sem falha.

## Ajustes da revisão (02/11/2026)

A revisão aprovou o resto (Selo, orçamento, recusas, renders). Dois ajustes de código, no mesmo escopo de arquivos (`tests/visual/hero_review.gd`, `tests/unit_tests.gd`), antes de liberar as OS-013 a 015:

1. **`lstar` de peça emissiva (P9, já corrigida no guia).** Em `_albedo_lstar`, quando o material tem `emission_enabled` e `emission_energy_multiplier >= 0.5`, devolva o maior entre o L* do `albedo_color` e o L* de `emission` (a cor, sem multiplicar pela energia). Sem emissão, ou com energia abaixo de 0,5, nada muda e `-1` sem material segue valendo. Motivo: `Look.glow` escurece o albedo em 40%, e o núcleo do foco do mago (`8A7BFF`, .1 x .1 m) dá L* 36 no albedo contra 59 na emissão. Testes novos em `unit_tests.gd`, com o auxiliar de caixa de 0,1 x 0,1 x 0,045 m de costas: `Look.glow(8A7BFF, .9)` dá `p9_ok` true e `lstar` de 59 ± 2; `Look.matte(1B1830)` do mesmo tamanho dá false; `Look.glow(8A7BFF, .3)` com albedo escuro dá false. Os dois negativos de antes seguem.
2. **`_gap_samples` do guerreiro.** O guerreiro usa em jogo `swing`, `overhead`, `thrust` e `shout`, e as lâminas da OS-013 ficam no ombro, onde `overhead` (os dois braços a -2,6 rad) e `shout` (os dois braços abertos a ±1,0 rad em z) passam perto. Para `class_id == &"warrior"`, some às amostras de hoje (`swing_*`) os mesmos três estágios (armado, impacto e fim, com `GAP_SWING_FRAMES`) para `overhead`, `thrust` e `shout`, com os nomes `overhead_windup`, `overhead_impact`, `overhead_finish`, e assim por diante. `_pose_swing` vira `_pose_strike(rig, action, stage)`. O guerreiro passa a ter 18 amostras e as demais 6. Atualize o teste de nomes e de contagem. Mago e sacerdote seguem só com `cast`, igual a `cast_quick` na pose.

Aceite: `check_scripts`, `unit_tests` e `flow_test` sem falha, e `report.json` de `--tier=3` sem mudança nos campos de hoje (nada marcado ainda).
