# OS-020: Ícones de habilidade do sacerdote e teste dos ícones

- **Agente:** `gameplay-developer`
- **Depende de:** 016 (os ícones de classe já estão copiados). A OS-017 só fecha depois desta.
- **Arquivos:** `assets/icons/smite.svg`, `assets/icons/heal.svg`, `assets/icons/circle.svg` e `tests/unit_tests.gd`. Os três `.svg.import` não mudam.
- **Fora do escopo:** qualquer outro ícone de habilidade ou de item, `data/`, `src/`, cores da UI e `check_scripts.gd`. `bless`, `judgement` e `miracle` foram lidos e ficam como estão.

## Problema

A OS-017 achou uma cruz latina em `smite.svg`, o ícone de "Luz Sagrada", ataque básico do sacerdote. O arquivo vem do commit original, e a OS-016 deixou ícones de habilidade fora do escopo. Pela regra O2 (nenhum símbolo religioso real, e a cruz é o primeiro da lista), a fé do jogo tem um único símbolo, a lanterna acesa.

Os outros dois ícones do sacerdote caem no mesmo critério:

| Arquivo | O que desenha | Veredito |
|---|---|---|
| `smite.svg` | Cruz latina: haste de y 4 a 60 e travessa de y 24 a 32 | Reprova O2 |
| `heal.svg` | "+" de braços iguais, grosso | Reprova. É uma cruz grega. O "+" lê como símbolo de saúde em qualquer HUD, mas a regra O2 não abre exceção para a cruz, e no sacerdote ele é o único traço que sobraria da cruz que a decisão de 31/10 tirou do ícone de classe |
| `circle.svg` | "+" dentro de um aro | Reprova. Cruz dentro de círculo lê como cruz de sol ou cruz céltica antes de ler como área de cura |
| `bless.svg` | Cabeça, faixa curva com pontas caídas e haste afunilada, tudo orgânico | Aprovado. Não há ângulo reto nem travessa, e lê como flor ou pássaro de asas abertas |
| `judgement.svg` | Pilar afunilado com dois cacos inclinados no pé | Aprovado. A travessa não existe: os cacos ficam embaixo e inclinados |
| `miracle.svg` | Estrela de 7 pontas | Aprovado. O O2 só proíbe a de 6 pontas |

Os demais ícones de `assets/icons/` foram lidos no SVG e nenhum desenha cruz. Espada, machado, cajado e cetro têm haste, mas sem travessa em ângulo reto.

## Trabalho

1. Copie sobre os atuais, sem editar:

| De | Para |
|---|---|
| `documents/art/concepts/icons/smite.svg` | `assets/icons/smite.svg` |
| `documents/art/concepts/icons/heal.svg` | `assets/icons/heal.svg` |
| `documents/art/concepts/icons/circle.svg` | `assets/icons/circle.svg` |

Os três mantêm o formato dos de classe: 96 × 96, `viewBox` de 64, `fill="#fff"` e `fill-rule="evenodd"`. A cor vem da UI (`UiKit.icon_tile` pinta com `skill.color`). Os ids das habilidades e o campo `icon` em `data/skills/` não mudam.

2. Em `tests/unit_tests.gd`, depois de `test_catalog_classes_are_complete`, acrescente os dois testes abaixo. O primeiro é o do `qa-tester`: o `check_scripts` só percorre `src`, `tests`, `data` e `assets/shaders`, então nenhum SVG de `assets/icons/` era carregado por teste nenhum. Conferido em `src/`: `UiKit.icon(id: StringName) -> Texture2D` é estático e devolve `null` se o arquivo não existe; `GameDB.catalog.classes` é `Array[ClassData]` e `ClassData.id` é `StringName`. O segundo usa `_player_skills()` e `_skill_named()`, que já existem no arquivo.

```gdscript
func test_class_icons_load() -> void:
	for class_data in GameDB.catalog.classes:
		var texture: Texture2D = UiKit.icon(class_data.id)
		check(texture != null and texture.get_size() == Vector2(96, 96), "ícone de %s carrega em 96 px" % class_data.id)


func test_skill_icons_load() -> void:
	for skill in _player_skills():
		var texture: Texture2D = UiKit.icon(skill.icon)
		check(texture != null and texture.get_size() == Vector2(96, 96), "ícone %s de %s carrega em 96 px" % [skill.icon, skill.id])
	equal(_skill_named(&"p_smite").icon, &"smite", "Luz Sagrada usa smite.svg")
	equal(_skill_named(&"p_heal").icon, &"heal", "Cura usa heal.svg")
	equal(_skill_named(&"p_circle").icon, &"circle", "Círculo usa circle.svg")
```

O segundo percorre as 18 habilidades dos jogadores, então cobre os três ícones trocados e qualquer ícone de habilidade que alguém apague ou renomeie. Os testes só provam que o arquivo carrega em 96 px. Quem prova que a cruz saiu é o critério visual abaixo.

3. Valide numa cópia descartável, com `config/name` trocado. Depois de copiar os SVGs, rode `godot --headless --import --path .` na cópia: sem isso o cache de `.godot/imported/` pode guardar a textura antiga e o teste passaria com a cruz.

4. Em `OS-016-icones.md`, a direção de arte já trocou a linha do `check_scripts`. Não mexa nos documentos.

## Especificação visual

Todos os três usam a mesma chama de lanterna, de ponta torta e com uma língua à esquerda, que é a chama da Vigília. Cada um tem uma silhueta própria.

| Ícone | Silhueta | Detalhe |
|---|---|---|
| `smite` | Cometa na diagonal, cabeça em (43, 43) com raio 16 e cauda até (5, 5), mais duas faixas finas paralelas | Chama vazada na cabeça, com a ponta voltada para a cauda. É o "raio de luz" da descrição da habilidade |
| `heal` | Coração sólido, 56 de largura e 53 de altura | Chama vazada no centro, com a ponta a 7 unidades do vão do topo |
| `circle` | Aro de raio 28 e espessura 7 | Chama sólida no centro, com 6 unidades de folga até o aro |

Nada de cruz, de "+", de estrela de 6 pontas nem de crescente (O2).

## Critérios de aceite

- `cmp` entre cada arquivo de `assets/icons/` e o de `documents/art/concepts/icons/` não acusa diferença nos três.
- `unit_tests` passa, com os dois testes novos contados. `check_scripts` e `flow_test` seguem verdes.
- Renders, entregues na pasta de saída:
  - `magick -background none -density 192 assets/icons/<nome>.svg -resize 40x40 saida.png` para `smite`, `heal` e `circle`, ampliados 3 vezes. A cabeça do cometa mostra a chama vazada, o coração mostra a chama e o aro mostra a chama, os três legíveis e nenhum com cruz. A referência é `documents/art/concepts/icons/sacerdote_habilidades_40px.png`.
  - `tour.tscn --class=priest`, sem `--short`, que grava `01_lobby_warrior.png`, `02_lobby_mage.png` e `03_lobby_priest.png`. Em cada uma, o emblema da classe aparece na cor dela (espada, lanterna ou emblema em Y), e em `03_lobby_priest.png` a lista de habilidades mostra "Luz Sagrada", "Cura" e "Círculo" com os ícones novos. Este render fecha também o critério da OS-016 que a OS-017 deixou sem ver.
- Os ícones de habilidade aparecem na lobby em um quadro de 38 px, que deixa cerca de 27 px para o desenho. Os três têm de ler nesse tamanho.
