# OS-009: Guerreiro T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/warrior_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/warrior.md`, `concepts/conceito_guerreiro.png`, função `warrior()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.

## Trabalho

Monte o guerreiro exatamente como a ficha: esqueleto, repouso, todas as peças da tabela, cabeça e as duas variantes de T0.

A capa fica no joint `cloth_back`, criado em `chest (0,.52,.17)`. Ombreiras e gola ficam em `chest` (J3).

Variante 0 (Cota de Malha): sem a telha média, tronco em `8F8D88`. Variante 1 (Couraça de Recruta): ficha completa.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho e sobrancelha em `Look.matte`. Marque as telhas com `set_meta(&"measure", true)`. O metal vem de `Look.trim(look.armor_tier)`. Selo em `E0603A`, energia 1,0.

## Critérios de aceite

Renders de `hero_review`, classe guerreiro:

| Render | Verificar |
|---|---|
| `silhouettes*.png` | Letra T nas 3 vistas, com e sem arma |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` das ombreiras de `.99 ± .03`, altura de `2.05 ± .05`, até 56 partes |
| `turn_warrior.png` | Selo na frente e nas costas, capa fendida, aresta no esterno, 3 telhas |
| `walk_side.png` | Capa abre para trás, sem atravessar as pernas |
| `pose_cast.png` | Cotovelo sem falha aberta em 90° de flexão (J1, J2) |
| `lobby_warrior.png` | Rosto visível no vão do elmo, sem textura suja, sem barba escura sob o queixo |
| `room_20_back.png` | Capa escura contra a neve, Selo aceso visível |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, primeira linha.

Os monstros continuam iguais. O Rei Gélido em especial mantém `_armored_body`.
