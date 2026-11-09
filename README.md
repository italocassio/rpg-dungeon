# Caçadores de Portais

MVP de MMORPG de masmorras em primeira pessoa: a progressão e o HUD de **Perfect World** com os Portões e o "Sistema" de **Solo Leveling**. Feito em **Godot 4.7** (Forward+), com GDScript tipado. O nome é provisório.

O objetivo deste MVP é testar a **mecânica** e os **gráficos**. O grupo é simulado por bots: ainda não há servidor nem multijogador real.

## Como jogar

```bash
godot --path .
```

Ou abra o `project.godot` no editor e aperte F5. Os comandos deste README assumem o Godot 4.7.2 no PATH como `godot`.

**O ciclo:** escolha a classe → escolha os itens iniciais → procure um grupo → entre no Portão → mate monstros e colete materiais → derrote o chefe → volte ao saguão e forje → entre em um Portão mais forte.

| Ação | Tecla |
|---|---|
| Mover / correr / pular | WASD / Shift / Espaço |
| Atacar / defender | Botão esquerdo / botão direito |
| Habilidades / suprema | 1 a 4 / R |
| Esquiva (invulnerabilidade curta) | Ctrl |
| Poção de vida / mana | Q / X |
| Alvo seguinte / aliados / limpar alvo | Tab / F2–F4 / T |
| Interagir (forja, baú, porta, portal) | E |
| Inventário / status / árvore de habilidades / forja / mapa | I / C / K / P / M |
| Soltar o cursor (e ler as habilidades passando o mouse na barra) | Segurar Alt |
| Pausa | Esc |
| Mostrar FPS / trocar qualidade gráfica | F9 / F10 |

**Dicas:** a suprema gasta 1 Faísca de Chi (as bolinhas vermelhas ao lado da vida), que você acumula lutando. Saia das áreas vermelhas e azuis no chão. O sacerdote cura o aliado selecionado com F2–F4 ou, sem seleção, o mais ferido. Pontos de atributo são distribuídos em C.

## Estrutura

```
data/        Conteúdo do jogo em Resources (.tres), editável no Inspector
  balance.tres   Todos os números globais de balanceamento
src/rpg/     Regras puras, sem cena: ficha, inventário, forja, dano, drops, busca de grupo
src/combat/  Componentes de combate compartilhados: Combatant, SkillCaster, execução de skills
src/actors/  Jogador, monstros, chefe e bots (máquinas de estados)
src/world/   Geração da masmorra (campo SDF → malhas, colisão e navegação) e regras da partida
src/visuals/ Modelos e armas procedurais
src/ui/      HUD, janelas e saguão
src/audio/   Música e sons de habilidade: escutam Events, a gameplay não os conhece
assets/audio/  Faixas e efeitos usados pelo jogo
documents/audio/raw/  MP3 originais do Stable Audio, com prompts e seeds no manifest.json
documents/art/  Guia de estilo, fichas das classes, conceitos e ordens de serviço da direção de arte
tests/       Testes automatizados e capturas visuais
tools/       Gerador das texturas (node tools/bake_textures.mjs)
```

**Decisões de arquitetura**

- **Regras separadas da apresentação.** `src/rpg` não depende de cena. Jogador, bots e monstros usam os mesmos `Combatant` e `SkillCaster`, e a busca de grupo está isolada em `PartyFinder`. Isso reduz o trabalho quando o multijogador real entrar, mas não o elimina: o combate ainda roda localmente.
- **Conteúdo em dados.** Item, skill, monstro, receita e masmorra são Resources. O índice de tudo é `data/catalog.tres`. Conteúdo novo precisa ser adicionado ali para o jogo enxergar.
- **Masmorra gerada de uma fonte só.** Salas e corredores viram um campo de distância com sinal, do qual saem paredes, abóbadas, piso, colisão, navegação, minimapa e mapa em pergaminho.
- **Arte procedural.** Texturas, modelos e animações são gerados por código, sem esqueletos importados. Por isso não há `AnimationTree`: a animação está em `CreatureRig`, e trocar por modelos reais significa substituir essa classe e `CreatureFactory`.

## Como adicionar conteúdo

- **Balanceamento:** edite `data/balance.tres` ou o recurso do monstro, item ou receita no Inspector.
- **Masmorra nova:** crie um `DungeonData` com salas, corredores, grupos de monstros e ranks, e adicione ao `catalog.tres`. Ela precisa ter sala de entrada, sala do chefe e `boss`; os testes falham se faltar. O saguão hoje só lista a primeira masmorra do catálogo.
- **Texturas:** ajuste `tools/bake_textures.mjs` e rode com Node.
- **Música:** troque as faixas, volumes e fades em `data/music.tres`.
- **Som de habilidade:** coloque o WAV em `assets/audio/sfx/` e ligue-o em `data/skill_sounds.tres`, pelo id da habilidade (`guard_<classe>` para a defesa). Cada momento (conjuração, disparo, impacto, contínuo) é um `SoundClip` com variações, ganho e variação de tom. Skill sem entrada fica em silêncio. Depois, atualize a planilha `SHEET` em `tests/sfx_tests.gd`.

## Build para Windows

Requer os templates de exportação do Godot 4.7.2.

```bash
mkdir -p build/windows
godot --headless --path . --export-release "Windows Desktop" build/windows/CacadoresDePortais.exe
```

Distribua o `.exe` e o `.pck` na mesma pasta.

## Build para Linux

Requer os templates de exportação do Godot 4.7.2.

```bash
mkdir -p build/linux
godot --headless --path . --export-release "Linux" build/linux/CacadoresDePortais.x86_64
```

Distribua o `.x86_64` e o `.pck` na mesma pasta. Para jogar, rode `./CacadoresDePortais.x86_64`.

## Testes

```bash
# Compila todos os scripts e carrega todos os recursos
godot --headless --path . res://tests/check_scripts.tscn

# Regras do jogo
godot --headless --path . res://tests/unit_tests.tscn

# Sons de habilidade: planilha completa, vozes e cortes
godot --headless --path . res://tests/sfx_tests.tscn

# Fluxo completo pela interface: saguão, janelas, forja, vitória, retorno e save
godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn

# Partida completa jogada por um piloto automático com as ações de entrada reais.
# Opções: --class=warrior|mage|priest --rank=0|1 --level=N --forged --no-dodge --trace
godot --headless --fixed-fps 60 --path . res://tests/playthrough.tscn -- --class=mage

# Capturas de tela e FPS (precisa de janela e GPU)
godot --path . --disable-vsync --fixed-fps 30 --resolution 1600x900 \
   res://tests/visual/tour.tscn -- --out=/tmp/capturas --class=warrior
```

Os testes usam arquivos de save próprios e não tocam no seu progresso. O save do jogo fica em `user://hunter_save.json`.

> Com a tela bloqueada, o Godot com vsync ligado fica parado esperando o compositor. Para capturas sem ninguém na máquina, use `--display-driver x11 --disable-vsync`.

## Fontes e licenças

As fontes Cinzel e Exo 2 estão em `assets/fonts/` sob a licença SIL Open Font (OFL), com os textos de licença ao lado. Texturas e ícones foram gerados para este projeto. "Perfect World" e "Solo Leveling" são apenas referências de inspiração: nenhum nome próprio, personagem ou arte dessas obras deve entrar em uma versão pública.
