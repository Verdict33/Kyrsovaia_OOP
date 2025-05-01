class_name Unit
extends Node2D

# Ссылка на карту тайлов
@onready var tile_map = get_node("/root/world/TileMap")

# Сетка AStar для построения путей
var astar_grid: AStarGrid2D

# Путь, по которому движется юнит (список клеток)
var current_id_path: Array[Vector2i]

# Целевая позиция в пикселях
var target_position: Vector2

# Флаг, показывающий, сделал ли юнит ход в этом раунде
var has_moved: bool = false

# Скорость перемещения юнита
var SPEED = 100

# Флаг, идет ли сейчас юнит
var is_moving: bool

# Максимальное число клеток, которые юнит может пройти за ход
var max_move_cells: int = 5

func _ready() -> void:
	# Инициализация AStar-сетки
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	# Установка непроходимых клеток по данным из TileMap
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walking") == false:
				astar_grid.set_point_solid(tile_position)

# (Пустой метод на случай ввода — может быть переопределен)
func _input(event) -> void:
	pass

# (Пустой физический процесс — логика движения реализуется в наследнике)
func _physics_process(delta: float) -> void:
	pass

# Обработка клика по юниту — выделяет его через GameManager
func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		GameManager.select_unit(self)

# Попытка перемещения юнита в указанную клетку
func try_move_to(target_cell: Vector2i) -> void:
	if has_moved:
		return

	var start_cell = tile_map.local_to_map(global_position)
	var occupied = GameManager.get_occupied_cells(self)

	# Временно помечаем занятые клетки как непроходимые
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)

	# Получаем путь с учетом препятствий
	var id_path = astar_grid.get_id_path(start_cell, target_cell)

	# Возвращаем доступность клеток обратно
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)

	# Если путь недоступен — выходим
	if id_path.is_empty():
		return

	# Проверка на ограничение по длине хода
	var move_length = id_path.size() - 1
	if move_length > max_move_cells:
		return

	# Устанавливаем путь к цели — юнит начнет движение
	current_id_path = id_path
	is_moving = false

# Получить все клетки, в которые юнит может дойти за ход
func get_reachable_cells() -> Array[Vector2i]:
	var start_cell = tile_map.local_to_map(global_position)
	var reachable: Array[Vector2i] = []
	
	var occupied = GameManager.get_occupied_cells(self)
	# Временно помечаем занятые клетки как непроходимые
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)
	
	# Перебираем все клетки в пределах карты
	var region = astar_grid.region
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var target_cell = Vector2i(x, y)
			if not astar_grid.is_point_solid(target_cell):
				var path = astar_grid.get_id_path(start_cell, target_cell)
				# Добавляем клетку, если путь существует и он в пределах дальности перемещения
				if not path.is_empty() and path.size() - 1 <= max_move_cells:
					reachable.append(target_cell)
	
	# Снимаем временные блокировки
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	return reachable

# Параметры и логика боевки:

var max_health := 1  # Максимальное здоровье
var health := 1      # Текущее здоровье
var attack_power := 3  # Сила атаки

# Получить урон
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

# Удалить юнита при смерти
func die() -> void:
	GameManager.remove_unit(self)
	queue_free()

# Атака другого юнита
func attack(target: Unit) -> void:
	if target:
		target.take_damage(attack_power)

# Проверка, можно ли атаковать указанного юнита (если он рядом)
func can_attack(target: Unit) -> bool:
	var self_cell = tile_map.local_to_map(global_position)
	var target_cell = tile_map.local_to_map(target.global_position)
	return self_cell.distance_to(target_cell) <= 1  # Ближний бой
