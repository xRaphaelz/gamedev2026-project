extends Node3D
## ฉากร้าน+ฉากหลัง ใช้ร่วมกันในด่านเล่น คัตซีน และเมนูหลัก
## ตั้งค่าแสง ท้องฟ้า โทนสี และสไตล์การ์ตูนของทั้งฉากที่นี่

var _sky_mat: ProceduralSkyMaterial


func _ready() -> void:
	_setup_environment()
	Stylize.apply(self)


func _setup_environment() -> void:
	var env: Environment = $WorldEnvironment.environment
	_sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.tonemap_white = 2.2
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	env.fog_enabled = true
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	var sun: DirectionalLight3D = $Sun
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 32.0
	if is_low_quality():
		_apply_low_quality(env, sun)


## เว็บ (เบราว์เซอร์) รันเธรดเดียวและใช้ WebGL จึงลดงานกราฟิกที่หนักที่สุดลง
## ทดสอบบนเครื่องได้ด้วย: godot --path . -- --lowq
static func is_low_quality() -> bool:
	return OS.has_feature("web") or "--lowq" in OS.get_cmdline_user_args()


func _apply_low_quality(env: Environment, sun: DirectionalLight3D) -> void:
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(2048, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 22.0
	sun.shadow_blur = 1.0
	env.glow_enabled = false
	# ไฟโคม 3 ดวงตอนเย็น: ใน Compatibility ทุกดวงคือการวาดซ้ำทั้งฉาก -> เหลือดวงเดียวตรงกลาง
	var lamps := $Lights.get_children()
	for i in lamps.size():
		var l := lamps[i] as OmniLight3D
		if l == null or l.is_queued_for_deletion():
			continue
		l.shadow_enabled = false
		if i > 0:
			l.queue_free()
		else:
			l.position = Vector3(0, 2.7, 0.8)
			l.omni_range = 8.0
			l.light_energy = 1.2


## ซ่อนป้ายชื่อ/สถานะของสถานี (ใช้ในคัตซีนและเมนู)
func hide_station_labels() -> void:
	for st in $Stations.get_children():
		for c in st.get_children():
			if c is Label3D:
				c.visible = false


## 0 = เช้า, 1 = กลางวัน, 2 = เย็น
func apply_time_of_day(t: int) -> void:
	if _sky_mat == null:
		_setup_environment()
	var sun: DirectionalLight3D = $Sun
	var env: Environment = $WorldEnvironment.environment
	var presets := [
		# แดด: สี, ความแรง, มุมก้ม, มุมหัน | ฟ้าบน, ขอบฟ้า | แสงแวดล้อม | ไฟประดับ, โคมไฟ | หมอก
		{"sun": Color(1.0, 0.88, 0.7), "e": 0.85, "pitch": -36.0, "yaw": -50.0,
		 "top": Color(0.42, 0.62, 0.92), "hor": Color(0.95, 0.84, 0.74), "amb": 0.26,
		 "bulb": 0.4, "lamps": false, "fog": Color(0.95, 0.85, 0.75), "exp": 0.85},
		{"sun": Color(1.0, 0.97, 0.9), "e": 0.95, "pitch": -60.0, "yaw": -20.0,
		 "top": Color(0.3, 0.55, 0.95), "hor": Color(0.75, 0.87, 1.0), "amb": 0.28,
		 "bulb": 0.2, "lamps": false, "fog": Color(0.8, 0.88, 1.0), "exp": 0.85},
		{"sun": Color(1.0, 0.5, 0.28), "e": 0.6, "pitch": -20.0, "yaw": 60.0,
		 "top": Color(0.2, 0.18, 0.42), "hor": Color(0.95, 0.58, 0.42), "amb": 0.3,
		 "bulb": 6.0, "lamps": true, "fog": Color(0.45, 0.35, 0.45), "exp": 1.15},
	]
	var p: Dictionary = presets[clampi(t, 0, 2)]
	sun.light_color = p.sun
	sun.light_energy = p.e
	sun.rotation_degrees = Vector3(p.pitch, p.yaw, 0)
	_sky_mat.sky_top_color = p.top
	_sky_mat.sky_horizon_color = p.hor
	_sky_mat.ground_horizon_color = p.hor
	_sky_mat.ground_bottom_color = (p.top as Color).darkened(0.4)
	_sky_mat.sun_angle_max = 30.0
	env.ambient_light_energy = p.amb
	env.fog_light_color = p.fog
	env.tonemap_exposure = p.exp
	$Lights.visible = p.lamps
	set_emission($Env/Bulbs, p.bulb)


var _rain: CPUParticles3D
var _rain_tween: Tween
var _sun_energy := -1.0
var _amb_energy := -1.0


## ฝนตก (เหตุการณ์สุ่ม): เม็ดฝน + ฟ้ามืดลง
func set_rain(on: bool) -> void:
	var sun: DirectionalLight3D = $Sun
	var env: Environment = $WorldEnvironment.environment
	if _sun_energy < 0.0:
		_sun_energy = sun.light_energy
		_amb_energy = env.ambient_light_energy
	if _rain == null:
		_rain = CPUParticles3D.new()
		_rain.amount = 160 if is_low_quality() else 420
		_rain.lifetime = 0.9
		_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_rain.emission_box_extents = Vector3(12, 0.2, 9)
		_rain.position = Vector3(0, 7, 2)
		_rain.direction = Vector3(0.15, -1, 0)
		_rain.spread = 2.0
		_rain.gravity = Vector3(0, -20, 0)
		_rain.initial_velocity_min = 9.0
		_rain.initial_velocity_max = 11.0
		var drop := BoxMesh.new()
		drop.size = Vector3(0.015, 0.35, 0.015)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.75, 0.85, 1.0, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop.material = m
		_rain.mesh = drop
		add_child(_rain)
	_rain.emitting = on
	if _rain_tween:
		_rain_tween.kill()
	_rain_tween = create_tween().set_parallel()
	_rain_tween.tween_property(sun, "light_energy", _sun_energy * (0.45 if on else 1.0), 1.2)
	_rain_tween.tween_property(env, "ambient_light_energy", _amb_energy * (0.75 if on else 1.0), 1.2)


static func set_emission(n: Node, energy: float) -> void:
	if n is MeshInstance3D:
		var mesh: Mesh = n.mesh
		for i in mesh.get_surface_count():
			var m := n.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				m = mesh.surface_get_material(i) as StandardMaterial3D
			if m and m.emission_enabled:
				var dup := m.duplicate() as StandardMaterial3D
				dup.emission_energy_multiplier = energy
				n.set_surface_override_material(i, dup)
	for c in n.get_children():
		set_emission(c, energy)
