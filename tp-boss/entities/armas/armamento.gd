class_name Armamento
extends RefCounted

const PISTOLA := 0
const ESCOPETA := 1
const GRANADA := 2

var usos: int
var usando_principal: bool = false

var _principal: Arma
var _secundaria: Arma


func _init(tipo_principal: int, municion: int) -> void:
	usos = municion
	_secundaria = Pistola.new()
	_principal = _crear_principal(tipo_principal)


func _crear_principal(tipo: int) -> Arma:
	match tipo:
		ESCOPETA:
			return Escopeta.new()
		GRANADA:
			return ArmaGranada.new()
		_:
			return null


func tiene_principal() -> bool:
	return _principal != null


func usando_la_principal() -> bool:
	return usando_principal and _principal != null


func actual() -> Arma:
	return _principal if usando_la_principal() else _secundaria


func seleccionar(principal: bool) -> void:
	usando_principal = principal and _principal != null and usos > 0


func disparar(unidad, inicio: Vector2, direccion: Vector2) -> float:
	var espera: float = actual().disparar(unidad, inicio, direccion)
	if usando_la_principal():
		usos -= 1
	return espera


func calcular_mira(unidad, inicio: Vector2, direccion: Vector2) -> Dictionary:
	return actual().calcular_mira(unidad, inicio, direccion)


func reset_turno() -> void:
	usando_principal = false
