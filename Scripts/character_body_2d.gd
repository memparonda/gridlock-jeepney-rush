extends CharacterBody2D

@export var max_speed: float = 350.0
@export var acceleration: float = 450.0
@export var friction: float = 400.0

@onready var vehicle_bump: AudioStreamPlayer2D = $VehicleCrash
@onready var path_follow = get_parent()

var current_speed = 0.0
var crashed = false
var current_light = null
var stopped_by_light := false

# --- THE ONLY NEW VARIABLES ---
var scan_timer: float = 0.0
var cached_distance: float = INF

func _ready():
	# Randomize the first scan so all 35 cars don't scan on frame 1
	scan_timer = randf() * 0.2

func play_vehicle_bump():
	vehicle_bump.play()

# 🚗 YOUR EXACT ORIGINAL FUNCTION
func get_car_ahead():
	var my_progress = path_follow.progress
	var closest_distance = INF
	var closest_pf = null

	for pf in path_follow.get_parent().get_children():
		if pf == path_follow:
			continue
		
		if pf is PathFollow2D:
			var distance = pf.progress - my_progress
			
			if distance > 0 and distance < closest_distance:
				closest_distance = distance
				closest_pf = pf

	return {
		"distance": closest_distance,
		"pf": closest_pf
	}

func _physics_process(delta):

	# 💥 If crashed → stop everything
	if crashed:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		rotation += velocity.length() * 0.001
		return

	# 🎯 Move along path
	path_follow.progress += current_speed * delta

	var target_pos = path_follow.global_position
	var direction = (target_pos - global_position).normalized()

	# 🌀 Turn slowdown
	var angle_diff = abs(wrapf(direction.angle() - rotation, -PI, PI))
	var turn_factor = clamp(angle_diff, 0.5, 2.0)
	var target_speed = max_speed / turn_factor
	
	# --- OPTIMIZED STAGGERED POLLING ---
	scan_timer -= delta
	if scan_timer <= 0:
		var data = get_car_ahead()
		cached_distance = data["distance"]
		# Reset timer to check a few times a second
		scan_timer = 0.15 + (randf() * 0.05) 
		
	var distance = cached_distance

	# 🚗 PATH-BASED FOLLOWING
	var safe_distance = 200.0
	var stop_distance = 90.0

	if distance < stop_distance:
		# 🛑 FULL STOP
		target_speed = 0

	elif distance < safe_distance:
		# 🚗 Smooth slowdown
		var t = (distance - stop_distance) / (safe_distance - stop_distance)
		t = clamp(t, 0.0, 1.0)
		target_speed *= t  

	stopped_by_light = false
	if current_light:
		if current_light.current_state == current_light.LightState.RED:
			stopped_by_light = true

	# 🚦 Traffic light override
	if stopped_by_light:
		target_speed = 0

	# 🚨 OPTIONAL: emergency brake
	$RayCast2D.target_position = Vector2(120, 0).rotated(rotation)

	if $RayCast2D.is_colliding():
		var collider = $RayCast2D.get_collider()

		if collider.is_in_group("npc") or collider.is_in_group("Player"):
			target_speed *= 0.1

	# ⚡ Smooth acceleration / braking
	var speed_diff = target_speed - current_speed

	if speed_diff > 0:
		current_speed += acceleration * delta
	else:
		var brake_strength = 4.0
		current_speed += speed_diff * brake_strength * delta

	current_speed = clamp(current_speed, 0, max_speed)

	velocity = direction * current_speed
	
	# 💥 Collision handling
	var collision = move_and_collide(velocity * delta)

	if collision:
		crashed = true
		play_vehicle_bump()
		current_speed = 0
		velocity = -velocity * 0.3
		print("CRASHED INTO:", collision.get_collider().name)
		return

	# 🚗 Smooth rotation
	if velocity.length() > 5:
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, 3.0 * delta)
	
	# 🛑 Stop when game ends
	if GameManager.game_over:
		velocity = Vector2.ZERO
		current_speed = 0
		return
