# OS-001: Ferramenta de revisão

- **Agente:** `gameplay-developer`
- **Depende de:** nenhuma
- **Arquivos novos:** `tests/visual/hero_review.gd`, `tests/visual/hero_review.tscn`
- **Fora do escopo:** qualquer arquivo em `src/`, `data/`, `assets/`. A ferramenta só lê o jogo.

## Objetivo

Toda revisão de arte depende destes renders. Câmera, luz e métricas são fixas, para que duas versões possam ser comparadas.

## Uso

```bash
godot --display-driver x11 --disable-vsync --resolution 1920x1080 --path . \
  res://tests/visual/hero_review.tscn -- --out=DIR [--class=warrior] [--tier=0] [--variant=0] [--weapon=sword_shield] [--rarity=0]
```

Sem filtros, gera todas as classes com a arma inicial. Precisa terminar em menos de 170 s. Isole a criação do herói em uma função `_make_hero()`, porque a OS-007 vai trocar a chamada de `build_hero`.

## Montagem das cenas

**Sala de referência:** `DungeonWorld` com `GameDB.dungeon(&"frost_gate")`, qualidade Médio. `eye = (-7, 1.7, -2)`, `dir = ((12, 1.7, 2) - eye).normalized()`, `right = dir.cross(UP)`.

**Palco neutro:** fundo `6A7486`, ambiente branco com energia 0,9, uma `DirectionalLight3D` em `rotation (-.8, .6, 0)`. Sem masmorra.

O modelo olha para -Z: `look_at()` sem `use_model_front` aponta a frente dele para o alvo.

## Saídas

| Arquivo | Conteúdo | Câmera |
|---|---|---|
| `turn_<classe>.png` | 8 vistas a cada 45°, na sala | FOV 24, 7 m, olho `eye + (0,-.5,0)`, alvo `spot + (0,1.08,0)`, com `spot = eye + dir*7` no chão |
| `neutral_<classe>.png` | Mesmas 8 vistas | Palco neutro, FOV 26, 7 m |
| `room_05/10/20_front.png`, `_back.png` | As 3 classes lado a lado | FOV 78, `eye`, a 5, 10, 20 m, com 1,5 a 2 m entre elas e `right*3.2` a partir de 10 m para fugir dos braseiros |
| `silhouettes.png` | Preto sem sombreamento sobre branco, 3 vistas por classe, a 20 m | FOV 78, recorte ampliado 4× sem suavizar |
| `silhouettes_noweapon.png` | Igual, com as armas escondidas | Igual |
| `lobby_<classe>.png` | `LobbyStage` real | Câmera do palco |
| `vm_<classe>_<arma>.png` | `Viewmodel` real | FOV 78, na sala |
| `walk_side.png`, `walk_back.png` | Corrida com `animate(dt, 6.0)` por 45 quadros e `_phase = PI*.5` | Palco neutro |
| `pose_cast.png`, `pose_strike.png` | Perfil após `wind_up(&"cast")` e `strike(&"overhead")` | Palco neutro, FOV 40, de +X |
| `tiers_<classe>.png` | T0 a T3 lado a lado, de frente e de costas | Palco neutro |
| `rarity_<classe>.png` | 5 raridades da arma inicial | Palco neutro |
| `report.json` | Métricas abaixo | |

Antes das OS-013 a 015 não há tiers: gere só T0. Antes da OS-008, `rarity` usa `build_main_hand` como está.

## Métricas de `report.json`

Por modelo: `parts` (`MeshInstance3D`), `tris`, `materials` (`material_override` distintos), `height_m` (AABB de todas as malhas), `key_width_m` (AABB só das peças marcadas com `set_meta(&"measure", true)`: ombreiras, gola, chapéu), `limit_ok` (compara com a seção 11 do guia). A arma fica fora da largura, porque escudo e cajado estourariam qualquer medida.

**Regra V1**, frente e costas, com a câmera de `turn_*`:

1. Renderize a placa sem herói e depois com ele.
2. Máscara: pixels em que a soma das diferenças absolutas de RGB (0 a 255) passa de 36.
3. Altura do pixel: `y_m = 1.08 + (H/2 - y_px) / ppm`, com `ppm = H / (2 * 7 * tan(12°))`.
4. L* padrão (sRGB para linear, luminância D65, CIE L*).
5. Zona alta: `y_m > 1.25`, percentil 90. Zona baixa: `.05 < y_m < .9`, percentil 10.
6. Grave `high_p90`, `low_p10` e `v1_ok` (`high_p90 >= 45` e `low_p10 <= 20`).

Para ganhar tempo, percorra só os 760 px centrais com passo de 2 em x.

**Regra V4**, com a mesma câmera e a mesma máscara:

| Classe | Vista | Altura | Meia-largura | Alvo |
|---|---|---|---|---|
| Guerreiro | Costas | .75 a 1.3 m | .14 m | H 0 |
| Mago | Costas | .3 a .85 m | .2 m | H 280 |
| Sacerdote | Frente e costas | .12 a .5 m | .2 m | H 165 |

Tire a média dos pixels em RGB **linear**, volte para sRGB e converta para HSV. Grave `mass_hue`, `mass_value` e `v4_ok` (erro circular de até 15° e V ≥ .15). No blockout final deu 356 e .42, 279 e .25, 164 e .22.

## Critérios de aceite

- Todos os arquivos saem em uma única execução.
- `report.json` mostra `v1_ok = false` no guerreiro e no sacerdote atuais. Se aprovar algum dos dois, a métrica está errada. O mago atual deu 40 contra o mínimo de 45 com a OS-002 aplicada, e pode variar antes dela.
- Duas execuções seguidas dão os mesmos valores, com tolerância de ±2.

## Depois de concluir

Rode a ferramenta com os modelos atuais e guarde a pasta fora do repositório, como "antes" das próximas ordens. Entregue o caminho à direção de arte.
