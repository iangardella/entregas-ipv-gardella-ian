extends Node
var astar: AStar2D = AStar2D.new()
var plataformas_walkables: Array[StaticBody2D] = []
var limite_escenario_izq: float = -INF
var limite_escenario_der: float = INF

func generar_grafo() -> void:
	astar.clear()
	plataformas_walkables.clear()
	var nivel = get_tree().current_scene.find_child("Nivel", true, false)
	_calcular_limites(nivel)
	var plataformas = _recolectar_plataformas(nivel)
	var todos_los_nodos = _crear_puntos_astar(plataformas)
	_conectar_escaleras(todos_los_nodos)


func _calcular_limites(nivel: Node) -> void:
	limite_escenario_izq = -INF
	limite_escenario_der = INF
	for child in nivel.get_children():
		if not (child is StaticBody2D and child.name.to_lower().contains("pared")):
			continue
		var col = child.find_child("CollisionShape2D", true, false)
		if col and col.shape is RectangleShape2D:
			var size = col.shape.size 
			if child.global_position.x < 500:
				limite_escenario_izq = child.global_position.x + (size.x / 2.0)
			else:
				limite_escenario_der = child.global_position.x - (size.x / 2.0)


func _recolectar_plataformas(nivel: Node) -> Array:
	var plataformas = []
	for child in nivel.get_children():
		if not child is StaticBody2D:
			continue
		var nombre = child.name.to_lower()
		if nombre.contains("techo") or nombre.contains("pared"):
			continue
		var col = child.find_child("CollisionShape2D", true, false)
		if not (col and col.shape is RectangleShape2D):
			continue
		var size = col.shape.size
		if size.y > size.x:
			continue
		var pos_global = child.global_position
		var y_top = pos_global.y - (size.y / 2.0)
		var x_min = clamp(pos_global.x - (size.x / 2.0), limite_escenario_izq, limite_escenario_der)
		var x_max = clamp(pos_global.x + (size.x / 2.0), limite_escenario_izq, limite_escenario_der)
		if x_min >= x_max:
			continue
		plataformas.append({"y": y_top, "x_min": x_min, "x_max": x_max, "node": child})
		plataformas_walkables.append(child)
	return plataformas


func _crear_puntos_astar(plataformas: Array) -> Array:
	var todos_los_nodos = []
	var paso = 20.0
	var id_counter = 1

	for plat in plataformas:
		var lista_nodos_plat = []
		var x = plat.x_min
		while x <= plat.x_max + 1.0:
			var pos_nodo = Vector2(x, plat.y)
			astar.add_point(id_counter, pos_nodo)
			lista_nodos_plat.append({"id": id_counter, "pos": pos_nodo, "node": plat.node})
			id_counter += 1
			x += paso

		if lista_nodos_plat[-1].pos.x < plat.x_max:
			var pos_nodo = Vector2(plat.x_max, plat.y)
			astar.add_point(id_counter, pos_nodo)
			lista_nodos_plat.append({"id": id_counter, "pos": pos_nodo, "node": plat.node})
			id_counter += 1

		for i in range(lista_nodos_plat.size() - 1):
			astar.connect_points(lista_nodos_plat[i].id, lista_nodos_plat[i + 1].id, true)

		todos_los_nodos.append_array(lista_nodos_plat)

	return todos_los_nodos

func _construir_exclusiones() -> Array[RID]:
	var excluir: Array[RID] = []
	for u in get_tree().get_nodes_in_group("unidades"):
		if is_instance_valid(u):
			excluir.append(u.get_rid())
	return excluir


func _conectar_escaleras(_todos_los_nodos: Array) -> void:
	var escaleras = get_tree().get_nodes_in_group("escaleras")
	for escalera in escaleras:
		if not is_instance_valid(escalera):
			continue
		
		var col = escalera.find_child("CollisionShape2D", true, false)
		if not (col and col.shape is RectangleShape2D):
			continue
		
		var size = col.shape.size
		var pos = escalera.global_position
		var x_centro = pos.x
		var y_top = pos.y - (size.y / 2.0)
		var y_bottom = pos.y + (size.y / 2.0)
		
		var id_top = astar.get_closest_point(Vector2(x_centro, y_top))
		var id_bottom = astar.get_closest_point(Vector2(x_centro, y_bottom))
		
		if id_top != id_bottom:
			astar.connect_points(id_top, id_bottom, true)
