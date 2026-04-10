extends CanvasLayer

signal start_game

# Called when the node enters the scene tree for the first time.
func show_message(text):
	$MessageLabel.text = text
	$MessageLabel.show()
	$MessageTimer.start()
	

func game_over():
	show_message("Game Over")
	await $MessageTimer.timeout
	$StrartButton.show()
	$MessageLabel.text = "Dodge the\nCreeps!"
	$MessageLabel.show()
	
func update_score(score):
	$ScoreLabel.text = str(score)


func _on_message_timer_timeout() -> void:
	$MessageLabel.hide()
	


func _on_strart_button_pressed() -> void:
	$StrartButton.hide()
	emit_signal("start_game")
	
