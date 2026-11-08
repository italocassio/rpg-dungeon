# OS-002: Corrigir malhas do avesso

- **Agente:** `gameplay-developer`
- **Depende de:** OS-001
- **Arquivos:** `src/visuals/mesh_kit.gd`, `src/visuals/weapon_kit.gd`, `src/world/dungeon_props.gd`, teste novo em `tests/unit_tests.gd`
- **Fora do escopo:** mudar a forma de qualquer modelo. Esta ordem só vira as faces e inverte a ordem dos pontos do perfil do escudo, sem mudar nenhum ponto.

## Problema

`MeshKit.lathe`, `loft`, `shard` e três faces de `extrude_path` estão com o sentido das faces invertido. Volume assinado medido, com referência negativa nas malhas nativas do Godot:

| Gerador | Volume | Normal média para fora |
|---|---|---|
| `BoxMesh`, `CylinderMesh`, `SphereMesh` | Negativo | Positiva |
| `rock`, `blade`, `_plate` | Negativo | Positiva |
| `lathe`, `loft`, `shard` | **Positivo** | **Negativa** |

Com o back-face culling, o jogo mostra o lado de dentro da parede oposta. Essa é a causa real da "saia com quinas", dos torsos ocos e das colunas e braseiros tortos. Veja `concepts/blockout/antes_depois_malha.png`.

## Correção exata

```gdscript
# lathe
_quad(st, a, b, c, d)
_triangle(st, bottom, ring.call(0, side + 1), ring.call(0, side))
_triangle(st, top, ring.call(profile.size() - 1, side), ring.call(profile.size() - 1, side + 1))

# loft
_quad(st, at.call(i, side), at.call(i, side + 1), at.call(i + 1, side + 1), at.call(i + 1, side))
_triangle(st, bottom, at.call(0, side + 1), at.call(0, side))
_triangle(st, top, at.call(rings.size() - 1, side), at.call(rings.size() - 1, side + 1))

# shard
_quad(st, base_ring[side], base_ring[next], shoulder_ring[next], shoulder_ring[side])
_triangle(st, shoulder_ring[side], shoulder_ring[next], tip)

# extrude_path: as 3 faces erradas (a de c0, c1, d1, d0 já está certa)
_quad(st, a0, a1, c1, c0)
_quad(st, b0, d0, d1, b1)
_quad(st, a0, b0, b1, a1)
```

Não mexa em `rock`, `blade`, `cloth`, `_plate`. Nem em `_quad` e `_triangle`, que `blade` usa corretamente.

## Efeito colateral: estandartes

Com as colunas sólidas, os estandartes somem: `_add_banners` usa `angle = TAU * (i + .5) / count + .2`, que cai exatamente sobre as colunas da sala (`TAU * i / pillar_count + .2`). Eles só apareciam porque as colunas estavam ocas.

Em `_add_banners`, encaixe cada estandarte no vão mais próximo, a meio caminho entre duas colunas. Somar meio passo só resolve quando `pillar_count` é múltiplo de `count`, e as salas reais têm 8 estandartes para 19 colunas e 4 para 9:

```gdscript
var pillar_count: int = _pillar_count(room)
var step: float = TAU / float(pillar_count)
# dentro do laço
var gap: float = floorf(TAU * (float(i) + 0.5) / float(count) / step)
var angle: float = 0.2 + (gap + 0.5) * step
```

No `lineup`, com 16 colunas e 4 estandartes, as posições continuam iguais. A extração de `_pillar_count` fica como está.

## Efeito colateral: escudo

`WeaponKit._shield`, em `weapon_kit.gd:116`, tem o perfil de cima para baixo e só saía certo por dupla inversão. Com o `lathe` corrigido, o disco fica oco. Inverta a ordem dos pontos, sem mudar nenhum:

```gdscript
var profile := PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.34, -0.02), Vector2(0.33, 0.0), Vector2(0.18, 0.025), Vector2(0.0, 0.03)])
```

Regra G1 do guia. Os perfis de `dungeon_props.gd:126` e `forge_brazier.gd:15` sobem e só dobram para dentro na borda da bacia: estão certos e não mudam.

## Teste automatizado

Em `tests/unit_tests.gd`, some o volume assinado (`a.dot(b.cross(c)) / 6`) de `lathe`, `loft`, `shard`, `rock` e `blade`. Todos precisam dar negativo.

Faça a mesma conta no disco de `WeaponKit.build_off_hand(&"sword_shield")`. Precisa dar -0,01222, com tolerância de ±0,0005.

## Critérios de aceite

Compare antes e depois com `lineup.tscn`, `world_shots.tscn` e `hero_review`.

- Colunas com base e capitel sólidos, sem a forma aberta no pé.
- Braseiros com bacia fechada, com a chama dentro.
- Saias e torsos atuais sem as quinas. As pernas não aparecem mais pela frente da saia.
- Estandartes visíveis entre as colunas, no `lineup.png`.
- Nas salas reais, cada estandarte fica a pelo menos 4 m do eixo de uma coluna: 8 de 8 na sala do chefe e 3 de 3 na antecâmara, onde o quarto cai na abertura.
- Escudo fechado, sem o umbo visível por dentro, em `lineup.png`, `vm_warrior_sword_shield.png` e no esqueleto.
- Cristais de gelo com a borda clara do `ice_crystal.gdshader` na parte de fora. Se algum ficar mais forte ou mais fraco que antes, avise a direção de arte em vez de ajustar. O realce mais forte já foi avisado e fica com a OS-018.
- Nenhuma malha some nem ganha furo em `tour.tscn`, inclusive na sala do chefe.

O código de colisão não usa estas malhas: `ConcavePolygonShape3D` vem do campo SDF, com `backface_collision`. Nada muda ali.

## Revisão de 01/11/2026: AJUSTES

Colunas, braseiros, arcos, saias e torsos estão aprovados nos renders. Faltam dois ajustes:

1. Escudo, como na seção "Efeito colateral: escudo", com o teste de volume.
2. Estandartes, como na seção "Efeito colateral: estandartes".

As nervuras escuras no teto da sala do chefe são a geometria que o código já previa, e ficam aceitas. Os cristais não bloqueiam esta ordem.

Depois dos ajustes, rode os testes e entregue `lineup.png`, `lineup_close.png`, `vm_warrior_sword_shield.png`, `world/view_3.png` e uma vista da antecâmara à direção de arte.
