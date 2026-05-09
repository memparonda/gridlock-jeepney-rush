extends Area2D

@export var traffic_light: Node2D

var player_inside := false
var player_ref = null
var penalty_applied := false

func _on_body_entered(body):
	if body.name == "Car":
		print("[Player Traffic Light] Entered:", body.name)
		player_inside = true
		player_ref = body
		penalty_applied = false  # reset when entering

func _on_body_exited(body):
	if body.name == "Car":
		player_inside = false
		player_ref = null
		penalty_applied = false

func _process(_delta):
	if not player_inside or not player_ref:
		return

	# 🚦 Check light state continuously
	if traffic_light.current_state == traffic_light.LightState.RED:
	
		# 🚗 Only penalize if player is MOVING
		if player_ref.velocity.length() > 10:
		
			# Apply penalty ONLY once per entry
			if not penalty_applied:
				player_ref.current_time -= 10
				print("🚨 Ran a red light! -10 seconds")
				penalty_applied = true
				# --- NEW: Trigger the UI Flash! ---
				if player_ref.has_method("flash_timer_red"):
					player_ref.flash_timer_red()
				# ----------------------------------
