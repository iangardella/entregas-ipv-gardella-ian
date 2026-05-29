extends Node2D

@onready var label: Label = $Label

func mostrar(danio: int, pos: Vector2) -> void:
	global_position = pos
	label.text = str(danio)
	
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 20
	label.label_settings.font_color = Color(1.0, 0.25, 0.25) 
	label.label_settings.outline_size = 5
	label.label_settings.outline_color = Color(0, 0, 0)
	
	var tween = create_tween().set_parallel(true)
	var desp_x = randf_range(-25.0, 25.0)
	var destino = pos + Vector2(desp_x, -60.0)
	
	tween.tween_property(self, "global_position", destino, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.65).set_delay(0.25)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(queue_free)
