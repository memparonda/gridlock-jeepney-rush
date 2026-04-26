extends Node

var subtitle_label

func register_label(label):
	subtitle_label = label

func say(text: String, duration := 3.0):
	if subtitle_label:
		subtitle_label.show_text(text, duration)
