extends Node2D

enum LightState { GREEN, YELLOW, RED }

var current_state = LightState.GREEN

func set_state(new_state):
	current_state = new_state
	update_visual()

func update_visual():
	$Visuals/GreenLight.visible = current_state == LightState.GREEN
	$Visuals/YellowLight.visible = current_state == LightState.YELLOW
	$Visuals/RedLight.visible = current_state == LightState.RED
