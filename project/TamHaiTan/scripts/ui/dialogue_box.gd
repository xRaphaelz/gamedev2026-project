class_name DialogueBox
extends CanvasLayer
## กล่องบทสนทนา: ตัวอักษรค่อย ๆ ขึ้น / Enter, Space, คลิก = ไปต่อ / Esc = ข้ามทั้งหมด
## ใช้ซ้ำได้ทุกบท: play(dialogue) แล้วรอสัญญาณ finished

signal finished

const NARRATOR := "บรรยาย"
## สีประจำตัวละคร (ใช้เป็นรูปชั่วคราวจนกว่าจะมีภาพจริง)
const SPEAKERS := {
	"ป้าแดง": {"color": Color(0.85, 0.22, 0.18), "side": "left", "portrait": "res://assets/icons/portrait_daeng.png"},
	"ต้อม": {"color": Color(0.2, 0.55, 0.85), "side": "right", "portrait": "res://assets/icons/portrait_tom.png"},
}
const CHARS_PER_SEC := 45.0
const CREAM := Color(1.0, 0.96, 0.86)
const ORANGE := Color(0.93, 0.45, 0.13)
const DARK := Color(0.2, 0.12, 0.08)

var _dialogue: Dialogue
var _index := -1
var _typing: Tween

var _dim: ColorRect
var _title: Label
var _narration: Label
var _box: PanelContainer
var _name_label: Label
var _text: Label
var _portrait_l: TextureRect
var _portrait_r: TextureRect
var _hint: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func play(d: Dialogue) -> void:
	_dialogue = d
	_index = -1
	_title.text = d.title
	show()
	_advance()


func is_playing() -> bool:
	return visible


func skip() -> void:
	if not visible:
		return
	if _typing:
		_typing.kill()
	hide()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var next: bool = event.is_action_pressed("confirm") or event.is_action_pressed("interact") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		skip()
	elif next:
		get_viewport().set_input_as_handled()
		_on_next()


func _on_next() -> void:
	var label := _current_label()
	if label and label.visible_ratio < 1.0:
		# กดระหว่างตัวอักษรกำลังขึ้น = แสดงทั้งบรรทัดทันที
		if _typing:
			_typing.kill()
		label.visible_ratio = 1.0
	else:
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= _dialogue.lines.size():
		skip()
		return
	var parts := Dialogue.split_line(_dialogue.lines[_index])
	var speaker: String = parts[0]
	var text: String = parts[1]

	var narrator := speaker == NARRATOR or not SPEAKERS.has(speaker)
	_narration.visible = narrator
	_box.visible = not narrator
	_dim.color = Color(0.08, 0.05, 0.03, 0.88 if narrator else 0.45)
	_title.visible = narrator and _index == 0

	if narrator:
		_narration.text = text
		_portrait_l.hide()
		_portrait_r.hide()
	else:
		var info: Dictionary = SPEAKERS[speaker]
		_name_label.text = speaker
		_name_label.add_theme_color_override("font_color", info.color.darkened(0.2))
		_text.text = text
		var left: bool = info.side == "left"
		_set_portrait(_portrait_l, info, left)
		_set_portrait(_portrait_r, info, not left)

	var label := _current_label()
	label.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(label, "visible_ratio", 1.0, maxf(text.length() / CHARS_PER_SEC, 0.2))
	_hint.text = "Enter / Space ไปต่อ  •  Esc ข้าม   (%d/%d)" % [_index + 1, _dialogue.lines.size()]


func _current_label() -> Label:
	return _narration if _narration.visible else _text


func _set_portrait(p: TextureRect, info: Dictionary, active: bool) -> void:
	p.visible = active
	if active and info.has("portrait"):
		p.texture = load(info.portrait)


# ---------------- สร้าง UI ----------------

func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_title = _label("", 52, ORANGE)
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.offset_left = -400
	_title.offset_right = 400
	_title.offset_top = 150
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)

	_narration = _label("", 30, CREAM)
	_narration.set_anchors_preset(Control.PRESET_FULL_RECT)
	_narration.offset_left = 160
	_narration.offset_right = -160
	_narration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narration.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_narration.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_narration)

	_portrait_l = _portrait()
	_portrait_l.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_portrait_l.offset_left = 50
	_portrait_l.offset_right = 370
	_portrait_l.offset_top = -500
	_portrait_l.offset_bottom = -180
	add_child(_portrait_l)

	_portrait_r = _portrait()
	_portrait_r.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_portrait_r.offset_left = -370
	_portrait_r.offset_right = -50
	_portrait_r.offset_top = -500
	_portrait_r.offset_bottom = -180
	_portrait_r.flip_h = true
	add_child(_portrait_r)

	_box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(5)
	sb.border_color = ORANGE
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 16
	sb.content_margin_bottom = 20
	_box.add_theme_stylebox_override("panel", sb)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 40
	_box.offset_right = -40
	_box.offset_top = -220
	_box.offset_bottom = -50
	add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_box.add_child(v)
	_name_label = _label("", 30, ORANGE)
	v.add_child(_name_label)
	_text = _label("", 26, DARK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text)

	_hint = _label("", 18, Color(1, 1, 1, 0.8))
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -520
	_hint.offset_right = -44
	_hint.offset_top = -42
	_hint.offset_bottom = -12
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(_hint)


func _portrait() -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
