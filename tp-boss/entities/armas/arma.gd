class_name Arma
extends RefCounted


var nombre: String = "Arma"


func disparar(_unidad, _inicio: Vector2, _direccion: Vector2) -> float:
	return 0.8


func calcular_mira(_unidad, _inicio: Vector2, _direccion: Vector2) -> Dictionary:
	return {}


static func circulo(centro: Vector2, radio: float, n: int = 24) -> Array[Vector2]:
	var puntos: Array[Vector2] = []
	for i in range(n):
		var a = TAU * float(i) / float(n)
		puntos.append(centro + Vector2(cos(a), sin(a)) * radio)
	return puntos
