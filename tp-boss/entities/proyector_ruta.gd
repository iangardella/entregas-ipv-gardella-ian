class_name ProyectorRuta
extends Node2D

var jugador: UnidadBase = null
var puntos_resaltados: Array[Dictionary] = []

var _ruta_preview: PackedVector2Array = []
var _distancia_preview: float = 0.0
var _destino_preview: Vector2 = Vector2.INF
var _ruta_valida: bool = false

var _detector: DetectorSuperficie
var _calculador: CalculadorRuta

signal ruta_seleccionada(path: PackedVector2Array, dist: float, destino: Vector2, es_naranja: bool)

func _ready() -> void:
	jugador = get_parent()
	_detector = DetectorSuperficie.new(self)
	_calculador = CalculadorRuta.new()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not _puede_proyectar():
		_limpiar_preview()
		return

	_detector.actualizar_excepciones(get_tree())
	_calcular_preview()

	if _ruta_valida and _distancia_preview <= CalculadorRuta.DISTANCIA_CELESTE:
		if Input.is_action_just_pressed("click_disparar"):
			var es_naranja = _distancia_preview <= CalculadorRuta.DISTANCIA_NARANJA
			ruta_seleccionada.emit(_ruta_preview, _distancia_preview, _destino_preview, es_naranja)

	queue_redraw()

func _draw() -> void:
	if not _puede_proyectar():
		return

	if puntos_resaltados.is_empty():
		actualizar_zonas_resaltadas()

	DibujadorRuta.dibujar_zonas(self, puntos_resaltados)

	if _ruta_valida and _ruta_preview.size() >= 2:
		DibujadorRuta.dibujar_ruta(self, _ruta_preview, _distancia_preview)
		DibujadorRuta.dibujar_destino(self, _destino_preview, _distancia_preview)

func _puede_proyectar() -> bool:
	return is_instance_valid(jugador) \
		and jugador.estado == jugador.Estado.MOVIMIENTO \
		and not jugador.moviendo_a_destino \
		and jugador.is_on_floor() \
		and not jugador.fin_turno_iniciado

func _limpiar_preview() -> void:
	_ruta_valida = false
	_ruta_preview = []
	_destino_preview = Vector2.INF
	puntos_resaltados.clear()
	queue_redraw()

func _calcular_preview() -> void:
	_ruta_valida = false
	var pos_mouse = get_global_mouse_position()
	var pos_proyectada = _detector.obtener_punto_superficie(pos_mouse)

	if pos_proyectada == Vector2.INF:
		return

	var resultado = _calculador.calcular(jugador.global_position, pos_proyectada)
	_ruta_preview = resultado.path
	_distancia_preview = resultado.distancia
	_destino_preview = resultado.destino
	_ruta_valida = resultado.valida

func actualizar_zonas_resaltadas() -> void:
	puntos_resaltados = _calculador.calcular_zonas_alcanzables(jugador.global_position, self)
