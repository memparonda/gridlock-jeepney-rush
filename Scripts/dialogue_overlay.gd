extends CanvasLayer

@onready var text_label = $Margin/NinePatchRect/HBoxContainer/RichTextLabel
@onready var chatter_audio = $Chatter
@onready var margin = $Margin 

# --- NEW: Point this to your newly moved TextureRect! ---
@onready var portrait = $Margin/NinePatchRect/TextureRect

var dialogue_tween: Tween 

func _ready():
	margin.modulate.a = 0.0
	hide()

# --- NEW: Added 'npc_face: Texture2D' back to the parameters ---
func show_dialogue(npc_text: String, npc_face: Texture2D, audio_clip: AudioStream):
	if dialogue_tween and dialogue_tween.is_valid():
		dialogue_tween.kill()

	# 1. Update the Text
	text_label.text = npc_text
	
	# --- NEW: 2. Update the Portrait ---
	if npc_face != null:
		portrait.texture = npc_face
		portrait.show()
	else:
		# If no face is provided (like a generic system warning), hide the picture box!
		portrait.hide() 
		
	# 3. Play the sound
	if audio_clip:
		chatter_audio.stream = audio_clip
		chatter_audio.play()
		
	# 4. Show and Animate!
	show()
	
	dialogue_tween = create_tween()
	dialogue_tween.tween_property(margin, "modulate:a", 1.0, 0.3)
	dialogue_tween.tween_interval(4.0)
	dialogue_tween.tween_property(margin, "modulate:a", 0.0, 0.3)
	dialogue_tween.tween_callback(hide)

# --- NEW: The Emergency Shutoff ---
func force_close():
	# 1. Kill the animation timer so it doesn't accidentally wake up later
	if dialogue_tween and dialogue_tween.is_valid():
		dialogue_tween.kill()
		
	# 2. Cut off the voice chatter instantly
	chatter_audio.stop()
	
	# 3. Reset the transparency and hide it
	margin.modulate.a = 0.0
	hide()
