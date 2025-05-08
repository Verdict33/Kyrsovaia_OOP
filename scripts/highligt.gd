extends Node

class_name Highlight

var tile_map: TileMap = null
const HIGHLIGHT_LAYER = 1
const TILESET_ID = 0
const ATLAS_COORDS = Vector2i(2, 23)

const ATTACK_HIGHLIGHT_LAYER = 3
const ATTACK_ATLAS_COORDS = Vector2i(5, 26)
func setup(map: TileMap):
	tile_map = map

func show_movement_range(reachable: Array[Vector2i]):
	if not tile_map:
		return

	clear_highlight()
	for cell in reachable:
		tile_map.set_cell(HIGHLIGHT_LAYER, cell, TILESET_ID, ATLAS_COORDS)

func show_attack_targets(unit: Unit, enemies: Array):
	for enemy in enemies:
		if enemy is Unit and is_instance_valid(enemy) and unit.can_attack(enemy):
			var cell = tile_map.local_to_map(enemy.global_position)
			tile_map.set_cell(ATTACK_HIGHLIGHT_LAYER, cell, TILESET_ID, ATTACK_ATLAS_COORDS)


func clear_highlight():
	if tile_map:
		tile_map.clear_layer(HIGHLIGHT_LAYER)

func clear_attack_highlight():
	if tile_map:
		tile_map.clear_layer(ATTACK_HIGHLIGHT_LAYER)
