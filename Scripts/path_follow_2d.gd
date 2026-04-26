extends PathFollow2D

@export var speed: float = 400.0
func _process(delta):
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		progress_ratio = 0.0
