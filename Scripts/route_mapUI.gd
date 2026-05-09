extends CanvasLayer

@onready var route_map = $RouteMapUI

var map_open = false

func _ready():
	route_map.visible = false

func _process(delta):
	if Input.is_action_just_pressed("open_routemap"):
		toggle_map()

func toggle_map():
	map_open = !map_open
	route_map.visible = map_open
