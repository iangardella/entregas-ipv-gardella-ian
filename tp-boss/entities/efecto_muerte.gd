extends Sprite2D


func _ready() -> void:
	z_index = 50
	scale = Vector2(0.25, 0.25)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.08)
	t.chain().tween_callback(queue_free)
