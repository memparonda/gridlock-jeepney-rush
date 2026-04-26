extends Area2D

@export var passenger_texture: Texture2D 
@export var passenger_scale: Vector2 = Vector2(0.02, 0.02) 

# --- NEW VARIABLES ---
var jeep_in_zone: Node2D = null
var is_dropping_off: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		jeep_in_zone = body
		
		if not body.jeepney_stopped.is_connected(_on_jeepney_stopped):
			body.jeepney_stopped.connect(_on_jeepney_stopped)
			
		if body.velocity.length() < 10.0:
			# Pass the body manually for the edge case
			_on_jeepney_stopped(body)

func _on_body_exited(body: Node2D):
	if body == jeep_in_zone:
		if body.jeepney_stopped.is_connected(_on_jeepney_stopped):
			body.jeepney_stopped.disconnect(_on_jeepney_stopped)
		jeep_in_zone = null

# Receive the jeepney argument
func _on_jeepney_stopped(jeepney: Node2D):
	if not is_dropping_off and is_instance_valid(jeepney):
		# We check the passed argument directly!
		if self in jeepney.current_passengers:
			start_dropoff(jeepney)
			
			# --- NEW CHECK: Does anyone in the Jeepney want to go here? ---
			if self in jeep_in_zone.current_passengers:
				start_dropoff(jeep_in_zone)

func start_dropoff(body: Node2D):
	is_dropping_off = true
	# (DELETE the 'jeep_in_zone = null' line from here!)
	
	# Find out how many people are getting off
	var drop_count = body.drop_off(self)
	
	for i in range(drop_count):
		spawn_dummy_passenger(body.global_position)
		await get_tree().create_timer(0.4).timeout
		
	is_dropping_off = false

# I moved the animation code into its own function to keep things clean
func spawn_dummy_passenger(spawn_pos: Vector2):
	var dropped_person = Sprite2D.new()
	
	if passenger_texture != null:
		dropped_person.texture = passenger_texture
	else:
		push_error("FAILED: passenger_texture is empty in the Inspector!")
		return 
		
	dropped_person.z_index = 100 
	dropped_person.z_as_relative = false 
	dropped_person.scale = passenger_scale
	dropped_person.top_level = true 
	
	add_child(dropped_person)
	dropped_person.global_position = spawn_pos
	
	var distance_to_walk = dropped_person.global_position.distance_to(global_position)
	var walk_speed = 100.0 
	var walk_duration = max(distance_to_walk / walk_speed, 0.2)
	
	var tween = create_tween()
	tween.tween_property(dropped_person, "global_position", global_position, walk_duration)
	
	tween.finished.connect(func():
		dropped_person.queue_free()
	)
