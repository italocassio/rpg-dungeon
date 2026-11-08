# OS-010: Mago T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/mage_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/mage.md`, `concepts/conceito_mago.png`, função `mage()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.
- **Estado:** APROVADO em 01/11/2026, com os valores da seção Revisão aplicados e o teste J9 do cajado dispensado (seção Fechamento).

## Trabalho

Monte o mago exatamente como a ficha: esqueleto, repouso, todas as peças, cabelo e as duas variantes de T0. Variante 1 (Manto do Novato): a capa desce, com o primeiro anel em `y=.16`.

A aba traseira do casaco fica no joint `cloth_back`, criado em `pelvis (0,.04,.12)`. A gola fica em `chest`.

Troque o ramo `&"mage"` do `match` de `build_hero` para delegar a `mage_model.gd` e apague o corpo antigo. Remova do mago todo vestígio dele: nada de `EnemyParts.robed_body`, `EnemyParts.hood`, `look.legacy_tint` nem olho emissivo.

## Revisão

Só `mage_model.gd` e a pose de repouso do cajado. Aprovado: Y nas 3 vistas, rosto, cabelo, forro, casaco violeta na sala, mago distinto do xamã no `lineup.png` e 54 partes.

**1. Aro longe da asa.** Em `turn_mage.png`, de costas, a ponta da asa toca o arco inferior do aro (cerca de 2 cm de sobreposição, medida com margem de 1 cm). Em `walk_back.png` a ponta entra no aro e cobre a borda do núcleo. Numa silhueta de 60 px o aro e a asa viram uma mancha só.

| Joint ou peça | Antes | Depois |
|---|---|---|
| `shoulder_r` no repouso do cajado | `(.32, 0, .3)` | `(.32, 0, .4)` |
| Rotação do cajado em `hand_r` | `(-.97, 0, -.32)` | `(-.97, 0, -.47)` |

Pela geometria, o ombro leva a mão cerca de 5,5 cm para fora, e a rotação extra inclina o topo mais 5,6 cm: o aro sai cerca de 11 cm e o pé da haste fica onde estava. O pé não pode ir para dentro, porque de costas ele já quase toca a barra do casaco. Os números são o ponto de partida. O que vale é o resultado: vão de 6 cm ou mais entre o aro e a ponta da asa em `turn_mage.png` de costas (8 px ou mais em `silhouettes.png`, a 129 px/m), pé da haste a menos de 1 cm da posição de hoje, e em `walk_back.png` a ponta da asa fora do aro. O orbe, com `shoulder_r (.35,0,.1)`, e o `strike_wrist` não mudam.

**2. Materiais, de 18 para 16.** Sem isso o T1 chega a 19, porque a pele `EEF1F6` é material novo. Duas trocas, sem mudança de aparência:

- Asa interna da gola: `Look.two_sided(CLASS_BLUE, 0.5)` no lugar de `Look.hero(CLASS_BLUE, 0.5)`. Fica igual ao forro.
- Cabelo sólido (casquete, nuca e coque): `Look.two_sided(HAIR, 0.55)` no lugar de `Look.hero(HAIR, 0.55)`. Fica igual à trança e às mechas.

`report.json` deve mostrar `materials` 16 e as demais medidas iguais (54 partes, `key_width_m` 0,60, `v1_ok`, `v4_ok`). Em `turn_mage.png`, cabelo e gola idênticos aos de hoje.

## Fechamento

Medido com `shoulder_r z .4` e rotação `-.47`: vão aro-asa de 11,2 cm em repouso e 13 px em `silhouettes.png` de costas; 54 partes, 16 materiais, altura 2,424 m.

- **`walk_back.png`: ponta da asa tangente ao aro, aceita.** Antes ela entrava no aro. É o pior quadro do ciclo de passo, a ponta não entra e a asa branca e o aro dourado têm cores distintas, então a tangência lê como vizinhança. Nenhuma combinação de ombro e haste fecha vão no passo sem estragar o pé ou o J9, e com J9 dispensado não vale piorar o repouso. O critério fica: nenhuma sobreposição.
- **Pé da haste: aceito.** Subiu 2,3 cm e andou 1,4 cm (2,6 cm no total). O 1 cm da revisão protegia a barra do casaco, e o pé não a tocou. A 2,3 cm do chão, a 3 px a 5 m, o cajado parece carregado, como o do sacerdote. A ficha passa a dizer "até 3 cm do chão".
- **J9 do cajado dispensado.** Nenhuma habilidade de mago usa `swing`, `overhead` ou `thrust`: o ataque básico é `m_bolt` (`cast_quick`) e todas as outras são `cast` ou `cast_quick`. O `test_hero_strike_keeps_hand_and_weapon_in_front_of_the_chest` falhava em 31° contra 30° numa pose que o jogador não vê. Mudança do teste (`gameplay-developer`, `tests/unit_tests.gd`): o laço passa a cobrir só `sword_shield` e `greataxe`, e os testes de `lean` e de impacto valem sem o `if`. Um teste novo falha se alguma habilidade ou ataque básico de mago ou sacerdote usar outra animação além de `cast` e `cast_quick`, com a mensagem apontando para J9. O `strike_wrist` `(-.8,0,.5)` do cajado fica na ficha como dado sem uso.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho e sobrancelha em `Look.matte`. Marque as placas externas da gola com `set_meta(&"measure", true)`. Casaco `6E2470`. Selo em `4F8DFF`, energia 1,0. Núcleo `8A7BFF`, energia 0,9.

As 4 placas da gola usam `MeshKit.plate`. Mantenha `z=.1` e `z=.09` para que a asa azul fique à frente da prateada.

## Critérios de aceite

Renders de `hero_review`, classe mago:

| Render | Verificar |
|---|---|
| `silhouettes*.png` | Letra Y nas 3 vistas. Aro do cajado não cobre a asa da gola: de costas, vão de 6 cm ou mais (8 px a 129 px/m) entre os dois. Sem cajado, a gola sustenta o Y |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` da gola de `.6 ± .03`, altura de `2.4 ± .05`, até 56 partes, até 16 materiais |
| `turn_mage.png` | Rosto à mostra de frente, Selo sobre a capa nos dois lados, forro azul visível |
| `walk_back.png` | Pernas não atravessam a aba do casaco. Ponta da asa fora do aro, tangente aceita |
| `lobby_mage.png` | Cabelo e rosto limpos. O casaco pode puxar para o magenta na luz quente |
| `room_10_front.png` | Casaco lê como violeta, não azul. Mago se separa da parede pela capa e da neve pelo casaco |
| Lado a lado com o xamã, em `lineup.png` | Ninguém confunde os dois: sem capuz, sem olho aceso |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, segunda linha.
