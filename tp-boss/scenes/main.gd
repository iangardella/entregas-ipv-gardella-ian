extends Node2D

@onready var camara: Camera2D = $Camera2D
@onready var banner_turno: PanelContainer = $CanvasLayer/UI/BannerTurno
@onready var texto_turno: Label = $CanvasLayer/UI/BannerTurno/TextoTurno
@onready var contenedor_acciones: MarginContainer = $CanvasLayer/UI/ContenedorAcciones
@onready var boton_apuntar: Button = $CanvasLayer/UI/ContenedorAcciones/HBoxContainer/BotonApuntar
@onready var boton_terminar: Button = $CanvasLayer/UI/ContenedorAcciones/HBoxContainer/BotonTerminar
@onready var pantalla_final: PanelContainer = $CanvasLayer/UI/PantallaFinal
@onready var texto_resultado: Label = $CanvasLayer/UI/PantallaFinal/VBoxContainer/TextoResultado
@onready var boton_reiniciar: Button = $CanvasLayer/UI/PantallaFinal/VBoxContainer/BotonReiniciar

var ultima_unidad_activa: Node2D = null
var pos_ultimo_impacto: Vector2 = Vector2.INF

const CONFIG_TURNO = {
	"AZUL": {
		"texto": "TURNO JUGADOR 1 (AZUL)",
		"borde": Color(0.15, 0.7, 1.0, 1.0),
		"fondo": Color(0.02, 0.1, 0.25, 0.85)
	},
	"ROJO": {
		"texto": "TURNO JUGADOR 2 (ROJO)",
		"borde": Color(1.0, 0.2, 0.2, 1.0),
		"fondo": Color(0.25, 0.02, 0.02, 0.85)
	}
}

const CONFIG_VICTORIA = {
	"AZUL": {
		"texto": "¡VICTORIA AZUL!",
		"color": Color(0.25, 0.65, 1.0)
	},
	"ROJO": {
		"texto": "¡VICTORIA ROJA!",
		"color": Color(1.0, 0.25, 0.25)
	}
}

func _ready() -> void:
	ManejadorTurnos.cambio_de_turno.connect(_on_cambio_de_turno)
	ManejadorTurnos.unidad_activada.connect(_on_unidad_activada)
	ManejadorTurnos.juego_terminado.connect(_on_juego_terminado)
	
	pantalla_final.visible = false
	contenedor_acciones.visible = false
	
	camara.limit_left = -70
	camara.limit_right = 1220
	camara.limit_top = 50
	camara.limit_bottom = 520
	
	boton_apuntar.pressed.connect(_on_boton_apuntar_pressed)
	boton_terminar.pressed.connect(_on_boton_terminar_pressed)
	boton_reiniciar.pressed.connect(_on_boton_reiniciar_pressed)
	
	ManejadorTurnos.iniciar_partida()

func _process(delta: float) -> void:
	var seguir_objetivo: Node2D = null
	
	var balas = get_tree().get_nodes_in_group("balas")
	for b in balas:
		if is_instance_valid(b):
			seguir_objetivo = b
			break
			
	var target_pos = Vector2.INF
	
	if seguir_objetivo:
		target_pos = seguir_objetivo.global_position
		pos_ultimo_impacto = target_pos 
	else:
		var activa = ManejadorTurnos.unidad_activa
		if is_instance_valid(activa) and activa is UnidadBase:
			if pos_ultimo_impacto != Vector2.INF and activa == ultima_unidad_activa:
				target_pos = pos_ultimo_impacto
			else:
				target_pos = activa.obtener_punto_camara()
				pos_ultimo_impacto = Vector2.INF 
				ultima_unidad_activa = activa
				
	if target_pos != Vector2.INF:
		camara.global_position = camara.global_position.lerp(target_pos, 7.5 * delta)		
	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and activa is UnidadBase:
		boton_apuntar.disabled = not activa.puede_apuntar()


func _on_cambio_de_turno(nuevo_turno: String) -> void:
	var config = CONFIG_TURNO[nuevo_turno]
	texto_turno.text = config.texto
	var sb = banner_turno.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if sb:
		sb.border_color = config.borde
		sb.bg_color = config.fondo
		banner_turno.add_theme_stylebox_override("panel", sb)
	
	banner_turno.scale = Vector2(0.3, 0.3)
	banner_turno.pivot_offset = banner_turno.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(banner_turno, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner_turno, "scale", Vector2(1.0, 1.0), 0.15)

func _on_unidad_activada(unidad: Node2D) -> void:
	if is_instance_valid(unidad) and unidad.is_in_group("unidades"):
		contenedor_acciones.visible = true
		boton_apuntar.disabled = false
	else:
		contenedor_acciones.visible = false

func _on_juego_terminado(ganador: String) -> void:
	pantalla_final.visible = true
	contenedor_acciones.visible = false
	
	var config = CONFIG_VICTORIA[ganador]
	texto_resultado.text = config.texto
	
	var settings = LabelSettings.new()
	settings.font_size = 40
	settings.font_color = config.color
	settings.outline_size = 8
	settings.outline_color = Color(0, 0, 0)
	texto_resultado.label_settings = settings

func _on_boton_apuntar_pressed() -> void:
	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and activa is UnidadBase:
		activa.cambiar_a_apuntado()

func _on_boton_terminar_pressed() -> void:
	ManejadorTurnos.finalizar_accion_unidad_actual()

func _on_boton_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()
