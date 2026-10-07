extends Node3D
## คัตซีนที่เล่นด้วยโมเดลในเกม (กล้องเคลื่อน ตัวละครขยับ ซับไทย)
## เพิ่ม/แก้คัตซีน: เขียนฟังก์ชัน _cs_<id>() ด้านล่าง แล้วตั้ง cutscene_before ในไฟล์ด่าน
## Enter/Space = ข้ามบรรทัด, Esc = ข้ามทั้งฉาก
## export เป็นวิดีโอ: godot --path . --write-movie out.avi --fixed-fps 30 res://scenes/cutscene.tscn -- --cutscene=level_1

## ถ้ามีไฟล์ assets/videos/<id>.ogv จะเล่นวิดีโอนั้นแทนคัตซีนที่เขียนด้วยโค้ด
const VIDEO_DIR := "res://assets/videos/%s.ogv"
const CREDITS := "ตำให้ทัน!

ทีมพัฒนา
673380353-1  นายอชิรวิทย์ ศรีชา (เชฟ)
673380531-3  นายวิษณุ รีชัยพิชิตกุล (บอส)
673380521-6  นายธีรปรัชญ์ สาขาคำ (ป่าน)
673380344-2  นายวีรภัทร โพธิ์สิงห์ (เพลง)"

@onready var stage: Node3D = $Stage
@onready var cam: Camera3D = $Camera3D
@onready var actors_root: Node3D = $Actors

signal done

var id := ""
var standalone := false
## ใช้ตอนทดสอบ: จบแล้วไม่เปลี่ยนฉาก
var no_scene_change := false
var actors := {}
var _skip := false
var _next_line := false
var _done := false
var _pound_t := 0.0

var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _sub_name: Label
var _sub_text: Label
var _title: Label
var _subtitle: Label
var _center_text: Label
var _black: ColorRect


func _ready() -> void:
	id = GameState.cutscene_id
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cutscene="):
			id = a.get_slice("=", 1)
			standalone = true
	_build_ui()
	stage.hide_station_labels()
	_run()


func _run() -> void:
	await get_tree().process_frame
	var video := VIDEO_DIR % id
	if ResourceLoader.exists(video):
		# มีไฟล์วิดีโอ (เช่นจาก AI) -> เล่นวิดีโอแทนคัตซีนในเกม
		await _play_video(video)
		if id.begins_with("ending"):
			_black.color.a = 0.85
			await center_text("รีวิวเฉลี่ย %.1f ดาว" % GameState.average_stars(), 2.0)
			await center_text(CREDITS, 7.0)
	elif has_method("_cs_" + id):
		await call("_cs_" + id)
	await _wait(0.3)
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Audio.music("")
	done.emit()
	if no_scene_change:
		return
	if standalone:
		get_tree().quit()
	else:
		GameState.cutscene_finished()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_skip = true
		_finish()
	elif event.is_action_pressed("confirm") or (event is InputEventMouseButton and event.pressed):
		_next_line = true


func _process(delta: float) -> void:
	# เสียงตำของตัวละครที่กำลังตำ
	_pound_t -= delta
	if _pound_t <= 0.0:
		for a in actors.values():
			if a.mood == "pound":
				Audio.sfx("pound", -4.0, 0.1)
				_pound_t = 0.45
				break


# ======================= เครื่องมือ =======================

func _play_video(path: String) -> void:
	Audio.music("")
	_top_bar.hide()
	_bottom_bar.hide()
	var vp := VideoStreamPlayer.new()
	vp.stream = load(path)
	vp.expand = true
	vp.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.bus = "Music"
	_black.get_parent().add_child(vp)
	_black.get_parent().move_child(vp, 0)
	_black.color = Color(0, 0, 0, 1)
	_black.get_parent().move_child(_black, 0)
	vp.play()
	while vp.is_playing() and not _skip and is_inside_tree():
		await get_tree().process_frame
	vp.queue_free()


func _wait(t: float) -> void:
	var left := t
	while left > 0.0 and not _skip and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()


## รอจนครบเวลา หรือผู้เล่นกดข้ามบรรทัด
func _wait_line(t: float) -> void:
	_next_line = false
	var left := t
	while left > 0.0 and not _skip and not _next_line and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()
	_next_line = false


func spawn(name: String, character: String, pos: Vector3, face_deg := 0.0) -> CharacterRig:
	var r := CharacterRig.new()
	r.character = character
	actors_root.add_child(r)
	r.position = pos
	r.rotation.y = deg_to_rad(face_deg)
	actors[name] = r
	return r


func prop(path: String, pos: Vector3, rot_deg := 0.0, s := 1.0) -> Node3D:
	var n := Item.instance_model(path)
	if n == null:
		n = Node3D.new()
	actors_root.add_child(n)
	n.position = pos
	n.rotation.y = deg_to_rad(rot_deg)
	n.scale = Vector3.ONE * s
	return n


## เดินไปยังจุดต่าง ๆ ตามลำดับ (เรียกแบบไม่ await เพื่อให้เดินพร้อมกับอย่างอื่นได้)
func walk(name: String, points: Array, speed := 2.2) -> void:
	var a: CharacterRig = actors[name]
	for p in points:
		var to: Vector3 = p
		var d := to - a.position
		d.y = 0
		if d.length() < 0.01:
			continue
		a.state = "walk"
		a.rotation.y = atan2(-d.x, -d.z)
		var dur := d.length() / speed
		var tw := create_tween()
		tw.tween_property(a, "position", to, dur)
		await _wait(dur)
		if _skip:
			return
	a.state = "idle"


func face(name: String, deg: float) -> void:
	actors[name].rotation.y = deg_to_rad(deg)


## หันหน้าตัวละครไปหาอีกคน (หรือจุดใด ๆ)
func face_to(name: String, target: Variant) -> void:
	var a: CharacterRig = actors[name]
	var p: Vector3 = actors[target].position if target is String else target
	var d := p - a.position
	a.rotation.y = atan2(-d.x, -d.z)


func mood(name: String, m: String) -> void:
	actors[name].react(m)


func shot(pos: Vector3, look: Vector3, fov := 45.0) -> void:
	cam.position = pos
	cam.fov = fov
	cam.look_at(look)


func move_cam(pos: Vector3, look: Vector3, dur: float, fov := -1.0) -> void:
	var p0 := cam.position
	var l0 := cam.position + -cam.global_transform.basis.z * 5.0
	var f0 := cam.fov
	var f1 := cam.fov if fov < 0 else fov
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float):
		cam.position = p0.lerp(pos, v)
		cam.fov = lerpf(f0, f1, v)
		cam.look_at(l0.lerp(look, v)), 0.0, 1.0, dur)


func say(speaker: String, text: String, t := 2.8) -> void:
	if _skip:
		return
	_sub_name.text = speaker
	var col := {"ป้าแดง": Color(1, 0.5, 0.42), "ต้อม": Color(0.5, 0.8, 1.0), "เจ๊หงส์": Color(1, 0.55, 0.8)}
	_sub_name.add_theme_color_override("font_color", col.get(speaker, Color(1, 0.85, 0.4)))
	_sub_text.text = text
	_sub_text.visible_ratio = 0.0
	create_tween().tween_property(_sub_text, "visible_ratio", 1.0, minf(text.length() / 40.0, 1.2))
	await _wait_line(t)
	_sub_text.text = ""
	_sub_name.text = ""


func narrate(text: String, t := 3.0) -> void:
	await say("", text, t)


func title(main: String, sub: String, t := 2.8) -> void:
	if _skip:
		return
	_title.text = main
	_subtitle.text = sub
	_title.modulate.a = 0
	_subtitle.modulate.a = 0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_black, "color:a", 0.75, 0.5)
	tw.tween_property(_title, "modulate:a", 1.0, 0.6)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.9)
	Audio.sfx("star", -4.0, 0.0)
	await _wait_line(t)


func center_text(text: String, t: float) -> void:
	if _skip:
		return
	_center_text.text = text
	_center_text.modulate.a = 0
	create_tween().tween_property(_center_text, "modulate:a", 1.0, 0.8)
	await _wait_line(t)


func fade_black(to: float, t := 0.6) -> void:
	create_tween().tween_property(_black, "color:a", to, t)
	await _wait(t)


func hide_env(names: Array) -> void:
	for n in names:
		var node := stage.get_node_or_null("Env/" + n)
		if node:
			node.visible = false


func confetti(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.05)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	p.mesh = q
	p.amount = 160
	p.lifetime = 3.0
	p.explosiveness = 0.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -3.0, 0)
	p.angular_velocity_min = -300
	p.angular_velocity_max = 300
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 0.4), Color(0.3, 0.6, 1), Color(1, 0.5, 0.9)])
	g.offsets = PackedFloat32Array([0, 0.25, 0.5, 0.75, 1])
	p.color_initial_ramp = g
	actors_root.add_child(p)
	p.position = pos
	p.emitting = true


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_black)
	_top_bar = ColorRect.new()
	_top_bar.color = Color.BLACK
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 64
	layer.add_child(_top_bar)
	_bottom_bar = ColorRect.new()
	_bottom_bar.color = Color.BLACK
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = -120
	layer.add_child(_bottom_bar)

	_sub_name = UiKit.label("", 26, Color(1, 0.85, 0.4))
	_sub_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sub_name.offset_top = -112
	_sub_name.offset_bottom = -78
	_sub_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_sub_name)
	_sub_text = UiKit.label("", 28, Color.WHITE)
	_sub_text.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sub_text.offset_top = -78
	_sub_text.offset_bottom = -20
	_sub_text.offset_left = 80
	_sub_text.offset_right = -80
	_sub_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_sub_text)

	_title = UiKit.label("", 84, UiKit.ORANGE, 14)
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.offset_left = -600
	_title.offset_right = 600
	_title.offset_top = -110
	_title.offset_bottom = 10
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_title)
	_subtitle = UiKit.label("", 40, UiKit.CREAM, 10)
	_subtitle.set_anchors_preset(Control.PRESET_CENTER)
	_subtitle.offset_left = -600
	_subtitle.offset_right = 600
	_subtitle.offset_top = 10
	_subtitle.offset_bottom = 70
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_subtitle)
	_center_text = UiKit.label("", 30, UiKit.CREAM, 8)
	_center_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(_center_text)

	var hint := UiKit.label("Enter ข้ามบรรทัด  •  Esc ข้ามฉาก", 16, Color(1, 1, 1, 0.6))
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -360
	hint.offset_right = -20
	hint.offset_top = 20
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.visible = not standalone
	layer.add_child(hint)


# ======================= คัตซีน =======================

## บท 1: เช้าวันนั้น ป้าแดงล้มป่วย
func _cs_level_1() -> void:
	stage.apply_time_of_day(0)
	Audio.music("calm")
	spawn("daeng", "daeng", Vector3(3.4, 0, -0.4), -90)
	spawn("p1", "office", Vector3(-13, 0, 6.6), -90)
	spawn("p2", "tourist", Vector3(13, 0, 7.3), 90)
	spawn("p3", "rider", Vector3(-15, 0, 7.6), -90)
	walk("p1", [Vector3(13, 0, 6.6)], 1.6)
	walk("p2", [Vector3(-13, 0, 7.3)], 1.3)
	walk("p3", [Vector3(13, 0, 7.6)], 1.9)
	mood("daeng", "pound")
	shot(Vector3(-10, 5.5, 13), Vector3(0, 1.5, -1.5), 45)
	move_cam(Vector3(-3.5, 4.0, 9.0), Vector3(1, 1.6, -1.5), 7.0)
	await narrate("ตลาดเช้าหน้าปากซอย มีร้านส้มตำเล็ก ๆ ร้านหนึ่ง ชื่อ \"ส้มตำป้าแดง\"", 3.6)
	await narrate("ป้าแดงตำส้มตำขายมากว่ายี่สิบปี ไม่เคยปิดร้านสักวัน", 3.4)
	shot(Vector3(5.7, 1.85, -1.5), Vector3(3.4, 1.2, -0.4), 40)
	move_cam(Vector3(5.4, 1.75, -1.25), Vector3(3.4, 1.2, -0.4), 4.0)
	await say("ป้าแดง", "ตำไทยจานนี้ เผ็ดกำลังดีเลย~", 2.6)
	mood("daeng", "dizzy")
	await say("ป้าแดง", "เอ๊ะ... ทำไมโลกมันหมุน ๆ ล่ะ...", 2.8)
	prop("res://assets/models/props/plastic_stool.glb", Vector3(2.6, 0, 0.5))
	mood("daeng", "")
	await walk("daeng", [Vector3(2.6, 0, 0.5)], 0.9)
	face("daeng", 180)
	actors["daeng"].state = "sit"
	mood("daeng", "sad")
	move_cam(Vector3(1.6, 1.4, 2.9), Vector3(2.6, 0.85, 0.5), 2.5)
	await narrate("แต่เช้าวันนั้น... ป้าแดงล้มป่วยกะทันหัน", 3.2)
	await title("บท 1", "วันแรก", 2.8)


## บท 2: วัตถุดิบขาด
func _cs_level_2() -> void:
	stage.apply_time_of_day(1)
	Audio.music("happy")
	hide_env(["Motorbike1"])
	spawn("tom", "tom", Vector3(0.0, 0, 3.3), 180)
	var bike := prop("res://assets/models/props/motorbike.glb", Vector3(-13, 0, 6.3))
	var rider := spawn("rider", "rider", Vector3(0, 0.25, 0), -90)
	actors_root.remove_child(rider)
	bike.add_child(rider)
	rider.position = Vector3(-0.12, 0.3, 0)
	rider.state = "sit"
	shot(Vector3(-6.5, 1.8, 10.0), Vector3(-1.5, 1.0, 5.6), 42)
	var tw := create_tween()
	tw.tween_property(bike, "position", Vector3(-1.6, 0, 6.3), 3.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	walk("tom", [Vector3(-0.3, 0, 3.3), Vector3(-0.3, 0, 5.75)], 1.6)
	await _wait(3.1)
	# ลงจากรถ
	bike.remove_child(rider)
	actors_root.add_child(rider)
	rider.position = Vector3(-1.6, 0, 5.75)
	rider.rotation.y = deg_to_rad(-90)
	rider.state = "idle"
	var papaya := prop("res://assets/models/ingredients/papaya.glb", Vector3(-1.25, 0.65, 5.75), 0, 1.6)
	face("tom", 90)
	move_cam(Vector3(-0.95, 1.35, 8.6), Vector3(-0.95, 0.95, 5.7), 1.5)
	await say("ไรเดอร์", "ส่งของครับ! วันนี้มีแต่มะละกอทั้งลูกนะ เครื่องสับของร้านเสีย", 3.2)
	create_tween().tween_property(papaya, "position", Vector3(-0.65, 0.65, 5.75), 0.4)
	mood("tom", "shock")
	await say("ต้อม", "ห๊ะ!? แล้วผมต้องหั่นเองหมดเลยเหรอ!", 2.6)
	mood("rider", "laugh")
	await say("ไรเดอร์", "สู้ ๆ นะน้อง เดี๋ยวพรุ่งนี้มาใหม่!", 2.4)
	mood("rider", "wave")
	papaya.visible = false
	# ตัดไปที่เขียง
	actors["tom"].position = Vector3(-3.4, 0, -1.6)
	face("tom", 90)
	mood("tom", "pound")
	shot(Vector3(-2.2, 1.8, 0.3), Vector3(-4.0, 1.1, -1.5), 40)
	var whole := prop("res://assets/models/ingredients/papaya_shred.glb", Vector3(-4.2, 0.98, -1.6), 0, 1.2)
	whole.visible = true
	for i in 6:
		Audio.sfx("chop", -2.0)
		await _wait(0.25)
	await say("ต้อม", "หั่นก็หั่น! ร้านป้าแดงต้องไม่หยุดขาย!", 2.6)
	await title("บท 2", "วัตถุดิบขาด", 2.8)


## บท 3: ร้านคู่แข่ง
func _cs_level_3() -> void:
	stage.apply_time_of_day(2)
	Audio.music("game")
	hide_env(["UmbrellaR", "TableR", "StoolR1", "StoolR2", "Tree4", "Motorbike2", "Plant1"])
	var rival := prop("res://assets/models/env/stall.glb", Vector3(10.6, 0, 1.6), -90, 0.55)
	var bulbs := prop("res://assets/models/env/bulbs.glb", Vector3.ZERO)
	actors_root.remove_child(bulbs)
	rival.add_child(bulbs)
	bulbs.position = Vector3.ZERO
	stage.set_emission(bulbs, 6.0)
	var sign := Label3D.new()
	sign.font = Station.THAI_FONT
	sign.text = "ส้มตำเจ๊หงส์"
	sign.font_size = 70
	sign.pixel_size = 0.0095
	sign.modulate = Color(0.85, 0.15, 0.55)
	sign.outline_size = 0
	sign.position = Vector3(0, 3.93, -3.27)
	rival.add_child(sign)
	var neon := OmniLight3D.new()
	neon.light_color = Color(1, 0.4, 0.8)
	neon.light_energy = 2.0
	neon.omni_range = 5.0
	neon.position = Vector3(0, 2.5, 0)
	rival.add_child(neon)
	spawn("hong", "jeh_hong", Vector3(8.6, 0, 1.6), 90)
	spawn("tom", "tom", Vector3(1.2, 0, 3.3), -90)
	spawn("c1", "office", Vector3(3.4 - 0.62, 0, 4.5), -90)
	spawn("c2", "tourist", Vector3(0.62, 0, 4.5), 90)
	spawn("c3", "rider", Vector3(-3.4 + 0.62, 0, 4.5), 90)
	mood("hong", "laugh")
	shot(Vector3(-1.5, 2.4, 5.6), Vector3(8.5, 1.4, 1.8), 42)
	await narrate("ไม่กี่วันต่อมา... มีร้านใหม่มาเปิดฝั่งตรงข้าม", 3.0)
	shot(Vector3(5.4, 1.45, 3.7), Vector3(8.6, 1.1, 1.6), 42)
	await say("เจ๊หงส์", "ร้านเจ๊ตำเร็วกว่า อร่อยกว่า! ลูกค้ามาทางนี้เลยจ้า~", 3.2)
	mood("hong", "wave")
	shot(Vector3(-2.0, 3.2, 7.5), Vector3(4.5, 1.0, 3.0), 45)
	walk("c1", [Vector3(5.5, 0, 4.5), Vector3(7.6, 0, 2.4)], 1.8)
	walk("c2", [Vector3(0.62, 0, 5.4), Vector3(7.4, 0, 3.0)], 1.6)
	walk("c3", [Vector3(-2.8, 0, 5.6), Vector3(7.6, 0, 3.6)], 2.0)
	mood("tom", "shock")
	await say("ต้อม", "เฮ้ย! ลูกค้าเดินไปร้านโน้นหมดเลย!", 2.8)
	shot(Vector3(-0.6, 1.5, 5.4), Vector3(1.2, 1.15, 3.3), 38)
	mood("tom", "angry")
	await say("ต้อม", "ไม่ยอมหรอก! ร้านป้าแดงต้องเร็วกว่า แซ่บกว่า!", 3.0)
	mood("tom", "point")
	await _wait(0.6)
	await title("บท 3", "ร้านคู่แข่ง", 2.8)


func _seat_customers(n: int, happy := true) -> void:
	var seats := stage.get_node("Seats").get_children()
	var models := ["office", "tourist", "rider"]
	for i in mini(n, seats.size()):
		var s: Marker3D = seats[i]
		var c := spawn("seat%d" % i, models[i % 3], s.position, rad_to_deg(s.rotation.y))
		c.state = "sit"
		if happy and i % 2 == 0:
			c.react("laugh")
		prop("res://assets/models/dishes/dish_tam_thai.glb",
			Vector3(s.position.x + (0.3 if s.rotation.y < 0 else -0.3), 0.72, s.position.z))


func _daeng_returns() -> void:
	spawn("daeng", "daeng", Vector3(-13, 0, 6.4), -90)
	await walk("daeng", [Vector3(1.7, 0, 6.4), Vector3(1.7, 0, 3.6), Vector3(1.1, 0, 3.4)], 2.6)
	face("daeng", -90)


func _ending_card(main: String, sub: String) -> void:
	await title(main, sub, 3.4)
	_title.text = ""
	_subtitle.text = ""
	if not standalone:
		await center_text("รีวิวเฉลี่ย %.1f ดาว" % GameState.average_stars(), 2.0)
	await center_text(CREDITS, 7.0)


func _cs_ending_good() -> void:
	stage.apply_time_of_day(1)
	Audio.music("happy")
	_seat_customers(6)
	spawn("tom", "tom", Vector3(2.3, 0, 3.4), 90)
	shot(Vector3(0, 7.0, 13.5), Vector3(0, 1.0, 2.0), 45)
	move_cam(Vector3(0, 5.0, 10.0), Vector3(0, 1.2, 3.0), 6.0)
	await narrate("หนึ่งสัปดาห์ต่อมา... ร้านส้มตำป้าแดงคึกคักกว่าที่เคย", 3.4)
	await _daeng_returns()
	mood("tom", "wave")
	mood("daeng", "shock")
	shot(Vector3(1.7, 1.5, 6.3), Vector3(1.7, 1.05, 3.4), 40)
	await say("ป้าแดง", "โอ้โห! ร้านคึกคักกว่าตอนป้าอยู่อีกนะเนี่ย!", 2.8)
	mood("tom", "happy")
	await say("ต้อม", "ผมฝึกตำทุกวันเลยครับป้า ลูกค้ารีวิวห้าดาวเพียบ!", 3.0)
	mood("tom", "")
	mood("daeng", "")
	await say("ป้าแดง", "งั้นต่อไปนี้... ร้านนี้เป็นของต้อมด้วยนะ", 3.0)
	stage.get_node("Env/ShopName").text = "ส้มตำป้าแดง & ต้อม"
	stage.get_node("Env/ShopName").font_size = 58
	shot(Vector3(0, 2.9, 0.6), Vector3(0, 3.75, -3.3), 48)
	await _wait(1.6)
	confetti(Vector3(0, 3.0, -2.5))
	Audio.sfx("win")
	mood("tom", "happy")
	mood("daeng", "happy")
	move_cam(Vector3(1.7, 2.3, 6.6), Vector3(1.7, 1.3, 3.2), 1.5, 45)
	confetti(Vector3(1.7, 2.5, 3.4))
	await _wait(2.4)
	await _ending_card("ตอนจบ: ทายาทร้านส้มตำ", "ต้อมกลายเป็นเจ้าของร้านร่วมกับป้าแดง")


func _cs_ending_mid() -> void:
	stage.apply_time_of_day(0)
	Audio.music("calm")
	_seat_customers(3)
	spawn("tom", "tom", Vector3(2.3, 0, 3.4), 90)
	shot(Vector3(-3, 5.0, 11.0), Vector3(0, 1.0, 2.5), 45)
	await narrate("หนึ่งสัปดาห์ต่อมา... ป้าแดงหายป่วยกลับมาที่ร้าน", 3.2)
	await _daeng_returns()
	shot(Vector3(1.7, 1.5, 6.3), Vector3(1.7, 1.05, 3.4), 40)
	await say("ป้าแดง", "ร้านยังอยู่ดี ลูกค้าประจำก็ยังมา ทำได้ดีมากนะต้อม", 3.0)
	mood("tom", "sad")
	await say("ต้อม", "แต่ผมยังตำช้าอยู่เลยครับป้า...", 2.6)
	mood("tom", "")
	mood("daeng", "laugh")
	await say("ป้าแดง", "ไม่เป็นไร พรุ่งนี้มาตำด้วยกันนะ ป้าจะสอนเคล็ดลับให้", 3.0)
	# ตำคู่กัน
	actors["tom"].position = Vector3(3.4, 0, -1.6)
	face("tom", -90)
	actors["daeng"].position = Vector3(3.4, 0, -0.4)
	face("daeng", -90)
	mood("tom", "pound")
	mood("daeng", "pound")
	shot(Vector3(1.0, 2.2, 1.2), Vector3(4.0, 1.1, -1.0), 42)
	move_cam(Vector3(1.6, 2.0, 0.6), Vector3(4.0, 1.1, -1.0), 3.0)
	await _wait(3.2)
	await _ending_card("ตอนจบ: ร้านยังอยู่", "ต้อมกับป้าแดงช่วยกันขายต่อไป")


func _cs_ending_bad() -> void:
	stage.apply_time_of_day(2)
	Audio.music("sad")
	# ต้อมนั่งเหงาบนเก้าอี้หน้าร้าน หันหน้าเข้ากล้อง
	prop("res://assets/models/props/plastic_stool.glb", Vector3(1.5, 0, 3.4))
	spawn("tom", "tom", Vector3(1.5, 0, 3.4), 180)
	actors["tom"].state = "sit"
	mood("tom", "sad")
	shot(Vector3(4.5, 4.0, 10.0), Vector3(1.0, 0.8, 4.0), 45)
	move_cam(Vector3(2.6, 2.4, 7.6), Vector3(1.4, 0.9, 3.6), 5.0)
	await narrate("หนึ่งสัปดาห์ต่อมา... ร้านเงียบเหงา ไม่มีลูกค้าสักคน", 3.4)
	spawn("daeng", "daeng", Vector3(-13, 0, 6.4), -90)
	await walk("daeng", [Vector3(1.7, 0, 6.4), Vector3(1.7, 0, 5.2), Vector3(0.6, 0, 4.4)], 2.4)
	face_to("daeng", "tom")
	shot(Vector3(2.9, 1.45, 6.9), Vector3(1.0, 1.0, 3.9), 40)
	await say("ป้าแดง", "ต้อม... วันนี้ไม่มีลูกค้าเลยเหรอ", 2.6)
	face_to("tom", "daeng")
	await say("ต้อม", "ขอโทษครับป้า... ผมทำให้ร้านเงียบ", 2.8)
	mood("daeng", "laugh")
	await say("ป้าแดง", "ไม่เป็นไรหรอก ป้าเองก็เริ่มจากศูนย์ ค่อย ๆ ฝึกไปนะ", 3.2)
	mood("daeng", "")
	actors["tom"].state = "idle"
	actors["tom"].position = Vector3(1.5, 0, 3.75)
	face_to("tom", "daeng")
	mood("tom", "shock")
	await say("ต้อม", "ครับ! พรุ่งนี้ผมจะลองใหม่ ให้ลูกค้ากลับมาให้ได้!", 3.0)
	mood("tom", "wave")
	await _wait(1.0)
	await _ending_card("ตอนจบ: เริ่มต้นใหม่", "ลองเล่นอีกครั้งเพื่อให้ได้รีวิวที่ดีขึ้นนะ")
