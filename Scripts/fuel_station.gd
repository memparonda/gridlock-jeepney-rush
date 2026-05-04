extends Area2D

func _ready():
	# Connect BOTH signals through code
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player") and body.has_method("start_refueling"):
		body.start_refueling()

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player") and body.has_method("stop_refueling"):
		body.stop_refueling()
