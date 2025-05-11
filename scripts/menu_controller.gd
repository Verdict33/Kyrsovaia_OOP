extends Control

var display_resolution : Vector2i = DisplayServer.screen_get_size()

@onready var main_container = get_node("%MainContainer")
@onready var Extra_popup = $Extra_popup
@onready var Extra_label = $Extra_popup/Extra_label
@onready var Extra_button = $MainContainer/Extra_button

func _ready():
	Extra_button.pressed.connect(_on_extra_button_pressed)

func _on_extra_button_pressed():
	Extra_popup.popup_centered()

func _first_time() -> void:
	DisplayServer.window_set_size(DisplayServer.screen_get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scene/world.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
