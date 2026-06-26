class_name ControladorMovimiento
extends RefCounted

var moviendo_a_destino := false
var es_movimiento_naranja := true
var ya_movio := false
var cubrir_al_llegar := false
var barril_objetivo: Node = null

var _puntos: PackedVector2Array = []
var _indice := 0
var _u


func _init(unidad) -> void:
	_u = unidad


func reset() -> void:
	moviendo_a_destino = false
	ya_movio = false
	cubrir_al_llegar = false
	barril_objetivo = null


func iniciar_ruta(path: PackedVector2Array, es_naranja: bool) -> void:
	_puntos = path
	_indice = 1
	moviendo_a_destino = true
	es_movimiento_naranja = es_naranja


func puede_apuntar() -> bool:
	if moviendo_a_destino:
		return false
	return (not ya_movio) or es_movimiento_naranja


func ir_a_cubrirse(barril) -> void:
	if not is_instance_valid(barril):
		return
	if _u.global_position.distance_to(barril.global_position) < 70.0:
		_u.cubrirse(barril)
		return
	var lado := signf(_u.global_position.x - barril.global_position.x)
	if lado == 0.0:
		lado = 1.0
	var objetivo_pos: Vector2 = barril.global_position + Vector2(lado * 34.0, 0.0)
	var calc := CalculadorRuta.new()
	var res = calc.calcular(_u.global_position, objetivo_pos)
	if not res.valida:
		_u.cubrirse(barril)
		return
	_puntos = res.path
	_indice = 1
	moviendo_a_destino = true
	es_movimiento_naranja = res.distancia <= CalculadorRuta.DISTANCIA_NARANJA
	cubrir_al_llegar = true
	barril_objetivo = barril


func procesar(delta: float) -> void:
	var u = _u
	if moviendo_a_destino:
		if cubrir_al_llegar and is_instance_valid(barril_objetivo) and u.global_position.distance_to(barril_objetivo.global_position) < 45.0:
			_terminar_movimiento()
			u.cubrirse(barril_objetivo)
			barril_objetivo = null
			return

		if _indice < _puntos.size():
			var target: Vector2 = _puntos[_indice]
			var target_centro := Vector2(target.x, target.y - 16.0)
			var diff: Vector2 = target_centro - u.global_position

			if abs(diff.x) > 6.0:
				u.velocity.x = sign(diff.x) * u.velocidad
				u.visual.flip_h = diff.x < 0
				u.arma.rotation = 0.0 if diff.x > 0 else PI
			else:
				u.velocity.x = 0

			if abs(diff.y) > 6.0 and abs(diff.x) <= 8.0:
				u.velocity.y = sign(diff.y) * u.velocidad
				u.collision_mask = 0
			else:
				u.velocity.y = 0
				u.collision_mask = 1

			if u.global_position.distance_to(target_centro) < 15.0:
				_indice += 1
		else:
			u.velocity.x = 0
			u.velocity.y = 0
			u.collision_mask = 1
			_terminar_movimiento()
			if cubrir_al_llegar:
				cubrir_al_llegar = false
				u.cubrirse(barril_objetivo)
				barril_objetivo = null
			elif not es_movimiento_naranja:
				u.iniciar_fin_turno_sprint()
	else:
		u.collision_mask = 1
		u.velocity.x = move_toward(u.velocity.x, 0, u.velocidad * delta)
		var dx_mouse: float = u.get_global_mouse_position().x - u.global_position.x
		if absf(dx_mouse) > 24.0:
			u.visual.flip_h = dx_mouse < 0


func _terminar_movimiento() -> void:
	moviendo_a_destino = false
	ya_movio = true
