class_name Indicadores
extends Node2D

var unidad: UnidadBase = null

func _ready() -> void:
	unidad = get_parent()
	unidad.danio_recibido.connect(_on_danio)
	queue_redraw()

func _on_danio(_cantidad: int, _vida_restante: int) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(unidad):
		return
	
	var vida_ancho = 32
	var vida_alto = 4
	var vida_pos = Vector2(-16, -28)
	
	draw_rect(Rect2(vida_pos, Vector2(vida_ancho, vida_alto)), Color(0.2, 0.1, 0.1))
	var vida_ratio = float(unidad.vida) / unidad.vida_maxima
	draw_rect(Rect2(vida_pos, Vector2(vida_ancho * vida_ratio, vida_alto)), unidad.color_activo)
