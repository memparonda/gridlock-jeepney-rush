extends CanvasLayer

@onready var background = $LoadingRect
@onready var progress_bar = $ProgressBar

var next_scene_path: String = "res://Scenes/Track/track.tscn"
var is_loading: bool = false

func _ready():
	# Start completely invisible so it doesn't block the screen when the game boots
	background.modulate.a = 0
	progress_bar.visible = false
	hide()

func transition_to_scene(path: String):
	next_scene_path = path
	show()
	progress_bar.value = 0
	progress_bar.visible = true
	
	# 1. FADE IN: Tween the background alpha to 1.0 (fully visible) over 0.5 seconds
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# 2. Start the background loading process
	ResourceLoader.load_threaded_request(next_scene_path)
	is_loading = true

func _process(_delta):
	# Don't do anything if we aren't actively loading
	if not is_loading:
		return

	var progress_array = []
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress_array)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		progress_bar.value = progress_array[0] * 100

	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loading = false
		progress_bar.value = 100
		
		# Optional: Wait a tiny fraction of a second so the player actually sees the bar hit 100%
		await get_tree().create_timer(0.2).timeout
		
		# 3. Swap the scene behind the black screen!
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
		
		# 4. FADE OUT: Tween the background alpha back to 0.0 over 0.5 seconds
		progress_bar.visible = false
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(background, "modulate:a", 0.0, 0.5)
		await fade_out_tween.finished
		
		hide()
