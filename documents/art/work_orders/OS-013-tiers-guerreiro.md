# OS-013: Tiers do guerreiro

- **Agente:** `gameplay-developer`
- **Depende de:** OS-005, OS-009, OS-012
- **Arquivos:** `src/visuals/heroes/warrior_model.gd`
- **Referência:** tabela "Tiers" de `documents/art/classes/warrior.md`
- **Fora do escopo:** balanceamento, novos itens.

## Trabalho

Peças cumulativas. Cada tier só soma ao anterior:

1. **T1:** gola de pele, canela em aço, metal `C4D2E0`.
2. **T2:** crista com escala y `1.5`, telhas com `centro_x` e `raio_x` multiplicados por `1.1`, metal `D8B464`. A espada já cresceu na OS-008.
3. **T3:** máscara fechada com visor fosco, 2 lâminas nas ombreiras, capa de 1,42 m, metal `E6ECF5`.

`look.head_tier` controla crista e máscara. `look.boots_tier` controla as canelas. `look.armor_tier` controla o resto.

A massa não muda: aço `B0AEA8`, carmesim `C23A22` e `B3301F` nos 4 tiers (P2).

## Critérios de aceite

`tiers_warrior.png`, `report.json` com `--tier=0` a `--tier=3`:

- Os 4 tiers se distinguem de frente, a 120 px de altura (`room_10`), sem ler o nome do item.
- Letra T mantida em preto (S5).
- A pele é branca e fosca, o T3 não emite luz no rosto e não tem cristal (B1, B6).
- `v1_ok` nos 4 tiers.
- T3 com até 70 partes.
- Elmo T1 com armadura T0 troca só a cabeça, e armadura T2 com elmo T1 mostra a cabeça de T2 (P3).
