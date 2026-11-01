# OS-005: Dados de aparência e nomes

- **Agente:** `rpg-systems`
- **Depende de:** OS-004
- **Arquivos:** `src/rpg/data/item_data.gd`, `src/rpg/data/dungeon_data.gd` (ou onde `DungeonData` estiver), `data/items/*.tres`, `data/skills/w_monarch.tres`, `data/dungeons/*.tres`, `src/ui/panels/forge_view.gd`, `tests/skill_cards.golden.txt`
- **Fora do escopo:** balanceamento, ids internos, modelos.

## 1. Campos de aparência

Adicione os campos aprovados na OS-004 e preencha todos os equipamentos:

| Itens | `look_tier` | `look_variant` |
|---|---|---|
| `w_start_mail`, `m_start_robe`, `p_start_habit` | 0 | 0 |
| `w_start_plate`, `m_start_cloak`, `p_start_pilgrim` | 0 | 1 |
| Armas iniciais (`w_start_*`, `m_start_staff`, `m_start_orb`, `p_start_scepter`, `p_start_tome`) | 0 | 0 |
| `*_t1_*` | 1 | 0 |
| `*_t2_*` | 2 | 0 |
| `*_t3_*` | 3 | 0 |

Adicione `enemy_glow` em `DungeonData`, com `7FE0FF` no Portão Gélido.

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
- `check_scripts`, `unit_tests` e `flow_test` passam.
- Saves antigos carregam: os ids não mudaram.
- Nenhum valor de `stat_bonuses` foi alterado.
