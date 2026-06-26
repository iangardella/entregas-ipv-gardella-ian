class_name HUD
extends RefCounted

const ICONO_PISTOLA = preload("res://assets/iconos/pistola.svg")
const ICONO_ESCOPETA = preload("res://assets/iconos/escopeta.svg")
const ICONO_GRANADA = preload("res://assets/iconos/granada.svg")

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
	"AZUL": {"texto": "¡VICTORIA AZUL!", "color": Color(0.25, 0.65, 1.0)},
	"ROJO": {"texto": "¡VICTORIA ROJA!", "color": Color(1.0, 0.25, 0.25)}
}

var _banner: PanelContainer
var _texto_turno: Label
var _contenedor_acciones: MarginContainer
var _boton_apuntar: Button
var _boton_terminar: Button
var _pantalla_final: PanelContainer
var _texto_resultado: Label
var _boton_reiniciar: Button
var _panel_personaje: PanelContainer
var _swatch: ColorRect
var _label_personaje: Label
var _contenedor_armas: PanelContainer
var _label_arma: Label
var _boton_pistola: TextureButton
var _boton_principal: TextureButton

var _unidad: Node = null


func _init(ui: Node) -> void:
	_banner = ui.get_node("BannerTurno")
	_texto_turno = ui.get_node("BannerTurno/TextoTurno")
	_contenedor_acciones = ui.get_node("ContenedorAcciones")
	_boton_apuntar = ui.get_node("ContenedorAcciones/HBoxContainer/BotonApuntar")
	_boton_terminar = ui.get_node("ContenedorAcciones/HBoxContainer/BotonTerminar")
	_pantalla_final = ui.get_node("PantallaFinal")
	_texto_resultado = ui.get_node("PantallaFinal/VBoxContainer/TextoResultado")
	_boton_reiniciar = ui.get_node("PantallaFinal/VBoxContainer/BotonReiniciar")
	_panel_personaje = ui.get_node("PanelPersonaje")
	_swatch = ui.get_node("PanelPersonaje/HBoxPersonaje/Swatch")
	_label_personaje = ui.get_node("PanelPersonaje/HBoxPersonaje/LabelPersonaje")
	_contenedor_armas = ui.get_node("ContenedorArmas")
	_label_arma = ui.get_node("ContenedorArmas/VBoxArmas/LabelArma")
	_boton_pistola = ui.get_node("ContenedorArmas/VBoxArmas/HBoxArmas/BotonPistola")
	_boton_principal = ui.get_node("ContenedorArmas/VBoxArmas/HBoxArmas/BotonPrincipal")

	_pantalla_final.visible = false
	_contenedor_acciones.visible = false
	_contenedor_armas.visible = false
	_panel_personaje.visible = false

	_boton_pistola.pressed.connect(func(): _elegir_arma(false))
	_boton_principal.pressed.connect(func(): _elegir_arma(true))
	_boton_apuntar.pressed.connect(_on_apuntar)
	_boton_terminar.pressed.connect(_on_terminar)
	_boton_reiniciar.pressed.connect(_on_reiniciar)


func actualizar(activa) -> void:
	_boton_apuntar.disabled = not activa.puede_apuntar()


func mostrar_turno(nuevo_turno: String) -> void:
	var config = CONFIG_TURNO[nuevo_turno]
	_texto_turno.text = config.texto
	var sb = _banner.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if sb:
		sb.border_color = config.borde
		sb.bg_color = config.fondo
		_banner.add_theme_stylebox_override("panel", sb)

	_banner.scale = Vector2(0.3, 0.3)
	_banner.pivot_offset = _banner.size / 2.0

	var tween = _banner.create_tween()
	tween.tween_property(_banner, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.15)


func activar_para_unidad(unidad: Node2D) -> void:
	if not (is_instance_valid(unidad) and unidad.is_in_group("unidades")):
		_contenedor_acciones.visible = false
		_contenedor_armas.visible = false
		_panel_personaje.visible = false
		return

	_contenedor_acciones.visible = true
	_boton_apuntar.disabled = false
	_contenedor_armas.visible = true
	_panel_personaje.visible = true
	_actualizar_panel_personaje(unidad)

	if is_instance_valid(_unidad) and _unidad.arma_cambiada.is_connected(_on_arma_cambiada):
		_unidad.arma_cambiada.disconnect(_on_arma_cambiada)
	_unidad = unidad
	if not unidad.arma_cambiada.is_connected(_on_arma_cambiada):
		unidad.arma_cambiada.connect(_on_arma_cambiada)
	_actualizar_iconos_armas(unidad)
	_on_arma_cambiada(unidad.arma_activa, unidad.tipo_arma, unidad.usos_principal_restantes)


func mostrar_fin(ganador: String) -> void:
	_pantalla_final.visible = true
	_contenedor_acciones.visible = false

	var config = CONFIG_VICTORIA[ganador]
	_texto_resultado.text = config.texto

	var settings = LabelSettings.new()
	settings.font_size = 40
	settings.font_color = config.color
	settings.outline_size = 8
	settings.outline_color = Color(0, 0, 0)
	_texto_resultado.label_settings = settings


func _actualizar_panel_personaje(unidad: Node2D) -> void:
	_swatch.color = unidad.color_equipo
	_label_personaje.text = "JUGADOR 1" if unidad.is_in_group("jugadores") else "JUGADOR 2"


func _actualizar_iconos_armas(unidad: Node2D) -> void:
	match unidad.tipo_arma:
		UnidadBase.ArmaTipo.ESCOPETA:
			_boton_principal.texture_normal = ICONO_ESCOPETA
		UnidadBase.ArmaTipo.GRANADA:
			_boton_principal.texture_normal = ICONO_GRANADA
		_:
			_boton_principal.texture_normal = ICONO_PISTOLA
	_boton_principal.visible = unidad.tipo_arma != UnidadBase.ArmaTipo.PISTOLA


func _on_arma_cambiada(activa: int, principal: int, usos: int) -> void:
	var es_principal := activa != UnidadBase.ArmaTipo.PISTOLA
	_boton_pistola.modulate = Color(1, 1, 1, 1) if not es_principal else Color(0.5, 0.5, 0.55, 1)
	if usos <= 0:
		_boton_principal.disabled = true
		_boton_principal.modulate = Color(0.95, 0.25, 0.25, 1)
	else:
		_boton_principal.disabled = false
		_boton_principal.modulate = Color(1, 1, 1, 1) if es_principal else Color(0.5, 0.5, 0.55, 1)
	if es_principal:
		var nombre := "Escopeta" if principal == UnidadBase.ArmaTipo.ESCOPETA else "Granada"
		_label_arma.text = "%s  x%d" % [nombre, usos]
	else:
		_label_arma.text = "Pistola"


func _on_apuntar() -> void:
	var activa = ManejadorTurnos.unidad_activa
	if is_instance_valid(activa) and activa is UnidadBase:
		activa.cambiar_a_apuntado()


func _on_terminar() -> void:
	ManejadorTurnos.finalizar_accion_unidad_actual()


func _on_reiniciar() -> void:
	_boton_reiniciar.get_tree().reload_current_scene()


func _elegir_arma(principal: bool) -> void:
	var u = ManejadorTurnos.unidad_activa
	if is_instance_valid(u) and u.has_method("seleccionar_arma"):
		u.seleccionar_arma(principal)
