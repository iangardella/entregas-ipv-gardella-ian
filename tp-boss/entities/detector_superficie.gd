class_name DetectorSuperficie

var _raycast: RayCast2D
var _owner_node: Node2D

func _init(owner: Node2D) -> void:
	_owner_node = owner
	_raycast = RayCast2D.new()
	_raycast.enabled = false
	_raycast.collision_mask = 1
	owner.add_child(_raycast)

func actualizar_excepciones(tree: SceneTree) -> void:
	_raycast.clear_exceptions()
	for u in tree.get_nodes_in_group("unidades"):
		if is_instance_valid(u):
			_raycast.add_exception(u)

func obtener_punto_superficie(pos_mouse: Vector2) -> Vector2:
	if pos_mouse.x < GeneradorNavegacion.limite_escenario_izq or pos_mouse.x > GeneradorNavegacion.limite_escenario_der:
		return Vector2.INF

	var punto_escalera = _buscar_en_escaleras(pos_mouse)
	if punto_escalera != Vector2.INF:
		return punto_escalera

	return _buscar_en_suelo(pos_mouse)

func _buscar_en_escaleras(pos_mouse: Vector2) -> Vector2:
	var escaleras = _owner_node.get_tree().get_nodes_in_group("escaleras")
	for escalera in escaleras:
		if not is_instance_valid(escalera):
			continue
		var col = escalera.find_child("CollisionShape2D", true, false)
		if not (col and col.shape is RectangleShape2D):
			continue
		var size = col.shape.size
		var pos = escalera.global_position
		var rect = Rect2(pos - size / 2.0, size)
		if not rect.has_point(pos_mouse):
			continue

		var y_top = pos.y - (size.y / 2.0)
		var y_bottom = pos.y + (size.y / 2.0)
		var dist_top = abs(pos_mouse.y - y_top)
		var dist_bottom = abs(pos_mouse.y - y_bottom)
		var x_centro = pos.x
		var target_y = y_top if dist_top < dist_bottom else y_bottom

		var astar = GeneradorNavegacion.astar
		if astar and astar.get_point_count() > 0:
			var id_cercano = astar.get_closest_point(Vector2(x_centro, target_y))
			return astar.get_point_position(id_cercano)

		return Vector2(x_centro, target_y)

	return Vector2.INF

func _buscar_en_suelo(pos_mouse: Vector2) -> Vector2:
	_raycast.global_position = Vector2(pos_mouse.x, pos_mouse.y - 20)
	_raycast.target_position = Vector2(0, 40)
	_raycast.force_raycast_update()

	if _raycast.is_colliding():
		var collider = _raycast.get_collider()
		if collider in GeneradorNavegacion.plataformas_walkables:
			return _raycast.get_collision_point()

	return Vector2.INF
