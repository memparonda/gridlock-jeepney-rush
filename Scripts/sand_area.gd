extends Area2D

func _on_body_entered(body):
	# Make sure it's the Jeepney, not an NPC or passenger!
	if body.is_in_group("Player"):
		# Tell the Jeepney it entered the sand
		if body.has_method("apply_sand_effect"):
			body.apply_sand_effect(true)
			print("Jeepney entered sand trap!")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		# Tell the Jeepney it left the sand
		if body.has_method("apply_sand_effect"):
			body.apply_sand_effect(false)
			print("Jeepney left sand trap!")
