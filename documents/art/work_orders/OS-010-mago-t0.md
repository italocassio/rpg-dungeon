# OS-010: Mago T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/mage_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/mage.md`, `concepts/conceito_mago.png`, função `mage()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.

## Trabalho

Monte o mago exatamente como a ficha: esqueleto, repouso, todas as peças, cabelo e as duas variantes de T0. Variante 1 (Manto do Novato): a capa desce, com o primeiro anel em `y=.16`.

A aba traseira do casaco fica no joint `cloth_back`, criado em `pelvis (0,.04,.12)`. A gola fica em `chest`.

Remova do mago todo vestígio do corpo anterior: nada de `_robed_body`, `_hood` nem olho emissivo.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho e sobrancelha em `Look.matte`. Marque as placas externas da gola com `set_meta(&"measure", true)`. Casaco `6E2470`. Selo em `4F8DFF`, energia 1,0. Núcleo `8A7BFF`, energia 0,9.

As 4 placas da gola usam `MeshKit.plate`. Mantenha `z=.1` e `z=.09` para que a asa azul fique à frente da prateada.

## Critérios de aceite

Renders de `hero_review`, classe mago:

| Render | Verificar |
|---|---|
| `silhouettes*.png` | Letra Y nas 3 vistas. Aro do cajado não cobre a asa da gola. Sem cajado, a gola sustenta o Y |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` da gola de `.6 ± .03`, altura de `2.4 ± .05`, até 56 partes |
| `turn_mage.png` | Rosto à mostra de frente, Selo sobre a capa nos dois lados, forro azul visível |
| `walk_back.png` | Pernas não atravessam a aba do casaco |
| `lobby_mage.png` | Cabelo e rosto limpos. O casaco pode puxar para o magenta na luz quente |
| `room_10_front.png` | Casaco lê como violeta, não azul. Mago se separa da parede pela capa e da neve pelo casaco |
| Lado a lado com o xamã, em `lineup.png` | Ninguém confunde os dois: sem capuz, sem olho aceso |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, segunda linha.
