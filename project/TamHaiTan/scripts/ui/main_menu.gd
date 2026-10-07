extends Node3D
## เมนูหลัก: ฉากร้านเป็นพื้นหลัง + ปุ่ม เริ่มเกม / เล่นต่อ / เลือกบท / วิธีเล่น / ตั้งค่า

const CHAPTER_SUB := ["เช้าวันแรกที่ร้าน", "ต้องหั่นมะละกอเอง", "ร้านคู่แข่งฝั่งตรงข้าม"]
const TIME_NAMES := ["ตอนเช้า", "ตอนกลางวัน", "ตอนเย็น"]

@onready var stage: Node3D = $Stage
@onready var cam: Camera3D = $Camera3D
@onready var actors: Node3D = $Actors

var _ui: Control
var _main_box: Control
var _panels := {}
var _t := 0.0


func _ready() -> void:
	GameState.phase = GameState.Phase.INTRO
	stage.apply_time_of_day(2)
	stage.hide_station_labels()
	_set_scene()
	_build_ui()
	Audio.music("menu")


func _process(delta: float) -> void:
	_t += delta
	cam.position = Vector3(-1.2 + sin(_t * 0.12) * 1.2, 5.2, 10.5)
	cam.look_at(Vector3(-2.6 + sin(_t * 0.12) * 0.6, 1.2, 0.0))


func _set_scene() -> void:
	var tom := _actor("tom", Vector3(3.4, 0, -1.6), -90)
	tom.react("pound")
	var daeng := _actor("daeng", Vector3(1.6, 0, 3.3), 0)
	daeng.react("wave")
	var seats := stage.get_node("Seats").get_children()
	var who := ["office", "tourist", "rider", "office"]
	for i in [2, 3, 4, 5]:
		var s: Marker3D = seats[i]
		var c := _actor(who[i - 2], s.position, rad_to_deg(s.rotation.y))
		c.state = "sit"
		if i % 2:
			c.react("laugh")


func _actor(ch: String, pos: Vector3, deg: float) -> CharacterRig:
	var r := CharacterRig.new()
	r.character = ch
	actors.add_child(r)
	r.position = pos
	r.rotation.y = deg_to_rad(deg)
	return r


# ---------------- UI ----------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)

	# แถบไล่สีด้านซ้ายให้อ่านง่าย
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.12, 0.05, 0.02, 0.85), Color(0.12, 0.05, 0.02, 0.0)])
	grad.gradient = g
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(1, 0)
	shade.texture = grad
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 640
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = 70
	col.offset_right = 520
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	_ui.add_child(col)
	_main_box = col

	var logo := UiKit.label("ตำให้ทัน!", 96, UiKit.ORANGE, 18)
	col.add_child(logo)
	var tag := UiKit.label("เกมร้านส้มตำริมทาง  •  ช่วยต้อมเฝ้าร้านแทนป้าแดง", 22, UiKit.CREAM, 6)
	col.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	col.add_child(gap)

	var has_progress := not GameState.best_stars.is_empty()
	if has_progress:
		col.add_child(UiKit.button("เล่นต่อ", _continue, true, 28, 340))
	col.add_child(UiKit.button("เริ่มเกมใหม่", func(): GameState.new_game(), not has_progress, 28, 340))
	col.add_child(UiKit.button("เลือกบท", func(): _open("levels"), false, 26, 340))
	col.add_child(UiKit.button("วิธีเล่น", func(): _open("howto"), false, 26, 340))
	col.add_child(UiKit.button("ตั้งค่า", func(): _open("settings"), false, 26, 340))
	if not OS.has_feature("web"):
		col.add_child(UiKit.button("ออกจากเกม", func(): get_tree().quit(), false, 22, 340))

	_panels["levels"] = _levels_panel()
	_panels["howto"] = _howto_panel()
	_panels["settings"] = _settings_panel()
	for p in _panels.values():
		p.hide()


func _continue() -> void:
	var i := 0
	for k in GameState.LEVELS.size():
		if GameState.is_unlocked(k):
			i = k
	GameState.start_level(i)


func _open(name: String) -> void:
	_main_box.hide()
	for k in _panels:
		_panels[k].visible = k == name
	if name == "levels":
		_panels["levels"].queue_free()
		_panels["levels"] = _levels_panel()


func _close() -> void:
	for p in _panels.values():
		p.hide()
	_main_box.show()


func _overlay(title: String) -> Array:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var p := UiKit.panel(UiKit.CREAM, UiKit.ORANGE, 28)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	var t := UiKit.label(title, 44, UiKit.ORANGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	return [center, v]


func _back_button() -> Control:
	var c := CenterContainer.new()
	c.add_child(UiKit.button("กลับ", _close, false, 22, 200))
	return c


func _levels_panel() -> Control:
	var o := _overlay("เลือกบท")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	o[1].add_child(row)
	for i in GameState.LEVELS.size():
		var lv: LevelConfig = GameState.LEVELS[i]
		var unlocked := GameState.is_unlocked(i)
		var card := UiKit.panel(Color(1, 0.99, 0.95) if unlocked else Color(0.85, 0.82, 0.78), UiKit.ORANGE.darkened(0.1) if unlocked else Color(0.6, 0.55, 0.5), 16)
		card.custom_minimum_size = Vector2(250, 0)
		row.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		card.add_child(v)
		v.add_child(UiKit.label("บท %d" % (i + 1), 22, UiKit.ORANGE.darkened(0.15)))
		var nm := UiKit.label(lv.level_name.get_slice(": ", 1), 28, UiKit.DARK)
		v.add_child(nm)
		v.add_child(UiKit.label("%s  •  %s" % [CHAPTER_SUB[i], TIME_NAMES[lv.time_of_day]], 15, Color(0.4, 0.3, 0.2)))
		var icons := HBoxContainer.new()
		for r in lv.recipes:
			var tr := TextureRect.new()
			tr.texture = r.icon
			tr.custom_minimum_size = Vector2(54, 54)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icons.add_child(tr)
		v.add_child(icons)
		var stars := StarRow.new()
		stars.star_size = 26
		stars.custom_minimum_size = Vector2(26 * 5 + 32, 26)
		stars.stars = int(GameState.best_stars.get(i, 0))
		v.add_child(stars)
		if unlocked:
			v.add_child(UiKit.button("เล่น", func(): GameState.start_level(i), true, 22))
		else:
			var lock := UiKit.label("ผ่านบทก่อนหน้าก่อน", 16, Color(0.45, 0.4, 0.35))
			v.add_child(lock)
	if GameState.best_stars.has(GameState.LEVELS.size() - 1):
		var c := CenterContainer.new()
		c.add_child(UiKit.button("ดูตอนจบ (รีวิวเฉลี่ย %.1f ดาว)" % GameState.average_stars(), func(): GameState.go_ending(), true, 22))
		o[1].add_child(c)
	o[1].add_child(_back_button())
	if not _main_box.visible:
		o[0].show()
	return o[0]


func _howto_panel() -> Control:
	var o := _overlay("วิธีเล่น")
	var txt := UiKit.label(
		"ปุ่มควบคุม\n" +
		"   WASD / ลูกศร  เดิน\n" +
		"   E  หยิบ / วาง / ใช้สถานี\n" +
		"   Space  ตำ หรือ หั่น (กดรัว ๆ)\n" +
		"   Esc  หยุดเกม\n\n" +
		"ขั้นตอนทำส้มตำ\n" +
		"   1. หยิบวัตถุดิบตามออเดอร์ (ด้านหลังร้าน)\n" +
		"   2. มะละกอต้องหั่นที่เขียงก่อน (ตั้งแต่บท 2)\n" +
		"   3. ใส่ของลงครก แล้วกด Space ตำจนเสร็จ\n" +
		"   4. หยิบจานเปล่า กด E ที่ครกเพื่อตักใส่จาน\n" +
		"   5. นำไปวางที่จุดเสิร์ฟ (ผ้าลายแดง)\n\n" +
		"ลูกค้าแต่ละคนรอได้ไม่เท่ากัน: ไรเดอร์ใจร้อนที่สุด นักท่องเที่ยวใจเย็นที่สุด\n" +
		"ใส่ของผิดสูตรจะได้ \"ส้มตำมั่ว\" และโดนหักคะแนน\n" +
		"ดาวรีวิวเฉลี่ยของทุกบท จะตัดสินตอนจบของเรื่อง", 20, UiKit.DARK)
	o[1].add_child(txt)
	o[1].add_child(_back_button())
	return o[0]


func _on_reset(b: Button) -> void:
	if b.text == "แน่ใจไหม? กดอีกครั้งเพื่อล้าง":
		GameState.reset_progress()
		b.text = "ล้างแล้ว"
	else:
		b.text = "แน่ใจไหม? กดอีกครั้งเพื่อล้าง"


func _settings_panel() -> Control:
	var o := _overlay("ตั้งค่า")
	for item in [["เพลง", "Music"], ["เสียงประกอบ", "SFX"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var l := UiKit.label(item[0], 24, UiKit.DARK)
		l.custom_minimum_size.x = 160
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.custom_minimum_size = Vector2(320, 32)
		s.value = GameState.music_volume if item[1] == "Music" else GameState.sfx_volume
		var bus: String = item[1]
		s.value_changed.connect(func(v: float):
			if bus == "Music":
				GameState.music_volume = v
			else:
				GameState.sfx_volume = v
				Audio.sfx("click")
			Audio.set_volume(bus, v)
			GameState.save())
		row.add_child(s)
		o[1].add_child(row)
	var reset_btn := UiKit.button("ล้างความคืบหน้า", func(): pass, false, 20)
	reset_btn.pressed.connect(_on_reset.bind(reset_btn))
	var c := CenterContainer.new()
	c.add_child(reset_btn)
	o[1].add_child(c)
	o[1].add_child(_back_button())
	return o[0]
