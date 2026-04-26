extends Node2D

enum LightState { GREEN, YELLOW, RED }

var current_state = LightState.GREEN

func set_state(new_state):
	current_state = new_state
	update_visual()

func update_visual():
	$TLVisualsNPC/GreenLight.visible = current_state == LightState.GREEN
	$TLVisualsNPC/YellowLight.visible = current_state == LightState.YELLOW
	$TLVisualsNPC/RedLight.visible = current_state == LightState.RED
