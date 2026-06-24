class_name ArmaGranada
extends Arma


const EscenaGranada = preload("res://entities/granada.tscn")
const GRAVEDAD := 980.0
const RADIO_EXPLOSION := 95.0


func _init() -> void:
	nombre = "Granada"


func disparar(unidad, inicio: Vector2, _direccion: Vector2) -> float:
	var objetivo = unidad.get_global_mouse_position()
	var vel = _velocidad(inicio, objetivo)
	var granada = EscenaGranada.instantiate()
	unidad.get_parent().add_child(granada)
	granada.lanzar(inicio, vel, unidad.danio_base, unidad)
	return 1.6


func calcular_mira(unidad, inicio: Vector2, _direccion: Vector2) -> Dictionary:
	var objetivo = unidad.get_global_mouse_position()
	var arco = _arco(unidad, inicio, objetivo)
	var datos := {
		"linea": arco,
		"color": Color(0.4, 1.0, 0.4, 0.85),
	}
	if arco.size() > 0:
		var circ = Arma.circulo(arco[arco.size() - 1], RADIO_EXPLOSION)
		datos["circulo"] = circ
		datos["relleno"] = circ
		datos["color_relleno"] = Color(0.4, 1.0, 0.4, 0.18)
	return datos


# Velocidad de lanzamiento para que la granada caiga en 'objetivo'.
func _velocidad(inicio: Vector2, objetivo: Vector2) -> Vector2:
	var t = clampf(inicio.distance_to(objetivo) / 420.0, 0.45, 1.5)
	var vx = (objetivo.x - inicio.x) / t
	var vy = (objetivo.y - inicio.y) / t - 0.5 * GRAVEDAD * t
	return Vector2(vx, vy)


# Simula el arco con gravedad y frena al tocar terreno.
func _arco(unidad, inicio: Vector2, objetivo: Vector2) -> Array[Vector2]:
	var space_state = unidad.get_world_2d().direct_space_state
	var excluir: Array[RID] = [unidad.get_rid()]
	var pos = inicio
	var vel = _velocidad(inicio, objetivo)
	var dt = 1.0 / 60.0
	var puntos: Array[Vector2] = [pos]
	for i in range(120):
		vel.y += GRAVEDAD * dt
		var siguiente = pos + vel * dt
		var query = PhysicsRayQueryParameters2D.create(pos, siguiente)
		query.collision_mask = 1
		query.exclude = excluir
		var res = space_state.intersect_ray(query)
		if res:
			puntos.append(res.position)
			break
		pos = siguiente
		puntos.append(pos)
	return puntos
