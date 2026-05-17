extends CanvasLayer

# Grab both pages
@onready var page_1 = $TutorialOverlay
@onready var page_2 = $TutorialOverlay2
@onready var page_3 = $TutorialOverlay3

func _ready():
	# 1. Check if they already saw it
	if GameManager.tutorial_shown:
		hide()
		queue_free()
		return
		
	GameManager.tutorial_shown = true

	# 2. Lock the pause menu and freeze the game
	GameManager.can_pause = false
	get_tree().paused = true
	
	# 3. Setup initial visibility (Page 1 visible, Page 2 invisible)
	page_1.modulate.a = 1.0
	page_2.modulate.a = 0.0
	page_3.modulate.a = 0.0
	page_1.show()
	page_2.show()
	page_3.show()
	show()
	
	# Hide the HUD if it exists
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HUD"):
		player.get_node("HUD").visible = false

	# 4. Start the Sequence!
	play_tutorial_sequence()

func play_tutorial_sequence():
	var tween = create_tween()
	
	# --- PAGE 1 ---
	# Hold Page 1 on screen for 3 seconds
	tween.tween_interval(3.0)
	# Fade Page 1 OUT (Takes 0.5 seconds)
	tween.tween_property(page_1, "modulate:a", 0.0, 0.5)
	
	# --- PAGE 2 ---
	# Fade Page 2 IN (Takes 0.5 seconds)
	tween.tween_property(page_2, "modulate:a", 1.0, 0.5)
	# Hold Page 2 on screen for 3 seconds
	tween.tween_interval(3.0)
	# Fade Page 2 OUT (Takes 0.5 seconds)
	tween.tween_property(page_2, "modulate:a", 0.0, 0.5)
	
		# --- PAGE 3 ---
	# Fade Page 3 IN (Takes 0.5 seconds)
	tween.tween_property(page_3, "modulate:a", 1.0, 0.5)
	# Hold Page 3 on screen for 3 seconds
	tween.tween_interval(3.0)
	# Fade Page 3 OUT (Takes 0.5 seconds)
	tween.tween_property(page_3, "modulate:a", 0.0, 0.5)
	
	# Wait for the entire sequence to finish
	await tween.finished
	
	# --- FINISH & CLEANUP ---
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HUD"):
		player.get_node("HUD").visible = true
		
	get_tree().paused = false
	GameManager.can_pause = true
	
	hide()
	queue_free()
