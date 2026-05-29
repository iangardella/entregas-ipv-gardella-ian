class_name CalculadorRuta

const DISTANCIA_NARANJA = 220.0
const DISTANCIA_CELESTE = 440.0

const COLOR_NARANJA = Color(0.9, 0.45, 0.15, 0.45)
const COLOR_CELESTE = Color(0.15, 0.85, 0.9, 0.45)

func calcular(pos_origen: Vector2, pos_destino: Vector2) -> Dictionary:
	var resultado = {"path": PackedVector2Array(), "distancia": 0.0, "destino": pos_destino, "valida": false}

	var astar = GeneradorNavegacion.astar
	var id_origen = astar.get_closest_point(pos_origen)
	var id_destino = astar.get_closest_point(pos_destino)

	var nodo_pos = astar.get_point_position(id_destino)
	if pos_destino.distance_to(nodo_pos) >= 25.0:
		return resultado

	var path = astar.get_point_path(id_origen, id_destino)
	if path.size() <= 0:
		return resultado
	if path.size() == 1 and id_origen != id_destino:
		return resultado

	resultado.path = path
	resultado.distancia = calcular_longitud(path)
	resultado.valida = true
	return resultado

func calcular_longitud(ruta: PackedVector2Array) -> float:
	var longitud = 0.0
	for i in range(ruta.size() - 1):
		longitud += ruta[i].distance_to(ruta[i + 1])
	return longitud

func calcular_zonas_alcanzables(pos_origen: Vector2, canvas: CanvasItem) -> Array[Dictionary]:
	var puntos: Array[Dictionary] = []
	var astar = GeneradorNavegacion.astar
	if not astar or astar.get_point_count() == 0:
		return puntos

	var id_origen = astar.get_closest_point(pos_origen)

	for id in astar.get_point_ids():
		var path = astar.get_point_path(id_origen, id)
		if path.size() > 0:
			var dist = calcular_longitud(path)
			if dist <= DISTANCIA_CELESTE:
				var color_zona = COLOR_NARANJA if dist <= DISTANCIA_NARANJA else COLOR_CELESTE
				puntos.append({
					"pos_local": canvas.to_local(astar.get_point_position(id)),
					"color": color_zona
				})

	return puntos
