# Parecer da OS-004: aprovada com alterações

Emitido pelo `game-architect` em 31/10/2026, só pela leitura do código e dos documentos. O Godot não foi executado. Pela OS-004, o parecer volta à direção de arte antes da OS-005.

## Alterações

1. **Dependência da OS-007:** de `002, 003, 004` para `002, 003, 004, 005, 006`, também em `README.md`. `HeroLook` lê `look_tier`, que ainda não existe em `src/rpg/data/item_data.gd:25-30`, e as OS-006 e 007 mexem nos mesmos corpos de `src/visuals/creature_factory.gd:87-141`.
2. **`armor_tint`:** `HeroLook` ganha `var legacy_tint: Color` só na transição, e ele sai junto com o campo no início da OS-012. A OS-007 mantém os corpos antigos até as OS-009 a 011, e eles precisam da cor em `creature_factory.gd:30,38,41-42,44,47`.
3. **Saguão:** de `LobbyStage.show_hero(class_id, armor, weapon)` para `LobbyStage.show_hero(look: HeroLook)`. `Lobby._refresh_hero` usa `from_sheet` se houver ficha e `from_items` se não houver. Hoje só armadura e arma são lidas em `src/ui/lobby/lobby.gd:108-113`, então o elmo T1 sumiria no saguão.
4. **Viewmodel:** em vez de "reconstrói ao trocar armadura", criar `HeroLook.equals(other)`, e `Viewmodel.setup` retorna cedo se o look for igual. `refresh_player_stats` sempre chama `setup(sheet.class_data, HeroLook.from_sheet(sheet))`, e `_shown_weapon` sai de `src/world/dungeon_run.gd:45,96,325-328`. `changed` dispara a cada XP e ponto (`src/rpg/logic/character_sheet.gd:59,68`), e `setup` recria mãos e luz de cast (`src/actors/player/viewmodel.gd:36-41,82-86`).
5. **Esqueleto:** `_biped_skeleton` e `_limb` viram `CreatureRig.biped_skeleton` e `CreatureRig.limb`, públicos, na OS-006, em vez de ficarem em `hero_base.gd`. Fichas e monstros usam os dois. Em `hero_base`, monstro dependeria de herói, contra a regra S4.
6. **Assinatura:** `from_items(hero_class: StringName, ...)`, aceitando item nulo, e `from_sheet` delega para ela, para a regra P3 ficar num lugar só. O nome `class_id` sombreia `var class_id`, o que o projeto evita (`src/rpg/data/item_data.gd:41`).
7. **`WeaponKit`:** de `build_main_hand(model, tier, rarity)` para `build_main_hand(model, rarity, tier)`, e igual em `build_off_hand`, na OS-008. `viewmodel.gd:55` passa a raridade em segundo lugar e só muda na OS-012; entre as duas ordens, ela viraria tier em silêncio.
8. **Lanterna:** criada uma vez em `WeaponKit._scepter`, na OS-008, em vez de no `priest_model` (OS-011:16) ou à parte no viewmodel (OS-012:77).

## Perguntas da ordem

1. **`RefCounted` basta.** `HeroLook` é derivado: o save guarda só os ids (`src/rpg/logic/character_sheet.gd:132-135`). Campos simples não fecham a porta do multijogador.
2. **Apagar `armor_tint`, sem campo morto, mas só no início da OS-012.** Hoje é lido em `src/actors/ally/party_bot.gd:41` e `src/ui/lobby/lobby_stage.gd:49`. A limpeza inclui `src/rpg/data/item_data.gd:30`, 15 `.tres` em `data/items/` e a citação em `.claude/agents/art-director.md`.
3. **`CreatureFactory.build(visual, glow)`, com `glow` obrigatório.** Caminho: `src/world/dungeon_run.gd:163`, depois `Enemy.setup` (`src/actors/enemy/enemy.gd:32`), depois `enemy.gd:65`. Valor estático criaria estado global dependente de ordem, porque `DungeonWorld.build` também roda no saguão (`src/ui/lobby/lobby_stage.gd:15,27`).
4. **A luz da lanterna fica dentro do rig, criada pelo `WeaponKit` junto da malha do `scepter`, nunca pelo ator.** A luz segue a arma, não a classe: o `tome` não a tem. O viewmodel usa a mesma função. Fora de `props.lights`, ela não entra no orçamento de sombras de `src/world/dungeon_world.gd:147-151`.

## Pendência para a direção de arte

A regra C3 (só a lanterna é luz permanente de herói, uma por sacerdote) conflita com a tabela de raridade, em que o lendário acende uma `OmniLight3D`. O `scepter` lendário existe em `data/items/priest_t3_weapon.tres:11,20`, o que daria duas luzes no sacerdote. As armas T3 de guerreiro e mago também são lendárias e teriam luz permanente. A OS-008 precisa dessa decisão.

## Pontos de uso esquecidos

- `tests/visual/lineup.gd:30-32` tem três chamadas de `build_hero` e não consta da ordem. `tests/check_scripts.gd:11,25-30` compila `tests`, então o `check_scripts` quebraria. As cores equivalem a `w_start_mail`, `m_start_robe` e `p_start_habit`.
- A lista de arquivos da OS-007 omite `party_bot.gd`, `lobby_stage.gd`, `lobby.gd` e `lineup.gd`.
- `tests/visual/hero_review.gd` também chama `LobbyStage` e `Viewmodel`, então as OS-007 e 012 precisam atualizá-lo.
- `Viewmodel.setup` tem duas chamadas: `src/actors/player/player_controller.gd:46-47` e `src/world/dungeon_run.gd:328`. A primeira falta na tabela da OS-004.
- Nenhum teste cita o viewmodel. A OS-012 precisa de um teste de troca de armadura durante a partida.
- A troca de equipamento na partida tem um caminho só: `src/ui/panels/inventory_view.gd:121`, `src/rpg/logic/character_sheet.gd:87-95`, `src/main/dungeon_screen.gd:42`, `src/world/dungeon_run.gd:322`. O inventário não pausa, então a troca pode ocorrer em combate.
- Os bots não precisam reconstruir: a ficha só é montada no spawn (`src/world/dungeon_run.gd:120-139`).

## Riscos

**OS-005**

- `w_start_*` na linha 16 também pega `w_start_mail` e `w_start_plate`, e a plate pode perder a variante 1. Liste `w_start_sword` e `w_start_axe`.
- Um `.tres` esquecido vira T0 sem erro, e `@export_range` não protege edição manual. Inclua em `tests/unit_tests.gd` um teste de `recipe.result.look_tier == recipe.tier` (`src/rpg/data/recipe_data.gd:9`) e do intervalo, com os iniciais em 0.
- Campos adicionados no fim do arquivo cairiam no grupo "Consumível" (`src/rpg/data/item_data.gd:32`). Insira depois da linha 30.

**OS-007**

- Delegar já para `heroes/*.gd` levaria os corpos antigos para essa pasta e reprovaria a OS-006. Mantenha o `match` em `creature_factory.gd`, delegue classe a classe nas OS-009 a 011 e use nomes públicos em `enemy_parts.gd`.
- O ramo `_:` em `creature_factory.gd:43` transforma classe desconhecida em sacerdote. Use `&"priest"` explícito e `push_warning`, como em `creature_factory.gd:20`.

## A confirmar no `check_scripts`

Vêm do conhecimento de GDScript, não de execução: membro inexistente não compila, enum vai para `int` sem erro e o parâmetro gera aviso de sombra.

Medido na OS-007: "membro inexistente não compila" só vale para acesso estático. O resultado completo está na seção final da OS-004.
