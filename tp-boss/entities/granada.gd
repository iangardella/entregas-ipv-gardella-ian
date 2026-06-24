extends Node2D

const EscenaExplosion = preload("res://entities/explosion.tscn")
const GRAVEDAD = 980.0
const RADIO_EXPLOSION = 95.0
const FUERZA_EMPUJE = 300.0
const VIDA_MAX = 1.5

@onready var raycast: RayCast2D = $RayCast2D

var velocidad: Vector2 = Vector2.ZERO
var danio: int = 25
var tirador: Node2D = null
var explotada: bool = false
var tiempo: float = 0.0


func lanzar(pos: Vector2, velocidad_inicial: Vector2, valor_danio: int, unidad_tirador: Node2D) -> void:
	global_position = pos
	danio = valor_danio
	tirador = unidad_tirador
	velocidad = velocidad_inicial


func _ready() -> void:
	add_to_group("balas")
	if is_instance_valid(tirador):
		raycast.add_exception(tirador)


func _physics_process(delta: float) -> void:
	if explotada:
		return
	tiempo += delta
	velocidad.y += GRAVEDAD * delta
	var paso := velocidad * delta
	raycast.target_position = paso
	raycast.force_raycast_update()
	if raycast.is_colliding():
		global_position = raycast.get_collision_point()
		_explotar()
	else:
		global_position += paso
		if tiempo >= VIDA_MAX:
			_explotar()


func _explotar() -> void:
	if explotada:
		return
	explotada = true

	var efecto = EscenaExplosion.instantiate()
	get_parent().add_child(efecto)
	efecto.global_position = global_position

	for u in get_tree().get_nodes_in_group("unidades"):
		if is_instance_valid(u) and u != tirador:
			var dist: float = u.global_position.distance_to(global_position)
			if dist <= RADIO_EXPLOSION:
				var factor: float = 1.0 - dist / RADIO_EXPLOSION
				if u.has_method("recibir_danio"):
					u.recibir_danio(int(round(danio * (0.6 + 0.4 * factor))))
				if u.has_method("aplicar_empuje"):
					u.aplicar_empuje(global_position, FUERZA_EMPUJE)
	queue_free()
