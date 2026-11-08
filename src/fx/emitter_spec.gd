class_name EmitterSpec
extends RefCounted
## Descrição de um emissor de partículas dos efeitos do chefe (OS-022). Só dados; quem monta é `Vfx.emitter`.

enum Shape { SPHERE, RING }

var amount: int = 12
var lifetime: float = 0.8
var sprite: String = ParticleKit.SPARK
var additive: bool = true
## Lado do quadro da partícula, em metros.
var size: float = 0.16
var color: Color = Color.WHITE
## Escala da partícula ao nascer e ao morrer, sobre `size`.
var scale_start: float = 1.0
var scale_end: float = 0.35
## Fração da vida em que a partícula começa a sumir.
var fade_start: float = 0.5
var shape: Shape = Shape.SPHERE
var shape_radius: float = 0.2
var direction: Vector3 = Vector3.UP
var spread: float = 180.0
var speed_min: float = 0.5
var speed_max: float = 1.0
var gravity: Vector3 = Vector3.ZERO
## Aceleração radial: negativa puxa para o centro do emissor.
var radial_accel_min: float = 0.0
var radial_accel_max: float = 0.0
var damping: float = 0.0
var one_shot: bool = false
var explosiveness: float = 0.0
## Partículas ficam no mundo ao mover o emissor (rastro de uma ponta que se move).
var world_space: bool = true
