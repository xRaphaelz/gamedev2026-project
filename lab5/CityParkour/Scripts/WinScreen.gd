extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Panel/VBox/MenuButton.text = "เล่นอีกครั้ง (ด่าน 1)"
	$Panel/VBox/MenuButton.pressed.connect(func(): GameManager.goto_level(0))
	$Panel/VBox/MenuButton.grab_focus()
