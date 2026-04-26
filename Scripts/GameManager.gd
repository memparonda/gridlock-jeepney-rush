extends Node

signal on_level_complete
signal on_level_failed

var game_over := false
var is_paused := false
var can_pause := true

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

# Call this when all passengers are dropped off
func trigger_victory(delay: float = 0.0):
	if game_over: return
	
	game_over = true # Set this immediately so nothing else can happen
	
	# Wait for the animations to finish if a delay is passed
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		
	can_pause = false
	is_paused = true
	get_tree().paused = true
	
	print("GameManager: Victory triggered!")
	AudioController.play_level_complete()
	on_level_complete.emit()

# Call this when the timer hits zero
func trigger_defeat(delay: float = 0.0):
	if game_over: return
	
	game_over = true
	
	# Wait a moment so the player processes that they lost
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		
	can_pause = false
	is_paused = true
	get_tree().paused = true
	
	print("GameManager: Defeat triggered!")
	AudioController.play_level_failed()
	on_level_failed.emit()
