extends Control
# Please check the documentation about
# Displayserver class : https://docs.godotengine.org/en/stable/classes/class_displayserver.html

#--
# Check out Colorblind addon for godot : https://github.com/paulloz/godot-colorblindness
#--

# Config file
# Move it into a singleton
var settings_file = ConfigFile.new()
#--
var vsync: int = 0
# I'm a Vector3 instead of 3 var float
# - x : General , y : Music , z : SFX
var audio: Vector3 = Vector3(70.0, 70.0, 70.0)
var display_resolution : Vector2i = DisplayServer.screen_get_size()


@onready var resolution_option_button = get_node("%Resolution_Optionbutton")
@onready var Extra_container = get_node("%ExtraContainer")
@onready var main_container = get_node("%MainContainer")




func _get_resolution(index) -> Vector2i:
	var resolution_arr = resolution_option_button.get_item_text(index).split("x")
	return Vector2i(int(resolution_arr[0]), int(resolution_arr[1]))


func _check_resolution(resolution: Vector2i):
	for i in resolution_option_button.get_item_count():
		if _get_resolution(i) == resolution:
			return i


func _first_time() -> void:
	DisplayServer.window_set_size(DisplayServer.screen_get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_vsync_mode(vsync)
	resolution_option_button.select(_check_resolution(DisplayServer.screen_get_size()))




func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scene/world.tscn")


func _on_exit_button_pressed():
	get_tree().quit()
