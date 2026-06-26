class_name Escopeta
extends Arma


const EscenaBala = preload("res://entities/bala.tscn")
const PERDIGONES := 6
const APERTURA := 28.0
const ALCANCE := 360.0
const EMPUJE := 260.0


func _init() -> void:
	nombre = "Escopeta"


func disparar(unidad, inicio: Vector2, direccion: Vector2) -> float:
	var base_ang = direccion.angle()
	var ap = deg_to_rad(APERTURA)
	for i in range(PERDIGONES):
		var t = float(i) / float(PERDIGONES - 1) - 0.5
		var d = Vector2.from_angle(base_ang + t * ap)
		var bala = EscenaBala.instantiate()
		unidad.get_parent().add_child(bala)
		bala.lanzar(inicio, d, int(round(unidad.danio_base * 0.5)), unidad, EMPUJE, ALCANCE, 1, 2)
	return 0.8


func calcular_mira(unidad, inicio: Vector2, direccion: Vector2) -> Dictionary:
	var cono = _cono(unidad, inicio, direccion)
	return {
		"linea": cono,
		"color": Color(1.0, 0.7, 0.2, 0.7),
		"relleno": cono,
		"color_relleno": Color(1.0, 0.7, 0.2, 0.16),
	}


func _cono(unidad, inicio: Vector2, direccion: Vector2) -> Array[Vector2]:
	var space_state = unidad.get_world_2d().direct_space_state
	var excluir: Array[RID] = [unidad.get_rid()]
	var ang0 = direccion.angle()
	var ap = deg_to_rad(APERTURA)
	var n = 8
	var puntos: Array[Vector2] = [inicio]
	for i in range(n + 1):
		var t = float(i) / float(n) - 0.5
		var d = Vector2.from_angle(ang0 + t * ap)
		var fin = inicio + d * ALCANCE
		var query = PhysicsRayQueryParameters2D.create(inicio, fin)
		query.exclude = excluir
		var res = space_state.intersect_ray(query)
		puntos.append(res.position if res else fin)
	puntos.append(inicio)
	return puntos
