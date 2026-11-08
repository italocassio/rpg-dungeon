# OS-015: Tiers do sacerdote

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-011, OS-012, OS-019 (com os ajustes da revisão de 02/11/2026: os discos do Selo, de `glow`, só passam em P9 pela emissão)
- **Arquivos:** `src/visuals/heroes/priest_model.gd`, `src/visuals/weapon_kit.gd` (só `_scepter`, para a escala da lanterna), `tests/unit_tests.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/priest.md` (corrigida em 02/11/2026) e as regras P1 a P11 do guia
- **Fora do escopo:** balanceamento, novos itens, T0 e as duas variantes, o tomo.

## Trabalho

Peças cumulativas. Marque toda parte nova com `set_meta(&"tier", N)`. `look.head_tier` controla pingentes, segunda aba e fitas. `look.armor_tier` controla manto, Selos e lanterna de cinto. `look.weapon_tier` controla a escala da lanterna do bastão, em `WeaponKit._scepter`, que passa a receber o tier.

**Nome e marca.** `rig.part` não dá nome: sem `instance.name`, o `report.json` lista `@MeshInstance3D@N` e o aceite de posição (P11) não acha a peça. Toda peça marcada com `set_meta(&"tier", N)` recebe também `instance.name` com os nomes da tabela abaixo, únicos no rig inteiro (o `report.json` só lista o nome, não o caminho). Teste em `unit_tests.gd`: para `--tier` de 1 a 3, o conjunto de nomes de `tier_pieces` é exatamente o da tabela até aquele tier, sem repetição e sem nome começando em `@`.

| Tier | Nome (`tier` marcado) |
|---|---|
| T1 | `t1_manto`. Os dois discos de luz do Selo, `t1_selo_frente` e `t1_selo_costas`, marcados com `tier` 1 enquanto `armor_tier >= 1` (inclusive em T2 e T3): `HeroBase.seal` devolve `void` e `hero_base.gd` está fora do escopo, então ache o filho de `chest` com `get_meta(&"seal")` igual a `front` ou `back` depois da chamada. O aro do Selo não se marca |
| T2 | `t2_pingente_r_fio`, `t2_pingente_r_esfera`, `t2_pingente_l_fio`, `t2_pingente_l_esfera` |
| T3 | `t3_aba_2`, `t3_fita_r`, `t3_fita_l`, `t3_lanterna_cinto_teto`, `t3_lanterna_cinto_nucleo` (só a lanterna nova em `pelvis (-.31,-.2,-.06)`; a de `+.31` do tomo é do T0 e não se marca) |

A lanterna do bastão a `1.18` e a segunda escala não são peça nova e não se marcam. A fita sai de `cloth` pelo mesmo caminho do véu: nomeie o `MeshInstance3D` devolvido.

| Tier | Muda | Partes | Material novo |
|---|---|---|---|
| T1 | Manto curto, Selos para fora do manto, metal `C4D2E0` | +1 | `D5D9E4`, `Look.hero` |
| T2 | 2 pingentes largos, metal `D8B464` | +4 | nenhum |
| T3 | Segunda aba menor, 2 fitas, lanterna a `1.18`, lanterna de cinto, metal `E6ECF5` | +5 | nenhum |

1. **T1.** Manto: `loft` 12 lados em `chest`: `(0,.3,.27,.17) (0,.38,.26,.165) (0,.5,.2,.135) (0,.56,.1,.09)`, `D5D9E4`. **Os dois Selos saem para fora do manto**: frontal em `chest (0,.4,-.18)` e traseiro em `chest (0,.42,.18)`. O traseiro de T0, em `z .14`, ficaria 1,5 cm por dentro do manto (que passa em `z .155` a `y .42`) e sumiria nas costas, a vista mais comum do aliado (E3, B3). O topo do manto, em `chest y .56`, fica 1,1 cm abaixo do queixo: não suba.
2. **T2.** Pingentes, nos dois lados: `cylinder(.005,.005,.2,6)` em `head (±.4,.13,.05)` e `sphere(.06,10)` com escala `(1,1.25,1)` em `head (±.4,.02,.05)`, metal do tier. A ficha antiga dava `z 0`, que põe o pingente sobre a orelha de perfil; `.05` o deixa 8 cm atrás do rosto. Cada pingente tem cerca de 12 cm de largura nominal (E1); a esfera de 10 lados dá 11,4 cm em x e 12,0 cm em z.
3. **T3.**
   - Segunda aba: `lathe` 16 lados em `head (0,.335,0)`: `(.22,0) (.21,.015) (.09,.095) (0,.13)`, cor do chapéu. A da ficha antiga, de raio `.27`, chegava a 3 cm da lanterna a `1.18`. Com `.22` o vão fica em 8 cm.
   - Véu: o de `.26` fica. Somam-se 2 fitas, `cloth(.07,.08,.5,.04,1,4)` em `head (±.15,.22,.125)`, creme duas faces (`Look.two_sided(CREAM, .75)`, o do véu), pelo mesmo caminho do véu de T0 (`priest_model.gd:115`). Um véu único de 0,50 m cobriria o Selo traseiro, que vai de `y` .34 a .50 no `chest`. Alavanca, se uma fita atravessar o braço no passo: `x ±.13` e largura `.06` e `.07`.
   - Lanterna do bastão com escala `1.18`, em `WeaponKit._scepter`, só com `weapon_tier >= 3`. A luz real continua `FFD76A`, energia `.55`, alcance `3.0`, uma só, em qualquer tier (C3). Vale também no viewmodel.
   - Lanterna de cinto em `pelvis (-.31,-.2,-.06)`: teto `lathe` 6 lados `(.08,.06) (.07,.07) (.02,.1)` e núcleo `sphere(.05,10)`, `glow(FFD76A,.9)` no mesmo material do núcleo da lanterna, sem `OmniLight3D`. Com `tome` o sacerdote fica com 2 lanternas de cinto (a de `+.31` já existe em T0), com `scepter` fica com 1.

A massa não muda: jade `247050`, creme `E6DCC0`, chapéu `E2D6B6` nos 4 tiers (P2).

## Números esperados, `--rarity=4`, variante 0

Medido no T0: `tome` 54 partes, 3.616 tris, 16 materiais, `height_m` 1.97; `scepter` 49 partes, 3.652 tris, 15 materiais, `height_m` 2.174. `key_width_m` .90 ± .02.

| Tier | `tome`: partes, tris, materiais | `scepter`: partes, tris, materiais | `height_m` |
|---|---|---|---|
| T1 | 55, 3.712, 17 | 50, 3.748, 16 | igual ao T0 |
| T2 | 59, 4.024, 17 | 54, 4.060, 16 | igual ao T0 |
| T3 | 64, 4.292, 17 | 59, 4.328, 16 | `scepter` 2.20 (até 2.25); `tome` 2.02, a segunda aba soma 5 cm |

Ceilings: 67, 68 e 70 partes; 5.200, 5.600 e 6.000 tris; 18 materiais. Em T3, uma só `OmniLight3D` no rig com `scepter` e nenhuma com `tome` (C3).

## Posição medida (P11)

`tier_pieces.center_m`, no espaço do modelo, com `pelvis` em `y = 0,9025`, `chest` em `1,0165` e `head` em `1,5675` (esqueleto `.95`), tolerância de 3 cm:

| Peça | `center_m` esperado |
|---|---|
| Manto | `(0, 1,45, 0)`, `size_m` x de .50 a .56 e y de .24 a .28 |
| Selo frontal, T1+ | `(0, 1,4165, -.18)` |
| Selo traseiro, T1+ | `(0, 1,4365, .18)` |
| Pingente, esfera | `(±.40, 1,5875, .05)` |
| Segunda aba | `(0, 1,965, 0)`, `size_m` x e z de .44, y de .13 |
| Fita | `(±.15, 1,54, .13)`, `size_m` y de .50 |
| Lanterna de cinto | `(-.31, 0,70, -.06)` |

Não há rotação composta nesta classe: a única é a do bastão em `hand_r` (OS-008, `EULER_ORDER_XYZ`), que não muda.

## Critérios de aceite

`--tier=0` a `--tier=3`, `--rarity=4`, `--weapon=scepter` e `--weapon=tome`. Renders: `tiers_priest.png`, `tiers_priest_room10.png`, `silhouettes.png` de cada tier, `turn_priest.png`, `walk_back.png`, `lobby_priest.png`, `vm_priest_scepter.png` do run `--weapon=scepter --tier=3` (o `hero_review.gd` não acrescenta o tier ao nome), `report.json`.

- Os 4 tiers se distinguem de frente em `tiers_priest_room10.png`, a 120 px.
- Letra A mantida em preto, nos 4 tiers e nas 3 vistas (S5). A segunda aba reforça a copa, e os pingentes não fecham o disco.
- Pingentes visíveis a 10 m: 11 cm ou mais de largura cada (E1 pede 9; medido 11,4 em x e 12,0 em z).
- Rosto à mostra: olhos e boca visíveis de frente, de 3/4 e de lado em `turn_priest.png`, nenhum pingente nem fita à frente deles. `p8_ok`.
- **Selo a 70% ou mais do T0 nas costas e na frente, `p7_ok`**, em T1, T2 e T3. É o risco real desta classe.
- Nada escuro e liso nas costas: `p9_ok`. Manto `D5D9E4` e fitas creme passam.
- `p1_ok` nos 3 tiers. Nenhuma peça lembra mitra, tiara, batina ou cruz (O2): a segunda aba é um segundo telhado, sem ponta em cruz e sem faixa frontal.
- **Vão (P10)**, com `_min_gap` em repouso, nas 4 fases do passo e em `cast`:
  - pingente contra a haste do bastão, as mãos e os braços: 5 cm ou mais;
  - lanterna a `1.18` contra a segunda aba: 6 cm ou mais (medido `.1774`); **contra a primeira aba: 4 cm ou mais em todas as fases** (medido 4,51 cm em `walk_25`, até 3,06 cm abaixo do T0). Exceção da classe, ao lado da de 0,6 cm da OS-011: o P10 pede 5 cm, e a lanterna a `1.18` não chega lá sem perder a escala;
  - fita contra o manto: 1 cm ou mais; contra os dois braços: 1 cm ou mais em todas as fases;
  - fita contra o Selo traseiro: 1,5 cm ou mais.
- Saia sem furo, nada fura a saia em `walk_back.png`, boca da manga escura (critérios da OS-011 intactos).
- `v1_ok` e `v4_ok` nos 4 tiers, `limit_ok` com `HERO_BUDGETS`. Sem `legacy_tint`, `EnemyParts` nem material fora da tabela.

## Revisão de 02/11/2026 (APROVADO)

Julgada sobre os renders de `scepter_t0` a `t3` e `tome_t0` a `t3`, sem rodar o Godot.

- **Lanterna a 1,18 contra a primeira aba: aceito 4,51 cm absolutos.** A distância é entre vértices, 3D, e a lanterna não toca a aba em nenhuma vista de `turn_priest.png` nem de `lobby_priest.png`; o contato em 2D já existia no T0 e é a exceção da OS-011. Escala menor (1,12 compra cerca de 1 cm e deixa o T3 com +12%) e pivô na base (código e outra medição) não valem a rodada. O piso do teste fica em 4 cm.
- **Pingente de 11,4 cm em x e 12,0 em z: aceito.** E1 pede 9 cm; o 12 era o nominal da esfera.
- **Tris acima do "cerca de": aceito.** Medidos: `scepter` 3.748, 4.060, 4.328; `tome` 3.712, 4.024, 4.292; tetos 5.200, 5.600, 6.000. Tabela atualizada.
- **Selo do `tome` em .93 (frente) de T1 a T3: aceito.** `p7_ok` pede .70. O livro já cobre parte do Selo frontal no T0, e o `scepter` fica em 1,03 a 1,04.
- **A 120 px:** T0 contra T2 se separam pelo manto branco de T1, que o T2 herda, e pelos pingentes; o par mais fraco é T1 contra T2 (prata contra ouro, mais pingentes pequenos), legível. O Selo traseiro do T3 aparece inteiro entre as duas fitas, com anel claro sobre manto branco.
- **Nome do viewmodel:** `vm_priest_scepter.png` da pasta do run T3.
- **Letra A, S5, rosto e progressão:** disco no alto e sino embaixo nos 4 tiers e nas 3 vistas; a segunda aba reforça a copa e os pingentes não fecham o disco. Olhos e boca à mostra de frente, de 3/4 e de lado em `turn_priest.png`, sem pingente nem fita à frente. A progressão confere com `conceito_sacerdote.png`: manto curto em T1, pingentes em T2, aba dupla, véu longo e lanterna maior em T3.
- **Observação, sem exigir mudança:** de costas, o pingente do lado do bastão fica sobre a haste (3D a 7,6 cm); o conceito faz o mesmo, é um só pingente com fio, e não vira fio de contas como os focos do mago. A alavanca, se o usuário não gostar, é `x ±.34`.
