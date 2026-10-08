class_name Hud
extends CanvasLayer
## HUD ทั้งหมดสร้างด้วยโค้ด: การ์ดออเดอร์, เวลา, คะแนน, ข้อความแจ้ง, หน้าเริ่มด่าน, หยุดเกม, สรุปผล

signal start_pressed
signal retry_pressed
signal next_pressed
signal menu_pressed
signal resume_pressed

const ORANGE := Color(0.93, 0.45, 0.13)
const CREAM := Color(1.0, 0.96, 0.86)
const DARK := Color(0.2, 0.12, 0.08)

var om: OrderManager

var _orders_box: VBoxContainer
var _time_label: Label
var _score_label: Label
var _toast_label: Label
var _toast_tween: Tween
var _intro: Control
var _intro_title: Label
var _intro_body: Label
var _pause: Control
var _result: Control
var _result_title: Label
var _result_body: Label
var _result_stars: StarRow
var _next_btn: Button
var _result_review: Label
var _combo_label: Label
var _combo_tween: Tween
var _event_banner: PanelContainer
var _event_title: Label
var _event_desc: Label
var _event_chip: Label
var _event_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.toast_requested.connect(_on_toast)


func bind(order_manager: OrderManager) -> void:
	om = order_manager
	om.orders_changed.connect(_rebuild_orders)
	om.score_changed.connect(func(s): _score_label.text = "คะแนน %d" % s)
	om.combo_changed.connect(_on_combo)
	om.event_warning.connect(_on_event_warning)
	om.event_started.connect(_on_event_started)
	om.event_ended.connect(func(_id): _refresh_event_chip())
	_rebuild_orders()


func _process(_delta: float) -> void:
	if om == null:
		return
	var t := int(ceil(om.time_left))
	_time_label.text = "%d:%02d" % [t / 60, t % 60]
	_time_label.modulate = Color(1, 0.4, 0.4) if t <= 30 and om.running else Color.WHITE
	if om.running and not om.active_events.is_empty():
		_refresh_event_chip()
	# อัปเดตแถบเวลาของแต่ละออเดอร์
	for i in min(_orders_box.get_child_count(), om.orders.size()):
		var card := _orders_box.get_child(i)
		var bar := card.get_node("H/V/Bar") as ProgressBar
		var r := om.orders[i].ratio()
		bar.value = r * 100.0
		var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
		fill.bg_color = Color(0.3, 0.75, 0.3).lerp(Color(0.9, 0.2, 0.15), 1.0 - r)


# ---------------- สร้าง UI ----------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ออเดอร์: คอลัมน์ซ้าย / เวลา-คะแนน: มุมขวาบน
	var left := MarginContainer.new()
	left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for side in ["left", "top"]:
		left.add_theme_constant_override("margin_" + side, 14)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)
	_orders_box = VBoxContainer.new()
	_orders_box.add_theme_constant_override("separation", 8)
	left.add_child(_orders_box)

	var panel := _panel(ORANGE)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_set_offsets(panel, -150, 14, -14, 120)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(panel)
	var rv := VBoxContainer.new()
	panel.add_child(rv)
	_time_label = _label("3:00", 34, CREAM)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(_time_label)
	_score_label = _label("คะแนน 0", 22, CREAM)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(_score_label)

	# คอมโบ: ใต้แผงเวลา
	_combo_label = _label("", 34, Color(1, 0.75, 0.2))
	_combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_offsets(_combo_label, -170, 128, -6, 176)
	_combo_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_combo_label.pivot_offset = Vector2(82, 24)
	_combo_label.add_theme_constant_override("outline_size", 10)
	_combo_label.add_theme_color_override("font_outline_color", Color(0.45, 0.12, 0.02))
	root.add_child(_combo_label)

	# ป้ายเตือนเหตุการณ์สุ่ม (กลางจอด้านบน) + ป้ายเล็กตอนเหตุการณ์กำลังเกิด
	_event_banner = _panel(Color(0.18, 0.1, 0.06, 0.92), ORANGE)
	_event_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_set_offsets(_event_banner, -300, 60, 300, 150)
	_event_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var ev := VBoxContainer.new()
	ev.alignment = BoxContainer.ALIGNMENT_CENTER
	_event_banner.add_child(ev)
	_event_title = _label("", 34, Color(1, 0.8, 0.3))
	_event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(_event_title)
	_event_desc = _label("", 20, CREAM)
	_event_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(_event_desc)
	_event_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_banner.hide()
	root.add_child(_event_banner)
	_event_chip = _label("", 22, Color(1, 0.85, 0.4))
	_event_chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_event_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_offsets(_event_chip, -300, 14, 300, 48)
	_event_chip.add_theme_constant_override("outline_size", 8)
	_event_chip.add_theme_color_override("font_outline_color", Color.BLACK)
	root.add_child(_event_chip)

	_toast_label = _label("", 26, Color.WHITE)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_offsets(_toast_label, -400, 150, 400, 190)
	_toast_label.add_theme_constant_override("outline_size", 8)
	_toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	root.add_child(_toast_label)

	var hint := _label("WASD เดิน  •  E หยิบ/วาง/ใช้  •  Space ตำ/หั่น (กดรัว)  •  Esc หยุด", 18, Color(1, 1, 1, 0.85))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_offsets(hint, -450, -44, 450, -12)
	hint.add_theme_constant_override("outline_size", 6)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	root.add_child(hint)

	# หน้าเริ่มด่าน
	var ib := _modal(root)
	_intro = ib[0]
	_intro_title = _label("", 40, ORANGE)
	_intro_body = _label("", 22, DARK)
	_intro_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_body.custom_minimum_size.x = 620
	ib[1].add_child(_intro_title)
	ib[1].add_child(_intro_body)
	ib[1].add_child(UiKit.button("เริ่มขาย! (Enter)", func(): start_pressed.emit()))

	# หยุดเกม
	var pb := _modal(root)
	_pause = pb[0]
	var pt := _label("หยุดชั่วคราว", 40, ORANGE)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pb[1].add_child(pt)
	pb[1].add_child(UiKit.button("เล่นต่อ (Esc)", func(): resume_pressed.emit(), true, 24, 300))
	pb[1].add_child(UiKit.button("เริ่มด่านนี้ใหม่", func(): retry_pressed.emit(), false, 24, 300))
	pb[1].add_child(UiKit.button("กลับเมนูหลัก", func(): menu_pressed.emit(), false, 24, 300))

	# สรุปผล
	var rb := _modal(root)
	_result = rb[0]
	_result_title = _label("ปิดร้าน!", 40, ORANGE)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_stars = StarRow.new()
	_result_body = _label("", 22, DARK)
	rb[1].add_child(_result_title)
	var sc := CenterContainer.new()
	sc.add_child(_result_stars)
	rb[1].add_child(sc)
	_result_review = _label("", 20, Color(0.45, 0.3, 0.2))
	_result_review.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rb[1].add_child(_result_review)
	rb[1].add_child(_result_body)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_child(UiKit.button("เมนู", func(): menu_pressed.emit(), false, 22))
	btns.add_child(UiKit.button("เล่นอีกครั้ง (R)", func(): retry_pressed.emit(), false, 22))
	_next_btn = UiKit.button("ด่านถัดไป (Enter)", func(): next_pressed.emit(), true, 22)
	btns.add_child(_next_btn)
	rb[1].add_child(btns)

	_intro.hide()
	_pause.hide()
	_result.hide()


func _set_offsets(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b


func _modal(root: Control) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var p := _panel(CREAM, ORANGE)
	(p.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(26)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	return [dim, v]


func _panel(bg: Color, border := Color.TRANSPARENT) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	if border.a > 0:
		sb.set_border_width_all(5)
		sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _rebuild_orders() -> void:
	for c in _orders_box.get_children():
		c.queue_free()
		_orders_box.remove_child(c)
	for o in om.orders:
		_orders_box.add_child(_order_card(o))


func _order_card(o: OrderManager.Order) -> Control:
	var p := _panel(CREAM, Color(0.95, 0.72, 0.1) if o.reviewer else o.recipe.dish_color.darkened(0.2))
	p.custom_minimum_size = Vector2(200, 0)
	var h := HBoxContainer.new()
	h.name = "H"
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	if o.recipe.icon:
		var icon := TextureRect.new()
		icon.texture = o.recipe.icon
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(icon)
	var v := VBoxContainer.new()
	v.name = "V"
	h.add_child(v)
	v.add_child(_label(o.recipe.display_name, 20, DARK))
	var spice_on := om.config != null and om.config.spice_enabled
	var ing := _label(o.recipe.ingredient_text(not spice_on), 12, Color(0.35, 0.25, 0.2))
	ing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ing.custom_minimum_size.x = 125
	v.add_child(ing)
	if spice_on:
		var sp := _label(Item.spice_text(o.spice), 15, Color(0.8, 0.15, 0.1) if o.spice > 0 else Color(0.25, 0.55, 0.2))
		v.add_child(sp)
	var who := _label(("★ นักรีวิว (x2)" if o.reviewer else o.customer), 13, Color(0.75, 0.5, 0.0) if o.reviewer else ORANGE.darkened(0.2))
	v.add_child(who)
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.value = o.ratio() * 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.75, 0.3)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)
	return p


# ---------------- หน้าจอต่าง ๆ ----------------

func show_intro(cfg: LevelConfig) -> void:
	_intro_title.text = cfg.level_name
	_intro_body.text = cfg.intro_text + "\n\nเวลา %d นาที  •  เป้าหมาย 5 ดาว: %d คะแนน" % [int(cfg.duration / 60), cfg.target_score]
	_intro.show()


func hide_intro() -> void:
	_intro.hide()


func set_paused(on: bool) -> void:
	_pause.visible = on


const REVIEWS := [
	"",
	"ลูกค้าบ่นอุบ... \"รอนาน รสชาติก็ยังไม่ได้\"",
	"\"พอกินได้ แต่ยังช้าไปหน่อยนะน้อง\"",
	"\"อร่อยดี จะมาอีกนะ\"",
	"\"แซ่บมาก! บอกต่อเพื่อนแน่นอน\"",
	"\"ร้านนี้ต้องลอง! ห้าดาวเต็ม\"",
]


func show_result(score: int, stars: int, stats: Dictionary, has_next: bool, is_last: bool) -> void:
	_result_stars.stars = 0
	var lines := PackedStringArray()
	lines.append("คะแนนรวม %d" % score)
	lines.append("ค่าอาหาร %d  •  ทิป %d  •  โบนัสคอมโบ %d" % [stats.get("food", 0), stats.get("tips", 0), stats.get("combo_bonus", 0)])
	lines.append("เสิร์ฟสำเร็จ %d จาน  •  คอมโบสูงสุด %d  •  ลูกค้ากลับ %d คน  •  ตำมั่ว %d จาน" % [stats.served, stats.get("max_combo", 0), stats.expired, stats.wrong])
	if stats.get("spice_off", 0) > 0:
		lines.append("เผ็ดไม่ตรง %d จาน" % stats.spice_off)
	if not stats.get("events", []).is_empty():
		lines.append("เหตุการณ์วันนี้: " + ", ".join(PackedStringArray(stats.events)))
	_result_body.text = "\n".join(lines)
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_review.text = REVIEWS[clampi(stars, 0, 5)]
	_next_btn.visible = true
	_next_btn.text = "ด่านถัดไป (Enter)" if has_next else "ดูตอนจบ (Enter)"
	_result.show()
	# ดาวขึ้นทีละดวง
	for i in stars:
		await get_tree().create_timer(0.35, true).timeout
		_result_stars.stars = i + 1
		Audio.sfx("star", -3.0)


func _on_combo(count: int, mult: float) -> void:
	if count < 2:
		_combo_label.text = ""
		return
	_combo_label.text = "คอมโบ %d  x%s" % [count, ("%.1f" % mult).trim_suffix(".0")]
	_combo_label.add_theme_color_override("font_color", Color(1, 0.35, 0.15) if mult >= 3.0 else (Color(1, 0.6, 0.15) if mult >= 2.0 else Color(1, 0.82, 0.3)))
	if _combo_tween:
		_combo_tween.kill()
	_combo_label.scale = Vector2.ONE * 1.5
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_event_warning(_id: String, title: String, desc: String) -> void:
	_event_title.text = "เหตุการณ์: " + title
	_event_desc.text = desc
	_event_banner.show()
	_event_banner.modulate.a = 0.0
	if _event_tween:
		_event_tween.kill()
	_event_tween = create_tween()
	_event_tween.tween_property(_event_banner, "modulate:a", 1.0, 0.25)
	_event_tween.tween_interval(3.6)
	_event_tween.tween_property(_event_banner, "modulate:a", 0.0, 0.4)
	_event_tween.tween_callback(_event_banner.hide)


func _on_event_started(_id: String, _duration: float) -> void:
	_refresh_event_chip()


func _refresh_event_chip() -> void:
	var parts := PackedStringArray()
	for id in om.active_events:
		parts.append("%s %d วิ" % [OrderManager.EVENTS[id].title, int(ceil(om.active_events[id]))])
	_event_chip.text = "  •  ".join(parts)


func _on_toast(text: String, good: Variant) -> void:
	_toast_label.text = text
	var c := Color.WHITE
	if good == true:
		c = Color(0.6, 1, 0.5)
	elif good == false:
		c = Color(1, 0.55, 0.45)
	_toast_label.add_theme_color_override("font_color", c)
	_toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)
