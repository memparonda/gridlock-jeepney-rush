extends Node

var music_stopped := false

func _ready() -> void:
	AudioController.play_level_music()
	GameManager.can_pause = true
	# --- NEW: Set the destination for the Next Level button! ---
	GameManager.next_level_scene = "res://Scenes/Track/track2.tscn"
	
func _process(_delta):
	if GameManager.game_over and not music_stopped:
		music_stopped = true
		AudioController.stop_level_music(1.5)  # fade out
		DialogueOverlay.force_close()
