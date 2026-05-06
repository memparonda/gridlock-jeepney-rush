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

func _on_restart_pressed():
	GameManager.game_over = false
	GameManager.can_pause = true
	GameManager.is_paused = false
	get_tree().paused = false
	AudioController.level_complete_sound.stop()
	await get_tree().process_frame
	get_tree().reload_current_scene()


func _on_main_menu_pressed():
	GameManager.game_over = false
	GameManager.can_pause = false
	GameManager.is_paused = false
	get_tree().paused = false
	AudioController.level_complete_sound.stop()
	AudioController.stop_level_music(1.0)
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")
