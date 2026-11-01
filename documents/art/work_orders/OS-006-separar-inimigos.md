# OS-006: Separar inimigos e unificar o brilho

- **Agente:** `gameplay-developer`
- **Depende de:** OS-002, OS-003, OS-005
- **Arquivos:** `src/visuals/creature_factory.gd`, `src/visuals/enemy_parts.gd` (novo), `src/visuals/weapon_kit.gd`, `src/visuals/look.gd`, `src/world/dungeon_world.gd`
- **Fora do escopo:** redesenhar monstros. Forma e materiais continuam iguais, exceto a cor dos olhos.

## Objetivo

Hoje o mago usa o corpo do xamã, o guerreiro usa o corpo do Rei Gélido e o esqueleto usa a espada do herói. Os próximos pedidos reescrevem heróis e armas, então os inimigos precisam sair desse caminho antes (regra S4).

## Trabalho

1. Mova para `enemy_parts.gd`, sem mudar números: `_armored_body`, `_robed_body`, `_hood`, `_cape`, e cópias de `_sword`, `_shield`, `_staff` de `WeaponKit`. O `Look.metal` fica permitido só aqui.
2. `_biped_skeleton`, `_limb` e `_grip` continuam compartilhados, por serem utilitários sem aparência.
3. `_skeleton` e `_shaman` passam a usar as armas de `enemy_parts.gd`. `_cape` deixa de alterar o material em cache: use `.duplicate()`, como `_frost_king` já faz.
4. Crie o brilho único de olho:

| Inimigo | Hoje | Depois |
|---|---|---|
| Goblin | `ffd24a`, 3,5 | `enemy_glow`, 4,0 |
| Lobo | `6fe0ff`, 4,0 | `enemy_glow`, 4,0 |
| Esqueleto | `6cc2ff`, 4,0 | `enemy_glow`, 4,0 |
| Xamã | `7fe0ff`, 4,0 | `enemy_glow`, 4,0 |
| Golem | `7fe0ff`, 5,0 | `enemy_glow`, 4,0 |
| Rei Gélido | `7fe0ff`, 7,0 | `enemy_glow`, 7,0 |

A cor vem de `DungeonData.enemy_glow`, pelo caminho decidido na OS-004. Cristais de `DungeonMaterials.crystal` continuam iguais.

## Critérios de aceite

- `lineup.png`: os seis monstros iguais ao render anterior, exceto pelos olhos do goblin e do esqueleto.
- Nenhuma chamada de `_robed_body`, `_hood`, `_armored_body` ou `_cape` vem de código de herói. Busca textual em `src/visuals/heroes/` não acha nada.
- Trocar `enemy_glow` para `FF7A2E` no recurso muda os olhos de todos os monstros de uma vez. Reverta depois do teste.
- `flow_test` e `tour.tscn` rodam sem erro.
