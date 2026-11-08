# Ordens de serviço da direção de arte

Execute na ordem. Uma ordem só começa quando as anteriores da coluna "Depende de" estiverem aprovadas pela direção de arte.

| OS | Título | Agente | Depende de |
|---|---|---|---|
| 001 | Ferramenta de revisão | `gameplay-developer` | Nenhuma |
| 002 | Corrigir malhas do avesso | `gameplay-developer` | 001 |
| 003 | Corrigir poses do rig | `gameplay-developer` | 001 |
| 004 | Contrato de aparência do herói | `game-architect` | Nenhuma |
| 005 | Dados de aparência e nomes | `rpg-systems` | 004 |
| 006 | Separar inimigos e unificar o brilho | `gameplay-developer` | 002, 003, 005 |
| 007 | Base comum do caçador | `gameplay-developer` | 002, 003, 004, 005, 006 |
| 008 | Armas e empunhadura | `gameplay-developer` | 006, 007 |
| 009 | Guerreiro T0 | `gameplay-developer` | 008 |
| 010 | Mago T0 | `gameplay-developer` | 008 |
| 011 | Sacerdote T0 | `gameplay-developer` | 008 |
| 012 | Viewmodel | `gameplay-developer` | 009, 010, 011 |
| 013 | Tiers do guerreiro | `gameplay-developer` | 005, 009, 012, 019 |
| 014 | Tiers do mago | `gameplay-developer` | 005, 010, 012, 019 |
| 015 | Tiers do sacerdote | `gameplay-developer` | 005, 011, 012, 019 |
| 016 | Ícones de classe | `gameplay-developer` | Nenhuma |
| 017 | Validação final | `qa-tester` | Todas |
| 018 | Realce dos cristais | `gameplay-developer` | 002 |
| 019 | Ferramenta de tiers | `gameplay-developer` | 012 |
| 020 | Ícones de habilidade do sacerdote e teste dos ícones | `gameplay-developer` | 016 |
| 021 | Rei Gélido, modelo novo | `gameplay-developer` | Nenhuma |
| 022 | Efeitos de ataque do Rei Gélido | `rpg-systems` (dados) e `gameplay-developer` (código) | 021 |

As OS-006 e 007 não correm em paralelo: a 007 lê `look_tier` da OS-005 e mexe nos mesmos corpos de `creature_factory.gd` que a 006. O contrato final está na OS-004, e o parecer em `OS-004-parecer.md`.

As OS-021 e 022 refazem o chefe pelo novo design. A 021 define o modelo e as âncoras (`weapon_tip`, `core`, `crown`) que a 022 usa para os efeitos. Cada uma traz uma seção "Mudança no guia" com propostas que o usuário precisa aprovar antes de `style_guide.md` mudar.

A OS-020 nasceu da validação da OS-017: o ícone `smite.svg` desenhava uma cruz (O2), e nenhum teste carregava os ícones de `assets/icons/`. A OS-017 só fecha depois dela.

Regras para todas as ordens:

- Referências: `documents/art/style_guide.md`, `documents/art/classes/*.md`, `documents/art/concepts/`. Se faltar um dado, pare e pergunte à direção de arte. Não decida arte sozinho.
- Valide em cópia descartável, porque o usuário mantém o editor aberto e outras sessões usam a mesma árvore. Nunca use `git add .` nem `git stash`. Faça commit só de arquivos seus, e só quando pedirem.
- Depois de cada ordem, `qa-tester` roda `check_scripts`, `unit_tests` e `flow_test`.
- Só a direção de arte aprova. Entregue a pasta de renders da OS-001 e o `report.json`.
