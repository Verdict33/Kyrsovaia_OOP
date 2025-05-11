class_name Unit
extends Node2D

@onready var tile_map = get_node("/root/world/TileMap")
@onready var game_manager = get_node("/root/world/GameManager")

var astar_grid: AStarGrid2D  # Сетка A* для поиска пути
var current_id_path: Array[Vector2i]  # Текущий путь юнита
var target_position: Vector2  # Целевая позиция в мировых координатах
var has_moved: bool = false  # Флаг, перемещался ли юнит в этом ходу
var SPEED = 100  # Скорость перемещения юнита
var is_moving: bool  # Флаг, двигается ли юнит в данный момент
var max_move_cells: int = 5  # Дильность передвижения юнита


# Создание игрового поля
func _ready() -> void:
	astar_grid = AStarGrid2D.new()
	
	# Регион, в котором работает A*
	astar_grid.region = tile_map.get_used_rect()
	
	astar_grid.cell_size = Vector2(16, 16)
	
	# Запрет на диагональное перемещение
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	# Применяем параметры и инициализируем сетку
	astar_grid.update()
	
	# Вычисляем абсолютную позицию клетки
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			# Данные о тайле на данном слое и позиции
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			# Если данные отсутствуют или тайл помечен как непроходимый, то он недоступен для перемещения
			if tile_data == null or tile_data.get_custom_data("walking") == false:
				astar_grid.set_point_solid(tile_position)
				

@onready var ray_cast_2d = $RayCast2D


# Функцция годота для вызова передвижения
func _physics_process(delta: float) -> void:
	if current_id_path.is_empty():
		return
	
	if has_moved:
		return
	
	var next_cell = current_id_path.front()
	
	var current_cell = tile_map.local_to_map(global_position)
	
	var direction = next_cell - current_cell
	
	# Обновляем RayCast2D для проверки столкновений в направлении движения
	ray_cast_2d.target_position = Vector2(direction.x, direction.y) * 16
	ray_cast_2d.force_raycast_update()
	
	# Если на пути препятствие, то останавливаем движение
	if ray_cast_2d.is_colliding():
		return
	
	check_for_traps()
	
	# Юнит мог быть уничтожен ловушкой
	if not is_instance_valid(self):
		return
	
	# Если юнит не начал движение, то задаём цель
	if not is_moving:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	
	global_position = global_position.move_toward(target_position, SPEED * delta)
	
	# Если юнит достиг следующей клетки
	if global_position == target_position:
		current_id_path.pop_front()
		
		# Если путь завершён
		if current_id_path.is_empty():
			is_moving = false
			has_moved = true

			# Для выбранного игроком юнита обновляется подсветка атаки
			if game_manager.selected_unit == self:
				Highligt.clear_attack_highlight()
				Highligt.show_attack_targets(self, get_node("/root/world/Enemys").get_children())
			
			Highligt.clear_highlight()
			
			if GameManager.all_units_moved():
				GameManager.end_player_turn()
		else:
			target_position = tile_map.map_to_local(current_id_path.front())


# Выстраивает путь для юнита
func try_move_to(target_cell: Vector2i) -> void:
	if has_moved:
		return
	
	var start_cell = tile_map.local_to_map(global_position)
	
	var occupied = GameManager.get_occupied_cells(self)
	
	# Отмечаем занятые клетки как непроходимые для расчёта пути
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)
	
	var id_path = astar_grid.get_id_path(start_cell, target_cell)
	
	# После построения пути снимаем отметки занятости клеток
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	if id_path.is_empty():
		return
	
	# Проверка, не превышает ли путь дальность хода
	var move_length = id_path.size() - 1  # Исключаем начальную клетку
	if move_length > max_move_cells:
		return
	
	current_id_path = id_path
	is_moving = false 


# Функция для определения клеток, в которые можно идти (нужна для подсветки хода)
func get_reachable_cells() -> Array[Vector2i]:
	var start_cell = tile_map.local_to_map(global_position)
	
	var reachable: Array[Vector2i] = []
	
	# Все занятые клетки, кроме текущего юнита
	var occupied = GameManager.get_occupied_cells(self)
	
	# Отмечаем занятые клетки как непроходимые
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)
	
	# Проходим по всем клеткам в пределах области действия
	var region = astar_grid.region
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var target_cell = Vector2i(x, y)
			
			# Пытаемся найти путь к клетке, если она проходима
			if not astar_grid.is_point_solid(target_cell):
				var path = astar_grid.get_id_path(start_cell, target_cell)
				
				# Если путь существует и его длина допустима, то добавляем в список
				if not path.is_empty() and path.size() - 1 <= max_move_cells:
					reachable.append(target_cell)
	
	# Снимаем запреты с сетки
	for cell in occupied:
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	return reachable


var max_health = 10
var health = 10
var attack_power = 3
var attack_dist = 1


# Получение урона
func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()
		GameManager.check_game_over()


# Удаление мертвого юнита с поля
func die():
	if is_inside_tree():
		get_node("/root/world/GameManager").remove_unit(self)
	queue_free()


# Нанесение урона
func attack(target: Unit) -> void:
	if target:
		target.take_damage(attack_power)


# Проверка на возможность атаковать
func can_attack(target: Unit) -> bool:
	var self_cell = tile_map.local_to_map(global_position)
	var target_cell = tile_map.local_to_map(target.global_position)
	return self_cell.distance_to(target_cell) <= attack_dist 


# Проверка на попадание юнита в ловушку
func check_for_traps():
	var traps = get_node("/root/world/Traps").get_children()
	for trap in traps:
		if trap is Trap:
			trap.check_trigger(self)
