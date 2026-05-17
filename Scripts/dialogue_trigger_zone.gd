extends Area2D

# @export_multiline gives you a nice big text box in the Godot Inspector!
@export_multiline var dialogue_text: String = "Enter route message here..."
@export var audio_clip = preload("res://Assets/Audios/universfield-new-notification-08-352461.mp3")
@export var npc_portrait = preload("res://Assets/Images/Sprites/passenger_level_1.png")
# Prevents the message from spamming if the Jeepney reverses over the line
@export var trigger_once: bool = true 
var has_triggered: bool = false

func _on_body_entered(body):
	# 1. Ensure it's the Jeepney
	if body.is_in_group("Player") and body.current_passengers.size() > 0:
		
		# 2. Check if it's already been fired
		if trigger_once and has_triggered:
			return
			
		# 3. Lock it and call your Global Dialogue Manager!
		has_triggered = true
		DialogueOverlay.show_dialogue(dialogue_text, npc_portrait, audio_clip)
