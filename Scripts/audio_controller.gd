extends Node

@onready var menu_music: AudioStreamPlayer = $Menu_Music
@onready var level_music: AudioStreamPlayer = $Level_Music
@onready var level_complete_sound: AudioStreamPlayer = $Level_Complete_Sound
@onready var level_failed_sound: AudioStreamPlayer = $Level_Failed_Sound

# --- NEW: We use this to track and kill ghost tweens! ---
var level_music_tween: Tween
var menu_music_tween: Tween

# Main Menu Music
# Main Menu Music
func play_menu_music():
	# 1. Kill any ghost fade-outs
	if menu_music_tween and menu_music_tween.is_valid():
		menu_music_tween.kill()
		
	# 2. TURN THE DIAL BACK UP! (Adjust this number to your preferred default volume)
	menu_music.volume_db = -30.0 
	
	# 3. Hit play
	menu_music.play()
	
func stop_menu_music(fade_time := 1.5):
	if not menu_music.playing:
		return
	
	# Kill ghosts
	if menu_music_tween and menu_music_tween.is_valid():
		menu_music_tween.kill()
	
	# Create and save the new fade-out tween
	menu_music_tween = create_tween()
	menu_music_tween.tween_property(menu_music, "volume_db", -100, fade_time)
	
	# Safely stop when finished
	menu_music_tween.tween_callback(menu_music.stop)


# Level Music
func play_level_music(fade_time := 1.5):
	# 1. If there is a fade-out tween running from the Game Over screen, kill it!
	if level_music_tween and level_music_tween.is_valid():
		level_music_tween.kill()
		
	level_music.volume_db = -80
	level_music.play()

	# 2. Save the fade-in tween to our tracker
	level_music_tween = create_tween()
	level_music_tween.tween_property(level_music, "volume_db", -15, fade_time)

func stop_level_music(fade_time := 2.5):
	if not level_music.playing:
		return

	# 1. Kill any existing tweens so they don't fight
	if level_music_tween and level_music_tween.is_valid():
		level_music_tween.kill()

	# 2. Save the fade-out tween to our tracker
	level_music_tween = create_tween()
	level_music_tween.tween_property(level_music, "volume_db", -80, fade_time)

	# 3. CRITICAL FIX: Use callback instead of 'await'. 
	# If this tween is killed by play_level_music(), this stop() command is erased!
	level_music_tween.tween_callback(level_music.stop)


# Play Level Complete
func play_level_complete():
	level_complete_sound.play()

# Play Level Failed
func play_level_failed():
	level_failed_sound.play()
