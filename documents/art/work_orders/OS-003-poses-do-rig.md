# OS-003: Corrigir poses do rig

- **Agente:** `gameplay-developer`
- **Depende de:** OS-001
- **Arquivos:** `src/visuals/creature_rig.gd`
- **Fora do escopo:** `_pose_quadruped`, `_pose_hover`, ritmo de ataque, gameplay.

## Problema

Atores viram o **-Z** do modelo para a direção do movimento (`atan2(-x, -z)`), e as malhas olham para -Z. Mas `_pose_biped` foi escrito como se a frente fosse +Z. Resultado em todo bípede, herói ou inimigo:

- Conjurar leva os dois braços para trás das costas.
- Golpes e estocadas saem para trás.
- Joelhos dobram para a frente.

Veja `concepts/blockout/antes_depois_pose.png`.

## Correção

Inverta o sinal de X ao aplicar as poses. Os cálculos internos ficam iguais.

```gdscript
var knee_bend: float = 1.1
var arm_swing_r: float = 0.7
var arm_swing_l: float = 0.7

# em _pose_biped
_set_joint(&"hip_l", Vector3(-swing, 0.0, 0.0))
_set_joint(&"hip_r", Vector3(swing, 0.0, 0.0))
_set_joint(&"knee_l", Vector3(-maxf(-sin(_phase), 0.0) * knee_bend * _blend, 0.0, 0.0))
_set_joint(&"knee_r", Vector3(-maxf(sin(_phase), 0.0) * knee_bend * _blend, 0.0, 0.0))
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

## Critérios de aceite

Renders de `hero_review`, com os modelos atuais:

- `pose_cast.png`: mãos à frente do peito, do lado do nariz do elmo.
- `pose_strike.png`: arma desce à frente do corpo.
- `walk_side.png`: joelho de trás dobra para trás e o pé fica atrás do quadril. O braço oposto à perna da frente vai à frente.
- No jogo, com `tour.tscn`: goblin, esqueleto e chefe golpeiam para o lado do jogador.
- A espada do esqueleto e a clava do goblin continuam na mão e não entram no corpo em repouso. Se entrarem, avise: a correção entra na OS-006.
