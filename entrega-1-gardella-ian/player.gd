extends Sprite2D

@export
var SPEED = 400
var velocity = Vector2()
var screensize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screensize = get_viewport_rect().size

func _process(delta):
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("mover_der"):
		velocity.x += 1;
	if Input.is_action_pressed("mover_izq"):
		velocity.x -= 1;

	position += velocity.normalized() * SPEED * delta
	position.x = clamp(position.x, 0, screensize.x)
	position.y = clamp(position.y, 0, screensize.y)
	
