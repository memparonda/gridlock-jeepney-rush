extends Control

func _ready():
	visible = false  # hidden at start

func _process(_delta):
	# Hide the pause menu immediately if the level is complete or failed
	if GameManager.game_over:
		visible = false
		return
		
	# Otherwise, sync normally
	visible = GameManager.is_paused

func _input(event):
	if event.is_action_pressed("pause"):
		if not GameManager.can_pause:
			return
		if GameManager.game_over:
			return
		toggle_pause()

func toggle_pause():
	if GameManager.is_paused:
		_unpause_with_fade()
	else:
		_pause_with_fade()
		
func _pause_with_fade():
	GameManager.is_paused = !GameManager.is_paused
	get_tree().paused = GameManager.is_paused
	visible = GameManager.is_paused

	modulate.a = 0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _unpause_with_fade():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	await tween.finished

	GameManager.is_paused = false
	get_tree().paused = false
	visible = false
	
func _on_resume_pressed() -> void:
	GameManager.is_paused = false
	get_tree().paused = false
	visible = false

func _on_restart_pressed():
	GameManager.is_paused = false
	DialogueOverlay.force_close()
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().paused = false
	GameManager.is_paused = false
	DialogueOverlay.force_close()
	AudioController.stop_level_music(1.0)
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")
