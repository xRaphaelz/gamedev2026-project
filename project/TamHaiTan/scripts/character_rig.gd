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
## อารมณ์/ท่าพิเศษ: happy, angry, sad, wave, shock, dizzy, laugh, point, pound

var _model: Node3D
var _parts := {}
var _t := 0.0
var _work := 0.0
var _mood_t := 0.0
var mood := ""


func _ready() -> void:
	_load_model()


func _load_model() -> void:
	if not is_inside_tree():
		return
	if _model:
		_model.queue_free()
		_model = null
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


func pulse_work() -> void:
	_work = 1.0


func react(m: String) -> void:
	mood = m
	_mood_t = 0.0
	if _model and m == "":
		_model.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	if _model == null or _parts.is_empty() or _parts["ArmL"] == null:
		return
	_t += delta
	_work = maxf(_work - delta * 5.0, 0.0)
	var arm_l := 0.0
	var arm_r := 0.0
	var leg_l := 0.0
	var leg_r := 0.0
	var bob := 0.0
	var head_x := sin(_t * 1.7) * 0.04
	var arm_z := 0.0

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
	if _work > 0.0:
		# ยกแขนขึ้นแล้วทุบลง (ท่าตำ)
		var p := sin(_work * PI)
		arm_r = lerpf(1.0, 2.7, p)
		arm_l = lerpf(1.0, 2.2, p)
		head_x = -0.15

	if mood != "":
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
		elif mood == "pound":
			var pp := absf(sin(_mood_t * 7.0))
			arm_r = lerpf(1.0, 2.7, pp)
			arm_l = lerpf(1.0, 2.2, pp)
			head_x = -0.15

	_parts["ArmL"].rotation = Vector3(arm_l, 0, -arm_z)
	if mood != "wave":
		_parts["ArmR"].rotation = Vector3(arm_r, 0, arm_z)
	else:
		_parts["ArmR"].rotation.x = arm_r
	_parts["LegL"].rotation.x = leg_l
	_parts["LegR"].rotation.x = leg_r
	_parts["Head"].rotation.x = head_x
	_model.position.y = bob
