# OS-005: Dados de aparência e nomes

- **Agente:** `rpg-systems`
- **Depende de:** OS-004
- **Arquivos:** `src/rpg/data/item_data.gd`, `src/rpg/data/dungeon_data.gd` (ou onde `DungeonData` estiver), `data/items/*.tres`, `data/skills/w_monarch.tres`, `data/dungeons/*.tres`, `src/ui/panels/forge_view.gd`, `tests/skill_cards.golden.txt`, `tests/unit_tests.gd`
- **Fora do escopo:** balanceamento, ids internos, modelos, apagar `armor_tint` (OS-012).

## 1. Campos de aparência

Adicione os campos do contrato da OS-004 em `item_data.gd`, logo depois da linha 30. No fim do arquivo, eles cairiam no grupo "Consumível" (`item_data.gd:32`). Preencha todos os equipamentos:

| Itens | `look_tier` | `look_variant` |
|---|---|---|
| `w_start_mail`, `m_start_robe`, `p_start_habit` | 0 | 0 |
| `w_start_plate`, `m_start_cloak`, `p_start_pilgrim` | 0 | 1 |
| Armas iniciais (`w_start_sword`, `w_start_axe`, `m_start_staff`, `m_start_orb`, `p_start_scepter`, `p_start_tome`) | 0 | 0 |
| `*_t1_*` | 1 | 0 |
| `*_t2_*` | 2 | 0 |
| `*_t3_*` | 3 | 0 |

Não use `w_start_*`: o padrão pega `w_start_plate`, que tem variante 1.

Adicione `enemy_glow` em `DungeonData`, com `7FE0FF` no Portão Gélido.

Um `.tres` esquecido vira T0 sem erro, e `@export_range` não protege edição manual. Acrescente em `tests/unit_tests.gd`:

- Toda receita: `recipe.result.look_tier == recipe.tier` (`src/rpg/data/recipe_data.gd:9`).
- Todo equipamento: `look_tier` de 0 a 3, `look_variant` de 0 a 1.
- Todo item inicial (`*_start_*`): `look_tier == 0`.

## 2. Nomes que saem do jogo

Regras O1 e O2 do guia. "Monarca Gélido" reproduz o "Frost Monarch" de Solo Leveling. Mitra, capuz, hábito e prece apontam para o que saiu do visual.

| Onde | Hoje | Novo |
|---|---|---|
| `warrior_t3_armor` | Armadura do Monarca Gélido | Armadura do Rei Gélido |
| `mage_t3_armor` | Manto do Monarca Gélido | Manto do Rei Gélido |
| `priest_t3_armor` | Vestes do Monarca Gélido | Vestes do Rei Gélido |
| `warrior_t3_weapon` | Lâmina do Monarca Gélido | Lâmina do Rei Gélido |
| `mage_t3_weapon` | Cajado do Monarca Gélido | Cajado do Rei Gélido |
| `priest_t3_weapon` | Cetro do Monarca Gélido | Cetro do Rei Gélido |
| `w_monarch` | Lâmina do Monarca | Lâmina do Portão |
| `forge_view.gd`, `TIER_NAMES[3]` | Conjunto do Monarca (Rank D) | Conjunto do Rei Gélido (Rank D) |
| `priest_t1_helm` | Mitra Gélida | Chapéu Gélido |
| `mage_t1_helm` | Capuz Gélido | Diadema Gélido |
| `mage_t1_boots` | Sandálias Gélidas | Botas Leves Gélidas |
| `p_start_habit` | Hábito do Noviço | Veste do Noviço |
| `p_start_tome` | Tomo de Preces | Tomo da Vigília |

Mantenha os ids. Regenere `tests/skill_cards.golden.txt` e confira que só a linha de `w_monarch` mudou.

## Critérios de aceite

- `grep -ri "monarca\|mitra\|hábito\|preces" data src tests` não acha texto visível ao jogador.
- `check_scripts`, `unit_tests` e `flow_test` passam, com os testes novos de `look_tier`.
- `w_start_plate` continua com `look_variant = 1`.
- Saves antigos carregam: os ids não mudaram.
- Nenhum valor de `stat_bonuses` foi alterado.
