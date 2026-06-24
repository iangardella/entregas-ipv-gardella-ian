extends Control

@onready var menu_botones: VBoxContainer = $CentroVBox
@onready var panel_instrucciones: PanelContainer = $PanelInstrucciones


func _ready() -> void:
	panel_instrucciones.visible = false
	$CentroVBox/BotonJugar.pressed.connect(_on_jugar)
	$CentroVBox/BotonInstrucciones.pressed.connect(_on_instrucciones)
	$CentroVBox/BotonSalir.pressed.connect(_on_salir)
	$PanelInstrucciones/MargenInstr/VBoxInstr/BotonVolver.pressed.connect(_on_volver)


func _on_jugar() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_instrucciones() -> void:
	menu_botones.visible = false
	panel_instrucciones.visible = true


func _on_volver() -> void:
	panel_instrucciones.visible = false
	menu_botones.visible = true


func _on_salir() -> void:
	get_tree().quit()
