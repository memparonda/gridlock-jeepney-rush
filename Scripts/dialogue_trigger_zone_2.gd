extends Area2D

@export var dialogue_text: Array[String] = [
	"Not much traffic here, but I hope you can get us there on time."
]

@onready var sound = $Chatter

var triggered := false

func play_dialogue_sequence() -> void:

	for line in dialogue_text:
		if GameManager.game_over:
			break

		DialogueManager.say(line)

		var wait_time = get_read_time(line)
		await get_tree().create_timer(wait_time).timeout

	# ✅ Dialogue is finished → STOP sound
	sound.stop()

func get_read_time(text: String) -> float:
	var base_time = 1.5  # minimum time
	var char_time = 0.05 # seconds per character
	
	return max(base_time, text.length() * char_time)

func _on_body_entered(body) :
	if triggered:
		print("[Dialogue Trigger Zone] Entered by:", body.name)
		return

	if body.name == "Car":
		if body.current_passengers.size() > 0:
			triggered = true
			play_dialogue_sequence()
			sound.play()
			return
			
func _process(delta):
	if GameManager.game_over and sound and sound.playing:
		sound.stop()
