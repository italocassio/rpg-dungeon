# OS-017: Validação final

- **Agente:** `qa-tester`
- **Depende de:** todas as anteriores
- **Arquivos:** nenhum no jogo. Testes novos só se faltar cobertura.
- **Fora do escopo:** ajustar arte. Falha volta para a ordem de origem.

## Trabalho

Numa cópia descartável, com `config/name` trocado:

1. Rode `check_scripts`, `unit_tests`, `sfx_tests`, `flow_test` e `playthrough` com as 3 classes.
2. Rode `hero_review` completo: 3 classes, 4 tiers, as 6 armas iniciais, 5 raridades.
3. Meça o custo com a cena de referência da seção 11 do guia: `frost_gate`, sala de `eye = (-7, 1.7, -2)`, 4 heróis em T3 e 12 monstros, em 1080p, 300 quadros.

| Qualidade | Referência da direção de arte | Limite |
|---|---|---|
| Baixo | 11,3 ms | Base + 1,0 ms |
| Médio | 20,7 ms | Base + 1,0 ms |
| Alto | 35,0 ms | Base + 1,0 ms |

A base é a sua medição na mesma cena, logo depois da OS-002, com os modelos antigos. A referência acima só serve de ordem de grandeza: Baixo e Médio foram medidos com a correção de malha, e Alto sem ela.

4. Rode `tour.tscn` com cada classe, em Médio, e confirme que não há erro no console.

## Critérios de aceite

- Todos os testes passam.
- `report.json` com `v1_ok`, `v4_ok` e `limit_ok` em todas as combinações.
- O custo novo não passa de 1,0 ms em nenhuma qualidade (C2).
- Montar um herói T3 leva menos de 6 ms.
- Na cena de referência, só o sacerdote com `scepter` tem `OmniLight3D` permanente, e só uma. Guerreiro e mago com arma T3 lendária têm 0 (C3).

## Entrega

Pasta de renders, `report.json`, tabela de tempos. A direção de arte fecha a revisão pelo checklist da seção 12 do guia.
