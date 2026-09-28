extends SceneTree
## Builds Scenes/Demo.tscn procedurally (run: godot --headless --script res://Tools/build_demo.gd)
var done := false

func claim(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			claim(c, owner_node)

func mat(c: Color, rough := 0.85, metal := 0.0, emit := Color(0,0,0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; m.metallic = metal
	if emit != Color(0,0,0): m.emission_enabled = true; m.emission = emit; m.emission_energy_multiplier = 2.0
	return m

func _process(_d: float) -> bool:
	if done: return true
	done = true
	var root := Node3D.new(); root.name = "Demo"
	root.set_script(load("res://Scripts/Demo.gd"))

	var env := Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.05, 0.06, 0.12); sm.sky_horizon_color = Color(0.16, 0.14, 0.26)
	sm.ground_bottom_color = Color(0.03, 0.03, 0.05); sm.ground_horizon_color = Color(0.12, 0.11, 0.2)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true; env.glow_intensity = 0.35; env.glow_bloom = 0.0
	env.ssao_enabled = true
	env.fog_enabled = true; env.fog_light_color = Color(0.12, 0.11, 0.2); env.fog_density = 0.06
	var we := WorldEnvironment.new(); we.name = "WorldEnvironment"; we.environment = env; root.add_child(we)

	var sun := DirectionalLight3D.new(); sun.name = "KeyLight"; sun.shadow_enabled = true
	sun.light_energy = 1.4; sun.light_color = Color(1.0, 0.95, 0.88); sun.rotation_degrees = Vector3(-48, 35, 0)
	root.add_child(sun)
	var rim := DirectionalLight3D.new(); rim.name = "RimLight"; rim.light_energy = 0.6; rim.light_specular = 0.0
	rim.light_color = Color(0.45, 0.85, 1.0); rim.rotation_degrees = Vector3(-20, 200, 0)
	root.add_child(rim)

	var stage := Node3D.new(); stage.name = "Stage"; root.add_child(stage)
	var floor_mi := MeshInstance3D.new(); floor_mi.name = "Floor"
	var pm := PlaneMesh.new(); pm.size = Vector2(400, 400); floor_mi.mesh = pm
	floor_mi.material_override = mat(Color(0.07, 0.07, 0.11), 0.95)
	floor_mi.position.y = -0.12; stage.add_child(floor_mi)
	var plat := MeshInstance3D.new(); plat.name = "Platform"
	var cm := CylinderMesh.new(); cm.top_radius = 1.7; cm.bottom_radius = 1.8; cm.height = 0.12; cm.radial_segments = 64
	plat.mesh = cm; plat.material_override = mat(Color(0.13, 0.13, 0.19), 0.92, 0.0); plat.position.y = -0.06
	stage.add_child(plat)
	var ring := MeshInstance3D.new(); ring.name = "GlowRing"
	var tm := TorusMesh.new(); tm.inner_radius = 1.73; tm.outer_radius = 1.76; tm.rings = 64
	ring.mesh = tm; ring.material_override = mat(Color(0.30, 0.75, 0.70), 0.4, 0.0, Color(0.15, 0.55, 0.5))
	ring.position.y = 0.0; stage.add_child(ring)

	var ch: Node3D = load("res://Character/RobloxChar_Mixamo.glb").instantiate()
	ch.name = "Character"; root.add_child(ch)
	var ap := AnimationPlayer.new(); ap.name = "AnimationPlayer"; ch.add_child(ap)

	var rig := Node3D.new(); rig.name = "CameraRig"; rig.position = Vector3(0, 1.0, 0)
	rig.set_script(load("res://Scripts/OrbitCamera.gd")); root.add_child(rig)
	var cam := Camera3D.new(); cam.name = "Camera3D"; cam.position = Vector3(0, 0, 5.8); cam.fov = 40
	cam.h_offset = -0.95; cam.v_offset = -0.25; cam.current = true
	rig.add_child(cam)

	claim(root, root)
	ap.owner = root
	var ps := PackedScene.new(); ps.pack(root)
	print("save=", ResourceSaver.save(ps, "res://Scenes/Demo.tscn"))
	root.free()
	return true
