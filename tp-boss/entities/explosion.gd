extends Sprite2D

# Explosion de la granada: estrella naranja que crece y se desvanece.
func _ready() -> void:
	z_index = 50
	modulate = Color(1.0, 0.6, 0.2, 1.0)
	scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(2.8, 2.8), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "modulate:a", 0.0, 0.45).set_delay(0.1)
	t.chain().tween_callback(queue_free)
