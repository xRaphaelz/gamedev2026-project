extends SceneTree
const GameBuilder = preload("res://Tools/Builder.gd")

var b
var _done := false

const PLAYER := "res://Scenes/Player.tscn"
const COIN := "res://Scenes/Coin.tscn"
const DOOR := "res://Scenes/Props/Door.tscn"
const SPINNER := "res://Scenes/Props/Spinner.tscn"
const CRUSHER := "res://Scenes/Props/Crusher.tscn"
const MOVER := "res://Scenes/Props/MovingPlatform.tscn"
const CHECKPOINT := "res://Scenes/Props/Checkpoint.tscn"
const HUD := "res://Scenes/UI/GameHUD.tscn"

var MAT_ROOF: StandardMaterial3D
var MAT_ROAD: StandardMaterial3D
var MAT_WALK: StandardMaterial3D
var MAT_LEDGE: StandardMaterial3D
var MAT_WOOD: StandardMaterial3D


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	MAT_ROOF = GameBuilder.mat(Color(0.34, 0.35, 0.38), 0.95)
	MAT_ROAD = GameBuilder.mat(Color(0.16, 0.16, 0.19), 0.98)
	MAT_WALK = GameBuilder.mat(Color(0.62, 0.62, 0.6), 0.95)
	MAT_LEDGE = GameBuilder.mat(Color(0.75, 0.73, 0.68), 0.9)
	MAT_WOOD = GameBuilder.mat(Color(0.55, 0.38, 0.24), 0.9)
	build_level1()
	build_level2()
	return true


# ------------------------------------------------------------- scaffolding

func level_root(node_name: String, index: int) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.set_script(load("res://Scripts/Level.gd"))
	root.set("level_index", index)
	b = GameBuilder.new(root)
	return root


func add_sky(root: Node3D, night: bool) -> void:
	var holder := Node3D.new()
	holder.name = "Environment"
	root.add_child(holder)

	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	if night:
		sky_mat.sky_top_color = Color(0.03, 0.04, 0.10)
		sky_mat.sky_horizon_color = Color(0.12, 0.10, 0.18)
		sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.04)
		sky_mat.ground_horizon_color = Color(0.10, 0.09, 0.14)
		sky_mat.sun_angle_max = 12.0
	else:
		sky_mat.sky_top_color = Color(0.13, 0.35, 0.72)
		sky_mat.sky_horizon_color = Color(0.62, 0.76, 0.92)
		sky_mat.ground_bottom_color = Color(0.32, 0.33, 0.36)
		sky_mat.ground_horizon_color = Color(0.72, 0.76, 0.82)
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_energy = 0.4 if night else 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9 if night else 0.78
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.4
	env.glow_enabled = true
	env.glow_intensity = 1.2 if night else 0.6
	env.glow_bloom = 0.25 if night else 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.09, 0.16) if night else Color(0.70, 0.78, 0.88)
	env.fog_density = 0.006 if night else 0.0012
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.14
	env.adjustment_brightness = 0.98

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	holder.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.light_energy = 0.4 if night else 1.35
	sun.light_color = Color(0.55, 0.60, 0.95) if night else Color(1.0, 0.96, 0.88)
	sun.rotation_degrees = Vector3(-52, 128, 0)
	holder.add_child(sun)


func add_common(root: Node3D, spawn_pos: Vector3, dead_center: Vector3, dead_size: Vector3) -> void:
	var player: Node3D = load(PLAYER).instantiate()
	player.name = "Player"
	player.position = spawn_pos
	root.add_child(player)

	var marker := Marker3D.new()
	marker.name = "SpawnPosition"
	marker.position = spawn_pos
	root.add_child(marker)
	root.set("spawn_point_path", NodePath("SpawnPosition"))

	var dead := Area3D.new()
	dead.name = "DeadZone"
	dead.set_script(load("res://Scripts/DeadZone.gd"))
	dead.position = dead_center
	root.add_child(dead)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = dead_size
	cs.shape = box
	dead.add_child(cs)

	var hud: Node = load(HUD).instantiate()
	hud.name = "GameHUD"
	root.add_child(hud)


func coin(parent: Node, pos: Vector3, idx: int) -> void:
	var c: Node3D = load(COIN).instantiate()
	c.name = "Coin%d" % idx
	c.position = pos
	c.scale = Vector3.ONE * 1.3
	parent.add_child(c)


func coin_line(parent: Node, from_pos: Vector3, to_pos: Vector3, count: int, start_idx: int) -> int:
	var idx := start_idx
	for i in count:
		var t := float(i + 1) / float(count + 1)
		coin(parent, from_pos.lerp(to_pos, t), idx)
		idx += 1
	return idx


## Tower + walkable roof deck. Returns the roof height.
func rooftop(parent: Node, node_name: String, center: Vector2, size: Vector2, height: float, key: String, rot := 0.0) -> float:
	var holder := Node3D.new()
	holder.name = node_name
	parent.add_child(holder)

	var deck_thickness := 0.8
	b.slab(holder, "Deck", Vector3(center.x, height, center.y), Vector3(size.x, deck_thickness, size.y), MAT_ROOF)

	var tower_h: float = max(height - deck_thickness, 1.0)
	b.place(holder, key, Vector3(center.x, 0, center.y), {
		"name": "Tower",
		"size": Vector3(size.x * 0.98, tower_h, size.y * 0.98),
		"rot": rot,
		"collide": true,
	})

	# low parapet wall around the roof so the player can see the edge
	var parapet := GameBuilder.mat(Color(0.48, 0.47, 0.45), 0.95)
	var t := 0.35
	var hgt := 0.5
	for spec in [
		[Vector3(center.x, height + hgt, center.y - size.y * 0.5 + t * 0.5), Vector3(size.x, hgt, t)],
		[Vector3(center.x, height + hgt, center.y + size.y * 0.5 - t * 0.5), Vector3(size.x, hgt, t)],
		[Vector3(center.x - size.x * 0.5 + t * 0.5, height + hgt, center.y), Vector3(t, hgt, size.y)],
		[Vector3(center.x + size.x * 0.5 - t * 0.5, height + hgt, center.y), Vector3(t, hgt, size.y)],
	]:
		var mi := MeshInstance3D.new()
		mi.name = "Parapet"
		var bm := BoxMesh.new()
		bm.size = spec[1]
		mi.mesh = bm
		mi.material_override = parapet
		mi.position = spec[0] - Vector3(0, hgt * 0.5, 0)
		holder.add_child(mi)
	return height


func spinner(parent: Node, pos: Vector3, speed := 90.0, node_name := "Spinner") -> void:
	var s: Node3D = load(SPINNER).instantiate()
	s.name = node_name
	s.position = pos
	s.set("spin_speed", speed)
	parent.add_child(s)


func crusher(parent: Node, pos: Vector3, delay := 0.0, node_name := "Crusher", drop := 5.0) -> void:
	var c: Node3D = load(CRUSHER).instantiate()
	c.name = node_name
	c.position = pos
	c.set("start_delay", delay)
	c.set("drop_height", drop)
	parent.add_child(c)


func mover(parent: Node, pos: Vector3, travel: Vector3, duration := 3.0, node_name := "Mover", delay := 0.0) -> void:
	var m: Node3D = load(MOVER).instantiate()
	m.name = node_name
	m.position = pos
	m.set("travel", travel)
	m.set("duration", duration)
	m.set("start_delay", delay)
	parent.add_child(m)


func checkpoint(parent: Node, pos: Vector3, node_name := "Checkpoint") -> void:
	var c: Node3D = load(CHECKPOINT).instantiate()
	c.name = node_name
	c.position = pos
	parent.add_child(c)


func door(parent: Node, pos: Vector3, rot := 0.0, final := false) -> void:
	var d: Node3D = load(DOOR).instantiate()
	d.name = "ExitDoor"
	d.position = pos
	d.rotation_degrees.y = rot
	d.set("is_final_door", final)
	parent.add_child(d)


## Car that patrols and hurts on contact.
func hazard_car(parent: Node, node_name: String, pos: Vector3, travel: Vector3, duration: float, key := "Car1", rot := 0.0, delay := 0.0) -> void:
	var body := AnimatableBody3D.new()
	body.name = node_name
	body.set_script(load("res://Scripts/MovingPlatform.gd"))
	parent.add_child(body)
	body.position = pos
	body.set("travel", travel)
	body.set("duration", duration)
	body.set("start_delay", delay)

	b.place(body, key, Vector3.ZERO, {"name": "Body", "height": 1.3, "rot": rot})

	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 1.2, 4.2) if int(rot) % 180 == 0 else Vector3(4.2, 1.2, 1.9)
	cs.shape = box
	cs.position = Vector3(0, 0.6, 0)
	body.add_child(cs)

	var hazard := Area3D.new()
	hazard.name = "Hazard"
	hazard.set_script(load("res://Scripts/Hazard.gd"))
	body.add_child(hazard)
	var hcs := CollisionShape3D.new()
	hcs.name = "Shape"
	var hbox := BoxShape3D.new()
	hbox.size = box.size * 1.05
	hcs.shape = hbox
	hcs.position = Vector3(0, 0.6, 0)
	hazard.add_child(hcs)

	var lamp := OmniLight3D.new()
	lamp.name = "Headlights"
	lamp.light_color = Color(1.0, 0.92, 0.7)
	lamp.light_energy = 2.0
	lamp.omni_range = 6.0
	lamp.position = Vector3(0, 0.7, -2.0)
	body.add_child(lamp)


func street_lamp(parent: Node, pos: Vector3, color := Color(1.0, 0.72, 0.35)) -> void:
	var holder := Node3D.new()
	holder.name = "Lamp"
	parent.add_child(holder)
	holder.position = pos
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.14
	cm.height = 5.0
	pole.mesh = cm
	pole.material_override = GameBuilder.mat(Color(0.16, 0.17, 0.2), 0.6, 0.4)
	pole.position = Vector3(0, 2.5, 0)
	holder.add_child(pole)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.2, 1.1)
	head.mesh = bm
	head.material_override = GameBuilder.mat(color, 0.3, 0.0, color)
	head.position = Vector3(0, 5.0, 0)
	holder.add_child(head)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = color
	light.light_energy = 4.0
	light.omni_range = 14.0
	light.position = Vector3(0, 4.8, 0)
	holder.add_child(light)


# ------------------------------------------------------------------ LEVEL 1

func build_level1() -> void:
	var root := level_root("Level1", 0)
	add_sky(root, false)

	var geo := Node3D.new(); geo.name = "Rooftops"; root.add_child(geo)
	var props := Node3D.new(); props.name = "Props"; root.add_child(props)
	var traps := Node3D.new(); traps.name = "Traps"; root.add_child(traps)
	var coins := Node3D.new(); coins.name = "Coins"; root.add_child(coins)
	var city := Node3D.new(); city.name = "CityBelow"; root.add_child(city)

	# --- the path of rooftops: centre(x,z), size(w,d), roof height, model
	# each tower is turned so its detailed (window) face looks at the approaching player
	var roofs := [
		["Roof1", Vector2(0, 0), Vector2(11, 11), 8.0, "Building_Brown", 0.0],
		["Roof2", Vector2(0, -13), Vector2(8, 8), 8.6, "Building_Green", 0.0],
		["Roof3", Vector2(11, -20), Vector2(8, 8), 9.2, "Building_Red", -90.0],
		["Roof4", Vector2(22, -20), Vector2(7, 7), 8.4, "Building_RedCorner", -90.0],
		["Roof5", Vector2(31, -11), Vector2(9, 9), 9.8, "Building_Pizza", 180.0],
		["Roof6", Vector2(31, 1), Vector2(9, 9), 10.6, "Building_Big", 180.0],
		["Roof7", Vector2(21, 9), Vector2(7, 7), 11.2, "Building_Green", 90.0],
		["Roof8", Vector2(10, 12), Vector2(8, 8), 11.8, "Building_Red", 90.0],
		["Roof9", Vector2(-3, 12), Vector2(11, 11), 12.4, "Building_Brown", 90.0],
	]
	for r in roofs:
		rooftop(geo, r[0], r[1], r[2], r[3], r[4], r[5])

	# --- rooftop clutter
	b.place(props, "RoofExit", Vector3(-3.5, 8, 3.0), {"name": "Exit1", "height": 1.8, "rot": 180})
	b.place(props, "AirConditioner", Vector3(3.4, 8, -3.2), {"name": "AC1", "height": 0.9, "rot": 25})
	b.place(props, "AirConditioner", Vector3(4.2, 8, 1.6), {"name": "AC2", "height": 0.9, "rot": -12})
	b.place(props, "WashingLine", Vector3(-2.5, 8.6, -13.5), {"name": "Line1", "height": 2.2, "rot": 90})
	b.place(props, "PowerBox", Vector3(2.4, 8.6, -15.0), {"name": "PB1", "height": 1.0})
	b.place(props, "Box", Vector3(9.0, 9.2, -22.0), {"name": "Crate1", "height": 1.0, "rot": 18})
	b.place(props, "Box", Vector3(9.8, 9.2, -21.0), {"name": "Crate2", "height": 1.0, "rot": -30})
	b.place(props, "AirConditioner", Vector3(23.5, 8.4, -22.0), {"name": "AC3", "height": 0.9, "rot": 40})
	b.place(props, "RoofExit", Vector3(33.0, 9.8, -13.0), {"name": "Exit2", "height": 1.8, "rot": -90})
	b.place(props, "PowerBox", Vector3(28.5, 10.6, 3.5), {"name": "PB2", "height": 1.0})
	b.place(props, "WashingLine", Vector3(22.0, 11.2, 10.5), {"name": "Line2", "height": 2.2})
	b.place(props, "Box", Vector3(12.0, 11.8, 14.0), {"name": "Crate3", "height": 1.0, "rot": 12})
	b.place(props, "RoofExit", Vector3(-6.0, 12.4, 14.5), {"name": "Exit3", "height": 1.8, "rot": 45})
	b.place(props, "Billboard", Vector3(-3.0, 12.4, 7.5), {"name": "Sign", "height": 5.0, "rot": 180})

	# --- moving platforms and a side island with bonus coins
	mover(traps, Vector3(5.5, 9.0, -20.0), Vector3(0, 0, 0), 1.0, "StaticBridgeA")
	mover(traps, Vector3(16.5, 9.0, -20.0), Vector3(0, 3.0, 0), 2.4, "LiftA")
	mover(traps, Vector3(27.0, 10.2, -5.5), Vector3(0, 0, 4.0), 2.6, "SlideA", 0.4)
	b.slab(geo, "Island", Vector3(11.0, 13.5, -31.0), Vector3(6, 0.7, 6), MAT_LEDGE)
	mover(traps, Vector3(11.0, 10.5, -26.5), Vector3(0, 3.2, 0), 2.8, "LiftIsland", 0.8)
	b.place(props, "FlowerPot", Vector3(12.6, 13.5, -32.4), {"name": "Pot1", "height": 1.2})
	b.place(props, "FlowerPot2", Vector3(9.4, 13.5, -29.6), {"name": "Pot2", "height": 1.2})

	# --- traps
	spinner(traps, Vector3(22, 8.4, -20), 110.0, "SpinnerA")
	spinner(traps, Vector3(31, 10.6, 1), -95.0, "SpinnerB")
	spinner(traps, Vector3(10, 11.8, 12), 130.0, "SpinnerC")
	crusher(traps, Vector3(29.0, 15.0, -11.0), 0.0, "CrusherA", 4.1)
	crusher(traps, Vector3(33.0, 15.0, -11.0), 1.1, "CrusherB", 4.1)
	crusher(traps, Vector3(21.0, 16.4, 9.0), 0.6, "CrusherC", 4.1)

	# --- checkpoints
	checkpoint(props, Vector3(22.0, 8.4, -17.5), "CheckpointA")
	checkpoint(props, Vector3(31.0, 10.6, 4.0), "CheckpointB")

	# --- coins (10)
	coin(coins, Vector3(0, 9.6, -13), 1)
	coin(coins, Vector3(5.5, 10.4, -20), 2)
	coin(coins, Vector3(11, 10.4, -20), 3)
	coin(coins, Vector3(16.5, 10.6, -20), 4)
	coin(coins, Vector3(11, 15.0, -31), 5)
	coin(coins, Vector3(31, 11.0, -11), 6)
	coin(coins, Vector3(27.0, 12.0, -3.5), 7)
	coin(coins, Vector3(31, 11.8, 1), 8)
	coin(coins, Vector3(21, 12.4, 9), 9)
	coin(coins, Vector3(10, 13.0, 12), 10)

	# --- exit
	door(props, Vector3(-6.0, 12.4, 10.0), 90.0, false)

	# --- decorative city far below (no collision)
	b.slab(city, "Ground", Vector3(12, 0, -5), Vector3(150, 1, 150), MAT_ROAD)
	city.get_node("Ground").get_node("Shape").disabled = true
	var filler := [
		["Building_Big", Vector2(-22, -8), Vector2(12, 12), 14.0, 90.0],
		["Building_Green", Vector2(-20, 18), Vector2(10, 10), 9.0, 90.0],
		["Building_Red", Vector2(14, 28), Vector2(10, 10), 11.0, 180.0],
		["Building_Brown", Vector2(45, 10), Vector2(12, 12), 16.0, -90.0],
		["Building_Pizza", Vector2(44, -26), Vector2(10, 10), 12.0, -90.0],
		["Building_RedCorner", Vector2(2, -36), Vector2(10, 10), 13.0, 0.0],
		["Building_Green", Vector2(-18, -30), Vector2(10, 10), 10.0, 90.0],
		["Building_Big", Vector2(30, 26), Vector2(12, 12), 15.0, 180.0],
	]
	for f in filler:
		b.place(city, f[0], Vector3(f[1].x, 0, f[1].y), {
			"name": "Far_%s_%d" % [f[0], int(f[1].x)],
			"size": Vector3(f[2].x, f[3], f[2].y),
			"rot": f[4],
			"collide": true,
		})
	for spec in [["Car1", Vector3(-2, 0, 22), 0.0], ["Car2", Vector3(6, 0, 30), 180.0],
			["PoliceCar", Vector3(-10, 0, 6), 90.0], ["Van", Vector3(24, 0, 18), 0.0],
			["SportsCar", Vector3(36, 0, -2), 90.0]]:
		b.place(city, spec[0], spec[1], {"name": "Street_%s_%d" % [spec[0], int(spec[1].z)], "height": 1.3, "rot": spec[2]})
	for tp in [Vector3(-8, 0, 14), Vector3(18, 0, 24), Vector3(40, 0, -14), Vector3(-14, 0, -20)]:
		b.place(city, "Tree", tp, {"name": "Tree_%d_%d" % [int(tp.x), int(tp.z)], "height": 5.5})

	add_common(root, Vector3(0, 9.5, 3.0), Vector3(12, -6, -5), Vector3(320, 10, 320))
	b.save(root, "res://Scenes/Levels/Level1.tscn")
	root.free()


# ------------------------------------------------------------------ LEVEL 2

func road_block(parent: Node, node_name: String, z_from: float, z_to: float) -> void:
	var length: float = abs(z_to - z_from)
	var cz := (z_from + z_to) * 0.5
	b.slab(parent, node_name + "_Road", Vector3(0, 0, cz), Vector3(16, 1.0, length), MAT_ROAD)
	b.slab(parent, node_name + "_WalkL", Vector3(-10, 0.35, cz), Vector3(4, 1.0, length), MAT_WALK)
	b.slab(parent, node_name + "_WalkR", Vector3(10, 0.35, cz), Vector3(4, 1.0, length), MAT_WALK)
	# centre line
	var line := MeshInstance3D.new()
	line.name = node_name + "_Line"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.02, length * 0.72)
	line.mesh = bm
	line.material_override = GameBuilder.mat(Color(0.85, 0.82, 0.55), 0.9)
	line.position = Vector3(0, 0.02, cz)
	parent.add_child(line)


func build_level2() -> void:
	var root := level_root("Level2", 1)
	add_sky(root, true)

	var geo := Node3D.new(); geo.name = "Street"; root.add_child(geo)
	var props := Node3D.new(); props.name = "Props"; root.add_child(props)
	var traps := Node3D.new(); traps.name = "Traps"; root.add_child(traps)
	var coins := Node3D.new(); coins.name = "Coins"; root.add_child(coins)
	var blocks := Node3D.new(); blocks.name = "Blocks"; root.add_child(blocks)

	# --- road segments with pits in between
	road_block(geo, "SegA", 16.0, -6.0)
	road_block(geo, "SegB", -10.0, -30.0)
	road_block(geo, "SegC", -34.0, -56.0)
	road_block(geo, "SegD", -60.0, -98.0)

	# --- buildings lining the street
	var left := [
		["Building_Red", 8.0, 10.0], ["Building_Green", -6.0, 12.0], ["Building_Brown", -20.0, 9.0],
		["Building_Pizza", -34.0, 13.0], ["Building_RedCorner", -48.0, 10.0], ["Building_Big", -62.0, 15.0],
		["Building_Green", -76.0, 11.0], ["Building_Red", -90.0, 12.0],
	]
	for i in left.size():
		var e = left[i]
		b.place(blocks, e[0], Vector3(-22, 0, e[1]), {
			"name": "BuildL%d" % i, "size": Vector3(14, e[2], 13), "collide": true, "rot": 90})
	var right := [
		["Building_Brown", 8.0, 12.0], ["Building_Red", -6.0, 9.0], ["Building_Big", -20.0, 14.0],
		["Building_Green", -34.0, 11.0], ["Building_Brown", -48.0, 13.0], ["Building_RedCorner", -62.0, 10.0],
		["Building_Pizza", -76.0, 12.0], ["Building_Big", -90.0, 15.0],
	]
	for i in right.size():
		var e = right[i]
		b.place(blocks, e[0], Vector3(22, 0, e[1]), {
			"name": "BuildR%d" % i, "size": Vector3(14, e[2], 13), "collide": true, "rot": -90})

	# --- street dressing
	for z in [12.0, 2.0, -14.0, -26.0, -40.0, -52.0, -66.0, -80.0, -92.0]:
		street_lamp(props, Vector3(-10.5, 0.35, z))
		street_lamp(props, Vector3(10.5, 0.35, z))
	b.place(props, "BusStop", Vector3(10.5, 0.35, 8.0), {"name": "BusStop1", "height": 2.6, "rot": -90})
	b.place(props, "Bench", Vector3(-10.5, 0.35, 4.0), {"name": "Bench1", "height": 0.85, "rot": 90})
	b.place(props, "Bench", Vector3(10.5, 0.35, -20.0), {"name": "Bench2", "height": 0.85, "rot": -90})
	b.place(props, "TrafficLight", Vector3(9.6, 0.35, -6.5), {"name": "TL1", "height": 4.2, "rot": 180})
	b.place(props, "TrafficLight", Vector3(-9.6, 0.35, -56.5), {"name": "TL2", "height": 4.2})
	b.place(props, "StopSign", Vector3(-10.5, 0.35, -30.5), {"name": "Stop1", "height": 2.2})
	b.place(props, "FireHydrant", Vector3(10.8, 0.35, -12.0), {"name": "Hydrant1", "height": 0.8})
	b.place(props, "FireHydrant", Vector3(-10.8, 0.35, -70.0), {"name": "Hydrant2", "height": 0.8})
	b.place(props, "Mailbox", Vector3(-10.8, 0.35, -44.0), {"name": "Mailbox1", "height": 1.1, "rot": 90})
	b.place(props, "Planter", Vector3(10.8, 0.35, -46.0), {"name": "Planter1", "height": 0.9, "rot": -90})
	b.place(props, "Planter", Vector3(-10.8, 0.35, -86.0), {"name": "Planter2", "height": 0.9, "rot": 90})
	for tz in [-2.0, -22.0, -48.0, -74.0, -94.0]:
		b.place(props, "Tree", Vector3(-10.8, 0.35, tz), {"name": "TreeL%d" % int(tz), "height": 5.5})
		b.place(props, "Tree", Vector3(10.8, 0.35, tz - 6.0), {"name": "TreeR%d" % int(tz), "height": 5.5})
	for cz in [-8.5, -32.0, -58.0]:
		b.place(props, "Cone", Vector3(-2.2, 0, cz), {"name": "ConeA%d" % int(cz), "height": 0.7})
		b.place(props, "Cone", Vector3(2.2, 0, cz), {"name": "ConeB%d" % int(cz), "height": 0.7})
	b.place(props, "PoliceCar", Vector3(-5.5, 0, 13.0), {"name": "ParkedCop", "height": 1.35})
	b.place(props, "SportsCar", Vector3(5.5, 0, -28.0), {"name": "ParkedSports", "height": 1.3, "rot": 180})

	# --- climbable scenery: dumpster -> crates -> awning with coins
	b.place(props, "Dumpster", Vector3(-6.5, 0, -16.0), {"name": "Dump1", "height": 1.4, "collide": true, "rot": 90})
	b.slab(geo, "Crate1", Vector3(-6.5, 2.6, -19.0), Vector3(1.6, 1.6, 1.6), MAT_WOOD)
	b.slab(geo, "Awning1", Vector3(-9.0, 4.0, -23.0), Vector3(6, 0.4, 6), MAT_LEDGE)
	b.slab(geo, "Awning2", Vector3(-9.0, 5.4, -30.0), Vector3(6, 0.4, 6), MAT_LEDGE)

	b.slab(geo, "Scaffold1", Vector3(9.0, 2.4, -40.0), Vector3(6, 0.4, 6), MAT_LEDGE)
	b.slab(geo, "Scaffold2", Vector3(9.0, 4.6, -47.0), Vector3(6, 0.4, 6), MAT_LEDGE)
	b.slab(geo, "Scaffold3", Vector3(3.0, 6.4, -52.0), Vector3(5, 0.4, 5), MAT_LEDGE)
	b.place(props, "TrashCan", Vector3(8.4, 0.35, -34.0), {"name": "Bin1", "height": 1.1, "collide": true})
	b.place(props, "Box", Vector3(9.2, 0.35, -35.6), {"name": "Box1", "height": 1.1, "collide": true, "rot": 20})

	# --- bridging the pits
	mover(traps, Vector3(0, 0, -32.0), Vector3(0, 0, 0), 1.0, "PitBridgeB")
	mover(traps, Vector3(0, 0, -58.0), Vector3(7.0, 0, 0), 2.8, "PitMoverC", 0.3)
	b.slab(geo, "PitLedgeA", Vector3(-6.0, 0, -8.0), Vector3(3.5, 1.0, 3.0), MAT_LEDGE)

	# --- traps
	hazard_car(traps, "TrafficA", Vector3(-4.0, 0, -12.0), Vector3(0, 0, -16.0), 4.2, "Car1", 180.0)
	hazard_car(traps, "TrafficB", Vector3(4.0, 0, -28.0), Vector3(0, 0, 16.0), 4.6, "Car2", 0.0, 0.8)
	hazard_car(traps, "TrafficC", Vector3(-4.0, 0, -36.0), Vector3(0, 0, -18.0), 4.0, "Van", 180.0, 0.4)
	hazard_car(traps, "TrafficD", Vector3(4.0, 0, -54.0), Vector3(0, 0, 16.0), 4.4, "SportsCar", 0.0)
	hazard_car(traps, "TrafficE", Vector3(-4.0, 0, -64.0), Vector3(0, 0, -28.0), 5.2, "PoliceCar", 180.0, 0.6)
	hazard_car(traps, "TrafficF", Vector3(4.0, 0, -94.0), Vector3(0, 0, 28.0), 5.6, "Car1", 0.0, 1.2)

	spinner(traps, Vector3(0, 0, -22.0), 120.0, "SpinnerS1")
	spinner(traps, Vector3(0, 0, -44.0), -105.0, "SpinnerS2")
	spinner(traps, Vector3(0, 0, -72.0), 135.0, "SpinnerS3")
	crusher(traps, Vector3(-4.0, 6.0, -48.0), 0.0, "CrushS1", 4.9)
	crusher(traps, Vector3(4.0, 6.0, -68.0), 0.9, "CrushS2", 4.9)
	crusher(traps, Vector3(-4.0, 6.0, -84.0), 0.5, "CrushS3", 4.9)
	crusher(traps, Vector3(4.0, 6.0, -88.0), 1.4, "CrushS4", 4.9)

	# --- checkpoints
	checkpoint(props, Vector3(-10.0, 0.35, -30.0), "CheckpointA")
	checkpoint(props, Vector3(10.0, 0.35, -60.0), "CheckpointB")

	# --- coins (12)
	coin(coins, Vector3(0, 1.4, 6.0), 1)
	coin(coins, Vector3(-6.0, 1.4, -8.0), 2)
	coin(coins, Vector3(-6.5, 4.0, -19.0), 3)
	coin(coins, Vector3(-9.0, 4.9, -23.0), 4)
	coin(coins, Vector3(-9.0, 6.3, -30.0), 5)
	coin(coins, Vector3(0, 1.4, -32.0), 6)
	coin(coins, Vector3(9.0, 3.4, -40.0), 7)
	coin(coins, Vector3(9.0, 5.6, -47.0), 8)
	coin(coins, Vector3(3.0, 7.4, -52.0), 9)
	coin(coins, Vector3(0, 1.6, -58.0), 10)
	coin(coins, Vector3(0, 1.4, -76.0), 11)
	coin(coins, Vector3(0, 1.4, -92.0), 12)

	# --- exit plaza and final door
	b.slab(geo, "Plaza", Vector3(0, 0.6, -102.0), Vector3(18, 1.2, 10), MAT_WALK)
	b.place(props, "Fence", Vector3(-6.5, 0.6, -106.0), {"name": "FenceA", "height": 1.6})
	b.place(props, "Fence", Vector3(6.5, 0.6, -106.0), {"name": "FenceB", "height": 1.6})
	door(props, Vector3(0, 0.6, -104.0), 0.0, true)

	add_common(root, Vector3(0, 1.6, 12.0), Vector3(0, -6, -42), Vector3(400, 10, 400))
	b.save(root, "res://Scenes/Levels/Level2.tscn")
	root.free()
