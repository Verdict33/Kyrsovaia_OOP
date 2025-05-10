extends Unit_enemy

func _ready() -> void:
	super._ready()
	max_move_cells = 3
	health = 150
	max_health = 150
	attack_power = 75
	attack_dist = 4
