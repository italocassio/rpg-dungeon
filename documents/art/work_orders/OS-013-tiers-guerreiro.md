# OS-013: Tiers do guerreiro

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-009, OS-012, OS-019 (com os ajustes da revisão de 02/11/2026)
- **Arquivos:** `src/visuals/heroes/warrior_model.gd`, `tests/unit_tests.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/warrior.md` (já corrigida em 02/11/2026) e as regras P1 a P11 do guia
- **Fora do escopo:** balanceamento, novos itens, T0 e as duas variantes, viewmodel.

## Trabalho

Peças cumulativas. Marque toda parte nova com `set_meta(&"tier", N)`. `look.armor_tier` controla o corpo, `look.head_tier` a crista e a máscara, `look.boots_tier` as botas. A canela fica escura nos 4 tiers (revisão de 02/11/2026).

**Nome e marca.** `rig.part` não dá nome: sem `instance.name`, o `report.json` lista `@MeshInstance3D@N` e o aceite de posição (P11) não acha a peça. Toda peça marcada com `set_meta(&"tier", N)` recebe também `instance.name` com os nomes da tabela abaixo, únicos no rig inteiro (o `report.json` só lista o nome, não o caminho). Teste em `unit_tests.gd`: para `--tier` de 1 a 3, o conjunto de nomes de `tier_pieces` é exatamente o da tabela até aquele tier, sem repetição e sem nome começando em `@`.

| Tier | Nome (`tier` marcado) |
|---|---|
| T1 | `t1_gola` |
| T2 | As 6 telhas de ombro que ganham a escala `1.1` (alta, média e baixa, de cada lado): `t2_telha_r_alta`, `t2_telha_r_media`, `t2_telha_r_baixa`, `t2_telha_l_alta`, `t2_telha_l_media`, `t2_telha_l_baixa`, marcadas com `tier` 2 enquanto `armor_tier >= 2` (inclusive no T3) |
| T3 | `t3_mascara` e `t3_visor` (os dois também `face_cover`), `t3_lamina_r`, `t3_lamina_l` |

O T2 não soma parte, e `p1_ok` só olha peça marcada com o tier do run: sem a marca nas telhas (todas com 9 cm ou mais), `p1_ok` dá falso em T2. A crista e a capa não se marcam: a crista é vermelha, de L* perto de 45, e a capa não é peça nova.

| Tier | Muda | Partes | Material novo |
|---|---|---|---|
| T1 | Gola de pele, metal `C4D2E0` | +1 | pele `EEF1F6`, o mesmo `Look.hero` do punho de pele do `viewmodel.gd` |
| T2 | Crista com escala y `1.5`, telhas a `1.1`, metal `D8B464` | 0 | nenhum |
| T3 | Máscara, visor, 2 lâminas, capa de 1,42 m, sem nasal, metal `E6ECF5` | +3 (+4 menos 1) | visor `Look.matte(0C0E14)` |

Em T3 a conta é +2 da máscara e do visor, +2 das lâminas e -1 do nasal, que não se constrói, ou seja, +3 sobre o T2.

1. **T1.** Gola: `lathe` 14 lados em `chest`, escala z `.62`: `(.3,.5) (.29,.53) (.23,.57) (.17,.585)`. A gola do blockout (`(.4,.43)` a `(.15,.65)`, z `.72`) cobria o queixo e a boca e engolia os dois Selos: não a use. **Canela: a `_limb(.46,.09,.07)` fica no material escuro `23262E` (pano `matte(.75)`) nos 4 tiers.** A canela de aço `B0AEA8` que esta ordem pedia em T1 está revogada (revisão de 02/11/2026): trocava a massa escura da zona baixa por aço claro (P2, V1, V2) e deu `low_p10` de costas 20,8 em T1 e 20,6 em T2, contra o limite de 20. O sinal do T1 é a gola, o metal prata e o cinto.
2. **T2.** Crista: escala y `1.5`. Telhas: multiplique por `1.1` o `origin.x` (±.21), o `centro_x` e o `raio_x` de cada anel, para a borda externa ir de `.495` a `.5445` por lado (+10%). Só `centro_x` e `raio_x` dariam +6%. A espada já cresceu na OS-008.
3. **T3.** Máscara: `loft` 10 lados em `head (0,0,-.006)`: `(0,.02,.06,.08) (0,.1,.098,.112) (0,.19,.103,.116)`, material de `Look.trim(3)` (o mesmo `E6ECF5`; outro material estoura os 18), `set_meta(&"face_cover", true)`. Visor: `box(.11,.012,.02)` em `(0,.135,-.116)`, `0C0E14`, sem emissão, com `set_meta(&"face_cover", true)` (o visor é a fenda da máscara). **Não construa o nasal** (`box(.024,.11,.02)`) quando `head_tier >= 3`: a barra vertical cruzando o visor desenha uma cruz (O2). Lâminas, `plate` espessura `.04`, material de `Look.trim(3)`:
   - direita, `chest (.33,.6,0)`, rot z `-.3`, perfil `(0,0) (.11,0) (.09,.2) (.03,.32)`;
   - esquerda, `chest (-.33,.6,0)`, rot z `+.3`, o perfil espelhado em x **e na ordem inversa**: `(-.03,.32) (-.09,.2) (-.11,0) (0,0)`. Sem inverter a ordem a malha sai do avesso (G1) e a lâmina some de um lado.
   - Só rotação em z, então a ordem de Euler não importa. Se usar duas rotações, `rotation_order = EULER_ORDER_XYZ` como em `hero_base.gd:121`.
   - A capa vai de 1,2 m para 1,42 m: `cloth(.25,.38,1.42,.26,6,7)` nas duas metades.

A massa não muda: aço `B0AEA8`, carmesim `C23A22` e `B3301F` nos 4 tiers (P2).

## Números esperados, `--rarity=4`, `sword_shield`

Do T1 em diante o corpo é o da variante 1 (a variante só existe em T0). Medido no T0 da variante 0: 62 partes, 4.730 tris, 16 materiais, `height_m` 2.075 e `key_width_m` .923. A variante 1 soma as 2 telhas médias, cerca de 64 partes e 4.850 tris, `key_width_m` .99 ± .02. Meça a variante 1 antes de começar e use-a como base:

| Tier | Partes | Tris | Materiais | `key_width_m` | `height_m` |
|---|---|---|---|---|---|
| T0 | base | base | base | base | base |
| T1 | base + 1 | base + 100 | base + 1 | igual | igual |
| T2 | base + 1 | base + 100 | base + 1 | de 1,08 a 1,12 vezes o T0 | até 2.30 |
| T3 | base + 4 | base + 350 | base + 2 | igual ao T2 | até 2.30 |

Ceilings do guia para o tier: 67 partes e 5.200 tris em T1, 68 e 5.600 em T2, 70 e 6.000 em T3, 18 materiais. Em T3, base + 4 partes são +3 em relação ao T1: máscara, visor e 2 lâminas, menos o nasal. Se T3 passar de 18 materiais, a máscara ou as lâminas não estão reusando `Look.trim(3)`.

## Posição medida (P11)

A ficha dá posição no joint. O aceite é `tier_pieces.center_m` no espaço do modelo, com tolerância de 3 cm. Faixas de `chest` em `y = 1,07 m` e `head` em `y = 1,65 m`:

| Peça | `center_m` esperado |
|---|---|
| Gola | `y` de 1,57 a 1,655, `x` 0, `size_m` x de .46 a .60 |
| Máscara | `(0, 1,755, -.006)` |
| Visor | `(0, 1,785, -.116)` |
| Lâmina direita | `(.40, 1,80, 0)`, `size_m` `(.145, .33, .04)` |
| Lâmina esquerda | `(-.40, 1,80, 0)`, mesmo `size_m` |

Lâmina fora disso é erro de conta (giro do `chest`, perfil não espelhado ou rotação com o sinal trocado): corrija, não ajuste o aceite.

## Critérios de aceite

`--tier=0` a `--tier=3`, `--rarity=4`. Renders: `tiers_warrior.png`, `tiers_warrior_room10.png`, `silhouettes.png` de cada tier, `turn_warrior.png`, `pose_swing.png`, `walk_back.png`, `walk_side.png`, `report.json`.

- Os 4 tiers se distinguem de frente em `tiers_warrior_room10.png`, a 120 px, sem ler o nome do item. Hoje (OS-019, sem nenhuma peça) T0 e T2 só diferem pelo bronze e pelo ouro e T1 e T3 pela prata e pela platina: o metal sozinho não basta, e é isto que as peças desta ordem resolvem.
- Letra T mantida em preto, nos 4 tiers e nas 3 vistas (S5). As lâminas só reforçam a linha do ombro.
- Rosto à mostra de T0 a T2 (R2): nariz, boca e queixo visíveis de frente e de 3/4 em `turn_warrior.png`. `p8_ok` em T1 e T2. Em T3 só a máscara e o visor dela cobrem o rosto, e `p8_ok` passa com os dois marcados `face_cover`.
- Selo na frente e nas costas, a 70% ou mais do T0: `p7_ok` nos 3 tiers, e o Selo das costas se vê em `room_10_back.png`.
- Nada escuro e liso nas costas: `p9_ok`. A capa de 1,42 m é a massa `B3301F` já aprovada, não conta como peça nova.
- `p1_ok` nos 3 tiers. Pele branca e fosca, sem cristal nem luz no rosto em T3 (B1, B2).
- Sem nasal em T3 e sem cruz em nenhuma vista (O2): o visor é uma só barra horizontal.
- Vão (P10, `_min_gap`, `_gap_samples(rig, &"warrior")`, que depois da OS-019 traz `swing`, `overhead`, `thrust` e `shout`, cada um armado, no impacto e no fim): lâminas contra o braço direito e o esquerdo em todas essas amostras, 1 cm ou mais (sem atravessar). O `shout` abre os dois braços a 1,0 rad em z, rente à lâmina; crista contra a lâmina, 5 cm ou mais; gola contra a mandíbula (`head`), 1 cm ou mais (medido `.0100`, aceito: é o pescoço); **capa (as duas metades) contra as pernas, os joelhos e as botas, 1 cm ou mais nas 4 fases do passo (J4)**, medida com `_min_gap`, e `walk_side.png` do T3 sem bota atravessando a capa de 1,42 m.
- `v1_ok` e `v4_ok` nos 4 tiers, com `low_p10` de costas em T1 e T2 de volta a 20 ou menos (esperado perto de 0,2, como no T0). Partes, tris e materiais da tabela acima, `limit_ok` com `HERO_BUDGETS`.
- P3: elmo T1 com armadura T0 troca só a cabeça (crista alta não, máscara não); armadura T2 com elmo T1 mostra a cabeça de T2. Teste em `unit_tests.gd` montando os `HeroLook`.
- Sem `legacy_tint`, `EnemyParts` nem material novo fora da tabela.

## Revisão de 02/11/2026 (AJUSTES)

Julgada sobre os renders de T0 a T3 e da variante 1, sem rodar o Godot.

- **Canela de aço revogada (v1_ok).** Em `tiers_warrior_room10.png`, T1 a T3 têm perna e bota claras contra a neve, e o T0 tem perna escura. A zona baixa deixa de ser escura, que é o que V1 protege (o aliado é visto com os pés sobre o piso), e a massa escura muda de cor com o tier, contra P2 e V2. O conceito mantém a perna escura nos 4 tiers. Volta `23262E` em T1, T2 e T3. Subir o limite de V1 ou escurecer o aço (um `6F6D69`, L* 46, também é massa clara em V1) foram descartados.
- **Visor marcado `face_cover` (p8_ok).** O visor é a fenda da máscara, não uma peça separada: só existe com ela, e o rosto de T3 já está coberto. Mover o visor para fora do volume do rosto o tiraria da máscara. P8 e R2 passam a dizer "máscara e visor".
- **Aceitos:** crista com `name` "crista" e sem `tier` (é a massa carmesim da classe, L* 45, redimensionada em T2, não peça nova, e de costas é fio vermelho e não laje escura); nasal em `Look.trim(head_tier)` (P3: a cabeça segue o maior tier entre armadura e elmo); gola contra a cabeça em `.0100`, no limite do critério.
- **Pendente de medir:** capa de 1,42 m contra pernas, joelhos e botas, nas 4 fases do passo. `walk_back.png` do T3 não mostra bota atravessando, mas a capa baixou de 1,2 m para 1,42 m (barra a cerca de .24 m do piso) e J4 pede o número. Critério acima.
- **S5, T e progressão:** a letra T mantém-se nos 4 tiers e nas 3 vistas, e as lâminas só somam à linha do ombro; rosto à mostra de T0 a T2; a progressão confere com `conceito_guerreiro.png`: gola de pele em T1, crista alta e ombreira 10% em T2, máscara e lâminas em T3, sem a cruz do visor que o conceito desenhava (O2). A 120 px o par mais fraco é T0 contra T2 (crista e largura), aceito.
