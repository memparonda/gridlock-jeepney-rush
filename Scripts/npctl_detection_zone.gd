extends Area2D

@export var traffic_light_npc: Node2D

func _on_body_entered(body):
	if body.is_in_group("npc"):
		print("[NPC Traffic Light] Entered:", body.name)
		body.current_light = traffic_light_npc

func _on_body_exited(body):
	if body.is_in_group("npc"):
		body.current_light = null
