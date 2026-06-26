extends Node2D

@onready var camara: Camera2D = $Camera2D
@onready var ui: Node = $CanvasLayer/UI
@onready var boton_cobertura: TextureButton = $CanvasLayer/UI/IndicadorCobertura

var _camara: ControladorCamara
var _hud: HUD
var _cobertura: IndicadorCobertura


func _ready() -> void:
	_camara = ControladorCamara.new(camara, get_tree())
	_hud = HUD.new(ui)
	_cobertura = IndicadorCobertura.new(boton_cobertura, get_tree())
	boton_cobertura.pressed.connect(_on_cobertura_pressed)

	ManejadorTurnos.cambio_de_turno.connect(_hud.mostrar_turno)
	ManejadorTurnos.unidad_activada.connect(_hud.activar_para_unidad)
	ManejadorTurnos.juego_terminado.connect(_hud.mostrar_fin)

	ManejadorTurnos.iniciar_partida()


func _process(delta: float) -> void:
	_camara.actualizar(delta)

	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and activa is UnidadBase:
		_hud.actualizar(activa)
		_cobertura.actualizar(activa)
	else:
		_cobertura.ocultar()


func _on_cobertura_pressed() -> void:
	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and is_instance_valid(_cobertura.barril) and activa.has_method("ir_a_cubrirse"):
		activa.ir_a_cubrirse(_cobertura.barril)
