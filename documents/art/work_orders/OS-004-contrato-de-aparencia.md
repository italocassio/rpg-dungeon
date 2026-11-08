# OS-004: Contrato de aparência do herói

- **Agente:** `game-architect`
- **Depende de:** nenhuma. Pode correr em paralelo às OS-001 a 003.
- **Arquivos a revisar:** `src/visuals/creature_factory.gd`, `src/visuals/weapon_kit.gd`, `src/actors/player/viewmodel.gd`, `src/actors/player/player_controller.gd`, `src/actors/ally/party_bot.gd`, `src/ui/lobby/lobby_stage.gd`, `src/world/dungeon_run.gd`, `src/rpg/data/item_data.gd`
- **Fora do escopo:** escrever os modelos. Esta ordem só fecha a interface.
- **Entrega:** parecer em `OS-004-parecer.md`, aprovado com 8 alterações. A direção de arte aceitou as 8. O contrato abaixo é o final e substitui a proposta original.

## Problema

Hoje o equipamento passa para a arte só `armor_tint`, `weapon_model` e raridade. `build_hero` recebe três valores soltos, `Viewmodel.setup` ignora a armadura e `creature_factory.gd` junta heróis e monstros num arquivo só. As novas regras pedem forma por tier, variante, elmo e botas.

## Contrato final

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
var legacy_tint: Color       # Só na transição. Sai no início da OS-012, junto com armor_tint

static func from_sheet(sheet: CharacterSheet) -> HeroLook   # Delega para from_items
static func from_items(hero_class: StringName, armor: ItemData, weapon: ItemData, helm: ItemData = null, boots: ItemData = null) -> HeroLook
func equals(other: HeroLook) -> bool
```

- `from_items` é o único lugar com a regra P3. O parâmetro se chama `hero_class` porque `class_id` sombreia `var class_id`.
- Todo item pode ser nulo. Item nulo vale tier 0 e variante 0. Arma nula deixa `weapon_model` vazio e raridade comum. Armadura nula deixa `legacy_tint` no valor padrão de `ItemData.armor_tint`.
- `equals` compara todos os campos, menos `legacy_tint`. Com `other` nulo, devolve `false`.

Pontos de uso:

| Hoje | Depois | Ordem |
|---|---|---|
| `_biped_skeleton`, `_limb` em `creature_factory.gd` | `CreatureRig.biped_skeleton`, `CreatureRig.limb`, públicos. Em `hero_base.gd`, monstro dependeria de herói (S4) | OS-006 |
| `CreatureFactory.build(visual)` | `CreatureFactory.build(visual, glow)`, com `glow` obrigatório | OS-006 |
| `build_hero(class_id, tint, model, rarity)` | `CreatureFactory.build_hero(look)` | OS-007 |
| `PartyBot._ready`, `party_bot.gd:41` | Usa `HeroLook.from_sheet`. Não reconstrói: a ficha do bot só é montada no spawn (`dungeon_run.gd:120-139`) | OS-007 |
| `LobbyStage.show_hero(class_id, armor, weapon)` | `LobbyStage.show_hero(look: HeroLook)` | OS-007 |
| `Lobby._refresh_hero`, `lobby.gd:108-113` | `HeroLook.from_sheet` se houver ficha, `HeroLook.from_items` se não houver | OS-007 |
| `tests/visual/lineup.gd:30-32` | Três chamadas de `build_hero(look)` | OS-007 |
| `tests/visual/hero_review.gd` | `_make_hero()` e `LobbyStage` na OS-007, `Viewmodel` na OS-012 | OS-007 e 012 |
| `WeaponKit.build_main_hand(model, rarity)`, `build_off_hand` | `(model, rarity, tier)`, com a raridade em segundo lugar | OS-008 |
| Lanterna do sacerdote | `OmniLight3D` criada uma vez, em `WeaponKit._scepter` | OS-008 |
| `Viewmodel.setup(class_data, weapon)` | `Viewmodel.setup(class_data, look)`. Retorna cedo se `look.equals(_look)` | OS-012 |
| `player_controller.gd:46-47`, primeira chamada de `setup` | Passa `HeroLook.from_sheet(sheet)` | OS-012 |
| `dungeon_run.gd:328`, troca de arma | `refresh_player_stats` sempre chama `setup(sheet.class_data, HeroLook.from_sheet(sheet))`. `_shown_weapon` sai de `dungeon_run.gd:45,96,325-328` | OS-012 |

Estrutura de arquivos, para não crescer um script monolítico:

```
src/visuals/hero_look.gd
src/visuals/heroes/hero_base.gd      # cabeça, mão, bota, Selo, pose
src/visuals/heroes/warrior_model.gd
src/visuals/heroes/mage_model.gd
src/visuals/heroes/priest_model.gd
src/visuals/enemy_parts.gd           # corpos e armas só de inimigo, com nomes públicos
```

`CreatureFactory.build_hero` vira um `match`. Na OS-007, ele ainda chama os corpos antigos, que ficam em `creature_factory.gd`. As OS-009 a 011 delegam para `heroes/*.gd`, classe a classe. `CreatureFactory.build` continua montando os monstros.

Campos novos em `ItemData`, implementados na OS-005, logo depois de `armor_tint`:

```gdscript
@export_range(0, 3) var look_tier: int = 0
@export_range(0, 1) var look_variant: int = 0
```

Campo novo em `DungeonData`: `@export var enemy_glow: Color = Color("7FE0FF")`.

## Respostas do parecer

| # | Pergunta | Resposta |
|---|---|---|
| 1 | `HeroLook` como `RefCounted` é o bastante, ou o saguão e o futuro multijogador pedem um `Resource` serializável? | **`RefCounted`.** `HeroLook` é derivado: o save guarda só os ids (`character_sheet.gd:132-135`). Campos simples não fecham a porta do multijogador |
| 2 | `armor_tint` pode ser apagado de `ItemData` e dos `.tres`, ou fica como campo morto até uma limpeza? | **Apagar, sem campo morto, no início da OS-012.** Até lá, os corpos antigos leem `look.legacy_tint`. A limpeza cobre `item_data.gd:30`, 15 `.tres` em `data/items/` e a citação em `.claude/agents/art-director.md` |
| 3 | A cor `enemy_glow` deve chegar aos modelos por `CreatureFactory.build(visual, glow)` ou por um valor estático em `Look`, definido em `DungeonWorld.build`? | **`CreatureFactory.build(visual, glow)`, com `glow` obrigatório.** Caminho: `dungeon_run.gd:163`, `Enemy.setup` (`enemy.gd:32`), `enemy.gd:65`. Valor estático criaria estado global dependente de ordem, porque `DungeonWorld.build` também roda no saguão (`lobby_stage.gd:15,27`) |
| 4 | A luz real da lanterna (`OmniLight3D`) pode viver dentro do rig, junto das malhas, ou deve ser criada pelo ator? | **Dentro do rig, criada por `WeaponKit._scepter` junto da malha, nunca pelo ator.** A luz segue a arma, e o `tome` não a tem. O viewmodel usa a mesma função. Fora de `props.lights`, ela não entra no orçamento de sombras de `dungeon_world.gd:147-151` |

## Decisão da direção de arte

Pendência do parecer: C3 contra a tabela de raridade. C3 vence, e o lendário não cria `OmniLight3D`. Motivo na seção 13 do guia, aplicação na OS-008.

## Confirmado no `check_scripts`

Medido na OS-007. A versão anterior dizia que membro inexistente não compila, o que só vale para acesso estático:

- `HeroLook.membro_inexistente` não compila.
- `look.membro_inexistente`, em variável tipada, compila e só falha em execução.
- Enum vai para `int` sem erro e sem aviso. `rarity` e `tier` em ordem trocada também não dão erro.
- Um parâmetro chamado `class_id` geraria `SHADOWED_VARIABLE`, que não é impresso em headless. Por isso `from_items` usa `hero_class`.

Portanto, `check_scripts` não protege a leitura de campo de `HeroLook` nem a ordem dos argumentos de `WeaponKit`. Quem protege são os testes de execução da OS-008, em `build_hero`, e da OS-012, no viewmodel.
