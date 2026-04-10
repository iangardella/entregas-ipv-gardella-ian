extends Node2D

@export
var Mob :PackedScene
var score

func _ready() -> void:
	randomize()
	
func new_game():
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.show_message("Get Ready")
	$HUD.update_score(score)


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.game_over()

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	

func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)
	


func _on_mob_timer_timeout() -> void:
	$MobPath/MobSpawnLocation.progress_ratio = randf()
	var mob = Mob.instantiate()
	add_child(mob)
	var direction = $MobPath/MobSpawnLocation.rotation + PI / 2
	mob.position = $MobPath/MobSpawnLocation.position
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	var velocity = Vector2(randf_range(mob.MIN_SPEED, mob.MAX_SPEED), 0)
	mob.linear_velocity = velocity.rotated(direction)
	
	
