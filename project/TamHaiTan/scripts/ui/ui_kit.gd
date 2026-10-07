class_name UiKit
## ชุดสไตล์ UI ร่วมของทั้งเกม (ปุ่ม แผง ป้าย) โทนร้านส้มตำ: ส้ม-ครีม-น้ำตาล

const ORANGE := Color(0.93, 0.45, 0.13)
const RED := Color(0.78, 0.2, 0.15)
const CREAM := Color(1.0, 0.96, 0.86)
const DARK := Color(0.2, 0.12, 0.08)
const GREEN := Color(0.24, 0.56, 0.23)


static func _box(bg: Color, radius := 14, border := Color.TRANSPARENT, bw := 0, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if bw > 0:
		sb.set_border_width_all(bw)
		sb.border_color = border
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 3)
	return sb


## ปุ่มหลัก (primary = สีส้ม, ไม่งั้นเป็นสีครีมขอบส้ม)
static func button(text: String, cb: Callable, primary := true, font_size := 24, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	var base := ORANGE if primary else CREAM
	var fg := CREAM if primary else DARK
	for st in ["normal", "hover", "pressed", "disabled"]:
		var c := base
		if st == "hover":
			c = base.lightened(0.12)
		elif st == "pressed":
			c = base.darkened(0.15)
		elif st == "disabled":
			c = Color(0.6, 0.58, 0.55)
		var sb := _box(c, 16, ORANGE.darkened(0.25), 3, 4 if st != "pressed" else 0)
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 8
		sb.content_margin_bottom = 10
		b.add_theme_stylebox_override(st, sb)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(0.9, 0.9, 0.9))
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(func():
		Audio.sfx("click")
		cb.call())
	b.mouse_entered.connect(func(): Audio.sfx("hover", -6.0))
	b.pivot_offset = Vector2(80, 24)
	return b


static func panel(bg := CREAM, border := ORANGE, margin := 24) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _box(bg, 18, border, 5 if border.a > 0 else 0, 8)
	sb.set_content_margin_all(margin)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func label(text: String, font_size: int, color := DARK, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.15, 0.06, 0.02))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
