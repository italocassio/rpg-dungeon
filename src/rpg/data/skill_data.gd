class_name SkillData
extends Resource
## Definição de habilidade. O mesmo formato serve para jogador, bots e monstros.

enum Delivery { MELEE_CONE, LINE, PROJECTILE, GROUND_AOE, SELF_AOE, TARGET_ALLY, PARTY, SELF_BUFF, DASH, BLINK, HEAL_ZONE }
enum DamageKind { PHYSICAL, MAGICAL, HEAL, NONE }
## Os cinco elementos de Perfect World.
enum Element { NONE, METAL, WOOD, WATER, FIRE, EARTH }

const ELEMENT_NAMES: Dictionary = {
	Element.NONE: "Neutro", Element.METAL: "Metal", Element.WOOD: "Madeira",
	Element.WATER: "Água", Element.FIRE: "Fogo", Element.EARTH: "Terra",
}
const DAMAGE_KIND_NAMES: Dictionary = {
	DamageKind.PHYSICAL: "Físico", DamageKind.MAGICAL: "Mágico",
	DamageKind.HEAL: "Cura", DamageKind.NONE: "Suporte",
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: StringName = &"slash"
@export var color: Color = Color.WHITE

@export_group("Entrega")
@export var delivery: Delivery = Delivery.MELEE_CONE
@export var skill_range: float = 3.0
@export var radius: float = 0.0
@export var cone_degrees: float = 90.0
@export var line_width: float = 2.0
@export var projectile_speed: float = 30.0
## Atraso entre o fim do cast e o impacto (ex.: meteoro).
@export var impact_delay: float = 0.0
@export var zone_duration: float = 0.0
@export var zone_tick_interval: float = 1.0
@export var revives_allies: bool = false
@export_range(0.0, 1.0) var revive_hp_ratio: float = 0.5

@export_group("Dano")
@export var damage_kind: DamageKind = DamageKind.PHYSICAL
@export var element: Element = Element.NONE
@export var power: float = 1.0
@export var threat_multiplier: float = 1.0

@export_group("Custos")
@export var cast_time: float = 0.0
@export var cooldown: float = 1.0
@export var triggers_global_cooldown: bool = true
@export var mp_cost: float = 0.0
@export var chi_cost: float = 0.0
@export var chi_gain: float = 0.0

@export_group("Efeitos")
@export var target_effect: EffectData
@export var self_effect: EffectData

@export_group("Animação e aviso")
## Monstros: mostra a área de perigo no chão durante o cast.
@export var telegraph: bool = false
@export var animation: StringName = &"swing"


func cast_duration(stats: StatBlock) -> float:
	return cast_time / maxf(stats.cast_speed, 0.1)


## Velocidade de ataque só encurta a recarga de habilidades instantâneas.
func recovery_time(stats: StatBlock) -> float:
	var speed: float = stats.attack_speed if cast_time <= 0.0 else 1.0
	return cooldown / maxf(speed, 0.1)


## O primeiro pulso da zona é imediato, por isso arredonda para cima.
func zone_tick_count() -> int:
	return ceili(zone_duration / zone_tick_interval)
