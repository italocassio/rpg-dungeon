# OS-015: Tiers do sacerdote

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-011, OS-012
- **Arquivos:** `src/visuals/heroes/priest_model.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/priest.md`
- **Fora do escopo:** balanceamento, novos itens.

## Trabalho

Peças cumulativas:

1. **T1:** manto curto `D5D9E4`, com o Selo frontal movido para `(0,.4,-.18)`, metal `C4D2E0`.
2. **T2:** 2 pingentes largos na aba, metal `D8B464`.
3. **T3:** segunda aba, véu de 0,50 m, lanterna do bastão com escala `1.18`, lanterna de cinto sem luz real, metal `E6ECF5`.

`look.head_tier` controla pingentes, segunda aba e véu. `look.armor_tier` controla manto e cinto. A escala da lanterna segue `look.weapon_tier`.

A massa não muda: jade `247050`, creme `E6DCC0`, chapéu `E2D6B6` nos 4 tiers (P2).

## Critérios de aceite

`tiers_priest.png`, `report.json` com `--tier=0` a `--tier=3`:

- Os 4 tiers se distinguem a 120 px de altura.
- Letra A mantida em preto. A segunda aba reforça o disco.
- Pingentes visíveis a 10 m. Cada um tem pelo menos 12 cm de largura (E1).
- Só uma `OmniLight3D` por sacerdote, mesmo em T3 (C3).
- Nenhuma peça lembra mitra, tiara ou batina (O2).
- `v1_ok` nos 4 tiers.
- T3 com até 70 partes.
