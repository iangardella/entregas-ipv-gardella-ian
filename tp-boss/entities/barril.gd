class_name Barril
extends StaticBody2D

const VIDA_MAX := 2

var vida := VIDA_MAX

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("barriles")


func recibir_danio_barril(cantidad: int) -> void:
	vida -= cantidad
	if vida <= 0:
		_romper()
	elif is_instance_valid(sprite):
		# parpadeo de dano
		sprite.modulate = Color(1.6, 1.2, 1.2)
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)


func _romper() -> void:
	queue_free()
