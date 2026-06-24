class_name Arma
extends RefCounted


var nombre: String = "Arma"


# Dispara desde la unidad. Devuelve cuantos segundos esperar antes de terminar el turno.
func disparar(_unidad, _inicio: Vector2, _direccion: Vector2) -> float:
	return 0.8


# Devuelve un diccionario describiendo la mira a dibujar. Claves posibles:
#   "linea" (Array[Vector2]), "color" (Color),
#   "relleno" (Array[Vector2]), "color_relleno" (Color),
#   "circulo" (Array[Vector2])
func calcular_mira(_unidad, _inicio: Vector2, _direccion: Vector2) -> Dictionary:
	return {}


# Util compartido: puntos de un circulo (para el area de la granada).
static func circulo(centro: Vector2, radio: float, n: int = 24) -> Array[Vector2]:
	var puntos: Array[Vector2] = []
	for i in range(n):
		var a = TAU * float(i) / float(n)
		puntos.append(centro + Vector2(cos(a), sin(a)) * radio)
	return puntos
