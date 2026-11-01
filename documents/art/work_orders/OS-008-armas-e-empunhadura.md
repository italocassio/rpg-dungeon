# OS-008: Armas e empunhadura

- **Agente:** `gameplay-developer`
- **Depende de:** OS-006, OS-007
- **Arquivos:** `src/visuals/weapon_kit.gd`, `src/visuals/heroes/hero_base.gd`, `src/visuals/creature_factory.gd`
- **Fora do escopo:** viewmodel (OS-012), tamanhos por tier além dos listados aqui.

## Trabalho

1. Reescreva os modelos com os números das fichas: espada, escudo, machado (`warrior.md`), cajado, orbe (`mage.md`), bastão-lanterna e tomo (`priest.md`).
2. Assinatura nova, com o tier para o metal e a raridade para a luz:

```gdscript
static func build_main_hand(model: StringName, tier: int = 0, rarity: ItemData.Rarity = ItemData.Rarity.COMMON) -> Node3D
static func build_off_hand(model: StringName, tier: int = 0, rarity: ItemData.Rarity = ItemData.Rarity.COMMON) -> Node3D
```

3. `accent_for` passa a devolver `LootDrop.RARITY_COLORS[rarity]`. Nada de `Look.metal`: aço e metal vêm de `Look.hero` e `Look.trim(tier)`.
4. Troque `_grip` por uma tabela por modelo em `hero_base.gd`, com posição e rotação da arma e `set_rest` dos joints, com os valores das fichas. O `_grip` antigo fica com os inimigos.
5. Aplique `arm_swing_r`, `arm_swing_l` e `stride` da ficha de cada classe.

## Encaixes de raridade

Toda arma tem 3 encaixes. Comum não acende nenhum. A tabela da seção 9 do guia diz quais acendem, com a cor e a energia.

| Arma | Encaixe 1 (fio) | Encaixe 2 (gema) | Encaixe 3 |
|---|---|---|---|
| Espada | `blade(.9,.018,.03,.14)` em `y=.13` | `sphere(.032,8)` em `y=-.115` | 2 × `box(.2,.01,.066)` na guarda, em `y=.098` e `y=.122` |
| Escudo | Sem encaixe | Sem encaixe | `torus(.31,.325,24)`, rot x 90° |
| Machado | 2 × `extrude_path` pela borda das lâminas, pontos `(.32,-.26) (.37,-.1) (.39,.06) (.35,.22)`, espessura `.012`, profundidade `.032` | `sphere(.05,8)` no centro da cabeça | `torus(.035,.05,12)` no cabo, em `y=.5` |
| Cajado | `torus(.125,.135,20)` dentro do aro | `sphere(.03,8)` na haste, em `y=.88` | `torus(.19,.2,20)` fora do aro |
| Orbe | `torus(.16,.17,20)` na rotação do aro | `sphere(.03,8)` sobre o aro | Segundo `torus(.16,.17,20)`, rot `(-.6,0,.4)` |
| Bastão-lanterna | 2 das 6 barras acesas, em lados opostos | `sphere(.03,8)` na haste, em `y=.72` | `torus(.1,.11,12)` sob a lanterna, em `y=.82` |
| Tomo | Lombada, `box(.02,.28,.03)` | `sphere(.03,8)` no centro da capa | 4 × `box(.03,.03,.012)` nos cantos |

Em lendário, some uma `OmniLight3D` sem sombra na cabeça da arma: alcance 2,0, energia 0,4, cor `FFB13C`.

Ajuste por tier: em T2 ou mais, a lâmina da espada passa de `.98` para `1.06`.

## Critérios de aceite

Renders de `hero_review`:

- `turn_*`: nenhuma arma apontada para a frente como pistola. Espada em guarda baixa, cajado em pé com o pé no chão, lanterna fora do disco do chapéu.
- Cabo dentro da mão nas 8 vistas.
- Machado sobre o ombro, com a cabeça acima dele.
- `rarity_*`: 5 estágios claros. Épico e lendário diferentes entre si, e as cores idênticas às da UI.
- Núcleo do cajado violeta, lanterna dourada. Nenhum disco branco.
- `silhouettes_noweapon.png` ainda não vale, porque os corpos ainda são os antigos.
- O esqueleto e o xamã seguem com as armas antigas.
