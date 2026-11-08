# OS-011: Sacerdote T0

- **Agente:** `gameplay-developer`
- **Depende de:** OS-008
- **Arquivos:** `src/visuals/heroes/priest_model.gd`, `src/visuals/creature_factory.gd`
- **Referência:** `documents/art/classes/priest.md`, `concepts/conceito_sacerdote.png`, função `priest()` em `concepts/blockout/bo_heroes.gd.txt`
- **Fora do escopo:** T1 a T3, viewmodel.
- **Estado:** APROVADO em 01/11/2026, depois da seção Revisão (estola, lanterna de cinto e bastão em `y .06`).

## Trabalho

Monte o sacerdote exatamente como a ficha: esqueleto, repouso, todas as peças, chapéu, as duas variantes de T0.

- Sem pernas (J5). Os joints continuam para o rig funcionar.
- O punho usa `MeshKit.lathe(..., close_ends = false)`.
- Sem mitra, sem tira frontal da batina, sem cabeça lisa.
- Não crie luz em `priest_model.gd`. A `OmniLight3D` da lanterna já vem de `WeaponKit._scepter` (OS-008). Com `tome` não há luz real, e a lanterna de cinto fica só com o núcleo emissivo.
- Troque o ramo `&"priest"` do `match` de `build_hero` para delegar a `priest_model.gd` e apague o corpo antigo. O modelo novo não lê `look.legacy_tint` nem chama `EnemyParts`.

## Revisão

Só `priest_model.gd` e a posição do bastão na mão. Aprovado: letra A nas 3 vistas, rosto sob a aba, boca da manga escura, saia sem furo, chapéu sem tampa embaixo (`close_ends=false`, sem z-fighting com o forro, e o aro de 1 cm de aba continua visível por baixo), poça quente no corredor com o bastão e tomo sem luz real, 47 e 48 partes, 14 e 15 materiais.

**1. Estola.** Com 2 colunas, a dobra de `MeshKit.cloth` afunda o centro 4,5 cm (`sin(u*TAU*1.5)*.045*v`) e a sobreveste, que chega a `z -.21` a `-.26`, cobre o meio: sobra um recorte creme em forma de garrafa, de y `-.30` a `-.10`, visível no saguão e de baixo.

| Peça | Antes | Depois |
|---|---|---|
| Estola | `cloth(.11,.13,.36,.1,2,4)` em `(0,0,-.21)` | `cloth(.11,.13,.36,.1,1,4)` em `(0,0,-.22)` |

Com 1 coluna, a dobra vale zero. Resta o `flare` .1, que leva o pano 10 cm para a frente na barra. Folga sobre a sobreveste, em z, de cima para baixo: 2,8 cm, 1,7 cm em y `-.09`, 1,2 cm em y `-.18` (o pior ponto), 1,8 cm em y `-.27` e 7 cm na barra. O topo fica 4,8 cm à frente da faixa. Se o render mostrar qualquer recorte creme, recue `z` mais 1 cm, para `-.23`.

**2. Lanterna de cinto do tomo.** `BELT_LANTERN_POS` de `(.24,-.2,-.06)` para `(.31,-.2,-.06)`. Em `.24` a esfera ficava embutida e só um disco de 2 cm aparecia no contorno, de frente. De costas não aparecia: é a vista mais comum do aliado (E3). O teto e o núcleo seguem a constante. No T3, a segunda lanterna vai para `(-.31,-.2,-.06)`: em `(-.2,-.2,-.08)` ela ficaria 8 cm dentro da sobreveste e não apareceria.

**3. Lanterna do bastão fora da aba.** Em `silhouettes.png` (33 px/m, blocos de 4 px), a base da lanterna fica a 0 cm da ponta da aba de lado e a 1 bloco (4 cm) de frente. O critério da OS pede a lanterna fora do disco. Posição do bastão em `hand_r`: `(0,-.02,0)` para `(0,.06,0)`. O eixo é o do antebraço, não o vertical do mundo, então valeu o resultado medido em 2D (frente / lado, em cm): `-.02` 3,2 / 0,8; `.04` 5,6 / 0,2; `.05` 6,0; `.06` 6,4 / 0,6; `.07` 6,8 / 0,7; `.10` 8,0 / 1,2; `.14` 9,6 / 0,7.

**Decisão (01/11/2026): APROVADO com `y .06`, altura 2,174 m.** De frente o vão é de 6,4 cm, dentro do critério. De lado a medida é contra a copa, não contra a aba, e fica em 0,6 cm: o critério de 6 cm de lado não é alcançável por `y` (o máximo é 1,2 cm, a `.10`, que já custa 4 cm de altura a mais) e só a rotação do bastão o resolveria. Aceito porque S1 pede a letra A a 60 px, onde 1 pixel vale cerca de 3,6 cm e qualquer folga abaixo disso some; no `silhouettes.png` o disco e o sino leem inteiros nas 3 vistas, a lanterna aparece acima da copa e a haste só toca a ponta da aba no contorno de frente. Fica registrado como exceção desta classe, sem mudar a regra S1. Se o usuário achar a lanterna colada no chapéu de lado, a alavanca é a rotação x do bastão, em ordem própria.

**4. Aceitos sem mudança.** Turbante e véu: leem como guia de chapéu largo, sem hábito, mitra ou cruz (O2). O véu, de costas, não lê capuz (S3): é pano retangular de 26 cm, creme, sem ponta. Se o usuário achar a leitura de freira, a alavanca é `length` do véu, de `.26` para `.18`.

## Especificação visual

Todas as medidas e cores estão na ficha. Materiais em `Look.hero`, com olho, sobrancelha, sob a aba e fundo da manga em `Look.matte`. Marque o chapéu com `set_meta(&"measure", true)`. Jade `247050`, creme `E6DCC0`, chapéu `E2D6B6`. Selo e núcleo em `FFD76A`, energia 0,9.

Chapéu em duas peças: a de cima `E2D6B6`, a de baixo `3A2E25`. O escuro separa a aba do rosto.

## Critérios de aceite

Renders de `hero_review`, classe sacerdote:

| Render | Verificar |
|---|---|
| `silhouettes*.png` | Letra A nas 3 vistas. Lanterna fora do disco do chapéu: de frente, vão de 6 cm ou mais (8 px a 129 px/m, 2 blocos a 33 px/m) entre a base da lanterna e a ponta da aba. De lado, a base fica sobre a copa e a exceção está aceita (ver Revisão, item 3) |
| `report.json` | `v1_ok`, `v4_ok`, `key_width_m` do chapéu de `.9 ± .02`, altura de `2.15 ± .05`, até 56 partes |
| `turn_priest.png` | Rosto legível sob a aba, sobreveste sem interpenetrar a saia, estola inteira dourada por fora da sobreveste, sem recorte creme, de frente e em 3/4. Com `tome`, núcleo da lanterna de cinto à vista de frente e de costas, 6 cm ou mais além do contorno da sobreveste |
| `walk_back.png` | Nada fura a saia |
| `lobby_priest.png` | Nenhuma leitura de papa nem de hábito. Boca da manga escura, sem bola de metal |
| `room_05_back.png`, `room_10_front.png` | Saia escura separa da neve. Chapéu claro separa da parede |
| Corredor escuro, com `scepter` | A lanterna clareia o próprio modelo e cria uma poça quente no chão |
| Corredor escuro, com `tome` | Núcleo da lanterna de cinto aceso, sem `OmniLight3D` (C3) |

Comparação: deve ficar no mesmo nível ou acima de `concepts/blockout/blockout_turnaround.png`, terceira linha.

Depois desta ordem, rode `silhouettes.png` com as 3 classes novas. É a primeira revisão de S1 com tudo junto.
