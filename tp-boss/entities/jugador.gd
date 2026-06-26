class_name Jugador
extends UnidadBase

@export var velocidad: float = 180.0
var fin_turno_iniciado: bool = false
var _apuntado: ControladorApuntado
var _movimiento: ControladorMovimiento
@onready var proyector: ProyectorRuta = $ProyectorRuta
@onready var timer_fin_turno: Timer = $TimerFinTurno

var moviendo_a_destino: bool:
	get:
		return _movimiento != null and _movimiento.moviendo_a_destino
var ya_movio: bool:
	get:
		return _movimiento != null and _movimiento.ya_movio


func _nombre_equipo() -> String:
	return "jugadores"

func _nombre_grupo() -> String:
	return "jugadores"

func inicializar() -> void:
	add_to_group(_nombre_grupo())
	RegistroUnidades.registrar(self, _nombre_equipo())
	proyector.ruta_seleccionada.connect(_on_ruta_seleccionada)
	timer_fin_turno.timeout.connect(_on_fin_turno_timeout)
	_apuntado = ControladorApuntado.new(self)
	_movimiento = ControladorMovimiento.new(self)

func activar() -> void:
	super.activar()
	fin_turno_iniciado = false
	_movimiento.reset()
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
	_movimiento.iniciar_ruta(path, es_naranja)

func procesar_fisicas(delta: float) -> void:
	match estado:
		Estado.MOVIMIENTO:
			_movimiento.procesar(delta)
		Estado.APUNTADO:
			manejar_apuntado(delta)
		Estado.ACCIONADO:
			velocity.x = move_toward(velocity.x, 0, velocidad * delta)

func iniciar_fin_turno_sprint() -> void:
	fin_turno_iniciado = true
	estado = Estado.ACCIONADO
	velocity.x = 0
	timer_fin_turno.start()

func _on_fin_turno_timeout() -> void:
	ManejadorTurnos.finalizar_accion_unidad_actual()

func manejar_apuntado(_delta: float) -> void:
	_apuntado.procesar()


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
	_movimiento.ir_a_cubrirse(barril)

func puede_apuntar() -> bool:
	if estado != Estado.MOVIMIENTO:
		return false
	return _movimiento.puede_apuntar()

func _morir() -> void:
	RegistroUnidades.remover(self, _nombre_equipo())
	super._morir()
