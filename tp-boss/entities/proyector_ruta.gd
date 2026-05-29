class_name ProyectorRuta
extends Node2D

var jugador: UnidadBase = null

const DISTANCIA_NARANJA = 220.0
const DISTANCIA_CELESTE = 440.0

var puntos_resaltados: Array[Dictionary] = []

var _ruta_preview: PackedVector2Array = []
var _distancia_preview: float = 0.0
var _destino_preview: Vector2 = Vector2.INF
var _ruta_valida: bool = false

var raycast_suelo: RayCast2D

signal ruta_seleccionada(path: PackedVector2Array, dist: float, destino: Vector2, es_naranja: bool)

func _ready() -> void:
	jugador = get_parent()
	
	raycast_suelo = RayCast2D.new()
	raycast_suelo.enabled = false  
	raycast_suelo.collision_mask = 1  
	add_child(raycast_suelo)
	
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not _puede_proyectar():
		_limpiar_preview()
		return
	
	_actualizar_excepciones_raycast()
	_calcular_preview()
	
	if _ruta_valida and _distancia_preview <= DISTANCIA_CELESTE:
		if Input.is_action_just_pressed("click_disparar"):
			var es_naranja = _distancia_preview <= DISTANCIA_NARANJA
			ruta_seleccionada.emit(_ruta_preview, _distancia_preview, _destino_preview, es_naranja)
	
	queue_redraw()

func _draw() -> void:
	if not _puede_proyectar():
		return
	
	if puntos_resaltados.is_empty():
		actualizar_zonas_resaltadas()
	
	for pt in puntos_resaltados:
		var local_pos = pt.pos_local
		var color_pt = pt.color
		var color_glow = Color(color_pt.r, color_pt.g, color_pt.b, 0.12)
		draw_line(local_pos + Vector2(-12, 0), local_pos + Vector2(12, 0), color_glow, 10.0)
		draw_line(local_pos + Vector2(-10, 0), local_pos + Vector2(10, 0), color_pt, 4.0)
	
	if not _ruta_valida or _ruta_preview.size() < 2:
		return
	
	_dibujar_ruta_segmentada(_ruta_preview)
	
	var color_dest = Color(0.9, 0.45, 0.15, 0.85)
	if _distancia_preview > DISTANCIA_CELESTE:
		color_dest = Color(0.85, 0.2, 0.2, 0.85)
	elif _distancia_preview > DISTANCIA_NARANJA:
		color_dest = Color(0.15, 0.85, 0.9, 0.85)
		
	var local_dest = to_local(_destino_preview)
	if _distancia_preview <= DISTANCIA_CELESTE:
		draw_circle(local_dest, 6.0, color_dest)
		draw_arc(local_dest, 10.0, 0, TAU, 32, color_dest, 1.5)
	else:
		draw_circle(local_dest, 5.0, color_dest)


func _puede_proyectar() -> bool:
	return is_instance_valid(jugador) \
		and jugador.estado == jugador.Estado.MOVIMIENTO \
		and not jugador.moviendo_a_destino \
		and jugador.is_on_floor() \
		and not jugador.fin_turno_iniciado


func _limpiar_preview() -> void:
	_ruta_valida = false
	_ruta_preview = []
	_destino_preview = Vector2.INF
	puntos_resaltados.clear()
	queue_redraw()


func _calcular_preview() -> void:
	_ruta_valida = false
	
	var pos_mouse = get_global_mouse_position()
	var pos_proyectada = obtener_punto_superficie(pos_mouse)
	
	if pos_proyectada == Vector2.INF:
		return
	
	var astar = GeneradorNavegacion.astar
	var id_origen = astar.get_closest_point(jugador.global_position)
	var id_destino = astar.get_closest_point(pos_proyectada)
	
	var nodo_pos = astar.get_point_position(id_destino)
	if pos_proyectada.distance_to(nodo_pos) >= 25.0:
		return
	
	var path = astar.get_point_path(id_origen, id_destino)
	if path.size() <= 0:
		return
	if path.size() == 1 and id_origen != id_destino:
		return
	
	_ruta_preview = path
	_distancia_preview = _calcular_longitud_ruta(path)
	_destino_preview = pos_proyectada
	_ruta_valida = true

func obtener_punto_superficie(pos_mouse: Vector2) -> Vector2:
	if pos_mouse.x < GeneradorNavegacion.limite_escenario_izq or pos_mouse.x > GeneradorNavegacion.limite_escenario_der:
		return Vector2.INF
	
	var escaleras = get_tree().get_nodes_in_group("escaleras")
	for escalera in escaleras:
		if is_instance_valid(escalera):
			var col = escalera.find_child("CollisionShape2D", true, false)
			if col and col.shape is RectangleShape2D:
				var size = col.shape.size
				var pos = escalera.global_position
				var rect = Rect2(pos - size / 2.0, size)
				if rect.has_point(pos_mouse):
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
	
	
	raycast_suelo.global_position = Vector2(pos_mouse.x, pos_mouse.y - 20)
	raycast_suelo.target_position = Vector2(0, 40) 
	raycast_suelo.force_raycast_update()
	
	if raycast_suelo.is_colliding():
		var collider = raycast_suelo.get_collider()
		if collider in GeneradorNavegacion.plataformas_walkables:
			return raycast_suelo.get_collision_point()
	
	return Vector2.INF

func _dibujar_ruta_segmentada(path: PackedVector2Array) -> void:
	var d_acum = 0.0
	for i in range(path.size() - 1):
		var A = path[i]
		var B = path[i + 1]
		_dibujar_segmento_segmentado(A, B, d_acum)
		d_acum += A.distance_to(B)

func _dibujar_segmento_segmentado(A: Vector2, B: Vector2, d_start: float) -> void:
	var L = A.distance_to(B)
	if L <= 0.001:
		return
	
	var color_naranja = Color(0.9, 0.45, 0.15, 0.9)
	var color_celeste = Color(0.15, 0.85, 0.9, 0.9)
	var color_rojo = Color(0.85, 0.2, 0.2, 0.5)
	
	var t_naranja = (DISTANCIA_NARANJA - d_start) / L
	var t_celeste = (DISTANCIA_CELESTE - d_start) / L
	
	var cortes = [0.0, 1.0]
	if t_naranja > 0.0 and t_naranja < 1.0:
		cortes.append(t_naranja)
	if t_celeste > 0.0 and t_celeste < 1.0:
		cortes.append(t_celeste)
	cortes.sort()
	
	for i in range(cortes.size() - 1):
		var t1 = cortes[i]
		var t2 = cortes[i + 1]
		var t_mid = (t1 + t2) / 2.0
		var d_mid = d_start + t_mid * L
		
		var color_actual = color_naranja
		var grosor = 3.0
		if d_mid > DISTANCIA_CELESTE:
			color_actual = color_rojo
			grosor = 2.0
		elif d_mid > DISTANCIA_NARANJA:
			color_actual = color_celeste
			grosor = 3.0
			
		var p1 = to_local(A.lerp(B, t1)) + Vector2(0, -6)
		var p2 = to_local(A.lerp(B, t2)) + Vector2(0, -6)
		draw_line(p1, p2, color_actual, grosor)

func _calcular_longitud_ruta(ruta: PackedVector2Array) -> float:
	var longitud = 0.0
	for i in range(ruta.size() - 1):
		longitud += ruta[i].distance_to(ruta[i + 1])
	return longitud

func _actualizar_excepciones_raycast() -> void:
	raycast_suelo.clear_exceptions()
	for u in get_tree().get_nodes_in_group("unidades"):
		if is_instance_valid(u):
			raycast_suelo.add_exception(u)



func actualizar_zonas_resaltadas() -> void:
	puntos_resaltados.clear()
	var astar = GeneradorNavegacion.astar
	if not astar or astar.get_point_count() == 0:
		return
	
	var id_origen = astar.get_closest_point(jugador.global_position)
	
	for id in astar.get_point_ids():
		var path = astar.get_point_path(id_origen, id)
		if path.size() > 0:
			var dist = _calcular_longitud_ruta(path)
			if dist <= DISTANCIA_CELESTE:
				var color_zona = Color(0.9, 0.45, 0.15, 0.45) if dist <= DISTANCIA_NARANJA else Color(0.15, 0.85, 0.9, 0.45)
				puntos_resaltados.append({
					"pos_local": to_local(astar.get_point_position(id)),
					"color": color_zona
				})
