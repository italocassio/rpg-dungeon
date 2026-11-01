# OS-011: Sacerdote T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/priest_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/priest.md`, `concepts/conceito_sacerdote.png`, função `priest()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.

## Trabalho

Monte o sacerdote exatamente como a ficha: esqueleto, repouso, todas as peças, chapéu, as duas variantes de T0.

- Sem pernas (J5). Os joints continuam para o rig funcionar.
- O punho usa `MeshKit.lathe(..., close_ends = false)`.
- Sem mitra, sem tira frontal da batina, sem cabeça lisa.
- Crie a `OmniLight3D` da lanterna onde a OS-004 decidir: `FFD76A`, energia `.55`, alcance `3.0`, `shadow_enabled = false`.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho, sobrancelha, sob a aba e fundo da manga em `Look.matte`. Marque o chapéu com `set_meta(&"measure", true)`. Jade `247050`, creme `E6DCC0`, chapéu `E2D6B6`. Selo e núcleo em `FFD76A`, energia 0,9.

Chapéu em duas peças: a de cima `E2D6B6`, a de baixo `3A2E25`. O escuro separa a aba do rosto.

## Critérios de aceite

Renders de `hero_review`, classe sacerdote:

| Render | Verificar |
|---|---|
| `silhouettes*.png` | Letra A nas 3 vistas. Lanterna fora do disco do chapéu |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` do chapéu de `.9 ± .02`, altura de `2.15 ± .05`, até 56 partes |
| `turn_priest.png` | Rosto legível sob a aba, sobreveste sem interpenetrar a saia, estola por fora da sobreveste |
| `walk_back.png` | Nada fura a saia |
| `lobby_priest.png` | Nenhuma leitura de papa nem de hábito. Boca da manga escura, sem bola de metal |
| `room_05_back.png`, `room_10_front.png` | Saia escura separa da neve. Chapéu claro separa da parede |
| Corredor escuro | A lanterna clareia o próprio modelo e cria uma poça quente no chão |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, terceira linha.

Depois desta ordem, rode `silhouettes.png` com as 3 classes novas. É a primeira revisão de S1 com tudo junto.
