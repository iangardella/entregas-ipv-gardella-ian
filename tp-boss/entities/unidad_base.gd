class_name UnidadBase
extends CharacterBody2D


const EscenaPopDanio = preload("res://ui/pop_danio.tscn")
const EscenaEfectoMuerte = preload("res://entities/efecto_muerte.tscn")

const GRAVEDAD = 980.0
const FRICCION_EMPUJE = 700.0

enum Estado { INACTIVO, MOVIMIENTO, APUNTADO, ACCIONADO }
var estado: Estado = Estado.INACTIVO

enum ArmaTipo { PISTOLA, ESCOPETA, GRANADA }
@export var tipo_arma: ArmaTipo = ArmaTipo.PISTOLA
@export var municion_principal: int = 2
var usos_principal_restantes: int = 0
var arma_activa: ArmaTipo = ArmaTipo.PISTOLA

# Instancias de las armas (patron Strategy): la unidad les delega disparar/mira.
var _arma_secundaria: Arma
var _arma_principal: Arma

signal arma_cambiada(activa: int, principal: int, usos: int)

@export var vida_maxima: int = 100
@export var danio_base: int = 25
@export var color_activo: Color = Color(0.5, 0.5, 0.5)
@export var color_inactivo: Color = Color(0.3, 0.3, 0.3)
@export var color_equipo: Color = Color(0.5, 0.5, 0.5)

var vida: int

@onready var arma: Node2D = $Arma
@onready var muzzle: Node2D = $Arma/Muzzle
@onready var mira_laser: Line2D = $MiraLaser
@onready var mira_area: Line2D = $MiraArea
@onready var mira_relleno: Polygon2D = $MiraRelleno
@onready var visual: AnimatedSprite2D = $Visual

signal danio_recibido(cantidad: int, vida_restante: int)

func _ready() -> void:
	vida = vida_maxima
	usos_principal_restantes = municion_principal
	_arma_secundaria = Pistola.new()
	_arma_principal = _crear_arma_principal()
	add_to_group("unidades")
	mira_laser.visible = false
	mira_laser.top_level = true
	mira_area.visible = false
	mira_area.top_level = true
	mira_relleno.visible = false
	mira_relleno.top_level = true
	actualizar_color_visual(false)

	var ind = load("res://ui/indicadores.gd").new()
	ind.name = "Indicadores"
	add_child(ind)

	inicializar()

func inicializar() -> void:
	pass

# Crea el arma principal de esta unidad segun tipo_arma (null si solo usa pistola).
func _crear_arma_principal() -> Arma:
	match tipo_arma:
		ArmaTipo.ESCOPETA:
			return Escopeta.new()
		ArmaTipo.GRANADA:
			return ArmaGranada.new()
		_:
			return null

# Devuelve el arma actualmente seleccionada (secundaria o principal).
func _arma_actual() -> Arma:
	if arma_activa != ArmaTipo.PISTOLA and _arma_principal != null:
		return _arma_principal
	return _arma_secundaria

func activar() -> void:
	estado = Estado.MOVIMIENTO
	arma_activa = ArmaTipo.PISTOLA
	actualizar_color_visual(true)
	arma_cambiada.emit(arma_activa, tipo_arma, usos_principal_restantes)
	_actualizar_marcador()
	queue_redraw()

func desactivar() -> void:
	estado = Estado.INACTIVO
	mira_laser.visible = false
	mira_area.visible = false
	mira_relleno.visible = false
	actualizar_color_visual(false)
	_actualizar_marcador()
	queue_redraw()

func seleccionar_arma(principal: bool) -> void:
	if principal and tipo_arma != ArmaTipo.PISTOLA and usos_principal_restantes > 0:
		arma_activa = tipo_arma
	else:
		arma_activa = ArmaTipo.PISTOLA
	arma_cambiada.emit(arma_activa, tipo_arma, usos_principal_restantes)

func _actualizar_marcador() -> void:
	var ind = get_node_or_null("Indicadores")
	if ind:
		ind.queue_redraw()

func actualizar_color_visual(activo: bool) -> void:
	if visual:
		visual.modulate = color_activo if activo else color_inactivo

# Punto desde donde salen los proyectiles (corregido si el cano esta pasado una pared).
func _punto_inicio_disparo() -> Vector2:
	var inicio = muzzle.global_position
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(arma.global_position, muzzle.global_position)
	query.exclude = [self.get_rid()]
	var resultado = space_state.intersect_ray(query)
	if resultado:
		inicio = resultado.position + resultado.normal * 2.0
	return inicio

func disparar() -> void:
	estado = Estado.ACCIONADO
	mira_laser.visible = false
	mira_area.visible = false
	mira_relleno.visible = false

	var inicio = _punto_inicio_disparo()
	var direccion = Vector2.from_angle(arma.rotation)
	var espera = _arma_actual().disparar(self, inicio, direccion)

	if arma_activa != ArmaTipo.PISTOLA:
		usos_principal_restantes -= 1
	arma_cambiada.emit(arma_activa, tipo_arma, usos_principal_restantes)
	_programar_fin_disparo(espera)

func _programar_fin_disparo(espera: float) -> void:
	await get_tree().create_timer(espera).timeout
	ManejadorTurnos.finalizar_accion_unidad_actual()

func aplicar_empuje(desde: Vector2, fuerza: float) -> void:
	var dir := global_position - desde
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	velocity = Vector2(dir.x * fuerza, -fuerza * 0.3)

func recibir_danio(cantidad: int) -> void:
	vida = max(0, vida - cantidad)
	danio_recibido.emit(cantidad, vida)
	var pop = EscenaPopDanio.instantiate()
	get_parent().add_child(pop)
	pop.mostrar(cantidad, global_position + Vector2(0, -20))
	queue_redraw()

	if vida <= 0:
		_morir()

# Dibuja la mira del arma activa, delegando la forma a cada arma.
func actualizar_mira(direccion: Vector2) -> void:
	var inicio = muzzle.global_position
	var datos = _arma_actual().calcular_mira(self, inicio, direccion)

	mira_laser.default_color = datos.get("color", Color.WHITE)
	mira_laser.points = datos.get("linea", PackedVector2Array())

	var circ = datos.get("circulo", [])
	mira_area.visible = circ.size() > 0
	if circ.size() > 0:
		mira_area.points = circ

	var relleno = datos.get("relleno", [])
	mira_relleno.visible = relleno.size() > 0
	if relleno.size() > 0:
		mira_relleno.polygon = relleno
		mira_relleno.color = datos.get("color_relleno", Color(1, 1, 1, 0.15))

func _morir() -> void:
	var efecto = EscenaEfectoMuerte.instantiate()
	get_parent().add_child(efecto)
	efecto.global_position = global_position
	queue_free()

func resetear_turno() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta
	if estado == Estado.INACTIVO:
		velocity.x = move_toward(velocity.x, 0.0, FRICCION_EMPUJE * delta)

	procesar_fisicas(delta)
	move_and_slide()
	_actualizar_animacion()
	queue_redraw()

func procesar_fisicas(_delta: float) -> void:
	pass

func _actualizar_animacion() -> void:
	if not (visual is AnimatedSprite2D):
		return
	if estado == Estado.APUNTADO:
		return
	if collision_mask == 0 and abs(velocity.y) > 10.0:
		visual.play(&"trepar")
	elif abs(velocity.x) > 10.0:
		visual.play(&"caminar")
	elif not is_on_floor():
		visual.play(&"saltar")
	else:
		visual.play(&"idle")


func obtener_punto_camara() -> Vector2:
	return global_position


func puede_apuntar() -> bool:
	return false


func cambiar_a_apuntado() -> void:
	pass
