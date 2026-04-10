extends Area2D

signal hit

@export
var SPEED = 0
var velocity = Vector2()
var screensize

func _ready():
	hide()
	screensize = get_viewport_rect().size
	

func _process(delta):
	velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1;
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1;
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1;
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1;
	if velocity.length() > 0:
		$AnimatedSprite2D.play()
		velocity = velocity.normalized() * SPEED
	else:
		$AnimatedSprite2D.stop()
	
	position += velocity * delta
	position.x = clamp(position.x, 0, screensize.x);
	position.y = clamp(position.y, 0, screensize.y)
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "right"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
		


func _on_player_body_entered(body: Node2D) -> void:
	hide()
	emit_signal("hit")
	call_deferred("set_monitoring", false)

func start(pos):
	position = pos
	show()
	monitoring = true 
	
	
