# OS-012: Viewmodel

- **Agente:** `gameplay-developer`
- **Depende de:** OS-009, OS-010, OS-011
- **Arquivos:** `src/actors/player/viewmodel.gd`, `src/actors/player/player_controller.gd`, `src/world/dungeon_run.gd`
- **Fora do escopo:** tempos e curvas de animação de ataque, barreira, luz de cast.

## Problema

É a arte mais vista do jogo. Hoje a mão parece um pé, com dedos em fila, sem envolver o cabo. A manga quase não aparece, a cor é fixa por classe e ignora a armadura. O orbe e a luz do tomo viram um disco branco. No tomo, o jogador vê a capa.

## Mudanças

`Viewmodel.setup(class_data, look)` recebe `HeroLook` e é chamado de novo ao trocar arma ou armadura.

Valores testados no motor, com o resultado em `concepts/blockout/blockout_viewmodel.png`. Nesse render, as armas ainda são as antigas e as mãos esquerdas ainda estão fechadas. A pose antiga deixava só 6 cm de manga na tela:

```gdscript
const RIGHT_REST := Vector3(0.31, -0.2, -0.6)
const LEFT_REST := Vector3(-0.44, -0.29, -0.66)
```

### Mão fechada

Num nó `grip`, com a **mesma rotação da arma** naquela mão:

| Peça | Construção |
|---|---|
| 4 dedos | `torus(.02, r, 14)` em `(0, (i - 1.5) * .031, 0)`, escala `(1,1,1.1)`, `r = .052` nos dois do meio, `.05` nos das pontas |
| Palma | `loft` 8 lados `(0,-.06,.03,.022) (0,0,.05,.026) (0,.06,.03,.02)` em `(lado*.012, 0, .042)` |
| Polegar | `cylinder(.014,.019,.085,8)` em `(lado*-.022, .05, -.03)`, rot `(1.1, 0, lado*.9)` |

Os anéis passam em volta do cabo. É isso que tira o aspecto de pé.

### Mão aberta

Para a esquerda de mago e sacerdote, e para a direita com orbe ou tomo. Nó com rotação `(-.95, .2, .45)`:

| Peça | Construção |
|---|---|
| Palma | `loft` 8 lados `(0,-.05,.032,.022) (0,0,.052,.024) (0,.045,.046,.018)` |
| 4 dedos | `cylinder(.0095,.012,.08,8)` em `((i-1.5)*.027, .08 - abs(i-1.3)*.008, 0)`, rot z igual a `-x * 1.2` |
| Polegar | `cylinder(.011,.014,.07,8)` em `(lado*.06, 0, -.01)`, rot `(.2, 0, -lado)` |

### Antebraço

Segmento de `wrist = (lado*.018, -.06, .075)` a `elbow = (lado*.3, -.26, .56)`, raio de `.058` a `.09`. Com `d` sendo a direção do pulso ao cotovelo:

| Classe | Manga | Detalhe |
|---|---|---|
| Guerreiro | Aço `B0AEA8` | Faixas de metal do tier: de 0 a `.05` em `d`, raio `.066`-`.07`; de `.24` a `.27`, raio `.082`-`.084`. A mão usa aço |
| Mago | `6E2470` | Punho `D5D9E4` de 0 a `.03`, raio `.07`; aro `glow(4F8DFF, .9)` de `.04` a `.065`, raio `.066` |
| Sacerdote | Sino `E6DCC0`, de `-.015` a `.2`, raio `.105`-`.085` | Punho de metal do tier de `-.02` a `.02`, raio `.108` |

Em T1 ou mais, some um punho `EEF1F6` de 3 cm logo acima do pulso, raio `.09`. Metal segue `look.armor_tier`.

### Arma por modelo

| Modelo | Posição | Rotação | `_right_rest_rotation` | Mãos |
|---|---|---|---|---|
| `sword_shield` | `(0,-.02,0)` | `(-.42,0,-.16)` | `(.35,.05,0)` | Direita fechada, esquerda fechada na alça |
| `greataxe` | `(0,-.02,0)` | `(-.42,0,-.16)` | `(.35,.05,0)` | Direita fechada, esquerda fechada |
| `staff` | `(0,-.3,.184)` | `(-.55,0,.12)` | `(.12,0,0)` | Direita fechada, esquerda aberta |
| `scepter` | `(0,-.25,.137)` | `(-.5,0,.1)` | `(.12,0,0)` | Direita fechada, esquerda aberta |
| `orb` | `(0,.14,-.04)` acima da palma | Sem rotação | `(.12,0,0)` | As duas abertas |
| `tome` | Livro na esquerda: `(0,.1,-.06)`, rot `(-1.0,0,.15)`. Luz na direita: `(0,.12,-.04)` | | `(.12,0,0)` | As duas abertas |

Com haste, a posição é calculada para o eixo passar pela origem da mão. Mantenha assim.

Valores do orbe e do tomo são ponto de partida, porque não foram testados no motor. Ajuste até ±.15 rad e ±3 cm para atender aos critérios abaixo. Fora disso, volte para a direção de arte.

### Outros

- Escudo: lado de dentro `5A4632`, alça `box(.3,.05,.03)` em `3A2A22`, escala `.62`.
- Brilho em viewmodel: energia até `.9` (B4). A luz do tomo tem raio `.045`.
- Todo material usa `Look.hero` (M4). A ponta da espada pode sair pelo topo do quadro: é aceito.
- Sacerdote com `scepter`: `OmniLight3D` presa à lanterna, `FFD76A`, energia `.55`, alcance `3.0`, sem sombra.

## Critérios de aceite

Renders `vm_<classe>_<arma>.png`, as 6 combinações iniciais:

- A mão se lê como mão, sem aspecto de pé, com dedos em volta do cabo.
- Nada flutua: o cabo passa por dentro do punho.
- A manga ocupa pelo menos o canto inferior, com a classe reconhecível só pelo braço.
- Trocar para armadura T2 muda o metal do antebraço na mesma cena.
- Núcleo violeta, lanterna dourada, nenhum disco branco.
- Tomo mostra as páginas.
- Até 34 partes no `report.json`.

Durante um golpe, em `tour.tscn`, a mão acompanha a arma e o braço não some nem entra na câmera.
