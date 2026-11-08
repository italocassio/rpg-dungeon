# OS-006: Separar inimigos e unificar o brilho

- **Agente:** `gameplay-developer`
- **Depende de:** OS-002, OS-003, OS-005
- **Arquivos:** `src/visuals/creature_factory.gd`, `src/visuals/creature_rig.gd`, `src/visuals/enemy_parts.gd` (novo), `src/visuals/weapon_kit.gd`, `src/visuals/look.gd`, `src/world/dungeon_run.gd`, `src/actors/enemy/enemy.gd`, `tests/` onde houver chamada de `CreatureFactory.build` ou `Enemy.setup`
- **Fora do escopo:** redesenhar monstros. Forma e materiais continuam iguais, exceto a cor dos olhos e os itens 5 a 7. `HeroLook` e `hero_base.gd` (OS-007).

## Objetivo

Hoje o mago usa o corpo do xamã, o guerreiro usa o corpo do Rei Gélido e o esqueleto usa a espada do herói. Os próximos pedidos reescrevem heróis e armas, então os inimigos precisam sair desse caminho antes (regra S4).

## Trabalho

1. Mova para `enemy_parts.gd` (`class_name EnemyParts`), sem mudar números e com nomes públicos: `armored_body`, `robed_body`, `hood`, `cape`, e cópias de `_sword`, `_shield`, `_staff` de `WeaponKit`. O `Look.metal` fica permitido só aqui. Os corpos antigos de herói ficam em `creature_factory.gd` e chamam esses nomes públicos até as OS-009 a 011. É a única exceção à S4, e é temporária.
2. `_biped_skeleton` e `_limb` viram `CreatureRig.biped_skeleton` e `CreatureRig.limb`, públicos e sem mudar números. Fichas e monstros usam os dois, por serem utilitários sem aparência. Em `hero_base.gd`, monstro dependeria de herói (S4). `_grip` continua em `creature_factory.gd` até a OS-008.
3. `_skeleton` e `_shaman` passam a usar as armas de `enemy_parts.gd`. `cape` deixa de alterar o material em cache: use `.duplicate()`, como `_frost_king` já faz.
4. Crie o brilho único de olho:

| Inimigo | Hoje | Depois |
|---|---|---|
| Goblin | `ffd24a`, 3,5 | `enemy_glow`, 4,0 |
| Lobo | `6fe0ff`, 4,0 | `enemy_glow`, 4,0 |
| Esqueleto | `6cc2ff`, 4,0 | `enemy_glow`, 4,0 |
| Xamã | `7fe0ff`, 4,0 | `enemy_glow`, 4,0 |
| Golem | `7fe0ff`, 5,0 | `enemy_glow`, 4,0 |
| Rei Gélido | `7fe0ff`, 7,0 | `enemy_glow`, 7,0 |

A cor vem de `DungeonData.enemy_glow` por parâmetro, sem valor estático e sem valor padrão:

| Ponto | Mudança |
|---|---|
| `src/world/dungeon_run.gd:163` | Passa `enemy_glow` para `Enemy.setup` |
| `src/actors/enemy/enemy.gd:32` | `Enemy.setup` recebe e guarda `glow` |
| `src/actors/enemy/enemy.gd:65` | Chama `CreatureFactory.build(visual, glow)` |
| Cenas de `tests/` | Carregam o Portão Gélido de `data/dungeons/` e passam o `enemy_glow` dele. Sem literal de cor |

Cristais de `DungeonMaterials.crystal` continuam iguais.

5. Clava do goblin em repouso. Com o cotovelo no sinal certo da OS-003, a base do cabo entra até 4,0 cm na tanga (22 de 414 vértices; antes, 0,4 cm), e a mão encosta nela. Afaste o braço, sem mudar a clava nem a tanga. No fim de `_goblin`:

```gdscript
rig.set_rest(&"shoulder_r", Vector3(0.0, 0.0, 0.12))
```

Isso leva a mão cerca de 10 cm para fora. O render de referência é `rest/compare_goblin.png`, e o da mão é `rest/goblin_mao.png`, na pasta de revisão da OS-003.

6. Pernas de `robed_body` (regra J5). Com o passo da OS-003, as pernas do xamã atravessam a túnica ao andar. Em `EnemyParts.robed_body`, retire as duas chamadas de `limb` em `hip_%s` e `knee_%s`. Os joints continuam em `biped_skeleton`. Mago e sacerdote também usam esse corpo até as OS-010 e 011, e perdem as pernas junto.
7. Passo do goblin. Com `stride = 0.95` e `knee_bend = 0.85`, a canela chega a 1,65 rad da vertical, acima da horizontal. Mantenha o `stride`, que dá a corrida curta dele, e reduza o joelho. No fim de `_goblin`:

```gdscript
rig.knee_bend = 0.65
```

A canela para em 1,49 rad, igual aos 1,49 rad dos bípedes com `stride = 0.75`.

## Critérios de aceite

- `lineup.png`: os seis monstros iguais ao render anterior, exceto pelos olhos do goblin e do esqueleto e pelo braço direito do goblin.
- Goblin em repouso: 0 de 414 vértices do cabo dentro da tanga, e a mão sem encostar nela, de frente e de perfil. A clava continua na mão e, em `swing`, à frente do corpo.
- Xamã andando, em tira fora do repositório com `_phase` em 0, 90°, 180° e 270°, de perfil: nenhuma perna fora da túnica. Parado, igual ao render anterior.
- Goblin andando, na mesma tira: canela abaixo da horizontal nas 4 fases.
- `_biped_skeleton`, `_limb`, `_armored_body`, `_robed_body`, `_hood` e `_cape` não existem mais em `creature_factory.gd`.
- Nada em `enemy_parts.gd` ou `creature_rig.gd` referencia código de herói (S4).
- Trocar `enemy_glow` para `FF7A2E` no recurso muda os olhos de todos os monstros de uma vez, em `lineup.png` e na masmorra. Reverta depois do teste.
- `grep -rn "CreatureFactory.build(" src tests` só acha chamadas com dois argumentos.
- `flow_test` e `tour.tscn` rodam sem erro.

## Resultado da revisão

**APROVADO.** As quatro divergências ficam aceitas:

| Divergência | Decisão |
|---|---|
| Xamã parado muda na barra da túnica | Aceita. Saíram só as pontas das pernas, efeito direto do item 6. No `lineup.png` a diferença não aparece |
| Mão do goblin sai 7,6 cm, não 10 cm | Aceita, e `0.12` fica. Os 10 cm eram estimativa. Vale a folga medida: 2,2 cm na mão e 4,6 cm no cabo |
| 9 de 330 vértices, não 22 de 414 | Aceita. A profundidade de 4,2 cm confirma o defeito descrito, e o resultado é zero |
| Assinaturas de `sword` e `staff` | Aceita. `sword` perde só o ramo de raridade do herói, e o esqueleto muda apenas nos olhos. `staff` mantém `7fd4ff`, registrado no guia |

Fica como está, porque não veio desta ordem: a mão esquerda do goblin parece encostar na quina da tanga, igual ao render anterior.

## Complemento: placa da túnica

A revisão achou um defeito anterior a esta ordem. A placa da frente de `robed_body` flutua de 0,6 cm no topo a 6,1 cm na base, e no perfil aparece como uma tira solta. O item 1 proibia mudar números, então não é falha da implementação. Isso não bloqueia a OS-007.

- **Agente:** `gameplay-developer`
- **Arquivo:** `src/visuals/enemy_parts.gd`, só a linha da `MeshKit.box(Vector3(0.12, 0.72, 0.02))`
- **Mudança:** posição `Vector3(0.0, -0.42, -0.214)` e rotação `Vector3(0.125, 0.0, 0.0)`. Tamanho, material e cor não mudam.
- **Fora do escopo:** o resto de `robed_body`. Mago e sacerdote recebem a mesma placa até as OS-010 e 011.
- **Aceite:** em `shaman_andando_perfil.png`, nas 4 fases, a placa fica colada à túnica, sem vão. No `lineup.png`, a faixa clara da frente continua visível no xamã.
- **Estado:** aprovado. A placa ficou colada nas 4 fases, e a faixa da frente segue visível.
