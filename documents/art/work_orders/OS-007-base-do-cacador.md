# OS-007: Base comum do caçador

- **Agente:** `gameplay-developer`
- **Depende de:** OS-002, OS-003, OS-004
- **Arquivos:** `src/visuals/hero_look.gd`, `src/visuals/heroes/hero_base.gd`, `src/visuals/mesh_kit.gd`, `src/visuals/look.gd`, `src/visuals/creature_factory.gd`, `tests/visual/hero_review.gd`
- **Fora do escopo:** corpo das classes, armas novas, viewmodel.

## Trabalho

1. Crie `HeroLook` como aprovado na OS-004 e troque as chamadas de `build_hero`. Até as OS-009 a 011, os três `match` continuam chamando os corpos antigos.
2. Mova `WeaponKit._plate` para `MeshKit.plate(outline, thickness)`, sem mudar a geometria.
3. Materiais em `Look`:

```gdscript
const CHARACTER_LIGHT := 0.2
static func hero(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D  # matte + emission = albedo, energia CHARACTER_LIGHT, cache própria
static func two_sided(color: Color, roughness: float = 0.85) -> StandardMaterial3D  # hero com cull desligado, cache própria
static func trim(tier: int) -> StandardMaterial3D   # hero(cor, .40, .45)
const TRIM_COLORS: Array[Color] = [Color("C8963F"), Color("C4D2E0"), Color("D8B464"), Color("E6ECF5")]
```

4. Em `hero_base.gd`, implemente a tabela da seção 10 do guia: cabeça, pescoço, olhos, sobrancelhas, nariz, boca, mão, bota e Selo.

```gdscript
static func head(rig: CreatureRig, skin: Material) -> Node3D
static func hand(rig: CreatureRig, joint_name: StringName, material: Material) -> void
static func boots(rig: CreatureRig, material: Material) -> void
static func seal(rig: CreatureRig, parent: Node3D, position: Vector3, color: Color, trim: Material, energy: float = 1.0) -> void
```

5. Em `hero_review`, troque `_make_hero()` para usar `HeroLook`, e acrescente a saída `mannequin.png`: esqueleto do guerreiro com cabeça, mãos, botas e os dois Selos, sem corpo, no saguão real.

## Especificação visual

Toda a seção 10 do guia. Pele `D9A981`, olho `1A1410` fosco, Selo com energia 1,0.

## Critérios de aceite

Em `mannequin.png`:

- No saguão, a cabeça tem cerca de 69 px, e olhos, sobrancelhas, nariz e boca se distinguem.
- Nenhum olho emite (B1).
- O Selo mantém o matiz, sem lavar para branco (B4).
- A mão é uma forma arredondada, sem caixa nem esfera.

Em código:

- `Look.hero` e `Look.two_sided` não alteram nenhum material já em cache de `Look.matte`.
- `Look.for_viewmodel` preserva a emissão, porque duplica o material.
- Os monstros continuam iguais em `lineup.png`.
- Nenhum `Look.metal` em `hero_base.gd`.
