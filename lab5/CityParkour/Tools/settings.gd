extends SceneTree
var _done := false
func _process(_d: float) -> bool:
	if _done: return true
	_done = true
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_R
	ProjectSettings.set_setting("input/restart", {"deadzone": 0.5, "events": [ev]})
	ProjectSettings.set_setting("application/config/name", "City Parkour - First 3D Game")
	ProjectSettings.set_setting("application/config/description", "แบบฝึกหัดที่ 5: First 3D Game - เกม 3D platformer ธีมเมือง 2 ด่าน สร้างด้วย Godot 4.7.2")
	ProjectSettings.set_setting("run/main_scene", "res://Scenes/UI/MainMenu.tscn")
	ProjectSettings.set_setting("display/window/size/always_on_top", false)
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.web", "gl_compatibility")
	var err := ProjectSettings.save()
	print("settings saved err=", err)
	return true
