# OS-008: Armas e empunhadura

- **Agente:** `gameplay-developer`
- **Depende de:** OS-006, OS-007
- **Arquivos:** `src/visuals/weapon_kit.gd`, `src/visuals/heroes/hero_base.gd`, `src/visuals/creature_factory.gd`, `src/visuals/creature_rig.gd`, `tests/unit_tests.gd`, `tests/visual/hero_review.gd`
- **Fora do escopo:** viewmodel (OS-012), tamanhos por tier além dos listados aqui, lanterna de cinto (OS-011 e OS-015), curvas de `swing`, `overhead` e `thrust` e tudo que é do inimigo.

## Trabalho

1. Reescreva os modelos com os números das fichas: espada, escudo, machado (`warrior.md`), cajado, orbe (`mage.md`), bastão-lanterna e tomo (`priest.md`).
2. Assinatura nova, com a raridade para a luz e o tier para o metal:

```gdscript
static func build_main_hand(model: StringName, rarity: ItemData.Rarity = ItemData.Rarity.COMMON, tier: int = 0) -> Node3D
static func build_off_hand(model: StringName, rarity: ItemData.Rarity = ItemData.Rarity.COMMON, tier: int = 0) -> Node3D
```

A raridade fica em segundo lugar porque `viewmodel.gd:55` já a passa assim e só muda na OS-012. Com o tier em segundo, ela viraria tier em silêncio.

3. `accent_for` passa a devolver `LootDrop.RARITY_COLORS[rarity]`. Nada de `Look.metal`: aço e metal vêm de `Look.hero` e `Look.trim(tier)`.
4. Troque `_grip` por uma tabela por modelo em `hero_base.gd`, com posição e rotação da arma e `set_rest` dos joints, com os valores das fichas. O `_grip` antigo fica com os inimigos.
5. Aplique `arm_swing_r`, `arm_swing_l`, `stride` e `knee_bend` da ficha de cada classe. Sem `knee_bend` na ficha, fica o padrão do rig.
6. Crie a `OmniLight3D` da lanterna uma vez, em `WeaponKit._scepter`, junto da malha, no centro do núcleo: `FFD76A`, energia `.55`, alcance `3.0`, `shadow_enabled = false`. Vale para modelo e viewmodel, em todas as raridades. Fica fora de `props.lights`, então não entra no orçamento de sombras de `dungeon_world.gd:147-151`. O `tome` não tem luz real.
7. Golpe limpa o repouso (J10), na seção abaixo.
8. `build_off_hand` decide pelo modelo antes de criar `root`. Hoje, em `weapon_kit.gd:38-46`, os modelos sem mão secundária devolvem `null` sem liberar o `Node3D` já criado. Cada montagem em `creature_factory.gd:50` e `viewmodel.gd:58` deixa um nó órfão.

## Golpe limpa o repouso (J10)

A soma do repouso da ficha com o golpe é o que tira machado, cajado e bastão da J9. Com `.6 + 1.35` no braço do machado, a arma gira 1,95 rad a mais que a espada. A curva não muda: muda o que soma com ela.

Em `creature_rig.gd`:

```gdscript
var _strike_wrist: Vector3 = Vector3.ZERO
var _strike_clears_rest: bool = false

## Só herói chama. Inimigo continua somando o repouso (J10).
func set_strike_grip(wrist: Vector3) -> void:
	_strike_clears_rest = true
	_strike_wrist = wrist
```

Em `_pose_biped`, troque as duas linhas de `_set_joint` do braço direito por:

```gdscript
var strike_weight: float = 0.0
if _action in [&"swing", &"overhead", &"thrust"]:
	strike_weight = 1.0 if _action_phase == ActionPhase.STRIKE else absf(value)
var shoulder_offset := Vector3(-arm_r.x, arm_r.y, arm_r.z)
var elbow_offset := Vector3(-elbow_r.x, elbow_r.y, elbow_r.z)
if _strike_clears_rest:
	shoulder_offset.x -= _rest[&"shoulder_r"].x * strike_weight
	elbow_offset.x -= _rest[&"elbow_r"].x * strike_weight
	_set_joint(&"hand_r", _strike_wrist * strike_weight)
_set_joint(&"shoulder_r", shoulder_offset)
_set_joint(&"elbow_r", elbow_offset)
```

Só sai o X do repouso. O Z fica, porque ele afasta a arma do corpo e a empunhadura o compensa (J7). A espada tem repouso X zero nos dois joints e punho zero, então nenhum número dela muda. `cast`, `cast_quick`, `shout` e `spin` seguem como estão.

Em `hero_base.gd`, cada modelo de `GRIPS` ganha `&"strike_wrist"`, e `wield` chama `rig.set_strike_grip(grips[&"strike_wrist"])` com o modelo já resolvido:

| Modelo | `strike_wrist` |
|---|---|
| `sword_shield`, `orb`, `tome` | `Vector3.ZERO` |
| `greataxe` | `(-1.235, 0, 0)`, que soma a empunhadura `-2.45` da espada |
| `staff`, `scepter` | `(-.8, 0, .5)` |

Valores previstos em conta, nas coordenadas locais do `chest`, com `+` à frente em metros e ângulo `+` além da vertical. A ponta é `y=1.1` na espada, `y=1.0` no machado, o núcleo no cajado e a origem da lanterna no bastão. O fim é o `value` `.8` do render:

| Arma | Armado: mão, arma | Impacto: mão, ponta, arma | Fim: mão, ponta, arma |
|---|---|---|---|
| Espada | +.43, -13° | +.45, +1.60, -88° | +.36, +1.49, -100° |
| Machado | +.41, -12° | +.44, +1.43, -88° | +.36, +1.33, -100° |
| Cajado | +.36, +22° | +.43, +1.23, -46° | +.36, +1.29, -57° |
| Bastão-lanterna | +.32, +28° | +.39, +1.03, -41° | +.33, +1.11, -54° |
| Orbe | +.44 | +.45 | +.36 |
| Tomo | +.39 | +.41 | +.32 |

Com tolerância de ±.05 m e ±4°, esses valores são o critério. Fora dela, ou com o limite de 30° estourado, não ajuste: volte à direção de arte com a medida.

## Encaixes de raridade

Toda arma e o escudo têm 3 encaixes. Comum não acende nenhum, e encaixe só existe quando aceso. A tabela da seção 9 do guia diz quais acendem, com a cor e a energia.

| Arma | Encaixe 1 (fio) | Encaixe 2 (gema) | Encaixe 3 |
|---|---|---|---|
| Espada | 2 × `extrude_path` pelas bordas da lâmina, pontos `(.0475,.13) (.04,.96) (0,1.1)` e o espelho em x, espessura `.012`, profundidade `.032` | `sphere(.046,8)` em `y=-.13`, sobre o pomo | 2 × `box(.2,.01,.066)` na guarda, em `y=.098` e `y=.122` |
| Escudo | `torus(.3,.325,24)`, rot x 90°, em `z=-.012` | `sphere(.04,8)` em `(0,0,-.1)`, no topo do umbo | `torus(.115,.14,20)`, rot x 90°, em `z=-.03` |
| Machado | 2 × `extrude_path` pela borda das lâminas, pontos `(.32,-.26) (.37,-.1) (.39,.06) (.35,.22)`, espessura `.012`, profundidade `.032` | `sphere(.05,8)` no centro da cabeça | `torus(.035,.05,12)` no cabo, em `y=.5` |
| Cajado | `torus(.125,.135,20)` dentro do aro | `sphere(.03,8)` na haste, em `y=.88` | `torus(.19,.2,20)` fora do aro |
| Orbe | `torus(.16,.17,20)` na rotação do aro | `sphere(.03,8)` sobre o aro | Segundo `torus(.16,.17,20)`, rot `(-.6,0,.4)` |
| Bastão-lanterna | 2 das 6 barras acesas, em lados opostos | `sphere(.03,8)` na haste, em `y=.72` | `torus(.1,.11,12)` sob a lanterna, em `y=.82` |
| Tomo | Lombada, `box(.02,.28,.03)` | `sphere(.036,8)` em `(0,.15,0)`, no topo da lombada | 4 cantoneiras em L, descritas abaixo |

Raridade nunca cria luz real (C3). Lendário é `FFB13C`, energia 1,0, nos 3 encaixes, sem `OmniLight3D`, inclusive nas armas T3 de guerreiro e mago. No `scepter` lendário, a luz da lanterna não muda de cor nem de energia.

Cantoneira do tomo: 2 caixas por canto, `box(.07,.02,T)` em `(±(hw-.032), ±(hh-.007), 0)` e `box(.02,.07,T)` em `(±(hw-.007), ±(hh-.032), 0)`. `hw` e `hh` são a meia largura e a meia altura do livro aberto, e `T` é a espessura total dele mais `.012`. Assim ela passa 3 mm da borda e 6 mm de cada face, e aparece na capa e nas páginas.

Peças que não são encaixe e existem em toda raridade:

- Pomo da espada: `sphere(.04,8)` em `y=-.13`, metal do tier. A gema o cobre por inteiro.
- Disco do escudo: `rot x -PI/2`, não `PI/2`, facetado. Abóbada e umbo ficam na face externa, em -Z, e a face plana fica em +Z, voltada para o braço.
- Empunhadura do escudo em `GRIPS`: posição `(-.104,-.007,-.003)`, rotação igual. O punho hoje fura a face externa ao lado do umbo.

Ajuste por tier: em T2 ou mais, a lâmina da espada passa de `.98` para `1.06`, e o fio passa a usar `(.0475,.13) (.04,1.04) (0,1.18)`.

Em `hero_review.gd`, gire o escudo `PI` em Y em `rarity_warrior_off.png`. Hoje esse render mostra a face de dentro.

## Critérios de aceite

Renders de `hero_review`:

- `turn_*`: nenhuma arma apontada para a frente como pistola. Espada em guarda baixa, cajado em pé com o pé no chão, lanterna fora do disco do chapéu.
- Cabo dentro da mão nas 8 vistas, em espada, machado, cajado e bastão. Orbe e luz do tomo não têm cabo: flutuam além dos dedos, com folga de até 5 cm, e não tocam a mão em nenhuma vista.
- Escudo: abóbada e umbo para fora, sem o punho aparecendo na face externa.
- Machado sobre o ombro, com a cabeça acima dele.
- `pose_swing.png`, nas 6 armas iniciais: tabela de J10, com mão a -.20 m ou menos em `z` local do `chest` nas 3 faixas (J9). O pé da haste pode ficar atrás do peito, fora do corpo.
- `pose_strike.png`, nas 6 armas iniciais: arma desce à frente do corpo. O machado não volta ao ombro durante o golpe, e a espada fica igual à de hoje.
- `rarity_*`: 5 estágios claros em cada arma, escudo incluído. O incomum se separa do comum a olho, sem comparar pixels. Épico e lendário diferentes entre si só pela cor e pela energia, e as cores idênticas às da UI.
- `turn_*` igual ao de hoje nas poses de repouso: J10 só age em golpe.
- Núcleo do cajado violeta, lanterna dourada. Nenhum disco branco.
- `silhouettes_noweapon.png` ainda não vale, porque os corpos ainda são os antigos.
- O esqueleto e o xamã seguem com as armas antigas.

Em código:

- `OmniLight3D.new()` aparece uma só vez em `weapon_kit.gd`, dentro de `_scepter`.
- Teste em `tests/unit_tests.gd`: em lendário, nas duas mãos, `scepter` tem 1 `OmniLight3D`, e `sword_shield`, `greataxe`, `staff`, `orb` e `tome` têm 0.
- Teste em `tests/unit_tests.gd`: `build_off_hand` devolve `null` em `greataxe`, `staff`, `orb` e `scepter`, e `Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)` não muda depois dessas chamadas.
- `viewmodel.gd:55` compila e monta o `scepter` sem mudança, com a luz como nó filho.
- Teste em `tests/unit_tests.gd`: nos 6 modelos, por `build_hero`, nos quadros de `pose_swing`, `chest.to_local(hand_r.global_position).z <= -.20`. Em espada, machado, cajado e bastão, o eixo +Y da arma em coordenadas de `chest` fica a 30° ou menos além da vertical no armado, e à frente dela no impacto e no fim. Tirar `set_strike_grip` de `wield` faz o teste falhar. Confirme com mutação na cópia.
- Teste em `tests/unit_tests.gd`: com `sword_shield`, `hand_r.rotation` fica zero, e `shoulder_r.rotation.x` fica `1.9`, `.75` e `.55` ±.01 nos 3 quadros. `goblin`, `skeleton` e `frost_king` não chamam `set_strike_grip`, e `hand_r.rotation` deles fica zero.
- Teste em `tests/unit_tests.gd` da ordem de `rarity` e `tier`, que o compilador não protege (seção final da OS-004). Em `WeaponKit.build_main_hand(&"sword_shield", ...)` e em `CreatureFactory.build_hero`, olhando só o que está sob `hand_r`:
  - `LEGENDARY` com tier 0: há material com a cor `LootDrop.RARITY_COLORS[ItemData.Rarity.LEGENDARY]` e material com `Look.TRIM_COLORS[0]`.
  - `COMMON` com tier 3: há material com `Look.TRIM_COLORS[3]`, e nenhum com aquela cor lendária.
  - Trocar os dois argumentos em `creature_factory.gd` faz o teste falhar. Confirme com mutação na cópia.
- Teste em `tests/unit_tests.gd` que monta `build_hero` nas 3 classes, com cada `weapon_model` da classe e com `armor_tier`, `head_tier`, `boots_tier` e `weapon_tier` juntos de 0 a 3, além de `armor_variant` 1 em T0. Falha em qualquer erro de script, capturado com `OS.add_logger`, como faz `WarningCatcher`. Campo errado em `look.*` só aparece em execução, e as OS-009 a 015 herdam essa cobertura.

## Revisão de 01/11/2026: AJUSTES

Código e testes da primeira entrega passaram. Os defeitos eram dos números da ficha, corrigidos acima. Refazer: J10, `GRIPS` do escudo, encaixes de espada, escudo e tomo, pomo e disco do escudo. Fica como está: cabo de couro do machado, posição do orbe e da luz do tomo, encaixes de machado, cajado, orbe e bastão, volume do disco em 0,01522, e o teste de S4 só nos construtores de monstro.

`os008_greataxe/pose_strike.png` mostra o machado no ombro no meio do golpe, com a mesma causa. Por isso J10 vale também para `overhead` e `thrust`.

## Revisão final de 01/11/2026: APROVADO

`pose_swing` e `pose_strike` cumprem a J9 nas 6 armas: todas as mãos a -0,20 m ou menos, ângulos a ±1° da previsão e máximo de +28° no armado, no bastão. O machado sai do ombro durante o golpe, e a espada não mudou. `rarity_warrior`, `rarity_warrior_off` e `rarity_priest_tome_off` mostram 5 estágios claros. Em `turn_warrior`, abóbada e umbo ficam para fora, sem o punho na face externa. Em `os008_greataxe/turn_warrior`, a pose de repouso não mudou.

Saíram da tolerância de J10 só valores do mago: no cajado, mão a +.38 e ponta a +1.17 no impacto, e no orbe, mão a +.39, +.40 e +.31. A diferença é de cerca de 5 cm na mão, nas duas armas, sem efeito na J9 nem a olho, e os valores ficam aceitos como estão. Limites que valem daqui em diante: os da J9. A tabela de J10 é registro da previsão.

Mago e sacerdote só usam `cast` e `cast_quick` nos dados de skill, então o pé da haste perto da saia não aparece em jogo.
