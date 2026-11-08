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

**Vista de 20 m:** outro eixo na mesma sala. `eye_20 = (3.8, 1.7, 8.1)`, `alvo_20 = (-4.7, 1.7, -10)`, `dir_20 = (alvo_20 - eye_20).normalized()`, `right_20 = dir_20.cross(UP)`. A distância é 20,0 m. As posições no chão, em (x, z), ficam guerreiro `(-6.06, -9.36)`, mago `(-4.7, -10)`, sacerdote `(-3.34, -10.64)`.

Por que outro eixo: de `eye`, a sala só tem 21,25 m em `dir`, e nenhuma direção passa de 21,3 m. Os 20 m sempre caem atrás da fileira de braseiros (`x = 10.08`), a cerca de 1 m da parede. O novo eixo passa pelo centro da sala, que não tem cenário, e aponta para o lado oposto ao fogo:

- O herói mais próximo fica a mais de 13 m da luz de braseiro (alcance 12) e a mais de 15 m da fogueira oeste (alcance 13). Nenhuma luz de fogo o alcança.
- A luz do `GatePortal`, em `(0, 4, -10.1)`, com energia 5,0 e alcance 17, chega aos heróis e domina a luz fria do centro. Pela curva de atenuação, a soma estimada na vista fica entre 0,6 e 1,0, contra 0,67 no ponto de V1. A luz é fria, permanente na sala e do mesmo nível da referência, então fica aceita.
- Os heróis ficam a 2,8 m da parede ou mais. Pedras e cristais aleatórios só nascem a menos de 2,4 m dela, então não entram entre a câmera e os heróis.
- A fileira cabe entre o cristal à esquerda e o aro do portal à direita, com pés sobre o piso e cabeça e ombros sobre a parede, como pede a seção 5 do guia. O vão útil é de x = 887 a x = 1034 px.

Ao trocar entre `eye` e `eye_20`, na ida e na volta, chame `world._update_light_shadows()` e espere `ROOM_WARMUP_FRAMES`. As 2 luzes com sombra são as mais próximas do foco, e o temporizador só as atualiza a cada 0,4 s. Sem isso, a sombra muda conforme o quadro em que ele dispara. A chamada fica na ferramenta: `src/` continua intocado.

**Palco neutro:** fundo `6A7486`, ambiente branco com energia 0,9, uma `DirectionalLight3D` em `rotation (-.8, .6, 0)`. Sem masmorra.

O modelo olha para -Z: `look_at()` sem `use_model_front` aponta a frente dele para o alvo.

## Saídas

| Arquivo | Conteúdo | Câmera |
|---|---|---|
| `turn_<classe>.png` | 8 vistas a cada 45°, na sala | FOV 24, 7 m, olho `eye + (0,-.5,0)`, alvo `spot + (0,1.08,0)`, com `spot = eye + dir*7` no chão |
| `neutral_<classe>.png` | Mesmas 8 vistas | Palco neutro, FOV 26, 7 m |
| `room_05/10_front.png`, `_back.png` | As 3 classes lado a lado | FOV 78, `eye`, a 5 e 10 m, com 1,5 a 2 m entre elas e `right*3.2` em 10 m para fugir dos braseiros |
| `room_20_front.png`, `_back.png` | As 3 classes lado a lado | FOV 78, `eye_20`, a 20 m, com 1,5 m entre elas, sem desvio lateral |
| `silhouettes.png` | Preto sem sombreamento sobre branco, 3 vistas por classe, a 20 m | FOV 78, recorte ampliado 4× sem suavizar |
| `silhouettes_noweapon.png` | Igual, com as armas escondidas | Igual |
| `lobby_<classe>.png` | `LobbyStage` real | Câmera do palco |
| `vm_<classe>_<arma>.png` | `Viewmodel` real | FOV 78, na sala |
| `walk_side.png`, `walk_back.png` | Corrida com `animate(dt, 6.0)` por 45 quadros e `_phase = PI*.5` | Palco neutro |
| `pose_cast.png`, `pose_strike.png` | Perfil após `wind_up(&"cast")` e `strike(&"overhead")` | Palco neutro, FOV 40, de +X |
| `pose_swing.png` | Perfil no golpe `swing`: armado, impacto e fim, em 3 faixas. Entra na OS-003 | Palco neutro, FOV 40, de +X |
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

Em `room_20_front.png` e `room_20_back.png`:

- Heróis centrados em x = 910, 960 e 1010 px, com ±8 px e de 60 a 80 px de altura.
- Nada entre a câmera e os heróis, e os três inteiros no quadro.
- O ombro do guerreiro não encosta no cristal, e o sacerdote não encosta no aro do portal. Fica parede visível entre eles, nas duas vistas.
- Pés sobre o piso, cabeça e ombros sobre a parede.
- Nenhuma chama a menos de 600 px de um herói. As chamas em quadro ficam perto das bordas, em torno de x = 20 e x = 1730. O calor cortado na borda direita, de x = 1896 a 1918, é aceito.
- Nenhum herói com lado laranja de fogo.

Se uma pedra ou um cristal cobrir parte de um herói, use `eye_20 = (4, 1.7, 8.6)` e `alvo_20 = (-4.5, 1.7, -9.5)`, que mantêm os 20 m. Se ainda cobrir, volte à direção de arte.

## Depois de concluir

Rode a ferramenta com os modelos atuais e guarde a pasta fora do repositório, como "antes" das próximas ordens. Entregue o caminho à direção de arte.

## Revisão de 01/11/2026: AJUSTES

Todas as saídas e métricas cumprem a ordem, exceto `room_20`. O defeito é desta ordem, não da implementação. Falta:

1. Implementar a vista de 20 m descrita em "Montagem das cenas". `room_05` e `room_10` não mudam.
2. Gerar de novo a pasta "antes", ainda com os modelos atuais, e entregar `room_20_front.png` e `room_20_back.png` à direção de arte.

As OS-002 e 003 só começam depois disso: elas mudam os modelos, e o "antes" de 20 m se perderia.

## Revisão final da vista de 20 m, 01/11/2026: AJUSTES

`eye_20` e `alvo_20` estão certos e continuam. Com 1,8 m entre os heróis, o ombro do guerreiro encosta no cristal, por 1 a 2 px, e a fileira não tem folga para as peças da OS-007 em diante: a ombreira de 0,99 m e a aba de 0,90 m do chapéu do sacerdote encostariam nas duas pontas do vão.

1. Troque o espaço de 1,8 para 1,5 m. Câmera, `room_05` e `room_10` não mudam.
2. Gere de novo a pasta "antes" e entregue `room_20_front.png` e `room_20_back.png` à direção de arte.
