class_name Unit
extends Node2D

@onready var tile_map = get_node("/root/world/TileMap")

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var SPEED = 100

func _ready() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walking") == false:
				astar_grid.set_point_solid(tile_position)


func _input(event) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		GameManager.select_unit(self)

func try_move_to(target_cell: Vector2i) -> void:
	var start_cell = tile_map.local_to_map(global_position)
	
	var occupied = GameManager.get_occupied_cells(self)
	
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)
	
	var id_path = astar_grid.get_id_path(start_cell, target_cell)
	
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	if id_path.is_empty():
		print("Путь не найден")
		return
	
	current_id_path = id_path
	is_moving = false
