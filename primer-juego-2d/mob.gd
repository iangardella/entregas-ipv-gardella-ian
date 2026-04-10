extends RigidBody2D

@export
var MIN_SPEED = 150 
@export
var MAX_SPEED = 250

var mob_types = ["fly", "walk", "swim"]

func _ready() -> void:
	$AnimatedSprite2D.animation = mob_types[randi() % mob_types.size()]
	


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	
