extends Node

@onready var menu_music: AudioStreamPlayer = $Menu_Music
@onready var level_music: AudioStreamPlayer = $Level_Music
@onready var level_complete_sound: AudioStreamPlayer = $Level_Complete_Sound
@onready var level_failed_sound: AudioStreamPlayer = $Level_Failed_Sound

# Main Menu Music
func play_menu_music():
	menu_music.play()
	
func stop_menu_music(fade_time := 1.5):
	if not menu_music.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(menu_music, "volume_db", -100, fade_time)
	
	await tween.finished
	menu_music.stop()
	menu_music.volume_db = -30


# Level Music
func play_level_music(fade_time := 1.5):
	level_music.volume_db = -80
	level_music.play()

	var tween = create_tween()
	tween.tween_property(level_music, "volume_db", -15, fade_time)

func stop_level_music(fade_time := 2.5):
	if not level_music.playing:
		return

	var tween = create_tween()
	tween.tween_property(level_music, "volume_db", -80, fade_time)

	await tween.finished
	level_music.stop()
	level_music.volume_db = -15  # reset for next play

# Play Level Complete
func play_level_complete():
	level_complete_sound.play()

# Play Level Failed
func play_level_failed():
	level_failed_sound.play()
