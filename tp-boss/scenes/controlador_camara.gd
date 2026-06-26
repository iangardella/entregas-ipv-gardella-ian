class_name ControladorCamara
extends RefCounted

const VEL_LERP := 7.5

var _camara: Camera2D
var _arbol: SceneTree
var _ultima_unidad: Node2D = null
var _pos_ultimo_impacto: Vector2 = Vector2.INF


func _init(camara: Camera2D, arbol: SceneTree) -> void:
	_camara = camara
	_arbol = arbol
	_camara.limit_left = -70
	_camara.limit_right = 1220
	_camara.limit_top = 50
	_camara.limit_bottom = 520


func actualizar(delta: float) -> void:
	var objetivo := _objetivo_a_seguir()
	if objetivo != Vector2.INF:
		_camara.global_position = _camara.global_position.lerp(objetivo, VEL_LERP * delta)


func _objetivo_a_seguir() -> Vector2:
	var bala := _bala_en_vuelo()
	if bala != null:
		_pos_ultimo_impacto = bala.global_position
		return bala.global_position

	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and activa is UnidadBase:
		if _pos_ultimo_impacto != Vector2.INF and activa == _ultima_unidad:
			return _pos_ultimo_impacto
		_pos_ultimo_impacto = Vector2.INF
		_ultima_unidad = activa
		return activa.obtener_punto_camara()
	return Vector2.INF


func _bala_en_vuelo() -> Node2D:
	for b in _arbol.get_nodes_in_group("balas"):
		if is_instance_valid(b):
			return b
	return null
