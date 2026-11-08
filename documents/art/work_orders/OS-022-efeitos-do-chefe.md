# OS-022: Efeitos de ataque do Rei Gélido

- **Agentes:** `rpg-systems` (parte A: dados) e `gameplay-developer` (parte B: código e shader). A parte B só começa com a A aprovada. `qa-tester` depois das duas.
- **Depende de:** OS-021 (âncoras `weapon_tip`, `core`, `crown`, metas `blade_material`, `core_material` e `crown_material`, tempos `strike_time` 0,18 e `recover_time` 0,50). A parte A pode correr em paralelo à OS-021.
- **Arquivos, parte A:** `src/rpg/data/skill_fx_data.gd` (novo, com a função estática `shake_trauma`), `src/rpg/data/skill_data.gd` (campo `fx`), `data/skill_fx/boss_*.tres` (5 novos), `data/skills/boss_*.tres` (só a referência `fx`), `tests/unit_tests.gd`
- **Arquivos, parte B:** `src/actors/enemy/attack_fx.gd` (novo, filho do `Enemy`), `src/actors/enemy/enemy.gd` (só criar o filho e ligar os sinais), `src/fx/vfx.gd` (funções novas, as atuais não mudam), `src/combat/telegraph.gd`, `assets/shaders/telegraph.gdshader`, `src/combat/skill_executor.gd` (só o desvio e o parâmetro `hostile`, descritos em "Ligações"), `src/autoload/events.gd` (só o sinal `camera_shake_requested`), `src/ui/hud/combat_feedback.gd` (só ouvir o sinal e aplicar o tremor), `tests/visual/tour.gd`, `tests/unit_tests.gd`
- **Fora do escopo:** dano, alcance, recarga e IA; o modelo do chefe (OS-021); os efeitos de heróis e dos monstros comuns (continuam como estão, com `fx` nulo); o que a câmera faz além do tremor; UI além do `CombatFeedback` ouvir o evento de tremor; áudio; a marca de área de aliado (`m_meteor`, `p_judgement`), que fica exatamente como está; `dungeon_props.gd` (a reação das runas é opcional, seção 8).
- **Estado:** Aprovada em 08/11/2026, com uma pendência de uma constante (`ConvergenceShards.TILT = 0,45`, seção "Resultado"). Zona vermelha só para conjurador hostil e tremor por evento já incorporados.

## Problema

| # | O que está errado | Dado |
|---|---|---|
| 1 | A telegrafia soma luz sobre neve clara e some | `telegraph.gdshader`: `blend_add`, `ALBEDO = tint * 1,1`, `ALPHA` de 0,07 a 0,2 no preenchimento. A neve mede L* 54 a 75: somar cor clara a ela satura em branco |
| 2 | A cor da zona é a cor da habilidade, e a do chefe não tem lógica | `boss_strike` e `boss_cleave` em `FF5A5A`, `boss_slam` em `7FD4FF`, `boss_spikes` em `9FE3FF`, `boss_nova` em `BFEAFF`. Quatro das cinco são azul-claro sobre neve |
| 3 | A nova disputa a borda com as runas do chão | `_add_rune_floor` desenha `9FE3FF` em 16,24 e 16,74 m (0,97 e 1,0 de `0,62 · 27`). A nova tem raio 16 e, com o desenho de +0,4 m, borda em 16,4: entre os dois anéis |
| 4 | O acerto soma o raio do alvo e o desenho não | `in_cone`, `in_line` e `hostiles_near` somam `body_radius` (0,4 do jogador). O jogador leva dano até 0,4 m fora do desenho |
| 5 | O chefe não tem identidade visual própria | Slam e nova usam o `shockwave` dos heróis, spikes usa o `line_wave` do `w_seismic`, o cleave só tem `hit_burst` em quem foi atingido e o strike não tem nada |
| 6 | O tremor só acontece quando o jogador toma dano | `add_trauma` só é chamado de `combat_feedback.gd`. Quem desvia não sente o golpe |
| 7 | Nenhum aviso sai do corpo do chefe | A única pista antes do golpe é a pose do rig e a zona no chão |
| 8 | O `Telegraph` não é só de inimigo | `SkillExecutor._ground_area` (`skill_executor.gd:106`) chama `Telegraph.spawn_area(tree, point, skill.radius, skill.impact_delay, skill.color)` para toda área atrasada no chão, inclusive de herói: `m_meteor` e `p_judgement`. Trocar a cor e a mistura para todos faria o meteoro do próprio jogador virar uma zona de perigo vermelha. Fora do chefe, só `mon_smash` tem `telegraph = true` |

## Decisões

| Questão | Decisão | Motivo |
|---|---|---|
| Cor da telegrafia | **Fixa, igual para todo inimigo e todo tema, quando o conjurador é hostil ao jogador (`Combatant.Team.MONSTERS`):** vermelho de perigo, `A01030` no preenchimento e `FF6A4D` na borda. Não vem de `skill.color` nem de `enemy_glow` | Telegrafia é sinal de jogo, e o chefe já usa dois matizes. O vermelho é o único matiz que o gelo, as runas e o `enemy_glow` do gelo não têm. Num tema de fogo (`FF7A2E`) o contorno escuro mantém a leitura |
| Cor dos efeitos de preparo e de impacto | **`Enemy.glow`** (o `enemy_glow` do tema). `SkillFxData.impact_color` com alfa 0 quer dizer "tema" | A forma de inimigo é pontuda e na cor do tema (seção 6 do guia). No gelo isso dá `7FE0FF`, que é o que as pontas do chefe já são |
| Marca de aliado | **Não muda.** Conjurador do grupo (`Team.PARTY`) mantém a cor da habilidade e a leitura de hoje: só aditiva, sem faixa escura, sem serrilha, no tamanho lógico (sem os 0,4 m). No shader `premul_alpha` isso é `ALPHA = 0` e `ALBEDO = tint · 1,1 · alfa_de_hoje` | A marca de área é compartilhada com `m_meteor` e `p_judgement`. É o jogador quem atira, e ele não pode ler o próprio golpe como perigo |
| Mistura | **Duas camadas.** Preenchimento por alfa (mistura, escurece a neve) e borda aditiva (acende sobre pedra escura) | Só aditivo some na neve, e só alfa some na pedra. As duas juntas leem nas duas |
| Efeito genérico | **Continua como base e como reserva.** `hit_burst` em quem foi atingido não muda. `shockwave`, `line_wave` e `melee_arc` seguem valendo para toda habilidade sem `fx`. Com `fx.impact_style` diferente de `NONE`, o `SkillExecutor` pula o genérico de área e o `AttackFx` desenha o do chefe | Heróis e monstros comuns não mudam. O chefe deixa de repetir o efeito do `w_seismic` |
| Slam e nova | **Mesma família.** `FRACTURE` (slam) e `CROWN` (nova) dividem o código: rachaduras, anel serrilhado, estacas e poeira, com raio e quantidade por escala. A nova soma a coroa de estacas na borda. Preparo `CORE` e `WINTER` dividem o núcleo, a luz e a névoa | Menos código, e o jogador aprende uma leitura só: a nova é "a mesma coisa em tamanho de sala" |
| Linguagem pontuda | **Nenhuma forma de efeito é redonda.** Estaca, rachadura, serrilha, chevron e lasca. A única forma sem ponta é a partícula de poeira e de neve, que é pequena. Anel é fita em zigue-zague, nunca toro. **Sem cúpula e sem tela cheia** | S3 e pilar 3. E o gargalo da cena é preenchimento de tela (seção 11): uma cúpula de 16 m cobriria o quadro inteiro |
| Tremor | **Evento, não chamada.** O `AttackFx` emite `Events.camera_shake_requested(origin, strength, radius)` e o `CombatFeedback`, que já é dono do tremor, decide a câmera. A fórmula é uma função estática pura em `SkillFxData` | Arquitetura do projeto: gameplay emite fatos, a camada de feedback decide a câmera. O `AttackFx` nunca guarda referência ao jogador |
| Cruz (O2) | Rachaduras em número ímpar (7 e 11) com fase fixa: nenhum par fica a 90° ou a 180° | Oito rachaduras a 45° desenham um "+" no chão |

## Parte A: dados

### `SkillFxData` (`Resource`, `src/rpg/data/skill_fx_data.gd`)

`SkillData.fx: SkillFxData`, `null` por padrão. Habilidade sem `fx` age exatamente como hoje.

| Campo | Tipo | Padrão | Significado |
|---|---|---|---|
| `telegraph_style` | enum `NONE, PLAIN, CONE_TEETH, CRACKS, CHEVRONS, CROWN` | `PLAIN` | Estilo da zona (seção 3). `NONE` apaga a zona mesmo com `skill.telegraph` verdadeiro. `PLAIN` é a base de duas camadas, sem serrilha |
| `prep_style` | enum `NONE, BLADE, TIP_CRYSTALS, CORE, WINTER` | `NONE` | Sinal do preparo (seção 4) |
| `prep_anchor` | `StringName` | `&"weapon_tip"` | Joint do rig que ancora o sinal. Se o joint não existir, usa a origem do inimigo |
| `prep_peak` | `float` | 3,0 | `glow` do cristal alvo no último instante do preparo (0 a 7,0) |
| `prep_motes` | `int` | 0 | Partículas do emissor de preparo (0 a 80) |
| `prep_shake` | `float` | 0,0 | Trauma de 0 a 1, repetido a cada 0,5 s durante o preparo |
| `impact_style` | enum `NONE, ARC, SCYTHE, FRACTURE, STAKES, CROWN` | `NONE` | Forma do impacto (seção 5) |
| `impact_color` | `Color` | alfa 0 | Alfa 0 usa `Enemy.glow` |
| `impact_scale` | `float` | 1,0 | Multiplica a altura das estacas e das lascas |
| `impact_duration` | `float` | 0,5 | Vida total do efeito, com o desaparecimento, em segundos |
| `impact_delay` | `float` | 0,0 | Segundos depois do `skill_fired` (campo que faltava: a lâmina só cruza a frente 0,09 s depois do disparo) |
| `shake_strength` | `float` | 0,0 | Trauma de 0 a 1 no impacto, na distância 0 do alcance cheio |
| `shake_radius` | `float` | 0,0 | Distância em metros em que o tremor chega a zero |
| `flash_energy` | `float` | 0,0 | Energia da luz do clarão. 0 não cria luz |

### Função do tremor

Em `SkillFxData`, estática e pura, sem acesso à árvore:

```gdscript
static func shake_trauma(strength: float, radius: float, distance: float) -> float
```

Devolve `strength · clamp(1 - (distance - 0,35·radius) / (0,65·radius), 0, 1)`, e 0 se `radius <= 0`. É a fórmula da seção 5. O `CombatFeedback` chama esta função, o `AttackFx` não.

### Valores das cinco habilidades

Um `.tres` por habilidade em `data/skill_fx/`, referenciado em `data/skills/boss_*.tres`.

| Campo | `boss_strike` | `boss_cleave` | `boss_slam` | `boss_spikes` | `boss_nova` |
|---|---|---|---|---|---|
| `telegraph_style` | `NONE` | `CONE_TEETH` | `CRACKS` | `CHEVRONS` | `CROWN` |
| `prep_style` | `BLADE` | `BLADE` | `CORE` | `TIP_CRYSTALS` | `WINTER` |
| `prep_anchor` | `weapon_tip` | `weapon_tip` | `core` | `weapon_tip` | `core` |
| `prep_peak` | 4,0 | 5,0 | 6,0 | 5,0 | 7,0 |
| `prep_motes` | 0 | 24 | 36 | 30 | 80 |
| `prep_shake` | 0 | 0 | 0 | 0 | 0,08 |
| `impact_style` | `ARC` | `SCYTHE` | `FRACTURE` | `STAKES` | `CROWN` |
| `impact_color` | tema | tema | tema | tema | tema |
| `impact_scale` | 1,0 | 1,0 | 1,0 | 1,0 | 1,3 |
| `impact_duration` | 0,25 | 0,55 | 1,4 | 1,2 | 2,2 |
| `impact_delay` | 0,09 | 0,09 | 0,09 | 0,09 | 0,09 |
| `shake_strength` | 0,20 | 0,35 | 0,65 | 0,40 | 0,90 |
| `shake_radius` | 12 | 16 | 22 | 26 | 34 |
| `flash_energy` | 1,0 | 1,6 | 3,0 | 1,8 | 4,0 |

`boss_strike` continua com `telegraph = false`. O aviso dele é o brilho da lâmina (seção 4). O `.tres` mantém `skill.telegraph` como está nas cinco.

### Testes da parte A

- Os 5 `.tres` carregam e cada campo está nos limites da tabela de campos.
- `strike.fx.telegraph_style == NONE` e `strike.telegraph == false`. As outras quatro têm `telegraph == true`.
- Todo `SkillData` fora do chefe tem `fx == null`.
- Os valores da tabela acima conferem, uma linha por habilidade.
- `SkillFxData.shake_trauma` devolve a tabela de `d` da seção 5 com tolerância de 0,01 para as cinco habilidades, 0 com `radius` 0 e nunca passa de `strength`.

## Parte B: código

### Ligações

`AttackFx` é criado no `Enemy._ready` quando alguma das habilidades do inimigo (`data.skills` e as das fases) tem `fx`. O critério é o dado, não o tier. Liga em `caster.cast_started`, `caster.cast_interrupted` e `caster.skill_fired`. Cálculo e desenho ficam separados: curvas de brilho, tremor, atraso e contagens são funções puras e testáveis em headless; só o desenho passa por `Vfx`, que é no-op sem janela. O `AttackFx` não conhece o jogador: para o tremor, emite o sinal novo `Events.camera_shake_requested(origin: Vector3, strength: float, radius: float)`, com `origin` na posição do chefe, no instante do impacto (depois de `impact_delay`) e a cada 0,5 s do preparo quando `prep_shake > 0` (força `prep_shake`, raio `shake_radius`). O `CombatFeedback` escuta o sinal, calcula `d` como a distância horizontal do jogador a `origin`, aplica `SkillFxData.shake_trauma(strength, radius, d)` e chama `_player.add_trauma` com o resultado, só quando é maior que 0.

Desvio no `SkillExecutor`: nas três entregas de área (`_self_area`, `_line`, `_ground_area`/`area_impact`), pule `shockwave`/`line_wave` quando `skill.fx != null and skill.fx.impact_style != NONE`. O `hit_burst` em quem foi atingido e o `Events.skill_impacted` ficam.

Marca de área e conjurador: `Telegraph.spawn` deriva `hostile` de `caster.team == Combatant.Team.MONSTERS`. `Telegraph.spawn_area` ganha o parâmetro `hostile: bool = false` (o padrão é a marca de aliado, que é o comportamento de hoje), e o `SkillExecutor._ground_area` passa `caster.team == Combatant.Team.MONSTERS`. O shader recebe `hostile` como uniform.

### 3. Telegrafia

`telegraph.gdshader` passa a `render_mode unshaded, cull_disabled, blend_premul_alpha, depth_draw_never, depth_test_disabled`. Com `premul_alpha`, `ALPHA` 0 soma e `ALPHA` maior que 0 mistura: uma camada de cada, no mesmo shader.

Camadas, de baixo para cima. Valem só com `hostile` verdadeiro; a marca de aliado está no fim desta seção.

| Camada | Cor (hex) | Efeito | Faixa | Alfa ou energia |
|---|---|---|---|---|
| Preenchimento | `A01030` | Mistura | Zona inteira | Alfa 0,22 fora do progresso, 0,55 dentro (`r < progress`), mais 0,08 de rampa até a borda |
| Faixa escura | `220410` | Mistura | 0,35 m para dentro da borda | Alfa 0,65. Substitui o preenchimento na faixa, não soma com ele |
| Borda acesa | `FF6A4D` | Soma | 0,14 m | Energia 1,3, com pulso `0,75 + 0,25·sin(t·f)` e `f` de 6 a 20 rad/s conforme o progresso |
| Aviso final | `FF9A7A` | Soma | Zona inteira, só com progresso acima de 0,85 | Energia 0,25, pulsando a 24 rad/s |

O alfa total passa de 0,65 em nenhum ponto. Sobre a neve, o preenchimento escurece e avermelha o piso (a neve de `AAC0D7` vira cerca de `A45E7B`): a zona lê pela cor e pelo valor. Sobre a pedra escura, a borda acesa é que lê.

**Geometria.** Na zona hostil, o desenho é a área lógica mais 0,4 m em todas as bordas (raio, comprimento e metade da largura; nas duas laterais do cone, 0,4 m medidos no chão). Serrilha, quando existir, fica fora dos 0,4 m. O `Telegraph.contains` e a lógica de acerto não mudam. O quadro do `QuadMesh` cresce o suficiente para caber raio + 0,4 + dente.

**Estilos.** Os números são constantes em `Telegraph`, em metros.

| Estilo | Quem usa | Serrilha | Extras no shader |
|---|---|---|---|
| `PLAIN` | Qualquer habilidade de conjurador hostil com `telegraph` e sem `fx` (hoje, só `mon_smash`) | Nenhuma | Só as camadas acima. A cor passa a ser fixa para todos os monstros |
| `CONE_TEETH` | `boss_cleave` (r 9, 120°) | Dentes triangulares na borda externa: passo 1,1 m (18 no arco), comprimento 0,35 m, apontando para fora | Preenchimento radial como hoje |
| `CRACKS` | `boss_slam` (r 8) | Passo 1,9 m (28 no círculo), comprimento 0,35 m | 7 rachaduras em zigue-zague do centro à borda, ângulos `i·TAU/7 + 0,31`, largura 0,12 m, escuras (`220410`, alfa 0,8) com fio aceso de `FF6A4D` de 0,03 m. Crescem do centro com o progresso e chegam à borda em 1,0: são o desenho antecipado do impacto |
| `CHEVRONS` | `boss_spikes` (22 por 3,6) | Três dentes triangulares no fim da linha, 0,6 m | Chevrons `>` apontando para a frente, passo 2,0 m, rolando para a frente a 4 m/s |
| `CROWN` | `boss_nova` (r 16) | Passo 2,1 m (48 no círculo), comprimento 0,6 m | 11 rachaduras (`i·TAU/11 + 0,17`) como as do slam. Três anéis finos que se contraem da borda ao centro, um a cada 0,8 s: o jogador vê o inverno "se juntar" |

Contra as runas: a zona da nova cobre os anéis de 16,24 e 16,74 m com vermelho. O ciano das runas continua legível por cima da faixa escura, e a serrilha em vermelho vivo fecha o círculo por fora de ambos.

**Marca de aliado (`hostile` falso).** Não muda: mesmo desenho, mesma cor, mesmo tamanho. Cor `skill.color`, sem faixa escura, sem serrilha, sem rachadura, sem os 0,4 m. Com `blend_premul_alpha` a conta de hoje se escreve `ALBEDO = tint · 1,1 · a` e `ALPHA = 0`, com `a = mask · (0,07 + fill · 0,16 + edge · (0,5 + wave · 0,3))` exatamente como o shader atual, o que reproduz o `blend_add` de hoje. `telegraph_style` não se aplica: habilidade de herói não tem `fx`.

### 4. Preparo

Começa no `cast_started` e acompanha `p = cast_progress` de 0 a 1. Termina no `skill_fired` (apaga em 0,4 s) ou no `cast_interrupted` (apaga em 0,2 s). A curva de brilho é `glow = base + (prep_peak - base) · p²`.

| Estilo | Quem | O que acende | Âncora | Extras |
|---|---|---|---|---|
| `BLADE` | strike, cleave | `blade_material.glow` de 1,5 até `prep_peak` | `weapon_tip` | Um brilho de ponta: sprite `SPARK` de 0,45 m na ponta, escala de 0,6 a 1,4. No cleave soma `prep_motes` partículas de `SPARK` de 0,16 m, saindo de uma esfera de 0,25 m, 0,6 a 1,4 m/s, vida 0,7 s, em `enemy_glow` clareado 0,4, com `amount_ratio = p` |
| `TIP_CRYSTALS` | spikes | `blade_material.glow` até 5,0 | `weapon_tip` | 3 lascas de cristal (`MeshKit.shard`, comprimentos 0,5, 0,4 e 0,35 m, raio 0,07 m) orbitando a ponta a 0,35 m de raio e 2,0 rad/s, com escala de 0 a 1 para `p` de 0,2 a 0,9. 30 partículas como no `BLADE` |
| `CORE` | slam | `core_material.glow` de 2,4 até 6,0 e `blade_material.glow` até 4,0 | `core` | Névoa no chão: emissor em anel de raio 2,4 m em volta do chefe, 36 partículas `SMOKE` pálidas (`E8F4FF`, alfa 0,25), subindo 0,5 m/s, vida 1,2 s, taxa proporcional a `p`. Luz `OmniLight3D` em `core`, cor do tema, energia de 0 a 1,2, alcance 9 m, sem sombra |
| `WINTER` | nova | `core_material.glow` de 2,4 até 7,0, `crown_material.glow` de 2,0 até 5,0 e `blade_material.glow` até 4,0 | `core` | Partículas convergindo: emissor em anel de raio 16 m, 80 partículas `SPARK` de 0,18 m, aceleração radial de -9 a -7 (rumo ao centro), vida 1,9 s. Luz em `core`, energia de 0 a 2,5, alcance 18 m, sem sombra. `prep_shake` a cada 0,5 s |

`glow` acima de 3,0 lava o cristal para branco-azulado: é o efeito desejado, mas só nos últimos 20% do preparo (a curva em `p²` já faz isso). O limite de 7,0 é o do chefe (seção 6 do guia).

### 5. Impacto

Começa em `skill_fired + impact_delay` e vive `impact_duration`. Material de lasca e estaca: `DungeonMaterials.crystal(glow.darkened(0,45), glow.lightened(0,35), 2,0)`, com `glow = Enemy.glow` ou `impact_color`. Cristal opaco e azul lê sobre a neve, que é onde o aditivo falha. Unidades em metros no mundo; `S` é `impact_scale`. Posição e direção vêm do `aim` e do `Events.skill_impacted`.

| Estilo | Forma | Números |
|---|---|---|
| `ARC` (strike) | Meia-lua horizontal aditiva a 2,0 m de altura, com as pontas finas. É o `Vfx.melee_arc` com parâmetros novos | Alcance 5,5, espessura 0,45 no meio, 100° de abertura centrados na mira, cor `enemy_glow` energia 1,6, alfa de 0,55 a 0 em 0,25 s. 8 lascas `FLAKE` de 0,12 m a 5 m/s |
| `SCYTHE` (cleave) | Foice de gelo rasteira: meia-lua achatada no chão (altura 0,2) que se expande de 1,5 a 9,0 m em 0,30 s (cúbica, saída suave) e depois some em 0,25 s | Abertura 120°, faixa de 1,2 m com as pontas finas em ±60°. Duas camadas: miolo aditivo `BFF4FF` e faixa de 1,6 m por baixo em mistura `1E4F86`, alfa 0,45, para ler sobre a neve. 5 estacas de cristal na borda, em -48°, -24°, 0°, 24° e 48° da mira, a 8,6 m, alturas de 1,4 a 2,0 m vezes `S`, inclinadas 0,25 rad para fora. Sobem em 0,10 s, seguram 0,30 s e afundam em 0,15 s. 24 partículas `FLAKE` e 12 `SMOKE` |
| `FRACTURE` (slam) | Rachaduras no chão, anel serrilhado, estacas e poeira | 7 rachaduras do centro a 8,4 m, ângulos `i·TAU/7 + 0,31`, linha quebrada de 6 segmentos com desvio lateral de até 0,35 m, largura de 0,22 m afinando para 0,05, escuras (`0A1626`, alfa 0,85) com fio aceso `enemy_glow` de 0,06 m por 0,4 s. Crescem do centro em 0,18 s, ficam e somem nos últimos 0,5 s de `impact_duration`. Anel: fita em zigue-zague (`MeshKit.extrude_path`, espessura 0,5 m, rotacionada para o chão) de 0,5 a 8,4 m em 0,38 s, aditiva, alfa de 0,45 a 0. 14 estacas, em raios de 2,0 a 7,4 m (nunca a menos de 1,8 m do centro, que é a cápsula), alturas de 0,9 a 2,2 m vezes `S`, inclinadas até 0,3 rad para fora, sobem em 0,10 s, seguram 0,55 s e afundam em 0,30 s. Poeira: 36 `SMOKE` (`E8F4FF`, alfa 0,5, vida 0,9 s) em anel e 20 `SPARK` |
| `STAKES` (spikes) | Duas fileiras de estacas ao longo da linha, em onda que vai do chefe ao fim | 11 estacas por fileira, a `1,5 + i·1,9` m do chefe, fileiras a ±0,9 m do eixo e a segunda deslocada 0,95 m ao longo da linha. Altura de 2,0 a 3,6 m (crescendo para o fim) vezes `S`, raio de base 0,28 m, inclinação de 0,12 rad para fora do eixo. Atraso de `i · 0,04 s` (onda a uns 47 m/s), sobem em 0,08 s, seguram 0,5 s e afundam em 0,22 s. 6 explosões de 8 partículas `FLAKE`, uma a cada duas estacas. O `line_wave` genérico (11 explosões) não roda |
| `CROWN` (nova) | `FRACTURE` com a escala da sala, mais uma coroa de estacas na borda. Sem cúpula | 11 rachaduras a 16,4 m (`i·TAU/11 + 0,17`), anel serrilhado até 16,4 m em 0,55 s (zigue-zague de 0,8 m), 20 estacas internas de 1,2 a 2,8 m. Coroa: 24 estacas num círculo de raio 15,0 m, alturas alternadas de 3,0 e 4,6 m vezes `S` (3,9 e 6,0 m), raio de base 0,45 m, inclinadas 0,22 rad para fora, atraso de `i · 0,02 s`, sobem em 0,14 s, seguram 0,8 s, afundam em 0,5 s. Névoa: 60 `SMOKE` baixas, subindo 0,5 m/s, vida 1,6 s. 40 `SPARK`. As runas, se reagirem (seção 8), vão de 0,55 a 2,0 de energia por 0,6 s |

Clarão: `OmniLight3D` na posição do centro do efeito (o chefe nos de área em volta dele, o meio do alcance no cone e na linha) a 1,0 m de altura, cor `enemy_glow` clareada 0,35, energia `flash_energy`, sem sombra, apagando em 0,3 s (0,10 s no strike, 0,45 s na nova). Alcance, constante por estilo em `AttackFx`: strike 8 m, cleave 10, slam 12, spikes 18, nova 28.

Tremor: `trauma = shake_strength · clamp(1 - (d - 0,35·R) / (0,65·R), 0, 1)`, com `d` a distância horizontal do jogador ao chefe e `R = shake_radius`. A função é `SkillFxData.shake_trauma`, chamada pelo `CombatFeedback` ao receber `camera_shake_requested`, no instante do impacto, quer o jogador tenha sido atingido ou não. Soma com o tremor de dano que já existe, e o total trava em 1,0 (`add_trauma` já faz isso). Valores resultantes, para os testes:

| `d` (m) | strike | cleave | slam | spikes | nova |
|---|---|---|---|---|---|
| 5 | 0,18 | 0,35 | 0,65 | 0,40 | 0,90 |
| 10 | 0,05 | 0,20 | 0,55 | 0,38 | 0,90 |
| 20 | 0 | 0 | 0,09 | 0,14 | 0,57 |
| 30 | 0 | 0 | 0 | 0 | 0,16 |

### 6. Orçamento de custo

Vale para a soma do preparo mais o impacto. O chefe só conjura uma habilidade por vez, mas o fim de uma (rachaduras, estacas afundando) pode sobrepor o início da próxima: o teto cobre duas sobrepostas.

| Efeito | Partículas no pico | Luzes | Malhas de efeito |
|---|---|---|---|
| strike | 8 | 1 (0,10 s) | 1 arco, 1 brilho de ponta |
| cleave | 24 de preparo + 36 de impacto | 1 | 1 foice, 1 faixa, 5 estacas |
| slam | 36 de preparo + 56 de impacto | 1 de preparo + 1 de clarão | 7 rachaduras, 1 anel, 14 estacas |
| spikes | 30 de preparo + 48 de impacto | 1 de clarão | 3 lascas de preparo, 22 estacas |
| nova | 80 de preparo + 100 de impacto | 1 de preparo + 1 de clarão | 11 rachaduras, 1 anel, 20 estacas, 24 da coroa |

Tetos globais do chefe: 160 partículas vivas, 2 luzes, 64 malhas de efeito. Nenhuma camada translúcida do impacto ocupa mais de 25% da tela no pico (a zona de telegrafia, que é piso, está fora desta conta). Peças de efeito liberadas com `queue_free` ao fim da vida, nunca acumuladas. Meça `Vfx.enabled()` primeiro: sem janela, nada é criado.

### 7. Testes da parte B

Sem janela, o que dá para testar é cálculo: curva de brilho em `p` de 0, 0,5 e 1 (valor de `blade_material.glow` e `core_material.glow` por habilidade), tabela de tremor da seção 5, `impact_delay`, contagens da seção 6 por estilo, e a seleção de ligação: `AttackFx` só nasce em inimigo com habilidade com `fx`. A leitura do shader (`blend_premul_alpha`, ausência de `blend_add`) é teste de texto. O desenho conferido em render é a seção de critérios.

### 8. Opcional

`DungeonProps` pode guardar o material das runas e o `AttackFx` pode pulsá-lo (energia de 0,55 a 2,0 por 0,6 s) no impacto da nova e em cada `prep_shake`. É leitura extra de "o poder do rei", sem custo de luz. Só entra se a captura `nova_prep` mostrar as runas sumindo sob a zona vermelha.

## Mudança no guia

Aprovadas em 08/11/2026 e aplicadas em `style_guide.md` (seções 6, 6.1, 11 e 13). A N1 virou as regras Z1 a Z3, com a correção abaixo:

| # | Regra | Texto proposto | Motivo |
|---|---|---|---|
| N1 | Nova seção 6.1, "Telegrafia" | "A zona de perigo de todo inimigo, em todo tema, é vermelha: preenchimento `A01030` por mistura, faixa escura `220410` e borda acesa `FF6A4D` por soma. Nunca só aditivo: a neve mede L* 54 a 75 e some. O desenho cobre a área lógica mais o raio do alvo (0,4 m). Serrilha e rachadura são os adornos permitidos. **A marca de área de aliado (`m_meteor`, `p_judgement`) continua na cor da habilidade, só aditiva, sem faixa escura, sem serrilha e no tamanho de hoje.**" | Hoje a cor vem da habilidade e quatro das cinco do chefe são azul sobre neve |
| N2 | Seção 6, tabela | Nova linha "Efeito de ataque de inimigo": forma pontuda (estaca, rachadura, serrilha, lasca); cor `enemy_glow` do tema; sem cúpula e sem tela cheia | Estende a linguagem de brilho aos efeitos, que ela não cobre |
| N3 | Seção 6, linha "Energia" | "Cristal do chefe: `glow` 2,4 em repouso e até 7,0 nos últimos 20% do preparo" | A regra de 7,0 vale para `Look.glow`; o cristal tem o parâmetro dele |
| N4 | Seção 11, nova regra C4 | "Efeitos do chefe: até 160 partículas vivas, 2 luzes e 64 malhas, sem camada translúcida acima de 25% da tela. Sem sombra." | O orçamento do guia só fala de personagem |
| N5 | Seção 13 | Uma linha de 08/11/2026 com as decisões acima | Registro |

## Critérios de aceite

Os renders vêm do `tests/visual/tour.gd` com um modo novo, `--boss_fx`, que depois do engajamento ancora o jogador a 7 m do chefe, invulnerável e mirando nele, e dispara por `caster.try_cast` cada habilidade em sequência (`strike`, `cleave`, `slam`, `spikes`, `nova`). Para cada uma grava em `OUT/boss_fx/`: `<skill>_pre.png` (antes do cast), `<skill>_prep.png` (a 85% do cast), `<skill>_hit.png` (0,12 s depois do disparo) e, para slam, spikes e nova, `<skill>_after.png` (0,7 s depois). A captura `32_boss_telegraph` do tour atual continua e é refeita.

Definições, sobre os valores de 0 a 255 do PNG, como na OS-018: **quente** é `R > B + 10` e `R >= 100`; **azul** é `B >= R + 40` e `B >= 140`; **saturado** é `min(R,G,B) >= 250`. Metade de baixo é a faixa y de 540 a 1080 em 1080p.

| # | Verificação | Onde | Alvo |
|---|---|---|---|
| 1 | Dados | Testes da parte A | Seção 3 |
| 2 | Zona lê sobre a neve | `<skill>_pre` e `<skill>_prep`, de cleave, slam, nova | Fração de pixels quentes da metade de baixo sobe 4 pontos percentuais ou mais de `_pre` para `_prep`. Spikes, que é uma linha, 2 pontos |
| 3 | Zona e runas | `nova_prep.png`, `32_boss_telegraph.png` | A borda vermelha da nova se vê inteira sobre as runas de `9FE3FF`. As runas continuam visíveis em ciano na parte de fora da zona |
| 4 | Desenho cobre o acerto | Teste | Para cleave, slam, spikes e nova, o semitamanho do `QuadMesh` é de raio + 0,4 + dente ou mais. Um alvo de raio 0,4 no limite do acerto está dentro do desenho |
| 5 | Shader | Teste de texto | `blend_premul_alpha` presente e `blend_add` ausente |
| 6 | Sinal do preparo | `<skill>_prep.png` | Lâmina (strike, cleave, spikes) ou núcleo (slam, nova) claramente mais claros que no `_pre`, sem perder o azul. A nova mostra as partículas convergindo e a luz fria no chefe |
| 7 | Âncora | `<skill>_prep.png` | O sinal sai da ponta da lâmina (strike, cleave, spikes) ou do peito (slam, nova), e não de um ponto flutuando |
| 8 | Impacto pontudo | `<skill>_hit.png` | Estacas, rachaduras e lascas legíveis. Nenhuma forma redonda grande e nenhuma cúpula. Em `slam_hit` há 7 rachaduras e nenhum par a 90° |
| 9 | Impacto sobre a neve | `slam_hit`, `spikes_hit`, `nova_hit` | Pixels azuis na metade de baixo: 2% ou mais |
| 10 | Sem estouro | Todas `_hit.png` | Pixels saturados: 3% ou menos da imagem |
| 11 | Restos | `slam_after`, `nova_after`, `spikes_after` | Rachaduras ainda visíveis em `slam_after` e `nova_after`. Estacas ainda de pé em `spikes_after` e `nova_after` |
| 12 | Tremor | Teste | A tabela de `d` da seção 5, com tolerância de 0,01, por `SkillFxData.shake_trauma`. O `AttackFx` só emite `camera_shake_requested(origin, strength, radius)` (impacto depois de `impact_delay`, e a cada 0,5 s do preparo na nova) e não referencia o jogador. O `CombatFeedback`, com um jogador de teste a `d` m de `origin`, chama `add_trauma` com o valor da tabela. Soma com o de dano e trava em 1,0 |
| 13 | Orçamento | Teste | Contagens por estilo iguais à tabela da seção 6, e os tetos globais |
| 14 | Custo | Saída do tour (`média`, `p95`, `p99`) | `p95` do tour completo, com o chefe em combate, até 1,5 ms acima do mesmo tour sem a OS-022 |
| 15 | Regressão | Suítes | `check_scripts`, `unit_tests`, `flow_test` e os 3 `playthrough` sem falhas. Heróis sem mudança de efeito, inclusive a marca de área. Monstros comuns sem mudança, salvo a zona de perigo do `mon_smash`, que agora é vermelha como a do chefe |
| 16 | Cor do tema | Teste | Com `enemy_glow` de fogo (`FF7A2E`), as lascas e as partículas saem laranja, e a zona continua vermelha |
| 17 | Marca de aliado | Teste de parâmetro e render | `m_meteor` e `p_judgement`, lançados por conjurador de `Team.PARTY`, criam a marca com `hostile == false`, `tint == skill.color`, sem faixa escura nem serrilha, com o mesmo tamanho de hoje (raio `skill.radius`, sem os 0,4 m). O shader com `hostile == false` dá `ALBEDO` e `ALPHA` iguais aos de hoje em 8 pontos de comparação (função de referência em GDScript com a fórmula do shader atual). Num render com o meteoro, a marca fica igual à de antes da ordem: aditiva, na cor da habilidade |

## Revisão 1 (08/11/2026): REPROVADO, dois ajustes de partícula

Revisão da parte B sobre `documents/art/review/boss_fx_os022/` (36 PNG). Os critérios numéricos que o `gameplay-developer` mediu (2, 9, 10, 12, 13, 14, 16 e 17) estão aceitos e não foram refeitos. A maior parte do conjunto passa: a zona vermelha lê muito bem sobre a neve e a pedra, as estacas, o anel serrilhado e a coroa de estacas têm a linguagem pontuda que a ordem pede, e o sinal sai da ponta da lâmina e do peito. Dois pontos falham, os dois por partícula.

### Veredito dos critérios visuais

| # | Veredito | O que vi |
|---|---|---|
| 3 | **APROVADO** | `nova_prep`: piso todo vermelho, com os anéis laranja se contraindo. `nova_wide_prep` (22 m): borda serrilhada, faixa escura e as runas em ciano legíveis dentro e fora da zona, sem sumir sob o vermelho. A seção 8 (runas reagindo) continua desnecessária. `32_boss_telegraph`: o cone lê pela cor e pelo valor, e a serrilha fecha a borda |
| 6 | **REPROVADO**, só a nova | Strike, cleave, spikes e slam: lâmina ou núcleo claramente mais claros que no `_pre`, sem perder o azul. A nova: núcleo aceso e luz no chefe, mas as 80 partículas que deviam convergir não se leem. Em `nova_prep` quase não há ponto claro em cena, e em `nova_wide_prep` são grãos de 5 a 8 px sobre o vermelho. Quem carrega a leitura são os anéis do shader. Ver ajuste 2 |
| 7 | **APROVADO** | Em `cleave_wide_prep` e `spikes_wide_prep` o sinal (brilho de ponta, partículas, as 3 lascas do spikes) está na ponta da lâmina. Em `slam_prep` e `nova_prep` o foco é o peito. No `strike_prep` e no `cleave_prep` a ponta sai do quadro, porque o preparo ergue a lâmina: é a pose, não o efeito. O `strike` usa o mesmo caminho do `cleave`, então aceito sem captura a 14 m, mas peço uma na próxima rodada de capturas |
| 8 | **REPROVADO** | Estacas, rachaduras com fio aceso, lascas e a foice rasteira leem pontudas, sem cúpula. O arco do strike é uma faixa de pontas finas. O anel serrilhado do slam e o de rachaduras funcionam. A falha é a poeira: em `slam_hit`, `slam_after`, `nova_hit` e `cleave_wide_hit` as partículas `SMOKE` formam nuvens brancas e redondas de 2 a 4 m, que cobrem o lado do quadro e parecem algodão de desenho animado. É a maior forma de cada quadro e contradiz o critério "nenhuma forma redonda grande". Falha minha: a ordem não fixou o tamanho do sprite de `SMOKE` e dizia só "pequena". Ver ajuste 1 |
| 11 | **APROVADO** | `spikes_after` e `spikes_wide_after`: as estacas ainda de pé, em corredor. `nova_after` (7 m): a coroa de estacas de pé em volta, e confirmei as rachaduras: no recorte do piso, comparado com `nova_pre`, aparecem faixas escuras largas partindo dos pés do chefe, que não existem no `_pre`. `slam_after` (7 m): as rachaduras escuras seguem no piso. A 14 m, em `slam_wide_after`, só sobra uma rachadura visível, o que fica aceito (o critério vale a 7 m) |

### Desvios do implementador: decisões

| # | Desvio | Decisão |
|---|---|---|
| 1 | Rachaduras mais largas e fio mais forte | **Aceito.** Os valores da ordem somem no piso de gelo rachado a 7 e 14 m (vi nas capturas). Os números novos viram o texto da ordem, na lista de ajuste 3. Continuam em número ímpar (7 e 11), sem par a 90° |
| 2 | Estacas internas da nova sem `impact_scale` (1,2 a 2,8 m) | **Aceito, e não é desvio:** a ordem diz "20 estacas internas de 1,2 a 2,8 m", sem `S`. Só a coroa usa 1,3 |
| 3 | Emissores do preparo apagam 0,15 s depois do disparo | **Aceito.** O teto de 160 partículas vivas manda. O brilho dos cristais segue em 0,4 s, como na ordem |
| 4 | Quadro da zona de linha cobre 0,4 m atrás e nos lados, dentes por fora | **Aceito.** É o que a regra Z3 pede: o acerto soma o raio do alvo atrás da origem também |
| 5 | Runas da seção 8 de fora | **Aceito.** `nova_wide_prep` mostra as runas legíveis, que era a condição para dispensar |
| 6 | Arquivos extras (`impact_plan.gd`, `boss_impact.gd`, `emitter_spec.gd`) | Decisão de código, sem objeção de arte |

### Ajustes

1. **Poeira (critério 8).** Todas as partículas `SMOKE` do chefe (a névoa de preparo do slam, a poeira do slam, do cleave e da nova, a névoa da nova):
   - sprite de 0,9 m na criação, com `scale_curve` de 0,8 a 1,4, ou seja, de 0,72 a 1,26 m. Nenhuma passa de 1,3 m;
   - alfa de pico 0,30 (hoje 0,5), cor `E8F4FF` como está;
   - as contagens da tabela de orçamento ficam (36, 12, 36 e 60).
   A ideia é que a névoa vire um véu baixo que deixa ver o chão e as rachaduras, e não uma bola.
2. **Convergência da nova (critério 6).** As 80 partículas `SPARK` do `WINTER`: sprite de 0,18 m para **0,40 m**, cor `enemy_glow` clareada 0,5, energia 1,4 (aditiva), com a velocidade e a vida iguais. Sem mudar a contagem. Em `nova_wide_prep` as fileiras de pontos têm de apontar para o chefe e ler a 22 m.
3. **Texto da ordem alinhado ao código** (nenhuma mudança de comportamento): rachadura do chão de 0,34 a 0,10 m de largura (a seção 5 dizia 0,22 a 0,05), fio aceso de 0,10 m com energia 1,6 (era 0,06), e no shader da zona a meia-largura da rachadura é 0,09 m e o fio 0,025 m (eram 0,06 e 0,015). Vale este ajuste onde a seção 5 e a seção 3 divergirem.

### Critérios de reaceite

Refazer só estas capturas, na mesma rodada do `--boss_fx`: `slam_hit`, `slam_after`, `slam_wide_hit`, `nova_prep`, `nova_wide_prep`, `nova_hit`, `nova_wide_hit` e `cleave_wide_hit`. Mais `strike_wide_prep` (14 m), que não existia.

| # | Verificação | Alvo |
|---|---|---|
| R1 | Poeira | Em `slam_hit.png`, `nova_hit.png` e `cleave_wide_hit.png`, nenhuma região de poeira com pixels de `min(R,G,B) >= 170`, fora do HUD, com mais de 200 px de largura, a 7 m. As rachaduras e as estacas aparecem sem ficar atrás de nuvem |
| R2 | Convergência | `nova_wide_prep.png`: pontos claros em fileira rumo ao chefe, legíveis entre a borda da zona e o chefe |
| R3 | O que não pode mudar | As medidas 2, 9, 10, 12, 13, 14, 16 e 17 seguem como o implementador as mediu. O custo (critério 14) tem de ficar igual ou menor, já que as partículas não mudam de número |
| R4 | Ponta | `strike_wide_prep.png`: o brilho de ponta aparece na ponta da lâmina |

Depois de aplicada, a conferência é só de arte, nessas capturas, e `unit_tests`.

### Observação fora desta ordem: rampa do trono

Sem ordem própria. Renders em `documents/art/review/trono_rampa/`. O tronco de cone de 0,75 m lê como um tablado baixo e escuro sobre a neve, com bom contraste em todas as vistas e a pedra do piso contínua pela encosta. Dois traços, os dois opcionais: de lado, a silhueta mostra os 24 lados (`RampPlatform.SIDES` para 32 resolve, e colisão e navmesh seguem o mesmo valor), e a rampa perde o degrau que dava monumentalidade ao trono. Se um dia quiserem recuperar isso, a alavanca é um aro dourado `D8B464` de 4 cm de altura na borda do topo (raio 5,0), sem mexer na rampa.

## Revisão 2 (08/11/2026): REPROVADO, só a convergência da nova

Reaceite da Revisão 1 sobre as 9 capturas refeitas em `documents/art/review/boss_fx_os022/`. A poeira, o brilho de ponta do strike e as medições passam. A convergência da nova, não.

| # | Veredito | O que vi |
|---|---|---|
| R1 | **APROVADO** | `slam_hit`: a poeira virou um véu fino, em fiapos baixos junto aos pés do chefe e nas laterais, e as rachaduras e a estaca voltaram a ser o que domina o quadro. `nova_hit` e `cleave_wide_hit`: sem nuvem redonda. `slam_after`: a névoa ainda cobre uma faixa de 3 m de cada lado, mas translúcida e sem borda dura, e as rachaduras seguem legíveis. Medição do implementador (112, 28 e 32 px contra o teto de 200) aceita |
| R2 | **REPROVADO** | Em `nova_prep` (7 m) há dois pontos de brilho em todo o quadro. Em `nova_wide_prep` (22 m) ampliei a zona 2 vezes: sobram uns 6 grãos de 3 a 5 px sobre o vermelho, sem fila e sem direção. O implementador mediu 14 pontos novos de uns 12 px, e eu não os separo do piso. Aditivo claro sobre o vermelho vivo da zona se perde, e uma bolinha mole não tem a forma de inimigo |
| R3 | **APROVADO** | Medições de 2, 9 e 10 aceitas sem refazer |
| R4 | **APROVADO** | `strike_wide_prep`: a lâmina erguida lê clara e o brilho de ponta aparece como um ponto com estrela na ponta. Pequeno a 14 m, mas está na ponta |

### Decisões nos dois desvios

1. **Poeira espalhada em 12 grupos de 3 (slam) e 20 de 3 (nova), raio de 1,0 m, 0,02 s de atraso por grupo, `explosiveness` 0,5: aceito.** Mesmas contagens, e o resultado é o véu que a ordem pedia. Os números entram no texto da ordem.
2. **Convergência em fileiras, uma por raio: aceito o princípio, rejeitado o desenho.**
   - Fileiras ao longo de raios lêem melhor que grãos espalhados no anel, e as constantes `AttackFx.CONVERGENCE_*` (4 m/s de velocidade inicial e 3 m/s² de aceleração) ficam.
   - Oito raios fazem 4 pares a 180°, e cada par vira uma linha reta pelo centro: dois pares a 90° desenham um "+" no chão (O2), o mesmo motivo pelo qual as rachaduras são 7 e 11.
   - O elemento que vai e vem tem de ser pontudo e opaco, como as estacas, e não ponto de luz.

### Ajuste (Revisão 2)

A convergência do `WINTER` deixa de ser partícula e passa a ser **lasca de gelo deitada**, no mesmo material de cristal das estacas.

| Item | Valor |
|---|---|
| Raios | **7**, ângulos `i·TAU/7 + 0,29`, sobre o chefe. Nada de 8 |
| Lascas | 4 por raio nos raios 0 a 5 e 3 no raio 6, 27 no total. Com o atraso de 0,07 s entre raios, a quarta lasca do raio 6 nasceria em 2,445 s, depois do disparo em 2,4 s (correção da sessão principal em 08/11, a cadência não muda). `MeshKit.shard(0,07, 1,1, rng, 4, 0)` deitada a 0,30 m do piso, com a ponta virada para o chefe |
| Material | O de cristal das estacas, `DungeonMaterials.crystal(glow.darkened(0,45), glow.lightened(0,35), 3,0)`. O `glow` de 3,0 (e não 2,0) é para a lasca ler sobre o vermelho |
| Trajeto | Nasce a 15,5 m do chefe e anda para dentro com `r(t) = 15,5 - (4,0·t + 0,5·3,0·t²)`, as constantes que o código já tem. Vida de 1,9 s, chega a uns 2,5 m |
| Cadência | Uma lasca nova por raio a cada 0,475 s, entre 25% e 100% do preparo, com 0,07 s de atraso entre um raio e o próximo |
| Escala | De 0 a 1 nos primeiros 0,15 s e de 1 a 0 nos últimos 0,25 s |
| Fim | **Todas somem no `skill_fired`**, sem esperar o fim da vida. Assim as 27 malhas do preparo nunca somam com as 56 do impacto, e o teto de 64 malhas vale |
| Partículas | Saem as 80 partículas do `WINTER`. `boss_nova.prep_motes` passa de 80 para 27, e para o `WINTER` o campo conta lascas, não partículas. A tabela do critério 13 e o teste da parte A trocam 80 por 27 |
| Orçamento | A nova no preparo: 0 partículas, 1 luz, 27 malhas. O pico de partículas vivas da nova cai de 132 para uns 52 |

As três linhas dos anéis que se contraem (seção 3, estilo `CROWN`) ficam como estão.

### Critérios de reaceite

Refazer só `nova_prep.png` e `nova_wide_prep.png`.

| # | Verificação | Alvo |
|---|---|---|
| R5 | Convergência | `nova_wide_prep.png`: pelo menos 8 lascas distintas, pontudas, apontando para o chefe, legíveis a 22 m sobre o vermelho da zona. `nova_prep.png`: pelo menos 3, de formas inteiras, fora do viewmodel |
| R6 | Contagens | Teste: no pico do preparo da nova, 27 lascas e 0 partículas de convergência. No `skill_fired`, 0 lascas |
| R7 | O que não pode mudar | As outras capturas e as medições de custo seguem como estão. O custo deve ficar igual ou menor |

Depois de aplicada, a conferência é só de arte, nessas duas capturas, e `unit_tests`.

### Fechamento da Revisão 2 (08/11/2026): R5 aprovado a 22 m, com `TILT = 0,45`

Comparei as quatro capturas de `nova_prep` e `nova_wide_prep`, deitada e inclinada, mais uma ampliação de 2 vezes do interior da zona a 22 m. A contagem de 27 lascas (a quarta lasca do raio 6 nasceria em 2,445 s, depois do disparo) está certa.

- **Deitada (`TILT = 0`, o que o código tem):** a 22 m sobram quatro ou cinco manchas claras e achatadas, que leem como pedrinhas brancas. Pouca direção e nenhuma ponta.
- **Inclinada (`TILT = 0,45`, uns 26° com a ponta para cima):** três agulhas bem nítidas em fila rumo ao chefe e mais uma dezena de agulhas finas, em ciano, ao longo da borda da zona, contra a pedra escura. Lê pontudo e com direção, que era o que a ordem pedia. Não muda a contagem nem o custo.
- **A 7 m, nas duas versões:** nenhuma lasca reconhecível. É geométrico: no momento de 85% do preparo as lascas mais velhas já passaram de 6,6 m do chefe, ou seja, estão atrás da câmera ou do outro lado dele, e de uma câmera a 1,6 m do chão uma lasca baixa vira um traço de 1 a 2 px. Considero o R5 não aplicável a 7 m. A leitura do preparo da nova a essa distância vem da zona vermelha, dos anéis, do núcleo aceso e da luz no chefe, e isso já foi aprovado no critério 3. Não pedi correção barata, porque nenhuma muda o ponto de vista do jogador.

**Mudança que falta, uma constante:** `ConvergenceShards.TILT` de `0` para **`0,45`**. Sem nova rodada de arte: o `nova_wide_prep_inclinada.png` já é a prova, e basta `unit_tests`.

## Resultado

**APROVADA em 08/11/2026**, com a constante `ConvergenceShards.TILT = 0,45` a aplicar (única pendência, sem reaceite de arte).

- Critérios 3, 6 (nova incluída, pela Revisão 2), 7, 8 e 11 aprovados, mais R1 a R4 da Revisão 1 e R5 a R7 da Revisão 2, com o R5 a 22 m e não aplicável a 7 m.
- Medições do implementador (2, 9, 10, 12, 13, 14, 16 e 17) aceitas. Custo dentro do ruído (+0,3 ms de média no tour).
- Desvios 1 a 6 da Revisão 1: aceitos. A poeira espalhada em grupos de 3 e a convergência em fileiras, esta refeita em lasca e em sete raios, estão decididas.
- Rampa do trono: leitura boa, sem ordem própria (`review/trono_rampa/`).
- Guia: as propostas N1 a N5 já estão aplicadas em `style_guide.md`, e nada novo pede mudança nele.
