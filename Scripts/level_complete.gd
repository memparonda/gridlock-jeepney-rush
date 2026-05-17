extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Listen for the victory signal from the GameManager!
	GameManager.on_level_complete.connect(show_level_complete)

func show_level_complete():
	print("UI: Showing Level Complete Screen")
	
	# 🎬 Show UI with fade (Pausing is now handled by GameManager)
	visible = true
	modulate.a = 0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

# (Keep your _on_restart_pressed() and _on_main_menu_pressed() functions exactly as they are!)


# 🎮 BUTTONS
func _on_next_level_button_pressed():
	# 1. Unpause the game so the next level isn't frozen!
	get_tree().paused = false 
	GameManager.is_paused = false
	# 2. Tell the GameManager we are no longer in a "game over/victory" state
	GameManager.game_over = false 
	AudioController.level_complete_sound.stop()
	await get_tree().process_frame
	# 3. Check if we actually have a next level set
	if GameManager.next_level_scene != "":
		# Transition to the next level!
		SceneTransition.transition_to_scene(GameManager.next_level_scene)
	else:
		# Safety net: If there is no next level (like beating the final level), 
		# send them back to the Main Menu!
		SceneTransition.transition_to_scene("res://Scenes/Main_Menu/main_menu.tscn")

func _on_restart_pressed():
	GameManager.game_over = false
	GameManager.can_pause = true
	GameManager.is_paused = false
	DialogueOverlay.force_close()
	get_tree().paused = false
	AudioController.level_complete_sound.stop()
	await get_tree().process_frame
	get_tree().reload_current_scene()


func _on_main_menu_pressed():
	GameManager.game_over = false
	GameManager.can_pause = false
	GameManager.is_paused = false
	DialogueOverlay.force_close()
	get_tree().paused = false
	AudioController.level_complete_sound.stop()
	AudioController.stop_level_music(1.0)
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")
