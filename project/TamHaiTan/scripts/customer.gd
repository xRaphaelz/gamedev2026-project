class_name Customer
extends Node3D
## ลูกค้า 1 คน: เดินมานั่งโต๊ะ มีลูกโป่งบอกเมนู (สีเปลี่ยนตามความอดทน) แล้วเดินกลับ

signal gone(customer: Customer)

const WALK_SPEED := 2.6
const THAI_FONT := preload("res://assets/fonts/Kanit-Medium.ttf")

var order: OrderManager.Order
var seat: Marker3D
var leaving := false

var rig: CharacterRig
var _path: Array[Vector3] = []
var _bubble: Node3D
var _bubble_bg: Sprite3D
var _label: Label3D
var _face: Sprite3D
var _mood := -1

static var _circle_tex: Texture2D
static var _face_tex := {}


func setup(o: OrderManager.Order, s: Marker3D, spawn: Vector3) -> void:
	order = o
	seat = s
	rig = CharacterRig.new()
	rig.character = o.model
	add_child(rig)
	if o.reviewer:
		rig.add_sunglasses.call_deferred()
	position = spawn
	var front := Vector3(s.global_position.x, 0, s.global_position.z + 1.1)
	_path = [Vector3(front.x, 0, spawn.z), front, s.global_position]
	_build_bubble()


func leave(served: bool, exit: Vector3) -> void:
	if leaving:
		return
	leaving = true
	_bubble.visible = false
	rig.react("happy" if served else "angry")
	Audio.sfx("happy" if served else "angry", -6.0)
	_say("อร่อย!" if served else "ช้าจัง!", Color(0.55, 1, 0.45) if served else Color(1, 0.45, 0.35))
	if not served:
		Fx.float_text(get_parent(), global_position + Vector3(0, 2.5, 0), "-%d" % OrderManager.EXPIRE_PENALTY, Color(1, 0.4, 0.3), 40)
		Fx.burst(get_parent(), global_position + Vector3(0, 1.6, 0), [Color(0.8, 0.8, 0.8), Color(1, 1, 1)], 8, 1.5, 0.08)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	rig.react("")
	rig.rotation.y = 0
	_label.visible = false
	var p := global_position
	_path = [Vector3(p.x, 0, p.z + 1.1), Vector3(p.x, 0, exit.z), exit]
	position.y = 0


func _process(delta: float) -> void:
	if order and not leaving:
		var r := order.ratio()
		_bubble_bg.modulate = Color(1, 1, 1).lerp(Color(1, 0.35, 0.25), 1.0 - r) if r < 0.6 else Color.WHITE
		_bubble.position.y = 2.05 + sin(Time.get_ticks_msec() / 300.0) * 0.04
		var m := order.mood()
		if m != _mood:
			_mood = m
			_face.texture = _face_texture(m)
			Fx.pop(_face, 1.35)
	if _path.is_empty():
		return
	var target := _path[0]
	var to := target - position
	to.y = 0
	var step := WALK_SPEED * delta
	rig.state = "walk"
	if to.length() <= step:
		position = Vector3(target.x, 0, target.z)
		_path.pop_front()
		if _path.is_empty():
			_arrive()
		return
	var dir := to.normalized()
	position += dir * step
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(12.0 * delta, 0, 1))


func _arrive() -> void:
	if leaving:
		gone.emit(self)
		queue_free()
		return
	rotation.y = seat.global_rotation.y
	rig.state = "sit"
	_bubble.visible = true


func _say(text: String, c: Color) -> void:
	_label.text = text
	_label.modulate = c
	_label.visible = true


func _build_bubble() -> void:
	_bubble = Node3D.new()
	_bubble.position.y = 2.05
	_bubble.visible = false
	add_child(_bubble)
	_bubble_bg = Sprite3D.new()
	_bubble_bg.texture = _circle()
	_bubble_bg.pixel_size = 0.0055
	_bubble_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble_bg.no_depth_test = true
	_bubble_bg.render_priority = 2
	_bubble.add_child(_bubble_bg)
	# หน้าบอกอารมณ์ลูกค้า (ยิ้ม -> เฉย -> หงุดหงิด ตามเวลาที่รอ)
	_face = Sprite3D.new()
	_face.texture = _face_texture(2)
	_face.pixel_size = 0.0042
	_face.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_face.no_depth_test = true
	_face.render_priority = 4
	_face.position = Vector3(0.44, 0.22, 0)
	_bubble.add_child(_face)
	# ระดับเผ็ดที่สั่ง
	if GameState.current_level().spice_enabled:
		var sp := Label3D.new()
		sp.font = THAI_FONT
		sp.font_size = 24
		sp.outline_size = 10
		sp.pixel_size = 0.01
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.render_priority = 6
		sp.outline_render_priority = 5
		sp.modulate = Color(1, 0.35, 0.25) if order.spice > 0 else Color(0.6, 0.9, 0.5)
		sp.text = "ไม่เผ็ด" if order.spice <= 0 else "พริก %d" % order.spice
		sp.position = Vector3(0, -0.42, 0)
		_bubble.add_child(sp)
	if order.reviewer:
		var rv := Label3D.new()
		rv.font = THAI_FONT
		rv.font_size = 34
		rv.outline_size = 12
		rv.pixel_size = 0.01
		rv.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rv.no_depth_test = true
		rv.render_priority = 6
		rv.outline_render_priority = 5
		rv.modulate = Color(1, 0.85, 0.25)
		rv.text = "★ นักรีวิว ★"
		rv.position = Vector3(0, 0.5, 0)
		_bubble.add_child(rv)
	if order.recipe.icon:
		var icon := Sprite3D.new()
		icon.texture = order.recipe.icon
		icon.pixel_size = 0.0034
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.render_priority = 3
		_bubble.add_child(icon)
	_label = Label3D.new()
	_label.font = THAI_FONT
	_label.font_size = 40
	_label.outline_size = 12
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 5
	_label.position.y = 2.1
	_label.visible = false
	add_child(_label)


## ได้ทิป: เหรียญเด้งเหนือหัว
func show_tip(tip: int, reviewer: bool) -> void:
	if tip <= 0 and not reviewer:
		return
	var top := global_position + Vector3(0, 2.6, 0)
	if tip > 0:
		Fx.float_text(get_parent(), top, "ทิป +%d" % tip, Color(1, 0.85, 0.3), 40)
		Fx.burst(get_parent(), global_position + Vector3(0, 1.8, 0), [Color(1, 0.82, 0.2), Color(1, 0.95, 0.55)], 12, 2.4, 0.07, true)
		Audio.sfx("star", -8.0, 0.0)
	if reviewer:
		Fx.float_text(get_parent(), top + Vector3(0, 0.45, 0), "รีวิว 5 ดาว! x2", Color(1, 0.7, 0.2), 44)


## หน้ายิ้ม/เฉย/บึ้ง วาดด้วยโค้ด (ไม่พึ่งฟอนต์อีโมจิ ซึ่งเว็บบางเครื่องไม่มี)
static func _face_texture(m: int) -> Texture2D:
	if _face_tex.has(m):
		return _face_tex[m]
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var fill: Color = [Color(1, 0.45, 0.35), Color(1, 0.82, 0.3), Color(0.55, 0.9, 0.4)][m]
	var ink := Color(0.25, 0.13, 0.08)
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d < 42:
				col = fill
			elif d < 46:
				col = ink
			# ตา
			for ex in [-14, 14]:
				if p.distance_to(c + Vector2(ex, -8)) < 6:
					col = ink
			# ปาก: ยิ้ม = โค้งลง, เฉย = เส้นตรง, บึ้ง = โค้งขึ้น
			var mx := p.x - c.x
			if absf(mx) < 18:
				var t := mx / 18.0
				var bend := 8.0 * (1.0 - t * t)
				var my: float = [c.y + 22.0 - bend, c.y + 18.0, c.y + 14.0 + bend][m]
				if absf(p.y - my) < 3.2:
					col = ink
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_face_tex[m] = tex
	return tex


static func _circle() -> Texture2D:
	if _circle_tex:
		return _circle_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d < 58:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			elif d < 63:
				img.set_pixel(x, y, Color(0.93, 0.45, 0.13, 1))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_circle_tex = ImageTexture.create_from_image(img)
	return _circle_tex
