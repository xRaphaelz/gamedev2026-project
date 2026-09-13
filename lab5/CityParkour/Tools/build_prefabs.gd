extends SceneTree
const GameBuilder = preload("res://Tools/Builder.gd")

var b: GameBuilder
var _done := false

const FONT_R := "res://Assets/Fonts/Sarabun-Regular.ttf"
const FONT_B := "res://Assets/Fonts/Sarabun-Bold.ttf"


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	b = GameBuilder.new(null)
	build_player()
	build_door()
	build_spinner()
	build_crusher()
	build_moving_platform()
	build_checkpoint()
	build_hud()
	build_main_menu()
	build_win_screen()
	return true


func _new_root(node: Node, node_name: String) -> Node:
	node.name = node_name
	b.root = node
	return node


# ------------------------------------------------------------------ PLAYER

func build_player() -> void:
	var player := CharacterBody3D.new()
	_new_root(player, "Player")
	player.set_script(load("res://Scripts/Player.gd"))
	player.add_to_group("Player", true)
	player.floor_snap_length = 0.4

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.33
	cap.height = 1.35
	cs.shape = cap
	cs.position = Vector3(0, 0.675, 0)
	player.add_child(cs)

	var model: Node3D = load("res://Assets/Character/AnimatedWoman.fbx").instantiate()
	model.name = "Model"
	model.scale = Vector3.ONE * 0.26
	player.add_child(model)

	var gimbal := Node3D.new()
	gimbal.name = "Gimbal"
	gimbal.position = Vector3(0, 1, 0)
	gimbal.set_script(load("res://Scripts/CameraMovement.gd"))
	player.add_child(gimbal)
	gimbal.unique_name_in_owner = true

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.position = Vector3(0, 2.2, 5.5)
	cam.rotation_degrees = Vector3(-15, 0, 0)
	cam.fov = 70.0
	gimbal.add_child(cam)

	var trail := CPUParticles3D.new()
	trail.name = "ParticleTrail"
	trail.amount = 30
	trail.mesh = load("res://Assets/Resources/cloud.res")
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.2
	trail.particle_flag_align_y = true
	trail.direction = Vector3.ZERO
	trail.gravity = Vector3(0, 0.1, 0)
	trail.scale_amount_min = 0.6
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.24, 1))
	curve.add_point(Vector2(1, 0))
	trail.scale_amount_curve = curve
	var pm := StandardMaterial3D.new()
	pm.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	pm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	pm.albedo_color = Color(0.9, 0.93, 1.0)
	trail.material_override = pm
	trail.emitting = false
	player.add_child(trail)

	var steps := AudioStreamPlayer3D.new()
	steps.name = "Footsteps"
	steps.stream = load("res://Assets/Audio/SFX/walking.ogg")
	steps.pitch_scale = 0.9
	steps.autoplay = true
	player.add_child(steps)

	b.save(player, "res://Scenes/Player.tscn")
	player.free()


# -------------------------------------------------------------------- DOOR

func build_door() -> void:
	var door := Area3D.new()
	_new_root(door, "Door")
	door.set_script(load("res://Scripts/Door.gd"))
	door.monitoring = true

	var frame_mat := GameBuilder.mat(Color(0.16, 0.17, 0.22), 0.6, 0.3)
	var glow_mat := GameBuilder.mat(Color(0.2, 0.9, 0.5), 0.4, 0.0, Color(0.15, 0.8, 0.4))

	# frame
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post%s" % ("L" if side < 0 else "R")
		var bm := BoxMesh.new()
		bm.size = Vector3(0.35, 3.4, 0.4)
		post.mesh = bm
		post.material_override = frame_mat
		post.position = Vector3(1.3 * side, 1.7, 0)
		door.add_child(post)

	var lintel := MeshInstance3D.new()
	lintel.name = "Lintel"
	var lm := BoxMesh.new()
	lm.size = Vector3(3.0, 0.45, 0.4)
	lintel.mesh = lm
	lintel.material_override = frame_mat
	lintel.position = Vector3(0, 3.6, 0)
	door.add_child(lintel)

	var portal := MeshInstance3D.new()
	portal.name = "Portal"
	var qm := QuadMesh.new()
	qm.size = Vector2(2.3, 3.3)
	portal.mesh = qm
	portal.material_override = glow_mat
	portal.position = Vector3(0, 1.7, 0)
	door.add_child(portal)

	var cs := CollisionShape3D.new()
	cs.name = "Area"
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.2, 1.2)
	cs.shape = box
	cs.position = Vector3(0, 1.6, 0)
	door.add_child(cs)

	# blocks the way while the door is locked
	var barrier := StaticBody3D.new()
	barrier.name = "Barrier"
	door.add_child(barrier)
	var bcs := CollisionShape3D.new()
	bcs.name = "Shape"
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(2.6, 3.4, 0.4)
	bcs.shape = bbox
	bcs.position = Vector3(0, 1.7, 0)
	barrier.add_child(bcs)

	var light := OmniLight3D.new()
	light.name = "LockLight"
	light.light_color = Color(1, 0.35, 0.35)
	light.light_energy = 3.0
	light.omni_range = 9.0
	light.position = Vector3(0, 2.0, 0.6)
	door.add_child(light)

	var label := Label3D.new()
	label.name = "Label"
	label.text = "0 / 0"
	label.font = load(FONT_B)
	label.font_size = 96
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 4.2, 0)
	door.add_child(label)

	b.save(door, "res://Scenes/Props/Door.tscn")
	door.free()


# ----------------------------------------------------------------- SPINNER

func build_spinner() -> void:
	var spinner := Node3D.new()
	_new_root(spinner, "Spinner")
	spinner.set_script(load("res://Scripts/Spinner.gd"))

	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16
	cm.bottom_radius = 0.24
	cm.height = 1.0
	pole.mesh = cm
	pole.material_override = GameBuilder.mat(Color(0.25, 0.26, 0.3), 0.5, 0.5)
	pole.position = Vector3(0, 0.5, 0)
	spinner.add_child(pole)

	var hazard_mat := GameBuilder.mat(Color(0.95, 0.25, 0.2), 0.5, 0.1, Color(0.5, 0.05, 0.03))

	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var am := BoxMesh.new()
	am.size = Vector3(5.4, 0.4, 0.4)
	arm.mesh = am
	arm.material_override = hazard_mat
	arm.position = Vector3(0, 0.55, 0)
	spinner.add_child(arm)

	for side in [-1.0, 1.0]:
		var tip := MeshInstance3D.new()
		tip.name = "Tip%s" % ("L" if side < 0 else "R")
		var tm := BoxMesh.new()
		tm.size = Vector3(0.9, 0.5, 0.5)
		tip.mesh = tm
		tip.material_override = GameBuilder.mat(Color(0.98, 0.85, 0.2), 0.5, 0.0, Color(0.5, 0.4, 0.05))
		tip.position = Vector3(2.4 * side, 0.55, 0)
		spinner.add_child(tip)

	var hazard := Area3D.new()
	hazard.name = "Hazard"
	hazard.set_script(load("res://Scripts/Hazard.gd"))
	spinner.add_child(hazard)
	var hcs := CollisionShape3D.new()
	hcs.name = "Shape"
	var hbox := BoxShape3D.new()
	hbox.size = Vector3(5.4, 0.7, 0.6)
	hcs.shape = hbox
	hcs.position = Vector3(0, 0.55, 0)
	hazard.add_child(hcs)

	b.save(spinner, "res://Scenes/Props/Spinner.tscn")
	spinner.free()


# ----------------------------------------------------------------- CRUSHER

func build_crusher() -> void:
	var crusher := AnimatableBody3D.new()
	_new_root(crusher, "Crusher")
	crusher.set_script(load("res://Scripts/Crusher.gd"))

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 2.0, 2.4)
	mi.mesh = bm
	mi.material_override = GameBuilder.mat(Color(0.35, 0.36, 0.4), 0.6, 0.4)
	crusher.add_child(mi)

	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	cs.shape = box
	crusher.add_child(cs)

	var spikes := MeshInstance3D.new()
	spikes.name = "Spikes"
	var sm := BoxMesh.new()
	sm.size = Vector3(2.5, 0.25, 2.5)
	spikes.mesh = sm
	spikes.material_override = GameBuilder.mat(Color(0.95, 0.25, 0.2), 0.5, 0.1, Color(0.5, 0.05, 0.03))
	spikes.position = Vector3(0, -1.05, 0)
	crusher.add_child(spikes)

	var hazard := Area3D.new()
	hazard.name = "Hazard"
	hazard.set_script(load("res://Scripts/Hazard.gd"))
	crusher.add_child(hazard)
	var hcs := CollisionShape3D.new()
	hcs.name = "Shape"
	var hbox := BoxShape3D.new()
	hbox.size = Vector3(2.5, 0.5, 2.5)
	hcs.shape = hbox
	hcs.position = Vector3(0, -1.1, 0)
	hazard.add_child(hcs)

	b.save(crusher, "res://Scenes/Props/Crusher.tscn")
	crusher.free()


# --------------------------------------------------------- MOVING PLATFORM

func build_moving_platform() -> void:
	var plat := AnimatableBody3D.new()
	_new_root(plat, "MovingPlatform")
	plat.set_script(load("res://Scripts/MovingPlatform.gd"))

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(3.6, 0.5, 3.6)
	mi.mesh = bm
	mi.material_override = GameBuilder.mat(Color(0.98, 0.66, 0.18), 0.7, 0.15)
	plat.add_child(mi)

	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(3.6, 0.5, 3.6)
	cs.shape = box
	plat.add_child(cs)

	b.save(plat, "res://Scenes/Props/MovingPlatform.tscn")
	plat.free()


# -------------------------------------------------------------- CHECKPOINT

func build_checkpoint() -> void:
	var cp := Area3D.new()
	_new_root(cp, "Checkpoint")
	cp.set_script(load("res://Scripts/Checkpoint.gd"))

	var flag: Node3D = load("res://Assets/Models/flag.glb").instantiate()
	flag.name = "Flag"
	flag.scale = Vector3.ONE * 1.4
	cp.add_child(flag)

	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.4, 2.0)
	cs.shape = box
	cs.position = Vector3(0, 1.2, 0)
	cp.add_child(cs)

	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.8, 0.35)
	light.light_energy = 1.6
	light.omni_range = 5.0
	light.position = Vector3(0, 1.6, 0)
	cp.add_child(light)

	b.save(cp, "res://Scenes/Props/Checkpoint.tscn")
	cp.free()


# --------------------------------------------------------------------- HUD

func _label(parent: Node, node_name: String, text: String, pos: Vector2, size_px: int, color: Color, bold := true) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", load(FONT_B if bold else FONT_R))
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.09, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	parent.add_child(l)
	return l


func build_hud() -> void:
	var layer := CanvasLayer.new()
	_new_root(layer, "GameHUD")

	var ui := Control.new()
	ui.name = "GameUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_script(load("res://Scripts/GameUI.gd"))
	layer.add_child(ui)

	var coin_icon := TextureRect.new()
	coin_icon.name = "CoinTexture"
	coin_icon.texture = load("res://Assets/Textures/coin.png")
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.custom_minimum_size = Vector2(52, 52)
	coin_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	coin_icon.offset_left = 28
	coin_icon.offset_top = 26
	coin_icon.offset_right = 80
	coin_icon.offset_bottom = 78
	ui.add_child(coin_icon)

	_label(ui, "CoinsLabel", "0 / 0", Vector2(92, 28), 40, Color(0.996, 0.711, 0.261))
	var hearts := HBoxContainer.new()
	hearts.name = "Hearts"
	hearts.position = Vector2(28, 84)
	hearts.add_theme_constant_override("separation", 6)
	ui.add_child(hearts)
	for i in 3:
		var h := TextureRect.new()
		h.name = "Heart%d" % (i + 1)
		h.texture = load("res://Assets/Textures/heart.svg")
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.custom_minimum_size = Vector2(34, 34)
		hearts.add_child(h)
	_label(ui, "LevelLabel", "Level", Vector2(28, 128), 26, Color(0.85, 0.9, 1.0))
	var hint := _label(ui, "HintLabel",
		"คลิกที่จอเพื่อเริ่มเล่น · WASD = เดิน · SPACE = กระโดด (กดซ้ำ = กระโดดสองชั้น) · R = เริ่มด่านใหม่ · ESC = ปล่อยเมาส์",
		Vector2(28, 166), 19, Color(0.85, 0.89, 0.97), false)
	hint.modulate = Color(1, 1, 1, 0.9)

	b.save(layer, "res://Scenes/UI/GameHUD.tscn")
	layer.free()


# --------------------------------------------------------------- MAIN MENU

func _menu_button(parent: Node, node_name: String, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.custom_minimum_size = Vector2(360, 64)
	btn.add_theme_font_override("font", load(FONT_B))
	btn.add_theme_font_size_override("font_size", 28)
	parent.add_child(btn)
	return btn


func _screen(node_name: String, script_path: String, title: String, subtitle: String) -> Control:
	var ui := Control.new()
	_new_root(ui, node_name)
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.set_script(load(script_path))

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.07, 0.08, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)

	var panel := CenterContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", load(FONT_B))
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(0.996, 0.75, 0.28))
	vbox.add_child(title_label)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", load(FONT_R))
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
	vbox.add_child(sub)

	return ui


func build_main_menu() -> void:
	var ui := _screen("MainMenu", "res://Scripts/MainMenu.gd", "CITY PARKOUR",
		"วิ่ง กระโดด เก็บเหรียญให้ครบ แล้วหาประตูไปด่านถัดไป\nWASD = เดิน · SPACE = กระโดด (กดซ้ำ = Double Jump) · R = เริ่มใหม่")
	var vbox := ui.get_node("Panel/VBox")
	_menu_button(vbox, "PlayButton", "เริ่มเกม (ด่าน 1 - Rooftop Run)")
	_menu_button(vbox, "Level2Button", "ด่าน 2 - Night Street")
	_menu_button(vbox, "QuitButton", "ออกจากเกม")

	var credit := Label.new()
	credit.name = "Credits"
	credit.text = "Starter Kit: 3D Platformer Starter Kit (SD Studios)\nModels: Poly Pizza - City Pack & Animated Woman (Quaternius)\nFont: Sarabun (SIL OFL)"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_override("font", load(FONT_R))
	credit.add_theme_font_size_override("font_size", 16)
	credit.add_theme_color_override("font_color", Color(0.55, 0.6, 0.72))
	vbox.add_child(credit)

	b.save(ui, "res://Scenes/UI/MainMenu.tscn")
	ui.free()


func build_win_screen() -> void:
	var ui := _screen("WinScreen", "res://Scripts/WinScreen.gd", "ผ่านทุกด่านแล้ว!",
		"คุณเก็บไอเท็มครบและไปถึงประตูสุดท้ายได้สำเร็จ")
	var vbox := ui.get_node("Panel/VBox")
	_menu_button(vbox, "MenuButton", "กลับเมนูหลัก")
	b.save(ui, "res://Scenes/UI/WinScreen.tscn")
	ui.free()
