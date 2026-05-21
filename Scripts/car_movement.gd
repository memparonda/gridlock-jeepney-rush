extends CharacterBody2D

@export var acceleration: float = 100.0
@export var max_speed: float = 300.0
@export var friction: float = 250.0
@export var brake_force: float = 500.0  # NEW: stronger than friction
@export var turn_speed: float = 3.0
@export var drift_factor: float = 0.9

@export var turn_accel: float = 2.0
@export var turn_friction: float = 2.5

@export var total_time: float = 160.0   # Total time in seconds
@export var max_capacity: int = 14
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var engine_startup: AudioStreamPlayer2D = $EngineStartup
@onready var vehicle_crash: AudioStreamPlayer2D = $VehicleCrash

# --- NEW: Camera Settings ---
@onready var camera = $Camera2D
@export var camera_distance: float = 150.0 # Increased slightly for top-down speed
@export var camera_smoothness: float = 5.0
# ----------------------------

@export_group("Late Warning Settings")
@export_multiline var late_warning_text: String = ""
@export var late_warning_portrait: Texture2D
@export var late_warning_audio: AudioStream

@export var min_pitch := 1.0
@export var max_pitch := 1.8
@export var pitch_smoothness := 5.0
@export var gear_speeds := [0.0, 100.0, 150.0, 200.0, 300.0] # speed thresholds
@export var max_gears := 4
@export var rpm_response := 2.0   # how fast RPM reacts

# --- NEW: Fuel System ---
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 0.5 
@export var refuel_rate: float = 25.0 # How fast it fills per second (takes 4 seconds to full)
var current_fuel: float = max_fuel
var is_refueling := false # Tracks if we are parked at a pump

var current_gear := 1
var last_gear := 1
var gear_shift_cooldown := 0.0
var engine_rpm := 0.0

var current_passengers: Array[Area2D] = []
var current_time: float
var has_penalized_this_frame: bool = false

var speed: float = 0.0
var turn_velocity: float = 0.0
var was_colliding := false
var warned_late = false
var had_passengers := false
var timer_active := true
signal jeepney_stopped(jeepney_node)
var was_moving := false

# --- NEW: Terrain Modifiers ---
var active_sand_zones: int = 0
var original_max_speed: float = 0.0
var original_acceleration: float = 0.0
var original_friction: float = 0.0

func start_engine_sequence():
	engine_startup.play()
	
	# --- NEW: Save the default driving stats! ---
	original_max_speed = max_speed
	original_acceleration = acceleration
	original_friction = friction

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
	current_time = total_time
	
	start_engine_sequence()
	
# --- NEW: Detach camera rotation from the Jeepney body ---
	if camera:
		camera.top_level = true
		
		# Instantly snap the camera to the correct starting position so it doesn't fly in!
		var forward = Vector2.UP.rotated(rotation)
		camera.global_position = global_position + forward * camera_distance

func play_vehicle_crash():
	vehicle_crash.play()

func handle_collision():
	var time_penalty = 2.0
	current_time = max(current_time - time_penalty, 0)
	
	# --- NEW: Trigger the visual flash! ---
	flash_timer_red()

func _physics_process(delta):
	var input_forward = Input.get_action_strength("accelerate")
	var input_brake = Input.get_action_strength("brake")
	var input_turn = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	
# Timer Countdown
	if timer_active:
		current_time -= delta
		current_time = max(current_time, 0)

# --- NEW: Late Warning Trigger ---
		if current_time <= 30.0 and not warned_late:
			warned_late = true
			show_late_warning()

		# --- UPDATED: Drain OR Fill Fuel ---
		if is_refueling:
			# Fill the tank while parked
			current_fuel += refuel_rate * delta
			current_fuel = min(current_fuel, max_fuel) # Caps it at 100
		elif abs(speed) > 5:
			# Drain the tank while driving
			current_fuel -= fuel_drain_rate * delta
			current_fuel = max(current_fuel, 0) # Caps it at 0
	
	# --- UPDATED: LOSE CONDITION (Time OR Fuel) ---
	if (current_time <= 0 or current_fuel <= 0) and not GameManager.game_over:
		if current_time <= 0:
			print("Time's up!")
		else:
			print("Out of gas!")
		timer_active = false
		engine_sound.stop()
		set_physics_process(false) 
		
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
	
		engine_rpm *= 0.7  # drop RPM instead of pitch  

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
	
# --- NEW: Dynamic Camera Logic (MOVED TO PHYSICS) ---
	if camera:
		# We reuse the 'forward' variable that was already calculated earlier in this frame!
		var target_pos = global_position + forward * camera_distance
		
		camera.global_position = camera.global_position.lerp(target_pos, camera_smoothness * delta)

func has_empty_seats() -> bool:
	return current_passengers.size() < max_capacity

# Passenger Pick-up
func pick_up(fare: Node, destination: Area2D):
	if has_empty_seats():
		current_passengers.append(destination)
		had_passengers = true
		
# --- NEW: Ask the destination for its unique details! ---
		# We use the .get() function. If the variable exists, it grabs it. 
		# If it doesn't exist, it safely returns 'null' without crashing!
		var face = fare.get("portrait")
		var audio = fare.get("voice_audio")
		var greeting = fare.get("greeting_text")
		
		# --- THE FIX: Only talk if they actually have custom data! ---
		if (greeting != null and greeting != "") or face != null:
			DialogueOverlay.show_dialogue(greeting, face, audio)
		
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
	if has_node("HUD/TimerLabel"):
		$HUD/TimerLabel.text = "Time: " + str(round(current_time))
		
	# --- NEW: Update Fuel UI ---
	if has_node("HUD/FuelBar"):
		$HUD/FuelBar.value = current_fuel

# --- UPDATED: Refuel Toggles ---
func start_refueling():
	is_refueling = true
	print("Started refueling...")

func stop_refueling():
	is_refueling = false
	print("Stopped refueling.")

# --- NEW: Late Warning Dialogue ---
func show_late_warning():
	if current_passengers.size() > 0:
		# Delete your old Label update code and use this:
		DialogueOverlay.show_dialogue(late_warning_text, late_warning_portrait, late_warning_audio)

# --- NEW: UI Feedback ---
func flash_timer_red():
	if has_node("HUD/TimerLabel"):
		var timer_label = $HUD/TimerLabel
		
		# Create a new Tween specifically for this label
		var tween = create_tween()
		
		# Step 1: Instantly turn it RED (takes 0.05 seconds)
		tween.tween_property(timer_label, "modulate", Color.RED, 0.05)
		
		# Step 2: Smoothly fade it back to WHITE (takes 0.4 seconds)
		tween.tween_property(timer_label, "modulate", Color.WHITE, 0.4)

# --- NEW: Terrain Handling ---
func apply_sand_effect(is_entering: bool):
	if is_entering:
		active_sand_zones += 1
	else:
		active_sand_zones -= 1
		# Safety net to ensure it never goes below 0
		active_sand_zones = max(0, active_sand_zones) 

	if active_sand_zones > 0:
		# SLUDGE MODE: Lower speed, lower acceleration, high friction
		max_speed = original_max_speed * 0.4
		acceleration = original_acceleration * 0.6
		friction = original_friction * 2.0
	else:
		# BACK ON THE ROAD: Restore original stats
		max_speed = original_max_speed
		acceleration = original_acceleration
		friction = original_friction
