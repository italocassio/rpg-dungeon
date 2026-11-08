class_name SkillFxData
extends Resource
## Efeitos visuais de uma habilidade de inimigo (OS-022). Só dados: quem desenha é o AttackFx.
## `SkillData.fx` nulo mantém o comportamento genérico de hoje.

enum TelegraphStyle { NONE, PLAIN, CONE_TEETH, CRACKS, CHEVRONS, CROWN }
enum PrepStyle { NONE, BLADE, TIP_CRYSTALS, CORE, WINTER }
enum ImpactStyle { NONE, ARC, SCYTHE, FRACTURE, STAKES, CROWN }

## Fração do alcance do tremor em que a força ainda é cheia.
const SHAKE_FULL_FRACTION: float = 0.35

@export_group("Zona")
## NONE apaga a zona mesmo com `SkillData.telegraph` verdadeiro.
@export var telegraph_style: TelegraphStyle = TelegraphStyle.PLAIN

@export_group("Preparo")
@export var prep_style: PrepStyle = PrepStyle.NONE
## Joint do rig que ancora o sinal. Se não existir, usa a origem do inimigo.
@export var prep_anchor: StringName = &"weapon_tip"
## `glow` do cristal alvo no último instante do preparo.
@export_range(0.0, 7.0, 0.1) var prep_peak: float = 3.0
## Partículas do emissor de preparo. No `WINTER` conta as lascas da convergência (a cadência dá 27 na nova).
@export_range(0, 80) var prep_motes: int = 0
## Trauma repetido a cada 0,5 s durante o preparo.
@export_range(0.0, 1.0, 0.01) var prep_shake: float = 0.0

@export_group("Impacto")
@export var impact_style: ImpactStyle = ImpactStyle.NONE
## Alfa 0 usa `Enemy.glow`.
@export var impact_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export_range(0.1, 3.0, 0.05) var impact_scale: float = 1.0
## Vida total do efeito, com o desaparecimento, em segundos.
@export_range(0.05, 5.0, 0.05) var impact_duration: float = 0.5
## Segundos depois do `skill_fired`.
@export_range(0.0, 1.0, 0.01) var impact_delay: float = 0.0
## Trauma no impacto, na distância 0 do alcance cheio.
@export_range(0.0, 1.0, 0.01) var shake_strength: float = 0.0
## Distância em metros em que o tremor chega a zero.
@export_range(0.0, 60.0, 0.5) var shake_radius: float = 0.0
## Energia da luz do clarão. 0 não cria luz.
@export_range(0.0, 8.0, 0.1) var flash_energy: float = 0.0


## Trauma sentido a `distance` metros do impacto: cheio até 35% do raio, linear até zero no raio.
static func shake_trauma(strength: float, radius: float, distance: float) -> float:
	if radius <= 0.0:
		return 0.0
	var falloff: float = clampf(1.0 - (distance - SHAKE_FULL_FRACTION * radius) / ((1.0 - SHAKE_FULL_FRACTION) * radius), 0.0, 1.0)
	return minf(strength * falloff, strength)
