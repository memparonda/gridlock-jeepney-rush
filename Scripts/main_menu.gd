extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioController.play_menu_music()
	get_tree().paused = false  # 🔥 reset pause just in case
	
func _on_play_pressed() -> void:
	AudioController.stop_menu_music(1.0)
	SceneTransition.transition_to_scene("res://Scenes/Track/track.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
