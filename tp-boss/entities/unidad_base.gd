class_name UnidadBase
extends CharacterBody2D


const EscenaBala = preload("res://entities/bala.tscn")
const EscenaPopDanio = preload("res://ui/pop_danio.tscn")

const GRAVEDAD = 980.0

enum Estado { INACTIVO, MOVIMIENTO, APUNTADO, ACCIONADO }
var estado: Estado = Estado.INACTIVO

@export var vida_maxima: int = 100
@export var danio_base: int = 25
@export var color_activo: Color = Color(0.5, 0.5, 0.5)
@export var color_inactivo: Color = Color(0.3, 0.3, 0.3)

var vida: int

@onready var arma: Node2D = $Arma
@onready var muzzle: Node2D = $Arma/Muzzle
@onready var mira_laser: Line2D = $MiraLaser
@onready var visual: ColorRect = $Visual

signal danio_recibido(cantidad: int, vida_restante: int)

func _ready() -> void:
	vida = vida_maxima
	add_to_group("unidades")
	mira_laser.visible = false
	mira_laser.top_level = true
	
	var ind = load("res://ui/indicadores.gd").new()
	ind.name = "Indicadores"
	add_child(ind)
	
	inicializar()

func inicializar() -> void:
	pass

func activar() -> void:
	estado = Estado.MOVIMIENTO
	actualizar_color_visual(true)
	queue_redraw()

func desactivar() -> void:
	estado = Estado.INACTIVO
	mira_laser.visible = false
	actualizar_color_visual(false)
	queue_redraw()

func actualizar_color_visual(activo: bool) -> void:
	if visual:
		visual.color = color_activo if activo else color_inactivo

func disparar() -> void:
	estado = Estado.ACCIONADO
	mira_laser.visible = false
	
	var dir_disparo = Vector2.from_angle(arma.rotation)
	var inicio_bala = muzzle.global_position
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(arma.global_position, muzzle.global_position)
	query.exclude = [self.get_rid()]
	var resultado = space_state.intersect_ray(query)
	if resultado:
		inicio_bala = resultado.position + resultado.normal * 2.0
		
	var bala = EscenaBala.instantiate()
	get_parent().add_child(bala)
	bala.lanzar(inicio_bala, dir_disparo, danio_base, self)
	bala.impacto_resuelto.connect(_on_bala_impacto)

func _on_bala_impacto() -> void:
	await get_tree().create_timer(0.4).timeout
	ManejadorTurnos.finalizar_accion_unidad_actual()

func recibir_danio(cantidad: int) -> void:
	vida = max(0, vida - cantidad)
	danio_recibido.emit(cantidad, vida)
	var pop = EscenaPopDanio.instantiate()
	get_parent().add_child(pop)
	pop.mostrar(cantidad, global_position + Vector2(0, -20))
	queue_redraw()
	
	if vida <= 0:
		_morir()

func actualizar_mira(direccion: Vector2) -> void:
	var inicio = muzzle.global_position
	var excluir: Array[RID] = [self.get_rid()]
	var puntos = calcular_trayectoria(inicio, direccion, excluir)
	mira_laser.points = puntos

func calcular_trayectoria(inicio: Vector2, direccion: Vector2, excluir: Array[RID]) -> Array[Vector2]:
	var space_state = get_world_2d().direct_space_state
	
	var query_inicio = PhysicsRayQueryParameters2D.create(arma.global_position, inicio)
	query_inicio.exclude = excluir
	var res_inicio = space_state.intersect_ray(query_inicio)
	
	var pos_actual = inicio
	var puntos: Array[Vector2] = []
	
	if res_inicio:
		puntos.append(res_inicio.position)
		return puntos
		
	puntos.append(inicio)
	var dir_actual = direccion
	var max_rebotes = 3
	
	for i in range(max_rebotes + 1):
		var destino = pos_actual + dir_actual * 1500.0
		var query = PhysicsRayQueryParameters2D.create(pos_actual, destino)
		query.exclude = excluir
		
		var resultado = space_state.intersect_ray(query)
		
		if resultado:
			puntos.append(resultado.position)
			var colisionador = resultado.collider
			
			if colisionador.is_in_group("unidades") and colisionador != self:
				break
			
			var normal = resultado.normal
			pos_actual = resultado.position + normal * 0.2
			dir_actual = dir_actual.bounce(normal)
		else:
			puntos.append(destino)
			break
			
	return puntos

func _morir() -> void:
	queue_free()

func resetear_turno() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta
	
	procesar_fisicas(delta)
	move_and_slide()
	queue_redraw()

func procesar_fisicas(_delta: float) -> void:
	pass


func obtener_punto_camara() -> Vector2:
	return global_position


func puede_apuntar() -> bool:
	return false


func cambiar_a_apuntado() -> void:
	pass
