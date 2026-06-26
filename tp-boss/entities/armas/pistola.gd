class_name Pistola
extends Arma

const EscenaBala = preload("res://entities/bala.tscn")
const REBOTES := 2


func _init() -> void:
	nombre = "Pistola"


func disparar(unidad, inicio: Vector2, direccion: Vector2) -> float:
	var bala = EscenaBala.instantiate()
	unidad.get_parent().add_child(bala)
	bala.lanzar(inicio, direccion, int(round(unidad.danio_base * 0.6)), unidad, 0.0, -1.0, REBOTES, 1)
	return 0.8


func calcular_mira(unidad, inicio: Vector2, direccion: Vector2) -> Dictionary:
	return {
		"linea": _trayectoria_rebote(unidad, inicio, direccion),
		"color": Color(1.0, 0.3, 0.2, 0.75),
	}


func _trayectoria_rebote(unidad, inicio: Vector2, direccion: Vector2) -> Array[Vector2]:
	var space_state = unidad.get_world_2d().direct_space_state
	var excluir: Array[RID] = [unidad.get_rid()]

	var query_inicio = PhysicsRayQueryParameters2D.create(unidad.arma.global_position, inicio)
	query_inicio.exclude = excluir
	var res_inicio = space_state.intersect_ray(query_inicio)

	var pos_actual = inicio
	var puntos: Array[Vector2] = []

	if res_inicio:
		puntos.append(res_inicio.position)
		return puntos

	puntos.append(inicio)
	var dir_actual = direccion
	var max_rebotes = REBOTES

	for i in range(max_rebotes + 1):
		var destino = pos_actual + dir_actual * 1500.0
		var query = PhysicsRayQueryParameters2D.create(pos_actual, destino)
		query.exclude = excluir
		var resultado = space_state.intersect_ray(query)
		if resultado:
			puntos.append(resultado.position)
			var colisionador = resultado.collider
			if colisionador.is_in_group("unidades") and colisionador != unidad:
				break
			var normal = resultado.normal
			pos_actual = resultado.position + normal * 0.2
			dir_actual = dir_actual.bounce(normal)
		else:
			puntos.append(destino)
			break

	return puntos
