extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Panel/VBox/PlayButton.pressed.connect(func(): GameManager.goto_level(0))
	$Panel/VBox/Level2Button.pressed.connect(func(): GameManager.goto_level(1))
	$Panel/VBox/QuitButton.pressed.connect(func(): get_tree().quit())
	$Panel/VBox/PlayButton.grab_focus()
	if OS.has_feature("web"):
		$Panel/VBox/QuitButton.visible = false
