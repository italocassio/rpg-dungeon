# OS-003: Corrigir poses do rig

- **Agente:** `gameplay-developer`
- **Depende de:** OS-001
- **Arquivos:** `src/visuals/creature_rig.gd`, `tests/unit_tests.gd`, `tests/visual/hero_review.gd`
- **Fora do escopo:** `_pose_quadruped`, `_pose_hover`, ritmo de ataque, gameplay. As curvas de `overhead`, `thrust`, `cast`, `shout` e `spin`.

## Problema

Atores viram o **-Z** do modelo para a direção do movimento (`atan2(-x, -z)`), e as malhas olham para -Z. Mas `_pose_biped` foi escrito como se a frente fosse +Z. Resultado em todo bípede, herói ou inimigo:

- Conjurar leva os dois braços para trás das costas.
- Golpes e estocadas saem para trás.
- Joelhos dobram para a frente.

Veja `concepts/blockout/antes_depois_pose.png`.

## Correção

Inverta o sinal de X ao aplicar as poses. Os cálculos internos ficam iguais, menos a curva do joelho e o golpe `swing`, descritos abaixo.

```gdscript
var knee_bend: float = 0.85
var arm_swing_r: float = 0.7
var arm_swing_l: float = 0.7

# em _pose_biped
_set_joint(&"hip_l", Vector3(-swing, 0.0, 0.0))
_set_joint(&"hip_r", Vector3(swing, 0.0, 0.0))
_set_joint(&"knee_l", Vector3(-_knee_flex(_phase + PI), 0.0, 0.0))
_set_joint(&"knee_r", Vector3(-_knee_flex(_phase), 0.0, 0.0))
# pano atrás: abre com a velocidade, as pernas nunca o atravessam
_set_joint(&"cloth_back", Vector3(-(_blend * 0.55 + sin(_phase * 2.0) * 0.05 * _blend + sin(_breath) * 0.012), 0.0, 0.0))

var arm_r := Vector3(swing * arm_swing_r + breath, 0.0, 0.0)
var arm_l := Vector3(-swing * arm_swing_l - breath, 0.0, 0.0)

# no fim de _pose_biped
_set_joint(&"shoulder_r", Vector3(-arm_r.x, arm_r.y, arm_r.z))
_set_joint(&"shoulder_l", Vector3(-arm_l.x, arm_l.y, arm_l.z))
_set_joint(&"elbow_r", Vector3(-elbow_r.x, elbow_r.y, elbow_r.z))
_set_joint(&"elbow_l", Vector3(-elbow_l.x, elbow_l.y, elbow_l.z))
_set_joint(&"chest", Vector3(-chest.x, chest.y, chest.z))
_set_joint(&"head", Vector3(-neck.x, neck.y, neck.z))
```

`_set_joint` já ignora joints que não existem, então `cloth_back` é opcional por modelo.

Acrescente um método para fixar a pose de repouso por classe:

```gdscript
func set_rest(joint_name: StringName, rest_rotation: Vector3) -> void:
	_rest[joint_name] = rest_rotation
```

Depois da ordem, `x` positivo no ombro leva o braço para a frente, e `_rest` soma com as poses (regra J6).

## Curva do joelho

Regra J8. A curva anterior dependia só de `sin(_phase)`: o pé ia e voltava pela mesma linha, sem subir ao avançar. Trocar os senos mantém esse defeito e ainda dobra o joelho no extremo da passada, por isso a troca fica recusada.

```gdscript
const KNEE_LEAD := 0.4
const KNEE_BASE := 0.15

## leg_phase = _phase na perna direita. A flexão chega antes da coxa passar pelo quadril.
func _knee_flex(leg_phase: float) -> float:
	return (KNEE_BASE + maxf(cos(leg_phase + KNEE_LEAD), 0.0) * knee_bend) * _blend
```

Resultado com `stride = .75` e `knee_bend = .85`, em perna de 0,46 + 0,46 m:

| `leg_phase` | Coxa | Joelho | Pé atrás do quadril | Altura do pé | Momento |
|---|---|---|---|---|---|
| 90° | +.75 | .15 | -.57 m | .20 m | Perna à frente, quase reta |
| 180° | 0 | .15 | +.07 m | .01 m | Apoio |
| -90° | -.75 | .48 | +.75 m | .43 m | Perna atrás, joelho dobrado |
| 0° | 0 | .93 | +.37 m | .19 m | Perna avançando, pé erguido |

`knee_bend` cai de 1,1 para 0,85 para o pé ficar longe da capa aberta do guerreiro (J4). Na conta, com 1,1 ele sobe até 0,58 m e fica a menos de 3 cm do plano dela. Com 0,85, sobe até 0,48 m e fica a 9 cm. A bota e o pano ainda precisam ser confirmados na OS-009.

## Golpe swing

Regra J9. `swing` é o golpe do goblin, do esqueleto, de 46 dos 62 golpes medidos do chefe e de `w_slash`. Hoje ele passa pelo repouso no meio do arco, porque o `lerp` usa `absf(value)`, e termina com o braço atrás da cabeça. Inverter o sinal só leva o defeito para a preparação. Nenhuma das duas opções serve: troque a curva por estas chaves, em interpolação linear entre elas.

| `value` | Momento | Ombro X | Ombro Z | Cotovelo X | Peito Y |
|---|---|---|---|---|---|
| -1 | Armado, ao lado da cabeça | 1.9 | +.55 | .2 | -.55 |
| 0 | Impacto, à frente do peito | .75 | 0 | .15 | 0 |
| +1 | Fim, à frente da cintura | .5 | -.35 | .15 | +.55 |

Os valores de X da tabela são os aplicados no joint. No cálculo interno, eles entram com sinal negativo:

```gdscript
&"swing":
	var armed: bool = value < 0.0
	var amount: float = absf(value)
	var weight: float = 1.0 if _action_phase == ActionPhase.STRIKE else amount
	var target := Vector3(-lerpf(0.75, 1.9 if armed else 0.5, amount), 0.0, lerpf(0.0, 0.55 if armed else -0.35, amount))
	arm_r = arm_r.lerp(target, weight)
	elbow_r = elbow_r.lerp(Vector3(-lerpf(0.15, 0.2, amount) if armed else -0.15, 0.0, 0.0), weight)
	chest.y += value * 0.55
```

Com peso 1 em `STRIKE`, o braço não volta ao repouso no meio do golpe. Medido no esqueleto, com a rotação do peito incluída:

| Quadro | `value` | Mão `z`, relativa ao peito | Mão `x` | Lâmina |
|---|---|---|---|---|
| Armado | -1 | -0,12 m | +0,72 m, ao lado da cabeça | 21,7° além da vertical |
| Impacto | 0 | -0,45 m | +0,23 m | À frente |
| Fim, no render | +.8 | -0,34 m | -0,09 m | À frente |
| Fim, no último quadro | +1 | -0,28 m | -0,15 m | À frente |

A conta anterior, de -0,56 m no armado, ignorava o peito: o giro de -0,55 rad recua o ombro direito, o que dá a carga do golpe e tira o braço de cima da cabeça. A curva fica como está (regra J9, decisão em 01/11/2026). Baixar o braço para trazer a ponta à frente encurta o arco e tira a altura que anuncia o golpe.

## Render e testes novos

Em `hero_review.gd`, gere `pose_swing.png`, porque a ferramenta só mostrava `overhead`, e `swing` é o golpe mais usado. Mesmo palco e câmera de `pose_cast`, com 3 faixas empilhadas pelo `_sheet`, nos mesmos rigs:

1. Armado: `wind_up(&"swing", .1)` e 12 quadros de `.016`.
2. Impacto: `strike(&"swing")` e 5 quadros de `.016`.
3. Fim: mais 4 quadros de `.016`.

Em `tests/unit_tests.gd`, com `_blend = 1`:

- `_phase = 0`: `knee_r.rotation.x = -.93` e `knee_l.rotation.x = -.15`, com ±.02.
- `_phase = PI*.5`: `knee_r.rotation.x = -.15` e `knee_l.rotation.x = -.48`, com ±.02.
- `swing`: nas 3 poses acima, a mão direita fica com `z` negativo em relação ao peito. Esta verificação fica, mas sozinha não protege a curva: a antiga também a cumpre.
- `swing`, proteção contra regressão: acrescente as 3 verificações abaixo a `test_swing_keeps_the_hand_ahead_of_the_chest`, nos mesmos quadros, com o `skeleton`.

A lâmina montada por `_grip` aponta para -Z da mão, então o sentido dela não depende do modelo da arma:

```gdscript
## Negativo: a ponta da arma está à frente da mão. Vale para armas montadas por _grip.
func _blade_forward_z(rig: CreatureRig) -> float:
	return -rig.get_joint(&"hand_r").global_basis.z.z
```

| Quadro | `value` | Verificação | Curva nova | Curva antiga |
|---|---|---|---|---|
| Armado | -1 | `hand_r.global_position.y - shoulder_r.global_position.y > 0.15` | +0,23 | -0,24 |
| Impacto | 0 | `_hand_ahead_of_chest(rig) < -0.30` | -0,45 | -0,06 |
| Fim | +.8 | `_blade_forward_z(rig) < -0.5` | -0,71 | +0,77 |

Confirme a proteção em uma cópia descartável: troque só o bloco `&"swing"` pelo de `git show HEAD:src/visuals/creature_rig.gd`, linhas 208 a 211, mantendo o resto do rig. As 3 verificações novas precisam falhar, e as 3 antigas, passar. Se o resultado for outro, volte à direção de arte com a medida. Não mexa nos limites.

## Critérios de aceite

Renders de `hero_review`, com os modelos atuais:

- `pose_cast.png`: mãos à frente do peito, do lado do nariz do elmo.
- `pose_strike.png`: arma desce à frente do corpo.
- `pose_swing.png`: no impacto e no fim, mão e lâmina à frente do peito. No armado, valem os limites da J9: mão ao lado da cabeça, sem tocá-la e à frente do peito, com a arma até 30° além da vertical.
- `walk_side.png`: joelho de trás dobra para trás e o pé fica atrás do quadril, com a canela abaixo da horizontal. A perna da frente fica quase reta, sem travar. O braço oposto à perna da frente vai à frente.
- Em tira fora do repositório, com `_phase` em 0, 90°, 180° e 270°: a perna que avança sobe dobrada, e a de apoio passa reta perto do chão.
- `arcos/`, para `frost_king`, `goblin` e `skeleton`: lâmina à frente do corpo do impacto ao fim do `swing`, e armado dentro da J9. `overhead` e `thrust` sem mudança.
- De frente, em imagem fora do repositório, `frost_king` e `goblin` no quadro armado: arma e mão ao lado da cabeça, sem tocar a coroa nem as orelhas. Os arcos são de perfil e não provam isso.
- No jogo, com `tour.tscn`: goblin, esqueleto e chefe golpeiam para o lado do jogador.
- A espada do esqueleto continua na mão e não entra no corpo em repouso. A clava do goblin foi registrada na OS-006.

## Revisão de 01/11/2026: AJUSTES

`pose_cast`, `pose_strike`, a direção dos golpes e o sinal de X estão certos e continuam. Faltam a curva do joelho, o `swing` e o `pose_swing.png`, nas seções acima. Se os números não atenderem aos critérios, não os ajuste: volte à direção de arte com a medida.

## Segunda revisão de 01/11/2026: AJUSTES

Joelho, `walk_side`, tira do passo, `pose_cast`, `pose_strike` e `swing` estão aprovados nos renders de perfil. A curva do `swing` não muda: o critério é que estava errado, e a J9 foi corrigida. Faltam as 3 verificações de regressão e a imagem de frente do quadro armado, sem mudança visual.

## Revisão final de 01/11/2026: APROVADO

`armado_frente.png` confirma a J9: mão ao lado da cabeça, golpe legível como lateral. A menor folga do golpe inteiro é a do armado: `frost_king` a 0,275 m do chifre e 0,381 m dos cristais, `goblin` a 0,349 m da orelha. Com o bloco `swing` do `HEAD`, só as 3 verificações novas falham. `overhead` e `thrust` são iguais ao `HEAD`, e a espada do esqueleto em repouso fica na mão, fora do corpo.
