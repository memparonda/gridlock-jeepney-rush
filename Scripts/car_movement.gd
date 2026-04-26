extends CharacterBody2D

@export var acceleration: float = 250.0
@export var max_speed: float = 300.0
@export var friction: float = 250.0
@export var brake_force: float = 500.0  # NEW: stronger than friction
@export var turn_speed: float = 3.0
@export var drift_factor: float = 0.9

@export var turn_accel: float = 2.0
@export var turn_friction: float = 2.5

@export var total_time: float = 80.0   # Total time in seconds
@export var max_capacity: int = 14
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var engine_startup: AudioStreamPlayer2D = $EngineStartup
@onready var vehicle_crash: AudioStreamPlayer2D = $VehicleCrash

@export var min_pitch := 1.0
@export var max_pitch := 1.8
@export var pitch_smoothness := 5.0
@export var gear_speeds := [0.0, 50.0, 120.0, 200.0, 300.0] # speed thresholds
@export var max_gears := 4
@export var rpm_response := 2.0   # how fast RPM reacts

var current_gear := 1
var last_gear := 1
var gear_shift_cooldown := 0.0
var engine_rpm := 0.0

var current_passengers: Array[Area2D] = []
var current_time: float = total_time
var has_penalized_this_frame: bool = false

var speed: float = 0.0
var turn_velocity: float = 0.0
var was_colliding := false
var warned_late = false
var had_passengers := false
var timer_active := true
signal jeepney_stopped(jeepney_node)
var was_moving := false

func start_engine_sequence():
	engine_startup.play()

	var length = engine_startup.stream.get_length()
	var overlap = 0.2

	await get_tree().create_timer(length - overlap).timeout

	engine_sound.play()

	var tween = create_tween()

	# Fade IN loop
	tween.tween_property(engine_sound, "volume_db", -18, overlap)

	# Fade OUT startup
	tween.parallel().tween_property(engine_startup, "volume_db", -20, overlap)

func _ready():
	start_engine_sequence()

func play_vehicle_crash():
	vehicle_crash.play()

func handle_collision():
	var time_penalty = 2.0
	current_time = max(current_time - time_penalty, 0)

func _physics_process(delta):
	var input_forward = Input.get_action_strength("accelerate")
	var input_brake = Input.get_action_strength("brake")
	var input_turn = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	
# Timer Countdown
	if timer_active:
		current_time -= delta
		current_time = max(current_time, 0)
	
# LOSE CONDITION
	if current_time <= 0 and not GameManager.game_over:
		print("Time's up!")
		timer_active = false
		engine_sound.stop()
		set_physics_process(false) 
		
		# Give a flat 1.5 second delay so the game doesn't instantly freeze
		GameManager.trigger_defeat(1.5)

	
	# ✅ Collision handling (FIXED)
	if get_slide_collision_count() > 0:
		if not has_penalized_this_frame:
			handle_collision()
			has_penalized_this_frame = true
			play_vehicle_crash()
	else:
		has_penalized_this_frame = false
	# 🚀 Acceleration
	if input_forward > 0:
		speed += acceleration * input_forward * delta

	# 🛑 BRAKING
	elif input_brake > 0:
		if speed > 0:
			# braking forward motion
			speed -= brake_force * input_brake * delta
		else:
			# reverse movement (slower)
			speed -= acceleration * 0.4 * input_brake * delta

	# 🧊 Natural friction
	else:
		if speed > 0:
			speed -= friction * delta
		elif speed < 0:
			speed += friction * delta

	# Clamp speed
	speed = clamp(speed, -max_speed * 0.4, max_speed)

	# 🛞 TURNING (with ease)
	if input_turn != 0:
		turn_velocity = lerp(turn_velocity, input_turn * turn_speed, turn_accel * delta)
	else:
		turn_velocity = lerp(turn_velocity, 0.0, turn_friction * delta)

	if abs(speed) > 10:
		rotation += turn_velocity * delta * (speed / max_speed)

	# 🚗 Movement
	var forward = Vector2.UP.rotated(rotation)
	velocity = velocity.lerp(forward * speed, drift_factor)

	move_and_slide()
	
	if velocity.length() < 10.0:
		if was_moving:
			# Pass 'self' through the signal!
			jeepney_stopped.emit(self) 
			was_moving = false
	else:
		was_moving = true

	# 🎯 Target RPM based on speed
	var speed_ratio = abs(speed) / max_speed
	speed_ratio = clamp(speed_ratio, 0.0, 1.0)

	# 🎧 Smooth RPM (THIS is the key fix)
	engine_rpm = lerp(engine_rpm, speed_ratio, rpm_response * delta)

	# 🎯 Determine gear based on RPM (NOT raw speed)
	for i in range(1, max_gears + 1):
		if engine_rpm < float(i) / max_gears:
			current_gear = i
			break

	# 🎚 Gear shift cooldown
	gear_shift_cooldown -= delta

	# 🔥 Trigger shift (based on RPM now)
	if current_gear != last_gear and gear_shift_cooldown <= 0:
		last_gear = current_gear
		gear_shift_cooldown = 1.6  # longer = more realistic
	
		engine_rpm *= 0.7  # drop RPM instead of pitch  # drop RPM instead of pitch

	# 🎵 Pitch based on RPM (not speed anymore)
	var target_pitch = lerp(min_pitch, max_pitch, engine_rpm)

	engine_sound.pitch_scale = lerp(
		engine_sound.pitch_scale,
		target_pitch,
		pitch_smoothness * delta
	)

	# 💤 Idle
	if abs(speed) < 5:
		engine_rpm = lerp(engine_rpm, 0.1, 2.0 * delta)
		engine_sound.pitch_scale = min_pitch

func has_empty_seats() -> bool:
	return current_passengers.size() < max_capacity

# Passenger Pick-up
func pick_up(destination: Area2D):
	if has_empty_seats():
		current_passengers.append(destination)
		had_passengers = true
		
		# --- NEW: Build a text list of all current destinations ---
		var destination_names = ""
		for p in current_passengers:
			destination_names += p.name + ", "
			
		# Clean up the trailing comma at the end of the text
		destination_names = destination_names.trim_suffix(", ")
		
		# --- NEW: Print exactly who boarded and the full route! ---
		print("Passenger boarded! Next stop: ", destination.name)
		print("Jeepney Manifest (", current_passengers.size(), "/", max_capacity, "): [", destination_names, "]")
		print("-------------------------------------------------")
		
	else:
		print("Jeepney is full! Cannot pick up passenger for: ", destination.name)

# Passenger Drop-off
func drop_off(destination: Area2D) -> int:
	# We need to count how many people want to get off at this specific stop
	var dropped_count = 0
	
	# When removing items from an array in a loop, ALWAYS loop backwards!
	for i in range(current_passengers.size() - 1, -1, -1):
		if current_passengers[i] == destination:
			current_passengers.remove_at(i)
			dropped_count += 1
			
	print("Dropped off ", dropped_count, " passengers at ", destination.name)
	print("Passengers remaining: ", current_passengers.size())
	
# WIN CONDITION
	if had_passengers and current_passengers.size() == 0:
		print("All passengers delivered!")
		timer_active = false
		engine_sound.stop()
		set_physics_process(false) # Stops the Jeepney from driving away
		
		# Calculate exactly how long the animations will take!
		# (0.4 seconds per passenger) + (0.5 seconds of extra buffer time)
		var animation_time = (dropped_count * 0.4) + 0.5 
		
		# Pass the calculated time into the manager
		GameManager.trigger_victory(animation_time)
	
	# Return the number so the destination knows how many animations to play
	return dropped_count

func _process(delta):
	# ✅ Update UI
	$HUD/TimerLabel.text = "Time: " + str(round(current_time))
