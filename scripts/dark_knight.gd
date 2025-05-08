extends Unit_enemy

func _ready() -> void:
	super._ready()
	max_move_cells = 10
	health = 1
	attack_power = 500
	attack_dist = 3
