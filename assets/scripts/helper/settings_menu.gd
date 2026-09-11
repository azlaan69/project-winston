extends CanvasLayer

func _ready() -> void:
	self.hide()
	$Control/VBoxContainer/Resolution/OptionButton.select(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	visible = paused
	
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_sens_slider_value_changed(value: float) -> void:
	Settings.sens = value


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		2:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		3:
			DisplayServer.window_set_size(Vector2i(2560, 1440))


func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
