extends Node3D
## Lab 6 demo: shows the Blender-made character driven by the
## OpenAnimationLibraries Melee + Shooter libraries through the Mixamo bone map.

const FONT_R := preload("res://Assets/Fonts/Sarabun-Regular.ttf")
const FONT_B := preload("res://Assets/Fonts/Sarabun-Bold.ttf")
const IDLE := "Melee/LightIdle"

const FEATURED := {
	"Melee": [
		["ยืนพัก", "LightIdle"], ["เดิน", "LightWalking"], ["วิ่ง", "LightRunning"], ["วิ่งเร็ว", "Sprint"],
		["กระโดด", "Jump"], ["กลิ้งหลบ", "Roll"], ["ฟัน 1", "Slash1"], ["ฟัน 2", "Slash2"],
		["ฟัน 3", "Slash3"], ["ท่าหนัก", "Heavy1"], ["หมุนตัวฟัน", "HeavySpin"], ["แทง", "Stab1"],
		["ตั้งการ์ด", "Guarding"], ["ชนโล่", "ShieldBash"], ["โดนตี", "Hurt1"], ["ดื่มยา", "UsePotion"],
		["เปิดหีบ", "OpenChest"], ["ล้ม", "Die1"],
	],
	"Shooter": [
		["ยืน", "idle"], ["เดิน", "walk"], ["วิ่ง", "run_067"], ["ย่อเดิน", "crouch-walk"],
		["หมอบคลาน", "prone-crawl"], ["ย่อง", "sneak-walk"], ["เล็งปืน", "aim-rifle"], ["รีโหลด", "reload-rifle"],
		["ต่อย", "punch1"], ["เตะ", "kick1"], ["ยกมือยอม", "handsup-idle"], ["ยักไหล่", "search-shrug"],
		["ตกใจ", "search-surprise"], ["ปีนข้าม", "vault-generic"], ["ขว้างระเบิด", "throw-grenade-"], ["ล้ม", "die1"],
	],
}
const LOOP_HINTS := ["idle", "Idle", "walk", "Walk", "run", "Run", "Sprint", "crawl", "Guarding", "strafe", "Strafe"]

@onready var anim: AnimationPlayer = $Character/AnimationPlayer
@onready var orbit = $CameraRig

var all_names: Array[String] = []
var featured_flat: Array[String] = []
var current := ""
var showcase := false
var _showcase_timer := 0.0

var now_label: Label
var sub_label: Label
var picker: OptionButton
var showcase_btn: Button
var rotate_btn: Button
var buttons := {}


func _ready() -> void:
	anim.add_animation_library("Melee", load("res://Animations/MeleeLib.res"))
	anim.add_animation_library("Shooter", load("res://Animations/ShooterLib.res"))
	for lib_name in ["Melee", "Shooter"]:
		var lib := anim.get_animation_library(lib_name)
		for n in lib.get_animation_list():
			var s := String(n)
			if s.begins_with("root-") or s.contains("mixamo_com"):
				continue          # root-motion duplicates / source take
			all_names.append("%s/%s" % [lib_name, s])
			var a := lib.get_animation(n)
			a.loop_mode = Animation.LOOP_LINEAR if _is_loop(s) else Animation.LOOP_NONE
	for lib_name in FEATURED:
		for pair in FEATURED[lib_name]:
			featured_flat.append("%s/%s" % [lib_name, pair[1]])
	anim.animation_finished.connect(_on_finished)
	_build_ui()
	play(IDLE)
	_add_cover()


# ปิดจอไว้ช่วงแรกระหว่างที่ shader คอมไพล์ จะได้ไม่เห็นภาพกระตุก
func _add_cover() -> void:
	var layer := CanvasLayer.new(); layer.layer = 100; add_child(layer)
	var cover := ColorRect.new(); cover.color = Color(0.06, 0.06, 0.1)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT); cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cover)
	for i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var tw := create_tween()
	tw.tween_property(cover, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)


func _is_loop(n: String) -> bool:
	if n.contains("die") or n.contains("Die") or n.contains("dead"):
		return n.contains("idle")
	for h in LOOP_HINTS:
		if n.contains(h):
			return true
	return false


func play(full_name: String) -> void:
	if not anim.has_animation(full_name):
		push_warning("missing animation " + full_name)
		return
	current = full_name
	anim.play(full_name, 0.25)
	var parts := full_name.split("/")
	now_label.text = _thai_name(full_name)
	sub_label.text = "%s  ·  %s  ·  %.1f วินาที%s" % [parts[0], parts[1], anim.current_animation_length,
		"  ·  วนซ้ำ" if anim.get_animation(full_name).loop_mode != Animation.LOOP_NONE else ""]
	for k in buttons:
		(buttons[k] as Button).button_pressed = (k == full_name)
	var idx := all_names.find(full_name)
	if idx >= 0:
		picker.select(idx)
	_showcase_timer = 0.0


func _thai_name(full_name: String) -> String:
	var parts := full_name.split("/")
	if FEATURED.has(parts[0]):
		for pair in FEATURED[parts[0]]:
			if pair[1] == parts[1]:
				return pair[0]
	return parts[1]


func _on_finished(anim_name: StringName) -> void:
	if showcase:
		_step(1)
	elif not String(anim_name).to_lower().contains("die"):
		play(IDLE)


func _step(dir: int) -> void:
	var list := featured_flat if showcase else all_names
	var i := list.find(current)
	i = wrapi(i + dir, 0, list.size())
	play(list[i])


func _process(delta: float) -> void:
	if showcase:
		_showcase_timer += delta
		var a := anim.get_animation(current)
		if a and a.loop_mode != Animation.LOOP_NONE and _showcase_timer > 3.5:
			_step(1)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT, KEY_D: _step(1)
			KEY_LEFT, KEY_A: _step(-1)
			KEY_SPACE: _toggle_showcase()


func _toggle_showcase() -> void:
	showcase = not showcase
	showcase_btn.button_pressed = showcase
	if showcase:
		play(featured_flat[0])


# ------------------------------------------------------------------ UI

func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_B if bold else FONT_R)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _style(bg: Color, border := Color(1, 1, 1, 0.10), radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14; sb.content_margin_right = 14
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb


func _chip(text: String, full_name: String, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FONT_R)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(0.86, 0.89, 0.96))
	b.add_theme_color_override("font_pressed_color", Color(0.05, 0.06, 0.1))
	b.add_theme_color_override("font_hover_pressed_color", Color(0.05, 0.06, 0.1))
	b.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.12), 9))
	b.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.11), accent, 9))
	b.add_theme_stylebox_override("pressed", _style(accent, accent, 9))
	b.add_theme_stylebox_override("hover_pressed", _style(accent.lightened(0.1), accent, 9))
	b.pressed.connect(func(): showcase = false; showcase_btn.button_pressed = false; play(full_name))
	buttons[full_name] = b
	return b


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var rootc := Control.new()
	rootc.set_anchors_preset(Control.PRESET_FULL_RECT)
	rootc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rootc)

	# ---- left panel: featured moves
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.06, 0.10, 0.78), Color(1, 1, 1, 0.08), 16))
	panel.anchor_top = 0; panel.anchor_bottom = 1
	panel.offset_left = 16; panel.offset_top = 16; panel.offset_bottom = -16; panel.offset_right = 16 + 330
	rootc.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)

	col.add_child(_label("LAB 06 · CHARACTER ANIMATION", 12, Color(0.45, 0.88, 0.82), true))
	col.add_child(_label("Character Demo", 21, Color(0.95, 0.96, 1.0), true))

	var accents := {"Melee": Color(1.0, 0.62, 0.42), "Shooter": Color(0.45, 0.88, 0.82)}
	for lib_name in ["Melee", "Shooter"]:
		var head := _label("%s  —  %d ท่าเด่น" % [lib_name, FEATURED[lib_name].size()], 15, accents[lib_name], true)
		col.add_child(head)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		col.add_child(grid)
		for pair in FEATURED[lib_name]:
			var full_name := "%s/%s" % [lib_name, pair[1]]
			if anim.has_animation(full_name):
				var chip := _chip(pair[0], full_name, accents[lib_name])
				chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(chip)

	col.add_child(_label("ท่าทั้งหมด (%d ท่า)" % all_names.size(), 15, Color(0.8, 0.84, 0.95), true))
	picker = OptionButton.new()
	picker.add_theme_font_override("font", FONT_R)
	picker.add_theme_font_size_override("font_size", 14)
	picker.focus_mode = Control.FOCUS_NONE
	for n in all_names:
		picker.add_item(n)
	picker.item_selected.connect(func(i): showcase = false; showcase_btn.button_pressed = false; play(all_names[i]))
	col.add_child(picker)

	# ---- bottom bar: now playing + controls
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _style(Color(0.05, 0.06, 0.10, 0.78), Color(1, 1, 1, 0.08), 16))
	bar.anchor_left = 0; bar.anchor_right = 1; bar.anchor_top = 1; bar.anchor_bottom = 1
	bar.offset_left = 16 + 330 + 16; bar.offset_right = -16; bar.offset_top = -96; bar.offset_bottom = -16
	rootc.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	now_label = _label("", 26, Color(1, 1, 1), true)
	sub_label = _label("", 13, Color(0.62, 0.67, 0.78))
	info.add_child(now_label); info.add_child(sub_label)

	var prev_b := _ctrl_button("◀  ก่อนหน้า"); prev_b.pressed.connect(func(): _step(-1)); row.add_child(prev_b)
	var next_b := _ctrl_button("ถัดไป  ▶"); next_b.pressed.connect(func(): _step(1)); row.add_child(next_b)
	showcase_btn = _ctrl_button("โชว์อัตโนมัติ", true)
	showcase_btn.pressed.connect(_toggle_showcase)
	row.add_child(showcase_btn)
	rotate_btn = _ctrl_button("หมุนกล้อง", true)
	rotate_btn.button_pressed = true
	rotate_btn.toggled.connect(func(on): orbit.auto_rotate = on)
	row.add_child(rotate_btn)

	var hint := _label("ลาก = หมุน · ล้อเมาส์ = ซูม · ←/→ = เปลี่ยนท่า", 13, Color(0.60, 0.64, 0.76))
	hint.anchor_left = 1; hint.anchor_right = 1
	hint.offset_left = -520; hint.offset_right = -20; hint.offset_top = 18
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rootc.add_child(hint)


func _ctrl_button(text: String, toggle := false) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_override("font", FONT_B)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	b.add_theme_color_override("font_pressed_color", Color(0.05, 0.06, 0.1))
	b.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.14), 11))
	b.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.3), 11))
	b.add_theme_stylebox_override("pressed", _style(Color(0.55, 0.48, 1.0), Color(0.55, 0.48, 1.0), 11))
	return b
