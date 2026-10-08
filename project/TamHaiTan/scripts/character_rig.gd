@tool
class_name CharacterRig
extends Node3D
## โหลดโมเดลตัวละคร (.glb จาก tools/blender/chars.py) แล้วขยับข้อต่อด้วยโค้ด
## สถานะ: idle / walk / sit  + ตัวเลือก carrying (ถือของ) และ pulse_work() (ท่าตำ/หั่น)

@export_enum("tom", "daeng", "rider", "office", "tourist", "jeh_hong") var character := "tom":
	set(v):
		character = v
		_load_model()

var state := "idle"
var carrying := false
## อารมณ์/ท่าพิเศษ: happy, angry, sad, wave, shock, dizzy, laugh, point, pound (ตำครกวนไป), chop (หั่นวนไป)
var mood := ""

## ตำแหน่งมือเทียบกับข้อต่อไหล่ (จาก tools/blender/chars.py)
const HAND_OFFSET := Vector3(0.01, -0.29, -0.01)
## มุมแขนตอนหัวสากกระแทกก้นครก / ตอนยกสากสุด / มุมโน้มตัว / มุมเอียงสาก
const POUND_STRIKE := 1.2
const POUND_RAISE := 2.8
const POUND_LEAN := -0.18
const PESTLE_TILT := 0.3
## จุดที่หัวสากกระแทก เทียบกับเท้าตัวละคร: (ขวา, สูง, หน้า) — ครกต้องอยู่ตรงนี้
const POUND_REACH := Vector3(0.265, 0.25, 0.46)

var _model: Node3D
var _parts := {}
var _t := 0.0
var _work := 0.0
var _mood_t := 0.0
var _tool := ""
var _tool_hold := 0.0
var _pestle: Node3D


func _ready() -> void:
	_load_model()


func _load_model() -> void:
	if not is_inside_tree():
		return
	if _model:
		_model.queue_free()
		_model = null
	_pestle = null
	var path := "res://assets/models/characters/%s.glb" % character
	if not ResourceLoader.exists(path):
		return
	_model = (load(path) as PackedScene).instantiate()
	_model.set_meta("generated", true)
	add_child(_model)
	if not Engine.is_editor_hint():
		Stylize.apply(_model, true)
	_parts.clear()
	for n in ["Torso", "Head", "ArmL", "ArmR", "LegL", "LegR"]:
		_parts[n] = _model.find_child(n, true, false)
	_t = randf() * 10.0


## กด Space ที่สถานี 1 ครั้ง: tool = "pestle" ตำ (ถือสากในมือ) / "" ท่าหั่น
func pulse_work(tool := "") -> void:
	_work = 1.0
	_tool = tool
	_tool_hold = 0.75 if tool != "" else 0.0


func is_pounding() -> bool:
	return mood == "pound" or (_tool == "pestle" and _tool_hold > 0.0)


## แว่นดำ (นักรีวิวแฝงตัว)
func add_sunglasses() -> void:
	var head: Node3D = _parts.get("Head")
	if head == null or head.has_node("Sunglasses"):
		return
	var g := Node3D.new()
	g.name = "Sunglasses"
	head.add_child(g)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.05, 0.07)
	m.metallic = 0.6
	m.roughness = 0.2
	for spec in [[Vector3(-0.09, 0.225, -0.25), Vector3(0.11, 0.07, 0.02)], [Vector3(0.09, 0.225, -0.25), Vector3(0.11, 0.07, 0.02)], [Vector3(0, 0.235, -0.25), Vector3(0.08, 0.015, 0.015)]]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = spec[1]
		mi.mesh = b
		mi.material_override = m
		mi.position = spec[0]
		g.add_child(mi)


func react(m: String) -> void:
	mood = m
	_mood_t = 0.0
	if _model and m == "":
		_model.rotation = Vector3.ZERO


## สากในมือขวา: หมุนสวนทางกับแขน ให้แกนสากเกือบตั้งตรงในโลก จับที่ด้ามด้านบน
func _ensure_pestle() -> void:
	if _pestle or _parts.get("ArmR") == null:
		return
	_pestle = Node3D.new()
	_pestle.name = "HandPestle"
	_pestle.position = HAND_OFFSET
	_parts["ArmR"].add_child(_pestle)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.78, 0.63, 0.42)
	wood.roughness = 0.7
	var shaft := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.026
	c.bottom_radius = 0.032
	c.height = 0.36
	c.radial_segments = 10
	shaft.mesh = c
	shaft.material_override = wood
	shaft.position.y = -0.1
	_pestle.add_child(shaft)
	var head := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.046
	s.height = 0.12
	s.radial_segments = 10
	s.rings = 6
	head.mesh = s
	var hm := wood.duplicate() as StandardMaterial3D
	hm.albedo_color = Color(0.68, 0.52, 0.33)
	head.material_override = hm
	head.position.y = -0.29
	_pestle.add_child(head)
	if not Engine.is_editor_hint():
		Stylize.apply(_pestle, true)
	_pestle.visible = false


func _process(delta: float) -> void:
	if _model == null or _parts.is_empty() or _parts["ArmL"] == null:
		return
	_t += delta
	_work = maxf(_work - delta * 5.0, 0.0)
	_tool_hold = maxf(_tool_hold - delta, 0.0)
	var arm_l := 0.0
	var arm_r := 0.0
	var leg_l := 0.0
	var leg_r := 0.0
	var bob := 0.0
	var head_x := sin(_t * 1.7) * 0.04
	var arm_z := 0.0
	var arm_l_z := 0.0
	var lean := 0.0

	match state:
		"walk":
			var s := sin(_t * 13.0)
			leg_l = s * 0.65
			leg_r = -s * 0.65
			arm_l = -s * 0.55
			arm_r = s * 0.55
			bob = absf(sin(_t * 13.0)) * 0.05
		"sit":
			leg_l = 1.45
			leg_r = 1.45
			arm_l = 0.7 + sin(_t * 2.0) * 0.05
			arm_r = 0.7 + sin(_t * 2.0 + 1.0) * 0.05
			bob = 0.09
		_:
			arm_z = sin(_t * 2.0) * 0.04
			bob = sin(_t * 2.0) * 0.008

	if carrying:
		arm_l = 1.35
		arm_r = 1.35

	var pounding := is_pounding() and not carrying
	if pounding:
		# ตำ: กดปุ่ม = สากกระแทกทันที แล้วค่อยยกกลับขึ้น / ท่าวน (คัตซีน) = ขึ้นลงเป็นจังหวะ
		var up := 0.0
		if mood == "pound":
			up = absf(sin(_mood_t * 6.5))
		else:
			up = pow(1.0 - _work, 0.6)
		arm_r = lerpf(POUND_STRIKE, POUND_RAISE, up)
		arm_l = 1.0
		arm_l_z = 0.45
		arm_z = 0.0
		head_x = -0.3
		lean = POUND_LEAN
		bob += -0.02 * (1.0 - up)
	elif _work > 0.0 or mood == "chop":
		# หั่น: ยกแขนขึ้นแล้วสับลง
		var p := sin(_work * PI) if mood != "chop" else absf(sin(_mood_t * 7.0))
		arm_r = lerpf(1.0, 2.7, p)
		arm_l = lerpf(1.0, 2.2, p)
		head_x = -0.15

	if mood != "" and mood != "pound" and mood != "chop":
		_mood_t += delta
		if mood == "happy":
			bob += absf(sin(_mood_t * 10.0)) * 0.12
			arm_l = 2.6
			arm_r = 2.6
		elif mood == "angry":
			_model.rotation.y = sin(_mood_t * 30.0) * 0.12
			arm_l = 0.4
			arm_r = 0.4
		elif mood == "sad":
			head_x = -0.45
			arm_l = 0.15
			arm_r = 0.15
			bob -= 0.03
		elif mood == "wave":
			arm_r = 2.9
			arm_z = 0.0
			_parts["ArmR"].rotation.z = sin(_mood_t * 9.0) * 0.4
		elif mood == "shock":
			bob += maxf(0.0, 0.15 - _mood_t * 0.3)
			arm_l = 2.4
			arm_r = 2.4
			head_x = 0.25
		elif mood == "dizzy":
			_model.rotation.z = sin(_mood_t * 3.0) * 0.12
			head_x = sin(_mood_t * 2.0) * 0.2
			arm_r = 2.6
			arm_l = 0.3
		elif mood == "laugh":
			bob += absf(sin(_mood_t * 14.0)) * 0.05
			head_x = 0.3
			arm_l = 0.8
			arm_r = 0.8
		elif mood == "point":
			arm_r = 1.6
	elif mood == "pound" or mood == "chop":
		_mood_t += delta

	_parts["ArmL"].rotation = Vector3(arm_l, 0, -arm_z + arm_l_z)
	if mood != "wave":
		_parts["ArmR"].rotation = Vector3(arm_r, 0, arm_z)
	else:
		_parts["ArmR"].rotation.x = arm_r
	_parts["LegL"].rotation.x = leg_l
	_parts["LegR"].rotation.x = leg_r
	_parts["Head"].rotation.x = head_x
	_model.position.y = bob
	_model.rotation.x = lean

	if pounding:
		_ensure_pestle()
	if _pestle:
		_pestle.visible = pounding
		if pounding:
			_pestle.rotation = Vector3(PESTLE_TILT - arm_r - lean, 0, 0)
