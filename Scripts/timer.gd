extends Timer

@onready var label: Label = $Label  # Sibling or child Label

var initial_time: float = 10.0

func _ready():
	wait_time = initial_time
	one_shot = false  # Loop for display, stop manually if needed
	timeout.connect(_on_timeout)

func _process(delta):
	if is_stopped():
		label.text = ""
		return
	label.text = "%.1f" % time_left  # Updates live countdown

func _on_timeout():
	label.text = "Time's up!"  # Or hide/reset
	# Optional: stop() or perform action like game over
