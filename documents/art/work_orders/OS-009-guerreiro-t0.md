# OS-009: Guerreiro T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/warrior_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/warrior.md`, `concepts/conceito_guerreiro.png`, função `warrior()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.
- **Estado:** AJUSTES, segunda revisão de 01/11/2026. Falta a nuca em aço claro (seção Segunda revisão). Todo o resto está aprovado.

## Trabalho

Monte o guerreiro exatamente como a ficha: esqueleto, repouso, todas as peças da tabela, cabeça e as duas variantes de T0.

A capa fica no joint `cloth_back`, criado em `chest (0,.52,.17)`. Ombreiras e gola ficam em `chest` (J3).

Variante 0 (Cota de Malha): construção na linha T0 da tabela de tiers da ficha. Variante 1 (Couraça de Recruta): ficha completa.

Troque o ramo `&"warrior"` do `match` de `build_hero` para delegar a `warrior_model.gd` e apague o corpo antigo. O modelo novo não lê `look.legacy_tint` nem chama `EnemyParts`.

## Ajustes da revisão

Só `warrior_model.gd`. O número de partes não muda. Valores completos na ficha.

| Peça | Mudança | Motivo |
|---|---|---|
| Proteção da nuca | Troque o `lathe` pelo `loft` da ficha, em `B0AEA8` (corrigido na segunda revisão) | O anel fechado passava na frente de bochechas, boca e queixo (R2) |
| Elmo | Aba de `y=.13` para `y=.172` | A aba descia abaixo das sobrancelhas, e olhos e sobrancelhas furavam a placa (R2) |
| Jugulares | Altura `.185`, centro em `y=.0875` | Acompanham a aba nova, sem deixar a têmpora solta |
| Nasal | `box(.024,.11,.02)` em `(0,.165,-.128)` | Para no meio do nariz e deixa nariz e boca visíveis |
| Gorjal | Perfil, escala e material da ficha, em `6F6D69`, facetado | Fim do colar preto. Faixa visível de 3 cm, sem borda ondulada |
| Joelheira | `sphere(.098,8)` em `(0,0,-.012)` | A atual aflora só 5 mm e vira uma mancha clara de perfil |
| Variante 0 | Telhas alta e baixa da linha T0 da ficha | Largura 0,92 m, sem braço preto entre as telhas e sem metal de 20 cm |

Um material novo: `Look.hero(Color("6F6D69"), .42, .35)`, usado só no gorjal, nas duas variantes.

Confirmado sem mudança: aço `8F8D88` só no `chest` da variante 0, e cabo da espada na mão (`lobby_warrior.png`). Confirmado o teste `test_heroes_folder_only_holds_the_common_base_and_class_models`, que deve valer também para os modelos de mago e sacerdote quando entrarem (S4).

## Segunda revisão

**1. Nuca de aço claro.** Em `warrior_model.gd`, a proteção da nuca volta a usar o material `steel` (`B0AEA8`, `Look.hero(.42,.35)`), o mesmo do elmo. O erro foi da ficha: em `6F6D69` e num plano vertical, de costas ela rende L* 26 e vira uma laje preta sob a cúpula, que lê como visor virado para trás e se confunde com a máscara do T3 (R2). O blockout mede L* 50,5 no mesmo ponto. Vale `turn_warrior.png`, quadro de costas, variante 1: média da nuca com L* de 45 ou mais. A cúpula mede 60. O gorjal fica em `6F6D69`.

**2. Razão do T, medida de novo.** Com o método do critério, o resultado é:

| Variante | Ombros frente / costas | Haste | Razão frente / costas | Mínimo |
|---|---|---|---|---|
| 1 | 1,053 / 1,053 m | 0,681 m | 1,55 / 1,55 | 1,5 |
| 0 | 0,960 / 0,929 m | 0,681 m | 1,41 / 1,36 | 1,3 |

Um pixel vale 0,008 m, ou 0,012 na razão. Os mínimos anteriores, 1,5 e 1,4, foram escritos sem método definido, e 1,4 deixava a variante 0 de costas (1,36) abaixo por uma conta de arredondamento. Entre 0,90 e 1,25 m o tronco mede 0,74 a 0,77 m, porque o braço pendente está colado às faldas. É o trapézio com braços da folha de conceito, e fica assim. A razão só guarda contra regressão. Quem prova S1 é `lineup.png`, depois das OS-010 e 011.

**3. Variante 0, aceita como está.** Entre a faixa de metal e a manopla aparecem 8 cm de braço em `23262E`. É o braço da ficha, dá o contraste claro e escuro e lê como manga acolchoada sob a cota.

**4. V vermelho na nuca, de costas, aceito (01/11/2026).** É a borda traseira da crista de placa, de 5 cm, cortando a cúpula. O blockout tem o mesmo V, e ele repete a ponta da crista que se vê de frente. Sem mudança.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho e sobrancelha em `Look.matte`. Marque as telhas com `set_meta(&"measure", true)`. O metal vem de `Look.trim(look.armor_tier)`. Selo em `E0603A`, energia 1,0.

## Critérios de aceite

Renders de `hero_review`, classe guerreiro:

| Render | Verificar |
|---|---|
| `silhouettes_noweapon.png` | Razão do T, frente e costas, em pixels pretos com escala `altura em px / 2,075`: ombros = maior largura entre y 1,25 e 1,70 m; haste = maior largura entre y 0,30 e 0,80 m (faldas, capa e pernas, abaixo da mão pendente, que termina perto de 0,87 m). Razão mínima 1,5 na variante 1 e 1,3 na variante 0. De perfil: crista e capa legíveis |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` das ombreiras de `.99 ± .03` na variante 1 e `.92 ± .03` na variante 0, altura de `2.05 ± .05`, até 56 partes, até 18 materiais |
| `turn_warrior.png` | Selo na frente e nas costas, capa fendida, aresta no esterno, 3 telhas na variante 1 e 2 na variante 0. Na variante 0, metal em faixa de 9 cm colada à telha alta, sem vão entre as telhas e sem braço atravessando a placa |
| `walk_side.png` | Capa abre para trás, sem atravessar as pernas |
| `pose_cast.png` | Cotovelo sem falha aberta em 90° de flexão (J1, J2) |
| `lobby_warrior.png` | Olhos, sobrancelhas, nariz, boca e queixo sobre pele contínua, sem aço recortando nenhum deles. Sem textura suja, sem colar preto ou barba escura sob o queixo. Gorjal lê como aço escuro |
| `room_20_back.png` | Capa escura contra a neve, Selo aceso visível |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, primeira linha. No rosto e no gorjal, a referência é a ficha.

S1 só fecha no `lineup.png` com as OS-010 e OS-011 prontas. Se o guerreiro se confundir com outra classe a 60 px, reduza a barra da capa em `cloth` de `.38` para `.3`, o que estreita a massa de 0,63 m para 0,55 m. As faldas não mudam.

Os monstros continuam iguais. O Rei Gélido em especial mantém `EnemyParts.armored_body`.
