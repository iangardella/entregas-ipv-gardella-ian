class_name Jugador
extends UnidadBase

@export var velocidad: float = 180.0
var fin_turno_iniciado: bool = false
var moviendo_a_destino: bool = false
var es_movimiento_naranja: bool = true
var puntos_ruta: PackedVector2Array = []
var indice_ruta: int = 0
@onready var proyector: ProyectorRuta = $ProyectorRuta
@onready var timer_fin_turno: Timer = $TimerFinTurno


func _nombre_equipo() -> String:
	return "jugadores"

func _nombre_grupo() -> String:
	return "jugadores"

func inicializar() -> void:
	add_to_group(_nombre_grupo())
	RegistroUnidades.registrar(self, _nombre_equipo())
	proyector.ruta_seleccionada.connect(_on_ruta_seleccionada)
	timer_fin_turno.timeout.connect(_on_fin_turno_timeout)

func activar() -> void:
	super.activar()
	fin_turno_iniciado = false
	moviendo_a_destino = false
	if is_instance_valid(proyector):
		proyector.actualizar_zonas_resaltadas()

func _on_ruta_seleccionada(path: PackedVector2Array, _dist: float, _destino: Vector2, es_naranja: bool) -> void:
	puntos_ruta = path
	indice_ruta = 1
	moviendo_a_destino = true
	es_movimiento_naranja = es_naranja

func procesar_fisicas(delta: float) -> void:
	match estado:
		Estado.MOVIMIENTO:
			manejar_movimiento(delta)
		Estado.APUNTADO:
			manejar_apuntado(delta)
		Estado.ACCIONADO:
			velocity.x = move_toward(velocity.x, 0, velocidad * delta)

func manejar_movimiento(delta: float) -> void:
	if moviendo_a_destino:
		if indice_ruta < puntos_ruta.size():
			var target = puntos_ruta[indice_ruta]
			var target_centro = Vector2(target.x, target.y - 16.0)
			var diff = target_centro - global_position
			
			
			if abs(diff.x) > 6.0:
				velocity.x = sign(diff.x) * velocidad
				visual.scale.x = sign(diff.x)
				arma.rotation = 0.0 if diff.x > 0 else PI
			else:
				velocity.x = 0
			
			if abs(diff.y) > 6.0 and abs(diff.x) <= 8.0:
				velocity.y = sign(diff.y) * velocidad
				collision_mask = 0  
			else:
				velocity.y = 0
				collision_mask = 1
			
			var dist_al_nodo = global_position.distance_to(target_centro)
			if dist_al_nodo < 15.0:
				indice_ruta += 1
		else:
			velocity.x = 0
			velocity.y = 0
			collision_mask = 1
			moviendo_a_destino = false
			
			if es_movimiento_naranja:
				cambiar_a_apuntado()
			else:
				iniciar_fin_turno_sprint()
			
	else:
		collision_mask = 1
		velocity.x = move_toward(velocity.x, 0, velocidad * delta)
		
		var pos_mouse = get_global_mouse_position()
		if pos_mouse.x != global_position.x:
			visual.scale.x = sign(pos_mouse.x - global_position.x)

func iniciar_fin_turno_sprint() -> void:
	fin_turno_iniciado = true
	estado = Estado.ACCIONADO
	velocity.x = 0
	timer_fin_turno.start()

func _on_fin_turno_timeout() -> void:
	ManejadorTurnos.finalizar_accion_unidad_actual()

func manejar_apuntado(_delta: float) -> void:
	velocity.x = 0
	
	var pos_mouse = get_global_mouse_position()
	var dir_apuntado = (pos_mouse - arma.global_position).normalized()
	arma.rotation = dir_apuntado.angle()
	
	if dir_apuntado.x != 0:
		visual.scale.x = sign(dir_apuntado.x)
	
	mira_laser.visible = true
	actualizar_mira(dir_apuntado)
	
	if Input.is_action_just_pressed("click_disparar"):
		disparar()


func cambiar_a_apuntado() -> void:
	if estado == Estado.MOVIMIENTO:
		estado = Estado.APUNTADO
		velocity.x = 0
		queue_redraw()


func obtener_punto_camara() -> Vector2:
	if estado == Estado.APUNTADO:
		return global_position.lerp(get_global_mouse_position(), 0.6)
	elif estado == Estado.MOVIMIENTO and not moviendo_a_destino:
		return global_position.lerp(get_global_mouse_position(), 0.35)
	return global_position

func puede_apuntar() -> bool:
	return estado == Estado.MOVIMIENTO

func _morir() -> void:
	RegistroUnidades.remover(self, _nombre_equipo())
	super._morir()
