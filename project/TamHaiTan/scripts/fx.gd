class_name Fx
## เอฟเฟกต์ภาพเล็ก ๆ ใช้ร่วมทั้งเกม: เศษกระเด็น, ประกาย, ตัวเลขลอย, เด้ง

const THAI_FONT := preload("res://assets/fonts/Kanit-Medium.ttf")


## เศษชิ้นเล็ก ๆ กระเด็น (ตำ/หั่น)
static func burst(parent: Node, pos: Vector3, colors: Array, amount := 10, speed := 2.2, size := 0.05, glow := false) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = m
	p.mesh = box
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.angular_velocity_min = -400
	p.angular_velocity_max = 400
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var g := Gradient.new()
	var cs := PackedColorArray()
	var offs := PackedFloat32Array()
	for i in colors.size():
		cs.append(colors[i])
		offs.append(float(i) / maxf(colors.size() - 1, 1))
	g.colors = cs
	g.offsets = offs
	p.color_initial_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


## ประกายดาว (ทำเสร็จ / เสิร์ฟ)
static func sparkle(parent: Node, pos: Vector3) -> void:
	burst(parent, pos, [Color(1, 0.9, 0.3), Color(1, 1, 0.8), Color(1, 0.6, 0.2)], 16, 3.2, 0.13, true)


## ตัวหนังสือลอยขึ้นแล้วจางหาย เช่น "+25"
static func float_text(parent: Node, pos: Vector3, text: String, color := Color(0.6, 1, 0.45), size := 48) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label3D.new()
	l.font = THAI_FONT
	l.text = text
	l.font_size = size
	l.outline_size = 12
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	l.pixel_size = 0.01
	parent.add_child(l)
	l.global_position = pos
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.9, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


## เด้งขยายแล้วหดกลับ (หยิบ/วางของ)
static func pop(n: Node3D, amount := 1.25) -> void:
	if n == null or not n.is_inside_tree():
		return
	var base := n.scale
	n.scale = base * amount
	n.create_tween().tween_property(n, "scale", base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## สั่นเบา ๆ (ครกตอนตำ)
static func shake(n: Node3D, strength := 0.03) -> void:
	if n == null or not n.is_inside_tree():
		return
	var base := n.position
	var tw := n.create_tween()
	for i in 3:
		tw.tween_property(n, "position", base + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * strength, 0.03)
	tw.tween_property(n, "position", base, 0.04)
