# OS-012: Viewmodel

- **Agente:** `gameplay-developer`
- **Depende de:** OS-009, OS-010, OS-011
- **Arquivos:** `src/actors/player/viewmodel.gd`, `src/actors/player/player_controller.gd`, `src/world/dungeon_run.gd`, `src/visuals/hero_look.gd`, `src/visuals/look.gd`, `src/rpg/data/item_data.gd`, `data/items/*.tres`, `tests/visual/hero_review.gd`, `tests/flow_test.gd`
- **Fora do escopo:** tempos e curvas de animação de ataque, barreira, luz de cast. Editar `.claude/agents/art-director.md`. Bots: a ficha deles só é montada no spawn (`dungeon_run.gd:120-139`) e eles não reconstroem.
- **Estado:** APROVADO em 02/11/2026, depois dos ajustes da seção Revisão. T0 e T2, em partes, tris e materiais: `sword_shield` 35/3750/6 e 37/3870/8; `greataxe` 17/1364/4 e 18/1424/6; `staff` 24/2640/8 e 26/2760/9; `orb` 23/2328/7 e 25/2448/8; `scepter` 30/1980/6 e 32/2100/8; `tome` 33/1340/7 e 35/1460/8. `limit_ok` em todas.

## Problema

É a arte mais vista do jogo. Hoje a mão parece um pé, com dedos em fila, sem envolver o cabo. A manga quase não aparece, a cor é fixa por classe e ignora a armadura. O orbe e a luz do tomo viram um disco branco. No tomo, o jogador vê a capa.

## Limpeza de `armor_tint`

Primeiro passo da ordem. Depois das OS-009 a 011, os corpos antigos não existem mais.

1. Apague `legacy_tint` de `src/visuals/hero_look.gd`.
2. Apague `armor_tint` de `src/rpg/data/item_data.gd:30` e dos 15 `.tres` em `data/items/`.
3. `.claude/agents/art-director.md` cita `armor_tint` na seção Pipeline. Não edite esse arquivo: a sessão principal faz essa correção.

## Mudanças

`Viewmodel.setup(class_data, look)` recebe `HeroLook` e retorna cedo se `look.equals(_look)`, guardando o último look. Sem isso, `changed` dispara a cada XP e ponto (`character_sheet.gd:59,68`), e `setup` recria mãos e luz de cast (`viewmodel.gd:36-41,82-86`).

| Chamada | Mudança |
|---|---|
| `src/actors/player/player_controller.gd:46-47` | Passa `HeroLook.from_sheet(sheet)` |
| `src/world/dungeon_run.gd:328`, em `refresh_player_stats` | Sempre chama `setup(sheet.class_data, HeroLook.from_sheet(sheet))`. `_shown_weapon` sai de `dungeon_run.gd:45,96,325-328` |
| `src/actors/player/viewmodel.gd:55` | `WeaponKit.build_main_hand(look.weapon_model, look.weapon_rarity, look.weapon_tier)`, e igual em `build_off_hand` |
| `tests/visual/hero_review.gd` | Chamadas de `Viewmodel.setup` passam `HeroLook` |

Valores testados no motor, com o resultado em `concepts/blockout/blockout_viewmodel.png`. Nesse render, as armas ainda são as antigas e as mãos esquerdas ainda estão fechadas. A pose antiga deixava só 6 cm de manga na tela:

```gdscript
const RIGHT_REST := Vector3(0.31, -0.2, -0.6)
const LEFT_REST := Vector3(-0.44, -0.29, -0.66)
```

### Mão fechada

Num nó `grip`, com a **mesma rotação da arma** naquela mão:

| Peça | Construção |
|---|---|
| 4 dedos | `torus(.02, r, 10)` em `(0, (i - 1.5) * .031, 0)`, escala `(1,1,1.1)`, `r = .052` nos dois do meio, `.05` nos das pontas |
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

Em T1 ou mais, some um punho `EEF1F6` de 3 cm logo acima do pulso, raio `.09`. Metal segue `look.armor_tier`. No sacerdote o sino chega a `.1` nesse ponto e engole o punho: lá ele vai de `.02` a `.05` em `d`, logo acima do punho de metal, com raio `.115` (ver Revisão, item 3).

### Arma por modelo

| Modelo | Posição | Rotação | `_right_rest_rotation` | Mãos |
|---|---|---|---|---|
| `sword_shield` | `(0,-.02,0)` | `(-.42,0,-.16)` | `(.35,.05,0)` | Direita fechada, esquerda fechada na alça |
| `greataxe` | `(0,-.02,0)` | `(-.42,0,-.16)` | `(.35,.05,0)` | Direita fechada. Braço e mão esquerdos ocultos: o machado é de uma mão (ver Revisão, item 5) |
| `staff` | `(0,-.3,.184)` | `(-.55,0,.12)` | `(.12,0,0)` | Direita fechada, esquerda aberta |
| `scepter` | `(0,-.25,.137)` | `(-.5,0,.1)` | `(.12,0,0)` | Direita fechada, esquerda aberta |
| `orb` | `(0,.14,-.04)` acima da palma | Sem rotação | `(.12,0,0)` | As duas abertas |
| `tome` | Livro na esquerda: `(0,.1,-.06)`, rot `(-1.0,0,.15)`. Luz na direita: `(0,.12,-.04)` | | `(.12,0,0)` | As duas abertas |

Com haste, a posição é calculada para o eixo passar pela origem da mão. Mantenha assim.

Valores do orbe e do tomo são ponto de partida, porque não foram testados no motor. Ajuste até ±.15 rad e ±3 cm para atender aos critérios abaixo. Fora disso, volte para a direção de arte.

### Outros

- Escudo: lado de dentro `5A4632`, alça `box(.3,.05,.03)` em `3A2A22`, escala `.62`.
- Brilho em viewmodel: energia até `.9` (B4), inclusive nos encaixes lendários. A luz do tomo tem raio `.045`.
- Todo material usa `Look.hero` (M4). A ponta da espada pode sair pelo topo do quadro: é aceito.
- Sacerdote com `scepter`: a `OmniLight3D` vem de `WeaponKit._scepter` (OS-008). Não crie outra no viewmodel.

### Materiais

O teto de 10 materiais da seção 11 não muda. No `report.json` de antes desta ordem, `viewmodel.limit_ok` é `false` nas três classes só por material: 21, 15 e 20, um por parte. `Look.for_viewmodel` duplica o material a cada peça, embora a origem tenha de 4 a 6.

1. `Look.for_viewmodel` guarda a duplicata em `static var _viewmodel_cache: Dictionary[Material, Material]`, com a origem como chave, e devolve a mesma duplicata para a mesma origem.
2. A barreira sai de `StandardMaterial3D.new()` em `_build_barrier` e passa para `Look.barrier(color)`, com os mesmos valores e cache por cor. Sem isso, cada `setup` soma uma entrada ao cache estático, e ela nunca sai. Todo material que entra em `for_viewmodel` vem do cache de `Look`.
3. A duplicata é compartilhada: nada altera um material depois de `for_viewmodel`. Hoje nada altera. A barreira só troca `visible`, e o tween de cast mexe na luz.

### Teste de troca em partida

Nenhum teste cita o viewmodel. Acrescente um caso em `tests/flow_test.gd`, pelo caminho real da troca: `src/ui/panels/inventory_view.gd:121`, `src/rpg/logic/character_sheet.gd:87-95`, `src/main/dungeon_screen.gd:42`, `src/world/dungeon_run.gd:322`. O inventário não pausa, então a troca pode ocorrer em combate.

| Passo | Verificar |
|---|---|
| Equipar armadura T2 com a partida rodando | O viewmodel guarda look com `armor_tier == 2` e mãos novas |
| Ganhar XP e ponto | `changed` dispara, `setup` retorna cedo, mãos e luz de cast são os mesmos nós |
| Equipar armadura durante um golpe | Sem erro no console, sem referência a nó liberado, e a mão volta ao repouso |
| Sacerdote com `scepter`, 3 trocas seguidas | Uma só `OmniLight3D` da lanterna no viewmodel (C3) |
| Alternar 3 vezes entre as mesmas 2 armaduras | `Look._viewmodel_cache.size()` não cresce depois da primeira volta |

## Critérios de aceite

Renders `vm_<classe>_<arma>.png`, as 6 combinações iniciais:

- A mão se lê como mão, sem aspecto de pé, com dedos em volta do cabo.
- Nada flutua: o cabo passa por dentro do punho.
- A manga ocupa pelo menos o canto inferior, com a classe reconhecível só pelo braço.
- Trocar para armadura T2 muda o metal do antebraço na mesma cena.
- Núcleo violeta, lanterna dourada, nenhum disco branco.
- Tomo mostra as páginas.
- Até 38 partes, 4.000 triângulos e 10 materiais no `report.json`, com `viewmodel.limit_ok = true`, nas 6 combinações rodadas com `--class`, `--weapon` e `--rarity=4`, em T0 e em T2 (seção 11 do guia, revista na Revisão).

Durante um golpe, em `tour.tscn`, a mão acompanha a arma e o braço não some nem entra na câmera.

Em código:

- `grep -rn "armor_tint\|legacy_tint" src data tests` não acha nada.
- `grep -rn "EnemyParts" src/visuals/heroes` não acha nada, e não sobra corpo antigo de herói em `creature_factory.gd` (S4).
- `_shown_weapon` não existe mais.
- `flow_test` passa com o teste de troca em partida.
- O teste de ordem de `rarity` e `tier` da OS-008 cobre também `Viewmodel.setup`, na arma da mão direita. Trocar os dois argumentos em `viewmodel.gd` faz o teste falhar.

## Revisão

Aprovado como está: mão fechada em anéis em volta do cabo e do cabo do escudo, mão aberta, mangas por classe, troca de metal em T2 na mesma cena, orbe lilás (matiz 255°, saturação .38), luz do tomo (matiz 47°, saturação .35, sem disco branco), páginas do tomo, limpeza de `armor_tint`, cache de materiais (4 a 8) e o teste de troca em partida. Só `viewmodel.gd`, `look.gd` e `tests/visual/hero_review.gd` mudam.

**1. Orçamento: 38 partes, 4.000 tris, 10 materiais.** O `sword_shield` mediu 35 partes e 4.262 tris em T0: espada 9 e 314; mãos 12 e 1.984 (8 `torus` somam 1.792, 224 cada); braços 6 e 360; escudo 8 e 1.604. O teto de 34 e 3.000 era estimativa anterior à ordem, e os 8 `torus` da própria ordem o consomem sozinhos. Decisão: o guia sobe (seção 11 e seção 13) e o `torus` dos dedos desce para 10 lados, `torus(.02, r, 10)`, 160 tris cada, 1.280 no total. Isso leva o `sword_shield` a cerca de 3.750 em T0. Em T2 somam-se 2 punhos de pele, perto de 4.000. Se passar de 4.000, corte o disco interno e a alça do escudo para 24 lados, nunca os dedos para menos de 10. O `report.json` mede o `sword_shield` em T2 (`vm_*_t2`) e `limit_ok` compara com 38, 4.000 e 10.

**2. Cotovelo no plano próximo: aceito, sem mudança.** O centro do cotovelo fica de 0 a 2 cm à frente de `z = -0,06` no guerreiro e de 3 a 8 cm atrás no mago e no sacerdote (`+0,02` só em `shout`). A cunha de manga aparece em poucos quadros do golpe, cobre o canto superior ou inferior direito e não chega ao centro da tela (`swing_*.png`). Encurtar o antebraço traria de 5 a 7 cm, mas pode mostrar a boca aberta da manga em `thrust`, e isso não dá para medir sem render. Alavanca, se o usuário reclamar: `elbow = (lado*.26, -.23, .49)` no lugar de `(lado*.3, -.26, .56)`, com render de `thrust` e `overhead` nas 3 classes antes de aprovar. O mago só conjura em jogo.

**3. Punho de pele do sacerdote.** O sino tem raio `.1` a 3,5 cm do pulso, então o punho de `.09` fica por dentro e T2 não se distingue de T0. No sacerdote o punho de pele `EEF1F6` vai de `.02` a `.05` em `d`, logo acima do punho de metal (que acaba em `.02`), com raio `.115`: 1,5 cm para fora do sino e 0,7 cm para fora do metal. Guerreiro e mago ficam em 0 a `.03`, raio `.09`. Prova: `vm_priest_scepter_t2.png` mostra uma faixa clara e redonda entre o ouro e o creme, e `montage_t2.png` mostra o sacerdote diferente do T0. O creme `E6DCC0` e a pele `EEF1F6` têm pouco contraste de valor: se a faixa só se ler pela sombra, passe a pele para `F4F7FB` com a mesma energia zero, e avise.

**4. Pele sobre a primeira faixa: aceito.** No guerreiro sobram 2 cm da faixa de aço (`.03` a `.05`) e a segunda faixa a 24 cm; no mago a pele cobre o punho prata `D5D9E4`, que tem quase o mesmo valor, e o aro azul de `.04` a `.065` continua à vista. É a progressão de tier da ficha: T1 troca o metal do pulso por pele.

**5. Machado de uma mão.** Em jogo o machado é de uma mão: a ficha (`shoulder_l (.05,0,-.12)`, `elbow_l` zero) e `build_off_hand`, que só devolve escudo e tomo, não dão nada ao braço esquerdo. Com `greataxe`, braço e mão esquerdos ficam ocultos no viewmodel (`_left.visible = false`, sem construir os 7 nós). A manga direita continua ocupando o canto inferior e lendo a classe. Os `torus` da mão vazia saem da conta de partes. Teste: `greataxe` no `flow_test` não deve criar mão esquerda.

**6. Confirmado.** Teto de `.9` em `Look.for_viewmodel` (B4: 0,9 a 1,0; nunca 1,4). Alça do escudo vertical, com o eixo pela origem da mão: lê como punho de escudo no render. Disco interno e alça somados no viewmodel, porque `WeaponKit._shield` não tem lado de dentro e o modelo de corpo nunca o mostra. Mão aberta direita espelhando a esquerda, com o polegar espelhado. Ficam na conta de partes e de tris da seção 1.

**Renders que provam o fechamento.** `vm_warrior_greataxe.png` sem mão esquerda; `vm_warrior_sword_shield_t2.png` com 38 partes ou menos e `limit_ok`; `vm_priest_scepter_t2.png` e `vm_priest_tome_t2.png` com a faixa de pele visível; `report.json` com os tris por parte.
