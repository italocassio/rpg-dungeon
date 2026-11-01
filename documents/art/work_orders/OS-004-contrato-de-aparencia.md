# OS-004: Contrato de aparência do herói

- **Agente:** `game-architect`
- **Depende de:** nenhuma. Pode correr em paralelo às OS-001 a 003.
- **Arquivos a revisar:** `src/visuals/creature_factory.gd`, `src/visuals/weapon_kit.gd`, `src/actors/player/viewmodel.gd`, `src/actors/player/player_controller.gd`, `src/actors/ally/party_bot.gd`, `src/ui/lobby/lobby_stage.gd`, `src/world/dungeon_run.gd`, `src/rpg/data/item_data.gd`
- **Fora do escopo:** escrever os modelos. Esta ordem só fecha a interface.
- **Entrega:** parecer aprovando ou alterando a proposta. Se alterar, devolva à direção de arte antes da OS-005.

## Problema

Hoje o equipamento passa para a arte só `armor_tint`, `weapon_model` e raridade. `build_hero` recebe três valores soltos, `Viewmodel.setup` ignora a armadura e `creature_factory.gd` junta heróis e monstros num arquivo só. As novas regras pedem forma por tier, variante, elmo e botas.

## Proposta

```gdscript
class_name HeroLook
extends RefCounted
## Tudo que a arte precisa saber para montar um herói. Não conhece cena nem regra de jogo.

var class_id: StringName
var armor_tier: int = 0      # 0 a 3
var armor_variant: int = 0   # 0 ou 1, só em T0
var head_tier: int = 0       # max(tier da armadura, tier do elmo)
var boots_tier: int = 0      # max(tier da armadura, tier das botas)
var weapon_model: StringName
var weapon_tier: int = 0
var weapon_rarity: ItemData.Rarity = ItemData.Rarity.COMMON

static func from_sheet(sheet: CharacterSheet) -> HeroLook
static func from_items(class_id: StringName, armor: ItemData, weapon: ItemData, helm: ItemData = null, boots: ItemData = null) -> HeroLook
```

Pontos de uso:

| Hoje | Depois |
|---|---|
| `build_hero(class_id, tint, model, rarity)` | `CreatureFactory.build_hero(look)` |
| `Viewmodel.setup(class_data, weapon)` | `Viewmodel.setup(class_data, look)` |
| `LobbyStage.show_hero(class_id, armor, weapon)` | Usa `HeroLook.from_items` |
| `PartyBot._ready` | Usa `HeroLook.from_sheet` |
| `dungeon_run.gd:328`, troca de arma | Reconstrói o viewmodel também ao trocar armadura |

Estrutura de arquivos proposta, para não crescer um script monolítico:

```
src/visuals/hero_look.gd
src/visuals/heroes/hero_base.gd      # esqueleto, cabeça, mão, bota, Selo, pose
src/visuals/heroes/warrior_model.gd
src/visuals/heroes/mage_model.gd
src/visuals/heroes/priest_model.gd
src/visuals/enemy_parts.gd           # corpos e armas só de inimigo
```

`CreatureFactory.build_hero` vira um `match` que delega. `CreatureFactory.build` continua montando os monstros.

Campos novos em `ItemData`, implementados na OS-005:

```gdscript
@export_range(0, 3) var look_tier: int = 0
@export_range(0, 1) var look_variant: int = 0
```

`armor_tint` deixa de ser lido pela arte. Campo novo em `DungeonData`: `@export var enemy_glow: Color = Color("7FE0FF")`.

## Perguntas para o parecer

1. `HeroLook` como `RefCounted` é o bastante, ou o saguão e o futuro multijogador pedem um `Resource` serializável?
2. `armor_tint` pode ser apagado de `ItemData` e dos `.tres`, ou fica como campo morto até uma limpeza?
3. A cor `enemy_glow` deve chegar aos modelos por `CreatureFactory.build(visual, glow)` ou por um valor estático em `Look`, definido em `DungeonWorld.build`?
4. A luz real da lanterna (`OmniLight3D`) pode viver dentro do rig, junto das malhas, ou deve ser criada pelo ator?
