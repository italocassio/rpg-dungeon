# OS-007: Base comum do caçador

- **Agente:** `gameplay-developer`
- **Depende de:** OS-002, OS-003, OS-004, OS-005, OS-006. `HeroLook` lê `look_tier`, que nasce na OS-005, e as OS-006 e 007 mexem nos mesmos corpos de `creature_factory.gd:87-141`.
- **Arquivos:** `src/visuals/hero_look.gd`, `src/visuals/heroes/hero_base.gd`, `src/visuals/mesh_kit.gd`, `src/visuals/look.gd`, `src/visuals/creature_factory.gd`, `src/visuals/enemy_parts.gd`, `src/actors/ally/party_bot.gd`, `src/ui/lobby/lobby_stage.gd`, `src/ui/lobby/lobby.gd`, `tests/visual/hero_review.gd`, `tests/visual/lineup.gd`, `tests/unit_tests.gd`
- **Fora do escopo:** corpo das classes, armas novas, viewmodel, apagar `armor_tint` (OS-012). Bots não reconstroem depois do spawn.

## Trabalho

1. Crie `HeroLook` como no contrato final da OS-004, com `legacy_tint`, `equals` e `from_sheet` delegando para `from_items`.
2. Troque as chamadas de `build_hero`:

| Arquivo | Mudança |
|---|---|
| `src/actors/ally/party_bot.gd:41` | `HeroLook.from_sheet`, sem ler `armor_tint` |
| `src/ui/lobby/lobby_stage.gd:49` | `show_hero(look: HeroLook)`, sem ler `armor_tint` |
| `src/ui/lobby/lobby.gd:108-113` | `_refresh_hero` usa `from_sheet` se houver ficha e `from_items` se não houver. Hoje só lê armadura e arma, e o elmo T1 sumiria no saguão |
| `tests/visual/lineup.gd:30-32` | 3 × `from_items` com `w_start_mail`, `m_start_robe`, `p_start_habit`, que equivalem às cores de hoje, e a arma inicial do mesmo `weapon_model` usado hoje. `tests/check_scripts.gd:11,25-30` compila `tests` |
| `tests/visual/hero_review.gd` | `_make_hero()` e as chamadas de `LobbyStage`. A chamada de `Viewmodel` fica para a OS-012 |

3. Mantenha o `match` e os corpos antigos em `creature_factory.gd`. Não mova nada para `heroes/*.gd`: as OS-009 a 011 delegam classe a classe. Até lá, os três `match` continuam chamando os corpos antigos, que leem `look.legacy_tint` e os nomes públicos de `enemy_parts.gd`.
4. O ramo `_:` em `creature_factory.gd:43` transforma classe desconhecida em sacerdote. Use `&"priest"` explícito e, para classe desconhecida, `push_warning`, no padrão de `creature_factory.gd:20`.
5. Mova `WeaponKit._plate` para `MeshKit.plate(outline, thickness)`, sem mudar a geometria. Se as cópias de `enemy_parts.gd` chamam `_plate`, aponte-as para `MeshKit.plate`.
6. Materiais em `Look`:

```gdscript
const CHARACTER_LIGHT := 0.2
static func hero(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D  # matte + emission = albedo, energia CHARACTER_LIGHT, cache própria
static func two_sided(color: Color, roughness: float = 0.85) -> StandardMaterial3D  # hero com cull desligado, cache própria
static func trim(tier: int) -> StandardMaterial3D   # hero(cor, .40, .45)
const TRIM_COLORS: Array[Color] = [Color("C8963F"), Color("C4D2E0"), Color("D8B464"), Color("E6ECF5")]
```

7. Em `hero_base.gd`, implemente a tabela da seção 10 do guia: cabeça, pescoço, olhos, sobrancelhas, nariz, boca, mão, bota e Selo. O esqueleto não fica aqui: use `CreatureRig.biped_skeleton` e `CreatureRig.limb`, da OS-006.

```gdscript
static func head(rig: CreatureRig, skin: Material) -> Node3D
static func hand(rig: CreatureRig, joint_name: StringName, material: Material) -> void
static func boots(rig: CreatureRig, material: Material) -> void
static func seal(rig: CreatureRig, parent: Node3D, position: Vector3, color: Color, trim: Material, energy: float = 1.0) -> void
```

8. Em `hero_review`, acrescente a saída `mannequin.png`: esqueleto do guerreiro com cabeça, mãos, botas e os dois Selos, sem corpo, no saguão real.
9. Em `tests/unit_tests.gd`, cubra `from_items` e `equals` como nos critérios abaixo.

## Especificação visual

Toda a seção 10 do guia. Pele `D9A981`, olho `1A1410` fosco, Selo com energia 1,0.

## Critérios de aceite

Em `mannequin.png`:

- No saguão, a cabeça tem cerca de 75 px, e olhos, sobrancelhas, nariz e boca se distinguem.
- Nenhum olho emite (B1).
- O Selo mantém o matiz, sem lavar para branco (B4).
- A mão é uma forma arredondada, sem caixa nem esfera.

Em código:

- `Look.hero` e `Look.two_sided` não alteram nenhum material já em cache de `Look.matte`.
- `Look.for_viewmodel` preserva a emissão, porque duplica o material.
- Heróis e monstros continuam iguais em `lineup.png`.
- Nenhum `Look.metal` em `hero_base.gd`.
- `from_items` aceita os 4 itens nulos. Armadura T0 com elmo T1 dá `head_tier == 1`, e o mesmo vale para botas (P3).
- `equals` dá `true` para dois looks dos mesmos itens, `false` para qualquer campo diferente e para `null`.
- `grep -rn "build_hero(" src tests` só acha chamadas com `HeroLook`.
- `src/visuals/heroes/` só contém `hero_base.gd`, sem esqueleto nem `limb`, e monstro nenhum depende dele (S4).
- Classe desconhecida dá `push_warning` e não vira sacerdote.
- `check_scripts` passa, com `lineup.gd` e `hero_review.gd` atualizados, e confirma os pontos da seção final da OS-004.

## Resultado da revisão

**APROVADO depois do ajuste do rosto.** Os demais critérios passaram na primeira revisão: olho sem emissão, Selo sem lavar, mão arredondada e heróis iguais em `lineup.png`.

- **Cabeça:** 75 px está certo, e a cabeça não muda. O erro estava na seção 3 do guia, já corrigida para 3,7 m e 299 px/m.
- **Olhos:** no tamanho real, leem como olho fechado. Olho e sobrancelha têm a mesma espessura e viram duas riscas paralelas, e a inclinação deixa o rosto abatido. O guia já traz os novos valores.
- **Lineup:** o mago com `UNCOMMON` fica, porque essa cena sempre o mostrou assim para exibir a luz da arma.

## Ajuste do rosto

- **Agente:** `gameplay-developer`
- **Arquivo:** `src/visuals/heroes/hero_base.gd`, linhas 31 e 32
- **Fora do escopo:** cabeça, nariz, boca e cores.

```gdscript
rig.part(joint, MeshKit.box(Vector3(0.036, 0.018, 0.012)), eye, Vector3(side * 0.044, 0.132, -0.1))
rig.part(joint, MeshKit.box(Vector3(0.05, 0.008, 0.02)), brow, Vector3(side * 0.045, 0.158, -0.098), Vector3(0.0, 0.0, -side * 0.06))
```

Critérios em `mannequin.png`, no tamanho real do saguão:

- O olho lê aberto e mais forte que a sobrancelha: cerca de 5 px de altura contra 2 a 3 px.
- O vão entre olho e sobrancelha continua visível.
- O rosto fica neutro e sereno, sem raiva (R1).
- O olho continua sem emissão (B1), e a cabeça segue em cerca de 75 px.

Entregue `mannequin.png` e um recorte da cabeça ampliado 7 vezes para a revisão de arte.

**Resultado:** aprovado, com a sobrancelha em `∓.06`. No tamanho real, o olho lê aberto e o rosto fica sereno, sem raiva. Olho com 5 a 6 px, sobrancelha com 2 a 3 px e vão de 2 px. Em relação à linha dos olhos, cada sobrancelha inclina cerca de 0,06 rad. A diferença entre os lados na tela vem do giro de 0,35 rad do palco, e a sobrancelha mais clara vem da grade de pixels, em 2,4 px de altura. As duas coisas somam cerca de 1 px.

O `mannequin.png` mostra um só ângulo. Se o rosto ainda ler abatido em `turn_*.png`, com cabelo e corpo, nas OS-009 a 011, use rotação z `0` nas duas sobrancelhas, sem mudar mais nada.
