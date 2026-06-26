class_name IndicadorCobertura
extends RefCounted

var _boton: TextureButton
var _arbol: SceneTree
var barril: Node = null


func _init(boton: TextureButton, arbol: SceneTree) -> void:
	_boton = boton
	_arbol = arbol
	_boton.visible = false


func actualizar(activa) -> void:
	var puede: bool = activa.estado == UnidadBase.Estado.MOVIMIENTO and not activa.moviendo_a_destino and not activa.ya_movio
	var b = _barril_objetivo(activa) if puede else null
	if b == null:
		ocultar()
		return
	barril = b
	_boton.visible = true
	var pantalla = _boton.get_viewport().get_canvas_transform() * (b.global_position + Vector2(0, -34))
	_boton.position = pantalla - _boton.size * 0.5


func ocultar() -> void:
	_boton.visible = false
	barril = null


func _barril_objetivo(activa):
	var calc := CalculadorRuta.new()
	var mejor = null
	var mejor_dist := INF
	for b in _arbol.get_nodes_in_group("barriles"):
		if not is_instance_valid(b):
			continue
		var d: float = activa.global_position.distance_to(b.global_position)
		var alcanzable: bool = d < 70.0
		if not alcanzable:
			var res = calc.calcular(activa.global_position, b.global_position)
			alcanzable = res.valida and res.distancia <= CalculadorRuta.DISTANCIA_CELESTE
		if alcanzable and d < mejor_dist:
			mejor_dist = d
			mejor = b
	return mejor
