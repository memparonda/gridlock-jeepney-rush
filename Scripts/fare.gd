extends Area2D

@export var possible_destinations: Array[Area2D] 
var my_destination: Area2D
@onready var sprite = $Sprite2D 

# --- NEW VARIABLES ---
var jeep_in_zone: Node2D = null
var is_picking_up: bool = false # Prevents the animation from firing 60 times a second
var passenger_name = "Passenger"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited) # Connect the exit signal!
	
	if possible_destinations.size() > 0:
		my_destination = possible_destinations.pick_random()

# Receive the jeepney argument
func _on_jeepney_stopped(jeepney: Node2D):
	if not is_picking_up and is_instance_valid(jeepney):
		if jeepney.has_empty_seats():
			start_pickup(jeepney)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		jeep_in_zone = body
		
		if not body.jeepney_stopped.is_connected(_on_jeepney_stopped):
			body.jeepney_stopped.connect(_on_jeepney_stopped)
			
		if body.velocity.length() < 10.0:
			_on_jeepney_stopped(body)

func _on_body_exited(body: Node2D):
	if body == jeep_in_zone:
		if body.jeepney_stopped.is_connected(_on_jeepney_stopped):
			body.jeepney_stopped.disconnect(_on_jeepney_stopped)
		jeep_in_zone = null

func start_pickup(body: Node2D):
	is_picking_up = true
	set_deferred("monitoring", false)
	
	var distance_to_walk = sprite.global_position.distance_to(body.global_position)
	var walk_speed = 100.0 
	var walk_duration = max(distance_to_walk / walk_speed, 0.2)
	
	var tween = create_tween()
	tween.tween_property(sprite, "global_position", body.global_position, walk_duration)
	
	tween.finished.connect(func():
		body.pick_up(my_destination)
		queue_free()
	)
	
func speak(text):
	DialogueManager.say(passenger_name + ": " + text)
