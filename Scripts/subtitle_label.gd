extends Label

var display_time = 3.0
var timer = 0.0

func show_text(text: String, duration := 3.0):
	self.text = text
	timer = duration
	visible = true

func _process(delta):
	if timer > 0:
		timer -= delta
		if timer <= 0:
			visible = false
			
func _ready():
	DialogueManager.register_label(self)
