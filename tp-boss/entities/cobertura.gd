class_name Cobertura
extends RefCounted

const RANGO := 60.0

var activa: bool = false
var barril: Node = null

var _u


func _init(unidad) -> void:
	_u = unidad


func reset() -> void:
	activa = false
	barril = null


func barril_cercano() -> Node:
	var mejor: Node = null
	var mejor_dist := RANGO
	for b in _u.get_tree().get_nodes_in_group("barriles"):
		if is_instance_valid(b):
			var dd: float = _u.global_position.distance_to(b.global_position)
			if dd < mejor_dist:
				mejor_dist = dd
				mejor = b
	return mejor


func cubrir(barril_forzado = null) -> void:
	var b = barril_forzado if barril_forzado != null else barril_cercano()
	if b == null or not is_instance_valid(b):
		return
	_u._entrar_en_accion()
	var lado := _lado(b)
	activa = true
	barril = b
	_u.global_position.x = b.global_position.x + lado * 28.0
	_u.visual.flip_h = lado > 0.0
	_u._actualizar_marcador()
	_u._programar_fin_disparo(0.4)


func recubrir_tras_disparo() -> void:
	var b = barril_cercano()
	if b == null:
		return
	activa = true
	barril = b
	var lado := _lado(b)
	if lado != 0.0:
		_u.visual.flip_h = lado > 0.0


func chequear_barril() -> void:
	if activa and not is_instance_valid(barril):
		activa = false
		barril = null


func _lado(b) -> float:
	var lado := signf(_u.global_position.x - b.global_position.x)
	return 1.0 if lado == 0.0 else lado
