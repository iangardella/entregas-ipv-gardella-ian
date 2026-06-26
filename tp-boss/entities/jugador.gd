class_name Jugador
extends UnidadBase

@export var velocidad: float = 180.0
var fin_turno_iniciado: bool = false
var moviendo_a_destino: bool = false
var es_movimiento_naranja: bool = true
var ya_movio: bool = false
var cubrir_al_llegar: bool = false
var barril_objetivo: Node = null
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
	ya_movio = false
	cubrir_al_llegar = false
	barril_objetivo = null
	if is_instance_valid(proyector):
		proyector.actualizar_zonas_resaltadas()

func _unhandled_input(event: InputEvent) -> void:
	if ManejadorTurnos.unidad_activa != self:
		return
	if estado != Estado.MOVIMIENTO and estado != Estado.APUNTADO:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			seleccionar_arma(false)
		elif event.keycode == KEY_2:
			seleccionar_arma(true)
	if estado == Estado.APUNTADO and event.is_action_pressed("click_disparar"):
		disparar()

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
		if cubrir_al_llegar and is_instance_valid(barril_objetivo) and global_position.distance_to(barril_objetivo.global_position) < 45.0:
			moviendo_a_destino = false
			ya_movio = true
			cubrir_al_llegar = false
			cubrirse(barril_objetivo)
			barril_objetivo = null
			return
		if indice_ruta < puntos_ruta.size():
			var target = puntos_ruta[indice_ruta]
			var target_centro = Vector2(target.x, target.y - 16.0)
			var diff = target_centro - global_position
			
			
			if abs(diff.x) > 6.0:
				velocity.x = sign(diff.x) * velocidad
				visual.flip_h = diff.x < 0
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
			ya_movio = true
			if cubrir_al_llegar:
				cubrir_al_llegar = false
				cubrirse(barril_objetivo)
				barril_objetivo = null
			elif not es_movimiento_naranja:
				iniciar_fin_turno_sprint()
			
	else:
		collision_mask = 1
		velocity.x = move_toward(velocity.x, 0, velocidad * delta)
		
		var pos_mouse = get_global_mouse_position()
		var dx_mouse = pos_mouse.x - global_position.x
		if absf(dx_mouse) > 24.0:
			visual.flip_h = dx_mouse < 0

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
	
	if absf(dir_apuntado.x) > 0.15:
		visual.flip_h = dir_apuntado.x < 0
	_aplicar_pose_apuntado(dir_apuntado)

	mira_laser.visible = true
	actualizar_mira(dir_apuntado)


func _aplicar_pose_apuntado(dir: Vector2) -> void:
	if not (visual is AnimatedSprite2D):
		return
	var elev := rad_to_deg(atan2(-dir.y, abs(dir.x)))
	var anim := &"aim_horizontal"
	if elev > 67.0:
		anim = &"aim_arriba"
	elif elev > 22.0:
		anim = &"aim_arribadiag"
	elif elev < -67.0:
		anim = &"aim_abajo"
	elif elev < -22.0:
		anim = &"aim_abajodiag"
	visual.play(anim)


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

func ir_a_cubrirse(barril) -> void:
	if not is_instance_valid(barril):
		return
	if global_position.distance_to(barril.global_position) < 70.0:
		cubrirse(barril)
		return
	var lado := signf(global_position.x - barril.global_position.x)
	if lado == 0.0:
		lado = 1.0
	var objetivo_pos: Vector2 = barril.global_position + Vector2(lado * 34.0, 0.0)
	var calc := CalculadorRuta.new()
	var res = calc.calcular(global_position, objetivo_pos)
	if not res.valida:
		cubrirse(barril)
		return
	puntos_ruta = res.path
	indice_ruta = 1
	moviendo_a_destino = true
	es_movimiento_naranja = res.distancia <= CalculadorRuta.DISTANCIA_NARANJA
	cubrir_al_llegar = true
	barril_objetivo = barril

func puede_apuntar() -> bool:
	if estado != Estado.MOVIMIENTO or moviendo_a_destino:
		return false
	return (not ya_movio) or es_movimiento_naranja

func _morir() -> void:
	RegistroUnidades.remover(self, _nombre_equipo())
	super._morir()
