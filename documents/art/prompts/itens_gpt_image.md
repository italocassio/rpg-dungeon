# Prompts de imagem dos itens (GPT Image)

Versão 1.0, 07/11/2026. Documento de apoio da direção de arte. Gera 48 ilustrações, uma por arquivo de `data/items/*.tres`, para o inventário, a forja e o saguão. Segue `documents/art/style_guide.md` e fica abaixo dele: se um prompt divergir do guia, vale o guia, e o prompt se corrige aqui. O guia não foi alterado.

Os textos deste documento são em português. Os blocos dentro de caixas de código são prompts em inglês, porque o modelo os segue melhor. Os nomes dos itens ficam em português nos títulos.

## Como usar

1. Monte cada pedido na ordem: **bloco de estilo** (seção 1), depois o **prompt do item**, depois o **bloco de restrições** (seção 2). Os três juntos são autossuficientes: nenhum prompt depende de imagem de referência nem de outro prompt.
2. Configuração no GPT Image: tamanho 1024 × 1024, qualidade alta, saída PNG, fundo transparente (na API, `background: transparent`). Gere de 2 a 3 candidatas por item e escolha a melhor.
3. Plano B se a ferramenta não der canal alfa (o ChatGPT costuma entregar fundo sólido): acrescente ao fim do pedido `Background: one flat solid pure green #00FF00, no gradient, no shadow, no floor.` e recorte o verde depois. O verde puro não existe em nenhuma paleta do jogo, e o jade `247050` do sacerdote fica longe dele em valor.
4. Nomeie o arquivo com o `id` do item (`w_start_sword.png`). Este documento não decide onde o arquivo entra no projeto.
5. Gere a linha inteira de uma classe em sequência (T0, T1, T2, T3) e confira os quatro lado a lado. Se o estilo derivar de um item para outro, anexe a imagem aprovada do T0 da mesma linha como referência opcional. Os prompts não exigem isso.
6. O modelo aproxima hex, não o reproduz. Confira com conta-gotas: o matiz fica a até 15° do alvo e o valor (L*) a até 10 pontos. Fora disso, regere ou corrija a cor no editor.

## Índice

| # | id | Nome | Grupo |
|---|---|---|---|
| 01 | `w_start_sword` | Espada e Broquel de Caçador | Guerreiro |
| 02 | `w_start_axe` | Machado Grande de Novato | Guerreiro |
| 03 | `w_start_mail` | Cota de Malha | Guerreiro |
| 04 | `w_start_plate` | Couraça de Recruta | Guerreiro |
| 05 | `warrior_t1_weapon` | Lâmina Gélida | Guerreiro |
| 06 | `warrior_t1_armor` | Couraça Gélida | Guerreiro |
| 07 | `warrior_t1_helm` | Elmo Gélido | Guerreiro |
| 08 | `warrior_t1_boots` | Grevas Gélidas | Guerreiro |
| 09 | `warrior_t2_weapon` | Lâmina Real | Guerreiro |
| 10 | `warrior_t2_armor` | Armadura Real | Guerreiro |
| 11 | `warrior_t3_weapon` | Lâmina do Rei Gélido | Guerreiro |
| 12 | `warrior_t3_armor` | Armadura do Rei Gélido | Guerreiro |
| 13 | `m_start_staff` | Cajado de Aprendiz | Mago |
| 14 | `m_start_orb` | Orbe Cintilante | Mago |
| 15 | `m_start_robe` | Túnica de Aprendiz | Mago |
| 16 | `m_start_cloak` | Manto do Novato | Mago |
| 17 | `mage_t1_weapon` | Cajado Gélido | Mago |
| 18 | `mage_t1_armor` | Manto Gélido | Mago |
| 19 | `mage_t1_helm` | Diadema Gélido | Mago |
| 20 | `mage_t1_boots` | Botas Leves Gélidas | Mago |
| 21 | `mage_t2_weapon` | Cajado Real | Mago |
| 22 | `mage_t2_armor` | Manto Real | Mago |
| 23 | `mage_t3_weapon` | Cajado do Rei Gélido | Mago |
| 24 | `mage_t3_armor` | Manto do Rei Gélido | Mago |
| 25 | `p_start_scepter` | Cetro do Noviço | Sacerdote |
| 26 | `p_start_tome` | Tomo da Vigília | Sacerdote |
| 27 | `p_start_habit` | Veste do Noviço | Sacerdote |
| 28 | `p_start_pilgrim` | Vestes do Peregrino | Sacerdote |
| 29 | `priest_t1_weapon` | Cetro Gélido | Sacerdote |
| 30 | `priest_t1_armor` | Vestes Gélidas | Sacerdote |
| 31 | `priest_t1_helm` | Chapéu Gélido | Sacerdote |
| 32 | `priest_t1_boots` | Botas Gélidas | Sacerdote |
| 33 | `priest_t2_weapon` | Cetro Real | Sacerdote |
| 34 | `priest_t2_armor` | Vestes Reais | Sacerdote |
| 35 | `priest_t3_weapon` | Cetro do Rei Gélido | Sacerdote |
| 36 | `priest_t3_armor` | Vestes do Rei Gélido | Sacerdote |
| 37 | `mat_bone` | Osso Antigo | Materiais |
| 38 | `mat_cloth` | Trapo Congelado | Materiais |
| 39 | `mat_essence` | Essência Gélida | Materiais |
| 40 | `mat_fang` | Presa Rachada | Materiais |
| 41 | `mat_hide` | Couro Gélido | Materiais |
| 42 | `mat_ore` | Ferro Negro | Materiais |
| 43 | `mat_shard` | Fragmento de Cristal | Materiais |
| 44 | `potion_hp` | Poção de Vida | Poções |
| 45 | `potion_mp` | Poção de Mana | Poções |
| 46 | `boss_core` | Núcleo do Rei Gélido | Itens de chefe |
| 47 | `boss_plate` | Placa Real Congelada | Itens de chefe |
| 48 | `boss_crown` | Estilhaço da Coroa | Itens de chefe |

## 1. Bloco de estilo comum

Cole este bloco **antes** de qualquer prompt de item. Decisões que o sustentam estão em "Decisões novas".

**Enquadramento e formato (resumo para você):** 1024 × 1024, quadrado, fundo transparente, um objeto centrado a 80% do quadro. Armas na diagonal com a ponta para cima e para a direita; armaduras de frente, simétricas e vazias, como num manequim invisível; elmos e chapéus em três quartos; botas em par; materiais, poções e itens de chefe em três quartos, de leve por cima. Luz principal em cima à esquerda, sem sombra no chão, topo claro e base escura, no espírito de V1. Nível de detalhe pensado para 46 a 64 px: no máximo 3 ou 4 massas de cor, mais um acento.

**Relação com o 3D procedural:** a ilustração é a versão de saguão do mesmo objeto. O 3D é facetado e liso, com 20 a 70 peças, e a imagem tem de manter as peças, a forma e as cores dele. Ela pode ter acabamento pintado mais rico, mas não pode inventar peça. A ilustração não substitui o modelo: serve para o inventário, a forja e o saguão. Nenhum dado da ilustração volta para o 3D.

```text
STYLE (applies to the whole image): a single game-item illustration for an inventory, forge and lobby icon of a dark-fantasy hunter-and-gates RPG. Clean stylized painted render of a hard-surface object: simple faceted planes with crisp edges on plate, metal, lacquer, glass and crystal, and smooth soft shading on cloth, leather and fur. Mood: sober, dignified, veteran-hunter gear; warm human materials (bronze, leather, cloth) with a cool pale accent. Finish is always clean: satin surfaces, no mirror chrome, no wet gloss, and no dirt, scratches, rust, grime or noise texture; detail comes from shape, never from surface noise. The item must look like the in-game procedural 3D model drawn in a polished 2D way: same silhouette, same pieces, same proportions, same colors. Never add ornaments, engravings, gems, runes, filigree, patterns or pieces that the item description does not list.
CANVAS: square 1:1, 1024 x 1024 px, transparent background (PNG with alpha), no backdrop of any kind.
FRAMING: exactly one item (or the pair or set the description names), centered, filling about 80 percent of the canvas along its longest side, with at least 9 percent empty margin on every side, never cropped. Weapons are drawn diagonally with the tip toward the upper right as described; armor is drawn front view, symmetrical; everything else as described.
CAMERA: orthographic-like, almost no perspective (long lens), camera about 10 degrees above the item unless the description says otherwise.
LIGHTING: soft key light from the upper left front (about 35 degrees above, 30 degrees to the left), a weak cool fill from the right #9FC8E8, a thin cool rim light on the shadow-side edge. Light on top, darker toward the bottom of the object. No hard cast shadow and no ground shadow. Darkest tone no darker than #14141C and lightest no brighter than #F2F4F8 (no pure black, no pure white).
READABILITY: it must read at 46 to 64 px. Strong silhouette; at most 3 or 4 large color masses plus one accent; every defining feature at least 8 percent of the canvas size, and anything under 5 percent is surface detail that may be dropped; a thin outline in a darker shade of the item's own color (about 3 px at 1024, never black) around the outer silhouette; clear value contrast between the item and the transparent background; never rely on a glow alone to show a shape.
COLOR: use exactly the hex values of the item prompt. One saturated mass per item; metals and the class color are punctuation.
EMISSION: only parts the item prompt lists may glow. A glow keeps its hue (never blown out to white), has a bloom of only a few pixels around the glowing part, and is never an aura, a halo, a particle, a light ray or a lens flare around the object.
```

**Materiais do guia (seção 7) como aparecem nos prompts.** O modelo não lê roughness nem metallic, então cada linha é traduzida em palavras. Os números ficam aqui para a conferência.

| Material do guia | Valores | No prompt |
|---|---|---|
| Aço `B0AEA8` | roughness 0,42, metallic 0,35, facetado | satin steel, flat faceted planes, low reflections |
| Metal de acabamento por tier | roughness 0,40, metallic 0,45, facetado | satin bronze `C8963F` (T0), cold silver `C4D2E0` (T1), gold `D8B464` (T2), platinum `E6ECF5` (T3) |
| Pano | roughness 0,85 | smooth cloth, no pattern, soft shading |
| Couro `3A2A22` | roughness 0,80 | smooth leather, no wrapping pattern |
| Laca | roughness 0,45 a 0,50, facetada | satin lacquer with hard facet highlights |
| Pele de animal `EEF1F6` | roughness 0,90 | soft fur sculpted in a few big clean tufts |
| Brilho (`Look.glow`) | energia 0,9 a 1,0 | moderate glow, hue preserved, never white |

O metal de acabamento troca por tier e a massa de cor da classe nunca troca (P2, V2).

## 2. Bloco de restrições comum

Cole este bloco **depois** do prompt do item. Ele cobre as regras O1 e O2, B2, B6, S3 e o pilar 5 do guia. Os prompts de material e de item de chefe trazem, no próprio texto, as poucas exceções (presa, cristal).

```text
DO NOT INCLUDE: any text, letters, numbers, runes, glyphs, labels, logos, signatures or watermarks; any frame, border, card, badge, panel, vignette, backdrop or background shape; any rarity frame, rarity glow, aura, halo, sparkle, particles, light rays, lens flare or colored backdrop (the game UI tints the background by rarity); any ground, floor, table, pedestal, stand, hanger, mannequin, bust or other support; any cast shadow or reflection on a surface; hands, fingers, arms, legs, faces, hair, characters or bodies (armor and clothes are shown hollow and floating, as on an invisible mannequin); more than the item (or pair or set) the prompt names; any real religious symbol: no cross of any kind (Latin cross, Greek cross, plus sign, cross inside a ring, two bars crossing at right angles; the plain crossguard of a sword is allowed and must stay), no crescent, star of David, om, dharma wheel, torii, yin-yang, mitre or chasuble; no hood or cowl; on weapons, armor and clothes: no horns, antlers, fangs, claws, spikes, skulls or demon motifs, no ice spikes, icicles, frost crystals or glowing blue shards ("Gélido" here means only pale silver trim and white wolf fur), no glowing eyes; no chrome, mirror metal or wet gloss; no dirt, rust, scratches, blood, grime, worn or noisy texture; no photorealism and no glossy plastic 3D look; no heavy black outlines and no comic halftone; no design, character, emblem, weapon or armor from any existing game, anime, comic or film, in particular nothing from Perfect World or Solo Leveling. If the item prompt explicitly asks for something listed here (for example a fang, a crystal or a crystal point on a monster material), the item prompt wins for that thing only.
```

## 3. Guerreiro (12 itens)

### Linha de progressão do Guerreiro

**Armas (espada e broquel).** Mesmo objeto nos 4 tiers; o que sobe é o metal, a luz e o comprimento da lâmina.

| | T0 Recruta | T1 Gélido | T2 Real | T3 Rei Gélido |
|---|---|---|---|---|
| Metal de guarda, pomo, aro e umbo | bronze `C8963F` | prata fria `C4D2E0` | ouro `D8B464` | platina `E6ECF5` |
| Raridade | Comum | Incomum | Raro | Lendário |
| Encaixes acesos | nenhum | fio da lâmina e anel do escudo, `6FE08A` | + gema do pomo e conta do umbo, `5AA8FF` | + barras da guarda e anel do umbo, `FFB13C` |
| Lâmina | 98 cm | 98 cm | 106 cm | 106 cm |

**Armaduras.** A Couraça de Recruta é a base; cada tier soma uma peça e nunca troca a massa (aço `B0AEA8`, tabardo `C23A22`, capa `B3301F`).

| | T0 (Couraça de Recruta) | T1 | T2 | T3 |
|---|---|---|---|---|
| Peça nova | nenhuma | gola de pele `EEF1F6` | ombreiras 10% maiores e crista alta | máscara fechada, 2 lâminas nos ombros, capa 20% mais longa |
| Metal | bronze | prata fria | ouro | platina |

O machado e a Cota de Malha são alternativas do T0: não entram na linha de tiers.

### 01. Espada e Broquel de Caçador

- **id:** `w_start_sword`
- **Nome:** Espada e Broquel de Caçador
- **Classe:** Guerreiro
- **Tipo:** Arma
- **Tier e raridade:** T0 · Comum
- **No jogo:** `weapon_model = sword_shield`, `look_tier = 0`. Espada de uma mão (mão direita) e escudo redondo (mão esquerda): o modelo monta as duas peças e a imagem mostra as duas. Descrição no jogo: "Equilibrada: ataque moderado e defesa extra."
- **Igual nos outros tiers da linha:** É a base da linha. T1, T2 e T3 repetem mesmo ângulo, mesma escala (escudo de 58% da largura, espada a 24° da vertical), lâmina de aço `B0AEA8`, punho de couro `3A2A22`, escudo carmesim `9A2A1F` liso e sem emblema, mesma forma de guarda, pomo, aro e umbo. Muda o metal (guarda, pomo, aro e umbo: bronze neste), a luz dos encaixes (nenhuma aqui) e, no T2, a lâmina 8% mais longa.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a knight's one-handed straight longsword together with its round shield, drawn as one weapon set (the shield is the off-hand half of this weapon). Hunter-soldier gear, clean and well kept, not ceremonial.
COMPOSITION: square canvas. The round shield is on the lower left, face toward the viewer, its diameter about 58 percent of the canvas width, centered about 33 percent from the left and 66 percent from the top. The sword stands in front of the shield's right rim, tilted about 24 degrees clockwise from vertical: pommel near the bottom at about 52 percent from the left and 92 percent from the top, point near the top right at about 90 percent from the left and 8 percent from the top. The sword never covers the shield's central boss.
SWORD: straight double-edged blade of satin steel #B0AEA8 with flat faceted bevels and a low central ridge, about ten times longer than it is wide, ending in a short sharp tip; one plain straight crossguard bar in bronze #C8963F, flat, with square ends, about three times as wide as the blade (a normal sword guard: it is wanted); short smooth grip of dark leather #3A2A22 (no wrapping pattern); round ball pommel in bronze #C8963F. The blade is about 80 percent of the sword's length.
SHIELD: round, about 0.8 m across, shallow dome with 16 flat visible facets, satin crimson lacquer #9A2A1F; a wide flat rim ring in bronze #C8963F; a round central boss in bronze #C8963F about one fifth of the shield's diameter. Nothing painted or engraved on the shield: no emblem, no pattern.
GLOW: Nothing on this item glows. Do not add any glowing line, gem or inlay to the blade, guard, pommel or shield.
```

### 02. Machado Grande de Novato

- **id:** `w_start_axe`
- **Nome:** Machado Grande de Novato
- **Classe:** Guerreiro
- **Tipo:** Arma
- **Tier e raridade:** T0 (arma alternativa) · Comum
- **No jogo:** `weapon_model = greataxe`, `look_tier = 0`. Machado de duas mãos e duas lâminas espelhadas, cabo de couro e colar de bronze. Não tem versões T1 a T3: a linha de tiers do guerreiro é a da espada. Descrição no jogo: "Lento na mão de iniciantes, mas muito mais forte."
- **Igual nos outros tiers da linha:** Não há machado nos outros tiers. Mantenha o aço `B0AEA8` e o bronze `C8963F` do início da linha, para que ele leia como irmão da espada T0.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a great two-handed double-bladed battle axe for a beginner hunter. Plain, sturdy, clean.
COMPOSITION: square canvas. The long straight haft runs from the lower left (butt end at about 38 percent from the left and 92 percent from the top) to the upper right (head center at about 60 percent from the left and 30 percent from the top), tilted about 20 degrees clockwise from vertical. The axe head sits at the very top of the haft, centered on it, and the two blades point sideways, perpendicular to the haft; the head is about 58 percent of the canvas wide.
HEAD: two mirrored broad blades, one on each side of the haft, each a flat plate with a pointed top corner and a pointed bottom corner and a gently convex cutting edge on the outside; the blades flare out from the haft like wide fans, about 0.8 m tip to tip against a haft about 1.15 m long. Satin steel #B0AEA8, flat faceted planes, plain flat faces. A short vertical collar around the haft at the center of the head, in bronze #C8963F.
HAFT: straight round haft in dark leather brown #3A2A22, smooth, no wrapping pattern, no pommel, a plain squared-off end.
GLOW: Nothing glows. No gems, no glowing edges.
```

### 03. Cota de Malha

- **id:** `w_start_mail`
- **Nome:** Cota de Malha
- **Classe:** Guerreiro
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 0 (`look_variant 0`) · Comum
- **No jogo:** Armadura inicial leve. No modelo 3D: ombreira de 2 telhas (sem a média), aço mais escuro `8F8D88`, largura de 0,92 m, telha baixa e cinto em bronze. Descrição no jogo: "Proteção equilibrada."
- **Igual nos outros tiers da linha:** Irmã da Couraça de Recruta: mesmos tabardo `C23A22`, capa `B3301F`, Selo `E0603A`, elmo, cinto e faldas. Muda só a ombreira (2 telhas, não 3), o aço (`8F8D88`) e a largura (7% menor). Atenção: o nome diz malha, mas o 3D é placa facetada, e a imagem segue o 3D (Decisões novas).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a complete suit of a veteran hunter-soldier's heavy plate armor, drawn hollow and floating as if worn by an invisible mannequin: no body, no arms, no legs and no head inside. Front view, perfectly symmetrical, the full set about 1.0 m wide by 1.55 m tall so it fills about 80 percent of the canvas height and about 55 percent of its width, centered. Clean, well kept, sober.
PIECES from top to bottom:
1. Helmet floating just above the neck opening: an open-faced skullcap helm: a low dome of 8 flat facets in satin steel #B0AEA8, two straight rectangular cheek plates hanging down both sides to the jaw line, a nape guard at the back, and a short straight nasal bar in bronze #C8963F that starts at the brim and ends above the mouth line (it hangs from the brim, it does not cross any horizontal bar); the face opening is empty and dark #14141C. On top, a swept-back crimson lacquer fin crest #C23A22 running front to back, low: rising about three quarters of the dome's height above it.
2. Neck ring (gorget): a short ring of darker satin steel #6F6D69.
3. Cuirass: a barrel-chested faceted plate with 8 flat facets and a hard ridge down the sternum, slightly darker satin steel #8F8D88, smooth faceted plates only (this is the lighter 'mail' set: do NOT draw chainmail rings, scales or any ring texture); broad at the shoulders and narrowing to the waist.
4. Shoulders: on each shoulder only two stepped plates (a high one and a low one), the high plate in satin steel #8F8D88 and the low plate in bronze #C8963F; the shoulders are about 7 percent narrower than on the full plate version.
5. Waist and hips: a belt band in bronze #C8963F; below it three stepped rings of overlapping satin steel plates #B0AEA8 (faldas) covering the hips.
6. Tabard: smooth crimson cloth #C23A22 hanging from the belt down the front, about as long as the cuirass is tall, slightly wider at the hem, hem a little uneven, no pattern.
7. Cape: smooth cloth #B3301F in two panels hanging behind the shoulders, visible at both sides of the tabard and below it, reaching about the lower hem of the tabard, no pattern.
CHEST SEAL: in the middle of the chest a round Hunter's Seal: a ring of bronze #C8963F, about 15 percent of the cuirass width across, around a round disc of warm orange-red light #E0603A (moderate glow, hue preserved, never white). It is the only glowing thing in the image.
GLOW: only the chest seal disc glows; no other part of the armor emits light.
```

### 04. Couraça de Recruta

- **id:** `w_start_plate`
- **Nome:** Couraça de Recruta
- **Classe:** Guerreiro
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 1 (`look_variant 1`) · Comum
- **No jogo:** Armadura inicial pesada e base da linha: ombreira de 3 telhas, aço `B0AEA8`, largura de 0,99 m, bronze `C8963F` na telha baixa e no cinto. Descrição no jogo: "Mais defesa, menos velocidade."
- **Igual nos outros tiers da linha:** É a base de T1, T2 e T3: o corpo é o mesmo (couraça, faldas, tabardo `C23A22`, capa `B3301F`, Selo `E0603A`, enquadramento e escala). Soma-se uma peça por tier: gola de pele em T1, ombreira 10% maior e crista alta em T2, máscara, lâminas e capa mais longa em T3.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a complete suit of a veteran hunter-soldier's heavy plate armor, drawn hollow and floating as if worn by an invisible mannequin: no body, no arms, no legs and no head inside. Front view, perfectly symmetrical, the full set about 1.0 m wide by 1.55 m tall so it fills about 80 percent of the canvas height and about 55 percent of its width, centered. Clean, well kept, sober.
PIECES from top to bottom:
1. Helmet floating just above the neck opening: an open-faced skullcap helm: a low dome of 8 flat facets in satin steel #B0AEA8, two straight rectangular cheek plates hanging down both sides to the jaw line, a nape guard at the back, and a short straight nasal bar in bronze #C8963F that starts at the brim and ends above the mouth line (it hangs from the brim, it does not cross any horizontal bar); the face opening is empty and dark #14141C. On top, a swept-back crimson lacquer fin crest #C23A22 running front to back, low: rising about three quarters of the dome's height above it.
2. Neck ring (gorget): a short ring of darker satin steel #6F6D69.
3. Cuirass: a barrel-chested faceted plate with 8 flat facets and a hard ridge down the sternum, satin steel #B0AEA8; broad at the shoulders and narrowing to the waist.
4. Shoulders: on each shoulder three overlapping stepped plates like roof tiles (high, middle, low), satin steel #B0AEA8, the lowest tile edged in bronze #C8963F; they make the widest part of the silhouette, shoulder to shoulder about the full width of the figure.
5. Waist and hips: a belt band in bronze #C8963F; below it three stepped rings of overlapping satin steel plates #B0AEA8 (faldas) covering the hips.
6. Tabard: smooth crimson cloth #C23A22 hanging from the belt down the front, about as long as the cuirass is tall, slightly wider at the hem, hem a little uneven, no pattern.
7. Cape: smooth cloth #B3301F in two panels hanging behind the shoulders, visible at both sides of the tabard and below it, reaching about the lower hem of the tabard, no pattern.
CHEST SEAL: in the middle of the chest a round Hunter's Seal: a ring of bronze #C8963F, about 15 percent of the cuirass width across, around a round disc of warm orange-red light #E0603A (moderate glow, hue preserved, never white). It is the only glowing thing in the image.
GLOW: only the chest seal disc glows; no other part of the armor emits light.
```

### 05. Lâmina Gélida

- **id:** `warrior_t1_weapon`
- **Nome:** Lâmina Gélida
- **Classe:** Guerreiro
- **Tipo:** Arma
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `weapon_model = sword_shield`, `look_tier = 1`. Mesma espada e mesmo escudo do T0, com metal prata fria e 1 encaixe aceso (verde). Descrição no jogo: "Forjada com materiais dos monstros do Portão."
- **Igual nos outros tiers da linha:** Igual ao T0: mesmo ângulo, mesma escala (escudo de 58% da largura, espada a 24° da vertical), lâmina de aço `B0AEA8`, punho de couro `3A2A22`, escudo carmesim `9A2A1F` liso e sem emblema, mesma forma de guarda, pomo, aro e umbo, lâmina de 98 cm. Muda: metal prata `C4D2E0` e fio da lâmina e anel do escudo acesos em `6FE08A`.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a knight's one-handed straight longsword together with its round shield, drawn as one weapon set (the shield is the off-hand half of this weapon). Hunter-soldier gear, clean and well kept, not ceremonial.
COMPOSITION: square canvas. The round shield is on the lower left, face toward the viewer, its diameter about 58 percent of the canvas width, centered about 33 percent from the left and 66 percent from the top. The sword stands in front of the shield's right rim, tilted about 24 degrees clockwise from vertical: pommel near the bottom at about 52 percent from the left and 92 percent from the top, point near the top right at about 90 percent from the left and 8 percent from the top. The sword never covers the shield's central boss.
SWORD: straight double-edged blade of satin steel #B0AEA8 with flat faceted bevels and a low central ridge, about ten times longer than it is wide, ending in a short sharp tip; one plain straight crossguard bar in cold silver #C4D2E0, flat, with square ends, about three times as wide as the blade (a normal sword guard: it is wanted); short smooth grip of dark leather #3A2A22 (no wrapping pattern); round ball pommel in cold silver #C4D2E0. The blade is about 80 percent of the sword's length.
SHIELD: round, about 0.8 m across, shallow dome with 16 flat visible facets, satin crimson lacquer #9A2A1F; a wide flat rim ring in cold silver #C4D2E0; a round central boss in cold silver #C4D2E0 about one fifth of the shield's diameter. Nothing painted or engraved on the shield: no emblem, no pattern.
GLOW: Only these inlays glow in green #6FE08A (moderate intensity, never blown out to white): thin glowing lines #6FE08A following both cutting edges of the blade from the guard to the tip (each line about 1 percent of the canvas wide), and a thin glowing ring #6FE08A lying on the shield's dome just inside the rim. Everything else is unlit.
```

### 06. Couraça Gélida

- **id:** `warrior_t1_armor`
- **Nome:** Couraça Gélida
- **Classe:** Guerreiro
- **Tipo:** Armadura
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. Couraça de Recruta mais a gola de pele branca `EEF1F6`, com metal prata fria `C4D2E0` no cinto e na telha baixa. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Igual ao T0 (Couraça de Recruta): couraça, 3 telhas, faldas, tabardo, capa, Selo, elmo baixo e todo o enquadramento. Muda: gola de pele e prata no lugar do bronze.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a complete suit of a veteran hunter-soldier's heavy plate armor, drawn hollow and floating as if worn by an invisible mannequin: no body, no arms, no legs and no head inside. Front view, perfectly symmetrical, the full set about 1.0 m wide by 1.55 m tall so it fills about 80 percent of the canvas height and about 55 percent of its width, centered. Clean, well kept, sober.
PIECES from top to bottom:
1. Helmet floating just above the neck opening: an open-faced skullcap helm: a low dome of 8 flat facets in satin steel #B0AEA8, two straight rectangular cheek plates hanging down both sides to the jaw line, a nape guard at the back, and a short straight nasal bar in cold silver #C4D2E0 that starts at the brim and ends above the mouth line (it hangs from the brim, it does not cross any horizontal bar); the face opening is empty and dark #14141C. On top, a swept-back crimson lacquer fin crest #C23A22 running front to back, low: rising about three quarters of the dome's height above it.
2. Neck ring (gorget): a short ring of darker satin steel #6F6D69.
3. Cuirass: a barrel-chested faceted plate with 8 flat facets and a hard ridge down the sternum, satin steel #B0AEA8; broad at the shoulders and narrowing to the waist.
3b. Wolf-fur collar #EEF1F6: a low, thick ring of soft off-white fur lying flat on the shoulders around the neck opening, sculpted in a few big clean tufts; it stays low and leaves the chest seal fully visible.
4. Shoulders: on each shoulder three overlapping stepped plates like roof tiles (high, middle, low), satin steel #B0AEA8, the lowest tile edged in cold silver #C4D2E0; they make the widest part of the silhouette, shoulder to shoulder about the full width of the figure.
5. Waist and hips: a belt band in cold silver #C4D2E0; below it three stepped rings of overlapping satin steel plates #B0AEA8 (faldas) covering the hips.
6. Tabard: smooth crimson cloth #C23A22 hanging from the belt down the front, about as long as the cuirass is tall, slightly wider at the hem, hem a little uneven, no pattern.
7. Cape: smooth cloth #B3301F in two panels hanging behind the shoulders, visible at both sides of the tabard and below it, reaching about the lower hem of the tabard, no pattern.
CHEST SEAL: in the middle of the chest a round Hunter's Seal: a ring of cold silver #C4D2E0, about 15 percent of the cuirass width across, around a round disc of warm orange-red light #E0603A (moderate glow, hue preserved, never white). It is the only glowing thing in the image.
GLOW: only the chest seal disc glows; no other part of the armor emits light.
```

### 07. Elmo Gélido

- **id:** `warrior_t1_helm`
- **Nome:** Elmo Gélido
- **Classe:** Guerreiro
- **Tipo:** Elmo
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. É o elmo aberto da ficha com o nasal em prata fria. Não existe elmo T2 nem T3: a cabeça passa a seguir o tier da armadura, e as imagens de armadura já mostram o elmo do tier. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** É o mesmo elmo que aparece na Couraça Gélida (T1): cúpula de 8 facetas em `B0AEA8`, nasal prata, crista baixa `C23A22`. A crista alta e a máscara do T2 e do T3 só aparecem nas imagens das armaduras.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a hunter-soldier's open-faced helmet, floating alone (no head inside), clean and well kept.
COMPOSITION: three-quarter view from the front left, camera slightly above, the helmet about 70 percent of the canvas width, centered, crest included.
HELMET: a low skullcap dome of 8 flat facets in satin steel #B0AEA8; two straight rectangular cheek plates hanging down both sides to the jaw line; a nape guard at the back; a short straight nasal bar in cold silver #C4D2E0 that starts at the brim and ends above the mouth line (it hangs from the brim, it does not cross any horizontal bar). The face opening is empty and dark #14141C.
CREST: a swept-back crimson lacquer fin crest #C23A22 running front to back along the top, low: rising about three quarters of the dome's height above it.
GLOW: nothing glows.
```

### 08. Grevas Gélidas

- **id:** `warrior_t1_boots`
- **Nome:** Grevas Gélidas
- **Classe:** Guerreiro
- **Tipo:** Botas
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. Bota de aço da ficha (cano de 8 lados e pé em bloco). O 3D ainda não muda a bota por tier (`boots_tier` não é usado); a faixa de prata é decisão nova deste documento. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Não há botas T2 nem T3. Ao lado das botas do mago e do sacerdote, mantenha o mesmo molde (cano de 16 cm e pé de 25 cm) e a mesma faixa prata, trocando só a cor do couro ou do aço.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pair of short ankle-high boots for a hunter, drawn as a pair, clean and well kept, the boots of a heavy plate-armored fighter.
COMPOSITION: three-quarter view from the front left, camera slightly above. The two boots stand side by side, the near one slightly in front of the far one, toes pointing to the lower left; the pair fills about 80 percent of the canvas width. No legs, no feet inside.
SHAPE: chunky and simple: an 8-sided faceted shaft about 16 cm tall, a little wider at the top than at the bottom, standing on a blocky foot about 25 cm long, 11 cm wide and 7 cm tall that extends forward past the shaft; no laces, no buckles, no straps.
COLORS: satin faceted steel #B0AEA8 for the whole boot. One thin band of cold silver #C4D2E0 around the top rim of each shaft, about one fifth of the shaft's height. Nothing else is added: no kneecap, no spikes, no fur.
GLOW: nothing glows.
```

### 09. Lâmina Real

- **id:** `warrior_t2_weapon`
- **Nome:** Lâmina Real
- **Classe:** Guerreiro
- **Tipo:** Arma
- **Tier e raridade:** T2 · Raro
- **No jogo:** `weapon_model = sword_shield`, `look_tier = 2`. Espada com lâmina de 1,06 m (8% mais longa), metal ouro `D8B464` e 2 encaixes acesos (azul). Descrição no jogo: "Exige o Núcleo do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: mesmo ângulo, mesma escala (escudo de 58% da largura, espada a 24° da vertical), lâmina de aço `B0AEA8`, punho de couro `3A2A22`, escudo carmesim `9A2A1F` liso e sem emblema, mesma forma de guarda, pomo, aro e umbo. Muda: lâmina 8% mais longa (mesma largura), ouro `D8B464` e, além do fio e do anel do escudo, a gema do pomo e a conta do umbo, todos em `5AA8FF`.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a knight's one-handed straight longsword together with its round shield, drawn as one weapon set (the shield is the off-hand half of this weapon). Hunter-soldier gear, clean and well kept, not ceremonial.
COMPOSITION: square canvas. The round shield is on the lower left, face toward the viewer, its diameter about 58 percent of the canvas width, centered about 33 percent from the left and 66 percent from the top. The sword stands in front of the shield's right rim, tilted about 24 degrees clockwise from vertical: pommel near the bottom at about 52 percent from the left and 94 percent from the top, point near the top right at about 91 percent from the left and 4 percent from the top. The sword never covers the shield's central boss.
SWORD: straight double-edged blade of satin steel #B0AEA8 with flat faceted bevels and a low central ridge, about ten times longer than it is wide, ending in a short sharp tip; one plain straight crossguard bar in gold #D8B464, flat, with square ends, about three times as wide as the blade (a normal sword guard: it is wanted); short smooth grip of dark leather #3A2A22 (no wrapping pattern); round ball pommel in gold #D8B464. The blade is about 80 percent of the sword's length. The blade is slightly longer than a standard one: the whole sword is about 8 percent longer than the bronze and silver versions, with exactly the same blade width.
SHIELD: round, about 0.8 m across, shallow dome with 16 flat visible facets, satin crimson lacquer #9A2A1F; a wide flat rim ring in gold #D8B464; a round central boss in gold #D8B464 about one fifth of the shield's diameter. Nothing painted or engraved on the shield: no emblem, no pattern.
GLOW: Only these inlays glow in blue #5AA8FF (moderate intensity, never blown out to white): thin glowing lines #5AA8FF following both cutting edges of the blade from the guard to the tip (each line about 1 percent of the canvas wide), and a thin glowing ring #5AA8FF lying on the shield's dome just inside the rim; a small glowing round gem #5AA8FF covering the pommel, and a small glowing bead #5AA8FF on top of the shield boss. Everything else is unlit.
```

### 10. Armadura Real

- **id:** `warrior_t2_armor`
- **Nome:** Armadura Real
- **Classe:** Guerreiro
- **Tipo:** Armadura
- **Tier e raridade:** T2 · Raro
- **No jogo:** `look_tier = 2`. Couraça Gélida com ombreiras 10% maiores, crista alta no elmo e metal ouro `D8B464`. Descrição no jogo: "Exige itens raros do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: couraça, gola de pele, faldas, tabardo, capa, Selo, enquadramento. Muda: ouro no lugar da prata, ombreiras 10% maiores e crista com mais que o dobro da altura da cúpula.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a complete suit of a veteran hunter-soldier's heavy plate armor, drawn hollow and floating as if worn by an invisible mannequin: no body, no arms, no legs and no head inside. Front view, perfectly symmetrical, the full set about 1.0 m wide by 1.55 m tall so it fills about 80 percent of the canvas height and about 55 percent of its width, centered. Clean, well kept, sober.
PIECES from top to bottom:
1. Helmet floating just above the neck opening: an open-faced skullcap helm: a low dome of 8 flat facets in satin steel #B0AEA8, two straight rectangular cheek plates hanging down both sides to the jaw line, a nape guard at the back, and a short straight nasal bar in gold #D8B464 that starts at the brim and ends above the mouth line (it hangs from the brim, it does not cross any horizontal bar); the face opening is empty and dark #14141C. On top, a swept-back crimson lacquer fin crest #C23A22 running front to back, tall: rising more than twice the height of the dome above it.
2. Neck ring (gorget): a short ring of darker satin steel #6F6D69.
3. Cuirass: a barrel-chested faceted plate with 8 flat facets and a hard ridge down the sternum, satin steel #B0AEA8; broad at the shoulders and narrowing to the waist.
3b. Wolf-fur collar #EEF1F6: a low, thick ring of soft off-white fur lying flat on the shoulders around the neck opening, sculpted in a few big clean tufts; it stays low and leaves the chest seal fully visible.
4. Shoulders: on each shoulder three overlapping stepped plates like roof tiles (high, middle, low), satin steel #B0AEA8, the lowest tile edged in gold #D8B464; they make the widest part of the silhouette, shoulder to shoulder about the full width of the figure; the shoulder plates are 10 percent larger than the plain version.
5. Waist and hips: a belt band in gold #D8B464; below it three stepped rings of overlapping satin steel plates #B0AEA8 (faldas) covering the hips.
6. Tabard: smooth crimson cloth #C23A22 hanging from the belt down the front, about as long as the cuirass is tall, slightly wider at the hem, hem a little uneven, no pattern.
7. Cape: smooth cloth #B3301F in two panels hanging behind the shoulders, visible at both sides of the tabard and below it, reaching about the lower hem of the tabard, no pattern.
CHEST SEAL: in the middle of the chest a round Hunter's Seal: a ring of gold #D8B464, about 15 percent of the cuirass width across, around a round disc of warm orange-red light #E0603A (moderate glow, hue preserved, never white). It is the only glowing thing in the image.
GLOW: only the chest seal disc glows; no other part of the armor emits light.
```

### 11. Lâmina do Rei Gélido

- **id:** `warrior_t3_weapon`
- **Nome:** Lâmina do Rei Gélido
- **Classe:** Guerreiro
- **Tipo:** Arma
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `weapon_model = sword_shield`, `look_tier = 3`. Mesma lâmina longa do T2 em platina `E6ECF5`, com os 3 encaixes da espada e os 3 do escudo acesos em âmbar. Descrição no jogo: "Arma lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: mesmo ângulo, mesma escala (escudo de 58% da largura, espada a 24° da vertical), lâmina de aço `B0AEA8`, punho de couro `3A2A22`, escudo carmesim `9A2A1F` liso e sem emblema, mesma forma de guarda, pomo, aro e umbo, lâmina de 1,06 m. Muda: platina `E6ECF5` e os 3 encaixes acesos em `FFB13C` (fio, gema do pomo, barras da guarda; anel, conta e anel do umbo no escudo).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a knight's one-handed straight longsword together with its round shield, drawn as one weapon set (the shield is the off-hand half of this weapon). Hunter-soldier gear, clean and well kept, not ceremonial.
COMPOSITION: square canvas. The round shield is on the lower left, face toward the viewer, its diameter about 58 percent of the canvas width, centered about 33 percent from the left and 66 percent from the top. The sword stands in front of the shield's right rim, tilted about 24 degrees clockwise from vertical: pommel near the bottom at about 52 percent from the left and 94 percent from the top, point near the top right at about 91 percent from the left and 4 percent from the top. The sword never covers the shield's central boss.
SWORD: straight double-edged blade of satin steel #B0AEA8 with flat faceted bevels and a low central ridge, about ten times longer than it is wide, ending in a short sharp tip; one plain straight crossguard bar in platinum #E6ECF5, flat, with square ends, about three times as wide as the blade (a normal sword guard: it is wanted); short smooth grip of dark leather #3A2A22 (no wrapping pattern); round ball pommel in platinum #E6ECF5. The blade is about 80 percent of the sword's length. The blade is slightly longer than a standard one: the whole sword is about 8 percent longer than the bronze and silver versions, with exactly the same blade width.
SHIELD: round, about 0.8 m across, shallow dome with 16 flat visible facets, satin crimson lacquer #9A2A1F; a wide flat rim ring in platinum #E6ECF5; a round central boss in platinum #E6ECF5 about one fifth of the shield's diameter. Nothing painted or engraved on the shield: no emblem, no pattern.
GLOW: Only these inlays glow in amber #FFB13C (slightly stronger but still never white): thin glowing lines #FFB13C following both cutting edges of the blade from the guard to the tip (each line about 1 percent of the canvas wide), and a thin glowing ring #FFB13C lying on the shield's dome just inside the rim; a small glowing round gem #FFB13C covering the pommel, and a small glowing bead #FFB13C on top of the shield boss; two thin glowing bars #FFB13C across the face of the crossguard, one above the other, and a glowing ring #FFB13C around the shield boss (about 1.4 times the boss diameter). Everything else is unlit.
```

### 12. Armadura do Rei Gélido

- **id:** `warrior_t3_armor`
- **Nome:** Armadura do Rei Gélido
- **Classe:** Guerreiro
- **Tipo:** Armadura
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `look_tier = 3`. Armadura Real com máscara fechada de visor único, duas lâminas de platina nas ombreiras, capa 20% mais longa e metal platina `E6ECF5`. Sem brilho frio. Descrição no jogo: "Armadura lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: couraça, gola de pele, ombreiras 10% maiores, crista alta, faldas, tabardo, Selo, enquadramento. Muda: platina, máscara no lugar do rosto aberto e do nasal (sem barra vertical, para não formar cruz), 2 lâminas planas nos ombros e capa mais longa.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a complete suit of a veteran hunter-soldier's heavy plate armor, drawn hollow and floating as if worn by an invisible mannequin: no body, no arms, no legs and no head inside. Front view, perfectly symmetrical, the full set about 1.0 m wide by 1.55 m tall so it fills about 80 percent of the canvas height and about 55 percent of its width, centered. Clean, well kept, sober.
PIECES from top to bottom:
1. Helmet floating just above the neck opening: a skullcap helm: a low dome of 8 flat facets in satin steel #B0AEA8, two straight rectangular cheek plates hanging down both sides to the jaw line, a nape guard at the back, and the face fully covered by a smooth blank mask in platinum #E6ECF5 with 10 flat facets: no eyes, no nose, no mouth, only one thin horizontal visor slit in #0C0E14 about 11 percent of the helmet width; there is no vertical bar anywhere on the mask. On top, a swept-back crimson lacquer fin crest #C23A22 running front to back, tall: rising more than twice the height of the dome above it.
2. Neck ring (gorget): a short ring of darker satin steel #6F6D69.
3. Cuirass: a barrel-chested faceted plate with 8 flat facets and a hard ridge down the sternum, satin steel #B0AEA8; broad at the shoulders and narrowing to the waist.
3b. Wolf-fur collar #EEF1F6: a low, thick ring of soft off-white fur lying flat on the shoulders around the neck opening, sculpted in a few big clean tufts; it stays low and leaves the chest seal fully visible.
4. Shoulders: on each shoulder three overlapping stepped plates like roof tiles (high, middle, low), satin steel #B0AEA8, the lowest tile edged in platinum #E6ECF5; they make the widest part of the silhouette, shoulder to shoulder about the full width of the figure; the shoulder plates are 10 percent larger than the plain version.
4b. Two flat angular blades of matte pale platinum #E6ECF5 standing on top of the shoulder plates: each a plain flat tapered plate (not curved), about 11 cm wide at the base and about 32 cm tall (about one third of the shoulder span), tilted about 17 degrees outward, mounted on the shoulders and not on the helmet. They are armor plates: no glow, no ice look, not horns.
5. Waist and hips: a belt band in platinum #E6ECF5; below it three stepped rings of overlapping satin steel plates #B0AEA8 (faldas) covering the hips.
6. Tabard: smooth crimson cloth #C23A22 hanging from the belt down the front, about as long as the cuirass is tall, slightly wider at the hem, hem a little uneven, no pattern.
7. Cape: smooth cloth #B3301F in two panels hanging behind the shoulders, visible at both sides of the tabard and below it, reaching about 20 percent longer than the tabard, clearly below its hem, no pattern.
CHEST SEAL: in the middle of the chest a round Hunter's Seal: a ring of platinum #E6ECF5, about 15 percent of the cuirass width across, around a round disc of warm orange-red light #E0603A (moderate glow, hue preserved, never white). It is the only glowing thing in the image.
GLOW: only the chest seal disc glows; no other part of the armor emits light.
```

## 4. Mago (12 itens)

### Linha de progressão do Mago

**Armas (cajado).** Mesmo cajado nos 4 tiers; o que sobe é o metal, a luz e, no T3, um aro interno.

| | T0 Recruta | T1 Gélido | T2 Real | T3 Rei Gélido |
|---|---|---|---|---|
| Metal do aro | bronze `C8963F` | prata fria `C4D2E0` | ouro `D8B464` | platina `E6ECF5` |
| Raridade | Comum | Incomum | Raro | Lendário |
| Encaixes acesos | nenhum | fio interno do aro, `6FE08A` | + conta na haste, `5AA8FF` | + fio externo do aro, `FFB13C` |
| Forma | aro simples | igual | igual | aro interno concêntrico e núcleo 20% mais baixo |

**Armaduras.** A Túnica de Aprendiz é a base; a massa (ameixa `6E2470`, prata `D5D9E4`, forro azul `4F8DFF`) nunca muda.

| | T0 (Túnica de Aprendiz) | T1 | T2 | T3 |
|---|---|---|---|---|
| Peça nova | nenhuma | barra de pele `EEF1F6` na capa | gola 22% mais alta e 1 foco por lado | 2 focos por lado e casaco 6% mais longo |
| Metal | bronze | prata fria | ouro | platina |

O orbe e o Manto do Novato são alternativas do T0: não entram na linha de tiers.

### 13. Cajado de Aprendiz

- **id:** `m_start_staff`
- **Nome:** Cajado de Aprendiz
- **Classe:** Mago
- **Tipo:** Arma
- **Tier e raridade:** T0 · Comum
- **No jogo:** `weapon_model = staff`, `look_tier = 0`. Haste de 2,1 m com aro de bronze e núcleo oval violeta flutuando dentro. Descrição no jogo: "Foco puro em ataque mágico."
- **Igual nos outros tiers da linha:** É a base da linha. T1 a T3 repetem mesma diagonal (pé em 14%/93%, aro em 74%/22%, a 40° da vertical), haste `2A2038`, aro liso e chato, núcleo oval violeta `8A7BFF` que nunca vira cristal, mesma proporção entre aro e haste. Muda o metal do aro (bronze neste), a luz dos encaixes (nenhuma) e, só no T3, o aro interno.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mage's tall staff topped by a flat ring that holds a floating glowing oval core. Elegant and thin, scholarly, not a shaman's staff: no crystal shards, no spikes, no horns.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 14 percent from the left and 93 percent from the top) to the upper right (ring center at about 74 percent from the left and 22 percent from the top), tilted about 40 degrees clockwise from vertical. The ring faces the viewer, so it shows as a full circle. The shaft is drawn about 20 percent shorter than its true length so the head reads at small sizes; the head proportions are true. The ring's outer diameter is about 20 percent of the canvas width.
SHAFT: straight round shaft in dark plum-black satin lacquer #2A2038, slightly thicker at the foot, plain end, no cap, no wrapping, no ornament.
RING: a smooth flat ring in bronze #C8963F, its width about one quarter of its outer radius, plain, no gems.
CORE: floating in the middle of the ring's hole without touching it, a smooth oval (egg-shaped, taller than wide, about 1.45 times) of soft violet light #8A7BFF; round and smooth, never a crystal, never faceted into points.
GLOW: Only the violet core glows. Nothing else: no glowing ring, bead or inlay.
```

### 14. Orbe Cintilante

- **id:** `m_start_orb`
- **Nome:** Orbe Cintilante
- **Classe:** Mago
- **Tipo:** Arma
- **Tier e raridade:** T0 (arma alternativa) · Comum
- **No jogo:** `weapon_model = orb`, `look_tier = 0`. Esfera de luz violeta com um aro de bronze inclinado, flutuando além dos dedos, sem cabo. Não tem versões T1 a T3. Descrição no jogo: "Mais mana e conjuração mais rápida."
- **Igual nos outros tiers da linha:** Não há orbe nos outros tiers. Mantenha o violeta `8A7BFF` e o bronze `C8963F` do início da linha do cajado, para ler como irmão dele.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mage's floating focus orb with a tilted ring around it. It has no handle and no stand: it hovers on its own.
COMPOSITION: square canvas, the orb centered, the whole object (orb plus ring) about 70 percent of the canvas width.
ORB: a smooth sphere of soft violet light #8A7BFF about 20 cm across at game scale, with a slightly brighter center; round and smooth, no facets, no crystal points. Moderate glow, hue preserved, never white.
RING: one flat thin ring in bronze #C8963F, about 31 cm outer diameter at game scale, circling the orb at a tilt of about 35 degrees, never touching the orb, plain, no gems.
GLOW: only the orb glows. Nothing else is lit, no halo, no particles.
```

### 15. Túnica de Aprendiz

- **id:** `m_start_robe`
- **Nome:** Túnica de Aprendiz
- **Classe:** Mago
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 0 (`look_variant 0`) · Comum
- **No jogo:** Armadura inicial e base da linha: casaco ameixa `6E2470`, capa curta prata `D5D9E4`, gola em duas asas (prata por fora, azul `4F8DFF` por dentro), Selo azul, bronze nos metais. Descrição no jogo: "Tecido encantado que amplia a mana."
- **Igual nos outros tiers da linha:** É a base de T1, T2 e T3: casaco ameixa, capa prata, gola, forro azul, enquadramento e escala. Soma-se uma peça por tier: barra de pele em T1, gola 22% mais alta e 2 focos em T2, 4 focos e casaco mais longo em T3.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a scholar-mage's long open coat with a short pale cape and a tall winged collar, drawn hollow and floating as if worn by an invisible mannequin: no body, no head, no hair, no hands inside. Front view, symmetrical, about 1.5 m tall (collar tip to hem) so it fills about 80 percent of the canvas height. Elegant, thin, upright. No hood, no cowl, no pointed hat.
PIECES:
- Winged collar (the Y shape): two pairs of flat angular wing plates that open outward and upward on both sides of an empty neck opening, each wing about 30 cm wide and 44 cm tall. Outer faces in pale silver lacquer #D5D9E4, inner faces in bright blue lacquer #4F8DFF. The collar is the highest part of the garment and the widest part of the body silhouette (about 60 cm tip to tip).
- Short cape: a smooth round pelerine of pale silver cloth #D5D9E4 covering the shoulders and upper chest; the cape ends at mid-chest. On the front, a round Hunter's Seal: a ring of bronze #C8963F, about 16 cm across at game scale, around a round disc of light #4F8DFF.
- Coat: smooth plum cloth #6E2470, fitted at the torso, opening below the waist into two front panels and one long back panel visible behind them; the front panels end about 13 cm above the floor line. Two thin vertical piping lines of bright blue #4F8DFF run down the inner edges of the front opening, and a dark lining #1B1830 shows through the gap between the panels.
- Belt: a narrow belt band in bronze #C8963F at the waist.
- Sleeves: plum cloth, hanging relaxed beside the torso, hollow, each ending in a wide cuff in pale silver #D5D9E4.
GLOW: The Hunter's Seal disc #4F8DFF glows; nothing else emits light.
```

### 16. Manto do Novato

- **id:** `m_start_cloak`
- **Nome:** Manto do Novato
- **Classe:** Mago
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 1 (`look_variant 1`) · Comum
- **No jogo:** Armadura inicial alternativa: a Túnica de Aprendiz com a capa 12 cm mais longa. Descrição no jogo: "Mais resistente, menos mana."
- **Igual nos outros tiers da linha:** Irmão da Túnica de Aprendiz: mesmo casaco, gola, forro e Selo. Muda só o comprimento da capa prata.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a scholar-mage's long open coat with a short pale cape and a tall winged collar, drawn hollow and floating as if worn by an invisible mannequin: no body, no head, no hair, no hands inside. Front view, symmetrical, about 1.5 m tall (collar tip to hem) so it fills about 80 percent of the canvas height. Elegant, thin, upright. No hood, no cowl, no pointed hat.
PIECES:
- Winged collar (the Y shape): two pairs of flat angular wing plates that open outward and upward on both sides of an empty neck opening, each wing about 30 cm wide and 44 cm tall. Outer faces in pale silver lacquer #D5D9E4, inner faces in bright blue lacquer #4F8DFF. The collar is the highest part of the garment and the widest part of the body silhouette (about 60 cm tip to tip).
- Short cape: a smooth round pelerine of pale silver cloth #D5D9E4 covering the shoulders and upper chest; the cape is about 12 cm longer than the short version, ending at belly height instead of mid-chest. On the front, a round Hunter's Seal: a ring of bronze #C8963F, about 16 cm across at game scale, around a round disc of light #4F8DFF.
- Coat: smooth plum cloth #6E2470, fitted at the torso, opening below the waist into two front panels and one long back panel visible behind them; the front panels end about 13 cm above the floor line. Two thin vertical piping lines of bright blue #4F8DFF run down the inner edges of the front opening, and a dark lining #1B1830 shows through the gap between the panels.
- Belt: a narrow belt band in bronze #C8963F at the waist.
- Sleeves: plum cloth, hanging relaxed beside the torso, hollow, each ending in a wide cuff in pale silver #D5D9E4.
GLOW: The Hunter's Seal disc #4F8DFF glows; nothing else emits light.
```

### 17. Cajado Gélido

- **id:** `mage_t1_weapon`
- **Nome:** Cajado Gélido
- **Classe:** Mago
- **Tipo:** Arma
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `weapon_model = staff`, `look_tier = 1`. Mesmo cajado do T0 com aro de prata fria e 1 encaixe aceso (verde). Descrição no jogo: "Forjada com materiais dos monstros do Portão."
- **Igual nos outros tiers da linha:** Igual ao T0: mesma diagonal (pé em 14%/93%, aro em 74%/22%, a 40° da vertical), haste `2A2038`, aro liso e chato, núcleo oval violeta `8A7BFF` que nunca vira cristal, mesma proporção entre aro e haste. Muda: aro em prata `C4D2E0` e um fio fino aceso em `6FE08A` rente à borda interna do aro.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mage's tall staff topped by a flat ring that holds a floating glowing oval core. Elegant and thin, scholarly, not a shaman's staff: no crystal shards, no spikes, no horns.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 14 percent from the left and 93 percent from the top) to the upper right (ring center at about 74 percent from the left and 22 percent from the top), tilted about 40 degrees clockwise from vertical. The ring faces the viewer, so it shows as a full circle. The shaft is drawn about 20 percent shorter than its true length so the head reads at small sizes; the head proportions are true. The ring's outer diameter is about 20 percent of the canvas width.
SHAFT: straight round shaft in dark plum-black satin lacquer #2A2038, slightly thicker at the foot, plain end, no cap, no wrapping, no ornament.
RING: a smooth flat ring in cold silver #C4D2E0, its width about one quarter of its outer radius, plain, no gems.
CORE: floating in the middle of the ring's hole without touching it, a smooth oval (egg-shaped, taller than wide, about 1.45 times) of soft violet light #8A7BFF; round and smooth, never a crystal, never faceted into points.
GLOW: The violet core #8A7BFF glows (moderate, hue preserved, never white). The rarity inlays glow in green #6FE08A (moderate intensity, never blown out to white): a thin glowing ring #6FE08A hugging the inside edge of the main ring. Everything else is unlit.
```

### 18. Manto Gélido

- **id:** `mage_t1_armor`
- **Nome:** Manto Gélido
- **Classe:** Mago
- **Tipo:** Armadura
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. Túnica de Aprendiz com a barra de pele branca `EEF1F6` na orla da capa e metais em prata fria `C4D2E0`. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Igual ao T0 (Túnica): casaco ameixa, capa prata curta, gola, forro, enquadramento. Muda: barra de pele e prata no lugar do bronze.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a scholar-mage's long open coat with a short pale cape and a tall winged collar, drawn hollow and floating as if worn by an invisible mannequin: no body, no head, no hair, no hands inside. Front view, symmetrical, about 1.5 m tall (collar tip to hem) so it fills about 80 percent of the canvas height. Elegant, thin, upright. No hood, no cowl, no pointed hat.
PIECES:
- Winged collar (the Y shape): two pairs of flat angular wing plates that open outward and upward on both sides of an empty neck opening, each wing about 30 cm wide and 44 cm tall. Outer faces in pale silver lacquer #D5D9E4, inner faces in bright blue lacquer #4F8DFF. The collar is the highest part of the garment and the widest part of the body silhouette (about 60 cm tip to tip).
- Short cape: a smooth round pelerine of pale silver cloth #D5D9E4 covering the shoulders and upper chest; the cape ends at mid-chest. On the front, a round Hunter's Seal: a ring of cold silver #C4D2E0, about 16 cm across at game scale, around a round disc of light #4F8DFF.
- Fur hem: a short band of soft off-white wolf fur #EEF1F6 around the lower edge of the cape, about 7 cm tall at game scale, sculpted in a few clean tufts.
- Coat: smooth plum cloth #6E2470, fitted at the torso, opening below the waist into two front panels and one long back panel visible behind them; the front panels end about 13 cm above the floor line. Two thin vertical piping lines of bright blue #4F8DFF run down the inner edges of the front opening, and a dark lining #1B1830 shows through the gap between the panels.
- Belt: a narrow belt band in cold silver #C4D2E0 at the waist.
- Sleeves: plum cloth, hanging relaxed beside the torso, hollow, each ending in a wide cuff in pale silver #D5D9E4.
GLOW: The Hunter's Seal disc #4F8DFF glows; nothing else emits light.
```

### 19. Diadema Gélido

- **id:** `mage_t1_helm`
- **Nome:** Diadema Gélido
- **Classe:** Mago
- **Tipo:** Elmo
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. O mago não tem elmo na ficha; a cabeça dele é cabelo prateado e a gola. Aparência definida neste documento (Decisões novas): aro fino de prata fria com um mini Selo azul. Não existe diadema T2 nem T3. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Não há diadema nos outros tiers. Mantenha a prata `C4D2E0` do T1 e o azul de classe `4F8DFF`, para combinar com o Manto Gélido e o Cajado Gélido.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a slim circlet (diadem) for a mage, floating alone (no head, no hair), clean and polished.
COMPOSITION: three-quarter view from the front left, camera slightly above, the circlet about 70 percent of the canvas width, centered.
CIRCLET: a thin open band of cold silver #C4D2E0 (satin, flat faceted surface, about 1.2 cm wide at game scale), the shape of a ring about 20 cm across that is open at the back, with its two ends slightly flared. At the center front sits a tiny Hunter's Seal: a small round silver ring with a round disc of bright blue light #4F8DFF inside it. The band has no points, no spikes, no horns and no crown shape: it is a smooth rounded band.
GLOW: only the small blue disc glows (moderate, hue preserved, never white). Nothing else is lit.
```

### 20. Botas Leves Gélidas

- **id:** `mage_t1_boots`
- **Nome:** Botas Leves Gélidas
- **Classe:** Mago
- **Tipo:** Botas
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. Bota de couro ameixa-escuro `2A2038` da ficha; a faixa de prata é decisão nova (o 3D não muda a bota por tier). Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Não há botas T2 nem T3. Mesmo molde das botas do guerreiro e do sacerdote, trocando só a cor do couro.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pair of short ankle-high boots for a hunter, drawn as a pair, clean and well kept, light and slim in feel but keeping the same simple blocky shape.
COMPOSITION: three-quarter view from the front left, camera slightly above. The two boots stand side by side, the near one slightly in front of the far one, toes pointing to the lower left; the pair fills about 80 percent of the canvas width. No legs, no feet inside.
SHAPE: chunky and simple: an 8-sided faceted shaft about 16 cm tall, a little wider at the top than at the bottom, standing on a blocky foot about 25 cm long, 11 cm wide and 7 cm tall that extends forward past the shaft; no laces, no buckles, no straps.
COLORS: dark plum-black satin leather #2A2038 for the whole boot. One thin band of cold silver #C4D2E0 around the top rim of each shaft, about one fifth of the shaft's height. Nothing else is added: no fur, no buckles, no straps.
GLOW: nothing glows.
```

### 21. Cajado Real

- **id:** `mage_t2_weapon`
- **Nome:** Cajado Real
- **Classe:** Mago
- **Tipo:** Arma
- **Tier e raridade:** T2 · Raro
- **No jogo:** `weapon_model = staff`, `look_tier = 2`. Mesmo cajado em ouro `D8B464`, com 2 encaixes acesos (azul). Descrição no jogo: "Exige o Núcleo do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: mesma diagonal (pé em 14%/93%, aro em 74%/22%, a 40° da vertical), haste `2A2038`, aro liso e chato, núcleo oval violeta `8A7BFF` que nunca vira cristal, mesma proporção entre aro e haste. Muda: aro em ouro `D8B464` e, além do fio interno, a conta na haste, os dois em `5AA8FF`.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mage's tall staff topped by a flat ring that holds a floating glowing oval core. Elegant and thin, scholarly, not a shaman's staff: no crystal shards, no spikes, no horns.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 14 percent from the left and 93 percent from the top) to the upper right (ring center at about 74 percent from the left and 22 percent from the top), tilted about 40 degrees clockwise from vertical. The ring faces the viewer, so it shows as a full circle. The shaft is drawn about 20 percent shorter than its true length so the head reads at small sizes; the head proportions are true. The ring's outer diameter is about 20 percent of the canvas width.
SHAFT: straight round shaft in dark plum-black satin lacquer #2A2038, slightly thicker at the foot, plain end, no cap, no wrapping, no ornament.
RING: a smooth flat ring in gold #D8B464, its width about one quarter of its outer radius, plain, no gems.
CORE: floating in the middle of the ring's hole without touching it, a smooth oval (egg-shaped, taller than wide, about 1.45 times) of soft violet light #8A7BFF; round and smooth, never a crystal, never faceted into points.
GLOW: The violet core #8A7BFF glows (moderate, hue preserved, never white). The rarity inlays glow in blue #5AA8FF (moderate intensity, never blown out to white): a thin glowing ring #5AA8FF hugging the inside edge of the main ring; a small glowing bead #5AA8FF on the shaft just below the ring. Everything else is unlit.
```

### 22. Manto Real

- **id:** `mage_t2_armor`
- **Nome:** Manto Real
- **Classe:** Mago
- **Tipo:** Armadura
- **Tier e raridade:** T2 · Raro
- **No jogo:** `look_tier = 2`. Manto Gélido com a gola 22% mais alta, 2 focos flutuantes (aro de ouro `D8B464` e disco violeta `8A7BFF`) e metais em ouro. Descrição no jogo: "Exige itens raros do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: casaco, capa com barra de pele, forro, Selo, enquadramento. Muda: ouro, gola 22% mais alta e 1 foco de cada lado, fora da silhueta do casaco.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a scholar-mage's long open coat with a short pale cape and a tall winged collar, drawn hollow and floating as if worn by an invisible mannequin: no body, no head, no hair, no hands inside. Front view, symmetrical, about 1.5 m tall (collar tip to hem) so it fills about 80 percent of the canvas height. Elegant, thin, upright. No hood, no cowl, no pointed hat.
PIECES:
- Winged collar (the Y shape): two pairs of flat angular wing plates that open outward and upward on both sides of an empty neck opening, each wing about 30 cm wide and 54 cm tall. Outer faces in pale silver lacquer #D5D9E4, inner faces in bright blue lacquer #4F8DFF. The collar is the highest part of the garment and the widest part of the body silhouette (about 60 cm tip to tip). The wings are 22 percent taller than in the plain version.
- Short cape: a smooth round pelerine of pale silver cloth #D5D9E4 covering the shoulders and upper chest; the cape ends at mid-chest. On the front, a round Hunter's Seal: a ring of gold #D8B464, about 16 cm across at game scale, around a round disc of light #4F8DFF.
- Fur hem: a short band of soft off-white wolf fur #EEF1F6 around the lower edge of the cape, about 7 cm tall at game scale, sculpted in a few clean tufts.
- Coat: smooth plum cloth #6E2470, fitted at the torso, opening below the waist into two front panels and one long back panel visible behind them; the front panels end about 13 cm above the floor line. Two thin vertical piping lines of bright blue #4F8DFF run down the inner edges of the front opening, and a dark lining #1B1830 shows through the gap between the panels.
- Belt: a narrow belt band in gold #D8B464 at the waist.
- Sleeves: plum cloth, hanging relaxed beside the torso, hollow, each ending in a wide cuff in pale silver #D5D9E4.
FLOATING FOCI: 2 small floating focus rings hovering in the air beside the garment, not attached to anything, arranged symmetrically about 66 cm from the center line: one focus per side, at chest height. Each is a thin flattened ring in gold #D8B464, about 18 cm across, holding a round lens-shaped disc of violet light #8A7BFF. Round only, no points. They are drawn outside the silhouette of the coat and never touch the collar wings.
GLOW: The Hunter's Seal disc #4F8DFF and the focus discs #8A7BFF glow; nothing else emits light.
```

### 23. Cajado do Rei Gélido

- **id:** `mage_t3_weapon`
- **Nome:** Cajado do Rei Gélido
- **Classe:** Mago
- **Tipo:** Arma
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `weapon_model = staff`, `look_tier = 3`. Mesmo cajado em platina `E6ECF5`, com aro interno extra, núcleo um pouco mais baixo e os 3 encaixes acesos em âmbar. Descrição no jogo: "Arma lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: mesma diagonal (pé em 14%/93%, aro em 74%/22%, a 40° da vertical), haste `2A2038`, aro liso e chato, núcleo oval violeta `8A7BFF` que nunca vira cristal, mesma proporção entre aro e haste. Muda: platina `E6ECF5`, segundo aro concêntrico por dentro, núcleo com 80% da altura e os 3 encaixes acesos em `FFB13C` (fio interno, conta na haste, fio externo).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mage's tall staff topped by a flat ring that holds a floating glowing oval core. Elegant and thin, scholarly, not a shaman's staff: no crystal shards, no spikes, no horns.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 14 percent from the left and 93 percent from the top) to the upper right (ring center at about 74 percent from the left and 22 percent from the top), tilted about 40 degrees clockwise from vertical. The ring faces the viewer, so it shows as a full circle. The shaft is drawn about 20 percent shorter than its true length so the head reads at small sizes; the head proportions are true. The ring's outer diameter is about 20 percent of the canvas width.
SHAFT: straight round shaft in dark plum-black satin lacquer #2A2038, slightly thicker at the foot, plain end, no cap, no wrapping, no ornament.
RING: a smooth flat ring in platinum #E6ECF5, its width about one quarter of its outer radius, plain, no gems.
CORE: floating in the middle of the ring's hole without touching it, a smooth oval (egg-shaped, taller than wide, about 1.45 times) of soft violet light #8A7BFF; round and smooth, never a crystal, never faceted into points.
INNER RING: nested concentric inside the hole of the main ring, in the same plane, a second thinner ring in platinum #E6ECF5, plain and flat. From the outside in, the stack is: the main ring, then the thin glowing line described under GLOW, then this thinner platinum ring, then a visible gap, then the core. The core oval is shortened to about 80 percent of its usual height.
GLOW: The violet core #8A7BFF glows (moderate, hue preserved, never white). The rarity inlays glow in amber #FFB13C (slightly stronger but still never white): a thin glowing ring #FFB13C hugging the inside edge of the main ring; a small glowing bead #FFB13C on the shaft just below the ring; a thin glowing ring #FFB13C hugging the outside edge of the main ring. Everything else is unlit.
```

### 24. Manto do Rei Gélido

- **id:** `mage_t3_armor`
- **Nome:** Manto do Rei Gélido
- **Classe:** Mago
- **Tipo:** Armadura
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `look_tier = 3`. Manto Real com 4 focos, casaco 6% mais longo e metais em platina `E6ECF5`. Sem brilho frio. Descrição no jogo: "Armadura lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: casaco ameixa, capa com barra de pele, gola 22% mais alta, forro, Selo, enquadramento. Muda: platina, 2 focos de cada lado (um a mais por lado) e painéis do casaco mais longos.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a scholar-mage's long open coat with a short pale cape and a tall winged collar, drawn hollow and floating as if worn by an invisible mannequin: no body, no head, no hair, no hands inside. Front view, symmetrical, about 1.5 m tall (collar tip to hem) so it fills about 80 percent of the canvas height. Elegant, thin, upright. No hood, no cowl, no pointed hat.
PIECES:
- Winged collar (the Y shape): two pairs of flat angular wing plates that open outward and upward on both sides of an empty neck opening, each wing about 30 cm wide and 54 cm tall. Outer faces in pale silver lacquer #D5D9E4, inner faces in bright blue lacquer #4F8DFF. The collar is the highest part of the garment and the widest part of the body silhouette (about 60 cm tip to tip). The wings are 22 percent taller than in the plain version.
- Short cape: a smooth round pelerine of pale silver cloth #D5D9E4 covering the shoulders and upper chest; the cape ends at mid-chest. On the front, a round Hunter's Seal: a ring of platinum #E6ECF5, about 16 cm across at game scale, around a round disc of light #4F8DFF.
- Fur hem: a short band of soft off-white wolf fur #EEF1F6 around the lower edge of the cape, about 7 cm tall at game scale, sculpted in a few clean tufts.
- Coat: smooth plum cloth #6E2470, fitted at the torso, opening below the waist into two front panels and one long back panel visible behind them; the front panels reach about 6 percent longer than the plain version, ending a few centimeters above the floor line. Two thin vertical piping lines of bright blue #4F8DFF run down the inner edges of the front opening, and a dark lining #1B1830 shows through the gap between the panels.
- Belt: a narrow belt band in platinum #E6ECF5 at the waist.
- Sleeves: plum cloth, hanging relaxed beside the torso, hollow, each ending in a wide cuff in pale silver #D5D9E4.
FLOATING FOCI: 4 small floating focus rings hovering in the air beside the garment, not attached to anything, arranged symmetrically about 66 cm from the center line: two foci per side: one at chest height and one about 32 cm higher and slightly farther back. Each is a thin flattened ring in platinum #E6ECF5, about 18 cm across, holding a round lens-shaped disc of violet light #8A7BFF. Round only, no points. They are drawn outside the silhouette of the coat and never touch the collar wings.
GLOW: The Hunter's Seal disc #4F8DFF and the focus discs #8A7BFF glow; nothing else emits light.
```

## 5. Sacerdote (12 itens)

### Linha de progressão do Sacerdote

**Armas (cetro-lanterna).** Mesma lanterna nos 4 tiers; o que sobe é o metal, a luz e, no T3, o tamanho.

| | T0 Recruta | T1 Gélido | T2 Real | T3 Rei Gélido |
|---|---|---|---|---|
| Metal da lanterna | bronze `C8963F` | prata fria `C4D2E0` | ouro `D8B464` | platina `E6ECF5` |
| Raridade | Comum | Incomum | Raro | Lendário |
| Encaixes acesos | nenhum | 2 barras, `6FE08A` | + conta na haste, `5AA8FF` | + anel sob a lanterna, `FFB13C` |
| Lanterna | 17% da largura | igual | igual | 18% maior |

O núcleo da lanterna é sempre `FFD76A`, em qualquer tier.

**Armaduras.** A Veste do Noviço é a base; a massa (jade `247050`, creme `E6DCC0`, chapéu `E2D6B6`) nunca muda.

| | T0 (Veste do Noviço) | T1 | T2 | T3 |
|---|---|---|---|---|
| Peça nova | nenhuma | manto curto `D5D9E4` | pingentes largos na aba | aba dupla, 2 fitas de véu, lanterna de cinto |
| Metal | bronze | prata fria | ouro | platina |

O tomo e as Vestes do Peregrino são alternativas do T0: não entram na linha de tiers.

### 25. Cetro do Noviço

- **id:** `p_start_scepter`
- **Nome:** Cetro do Noviço
- **Classe:** Sacerdote
- **Tipo:** Arma
- **Tier e raridade:** T0 · Comum
- **No jogo:** `weapon_model = scepter`, `look_tier = 0`. É um bastão-lanterna: haste de 1,5 m com lanterna hexagonal de bronze e núcleo dourado aceso. Descrição no jogo: "Equilibra ataque e poder de cura."
- **Igual nos outros tiers da linha:** É a base da linha. T1 a T3 repetem mesma diagonal (pé em 16%/92%, lanterna em 72%/26%, a 40° da vertical), haste `2B211B`, lanterna hexagonal com 6 barras e núcleo dourado `FFD76A`, sem corrente nem gancho. Muda o metal da lanterna (bronze neste), a luz dos encaixes (nenhuma) e, no T3, a lanterna 18% maior.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's lantern staff: a long slim shaft topped by a small hexagonal lantern with a lit flame core. It is a lantern, not a religious object.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 16 percent from the left and 92 percent from the top) to the upper right (lantern center at about 72 percent from the left and 26 percent from the top), tilted about 40 degrees clockwise from vertical. The shaft is drawn about 20 percent shorter than its true length so the lantern reads at small sizes; the lantern's proportions are true. The lantern is about 17 percent of the canvas width.
SHAFT: straight round slim shaft in dark brown satin lacquer #2B211B, plain end, no cap, no wrapping, no ornament; there is no horizontal bar anywhere on it except the one ring described below, if any.
LANTERN: a six-sided (hexagonal) cage: a low six-sided pyramid roof, a six-sided base plate, and six thin vertical bars, all in bronze #C8963F; inside, visible between the bars, an oval flame-shaped core of warm gold light #FFD76A, round and smooth, no point. No chain, no handle, no hook.
GLOW: Only the warm flame core #FFD76A glows. All six bars stay unlit, in metal.
```

### 26. Tomo da Vigília

- **id:** `p_start_tome`
- **Nome:** Tomo da Vigília
- **Classe:** Sacerdote
- **Tipo:** Arma
- **Tier e raridade:** T0 (arma alternativa) · Comum
- **No jogo:** `weapon_model = tome`, `look_tier = 0`. Livro aberto, páginas voltadas para quem lê, e uma luz dourada flutuando ao lado da mão. Não tem versões T1 a T3. Descrição no jogo: "Mais mana e cura, menos ataque."
- **Igual nos outros tiers da linha:** Não há tomo nos outros tiers. Mantenha o dourado `FFD76A` da luz, para ler como irmão do cetro.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's open book together with a small floating hand-light, drawn as one item.
COMPOSITION: square canvas. The open book stands upright, pages toward the viewer, centered at about 50 percent from the left and 46 percent from the top, about 66 percent of the canvas wide; its two halves are tilted slightly back like a half-open book (a shallow V). The small floating light is at the lower right, about 12 percent of the canvas wide, hovering free, centered at about 80 percent from the left and 82 percent from the top, not touching the book.
BOOK: two thick covers in dark red-brown #5A2A22 forming a border about 1 cm wide at game scale all around the pages; the pages in warm parchment #E8DFCA, plain and clean, blank (no text, no lines, no drawings, no symbols). A plain thick spine at the center. No clasp, no strap, no metal corners, no ribbon.
LIGHT: a smooth round orb of warm gold light #FFD76A, moderate glow, hue preserved, never white.
GLOW: only the floating orb glows. The book itself is unlit.
```

### 27. Veste do Noviço

- **id:** `p_start_habit`
- **Nome:** Veste do Noviço
- **Classe:** Sacerdote
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 0 (`look_variant 0`) · Comum
- **No jogo:** Armadura inicial e base da linha: túnica jade `247050`, sobreveste e mangas de sino creme `E6DCC0`, saia em sino, faixa e estola de bronze, chapéu `E2D6B6`. Descrição no jogo: "Vestes abençoadas."
- **Igual nos outros tiers da linha:** É a base de T1, T2 e T3: túnica, saia, sobreveste, mangas, Selo dourado e chapéu base. Soma-se uma peça por tier: manto curto em T1, pingentes na aba em T2, aba dupla, fitas e lanterna de cinto em T3.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's vestments: wide hat, jade tunic with a bell skirt, cream bell sleeves, drawn hollow and floating as if worn by an invisible mannequin (no body, no face, no hands, no legs inside). Front view, symmetrical, about 1.9 m tall at game scale, so it fills about 80 percent of the canvas height; the hat and the skirt hem are about the same width, giving an A shape. Calm, plain, dignified. It is not a priest's cassock or a ceremonial robe.
PIECES from top to bottom:
- Hat floating above the neck opening: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in bronze #C8963F around the base of the cone; the underside of the brim is dark brown #3A2E25; a cream skullcap #E6DCC0 sits under it.
- Tunic: smooth jade cloth #247050, fitted at the chest, narrow at the waist, with a low stand collar in cream #E6DCC0.
- Sleeves: jade at the shoulder, then cream #E6DCC0 bell sleeves that flare wide and end in a thin rim in bronze #C8963F; the inside of each sleeve mouth is very dark green #14231F. They hang relaxed beside the torso, hollow.
- Overvest: a short cream bell-shaped tunic #E6DCC0 from the waist to the hip, over the skirt.
- Sash and stole: a sash band in bronze #C8963F at the waist; a single narrow strip (stole) in bronze #C8963F hangs from the sash down the front center, about 11 cm wide, and ends below the sash only (it does not extend above the sash).
- Skirt: smooth jade cloth #247050, a bell shape flaring from the waist to a wide hem about 84 cm across, with a thin hem band in bronze #C8963F, reaching the floor line. No legs, no feet.
CHEST SEAL: on the chest, a round Hunter's Seal: a ring of bronze #C8963F, about 16 cm across at game scale, around a round disc of warm gold light #FFD76A.
GLOW: the gold Seal disc #FFD76A glows; nothing else emits light.
```

### 28. Vestes do Peregrino

- **id:** `p_start_pilgrim`
- **Nome:** Vestes do Peregrino
- **Classe:** Sacerdote
- **Tipo:** Armadura
- **Tier e raridade:** T0, variante 1 (`look_variant 1`) · Comum
- **No jogo:** Armadura inicial alternativa: a Veste do Noviço com um alforje de couro no quadril. Descrição no jogo: "Mais vida para sobreviver na linha de frente."
- **Igual nos outros tiers da linha:** Irmã da Veste do Noviço: mesma túnica, saia, chapéu e Selo. Muda só o alforje de couro `3A2A22` no quadril, do lado direito de quem olha.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's vestments: wide hat, jade tunic with a bell skirt, cream bell sleeves, drawn hollow and floating as if worn by an invisible mannequin (no body, no face, no hands, no legs inside). Front view, symmetrical, about 1.9 m tall at game scale, so it fills about 80 percent of the canvas height; the hat and the skirt hem are about the same width, giving an A shape. Calm, plain, dignified. It is not a priest's cassock or a ceremonial robe.
PIECES from top to bottom:
- Hat floating above the neck opening: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in bronze #C8963F around the base of the cone; the underside of the brim is dark brown #3A2E25; a cream skullcap #E6DCC0 sits under it.
- Tunic: smooth jade cloth #247050, fitted at the chest, narrow at the waist, with a low stand collar in cream #E6DCC0.
- Sleeves: jade at the shoulder, then cream #E6DCC0 bell sleeves that flare wide and end in a thin rim in bronze #C8963F; the inside of each sleeve mouth is very dark green #14231F. They hang relaxed beside the torso, hollow.
- Overvest: a short cream bell-shaped tunic #E6DCC0 from the waist to the hip, over the skirt.
- Sash and stole: a sash band in bronze #C8963F at the waist; a single narrow strip (stole) in bronze #C8963F hangs from the sash down the front center, about 11 cm wide, and ends below the sash only (it does not extend above the sash).
- Satchel: a small flat leather pouch #3A2A22 (about 16 cm wide and 12 cm tall at game scale, thin) hanging at the hip on the viewer's right, with no buckle detail.
- Skirt: smooth jade cloth #247050, a bell shape flaring from the waist to a wide hem about 84 cm across, with a thin hem band in bronze #C8963F, reaching the floor line. No legs, no feet.
CHEST SEAL: on the chest, a round Hunter's Seal: a ring of bronze #C8963F, about 16 cm across at game scale, around a round disc of warm gold light #FFD76A.
GLOW: the gold Seal disc #FFD76A glows; nothing else emits light.
```

### 29. Cetro Gélido

- **id:** `priest_t1_weapon`
- **Nome:** Cetro Gélido
- **Classe:** Sacerdote
- **Tipo:** Arma
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `weapon_model = scepter`, `look_tier = 1`. Mesmo bastão-lanterna do T0 com lanterna de prata fria e 1 encaixe aceso (verde). Descrição no jogo: "Forjada com materiais dos monstros do Portão."
- **Igual nos outros tiers da linha:** Igual ao T0: mesma diagonal (pé em 16%/92%, lanterna em 72%/26%, a 40° da vertical), haste `2B211B`, lanterna hexagonal com 6 barras e núcleo dourado `FFD76A`, sem corrente nem gancho. Muda: lanterna em prata `C4D2E0` e 2 das 6 barras acesas em `6FE08A`, em lados opostos.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's lantern staff: a long slim shaft topped by a small hexagonal lantern with a lit flame core. It is a lantern, not a religious object.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 16 percent from the left and 92 percent from the top) to the upper right (lantern center at about 72 percent from the left and 26 percent from the top), tilted about 40 degrees clockwise from vertical. The shaft is drawn about 20 percent shorter than its true length so the lantern reads at small sizes; the lantern's proportions are true. The lantern is about 17 percent of the canvas width.
SHAFT: straight round slim shaft in dark brown satin lacquer #2B211B, plain end, no cap, no wrapping, no ornament; there is no horizontal bar anywhere on it except the one ring described below, if any.
LANTERN: a six-sided (hexagonal) cage: a low six-sided pyramid roof, a six-sided base plate, and six thin vertical bars, all in cold silver #C4D2E0; inside, visible between the bars, an oval flame-shaped core of warm gold light #FFD76A, round and smooth, no point. No chain, no handle, no hook.
GLOW: The warm flame core #FFD76A glows (moderate, hue preserved, never white). The rarity inlays glow in green #6FE08A (moderate intensity, never blown out to white): two of the six lantern bars, on opposite sides, glow in green #6FE08A. Everything else is unlit.
```

### 30. Vestes Gélidas

- **id:** `priest_t1_armor`
- **Nome:** Vestes Gélidas
- **Classe:** Sacerdote
- **Tipo:** Armadura
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. Veste do Noviço com o manto curto prata `D5D9E4` sobre os ombros (o Selo fica por cima dele) e metais em prata fria `C4D2E0`. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Igual ao T0 (Veste do Noviço): túnica, saia, sobreveste, mangas, chapéu base e enquadramento. Muda: manto curto e prata no lugar do bronze.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's vestments: wide hat, jade tunic with a bell skirt, cream bell sleeves, drawn hollow and floating as if worn by an invisible mannequin (no body, no face, no hands, no legs inside). Front view, symmetrical, about 1.9 m tall at game scale, so it fills about 80 percent of the canvas height; the hat and the skirt hem are about the same width, giving an A shape. Calm, plain, dignified. It is not a priest's cassock or a ceremonial robe.
PIECES from top to bottom:
- Hat floating above the neck opening: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in cold silver #C4D2E0 around the base of the cone; the underside of the brim is dark brown #3A2E25; a cream skullcap #E6DCC0 sits under it.
- Tunic: smooth jade cloth #247050, fitted at the chest, narrow at the waist, with a low stand collar in cream #E6DCC0.
- Short mantle: a smooth round pelerine of pale silver cloth #D5D9E4 over the shoulders and upper chest, ending at about chest height; the Hunter's Seal sits in front of it, on top.
- Sleeves: jade at the shoulder, then cream #E6DCC0 bell sleeves that flare wide and end in a thin rim in cold silver #C4D2E0; the inside of each sleeve mouth is very dark green #14231F. They hang relaxed beside the torso, hollow.
- Overvest: a short cream bell-shaped tunic #E6DCC0 from the waist to the hip, over the skirt.
- Sash and stole: a sash band in cold silver #C4D2E0 at the waist; a single narrow strip (stole) in cold silver #C4D2E0 hangs from the sash down the front center, about 11 cm wide, and ends below the sash only (it does not extend above the sash).
- Skirt: smooth jade cloth #247050, a bell shape flaring from the waist to a wide hem about 84 cm across, with a thin hem band in cold silver #C4D2E0, reaching the floor line. No legs, no feet.
CHEST SEAL: on the chest, a round Hunter's Seal: a ring of cold silver #C4D2E0, about 16 cm across at game scale, around a round disc of warm gold light #FFD76A.
GLOW: the gold Seal disc #FFD76A glows; nothing else emits light.
```

### 31. Chapéu Gélido

- **id:** `priest_t1_helm`
- **Nome:** Chapéu Gélido
- **Classe:** Sacerdote
- **Tipo:** Elmo
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. É o chapéu largo da ficha, com a fita em prata fria. Não existe chapéu T2 nem T3: os pingentes e a aba dupla vêm junto da armadura. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** É o mesmo chapéu que aparece nas Vestes Gélidas (T1): aba de 90 cm, cone baixo `E2D6B6`, fita prata. Pingentes (T2) e aba dupla (T3) só aparecem nas imagens das armaduras.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's wide traveling hat, floating alone (no head), clean and well kept.
COMPOSITION: front view with the camera slightly above (about 15 degrees), the hat about 85 percent of the canvas width, centered.
HAT: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in cold silver #C4D2E0 around the base of the cone; the underside of the brim, visible at the front edge, is dark brown #3A2E25; a cream skullcap #E6DCC0 is just visible under the brim at the center. Smooth surface, no pattern, no embroidery. It has no point, no tiara shape and no band across the front.
GLOW: nothing glows.
```

### 32. Botas Gélidas

- **id:** `priest_t1_boots`
- **Nome:** Botas Gélidas
- **Classe:** Sacerdote
- **Tipo:** Botas
- **Tier e raridade:** T1 · Incomum
- **No jogo:** `look_tier = 1`. O sacerdote não tem pernas nem botas no 3D (a saia cobre tudo, J5). Aparência definida neste documento: o mesmo molde das outras classes, em couro `3A2A22`, com a faixa de prata. Descrição no jogo: "Peça do conjunto Gélido."
- **Igual nos outros tiers da linha:** Não há botas T2 nem T3. Mesmo molde das botas do guerreiro e do mago, trocando só a cor do couro.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pair of short ankle-high boots for a hunter, drawn as a pair, clean and well kept, plain walking boots for a pilgrim guide, same simple blocky shape.
COMPOSITION: three-quarter view from the front left, camera slightly above. The two boots stand side by side, the near one slightly in front of the far one, toes pointing to the lower left; the pair fills about 80 percent of the canvas width. No legs, no feet inside.
SHAPE: chunky and simple: an 8-sided faceted shaft about 16 cm tall, a little wider at the top than at the bottom, standing on a blocky foot about 25 cm long, 11 cm wide and 7 cm tall that extends forward past the shaft; no laces, no buckles, no straps.
COLORS: dark brown satin leather #3A2A22 for the whole boot. One thin band of cold silver #C4D2E0 around the top rim of each shaft, about one fifth of the shaft's height. Nothing else is added: no fur, no buckles, no straps, no laces.
GLOW: nothing glows.
```

### 33. Cetro Real

- **id:** `priest_t2_weapon`
- **Nome:** Cetro Real
- **Classe:** Sacerdote
- **Tipo:** Arma
- **Tier e raridade:** T2 · Raro
- **No jogo:** `weapon_model = scepter`, `look_tier = 2`. Mesmo bastão-lanterna com lanterna de ouro `D8B464` e 2 encaixes acesos (azul). Descrição no jogo: "Exige o Núcleo do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: mesma diagonal (pé em 16%/92%, lanterna em 72%/26%, a 40° da vertical), haste `2B211B`, lanterna hexagonal com 6 barras e núcleo dourado `FFD76A`, sem corrente nem gancho. Muda: ouro `D8B464` e, além das 2 barras acesas, a conta na haste, tudo em `5AA8FF`.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's lantern staff: a long slim shaft topped by a small hexagonal lantern with a lit flame core. It is a lantern, not a religious object.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 16 percent from the left and 92 percent from the top) to the upper right (lantern center at about 72 percent from the left and 26 percent from the top), tilted about 40 degrees clockwise from vertical. The shaft is drawn about 20 percent shorter than its true length so the lantern reads at small sizes; the lantern's proportions are true. The lantern is about 17 percent of the canvas width.
SHAFT: straight round slim shaft in dark brown satin lacquer #2B211B, plain end, no cap, no wrapping, no ornament; there is no horizontal bar anywhere on it except the one ring described below, if any.
LANTERN: a six-sided (hexagonal) cage: a low six-sided pyramid roof, a six-sided base plate, and six thin vertical bars, all in gold #D8B464; inside, visible between the bars, an oval flame-shaped core of warm gold light #FFD76A, round and smooth, no point. No chain, no handle, no hook.
GLOW: The warm flame core #FFD76A glows (moderate, hue preserved, never white). The rarity inlays glow in blue #5AA8FF (moderate intensity, never blown out to white): two of the six lantern bars, on opposite sides, glow in blue #5AA8FF; a small glowing bead #5AA8FF on the shaft about one lantern-width below the lantern. Everything else is unlit.
```

### 34. Vestes Reais

- **id:** `priest_t2_armor`
- **Nome:** Vestes Reais
- **Classe:** Sacerdote
- **Tipo:** Armadura
- **Tier e raridade:** T2 · Raro
- **No jogo:** `look_tier = 2`. Vestes Gélidas com 2 pingentes largos pendurados na aba do chapéu e metais em ouro `D8B464`. O corpo não muda além do metal. Descrição no jogo: "Exige itens raros do Rei Gélido."
- **Igual nos outros tiers da linha:** Igual ao T1: túnica, manto curto, saia, sobreveste, mangas e enquadramento. Muda: ouro e os 2 pingentes de fio e gota na aba.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's vestments: wide hat, jade tunic with a bell skirt, cream bell sleeves, drawn hollow and floating as if worn by an invisible mannequin (no body, no face, no hands, no legs inside). Front view, symmetrical, about 1.9 m tall at game scale, so it fills about 80 percent of the canvas height; the hat and the skirt hem are about the same width, giving an A shape. Calm, plain, dignified. It is not a priest's cassock or a ceremonial robe.
PIECES from top to bottom:
- Hat floating above the neck opening: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in gold #D8B464 around the base of the cone; the underside of the brim is dark brown #3A2E25; a cream skullcap #E6DCC0 sits under it; two pendants hang from the brim edge, one on each side: a very thin wire about 20 cm long in gold #D8B464 ending in a teardrop bead (about 12 cm wide, a little taller than wide) in gold #D8B464; they hang straight down, clear of the face area.
- Tunic: smooth jade cloth #247050, fitted at the chest, narrow at the waist, with a low stand collar in cream #E6DCC0.
- Short mantle: a smooth round pelerine of pale silver cloth #D5D9E4 over the shoulders and upper chest, ending at about chest height; the Hunter's Seal sits in front of it, on top.
- Sleeves: jade at the shoulder, then cream #E6DCC0 bell sleeves that flare wide and end in a thin rim in gold #D8B464; the inside of each sleeve mouth is very dark green #14231F. They hang relaxed beside the torso, hollow.
- Overvest: a short cream bell-shaped tunic #E6DCC0 from the waist to the hip, over the skirt.
- Sash and stole: a sash band in gold #D8B464 at the waist; a single narrow strip (stole) in gold #D8B464 hangs from the sash down the front center, about 11 cm wide, and ends below the sash only (it does not extend above the sash).
- Skirt: smooth jade cloth #247050, a bell shape flaring from the waist to a wide hem about 84 cm across, with a thin hem band in gold #D8B464, reaching the floor line. No legs, no feet.
CHEST SEAL: on the chest, a round Hunter's Seal: a ring of gold #D8B464, about 16 cm across at game scale, around a round disc of warm gold light #FFD76A.
GLOW: the gold Seal disc #FFD76A glows; nothing else emits light.
```

### 35. Cetro do Rei Gélido

- **id:** `priest_t3_weapon`
- **Nome:** Cetro do Rei Gélido
- **Classe:** Sacerdote
- **Tipo:** Arma
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `weapon_model = scepter`, `look_tier = 3`. Mesmo bastão-lanterna, lanterna 18% maior em platina `E6ECF5`, com os 3 encaixes acesos em âmbar. Descrição no jogo: "Arma lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: mesma diagonal (pé em 16%/92%, lanterna em 72%/26%, a 40° da vertical), haste `2B211B`, lanterna hexagonal com 6 barras e núcleo dourado `FFD76A`, sem corrente nem gancho. Muda: platina `E6ECF5`, lanterna 18% maior e os 3 encaixes acesos em `FFB13C` (2 barras, conta na haste, anel sob a lanterna). O núcleo segue dourado `FFD76A`, igual ao do comum.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's lantern staff: a long slim shaft topped by a small hexagonal lantern with a lit flame core. It is a lantern, not a religious object.
COMPOSITION: square canvas. The staff runs from the lower left (foot at about 16 percent from the left and 92 percent from the top) to the upper right (lantern center at about 72 percent from the left and 26 percent from the top), tilted about 40 degrees clockwise from vertical. The shaft is drawn about 20 percent shorter than its true length so the lantern reads at small sizes; the lantern's proportions are true. The lantern is about 20 percent of the canvas width. The lantern is 18 percent larger than the plain version.
SHAFT: straight round slim shaft in dark brown satin lacquer #2B211B, plain end, no cap, no wrapping, no ornament; there is no horizontal bar anywhere on it except the one ring described below, if any.
LANTERN: a six-sided (hexagonal) cage: a low six-sided pyramid roof, a six-sided base plate, and six thin vertical bars, all in platinum #E6ECF5; inside, visible between the bars, an oval flame-shaped core of warm gold light #FFD76A, round and smooth, no point. No chain, no handle, no hook.
GLOW: The warm flame core #FFD76A glows (moderate, hue preserved, never white). The rarity inlays glow in amber #FFB13C (slightly stronger but still never white): two of the six lantern bars, on opposite sides, glow in amber #FFB13C; a small glowing bead #FFB13C on the shaft about one lantern-width below the lantern; a thin glowing ring #FFB13C encircling the shaft directly under the lantern base. Everything else is unlit.
```

### 36. Vestes do Rei Gélido

- **id:** `priest_t3_armor`
- **Nome:** Vestes do Rei Gélido
- **Classe:** Sacerdote
- **Tipo:** Armadura
- **Tier e raridade:** T3 · Lendário
- **No jogo:** `look_tier = 3`. Vestes Reais com aba dupla, 2 fitas de véu, lanterna de cinto e metais em platina `E6ECF5`. Sem brilho frio. Descrição no jogo: "Armadura lendária do Portão Gélido."
- **Igual nos outros tiers da linha:** Igual ao T2: túnica, manto curto, saia, sobreveste, mangas, pingentes, enquadramento. Muda: platina, segunda aba menor sobre a primeira, 2 fitas creme e a lanterna de cinto.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a pilgrim-guide's vestments: wide hat, jade tunic with a bell skirt, cream bell sleeves, drawn hollow and floating as if worn by an invisible mannequin (no body, no face, no hands, no legs inside). Front view, symmetrical, about 1.9 m tall at game scale, so it fills about 80 percent of the canvas height; the hat and the skirt hem are about the same width, giving an A shape. Calm, plain, dignified. It is not a priest's cassock or a ceremonial robe.
PIECES from top to bottom:
- Hat floating above the neck opening: a very wide low conical hat: a flat brim about 90 cm across rising into a shallow cone about 20 cm tall with a tiny rounded peak, in satin cream-sand lacquer #E2D6B6; a thin band in platinum #E6ECF5 around the base of the cone; the underside of the brim is dark brown #3A2E25; a cream skullcap #E6DCC0 sits under it; on top of the first cone sits a second, smaller flat hat about 44 cm across and 13 cm tall, same cream-sand lacquer, stacked like a second roof, with no pointed tip and no band across its front; two pendants hang from the brim edge, one on each side: a very thin wire about 20 cm long in platinum #E6ECF5 ending in a teardrop bead (about 12 cm wide, a little taller than wide) in platinum #E6ECF5; they hang straight down, clear of the face area; two thin cream ribbons #E6DCC0 (about 7 cm wide and 50 cm long at game scale) hang down at the sides of the neck opening, behind the head position.
- Tunic: smooth jade cloth #247050, fitted at the chest, narrow at the waist, with a low stand collar in cream #E6DCC0.
- Short mantle: a smooth round pelerine of pale silver cloth #D5D9E4 over the shoulders and upper chest, ending at about chest height; the Hunter's Seal sits in front of it, on top.
- Sleeves: jade at the shoulder, then cream #E6DCC0 bell sleeves that flare wide and end in a thin rim in platinum #E6ECF5; the inside of each sleeve mouth is very dark green #14231F. They hang relaxed beside the torso, hollow.
- Overvest: a short cream bell-shaped tunic #E6DCC0 from the waist to the hip, over the skirt.
- Sash and stole: a sash band in platinum #E6ECF5 at the waist; a single narrow strip (stole) in platinum #E6ECF5 hangs from the sash down the front center, about 11 cm wide, and ends below the sash only (it does not extend above the sash).
- Belt lantern: a small hexagonal lantern (about 14 cm tall at game scale) hanging at the hip on the viewer's right, frame in platinum #E6ECF5, with a round warm gold flame core #FFD76A glowing inside.
- Skirt: smooth jade cloth #247050, a bell shape flaring from the waist to a wide hem about 84 cm across, with a thin hem band in platinum #E6ECF5, reaching the floor line. No legs, no feet.
CHEST SEAL: on the chest, a round Hunter's Seal: a ring of platinum #E6ECF5, about 16 cm across at game scale, around a round disc of warm gold light #FFD76A.
GLOW: the gold Seal disc #FFD76A and the small belt lantern core #FFD76A glow; nothing else emits light.
```

## 6. Materiais (7 itens)

### 37. Osso Antigo

- **id:** `mat_bone`
- **Nome:** Osso Antigo
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Comum
- **No jogo:** Cai do Esqueleto (Sentinela Óssea). Descrição no jogo: "Osso de morto-vivo, resistente ao frio." Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** Irmão visual da Presa Rachada: mesmo marfim fosco, mesmas facetas simples e mesma luz.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one single long bone from an undead warrior, a crafting material.
COMPOSITION: three-quarter view from slightly above, the bone laid diagonally from the lower left to the upper right, about 85 percent of the canvas along its diagonal, centered.
SHAPE: a thick, chunky, femur-like bone with a straight shaft and two knobbed ends (each end made of two rounded lobes), simplified into flat facets (about 10 visible facets) so it reads as a clean game asset. One hairline crack runs across the shaft near one end, drawn as a thin darker line.
COLORS AND MATERIAL: aged ivory #C9C3AE with shaded facets #9A937E and lit facets #DDD7C2. Matte (like dry chalk), no gloss, no wetness. Pale and clean: no dirt, no blood, no moss, no flesh.
GLOW: nothing glows.
```

### 38. Trapo Congelado

- **id:** `mat_cloth`
- **Nome:** Trapo Congelado
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Comum
- **No jogo:** Cai do Goblin Gélido e da Sentinela Óssea. Descrição no jogo: "Tecido duro de gelo, ainda útil." Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** Pano liso e fosco como o do equipamento, mas endurecido: não deve parecer um tecido de herói (sem Selo, sem debrum).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one folded scrap of coarse cloth frozen stiff, a crafting material.
COMPOSITION: three-quarter view from slightly above, the scrap lying slightly tilted, centered, about 80 percent of the canvas width.
SHAPE: a roughly rectangular piece of cloth folded in three or four angular, rigid creases like stiff cardboard; the edges are ragged with two or three triangular tears and a couple of short loose threads. Simple flat planes, about 8 visible facets.
COLORS AND MATERIAL: weathered goblin-cloth brown #5A4232 with lit planes #7A5C46 and shaded planes #3A2A22; a thin dusting of pale frost #C8D6E4 only along the upper edges of the folds (a light crust, not crystals, not icicles). Matte.
GLOW: nothing glows.
```

### 39. Essência Gélida

- **id:** `mat_essence`
- **Nome:** Essência Gélida
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Incomum
- **No jogo:** Cai do Golem de Cristal e do Xamã do Inverno. Descrição no jogo: "Magia condensada dos xamãs." Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** É o único material que acende, e acende pouco: a cor é a do cajado do xamã `7FD4FF`, sem aura. Não use esta cor em nenhuma peça de herói.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a droplet of condensed magical essence, a crafting material.
COMPOSITION: front view, the droplet floating in the center, about 65 percent of the canvas height, with a short curl of thin vapor under it.
SHAPE: a smooth rounded teardrop (an egg-like orb with a soft tip pointing up), glassy-smooth, slightly translucent, with a brighter heart inside; under it a short, thin, curling tail of dark navy vapor #2C3E5E that ends in two small curls.
COLORS: body pale cyan #7FD4FF, bright heart #CFF1FF, rim of the droplet slightly deeper #4F9FCF. The vapor is #2C3E5E. Clean and simple, no sparkles, no particles around it.
GLOW: the droplet is softly self-lit (moderate, hue preserved, never white), with a bloom of only a few pixels; no aura, no halo.
```

### 40. Presa Rachada

- **id:** `mat_fang`
- **Nome:** Presa Rachada
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Comum
- **No jogo:** Cai do Goblin Gélido e do Lobo de Gelo. Descrição no jogo: "Tirada de goblins e lobos. Base de armas simples." Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** Mesmo marfim fosco do Osso Antigo, mas mais claro e mais liso, para as duas se separarem a 46 px pela forma (osso reto e grosso, presa curva e pontuda).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one single large cracked canine fang from a wolf or goblin, a crafting material. (This is the one item in this set where a fang is wanted: the fang restriction in the negative block does not apply here.)
COMPOSITION: three-quarter view from slightly above, the fang laid diagonally, root at the lower left and the tip at the upper right, about 85 percent of the canvas along its diagonal, centered.
SHAPE: one curved, tapering canine tooth with a sharp tip and a broad flat-cut root, simplified into about 8 flat facets; a clean angular crack runs along it from the root for about one third of its length, splitting off one small triangular flake that is still attached, drawn as a thin darker zig-zag line.
COLORS AND MATERIAL: ivory #DCD4BC with lit facets #E8E4D4 and cool shaded facets #B9B6A8; crack line #8C846E. Matte-satin, like polished bone, no wetness. Clean: no blood, no dirt.
GLOW: nothing glows.
```

### 41. Couro Gélido

- **id:** `mat_hide`
- **Nome:** Couro Gélido
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Incomum
- **No jogo:** Cai do Lobo de Gelo. Descrição no jogo: "Pele de lobo das neves." É a pele branca de lobo do troféu de T1 do guia. Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** O mesmo branco `EEF1F6` da gola de pele do guerreiro T1 e da barra de pele do mago T1: a pele da imagem tem que ser reconhecida como a mesma das armaduras.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one tanned wolf pelt, a crafting material.
COMPOSITION: top-down view tilted about 30 degrees, the pelt lying flat and slightly curled at one corner, centered, about 85 percent of the canvas width.
SHAPE: the rough outline of a wolf hide: a body shape with four short leg stubs and a short tail, edges slightly curled, sculpted as soft fur masses in large clean tufts (not individual hairs). One corner folds over to show the leather underside.
COLORS AND MATERIAL: snow-white fur #EEF1F6 on most of it, a grey-blue saddle #8EA3B8 along the back, shaded tufts #C8D6E4; the folded underside is leather #3A2A22. Fur is soft and matte. Clean: no blood, no dirt, no stains.
GLOW: nothing glows.
```

### 42. Ferro Negro

- **id:** `mat_ore`
- **Nome:** Ferro Negro
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Incomum
- **No jogo:** Cai do Golem de Cristal e do Rei Gélido. Descrição no jogo: "Minério arrancado do corpo dos golens." Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** É o material escuro da coleção: precisa de luz de borda para não sumir sobre o fundo verde da raridade incomum.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one chunk of black iron ore, a crafting material.
COMPOSITION: three-quarter view from slightly above, the nugget sitting centered, about 75 percent of the canvas width.
SHAPE: a chunky angular lump with 8 to 10 large flat planes, a blunt top and a rough broken base, a narrow vein of cold steel running across one face. Simple and heavy.
COLORS AND MATERIAL: dark blue-black #1E242E for the shaded planes, lit planes #3F4D62, thin pale-steel edge highlights #9FB8D0 along the upper left edges, the vein in satin steel #B0AEA8. Matte, no wetness, no crystals, no sparkle. Clean: no rust, no dirt, no soot.
GLOW: nothing glows.
```

### 43. Fragmento de Cristal

- **id:** `mat_shard`
- **Nome:** Fragmento de Cristal
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material
- **Tier e raridade:** — · Raro
- **No jogo:** Cai do Golem de Cristal e do Rei Gélido. Descrição no jogo: "Coração de um golem de elite." Este item não tem ícone próprio nos dados (`icon` fica no valor padrão `crystal`). Material de monstro: sem versão por tier. Aparência definida neste documento (Decisões novas), com as cores das criaturas de `creature_factory.gd`.
- **Igual nos outros tiers da linha:** É o cristal do Golem: a mesma família de cor do Núcleo do Rei Gélido e do Estilhaço da Coroa, só que bruto e sem engaste. Cristal só em material, nunca em arma ou armadura de herói.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: one jagged crystal fragment, the heart of an elite crystal golem, a crafting material. (This is a monster material: the crystal here is wanted, and the restriction about crystals in the negative block does not apply to this item.)
COMPOSITION: three-quarter view from slightly above, the crystal standing upright, slightly tilted, centered, about 75 percent of the canvas height.
SHAPE: an elongated faceted crystal with 5 or 6 large flat planes, a sharp pointed top and a rough broken base; at the broken base a small cap of grey rock #5E6A78 still clings to it.
COLORS AND MATERIAL: deep blue body #2673CC with darker shaded planes #1B4F94, lit planes #6FB6F2 and pale rim light #B9E6FF along the edges; hard faceted planes, low reflections, not a mirror, not a white sparkle. Clean.
GLOW: a subtle inner glow (moderate, hue preserved, never white); no aura, no particles. The crystal must keep a dark enough body and a bright rim so that it stays readable over a mid-blue background.
```

## 7. Poções (2 itens)

### 44. Poção de Vida

- **id:** `potion_hp`
- **Nome:** Poção de Vida
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Consumível
- **Tier e raridade:** — · Comum
- **No jogo:** Recupera 45% da vida (`restores_hp_ratio = 0.45`). Descrição no jogo: "Recupera 45% da vida." Aparência definida neste documento: frasco bojudo, líquido carmesim.
- **Igual nos outros tiers da linha:** Mesmo vidro, mesma rolha, mesmo colar de bronze e mesma luz da Poção de Mana. Muda a forma do frasco (aqui, redondo e baixo) e o líquido (carmesim).

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a healing potion in a squat round-bellied glass flask, a consumable.
COMPOSITION: front view, perfectly upright, centered, the flask about 80 percent of the canvas height.
SHAPE: a wide round body (about as wide as it is tall) with a short narrow neck; the glass is cut with 8 to 10 flat facets so it matches the game's faceted look; a plain cork stopper in #A8835A with a thin leather cord #3A2A22 wound twice around the neck; a thin collar of bronze #C8963F where the neck meets the body.
COLORS AND MATERIAL: clear glass tinted pale #D5D9E4 at the edges; liquid filling about 70 percent of the body, crimson #C23A22 with lit facets #E8745E and a small bright highlight; the level line is a clean straight edge. No label, no text, no emblem, no heart, no plus sign, no cross, no drops, no splash.
GLOW: the liquid is faintly self-lit (low intensity, hue preserved, never white); no aura, no bubbles floating outside.
```

### 45. Poção de Mana

- **id:** `potion_mp`
- **Nome:** Poção de Mana
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Consumível
- **Tier e raridade:** — · Comum
- **No jogo:** Recupera 45% da mana (`restores_mp_ratio = 0.45`). Descrição no jogo: "Recupera 45% da mana." Aparência definida neste documento: frasco alto e fino, líquido azul.
- **Igual nos outros tiers da linha:** Mesmo vidro, mesma rolha, mesmo colar de bronze e mesma luz da Poção de Vida. Muda a forma do frasco (aqui, alto e cônico) e o líquido (azul `4F8DFF`), para as duas se distinguirem pela forma e não só pela cor.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a mana potion in a tall slim conical glass vial, a consumable.
COMPOSITION: front view, perfectly upright, centered, the vial about 85 percent of the canvas height and about 45 percent of its width.
SHAPE: a tall teardrop-cone body widening to a flat base, with a long narrow neck; the glass is cut with 8 to 10 flat facets so it matches the game's faceted look; a plain cork stopper in #A8835A with a thin leather cord #3A2A22 wound twice around the neck; a thin collar of bronze #C8963F where the neck meets the body.
COLORS AND MATERIAL: clear glass tinted pale #D5D9E4 at the edges; liquid filling about 70 percent of the body, bright blue #4F8DFF with lit facets #8FBBFF and a small bright highlight; the level line is a clean straight edge. No label, no text, no emblem, no star, no cross, no drops, no splash.
GLOW: the liquid is faintly self-lit (low intensity, hue preserved, never white); no aura, no bubbles floating outside.
```

## 8. Itens de chefe (3 itens)

### 46. Núcleo do Rei Gélido

- **id:** `boss_core`
- **Nome:** Núcleo do Rei Gélido
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material (item de chefe)
- **Tier e raridade:** — (ingrediente da forja T2) · Raro
- **No jogo:** Item do Rei Gélido Vargoth. Aparência definida neste documento (Decisões novas) com as cores do chefe em `creature_factory.gd`: placa `3F4D62`, aço pálido `9FB8D0`, cristal azul. Descrição no jogo: "Item raro de chefe. Essencial para a forja Real."
- **Igual nos outros tiers da linha:** Mesma família de cor do Fragmento de Cristal e do Estilhaço da Coroa. Este é redondo e engastado em anéis; o Fragmento é bruto e pontudo; a Coroa é um arco.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: the core of the Frost King, a boss crafting item: a faceted crystal heart floating inside three thin orbiting rings. (This is a boss material: the crystal here is wanted, and the restriction about crystals in the negative block does not apply to this item.)
COMPOSITION: front view, the heart centered, the whole object (heart plus rings) about 78 percent of the canvas width.
HEART: a round, roughly spherical crystal with 14 to 16 large flat facets (like a cut gem, no points), deep blue body #246BB8 with lit facets #5AA8E8 and pale rim light #A6EBFF on the edges.
RINGS: three thin flat rings of satin pale steel #9FB8D0 circling the heart at three different tilts, never touching it, plain, no gems, no engraving, like a gyroscope.
GLOW: the heart has a subtle inner glow (moderate, hue preserved, never white); no aura, no particles, no light rays.
```

### 47. Placa Real Congelada

- **id:** `boss_plate`
- **Nome:** Placa Real Congelada
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material (item de chefe)
- **Tier e raridade:** — (ingrediente da forja T3) · Épico
- **No jogo:** Item do Rei Gélido Vargoth. Aparência definida neste documento (Decisões novas) com as cores do chefe em `creature_factory.gd`: placa `3F4D62`, aço pálido `9FB8D0`, cristal azul. Descrição no jogo: "Item épico de chefe. Pedaço da armadura do Rei."
- **Igual nos outros tiers da linha:** É o mesmo aço azul-escuro da armadura do chefe, e não o aço claro `B0AEA8` do herói: não pode parecer peça do Guerreiro.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a broken piece of the Frost King's armor, a boss crafting item: a curved fragment of plate.
COMPOSITION: three-quarter view from slightly above, the plate lying tilted, centered, about 80 percent of the canvas width.
SHAPE: a curved faceted plate fragment (like a piece of pauldron or breastplate) about twice as wide as it is tall, with 6 to 8 large flat facets; one long edge is finished with a thin rolled rim in pale steel #9FB8D0; the opposite edge is a ragged, torn fracture with 3 or 4 angular notches and a lighter inner edge #6F7F96; two round rivets in pale steel #9FB8D0 near the finished edge.
COLORS AND MATERIAL: dark blue-steel #3F4D62 with lit facets #5B6B85 and shaded facets #1A2029; satin metal with low reflections, never chrome. A thin dusting of pale frost #C8D6E4 only along the upper edges (a light crust, no icicles, no crystals, no spikes).
GLOW: nothing glows.
```

### 48. Estilhaço da Coroa

- **id:** `boss_crown`
- **Nome:** Estilhaço da Coroa
- **Classe:** Nenhuma (qualquer classe)
- **Tipo:** Material (item de chefe)
- **Tier e raridade:** — (ingrediente de maior raridade) · Lendário
- **No jogo:** Item do Rei Gélido Vargoth. Aparência definida neste documento (Decisões novas) com as cores do chefe em `creature_factory.gd`: placa `3F4D62`, aço pálido `9FB8D0`, cristal azul. Descrição no jogo: "Item lendário. Só cai em Portões de Rank D."
- **Igual nos outros tiers da linha:** Mesma família de cor do Núcleo e do Fragmento. O fio de ouro `D8B464` é o mesmo ouro do T2, e o aço pálido `9FB8D0` é o aço da coroa do chefe.

Prompt (cole entre o bloco de estilo e o bloco de restrições):

```text
ITEM: a broken fragment of the Frost King's crown, a boss crafting item: an arc of crown band with two crystal points. (This is a boss material: the crystal points here are wanted, and the restrictions about crystals and spikes in the negative block do not apply to this item.)
COMPOSITION: three-quarter view from slightly above, the fragment lying tilted, centered, about 80 percent of the canvas width.
SHAPE: about a quarter of a circle of a wide crown band (curved, thick, faceted, with a flat top edge), with two crystal points rising from the top edge, both leaning the same direction, one taller than the other; one end of the arc is cleanly finished, the other end is a jagged fracture showing a darker interior #3F4D62. Nothing forms a cross or a plus sign.
COLORS AND MATERIAL: the band in satin pale steel #9FB8D0 with lit facets #C9D8E6; one thin inlay line in gold #D8B464 running along the middle of the band; crystal points in deep blue #2673CC with pale rim light #B9E6FF; hard faceted planes, low reflections, never chrome.
GLOW: the two crystal points have a subtle inner glow (moderate, hue preserved, never white); no aura, no particles, no light rays.
```

## Decisões novas

O guia não cobre ilustração 2D nem vários dos itens abaixo. Estas decisões valem só para este documento e não alteram o guia. Se alguma virar regra, ela entra no guia com data e motivo na seção 13.

1. **Formato: 1024 × 1024, 1:1, PNG com alfa.** O motivo é que a UI tinge o fundo por raridade (`UiKit.rarity_color`), e a ilustração é reduzida a 46 e 64 px (`inventory_view.gd`). Fundo transparente também deixa o mesmo arquivo servir ao inventário, à forja e ao saguão.
2. **A ilustração é a versão de saguão do mesmo objeto, não uma reinterpretação.** Mesma silhueta, mesmas peças, mesmas proporções e mesmas cores da ficha. Liberdades permitidas: acabamento pintado mais rico que o 3D, contorno fino na cor do próprio objeto (3 px, nunca preto) para ler a 46 px, e haste de cajado e de cetro 20% mais curta para a cabeça da arma aparecer em tamanho pequeno. Proibido: peça, gema, gravura ou símbolo que a ficha não tem.
3. **Tolerância de cor da ilustração: matiz a até 15° e L* a até 10 pontos do hex.** Vem do critério V4, que mede a massa na sala a 15°. Aqui não há sala, então o valor também ganha limite.
4. **Brilho da raridade desenhado só nos encaixes das armas.** O guia (P5 e P6) diz que a raridade acende os encaixes da arma e do escudo, e o modelo 3D faz isso. A imagem repete: fio, gema e peças acesas na cor exata de `LootDrop.RARITY_COLORS`, sem aura, sem halo e sem moldura. O comum não acende nada. Armadura, elmo e botas não têm encaixe e não brilham por raridade. O Selo e o núcleo de classe brilham em qualquer raridade, porque são cor de classe (V3).
5. **Armadura = conjunto vestido sem corpo, com a peça de cabeça do tier.** O `HeroLook` faz a cabeça seguir `max(tier da armadura, tier do elmo)` (P3), e só existe elmo T1: nos T2 e T3 o elmo, o chapéu e a máscara só aparecem junto da armadura. Por isso toda armadura de guerreiro e de sacerdote mostra o elmo ou o chapéu do próprio tier, flutuando sobre o pescoço, e a do mago mostra a gola, que é a peça de cabeça dele. Braços e pernas não aparecem, exceto as mangas do mago e do sacerdote, que fazem parte da veste.
6. **Cota de Malha desenhada em placa facetada.** O nome diz malha, mas o 3D (variante 0) é placa lisa em aço `8F8D88`, e o guia proíbe textura de sujeira ou de superfície (pilar 5). A imagem segue o 3D, sem anéis de cota. Se o usuário quiser anéis, é uma mudança de modelo e de guia, não de prompt.
7. **Elmo Gélido do guerreiro = o elmo aberto da ficha, com nasal prata.** Sem peça nova: a ficha não dá outra. O nasal desce da aba e para acima da boca, para não formar cruz com a aba (O2).
8. **Diadema Gélido do mago = aro fino aberto em prata fria `C4D2E0`, com um mini Selo azul `4F8DFF` na frente.** O mago não tem peça de cabeça no 3D (cabelo e gola). O mini Selo repete a assinatura do jogo (O3). Se um dia ele entrar no modelo, tem de ficar fora do volume do rosto de P8 (o aro encosta no limite de `y .2` da cabeça) e não pode virar coroa nem ter ponta.
9. **Botas Gélidas = molde único das três classes** (cano de 8 lados de 16 cm sobre pé em bloco de 25 × 11 × 7 cm, da base comum, seção 10 do guia), com 1 faixa de prata fria no topo do cano. Cor: aço `B0AEA8` no guerreiro, `2A2038` no mago, e `3A2A22` no sacerdote. O 3D ainda não muda a bota por tier (`boots_tier` não é lido nos modelos) e o sacerdote nem tem botas visíveis (J5). A cor do couro do sacerdote é nova: o guia só dá o couro `3A2A22`.
10. **Materiais de monstro: aparência definida aqui, pelas cores das criaturas.** O guia não descreve loot. Osso `C9C3AE` (esqueleto), presa `DCD4BC` e `E8E4D4` (goblin e lobo), pele de lobo `EEF1F6` e `8EA3B8` (lobo, e o troféu de T1 do guia), trapo `5A4232` com geada `C8D6E4` (goblin), essência `7FD4FF` (cajado do xamã), ferro negro `1E242E` e `3F4D62` (placa do chefe), cristal `2673CC` e borda `B9E6FF` (golem). Todos fosco e limpo, sem sujeira. Só a Essência e o Cristal acendem, pouco (os itens de chefe seguem a decisão 12).
11. **Poções: dois frascos de forma diferente** (redondo e baixo, carmesim `C23A22`; alto e cônico, azul `4F8DFF`), com rolha `A8835A`, cordão de couro `3A2A22` e colar de bronze `C8963F`. A forma separa as duas para quem não distingue vermelho de azul (pilar 1). Sem cruz, sem "+" e sem coração, porque o "+" de saúde é cruz pela regra O2. A rolha `A8835A` é cor nova.
12. **Itens de chefe com a paleta do Rei Gélido** (`creature_factory.gd`): placa `3F4D62`, aço pálido `9FB8D0`, cristal `246BB8` com borda `A6EBFF`, mais o ouro do rei `D8B464` da seção 9 no fio da coroa. São material, não equipamento de herói, então o cristal é permitido; a regra B6 (nada de gelo emissivo em armadura de herói) continua valendo para os 36 itens de classe.
13. **Fallback de fundo: verde puro `#00FF00`**, para ferramentas sem alfa. Escolhido por não existir em nenhuma paleta do jogo.

### Observações para outras frentes (nada foi alterado)

- Os ícones de dados `hood` (`mage_t1_helm`, `priest_t1_helm`) usam o nome de uma peça que o guia proíbe em herói (S3, sem capuz). As imagens novas não têm capuz. Quem trocar o campo `icon` deve escolher outro nome.
- `mat_shard` não define `icon` e cai no padrão `crystal`.
- `boots_tier` não é lido por nenhum modelo de herói: as botas T1 não mudam o 3D. A faixa prata só existe na imagem.

## Lista de conferência

Para cada imagem gerada, marque tudo antes de aprovar. Uma falha em qualquer linha da seção A reprova a imagem. A seção B vale para as linhas de tier e é feita com os quatro itens lado a lado.

**A. Por imagem**

- [ ] 1024 × 1024, fundo realmente transparente (sem quadriculado desenhado, sem fundo cinza, sem borda de cor ao redor).
- [ ] Um item só, centrado, ocupando cerca de 80% do quadro, sem cortes, margem de 9% ou mais.
- [ ] Sem texto, número, runa, marca d'água, assinatura, moldura, cartão, aura, halo, brilho de raridade, partícula ou sombra no chão.
- [ ] Sem cruz de nenhum tipo (latina, grega, "+", cruz em aro, duas barras em ângulo reto), sem crescente, estrela de Davi, om, roda, torii, yin-yang, mitra nem casula (O2). Confira o elmo (nasal contra a aba), a máscara do T3, a guarda da espada, a estola contra a faixa do sacerdote e o livro. A guarda reta da espada e a estola que só pende abaixo da faixa são aceitas.
- [ ] Sem capuz, chifre, espinho, presa ou garra em arma, armadura ou veste. Sem gelo, estalactite, cristal azul ou olho aceso em equipamento de herói (B2, B6, S3). As duas lâminas planas do ombro do T3 do guerreiro são placas de platina: se lerem como chifre curvo, regere.
- [ ] Nada de Perfect World ou Solo Leveling, nem de outro jogo ou anime reconhecível.
- [ ] Acabamento limpo: sem sujeira, ferrugem, arranhão, ruído de textura, cromado nem reflexo molhado.
- [ ] Cores conferidas com conta-gotas: matiz a até 15° e L* a até 10 pontos de cada hex do prompt. Sem preto nem branco puros.
- [ ] Só brilha o que o prompt manda, na cor exata, sem lavar para branco.
- [ ] Sem peça, gema, gravura ou ornamento que o item não tem. O que o prompt lista está presente.
- [ ] Reduzida a 64 px e a 46 px, a silhueta se reconhece e a parte que define o item ainda aparece.
- [ ] Posta sobre um fundo escuro tingido de cada cor de raridade (`C8D0DC`, `6FE08A`, `5AA8FF`, `C07AFF`, `FFB13C`, a 25% sobre `10141C`), ela continua legível. Cuidado especial com o cristal e a Poção de Mana sobre o azul `5AA8FF`, com o Ferro Negro sobre o verde `6FE08A` e com a platina `E6ECF5` sobre o cinza `C8D0DC`.
- [ ] Bate com o 3D da ficha: mesma forma e mesmas peças da classe (letra T, Y ou A mantida: ombreiras largas, gola em duas asas, chapéu em disco).

**B. Por linha de tier (4 itens lado a lado, a 64 px)**

- [ ] Armas: mesmo ângulo, mesma escala e mesmo objeto; a ordem T0, T1, T2, T3 se lê pelo metal (bronze, prata, ouro, platina) e pelo número de encaixes acesos (0, 1, 2, 3), nessa ordem.
- [ ] Armaduras: mesmo enquadramento, mesma massa de cor (V2) e uma peça nova por tier, empilhada sobre as anteriores.
- [ ] A cor da raridade nos encaixes é a da UI: verde `6FE08A` no T1, azul `5AA8FF` no T2, âmbar `FFB13C` no T3.
- [ ] Nenhum tier quebra a silhueta da classe (S5): o T3 só reforça a forma.
- [ ] Guerreiro T0 e Cota de Malha se distinguem pela ombreira de 2 telhas; Mago T0 e Manto do Novato pelo comprimento da capa; Sacerdote T0 e Peregrino pelo alforje.
