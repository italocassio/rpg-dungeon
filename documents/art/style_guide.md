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
- **O2.** Nenhum símbolo religioso real: cruz, mitra, casula, crescente, estrela de Davi, om, roda do dharma, torii, yin-yang. A fé do jogo é a Vigília, ficcional, e seu único símbolo é a lanterna acesa.
- **O3.** A assinatura do jogo é o Selo de Caçador: um aro de bronze com um disco de luz.

## 3. Escala e distâncias reais

Herói mede cerca de 1,90 m sem peça alta. Cabeça de 0,25 m, proporção de 7,5 cabeças. A frente do modelo é **-Z**, a mão direita fica em **+X**.

| Onde o herói é visto | Câmera | px por metro em 1080p | Herói | O que conta |
|---|---|---|---|---|
| Saguão | 4 m, FOV 52 | 277 | 500 px | Rosto, materiais |
| Aliado perto | 5 m, FOV 78 | 133 | 240 px | Peças grandes, Selo |
| Aliado médio | 10 m, FOV 78 | 67 | 120 px | Massas e cor |
| Aliado longe | 20 m, FOV 78 | 33 | 60 px | Só silhueta e Selo |
| Primeira pessoa | Câmera, FOV 74 | Peça a peça | Mãos, arma | Mão, manga, arma |

- **E1.** Peça com menos de 9 cm (3 px a 20 m) não conta como silhueta. Serve de detalhe.
- **E2.** A cabeça nunca passa de 1/7 da altura do corpo. Nada de proporção infantil.
- **E3.** O aliado costuma ser visto de costas, porque luta virado para o monstro. A vista traseira vale tanto quanto a frontal.

## 4. Silhueta

| Classe | Letra | Largura em T0 | Altura em T0 | Traço que nenhuma outra tem |
|---|---|---|---|---|
| Guerreiro | **T** | 0,99 m nos ombros | 2,05 m | Ombreiras e escudo |
| Mago | **Y** | 0,60 m na gola | 2,40 m | Gola em duas asas e haste alta |
| Sacerdote | **A** | 0,90 m na aba | 2,15 m | Disco do chapéu e sino da saia |

- **S1.** Em preto, as três classes se distinguem de frente, de perfil e de costas, a 20 m e a 60 px.
- **S2.** A classe se lê sem a arma. Machado, orbe e tomo não podem apagar a letra.
- **S3.** Formas reservadas a inimigos: capuz, chifre lateral, espinho de gelo, estilhaço emissivo. Herói não usa nenhuma delas.
- **S4.** Herói e inimigo não compartilham função de modelo nem arma. `_robed_body`, `_hood`, `_armored_body`, `_cape` e as armas atuais ficam só com os inimigos.
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
- **V5. Limites de albedo.** L* entre 10 e 88. Nada de branco ou preto puros. Olho, boca e visor são exceção.
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
| Energia | 0,9 a 1,0 | 4,0 nos olhos, até 7,0 no chefe |

- **B1.** Olho de herói nunca emite. Olho é `1A1410` fosco, sem luz de personagem. Máscara de T3 também não brilha.
- **B2.** Herói nunca emite em estilhaço. Ponta de metal fosco é permitida.
- **B3.** Todo herói carrega o Selo na frente e nas costas.
- **B4.** Energia de herói fica entre 0,9 e 1,0. Em 1,4 o Selo já lava para branco, e em 2,0 a 3,0 o orbe e a luz do tomo viram um disco branco no viewmodel.
- **B5.** Todo olho de inimigo usa `enemy_glow`. Isso inclui o goblin `ffd24a`, que hoje fica perto do ouro do sacerdote, e o esqueleto `6cc2ff`.
- **B6.** Peça de herói feita de monstro é pálida e fosca. Nada de gelo emissivo em armadura de herói.
- **B7.** Luz de personagem (M4) não conta como brilho: ela só impede a massa de sumir.

## 7. Materiais

Valores para `Look.hero(cor, roughness, metallic)`, que é `Look.matte` com a luz de personagem de M4. Hex por classe nas fichas. `Look.metal` fica proibido em herói e em arma de herói: a textura dele é a sujeira que aparece nos renders.

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

Cada peça é rígida. Junta e pano precisam esconder isso.

- **J1. Pivô.** Toda articulação visível tem uma esfera centrada no joint, com raio igual ou maior que o do membro naquele ponto. A esfera fica no joint filho.
- **J2. Sobreposição.** Uma peça entra pelo menos 3 cm na peça vizinha. Nenhuma falha aparece em 90° de flexão.
- **J3. Ombreira e gola no `chest`.** Elas ficam paradas e o braço se move por baixo.
- **J4. Pano atrás fica no joint `cloth_back`.** Ele abre para trás com a velocidade, até 0,55 rad, e nunca é atravessado pelas pernas. O joint é opcional: bichos e inimigos não o criam.
- **J5. Perna coberta não existe.** Se a saia esconde a perna em toda a animação, não modele a perna. Mantenha os joints.
- **J6. Sinal das poses.** `x` positivo leva o braço para a frente e dobra o cotovelo para a frente. `x` negativo dobra o joelho para trás. A OS-003 corrige o rig atual, que faz o contrário.
- **J7. Arma compensa o braço.** Com o braço girado em `a` rad, em X ou em Z, a arma precisa girar `-a` no mesmo eixo para ficar em pé.

## 9. Progressão de equipamento

**Tier muda a forma e o metal. Raridade muda a luz da arma.** São eixos separados.

| Tier | Nome | Metal de acabamento | Troféu | Regra |
|---|---|---|---|---|
| T0 | Recruta | Bronze `C8963F` | Nenhum | Base da ficha |
| T1 | Gélido | Prata fria `C4D2E0` | Pele branca do lobo | +1 peça de silhueta |
| T2 | Real | Ouro `D8B464` | Ouro do rei | +1 peça ou 10% de escala |
| T3 | Rei Gélido | Platina `E6ECF5` | Coroa e aço pálido | +1 peça, sem brilho frio |

- **P1.** Cada tier soma pelo menos uma peça de silhueta com 9 cm ou mais, e as peças se acumulam.
- **P2.** A massa da classe é a mesma do T0 ao T3. Hoje T2 fica dourado e T3 fica azul-gelo nas três classes.
- **P3.** O corpo inteiro segue o tier da armadura. A cabeça segue `max(tier da armadura, tier do elmo)`, e as botas seguem a mesma regra com o tier das botas.
- **P4.** As duas armaduras iniciais de cada classe diferem por uma peça (`look_variant`), detalhada nas fichas.

Luz da arma por raridade, com a cor exata de `LootDrop.RARITY_COLORS`:

| Raridade | Cor | Acesos | Energia |
|---|---|---|---|
| Comum | `C8D0DC` | Nada | Sem brilho |
| Incomum | `6FE08A` | Encaixe 1 (fio) | 0,8 |
| Raro | `5AA8FF` | Encaixes 1 e 2 (fio e gema) | 0,9 |
| Épico | `C07AFF` | Encaixes 1, 2 e 3 (segundo fio) | 0,9 |
| Lendário | `FFB13C` | Encaixes 1, 2 e 3, mais uma `OmniLight3D` sem sombra (alcance 2 m, energia 0,4) | 1,0 |

- **P5.** `WeaponKit.accent_for` usa essas cores. Hoje épico e lendário são iguais, e o raro repete o ouro do sacerdote.

## 10. Base comum do caçador

Todo herói usa estas peças. É o que faz os três parecerem do mesmo jogo, junto com o Selo e o metal de acabamento.

Na tabela, `loft` usa anéis `(centro_x, y, raio_x, raio_z)`.

| Peça | Joint | Construção |
|---|---|---|
| Cabeça | `head` | `loft` de 10 lados com anéis `(0,0,.04,.05) (0,.05,.075,.088) (0,.12,.095,.106) (0,.175,.098,.11) (0,.225,.072,.085) (0,.25,.02,.03)` em `y=.02` |
| Pescoço | `head` | `cylinder(.055,.065,.1,8)` em `y=-.02` |
| Olhos | `head` | `box(.036,.012,.012)` em `(±.044,.135,-.1)`, `1A1410` |
| Sobrancelhas | `head` | `box(.05,.012,.02)` em `(±.045,.158,-.098)`, rot z `∓.12`, `2A1E18` |
| Nariz | `head` | `loft` de 4 lados facetado `(0,0,.018,.02) (0,.05,.008,.008)` em `(0,.085,-.108)`, pele |
| Boca | `head` | `box(.04,.008,.008)` em `(0,.055,-.092)`, `7A4E3A` |
| Mão | `hand_*` | `loft` de 10 lados `(0,-.095,.03,.035) (0,-.05,.045,.052) (0,-.005,.042,.048) (0,.02,.032,.038)` |
| Bota | `knee_*` | `box(.11,.07,.25)` em `(0,-.46,-.05)` e `cylinder(.078,.062,.16,8)` em `(0,-.36,0)` |
| Selo, aro | Ver ficha | `torus(.055,.08,16)`, metal do tier, rot x 90°, escala `(1,.6,1)` |
| Selo, luz | Ver ficha | `sphere(.055,10)`, `glow(cor de classe)`, escala `(1,1,.35)` |

Regras de rosto:

- **R1.** Rosto neutro e sereno. Sem expressão fixa de raiva.
- **R2.** Rosto sempre em T0 a T2. Só o T3 do guerreiro fecha a máscara.
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
| Herói T0, com arma | 56 | 4.500 | 18 |
| Herói T3, com arma | 70 | 6.000 | 18 |
| Monstro comum | 45 | 3.500 | 10 |
| Chefe | 90 | 8.000 | 12 |
| Viewmodel completo | 34 | 3.000 | 10 |

- **C1.** Teto da cena: 900 partes de criatura visíveis.
- **C2.** A soma de todas as peças de arte novas não pode somar mais de 1,0 ms em Médio na cena de referência.
- **C3.** A luz da lanterna é a única luz permanente de herói, com um limite de uma por sacerdote. Sem sombra.

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
| 10 | Ataque e cast à frente do corpo (J6) | `pose_cast`, `pose_strike` |
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
