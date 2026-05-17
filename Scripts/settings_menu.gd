extends CanvasLayer

@onready var music_slider = $ColorRect/VBoxContainer/MusicSlider
@onready var sfx_slider = $ColorRect/VBoxContainer/SFXSlider

# We ask Godot for the exact ID numbers of the buses we created
@onready var music_bus_index = AudioServer.get_bus_index("Music")
@onready var sfx_bus_index = AudioServer.get_bus_index("SFX")

func _ready():
	# When the menu opens, update the sliders to match the current actual volume
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))

# Connect this to your Music HSlider's 'value_changed' signal
func _on_music_slider_value_changed(value: float) -> void:
	# Convert the 0.0-1.0 slider value into Decibels and apply it!
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))

# Connect this to your SFX HSlider's 'value_changed' signal
func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))

# Connect this to your Close Button's 'pressed' signal
func _on_close_button_pressed() -> void:
	hide()
