extends Node

signal cambio_de_turno(nuevo_turno: String)
signal unidad_activada(unidad: Node2D)
signal juego_terminado(ganador: String)

enum Turno { AZUL, ROJO }

const CONFIG_TURNO = {
	Turno.AZUL: {"equipo": "jugadores", "nombre": "AZUL", "opuesto": Turno.ROJO, "ganador_rival": "ROJO"},
	Turno.ROJO: {"equipo": "enemigos", "nombre": "ROJO", "opuesto": Turno.AZUL, "ganador_rival": "AZUL"},
}

var turno_actual: Turno = Turno.AZUL
var unidad_activa: Node2D = null
var indice_unidad_activa: int = -1


func _ready() -> void:
	RegistroUnidades.equipo_vacio.connect(_on_equipo_vacio)
	RegistroUnidades.unidad_removida.connect(_on_unidad_removida)


func iniciar_partida() -> void:
	RegistroUnidades.limpiar()

	for u in get_tree().get_nodes_in_group("jugadores"):
		RegistroUnidades.registrar(u, "jugadores")
	for u in get_tree().get_nodes_in_group("enemigos"):
		RegistroUnidades.registrar(u, "enemigos")

	if _sin_unidades():
		await get_tree().process_frame
		for u in get_tree().get_nodes_in_group("jugadores"):
			RegistroUnidades.registrar(u, "jugadores")
		for u in get_tree().get_nodes_in_group("enemigos"):
			RegistroUnidades.registrar(u, "enemigos")

	GeneradorNavegacion.generar_grafo()

	turno_actual = Turno.AZUL
	indice_unidad_activa = -1
	comenzar_turno(Turno.AZUL)


func comenzar_turno(turno: Turno) -> void:
	turno_actual = turno
	var config = CONFIG_TURNO[turno]
	for u in RegistroUnidades.obtener_unidades(config.equipo):
		if is_instance_valid(u):
			u.resetear_turno()
	cambio_de_turno.emit(config.nombre)
	indice_unidad_activa = -1
	activar_siguiente_unidad()

func activar_siguiente_unidad() -> void:
	if is_instance_valid(unidad_activa):
		unidad_activa.desactivar()

	indice_unidad_activa += 1
	var config = CONFIG_TURNO[turno_actual]
	var unidades = RegistroUnidades.obtener_unidades(config.equipo)

	if indice_unidad_activa >= unidades.size():
		comenzar_turno(config.opuesto)
		return

	unidad_activa = unidades[indice_unidad_activa]
	if is_instance_valid(unidad_activa):
		unidad_activa.activar()
		unidad_activada.emit(unidad_activa)
	else:
		activar_siguiente_unidad()

func finalizar_accion_unidad_actual() -> void:
	call_deferred("activar_siguiente_unidad")


func _on_equipo_vacio(nombre_equipo: String) -> void:
	for turno in CONFIG_TURNO:
		if CONFIG_TURNO[turno].equipo == nombre_equipo:
			juego_terminado.emit(CONFIG_TURNO[turno].ganador_rival)
			return

func _on_unidad_removida(unidad: Node2D, _equipo: String) -> void:
	if unidad == unidad_activa:
		indice_unidad_activa -= 1
		unidad_activa = null
		call_deferred("activar_siguiente_unidad")


func _sin_unidades() -> bool:
	return RegistroUnidades.obtener_unidades("jugadores").is_empty() \
		and RegistroUnidades.obtener_unidades("enemigos").is_empty()
