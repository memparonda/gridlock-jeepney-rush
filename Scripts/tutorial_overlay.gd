extends Control # Change this if your root node is a Panel, TextureRect, etc.

func _ready():
	
	# --- NEW: Check if we already saw the tutorial ---
	if GameManager.tutorial_shown:
		hide()         # Make sure it's invisible
		queue_free()   # Delete the overlay entirely from the scene
		return         # CRITICAL: Stop reading the rest of this function!
	
	# If we made it here, it means we haven't seen it yet! Mark it as seen:
	GameManager.tutorial_shown = true
	# ----

	# 1. Instantly pause the entire game the moment the level loads
	get_tree().paused = true
	
	# Ensure the overlay is fully visible to start
	modulate.a = 1.0
	show()
	
	# --- NEW: Find the player and hide their HUD ---
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HUD"):
		player.get_node("HUD").visible = false
	# -----------------------------------------------

	# 2. Create a Tween to handle the timer and the fade animation
	var tween = create_tween()
	
	# 3. Step One of Tween: Wait for exactly 2.0 seconds
	tween.tween_interval(2.0)
	
	# 4. Step Two of Tween: Fade the alpha (modulate:a) to 0.0 over 0.5 seconds
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# 5. Wait for the entire Tween sequence (wait + fade) to finish completely
	await tween.finished
	
	# 6. Unpause the game and let the Jeepney drive!
	get_tree().paused = false
	
	# --- NEW: Show the HUD again when the tutorial ends ---
	if player and player.has_node("HUD"):
		player.get_node("HUD").visible = true
	# ------------------------------------------------------
	
	# 7. Hide the overlay so it doesn't block any mouse clicks on the screen
	hide()
	
	# Optional: If this tutorial only happens once per level, you can delete it 
	# from memory completely by uncommenting the line below:
	# queue_free()
