# OS-014: Tiers do mago

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-010, OS-012
- **Arquivos:** `src/visuals/heroes/mage_model.gd`, `src/visuals/creature_rig.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/mage.md`
- **Fora do escopo:** balanceamento, novos itens.

## Trabalho

Peças cumulativas:

1. **T1:** barra de pele na capa, metal `C4D2E0`.
2. **T2:** gola com escala y `1.22`, 2 focos flutuantes, metal `D8B464`.
3. **T3:** mais 2 focos, aro duplo no cajado, aba traseira com `length = 1.14`, metal `E6ECF5`.

Os focos oscilam em y `±.03` m a `.5` Hz, com fase distinta em cada um. Faça isso num método de `CreatureRig`, por exemplo `add_float(node, amplitude, frequency, phase)`, chamado de `animate`, sem processo próprio por foco.

`look.head_tier` controla a gola. `look.armor_tier` controla o resto. O aro duplo segue `look.weapon_tier`.

A massa não muda: ameixa `6E2470`, prata `D5D9E4`, pernas `1B1830` nos 4 tiers (P2).

## Critérios de aceite

`tiers_mage.png`, `report.json` com `--tier=0` a `--tier=3`:

- Os 4 tiers se distinguem a 120 px de altura.
- Letra Y mantida em preto, sem os focos encostarem nas asas da gola.
- Focos redondos com aro, em `8A7BFF`, sem estilhaço (B2).
- `v1_ok` nos 4 tiers.
- T3 com até 70 partes.
- Com o jogo pausado, os focos param. Morto, ficam parados também.
