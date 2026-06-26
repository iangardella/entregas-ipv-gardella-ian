class_name ControladorApuntado
extends RefCounted

var _unidad


func _init(unidad) -> void:
	_unidad = unidad


func procesar() -> void:
	var u = _unidad
	u.velocity.x = 0

	var dir: Vector2 = (u.get_global_mouse_position() - u.arma.global_position).normalized()
	u.arma.rotation = dir.angle()

	if absf(dir.x) > 0.15:
		u.visual.flip_h = dir.x < 0
	_aplicar_pose(dir)

	u.mira_laser.visible = true
	u.actualizar_mira(dir)


func _aplicar_pose(dir: Vector2) -> void:
	var u = _unidad
	if not (u.visual is AnimatedSprite2D):
		return
	var elev := rad_to_deg(atan2(-dir.y, abs(dir.x)))
	var anim := &"aim_horizontal"
	if elev > 67.0:
		anim = &"aim_arriba"
	elif elev > 22.0:
		anim = &"aim_arribadiag"
	elif elev < -67.0:
		anim = &"aim_abajo"
	elif elev < -22.0:
		anim = &"aim_abajodiag"
	u.visual.play(anim)
