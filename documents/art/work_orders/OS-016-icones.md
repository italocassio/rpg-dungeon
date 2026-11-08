# OS-016: Ícones de classe

- **Agente:** `gameplay-developer`
- **Depende de:** nenhuma
- **Arquivos:** `assets/icons/priest.svg`, `assets/icons/mage.svg`
- **Fora do escopo:** ícones de item e habilidade. O ícone do guerreiro continua igual. Os ícones de habilidade do sacerdote que desenhavam cruz (`smite`, `heal` e `circle`) ficam para a OS-020.

## Problema

`priest.svg` é uma cruz, proibida pela regra O2. `mage.svg` é um chapéu pontudo, forma que o mago não usa mais.

## Trabalho

Copie sobre os atuais, sem editar:

| De | Para |
|---|---|
| `documents/art/concepts/icons/priest.svg` | `assets/icons/priest.svg` |
| `documents/art/concepts/icons/mage.svg` | `assets/icons/mage.svg` |

Os dois mantêm o formato atual: 96 × 96, `viewBox` de 64, preenchimento branco. A cor vem da UI.

## Critérios de aceite

- Na escolha de classe do saguão (`lobby.gd`), a lanterna e o emblema em Y aparecem na cor da classe.
- Legíveis a 40 px.
- Os dois carregam em 96 px. O `check_scripts` não vê isso: ele só percorre `src`, `tests`, `data` e `assets/shaders`, nunca `assets/icons/`. A conferência é de `test_class_icons_load`, em `tests/unit_tests.gd`, que entra na OS-020.
