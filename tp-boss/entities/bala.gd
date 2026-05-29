extends Node2D

@onready var raycast: RayCast2D = $RayCast2D

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 1400.0
var danio: int = 25  #El que me diga algo de la ñ, le digo con amor que escriba con ñ en un teclado ingles
var max_rebotes: int = 3
var rebotes_actuales: int = 0
var tirador: Node2D = null

signal impacto_resuelto

func lanzar(pos_inicio: Vector2, dir_inicio: Vector2, valor_danio: int, unidad_tirador: Node2D) -> void:
	global_position = pos_inicio
	direccion = dir_inicio.normalized()
	danio = valor_danio 
	tirador = unidad_tirador
	rotation = direccion.angle()

func _ready() -> void:
	add_to_group("balas")
	if is_instance_valid(tirador):
		raycast.add_exception(tirador)

func _physics_process(delta: float) -> void:
	var paso = velocidad * delta
	
	raycast.target_position = Vector2(paso, 0)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var colisionador = raycast.get_collider()
		var punto_colision = raycast.get_collision_point()
		var normal = raycast.get_collision_normal()
		global_position = punto_colision
		
		if is_instance_valid(colisionador) and colisionador.has_method("recibir_danio"):
			colisionador.recibir_danio(danio)
			_finalizar()
			return

		if rebotes_actuales < max_rebotes:
			direccion = direccion.bounce(normal)
			rotation = direccion.angle()
			rebotes_actuales += 1
			global_position += normal * 2.0
		else:
			_finalizar()
	else:
		global_position += direccion * paso

func _finalizar() -> void:
	impacto_resuelto.emit()
	queue_free()
