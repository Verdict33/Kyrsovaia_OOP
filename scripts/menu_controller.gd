extends Control  # Наследуемся от класса Control для создания пользовательского интерфейса

# Связываем узлы с помощью @onready. Эти узлы будут найдены и инициализированы при запуске сцены.
@onready var main_container = get_node("%MainContainer")  # Находим узел MainContainer
@onready var Extra_popup = $Extra_popup  # Находим узел Extra_popup
@onready var Extra_label = $Extra_popup/Extra_label  # Находим дочерний узел Extra_label внутри Extra_popup
@onready var Extra_button = $MainContainer/Extra_button  # Находим дочерний узел Extra_button внутри MainContainer

# Функция, вызываемая, когда сцена готова (она вызывается один раз при загрузке сцены)
func _ready():
	Extra_button.pressed.connect(_on_extra_button_pressed)  # Подключаем сигнал нажатия кнопки Extra_button к функции _on_extra_button_pressed

# Функция, которая вызывается при нажатии на Extra_button
func _on_extra_button_pressed():
	Extra_popup.popup_centered()  # Открывает всплывающее окно Extra_popup по центру экрана

# Функция для настройки окна приложения при первом запуске
func _first_time() -> void:
	DisplayServer.window_set_size(DisplayServer.screen_get_size())  # Устанавливаем размер окна в размер экрана
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)  # Устанавливаем режим окна на развернутый (максимизированный)

# Функция для обработки нажатия кнопки "Start"
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scene/world.tscn")  # Меняем текущую сцену на новую сцену по пути "res://scene/world.tscn"

# Функция для обработки нажатия кнопки "Exit"
func _on_exit_button_pressed():
	get_tree().quit()  # Закрывает приложение
