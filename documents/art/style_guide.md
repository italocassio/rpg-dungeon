# Guia de estilo de Caçadores de Portais

Versão 1.0, 31/10/2026. É o padrão de toda arte do jogo. Cada regra tem um código e pode ser conferida num render. Para mudar uma regra, altere este arquivo e registre o motivo na seção 13. Nenhum asset diverge em silêncio.

Os números de T0 vieram de testes no motor, na Iris Xe de referência, com o blockout em `concepts/blockout/`. T1 a T3, encaixes de raridade e o viewmodel de orbe e tomo ainda não rodaram no motor. A verificação usa a ferramenta da OS-001. Quando o blockout e uma ficha de classe divergirem, vale a ficha.

## 1. Pilares

1. **A forma fala primeiro.** A classe se lê na silhueta preta. Cor e brilho só confirmam.
2. **Dois valores em cada corpo.** Todo herói tem uma massa clara e uma escura, então sempre uma delas contrasta com o fundo.
3. **Caçador é quente e redondo, Portão é frio e pontudo.** Herói tem bronze, couro, pano e luz circular. Criatura do Portão tem estilhaço, olho aceso e cor de contaminação.
4. **Você veste o que caçou.** O equipamento conta a caçada: pele do lobo, ouro do rei. Evoluir muda a forma, não pinta o boneco.
5. **Acabamento limpo.** Personagem não leva textura de sujeira. Placa é facetada, pano é liso, e o detalhe vem da forma.

## 2. Origem das referências

O clima vem de MMOs orientais clássicos e de fantasia de caçadores. Só o clima.

- **O1.** Nenhum nome, personagem, emblema ou design de Perfect World ou Solo Leveling. Na dúvida, é proibido.
- **O2.** Nenhum símbolo religioso real: cruz, mitra, casula, crescente, estrela de Davi, om, roda do dharma, torii, yin-yang. A fé do jogo é a Vigília, ficcional, e seu único símbolo é a lanterna acesa. Vale para modelo, arma e ícone de UI, de classe, de habilidade ou de item. Cruz é qualquer travessa em ângulo reto sobre uma haste: a latina, a grega (o "+" de braços iguais) e a cruz dentro de aro. Espada com guarda e machado são objetos reconhecíveis e ficam fora da regra.
- **O3.** A assinatura do jogo é o Selo de Caçador: um aro de bronze com um disco de luz.

## 3. Escala e distâncias reais

Herói mede cerca de 1,90 m sem peça alta. Cabeça de 0,25 m, proporção de 7,5 cabeças. A frente do modelo é **-Z**, a mão direita fica em **+X**.

| Onde o herói é visto | Câmera | px por metro em 1080p | Herói | O que conta |
|---|---|---|---|---|
| Saguão | 3,7 m, FOV 52 | 299 | 570 px | Rosto, materiais |
| Aliado perto | 5 m, FOV 78 | 133 | 240 px | Peças grandes, Selo |
| Aliado médio | 10 m, FOV 78 | 67 | 120 px | Massas e cor |
| Aliado longe | 20 m, FOV 78 | 33 | 60 px | Só silhueta e Selo |
| Primeira pessoa | Câmera, FOV 74 | Peça a peça | Mãos, arma | Mão, manga, arma |

- **E1.** Peça com menos de 9 cm (3 px a 20 m) não conta como silhueta. Serve de detalhe.
- **E2.** A cabeça, sem coroa, chifre e cristal de cabeça (S3), nunca passa de 1/7 da altura do corpo. Vale para herói e chefe. Nada de proporção infantil.
- **E3.** O aliado costuma ser visto de costas, porque luta virado para o monstro. A vista traseira vale tanto quanto a frontal.

## 4. Silhueta

| Classe | Letra | Largura em T0 | Altura em T0 | Traço que nenhuma outra tem |
|---|---|---|---|---|
| Guerreiro | **T** | 0,99 m nos ombros | 2,05 m | Ombreiras e escudo |
| Mago | **Y** | 0,60 m na gola | 2,40 m | Gola em duas asas e haste alta |
| Sacerdote | **A** | 0,90 m na aba | 2,15 m | Disco do chapéu e sino da saia |

- **S1.** Em preto, as três classes se distinguem de frente, de perfil e de costas, a 20 m e a 60 px.
- **S2.** A classe se lê sem a arma. Machado, orbe e tomo não podem apagar a letra.
- **S3.** Formas reservadas a inimigos: capuz, chifre lateral, espinho de gelo, estilhaço emissivo. Herói não usa nenhuma delas. Chifre e espinho são os de cabeça e de corpo, em cristal, osso ou gelo. A lâmina de aço mate sobre a ombreira, que a ficha do guerreiro T3 pede, é peça de armadura e não entra na proibição, desde que não emita luz (B2).
- **S4.** Herói e inimigo não compartilham função de modelo nem arma. `robed_body`, `hood`, `armored_body`, `cape` e as armas de `enemy_parts.gd` ficam só com os inimigos. `CreatureRig.biped_skeleton` e `CreatureRig.limb` são utilitários sem aparência e valem para os dois.
- **S5.** Tier nenhum pode quebrar a letra da classe. T3 só reforça a forma.

## 5. Valor e cor

Valores medidos no render, em L* (0 preto, 100 branco):

| Fundo | L* |
|---|---|
| Parede | 5 a 20 |
| Coluna | 9 |
| Gelo em sombra | 22 a 49 |
| Neve | 54 a 75 |

A câmera em primeira pessoa fica a 1,70 m. Por isso os pés de um aliado sempre caem sobre o piso, e cabeça e ombros sobre a parede. Essa geometria dita a regra V1.

- **V1. Claro em cima, escuro embaixo.** No render padrão, frente e costas, na máscara do herói:
  - Zona alta (acima de 1,25 m): percentil 90 de L* ≥ 45.
  - Zona baixa (abaixo de 0,90 m): percentil 10 de L* ≤ 20.

| Modelo | Alto p90 (frente/costas) | Baixo p10 (frente/costas) | V1 |
|---|---|---|---|
| Guerreiro atual | 29 / 31 | 0 / 2 | Reprova |
| Mago atual | 40 / 35 | 7 / 6 | Reprova |
| Sacerdote atual | 69 / 67 | 41 / 38 | Reprova |
| Guerreiro blockout | 63 / 63 | 4 / 0 | Aprova |
| Mago blockout | 75 / 73 | 1 / 6 | Aprova |
| Sacerdote blockout | 84 / 84 | 16 / 16 | Aprova |

Medido com as OS-002 e OS-003 aplicadas nos dois casos.

- **V2. A massa é da classe.** A cor das massas nunca muda com tier nem com masmorra.
- **V3. A cor de classe é assinatura, não massa.** `E0603A`, `4F8DFF` e `FFD76A` entram exatos no Selo e num detalhe de pano. O mago azul sobre cenário azul foi justamente o erro da versão atual.
- **V4. Matiz medido na sala.** A sala desloca toda cor para o azul e apaga as escuras, então hex na ficha não prova nada. Na sala de referência, em média linear, a massa de cor fica a até 15° do alvo, com V ≥ 0,15. A OS-001 mede isso.

| Massa | Alvo | Primeira escolha, sem luz de personagem | Final, com luz de personagem |
|---|---|---|---|
| Casaco do mago, costas | H 280 | `5A2378`: H 246, V 0,17. Lê azul | `6E2470`: H 279, V 0,25 |
| Saia do sacerdote | H 165 | `1F5E52`: H 196, V 0,09. Lê preto-azulado | `247050`: H 164, V 0,22 |
| Capa do guerreiro, costas | H 0 | `9A2A1F`: H 354, V 0,15. Lê quase preto | `B3301F`: H 356, V 0,42 |

No saguão, com luz quente, as mesmas massas ficam mais vivas e o casaco puxa para o magenta. É esperado: a masmorra manda.
- **V5. Limites de albedo.** L* entre 10 e 88 nas massas. Metal de tier e pele branca são pontuação e podem chegar a L* 96: platina `E6ECF5` (L* 93) e pele `EEF1F6` (L* 95). Nada de branco ou preto puros. Olho, boca e visor são exceção.
- **V6. Uma massa saturada por modelo.** Metal e cor de classe são pontuação.

### Masmorras futuras

A paleta dos heróis não muda por tema. O que muda é `enemy_glow`, e a regra V1 é medida de novo em cada masmorra.

| Tema | Fundo esperado | `enemy_glow` | Quem sofre | O que sustenta |
|---|---|---|---|---|
| Gelo (atual) | Parede escura, neve clara | `7FE0FF` | Ninguém | V1 aprovada |
| Fogo | Parede preta, piso escuro com fendas | `FF7A2E` | Guerreiro perde matiz e Selo fica perto do inimigo | Forma T, aço claro, Selo redondo |
| Pântano | Verde-escuro, musgo | `A8FF5A` | Sacerdote perde o jade | Chapéu e creme |
| Deserto | Ocre, areia clara | `FFC94A` | Lanterna fica perto do inimigo | Forma redonda da luz |
| Abismo | Violeta-preto | `E05AFF` | Mago perde o ameixa | Capa e gola claras |

**Pendência conhecida:** em piso escuro, a zona baixa do mago tem p90 de apenas 11 de costas. Na primeira masmorra de piso escuro, meça isso e, se a aba do casaco sumir, aumente o `rim` dos materiais escuros.

## 6. Linguagem de brilho

Aliado e inimigo se separam por **forma e lugar**, porque matiz sozinho não basta: o Selo do mago (219°) e o olho inimigo (194°) ficam a 25° de distância.

| | Aliado | Inimigo |
|---|---|---|
| Forma | Redonda: aro, disco, núcleo oval, lanterna | Pontuda: olho em ponto, estilhaço, fenda |
| Lugar | Peito, costas e cabeça da arma | Olhos, núcleo e rachaduras do corpo |
| Cor | Cor de classe; núcleo do mago `8A7BFF` | `enemy_glow` do tema |
| Energia | 0,9 a 1,0 | 4,0 nos olhos, até 7,0 no chefe. Cristal do chefe: `glow` 2,4 em repouso e até 7,0 nos últimos 20% do preparo |
| Efeito de ataque | Cor da habilidade (marca de área, seção 6.1) | Forma pontuda (estaca, rachadura, serrilha, lasca), cor `enemy_glow` do tema, sem cúpula e sem tela cheia |

- **B1.** Olho de herói nunca emite. Olho é `1A1410` fosco, sem luz de personagem. Máscara de T3 também não brilha.
- **B2.** Herói nunca emite em estilhaço. Ponta de metal fosco é permitida.
- **B3.** Todo herói carrega o Selo na frente e nas costas.
- **B4.** Energia de herói fica entre 0,9 e 1,0. Em 1,4 o Selo já lava para branco, e em 2,0 a 3,0 o orbe e a luz do tomo viram um disco branco no viewmodel.
- **B5.** Todo olho de inimigo usa `enemy_glow`. Isso inclui o goblin `ffd24a`, que hoje fica perto do ouro do sacerdote, e o esqueleto `6cc2ff`.
- **B6.** Peça de herói feita de monstro é pálida e fosca. Nada de gelo emissivo em armadura de herói.
- **B7.** Luz de personagem (M4) não conta como brilho: ela só impede a massa de sumir.

### 6.1. Telegrafia

- **Z1.** A zona de perigo de todo inimigo, em todo tema, é vermelha: preenchimento `A01030` por mistura, faixa escura `220410` e borda acesa `FF6A4D` por soma. O vermelho vale quando o conjurador é hostil ao jogador (`Team.MONSTERS`). Nunca só aditivo: a neve mede L* 54 a 75 e some. Serrilha e rachadura são os adornos permitidos.
- **Z2.** A marca de área de aliado (habilidade de herói, como `m_meteor` e `p_judgement`) continua na cor da habilidade e na leitura de sempre: só aditiva, sem faixa escura, sem serrilha e sem o vermelho de Z1.
- **Z3.** O desenho da zona de perigo cobre a área lógica mais o raio do alvo (0,4 m do jogador), porque o acerto soma esse raio. A marca de aliado mantém o tamanho de hoje.

## 7. Materiais

Valores para `Look.hero(cor, roughness, metallic)`, que é `Look.matte` com a luz de personagem de M4. Hex por classe nas fichas. `Look.metal` fica proibido em herói, em arma de herói e no chefe: a textura dele é a sujeira que aparece nos renders.

| Material | Roughness | Metallic | Sombreamento | Uso |
|---|---|---|---|---|
| Aço `B0AEA8` | 0,42 | 0,35 | Facetado | Placa |
| Metal de acabamento (seção 9) | 0,40 | 0,45 | Facetado | Aro, cinto, debrum |
| Pano | 0,85 | 0 | Suave | Capa, casaco, veste |
| Couro `3A2A22` | 0,80 | 0 | Suave | Punho, alça |
| Laca | 0,45 a 0,50 | 0 | Facetado | Crista, escudo, chapéu, gola |
| Pele humana `D9A981` | 0,70 | 0 | Suave | Rosto, mãos |
| Cabelo | 0,55 | 0 | Suave | Mago |
| Pele de animal `EEF1F6` | 0,90 | 0 | Suave | Troféu de T1 |
| Brilho | `Look.glow(cor, 0,9 a 1,0)` | | Suave | Selo, focos, lanterna |

- **M1.** Pano com as duas faces usa material próprio com `cull_mode` desligado. Não altere o material em cache de `Look.matte`, como `_cape` faz hoje.
- **M2.** Corpo de personagem não usa transparência. Ela fica para efeitos.
- **M3.** Metal puro fica proibido: sem cena para refletir, ele escurece. Limite de 0,5 em metallic.
- **M4. Luz de personagem.** Todo material de herói tem emissão igual ao albedo, com energia 0,20, na arma e no viewmodel também. Sem ela, o rosto da massa voltado para a câmera fica só com o ambiente frio e a cor some (V4). Peças de sombra usam `Look.matte` puro: olho, sobrancelha, sob a aba, fundo da manga. Monstros não usam: a vantagem de leitura é do grupo.

## 8. Rig sem skinning

Cada peça é rígida. Junta e pano precisam esconder isso. J1 a J3 e J8 valem para todo modelo bípede, herói ou monstro. A medida é `joint_gaps` do `--monster`.

- **J1. Pivô.** Toda articulação visível tem uma esfera centrada no joint, com raio igual ou maior que o do membro naquele ponto. A esfera fica no joint filho.
- **J2. Sobreposição.** Uma peça entra pelo menos 3 cm na peça vizinha. Nenhuma falha aparece em 90° de flexão.
- **J3. Ombreira e gola no `chest`.** Elas ficam paradas e o braço se move por baixo.
- **J4. Pano atrás fica no joint `cloth_back`.** Ele abre para trás com a velocidade, até 0,55 rad, e nunca é atravessado pelas pernas. O joint é opcional: bichos e a maioria dos inimigos não o criam. O chefe com capa o cria, e as pernas nunca a atravessam.
- **J5. Perna coberta não existe.** Se a saia esconde a perna em toda a animação, não modele a perna. Mantenha os joints.
- **J6. Sinal das poses.** `x` positivo leva o braço para a frente e dobra o cotovelo para a frente. `x` negativo dobra o joelho para trás. A OS-003 corrige o rig atual, que faz o contrário.
- **J7. Arma compensa o braço.** Com o braço girado em `a` rad, em X ou em Z, a arma precisa girar `-a` no mesmo eixo para ficar em pé.
- **J8. Passo em laço.** O joelho dobra enquanto a perna avança, com a flexão adiantada 0,4 rad em relação à coxa, e fica em 0,15 na perna de apoio. Flexão em fase com o quadril faz o pé ir e voltar pela mesma linha, sem sair do chão.
- **J9. Golpe sempre à frente.** Do impacto ao fim, mão e arma ficam à frente do peito. Na preparação, a mão fica à frente do peito e ao lado da cabeça, sem tocá-la, e a arma pode passar da vertical até 30°, com a ponta recuando além do peito. Nenhum outro momento do golpe passa da vertical. A medida é em coordenadas locais do `chest`: mão à frente do peito é `z` de -0,20 m ou menos, além da frente do tronco. Arma é o trecho da mão até a ponta de golpe. O pé de uma haste longa pode ficar atrás do peito, desde que fora do corpo. J9 vale para as armas que golpeiam em jogo, espada e machado. Cajado, orbe, bastão e tomo só conjuram (`cast` e `cast_quick`), e um teste falha se uma habilidade de mago ou sacerdote passar a usar outra animação.
- **J10. Golpe limpa o repouso.** Em `swing`, `overhead` e `thrust` de herói, o X do repouso de `shoulder_r` e `elbow_r` sai com o peso do golpe, e o punho gira para o `strike_wrist` da ficha. O Z do repouso fica (J7). Inimigo continua somando o repouso.

## 9. Progressão de equipamento

**Tier muda a forma e o metal. Raridade muda a luz da arma.** São eixos separados.

| Tier | Nome | Metal de acabamento | Troféu | Regra |
|---|---|---|---|---|
| T0 | Recruta | Bronze `C8963F` | Nenhum | Base da ficha |
| T1 | Gélido | Prata fria `C4D2E0` | Pele branca do lobo | +1 peça de silhueta |
| T2 | Real | Ouro `D8B464` | Ouro do rei | +1 peça ou 10% de escala |
| T3 | Rei Gélido | Platina `E6ECF5` | Coroa e aço pálido | +1 peça, sem brilho frio |

O Rei Gélido veste o que dá: acabamento em ouro `D8B464` (T2 dos heróis) e massa clara em aço pálido `B4C3D6` (família da prata `C4D2E0` e da platina `E6ECF5`). O ícone de `boss_crown` é o aro de ouro com pontas de gelo, e o de `boss_plate` é a couraça pálida.

- **P1.** Cada tier soma pelo menos uma peça de silhueta com 9 cm ou mais em algum eixo, e as peças se acumulam. A ferramenta lê isso em `tier_pieces` (medida no espaço do modelo, não no joint).
- **P2.** A massa da classe é a mesma do T0 ao T3. Hoje T2 fica dourado e T3 fica azul-gelo nas três classes. Isso vale para a massa escura da zona baixa: perna, saia ou casaco escuro não vira aço, prata nem pele em tier nenhum (V1, V2). O guerreiro T1 com canela de aço deu `low_p10` de costas 20,8, contra o limite de 20.
- **P3.** O corpo inteiro segue o tier da armadura. A cabeça segue `max(tier da armadura, tier do elmo)`, e as botas seguem a mesma regra com o tier das botas.
- **P4.** As duas armaduras iniciais de cada classe diferem por uma peça (`look_variant`), detalhada nas fichas.

Luz da arma por raridade, com a cor exata de `LootDrop.RARITY_COLORS`:

| Raridade | Cor | Acesos | Energia |
|---|---|---|---|
| Comum | `C8D0DC` | Nada | Sem brilho |
| Incomum | `6FE08A` | Encaixe 1 (fio) | 0,9 |
| Raro | `5AA8FF` | Encaixes 1 e 2 (fio e gema) | 0,9 |
| Épico | `C07AFF` | Encaixes 1, 2 e 3 | 0,9 |
| Lendário | `FFB13C` | Encaixes 1, 2 e 3 | 1,0 |

- **P5.** `WeaponKit.accent_for` usa essas cores. Hoje épico e lendário são iguais, e o raro repete o ouro do sacerdote.
- **P6.** Toda arma e o escudo têm 3 encaixes, diferentes por modelo, listados na OS-008. Encaixe só existe quando aceso. Peça fixa, como o pomo da espada, não é encaixe.
- **P7.** Peça de tier nenhuma cobre o Selo, na frente nem nas costas. O disco de luz mantém pelo menos 70% dos pixels que tem no T0, medido na frente e nas costas (B3, E3).
- **P8.** Peça de tier nenhuma entra no volume do rosto: no joint `head`, `x` de -0,1 a 0,1, `y` de 0,02 (o queixo) a 0,2 e `z` de -0,05 para a frente. Só a máscara do T3 do guerreiro e o visor dela, que é a fenda da máscara e leva a mesma marca `face_cover` (R2).
- **P9.** Peça de tier com 0,01 m² ou mais de área vista de costas tem L* de 46 ou mais. Peça escura em plano vertical vira laje preta sob a cúpula, como o gorjal do guerreiro. Peça emissiva (`emission_enabled` e energia de 0,5 ou mais) conta pela maior entre o L* do albedo e o da emissão: luz não faz laje.
- **P10.** Peça de tier que se move, ou que fica perto de algo que se move, mantém vão de 5 cm ou mais: focos, aros, pingentes e lâminas contra asas, haste, braços e cabeça, em repouso, em 4 fases do passo, na conjuração e no golpe da classe. O teste mede a distância entre vértices.
- **P11.** Posição de peça de tier é conferida no espaço do modelo, depois do giro do `chest` (guinada de até 0,08 rad no passo e 0,55 rad no golpe) e da ordem de Euler da peça. A ficha dá a posição no joint; o aceite é a posição medida em `tier_pieces`.

## 10. Base comum do caçador

Todo herói usa estas peças. É o que faz os três parecerem do mesmo jogo, junto com o Selo e o metal de acabamento.

Na tabela, `loft` usa anéis `(centro_x, y, raio_x, raio_z)`.

- **G1.** Perfil de `lathe` e anéis de `loft` começam embaixo e sobem em y. Na borda de uma bacia, o perfil pode dobrar para dentro. Perfil de cima para baixo vira a malha do avesso e deixa a peça oca. Vale para toda ficha e ordem.

| Peça | Joint | Construção |
|---|---|---|
| Cabeça | `head` | `loft` de 10 lados com anéis `(0,0,.04,.05) (0,.05,.075,.088) (0,.12,.095,.106) (0,.175,.098,.11) (0,.225,.072,.085) (0,.25,.02,.03)` em `y=.02` |
| Pescoço | `head` | `cylinder(.055,.065,.1,8)` em `y=-.02` |
| Olhos | `head` | `box(.036,.018,.012)` em `(±.044,.132,-.1)`, `1A1410` |
| Sobrancelhas | `head` | `box(.05,.008,.02)` em `(±.045,.158,-.098)`, rot z `∓.06`, `2A1E18` |
| Nariz | `head` | `loft` de 4 lados facetado `(0,0,.018,.02) (0,.05,.008,.008)` em `(0,.085,-.108)`, pele |
| Boca | `head` | `box(.04,.008,.008)` em `(0,.055,-.092)`, `7A4E3A` |
| Mão | `hand_*` | `loft` de 10 lados `(0,-.095,.03,.035) (0,-.05,.045,.052) (0,-.005,.042,.048) (0,.02,.032,.038)` |
| Bota | `knee_*` | `box(.11,.07,.25)` em `(0,-.46,-.05)` e `cylinder(.078,.062,.16,8)` em `(0,-.36,0)` |
| Selo, aro | Ver ficha | `torus(.055,.08,16)`, metal do tier, rot x 90°, escala `(1,.6,1)` |
| Selo, luz | Ver ficha | `sphere(.055,10)`, `glow(cor de classe)`, escala `(1,1,.35)` |

Regras de rosto:

- **R1.** Rosto neutro e sereno. Sem expressão fixa de raiva.
- **R2.** Rosto sempre em T0 a T2. Só o T3 do guerreiro fecha a máscara, e o visor faz parte dela.
- **R3.** Corpo sem marca de gênero: nenhuma classe esculpe peito nem cintura sexuada.

## 11. Orçamento

Medido na masmorra real, em 1080p, com 4 heróis e 12 monstros (440 partes por quadro), Iris Xe em Forward+:

| Partes por criatura | Objetos por quadro | Médio | Alto |
|---|---|---|---|
| 1× (hoje) | 1.487 | 20,7 ms | 35,0 ms |
| 2× | 2.621 | 21,0 ms | 35,4 ms |
| 4× | 4.880 | 22,1 ms | 37,4 ms |

A coluna Alto foi medida antes da correção de malha da OS-002. A coluna Médio, depois.

Hoje os heróis usam de 21 a 30 partes, os monstros de 22 a 34 e o chefe 44, e o blockout usa de 47 a 55. Quadruplicar as partes custa 1,4 ms em Médio. O gargalo desta cena é preenchimento de tela, não número de partes. Montar um herói custa cerca de 3 ms.

| Modelo | Partes | Triângulos | Materiais |
|---|---|---|---|
| Herói T0, com arma lendária | 66 | 5.000 | 18 |
| Herói T1, com arma lendária | 67 | 5.200 | 18 |
| Herói T2, com arma lendária | 68 | 5.600 | 18 |
| Herói T3, com arma lendária | 70 | 6.000 | 18 |
| Monstro comum | 45 | 3.500 | 10 |
| Chefe | 90 | 8.000 | 12 |
| Viewmodel completo, medido em T2 com a pior arma (`sword_shield`) | 38 | 4.000 | 10 |

Heróis medem-se com `--rarity=4` (lendária): os 3 encaixes acesos da arma e do escudo somam partes e um material, e é assim que o T3 é visto em jogo. A raridade 0 mede só o corpo. T0 em raridade 4, variante 0, mediu: guerreiro `sword_shield` 62 partes, 4.730 tris, 16 materiais (a variante 1 soma as 2 telhas médias, cerca de 64 partes e 4.850 tris); mago `staff` 57, 4.144, 17; sacerdote `tome` 54, 3.616, 16 e `scepter` 49, 3.652, 15.

- **C1.** Teto da cena: 900 partes de criatura visíveis.
- **C2.** A soma de todas as peças de arte novas não pode somar mais de 1,0 ms em Médio na cena de referência.
- **C3.** A luz da lanterna do `scepter` é a única luz permanente de herói, com um limite de uma por sacerdote. Sem sombra. Raridade nunca cria luz real: inclusive no lendário, ela só acende encaixes.
- **C4.** Efeitos do chefe: até 160 partículas vivas, 2 luzes e 64 malhas, sem camada translúcida acima de 25% da tela. Sem sombra.

## 12. Checklist de aprovação

Toda revisão usa os renders da OS-001. O veredito é APROVADO, AJUSTES ou REPROVADO, sempre com o código da regra.

| # | Verificação | Render ou dado |
|---|---|---|
| 1 | Malha sólida: nada visível por dentro de outra peça | Turnaround |
| 2 | Silhueta preta distingue as classes nas 3 vistas (S1) | `silhouettes.png` |
| 3 | A classe continua clara sem a arma (S2) | `silhouettes_noweapon.png` |
| 4 | V1 aprovada, frente e costas | `report.json` |
| 5 | Herói legível a 5, 10 e 20 m, de frente e de costas (E3) | `room_05/10/20` |
| 6 | Nenhum brilho em forma ou lugar de inimigo (B1, B2) | Turnaround |
| 7 | Selo na frente e nas costas, em cor exata (B3, V3) | Turnaround, `room_20` |
| 8 | Brilho preserva o matiz, sem disco branco (B4) | Viewmodel, turnaround |
| 9 | Rig: cotovelo e joelho sem falha, pano sem atravessar (J1 a J4) | `walk_side`, `walk_back` |
| 10 | Ataque e cast à frente do corpo (J6, J9) | `pose_cast`, `pose_strike`, `pose_swing` |
| 11 | Arma firme na mão, cabo dentro do punho (J7) | Turnaround, viewmodel |
| 12 | Saguão: rosto e materiais limpos, sem sujeira de textura | `lobby` |
| 13 | Viewmodel mostra mão, manga e armadura vestida | `vm_*` |
| 14 | Tier troca forma e metal, massa igual, letra mantida (P1, P2, S5) | `tiers` |
| 15 | Raridade troca só a luz da arma, na cor da UI (P5) | `rarity` |
| 16 | Dentro do orçamento (seção 11) | `report.json` |
| 17 | Sem nome ou símbolo proibido (O1, O2) | Leitura dos dados e ícones |
| 18 | Matiz e valor das massas na sala (V4) | `report.json`, `room_10` |

## 13. Registro de decisões

| Data | Decisão | Motivo |
|---|---|---|
| 31/10/2026 | Classes em T, Y e A | Três formas opostas, testadas em preto a 20 m |
| 31/10/2026 | Mago em ameixa, não azul | Azul some no gelo. A cor de classe segue no Selo e no forro |
| 31/10/2026 | Sacerdote em jade, chapéu e lanterna | Fim da mitra e da batina. Creme só em cima, porque some na neve |
| 31/10/2026 | Sem capuz em herói | Capuz é a marca do xamã inimigo |
| 31/10/2026 | Luz aliada redonda, inimiga pontuda | Matiz não separa o azul do mago do ciano do Portão |
| 31/10/2026 | Núcleo do cajado oval, não cristal | Estilhaço é linguagem de inimigo |
| 31/10/2026 | Orçamento dobrado em relação ao uso atual | Medição: partes quase não pesam nesta cena |
| 31/10/2026 | Sacerdote sem pernas | Elas nunca aparecem e furavam a saia |
| 31/10/2026 | T3 sai de "Monarca Gélido" para "Rei Gélido" | "Frost Monarch" é nome de Solo Leveling, proibido por O1 |
| 31/10/2026 | Ícone do sacerdote deixa de ser cruz | Regra O2 |
| 31/10/2026 | Massas recalculadas e luz de personagem de 0,20 | A primeira escolha lia azul e preto na sala real, medido em matiz. V1 só mede valor e não pegou isso |
| 31/10/2026 | Teto de 18 materiais por herói | O teto inicial de 12 não cabia nas próprias paletas |
| 31/10/2026 | Lendário sem `OmniLight3D`. C3 vence a tabela de raridade | As armas T3 das três classes são lendárias: todo guerreiro e mago de fim de jogo teria luz permanente, e o sacerdote teria duas. O âmbar `FFB13C` fica a 8° do ouro `FFD76A`, então a poça de luz deixaria de marcar o sacerdote no corredor (O2). O custo de 4 luzes em T3 nunca foi medido contra C2. Cor, energia e encaixes já separam o lendário do épico, e o tier já muda a forma |
| 31/10/2026 | A luz real nasce em `WeaponKit._scepter` e segue a arma | Parecer da OS-004: modelo e viewmodel usam a mesma função, e a luz fica uma só. Sacerdote com tomo não tem luz real. O símbolo da lanterna acesa continua no cinto, com o núcleo emissivo |
| 01/11/2026 | Incomum sobe de 0,8 para 0,9 na seção 9. B4 não muda | B4 vale para todo brilho de herói e se repete nas seções 6 e 7: a tabela era a única exceção. O degrau de 0,1 não separa nada, porque o incomum já difere do raro pela cor e pelo número de encaixes. Abrir B4 para 0,8 criaria uma exceção só para ele. O limite de lavagem segue longe, em 1,4 |
| 01/11/2026 | `room_20` usa outro eixo da sala, `eye_20` | De `eye`, 20 m sempre cai atrás dos braseiros, a cerca de 1 m da parede. O herói recebia fogo e o sacerdote ficava escondido, então a vista não media um aliado a 20 m. `room_05` e `room_10` ficam em `eye`. Detalhe na OS-001 |
| 01/11/2026 | Perfil de `lathe` e `loft` sobe em y (G1) | O escudo e a ficha dele estavam de cima para baixo e só saíam certos por dupla inversão. Corrigido na OS-002 e nas fichas do guerreiro e do sacerdote, antes da OS-008 |
| 01/11/2026 | Cristal com `ROUGHNESS` 0,3 (OS-018) | Com as normais corretas, 0,08 estoura o reflexo em branco e traz fogo para o gelo, contra o pilar 3. A emissão não muda |
| 01/11/2026 | Cristal quase sem reflexo: `METALLIC` 0 e `SPECULAR` 0,1, com `ROUGHNESS` 0,3 (OS-018) | A ponta branca e o salmão da base eram reflexo, não emissão: o mesmo pixel muda com `ROUGHNESS`, e a emissão não passa de cerca de `(185,216,233)`. Alargar o reflexo só espalhou o fogo. No teste, ponta e base zeraram saturados e quentes, e o peito do rei voltou a ler azul. Custo aceito: cristais de corredor um pouco mais escuros, com silhueta e borda clara mantidas |
| 01/11/2026 | Cristal do cajado do xamã fica `7FD4FF`, fora de `enemy_glow` (OS-006) | Acompanha os cristais do golem e do rei, que seguem o tema gelo. Hoje a diferença não aparece. Ao criar o segundo tema, decidir juntos o cajado, os núcleos e os cristais |
| 01/11/2026 | Saguão medido a 3,7 m, com 299 px/m e herói de 570 px | A câmera fica fora do eixo: o herói está a 4,2 m dela, mas a escala depende da profundidade, que é de 3,7 m. A cabeça de 0,25 m mede 75 px no render. Só o número estava errado, e nenhuma peça muda |
| 01/11/2026 | Olho com o dobro da espessura da sobrancelha, e sobrancelha menos inclinada (OS-007) | Com a mesma espessura, olho e sobrancelha viravam duas riscas, e o rosto lia como olho fechado e abatido, contra R1. O saguão é onde o rosto mais aparece |
| 01/11/2026 | Nervuras escuras da abóbada aceitas | São a geometria prevista em `_dome_rib`, com a pedra das colunas, e só apareceram com as faces certas. Na sala do chefe, ficam acima do olhar de combate |
| 01/11/2026 | Passo em laço (J8), `knee_bend` 0,85 e mago com `stride` 0,55 e `knee_bend` 0,6 | Só inverter o sinal deixava a perna em balanço reta e o pé na mesma linha, e trocar os senos virava um salto. Os valores menores mantêm o pé fora da capa e da aba abertas (J4), o que ainda se confirma nas OS-009 e 010 |
| 01/11/2026 | Curva própria para `swing` (J9) | Nem o golpe atual nem o sinal invertido ficam à frente de ponta a ponta, e ele é o golpe mais usado. `pose_swing.png` entra na ferramenta porque o `swing` não aparecia em nenhuma revisão |
| 01/11/2026 | Viewmodel mantém o teto de 10 materiais, com duplicatas em cache | Os 15 a 21 medidos vêm de uma cópia por peça em `Look.for_viewmodel`: a origem tem de 4 a 6 materiais. Subir o teto só esconderia o desperdício. Pela paleta das fichas, o pior caso é o mago com `staff` em T1 ou mais e raridade acesa, com 9 materiais, ou 10 com a barreira ativa. Detalhe na OS-012 |
| 01/11/2026 | J9 separa a preparação do resto do golpe, com a arma até 30° além da vertical | O texto pedia arma à frente do peito e, ao mesmo tempo, permitia passar da vertical. A rotação do peito recua o ombro e leva a mão para o lado da cabeça (0,73 m ou mais), o que dá um golpe lateral legível. Baixar o braço encurtaria o arco e tiraria o aviso do golpe |
| 01/11/2026 | J10: em golpe de herói, o X do repouso sai e o punho gira por modelo | A soma do repouso com o golpe jogava machado, cajado e bastão para trás do peito. Só limpar o repouso deixaria essas armas 50° a 70° além da vertical no armado, então o punho completa. O machado entra no arco da espada, e a curva e os números da espada não mudam. `overhead` e `thrust` entram porque o machado voltava ao ombro no meio do golpe |
| 01/11/2026 | J9 medida no `chest`, com arma da mão até a ponta de golpe | No referencial do mundo, o giro do peito esconde o avanço da mão. O pé de uma haste de 2,1 m segurada no meio não pode ficar à frente em todo o arco sem encurtar o golpe |
| 01/11/2026 | Abóbada e umbo do escudo em -Z (rot x `-PI/2`), com a mão recuada 5 cm | A ficha dizia `PI/2`, e a abóbada ficava voltada para o braço: o render de raridade mostrava a face de dentro. O punho furava a face plana ao lado do umbo. Laca é facetada (seção 7), o que tira a emenda do `lathe` |
| 01/11/2026 | Escudo com 3 encaixes, fio da espada nas bordas e pomo fixo | Com só um encaixe, o escudo não mostrava 5 estágios. O fio central ficava sob a aresta da lâmina e sumia de perfil, enquanto o fio de borda do machado já lia bem. Sem pomo, a espada comum parecia inacabada |
| 01/11/2026 | Orbe e luz do tomo flutuam, sem cabo | Forma redonda fechada na mão esconderia o foco, e flutuar é a ideia do aro do mago. O critério de cabo na mão não se aplica a eles |
| 01/11/2026 | Peça sólida pode usar o material de duas faces do pano de mesma cor (M1) | O mago fechava o T0 em 18 materiais e o T1 traz a pele `EEF1F6`, material novo: 19, acima do teto da seção 11. Asa interna e cabelo sólido passam a dividir o material do forro e da trança, sem mudar a aparência. O teto de 18 fica |
| 01/11/2026 | J9 vale só para espada e machado | A ficha do mago exigia a haste a 30° além da vertical no preparo do golpe e o ombro aberto para afastar o aro da asa a levou a 31°. Nenhuma habilidade de mago ou sacerdote golpeia: o ataque básico é `cast_quick` e o resto é `cast`. Proteger uma pose que o jogador não vê custava o vão entre aro e asa, que se vê de costas o tempo todo. Um teste novo cobre o caso em que alguém dê `swing` a um conjurador |
| 01/11/2026 | Mago: ombro do cajado em `.4` e haste em `-.47`, no lugar de `.3` e `-.32` | Com os valores da ficha, o aro tocava a ponta da asa de costas e, em passo, ela entrava no aro. A ficha acertou a haste vertical, mas não media o vão. Agora o vão mínimo é de 6 cm |
| 01/11/2026 | Viewmodel sobe de 34 partes e 3.000 tris para 38 e 4.000 (OS-012) | A estimativa era anterior à ordem, que pede 8 `torus` de dedo, alça e disco interno de escudo: o `sword_shield` mediu 35 partes e 4.262 tris em T0, e em T2 soma 2 punhos de pele. O gargalo desta cena é preenchimento de tela (seção 11), e o viewmodel é um objeto só, não multiplicado por 440 partes. Os dedos descem de 14 para 10 lados (224 para 160 tris), o que ainda lê como anel em volta do cabo e combina com o escudo facetado. Materiais seguem em 10 |
| 01/11/2026 | Machado do guerreiro é de uma mão, também no viewmodel (OS-012) | A ficha (`shoulder_l (.05,0,-.12)`, `elbow_l` zero) e `build_off_hand` não dão nada ao braço esquerdo. O punho fechado vazio do viewmodel parecia apontar. Braço e mão esquerdos ficam ocultos com `greataxe` |
| 01/11/2026 | Cotovelo no plano próximo aceito no viewmodel (OS-012) | O centro do cotovelo fica de 0 a 2 cm à frente do plano `z = -0,06` no guerreiro, e até 8 cm atrás dele no mago e no sacerdote, só em `swing`, `overhead`, `thrust` e `shout`. A cunha de manga dura poucos quadros e não chega ao centro da tela. Tempos e curvas estão fora da ordem, e encurtar o antebraço arrisca mostrar a boca aberta da manga em `thrust`, que não dá para medir sem render |
| 02/11/2026 | Orçamento de herói por tier, medido em raridade 4: 66, 67, 68 e 70 partes; 5.000, 5.200, 5.600 e 6.000 tris; 18 materiais | A linha antiga (T0 com 56 partes e 4.500 tris) foi medida sem raridade. Com `--rarity=4`, o T0 do guerreiro (variante 0) já mede 62 e 4.730 e o do mago 57 e 4.144, então `limit_ok` dava falso sem culpa do T0. O T3 do mago, com 4 focos de `torus(.06,.09,18)`, passaria de 6.000 tris, e os focos descem para 12 lados. Guerreiro e mago ficam sem folga em materiais (18 de 18): a pele e o visor são os únicos materiais novos |
| 02/11/2026 | V5 aceita metal de tier e pele até L* 96 | A platina `E6ECF5` (L* 93) e a pele `EEF1F6` (L* 95) estavam acima do teto de 88 da própria regra. São pontuação sobre a massa (V6), e o viewmodel T2 com pele já foi aprovado em render. Subir a massa seria outra coisa: ela segue em 88 |
| 02/11/2026 | P7 a P11: Selo, rosto, laje escura, vão e posição medida (OS-013 a 015, ferramenta na OS-019) | As quatro classes erraram T0 por esses motivos: conta no joint sem o giro do `chest` e sem Euler, peça em volta da cabeça cobrindo o rosto, peça escura em plano vertical virando laje nas costas, aro e asa se tocando andando. Nos tiers, a mesma conta mostrou 3 casos antes de qualquer render: a gola de pele do guerreiro (`y` .43 a .65, `z` .29) engolia o Selo e o queixo, o manto do sacerdote ficava 1,5 cm por fora do Selo traseiro e o véu de 0,50 m o cobria, e o segundo aro do mago (`.205` a `.24`) chegava a 1,5 cm da asa da gola |
| 02/11/2026 | Sacerdote T3: véu em duas fitas, segunda aba menor. Mago T3: aro interno, painéis da frente em .94. Guerreiro T1: gola mais baixa. Guerreiro T3: sem nasal | Ver OS-013 a 015. O véu único de 0,50 m cobre o Selo das costas (E3). O segundo aro externo encostava na asa. A aba traseira de 1,14 m desce 13 cm abaixo do piso. Visor e nasal juntos desenham uma cruz (O2) |
| 02/11/2026 | P9 mede peça emissiva pela emissão (revisão da OS-019) | `Look.glow` escurece o albedo em 40%: o núcleo do foco do mago (`8A7BFF`, energia .9, esfera de .1 x .1 m, visível de costas) tem L* 36 no albedo e 59 na emissão. Pelo albedo, `p9_ok` falharia em todo T2 e T3 do mago por uma peça que acende. Os Selos do sacerdote em T1+, discos de `glow`, entrariam no mesmo caso |
| 02/11/2026 | Guerreiro T1: canela volta ao escuro. T3: visor é `face_cover` (revisão da OS-013) | A canela de aço do T1 deixou a zona baixa clara contra a neve e trocou a massa escura por tier, contra V1, P2 e V2: `low_p10` de costas 20,8 em T1 e 20,6 em T2, com limite de 20. O limite não sobe: V1 existe para o aliado visto com os pés sobre o piso. O visor do T3 cai no volume do rosto por ser a fenda da máscara, e a máscara já cobre o rosto por R2: mover o visor o separaria dela |
| 02/11/2026 | Sacerdote T3: lanterna a 1,18 chega a 4,51 cm da primeira aba (P10 pede 5); pingente de 11,4 cm (E1 pede 9) (revisão da OS-015) | A distância é 3D entre vértices e a lanterna não toca a aba em render; o contato em 2D já era exceção da OS-011. Recuperar 0,5 cm custaria escala menor ou pivô novo e outra medição. Exceção da classe, piso de 4 cm. O pingente de 12 cm era o nominal da esfera de 10 lados |
| 07/11/2026 | Ícones de habilidade do sacerdote sem cruz: `smite`, `heal` e `circle` trocados (OS-020). O2 passa a valer para ícone de UI e a incluir a cruz grega e a cruz em aro | A validação da OS-017 achou uma cruz latina em `smite.svg`, do commit original. O "+" de braços iguais lê como símbolo de saúde em qualquer HUD, mas a regra lista a cruz sem exceção, e no sacerdote ele seria o único traço que sobraria da cruz que a decisão de 31/10 já tirou do ícone de classe. A cruz em aro lê como cruz de sol antes de ler como área de cura. Os três ícones novos usam a chama da lanterna, a única marca da Vigília: cometa com chama vazada, coração com chama vazada e aro com chama. `bless`, `judgement` e `miracle` foram lidos no SVG e ficam: não há travessa em ângulo reto, e a estrela tem 7 pontas |
| 07/11/2026 | S3 não proíbe a lâmina de aço mate da ombreira do guerreiro T3 | Na revisão final, as duas lâminas brancas sobre os ombros leem como chifres no saguão. A ficha as pede desde a OS-013, o aço é mate (B2) e a letra T se mantém (S5). A proibição de S3 é a do chifre e do espinho de cabeça e de corpo, em cristal, osso ou gelo, que é o que o inimigo usa. Se em jogo elas lerem como inimigo, a alavanca é a inclinação (rot z `.3` para `.15`) e a altura (`.32` para `.24`) |
| 07/11/2026 | Revisão final do conjunto de classes (checklist da seção 12): AJUSTES, só pelos ícones | Os três modelos passam nos itens visuais em T0 e T3. Ressalvas aceitas: fiapo roxo do casaco do mago sobre a pelerine, vista só de costas a menos de 4 m; Selo dourado do sacerdote T3 sobre o creme, com pouco contraste a 20 m; lendário e comum do cetro com a mesma cor de lanterna. Detalhes na resposta da revisão |
| 08/11/2026 | Chefe passa a seguir o guia: sem `Look.metal` (M1), E2 sem coroa e chifre (M2), `cloth_back` no chefe (M3), J1 a J3 e J8 em todo bípede (M4), ouro `D8B464` e aço pálido `B4C3D6` como o que o chefe veste (M5). Aprovado com a OS-021 | O diagnóstico do Rei Gélido achou J2 quebrada em cotovelo e joelho, ferrugem de textura em placa e capa furada pela perna. O guia só falava de herói. O corpo novo cabe na cápsula atual (excesso de -0,032 m no blockout) |
| 08/11/2026 | Seção 6.1, telegrafia (Z1 a Z3), linha de efeito de ataque e energia do cristal do chefe na seção 6, e C4 (OS-022) | A zona de perigo somava luz sobre a neve (L* 54 a 75) e sumia, e quatro das cinco habilidades do chefe eram azul-claro sobre as runas `9FE3FF`. O vermelho é o único matiz que o gelo e o `enemy_glow` não têm, e vale só para conjurador hostil: `Telegraph.spawn_area` também serve a `m_meteor` e `p_judgement`, que seguem na cor da habilidade, só aditivas. A cúpula de 16 m cobriria o quadro inteiro e o gargalo da cena é preenchimento de tela, daí C4 |
