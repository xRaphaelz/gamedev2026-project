@tool
class_name Station
extends StaticBody3D
## คลาสแม่ของสถานีทั้งหมด พฤติกรรมพื้นฐาน = เคาน์เตอร์ (วางของได้ 1 ชิ้น)
## คลาสลูก override: interact(), work(), accepts(), status_text(), _build_extra()

const THAI_FONT := preload("res://assets/fonts/Kanit-Medium.ttf")
const HIGHLIGHT := preload("res://assets/materials/highlight.tres")

## โมเดลของสถานี (ถ้าว่างจะใช้กล่องสี)
@export var model: PackedScene:
	set(v):
		model = v
		_rebuild()
## ขนาดกล่องชน
@export var size := Vector3(1.0, 0.9, 1.0):
	set(v):
		if size == v:
			return
		size = v
		_rebuild()
@export var color := Color(0.62, 0.42, 0.25):
	set(v):
		if color == v:
			return
		color = v
		_rebuild()
@export var title := "":
	set(v):
		if title == v:
			return
		title = v
		_rebuild()
## ความสูงที่วางของ
@export var item_height := 0.9

var held: Item = null

var _visual: Node3D
var _title_label: Label3D
var _status_label: Label3D
var _built := false
var _highlighted := false


func _ready() -> void:
	add_to_group("stations")
	_built = true
	_rebuild()


func _rebuild() -> void:
	if not _built:
		return
	for c in get_children():
		if c.has_meta("generated"):
			c.free()

	if model:
		_visual = model.instantiate()
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mi.mesh = box
		mi.position.y = size.y / 2.0
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		mi.material_override = m
		_visual = mi
	_gen(_visual)

	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	shape.position.y = size.y / 2.0
	_gen(shape)

	_title_label = _make_label(22, Color.WHITE)
	_title_label.position = Vector3(0, 0.45, 0.62)
	_title_label.text = title
	_gen(_title_label)

	_status_label = _make_label(24, Color(1, 0.95, 0.6))
	_status_label.position = Vector3(0, size.y + 0.85, 0)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_gen(_status_label)

	_build_extra()
	set_highlight(_highlighted)
	refresh_status()


func _gen(n: Node) -> void:
	n.set_meta("generated", true)
	add_child(n)


func _make_label(font_size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.font = THAI_FONT
	l.font_size = font_size
	l.outline_size = 10
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	l.outline_render_priority = 4
	l.pixel_size = 0.01
	return l


## override เพื่อเพิ่มของตกแต่ง/ชิ้นที่ขยับได้ (เช่น ครก มีด)
func _build_extra() -> void:
	pass


func top_position() -> Vector3:
	return Vector3(0, item_height, 0)


func set_highlight(on: bool) -> void:
	_highlighted = on
	if _visual == null:
		return
	for mi in _meshes(_visual):
		mi.material_overlay = HIGHLIGHT if on else null


static func _meshes(n: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if n is GeometryInstance3D and not n is Label3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func refresh_status() -> void:
	if _status_label:
		_status_label.text = status_text()


func status_text() -> String:
	return ""


# ---------------- การโต้ตอบ ----------------

## กด E ที่สถานี
func interact(player: Player) -> void:
	if player.held and held == null:
		if accepts(player.held):
			place(player.release())
		else:
			GameState.toast("วางที่นี่ไม่ได้")
	elif player.held == null and held:
		player.grab(take())
	elif player.held and held:
		_try_combine(player)
	refresh_status()


## กด Space ที่สถานี (กดรัว)
func work(_player: Player) -> void:
	pass


func accepts(_item: Item) -> bool:
	return true


func place(item: Item) -> void:
	if not Engine.is_editor_hint():
		Audio.sfx("plate" if item.is_plate() else "place", -4.0)
	held = item
	if item.get_parent():
		item.reparent(self, false)
	else:
		add_child(item)
	item.position = top_position()
	item.rotation = Vector3.ZERO
	if not Engine.is_editor_hint():
		Fx.pop(item)
	refresh_status()


func take() -> Item:
	var item := held
	held = null
	refresh_status()
	return item


## ถือจานเปล่า + บนเคาน์เตอร์มีจานที่มีอาหาร (หรือกลับกัน) -> ย้ายอาหาร
func _try_combine(player: Player) -> void:
	var a := player.held
	var b := held
	if a.is_empty_plate() and b.has_dish():
		a.set_dish(b.dish, b.dish_failed, b.spice)
		b.clear_dish()
	elif b.is_empty_plate() and a.has_dish():
		b.set_dish(a.dish, a.dish_failed, a.spice)
		a.clear_dish()
	else:
		GameState.toast("มีของวางอยู่แล้ว")
