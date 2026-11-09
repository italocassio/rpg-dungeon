# OS-023: Arte de itens e de habilidades na UI

- **Agente:** `gameplay-developer`
- **Depende de:** nenhuma ordem. As imagens e a OS-020 (ícones do sacerdote) já estão prontas.
- **Arquivos:**
  - código: `src/ui/ui_kit.gd`, `src/ui/hud/skill_slot.gd`, `src/ui/hud/hotbar.gd`, `src/ui/panels/inventory_view.gd`, `src/ui/panels/forge_view.gd`, `src/ui/panels/skill_card.gd`, `src/ui/panels/skill_tree_view.gd`, `src/ui/lobby/lobby.gd`;
  - testes: `tests/unit_tests.gd` e a cena nova `tests/visual/icon_review.tscn` com `icon_review.gd`;
  - arte: `assets/icons/items/`, `assets/icons/skills/`, `documents/art/item_art/` (com `.gdignore`); somem `assets/item_art/` e `assets/icons/skill_gpt_image/`.
- **Fora do escopo:** `data/` inteiro (nenhum `.tres` muda), `src/rpg/data/skill_data.gd` e `src/rpg/data/item_data.gd` (outra sessão edita o primeiro), `tests/flow_test.gd` (outra sessão), os SVG de `assets/icons/` (ficam todos, são o plano B), os ícones de classe (`party_frames.gd`, `player_frame.gd`, `lobby.gd:147` e `lobby.gd:401`), o ícone `shield` da Guarda (botão direito), o 3D e qualquer arte nova. Não faça `git add`, `commit` nem `stash`.

## Contexto

O usuário gerou as ilustrações dos dois documentos de prompts (`documents/art/prompts/itens_gpt_image.md` e `habilidades_gpt_image.md`). A direção de arte revisou as 67 imagens (seção final de cada documento). Nada no código as usa ainda: a UI desenha os SVG brancos de `assets/icons/`, tingidos por `UiKit.icon_tile` e por `SkillSlot`.

A arte de **item** é colorida e não pode ser tingida. A arte de **habilidade** é um glifo cinza, feito para ser multiplicado por `skill.color.lightened(0,3)` no `SkillSlot` e por `lightened(0,25)` no `icon_tile`, como o SVG de hoje.

## Veredito das 67 imagens

| Grupo | Veredito | Entram na cópia do jogo |
|---|---|---|
| 48 itens (`assets/item_art/`) | 47 APROVADO, 1 AJUSTES (`priest_t2_armor`, névoa clara fraca acima do chapéu) | os 48 |
| 19 habilidades (`assets/icons/skill_gpt_image/`) | 16 APROVADO, 1 AJUSTES (`w_monarch`, o anel escuro lê como "Ø"), 2 REPROVADO | 17 |

REPROVADO: `w_whirl` lê como ícone de atualizar e `w_warcry` lê como ícone de volume. As duas **não** vão para `assets/icons/skills/`: o jogo usa o `whirl.svg` e o `shout.svg` até o usuário regerar (prompts revisados em `habilidades_gpt_image.md`). Mova os dois PNGs para `documents/art/item_art/rejeitadas/`.

## Decisões de arquitetura (fechadas, na ordem)

1. **A arte se acha pelo `id`, não pelo campo `icon`.** Item: `assets/icons/items/<item.id>.png`. Habilidade: `assets/icons/skills/<skill.id>.png`, e `dodge.png` para a Esquiva. Se o arquivo não existe, a UI cai no SVG de hoje (`UiKit.icon(item.icon)`, `UiKit.icon(skill.icon)`), com o comportamento de hoje, incluindo a tinta. Nenhum `.tres` muda.
2. **Pastas e tamanhos.** Itens em 256 × 256 (redução Lanczos das de 1024), habilidades em 128 × 128 (as atuais, movidas). As originais de 1024 vão para `documents/art/item_art/`, com um `.gdignore` vazio, para o editor não importar 48 texturas de 1024.
3. **Importação das novas com `mipmaps/generate=true`**, lossless, e os controles que as desenham usam `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. Sem isso a arte serrilha na redução de 128 e 256 px para 27 a 64 px.
4. **Arte de item é colorida: desenhada sem modulação (branco).** A cor da raridade fica só no fundo e na borda do quadro. **Arte de habilidade é cinza: continua multiplicada por `skill.color`.**
5. **Quem usa o quê.** Itens: `inventory_view.gd`, `forge_view.gd`, `lobby.gd:293`. Habilidades: `hotbar.gd` (com a Esquiva), `skill_tree_view.gd`, `skill_card.gd`, `lobby.gd:204`. As poções Q e X do hotbar passam a usar a arte de `potion_hp` e `potion_mp`, sem tinta.
6. **Um teste confere a cobertura** (seção "Teste"), com as exceções nomeadas.

## Decisões de arte, em números

### Quadro do item colorido

Conferido em renders de 46, 28 e 64 px sobre as cinco cores de raridade, inclusive o cristal e a Poção de Mana sobre o azul `5AA8FF`: **o fundo de hoje basta** (`cor × 0,16`, alfa 0,95, borda de 1 px na cor da raridade, raio 3). O fundo é escuro o bastante para o azul do cristal e o vermelho da poção se separarem, e a borda de 1 px não encosta na arte. O que muda é só a margem:

| Onde | Quadro | Margem do ícone | Arte |
|---|---|---|---|
| Item colorido em `icon_tile` | qualquer | **8%** de cada lado (era 14%) | 84% do quadro |
| Espaço de equipamento | 46 px | 8% | 38,6 px |
| Cartão de item do saguão | 54 px | 8% | 45,4 px |
| Cabeçalho da forja | 64 px | 8% | 53,8 px |
| Ingrediente da forja | 28 px | 8% | 23,5 px |
| Grade do inventário (`Button`) | 58 px | `icon_max_width` **46** (era 40) | 46 px |
| Lista de receitas da forja (`Button`) | linha | `icon_max_width` **28** (era 24) | 28 px |

Por que 8%: a arte já tem de 2% a 14% de vazio por dentro (as armaduras altas chegam a 96% a 98% da altura), então a margem de 14% a encolhia sem ganho, e a de 8% deixa ainda 5 px de folga a 46 px. O cabo fino do cajado e do cetro ganha 14% de tamanho e a cabeça lê melhor a 46 px.

Glifo de habilidade em `icon_tile` (saguão 38 px, cartão 46 px) e o SVG de plano B ficam com a margem de **14%** de hoje: a arte de habilidade já traz 6% a 12% de vazio e vira cerca de 27 px e 33 px.

### Slot de habilidade (58 px)

O `SkillSlot` já tem `area.grow(-8)`, ou seja, um retângulo de 42 px. Os glifos ocupam de 88% a 95% do quadro de 128 px, então o desenho chega a 37 a 40 px, com cerca de 9 px de folga até a borda. **Sem ajuste de margem**: mantenha `8.0`, num campo `icon_inset`. Um inset menor aumentaria a sobreposição com a tecla (13 px no canto superior esquerdo) e com o número da recarga (20 px no centro), que os prompts já evitam.

### Espaço de equipamento vazio

Hoje é o ícone `cloth` com `modulate.a = 0.35`. Passa a ser **a silhueta do tipo de peça**, com os SVG que já existem, no quadro de 46 px e borda `BRONZE_DARK` como hoje, com alfa **0,5** (o 0,35 apagava a silhueta):

| Espaço | Ícone SVG |
|---|---|
| Arma | `starter_weapons[0].icon` da classe (`sword`, `staff` ou `scepter`) |
| Elmo | `helm` |
| Armadura | `starter_armors[0].icon` da classe (`armor` ou `robe`) |
| Botas | `boots` |

Não use `hood` em nenhum espaço (capuz é forma de inimigo, S3). O texto "Vazio" e o rótulo do tipo não mudam.

## Trabalho

### 1. Conversão e cópia dos arquivos

Num diretório descartável fora do projeto, rode um script Python (Pillow) e depois mova os arquivos. Pillow premultiplica o alfa ao reduzir RGBA, então não sai halo escuro nas bordas.

```python
import os
from PIL import Image
SRC = "assets/item_art"
DST = "assets/icons/items"
os.makedirs(DST, exist_ok=True)
for name in sorted(os.listdir(SRC)):
    if not name.endswith(".png"):
        continue
    im = Image.open(os.path.join(SRC, name)).convert("RGBA")
    r, g, b, a = im.split()
    a = a.point(lambda v: 0 if v <= 12 else v)      # ruído de alfa de 1 a 12, invisível, sai
    im = Image.merge("RGBA", (r, g, b, a)).resize((256, 256), Image.LANCZOS)
    im.save(os.path.join(DST, name), optimize=True)
```

1. Depois da conversão e de conferir 48 arquivos de 256 × 256, mova as originais: `mkdir -p documents/art/item_art && mv assets/item_art/*.png documents/art/item_art/ && touch documents/art/item_art/.gdignore`. Remova `assets/item_art/` inteira, com os `.import`.
2. Habilidades: `mkdir -p assets/icons/skills`, e copie para lá os 17 PNG de `assets/icons/skill_gpt_image/`, **menos** `w_whirl.png` e `w_warcry.png`, que vão para `documents/art/item_art/rejeitadas/`. Remova `assets/icons/skill_gpt_image/` inteira, com os `.import`. Se o Godot importar o cinza com alfa (LA) errado (a imagem aparecer toda opaca ou preta no render), converta os 17 para RGBA com o cinza replicado: `Image.open(p).convert("RGBA").save(p)`.
3. Nenhum SVG de `assets/icons/` é apagado ou editado.

### 2. Importação

Escreva o `.import` de cada PNG novo **antes** do PNG (o editor aberto do usuário pode varrer a pasta no meio do caminho), com este conteúdo, trocando `<caminho>`. O Godot preenche `uid`, `path` e `dest_files` sozinho:

```
[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://<caminho>.png"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
```

Os parâmetros são os dos `.import` que o editor gerou para `assets/item_art/`, com só `mipmaps/generate` trocado para `true`. Se o editor ou o `--import` não aceitar o `.import` sem `uid` e `path`, rode `godot --headless --import --path .` **numa cópia**, troque `mipmaps/generate=false` por `true` nos `.import` gerados, reimporte e copie os `.import` de volta. Confira nos dois casos: `grep -L "mipmaps/generate=true" assets/icons/items/*.import assets/icons/skills/*.import` não lista nada.

Não mude `project.godot` (nada de `importer_defaults`): os outros PNG do projeto, como o `noise.png` dos shaders, não devem ganhar mipmaps.

### 3. `UiKit` (`src/ui/ui_kit.gd`)

Nomes e contrato. O corpo é seu; a lista é o que as telas e o teste usam.

```gdscript
const ITEM_ART_DIR := "res://assets/icons/items/"
const SKILL_ART_DIR := "res://assets/icons/skills/"
const ITEM_ART_SIZE := Vector2i(256, 256)
const SKILL_ART_SIZE := Vector2i(128, 128)
const ART_FILTER := CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
const GLYPH_PADDING := 0.14   # o de hoje
const ITEM_ART_PADDING := 0.08

static func item_art(item_id: StringName) -> Texture2D        # null se não houver arquivo
static func skill_art(skill_id: StringName) -> Texture2D      # null se não houver arquivo
static func item_icon(item: ItemData) -> Texture2D            # arte do id, senão icon(item.icon)
static func skill_icon(skill: SkillData) -> Texture2D         # arte do id, senão icon(skill.icon)
static func item_tile(item: ItemData, size: float) -> PanelContainer
static func skill_tile(skill: SkillData, size: float) -> PanelContainer
static func empty_slot_tile(icon_id: StringName, size: float) -> PanelContainer
static func set_button_icon(button: Button, item: ItemData, tint: Color, art_width: int, svg_width: int) -> void
```

- `item_art` e `skill_art` seguem o padrão de `icon()`: carregam com `ResourceLoader.exists`, guardam em cache, inclusive o `null`.
- `icon_tile(icon_id, tint, size)` **não muda de assinatura nem de resultado** (os ícones de classe usam). Extraia o miolo para um `_tile(texture, tint, size, modulate_color, padding, filtered)`.
- `item_tile`: com arte, `_tile(art, rarity_color, size, Color.WHITE, ITEM_ART_PADDING, true)`. Sem arte, `icon_tile(item.icon, ...)` como hoje.
- `skill_tile`: com arte, `_tile(art, skill.color, size, skill.color.lightened(0.25), GLYPH_PADDING, true)`. Sem arte, `icon_tile(skill.icon, skill.color, size)`.
- `empty_slot_tile`: `icon_tile(icon_id, BRONZE_DARK, size)` com `modulate.a = 0.5`.
- `set_button_icon`: com arte, `button.icon = art`, `icon_max_width = art_width`, **sem** sobrescrever nenhum `icon_*_color` (o tema deixa o ícone branco) e `button.texture_filter = ART_FILTER`. Sem arte, o que as telas fazem hoje: `icon = icon(item.icon)`, `icon_max_width = svg_width` e `icon_normal_color = tint` (a tela passa a cor que usa hoje).
- Onde há arte, o `TextureRect` do quadro leva `texture_filter = ART_FILTER`.

### 4. `SkillSlot` (`src/ui/hud/skill_slot.gd`)

- Campos novos: `icon_colored: bool = false` e `icon_inset: float = 8.0`.
- `_ready`: `texture_filter = UiKit.ART_FILTER`.
- `_draw`: a cor do ícone é `Color(1, 1, 1, alpha)` com `icon_colored`, e `Color(tint.lightened(0.3), alpha)` sem ele (como hoje). `area.grow(-icon_inset)`. O fundo continua `tint × 0,13`. Setor de recarga, número, tecla e borda não mudam.
- Fábricas estáticas, usadas por `Hotbar` e por `SkillTreeView`, para que as duas telas e a cena de revisão passem pelo mesmo código:

```gdscript
const DODGE_COLOR := Color("9fe3ff")
static func for_skill(skill: SkillData, key: String) -> SkillSlot                       # UiKit.skill_icon, tint = skill.color
static func for_icon(icon_id: StringName, tint: Color, key: String) -> SkillSlot        # SVG tingido, como a Guarda hoje
static func for_dodge(key: String) -> SkillSlot                                         # UiKit.skill_art(&"dodge") ou icon(&"dodge"), tint = DODGE_COLOR
static func for_potion(item: ItemData, fallback_icon: StringName, tint: Color, key: String) -> SkillSlot
```

`for_potion` usa `UiKit.item_art(item.id)` com `icon_colored = true` e o fundo na cor do HP ou da MP (`tint`). Sem arte, cai em `icon(fallback_icon)` com `icon_colored = false`.

### 5. Telas

| Arquivo | Mudança |
|---|---|
| `hotbar.gd` | Extraia de `bind` um `build_slots(class_data: ClassData) -> Array[SkillSlot]`, que cria os 10 slots **sem provedores**, nesta ordem: botão esquerdo, Guarda (botão direito), as 4 habilidades, a suprema (R), Esquiva (Ctrl), poção Q, poção X. Use `SkillSlot.for_skill`, `for_icon` (Guarda), `for_dodge` e `for_potion` (`potion_hp`, com `potion_red` e `UiKit.HP_COLOR`; `potion_mp`, com `potion_blue` e `UiKit.MP_COLOR`). `bind` chama `build_slots` e liga os provedores, tooltips e contagens de hoje. Os gaps de 10 px e o `separation 4` não mudam. A cena de revisão chama `build_slots` direto |
| `skill_tree_view.gd` | `_add_tier` cria cada slot com `SkillSlot.for_skill(skill, keys[i])` |
| `skill_card.gd` | `UiKit.skill_tile(skill, ICON_SIZE)` (46 px) |
| `lobby.gd:204` | `UiKit.skill_tile(skill, 38.0)` |
| `lobby.gd:293` | `UiKit.item_tile(item, 54.0)` |
| `inventory_view.gd` `_item_tile` | `UiKit.set_button_icon(button, item, tint.lightened(0.3), 46, 40)`; o resto do botão não muda |
| `inventory_view.gd` `_slot_row` | Com peça: `UiKit.item_tile(item, 46.0)`. Sem peça: `UiKit.empty_slot_tile(...)` da tabela acima; apague o `modulate.a = 0.35` |
| `forge_view.gd` `_recipe_row` | `UiKit.set_button_icon(button, item, tint, 28, 24)`; `expand_icon` segue `false` |
| `forge_view.gd` `_show_detail` | Cabeçalho `UiKit.item_tile(item, 64.0)`; ingredientes `UiKit.item_tile(ingredient, 28.0)`. Acrescente `func select(recipe: RecipeData) -> void` público (define `_selected` e chama `_refresh`), que a cena de revisão usa |

Fica como está: `party_frames.gd`, `player_frame.gd`, `lobby.gd:147`, `lobby.gd:401`, a Guarda do botão direito.

### 6. Teste (`tests/unit_tests.gd`)

Depois de `test_skill_icons_load`, que **continua valendo** (os SVG seguem lá, 96 × 96). O teste lê os ids da pasta `res://data/items/` (não do catálogo, para pegar item que alguém esqueça de pôr nele).

```gdscript
## Habilidades sem arte aceita. Cada exceção carrega o motivo. Ao chegar a imagem nova, apague a entrada: o teste falha se a arte existir.
const SKILL_ART_EXCEPTIONS: Dictionary[StringName, String] = {
	&"w_whirl": "REPROVADA em 08/11/2026: lê como ícone de atualizar; regerar com o prompt revisado de habilidades_gpt_image.md",
	&"w_warcry": "REPROVADA em 08/11/2026: lê como ícone de volume; regerar com a opção A ou B de habilidades_gpt_image.md",
}


func test_item_and_skill_art() -> void:
	for file_name in DirAccess.get_files_at("res://data/items"):
		if not file_name.ends_with(".tres"):
			continue
		var id := StringName(file_name.get_basename())
		var art: Texture2D = UiKit.item_art(id)
		check(art != null and art.get_size() == Vector2(256, 256), "item %s tem arte de 256 px" % id)
		check(_import_has_mipmaps("res://assets/icons/items/%s.png" % id), "arte do item %s importa com mipmaps" % id)
	var skill_ids: Array[StringName] = [&"dodge"]
	for skill in _player_skills():
		skill_ids.append(skill.id)
	check(skill_ids.size() == 19, "18 habilidades de classe e a Esquiva")
	for id in skill_ids:
		var art: Texture2D = UiKit.skill_art(id)
		if SKILL_ART_EXCEPTIONS.has(id):
			check(art == null, "exceção %s (%s) ainda sem arte: se a arte chegou, apague a exceção" % [id, SKILL_ART_EXCEPTIONS[id]])
		else:
			check(art != null and art.get_size() == Vector2(128, 128), "habilidade %s tem arte de 128 px" % id)
			check(_import_has_mipmaps("res://assets/icons/skills/%s.png" % id), "arte da habilidade %s importa com mipmaps" % id)
	for id: StringName in SKILL_ART_EXCEPTIONS:
		check(id in skill_ids, "exceção %s é de uma habilidade que existe" % id)
	# Plano B: sem arte, o SVG de hoje.
	equal(UiKit.skill_icon(_skill_named(&"w_whirl")), UiKit.icon(&"whirl"), "Giro de Lâminas cai no whirl.svg")
	equal(UiKit.skill_icon(_skill_named(&"w_warcry")), UiKit.icon(&"shout"), "Grito de Guerra cai no shout.svg")
	equal(UiKit.item_art(&"nao_existe"), null, "id sem arte devolve nulo")
	check(not DirAccess.dir_exists_absolute("res://assets/item_art"), "assets/item_art foi removida")
	check(not DirAccess.dir_exists_absolute("res://assets/icons/skill_gpt_image"), "skill_gpt_image foi removida")
	# Tinta: poção colorida, habilidade tingida.
	check(SkillSlot.for_potion(GameDB.item(&"potion_hp"), &"potion_red", UiKit.HP_COLOR, "Q").icon_colored, "poção usa a arte colorida, sem tinta")
	check(not SkillSlot.for_skill(_skill_named(&"w_slash"), "LMB").icon_colored, "habilidade segue tingida")


func _import_has_mipmaps(png_path: String) -> bool:
	return FileAccess.get_file_as_string(png_path + ".import").contains("mipmaps/generate=true")
```

`_player_skills` e `_skill_named` já existem no arquivo (linhas 775 e 784). Se algum auxiliar novo tiver o mesmo nome de outro, renomeie o novo.

### 7. Cena de revisão e renders

Crie `tests/visual/icon_review.tscn` (um `Node` com o script) e `icon_review.gd`, no padrão de `lineup.gd` e `tour.gd`: argumento `--out=DIR` (padrão `user://icon_review`), `DirAccess.make_dir_recursive_absolute`, `await RenderingServer.frame_post_draw`, `get_viewport().get_texture().get_image().save_png(...)` e `get_tree().quit()`. Fundo de tela `1E1C24`, janela de 1600 × 900, que é a viewport do projeto: **escala 1:1, nos tamanhos reais da UI**.

Cada captura grava dois arquivos: o PNG no tamanho real e um `<nome>_x3.png`, que é um recorte do controle principal ampliado 3 vezes, com `Image.INTERPOLATE_NEAREST` (função `_shot(nome, controle)`). A revisão de arte é feita no `_x3`.

| Arquivo | O que mostra | Como |
|---|---|---|
| `01_hotbars` | O hotbar do guerreiro, do mago e do sacerdote, um sobre o outro | `Hotbar.new()` + `build_slots(class_data)` de cada classe, com provedores parados: botão esquerdo pronto; slot `2` com recarga em andamento (`ratio` 0,6 e 5,4 s, que mostra o setor preto e o número por cima da arte); slot `4` sem mana (`usable` falso, alfa 0,4); suprema `R` com recarga (`ratio` 0,25 e 4 s) e sem Chi; poção Q com contagem 3 e X com contagem 12; Esquiva sem recarga |
| `02_inventory_grid` | A grade com os **48 itens**, todos visíveis, sem rolagem | `InventoryView` do guerreiro, com uma `CharacterSheet` cujo `inventory.add(id)` recebe cada id de `data/items/`; moldura de 900 × 640 |
| `03_equipment` | Os espaços de equipamento, três fichas lado a lado: guerreiro com `warrior_t3_weapon`, `warrior_t1_helm`, `warrior_t3_armor`, `warrior_t1_boots`; mago com tudo vazio; sacerdote só com `priest_t2_weapon` e `priest_t2_armor` | `InventoryView` de cada ficha, `equip_directly` como o saguão faz; recorte da coluna esquerda |
| `04_forge_header` | Duas receitas: `forge_mage_t3_armor` (lendária, ingredientes comuns) e `forge_warrior_t2_weapon` (rara, com `boss_core` como ingrediente); lista de receitas com ícones de 28 px, cabeçalho de 64 px e ingredientes de 28 px | `ForgeView.bind(sheet)` + `select(recipe)`, com materiais no inventário para o "tem / precisa" aparecer em verde e vermelho |
| `05_lobby_skills_warrior`, `_mage`, `_priest` | A lista de "Habilidades" da aba de classe do saguão, 38 px | O `Lobby` real, via `main.tscn` como o `tour.gd` faz (`_on_class_chosen`), recorte do bloco de habilidades |
| `06_lobby_item_choice` | Os cartões de itens iniciais, tile de 54 px, de uma classe sem ficha | O mesmo `Lobby`, `open_tab(&"gear")`, sem ficha em `Session.sheets` |
| `07_skill_tree_warrior`, `_mage`, `_priest` | A janela de habilidades, slots de 58 px e cabeçalho de 46 px | `SkillTreeView.new()` + `bind(sheet, describe)`, `describe` como o `_preview_info` do saguão |

O comando, na cópia descartável (o editor do usuário fica aberto), com `COPY` e `OUT` numa pasta temporária fora do projeto:

```bash
COPY=$(mktemp -d /tmp/artreview_copy_XXXXXX); OUT=$(mktemp -d /tmp/artreview_out_XXXXXX)
rsync -a --delete --exclude .git --exclude documents/audio ./ "$COPY/"
sed -i 's/^config\/name=.*/config\/name="ArtReview"/' "$COPY/project.godot"
(cd "$COPY" && godot --headless --import --path .)
(cd "$COPY" && timeout 170 godot --display-driver x11 --disable-vsync --resolution 1600x900 --path . res://tests/visual/icon_review.tscn -- --out="$OUT")
echo "$OUT"
```

Entregue o caminho de `$OUT` e a lista dos arquivos. Sem `--display-driver x11 --disable-vsync` o Godot trava na tela travada, e o `--import` na cópia vem antes porque o cache de `.godot/imported/` da cópia pode guardar a textura antiga.

## Critérios de aceite

- `check_scripts` sem erro; `unit_tests` passa com o teste novo; `flow_test` sem falha nova.
- `grep -L "mipmaps/generate=true"` nos `.import` das duas pastas novas não lista nada.
- `assets/item_art/` e `assets/icons/skill_gpt_image/` não existem; `documents/art/item_art/` tem 48 PNG de 1024 × 1024, o `.gdignore` e `rejeitadas/` com 2 PNG de 128 × 128.
- Renders conferidos pela direção de arte nos `_x3`:
  - **Item colorido sem tinta.** Em `02_inventory_grid`, cada item mostra as cores da ilustração (o vermelho do escudo, o verde do sacerdote, a pele branca) e a raridade só aparece no fundo e na borda.
  - **Habilidade tingida.** Em `01_hotbars` e `07_*`, cada glifo tem a cor da habilidade (laranja na Investida, azul-gelo na Lança de Gelo, dourado na Luz Sagrada) e continua legível com o setor de recarga e o número por cima.
  - **Poções.** Em `01_hotbars`, Q é a poção vermelha e X a azul, com as cores da arte, e não monocromáticas.
  - **Espaços vazios.** Em `03_equipment`, o mago mostra as 4 silhuetas (cajado, elmo, manto, botas) e nenhuma é `cloth`.
  - **Plano B.** Em `05_*` e `07_warrior`, `w_whirl` e `w_warcry` aparecem com o SVG de hoje, tingido, sem erro de carga.
  - **Sem serrilhado**, em 27, 33, 38 e 46 px, graças aos mipmaps: arestas lisas no `_x3`.
  - **Um slot em recarga** em pelo menos um slot de cada classe em `01_hotbars`, com o número legível sobre a arte.
- Nada mudou nos ícones de classe, na Guarda e na lista de itens do saguão que não usam os componentes acima.

## Ordem

1. `gameplay-developer`: esta ordem, inteira, numa sessão (os arquivos de UI, o teste e a cena de revisão se amarram pelo `UiKit` e pelo `SkillSlot`).
2. `qa-tester`: `godot --headless --import --path .` e as suítes de `CLAUDE.md` (`check_scripts`, `unit_tests`, `sfx_tests`, `flow_test`, `playthrough` com as 3 classes), na cópia descartável.
3. `art-director`: revisão dos renders de `icon_review`, nos `_x3`, pelos critérios acima.

## Revisão 1 (08/11/2026): AJUSTES

Julgada sobre os renders de `/tmp/artreview_out_0hss5o/` (as 11 capturas, no tamanho real e `_x3`), e sobre o código por `git diff`. Conferi também, numa cópia descartável já apagada: `check_scripts` com 128 scripts, 150 recursos e 0 erros, e `unit_tests` com 3.776 verificações e 0 falhas; depois do `--import` na cópia, nenhum `.import` perdeu `mipmaps/generate=true`. `flow_test` e `playthrough` ficam por conta do `qa-tester`.

### Critério por critério

| Critério da OS | Resultado |
|---|---|
| `check_scripts`, `unit_tests`, `flow_test` | `check_scripts` e `unit_tests` conferidos por mim. `flow_test` não rodei |
| `.import` com `mipmaps/generate=true` | Passa, na árvore e na cópia reimportada |
| Pastas e arquivos | Passa: `assets/item_art/` e `skill_gpt_image/` não existem; `assets/icons/items/` com 48 PNG de 256 × 256 e `skills/` com 17 PNG de 128 × 128; `documents/art/item_art/` com 48 PNG, `.gdignore` e `rejeitadas/` com 2 |
| Item colorido sem tinta (`02`) | Passa. As cores da ilustração (escudo vermelho, saia verde, pele branca) saem inteiras nos 48, e a raridade só pinta o fundo e a borda |
| Habilidade tingida e legível com recarga (`01`, `07`) | Passa. Cada glifo leva a cor do `.tres` (Investida laranja, Lança de Gelo azul-gelo, Luz Sagrada dourada). O setor preto e o número de 20 px ficam legíveis sobre a arte nos slots `2` e `R` das três classes; o slot `4`, sem mana, fica a 40% |
| Poções (`01`) | Passa. Q é a poção vermelha e X a azul, com as cores da arte e o fundo vermelho e azul-escuro do HP e da MP |
| Espaços vazios (`03`) | Passa. O mago mostra cajado, elmo, manto e botas em silhueta, nenhuma é `cloth`. As silhuetas a 0,5 se leem, apesar de apagadas |
| Plano B (`01`, `05_warrior`, `07_warrior`) | Passa. `w_whirl` e `w_warcry` aparecem com `whirl.svg` e `shout.svg`, tingidos, sem erro de carga |
| Sem serrilhado a 27, 33, 38 e 46 px | Passa. As arestas saem lisas nos `_x3` do saguão (27 px), do cabeçalho da árvore (33 px), do espaço de equipamento (38,6 px) e da grade (46 px) |
| Um slot em recarga por classe (`01`) | Passa nas três |
| Nada mudou nos ícones de classe | Passa. `party_frames.gd`, `player_frame.gd` e a Guarda não aparecem no `git diff`; `lobby.gd` mudou 2 linhas |

Também conferidos e aprovados: a grade com os 48 itens sem rolagem (7 colunas, a última linha com 6), o cabeçalho de 64 px e os ingredientes de 28 px da forja (o cristal e o Núcleo do Rei sobre o azul `5AA8FF` se leem), a lista de receitas a 28 px, e a refatoração do `Hotbar` (a ordem dos 10 slots e os dois gaps batem com o que a OS pediu).

Os desvios que o implementador relatou ficam aceitos: `build_slots` também adiciona os slots e os gaps ao hotbar (basta chamá-lo uma vez por `Hotbar`, e o comentário da função diz isso), o teste libera os dois `SkillSlot` com `free()`, e a coluna de `03_equipment` tem 260 px.

### O que falha: o quadro estica na vertical

Em `06_lobby_item_choice_x3.png` o quadro de 54 px do cartão de item sai com cerca de 54 × 108 px: a arte (45 px) fica pequena e boiando no meio de um retângulo alto. O mesmo acontece, em menor grau, na lista de habilidades do saguão (`05_*`): onde a linha tem a descrição em duas linhas, o quadro de 38 px sai com 38 × 50. A causa é a mesma nos dois: o filho de um `HBoxContainer` ocupa a altura da linha por padrão. Já acontecia com o SVG, mas a arte colorida expõe o defeito. A sugestão do implementador (`SIZE_SHRINK_BEGIN`) está certa.

### Correção exata

Só em `src/ui/lobby/lobby.gd`:

1. Em `_item_card`, troque `row.add_child(UiKit.item_tile(item, 54.0))` por:

```gdscript
var tile := UiKit.item_tile(item, 54.0)
tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
row.add_child(tile)
```

2. Em `_class_detail`, logo depois de `tile.mouse_filter = Control.MOUSE_FILTER_IGNORE`, acrescente `tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN`.

Nada mais muda: o tamanho continua 54 e 38, a margem e o fundo também. Não altere `UiKit` nem os outros painéis (a grade do inventário, o cabeçalho da forja e os espaços de equipamento já saem quadrados).

### Critério de aceite da Revisão 1

Rode de novo `icon_review` (mesmo comando da seção 7) e entregue `$OUT`. Conferência nos `_x3`:

- `06_lobby_item_choice`: os 4 quadros de item medem 162 × 162 px (54 × 3), com a margem de 8% (a arte com 45 px, centrada no quadro) e o topo do quadro alinhado ao topo do nome do item.
- `05_lobby_skills_warrior`, `_mage` e `_priest`: os 6 quadros de cada classe medem 114 × 114 px (38 × 3), inclusive nas linhas de descrição em duas linhas (Investida, Cura, Nova Elemental).
- `unit_tests` e `check_scripts` seguem verdes (a mudança não toca em dados nem em testes), e `flow_test` roda uma vez, porque `lobby.gd` mudou.

Passando isso, a OS-023 fecha como APROVADA.

### Ordem

1. `gameplay-developer`: as 2 linhas acima e os renders `05_*` e `06`.
2. Direção de arte: confere só esses 4 arquivos `_x3`. `qa-tester` só se o `flow_test` do passo 1 falhar.
