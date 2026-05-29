extends Node

signal equipo_vacio(nombre_equipo: String)
signal unidad_removida(unidad: Node2D, equipo: String)

var equipos: Dictionary = {
	"jugadores": [],
	"enemigos": []
}

func registrar(unidad: Node2D, equipo: String) -> void:
	if not equipos.has(equipo):
		equipos[equipo] = []
	var lista = equipos[equipo] as Array
	if not lista.has(unidad):
		lista.append(unidad)


func remover(unidad: Node2D, equipo: String) -> void:
	if not equipos.has(equipo):
		return
	var lista = equipos[equipo] as Array
	if lista.has(unidad):
		lista.erase(unidad)
		unidad_removida.emit(unidad, equipo)
	if lista.is_empty():
		equipo_vacio.emit(equipo)


func obtener_unidades(equipo: String) -> Array:
	if not equipos.has(equipo):
		return []
	return equipos[equipo]


func limpiar() -> void:
	for equipo in equipos:
		equipos[equipo].clear()
