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
