extends Node

enum LightState { GREEN, YELLOW, RED }

@export var green_time := 5.0
@export var yellow_time := 3.0

var current_state = LightState.GREEN

# Store references to lights
var group_a = []  # e.g. North-South
var group_b = []  # e.g. East-West

func _ready():
	# Assign traffic lights to groups manually or via code
	group_a = get_tree().get_nodes_in_group("traffic_ns")
	group_b = get_tree().get_nodes_in_group("traffic_ew")

	run_cycle()

func run_cycle() -> void:
	while true:
		# Group A GREEN, Group B RED
		set_group_state(group_a, LightState.GREEN)
		set_group_state(group_b, LightState.RED)
		await get_tree().create_timer(green_time, false).timeout

		set_group_state(group_a, LightState.YELLOW)
		await get_tree().create_timer(yellow_time, false).timeout

		# Switch
		set_group_state(group_a, LightState.RED)
		set_group_state(group_b, LightState.GREEN)
		await get_tree().create_timer(green_time, false).timeout

		set_group_state(group_b, LightState.YELLOW)
		await get_tree().create_timer(yellow_time, false).timeout

func set_group_state(group, state):
	for light in group:
		if light.has_method("set_state"):
			light.set_state(state)
