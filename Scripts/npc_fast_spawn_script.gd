extends Path2D

@export var npc_pool := [
	{"scene": preload("res://Scenes/Npc/character_body_2d.tscn"), "weight": 20},
	{"scene": preload("res://Scenes/Npc/npc_fast.tscn"), "weight": 20},
	{"scene": preload("res://Scenes/Npc/npc_taxi.tscn"), "weight": 20},
	{"scene": preload("res://Scenes/Npc/npc_pickup.tscn"), "weight": 20},
		{"scene": preload("res://Scenes/Npc/npc_truck.tscn"), "weight": 4},
	{"scene": preload("res://Scenes/Npc/npc_bus.tscn"), "weight": 4},
	{"scene": preload("res://Scenes/Npc/npc_police_1.tscn"), "weight": 2}
]

func get_weighted_scene():
	var total_weight = 0
	for item in npc_pool:
		total_weight += item.weight
	
	var roll = randf() * total_weight
	
	for item in npc_pool:
		roll -= item.weight
		if roll <= 0:
			return item.scene
	
	return npc_pool[0].scene

func spawn_npc(offset: float):
	if npc_pool.is_empty():
		return
	
	var npc_scene = get_weighted_scene()
	
	var path_follow = PathFollow2D.new()
	
	var path_length = curve.get_baked_length()
	path_follow.progress = fposmod(offset, path_length)  # ✅ wraps properly
	
	add_child(path_follow)
	
	var npc = npc_scene.instantiate()
	path_follow.add_child(npc)
	print("Spawned at:", path_follow.progress)

func _ready():
	var path_length = curve.get_baked_length()
	var spacing = path_length / 25.0  # evenly distribute. MUST BE SAME VALUE AS i IN RANGE!
	
	for i in range(25): # MUST BE SAME VALUE AS SPACING!
		var offset = i * spacing
		spawn_npc(offset)
