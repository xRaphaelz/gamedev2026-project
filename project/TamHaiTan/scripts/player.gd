@tool
class_name Player
extends CharacterBody3D
## ต้อม (ผู้เล่น): WASD เดิน / E หยิบ-วาง-ใช้สถานี / Space ตำ-หั่น (กดรัว)

@export var speed := 5.0
@export var turn_speed := 14.0
## ระยะเอื้อมถึงสถานี
@export var reach := 1.35

var held: Item = null
var target: Station = null

var rig: CharacterRig
var _step_t := 0.0
var _hand: Node3D
var _body: Node3D


func _ready() -> void:
	for c in get_children():
		if c.has_meta("generated"):
			c.free()
	_build_placeholder()
	if Engine.is_editor_hint():
		return
	add_to_group("player")


func _build_placeholder() -> void:
	_body = Node3D.new()
	_gen(_body)

	rig = CharacterRig.new()
	rig.character = "tom"
	_body.add_child(rig)

	_hand = Node3D.new()
	_hand.name = "Hand"
	_hand.position = Vector3(0, 0.6, -0.42)
	_body.add_child(_hand)

	var shape := CollisionShape3D.new()
	var cs := CapsuleShape3D.new()
	cs.radius = 0.3
	cs.height = 1.3
	shape.shape = cs
	shape.position.y = 0.65
	_gen(shape)


func _gen(n: Node) -> void:
	n.set_meta("generated", true)
	add_child(n)


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var can_move := GameState.is_playing()
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if can_move else Vector2.ZERO
	var dir := Vector3(input.x, 0, input.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	if rig:
		rig.state = "walk" if dir.length() > 0.1 else "idle"
		if dir.length() > 0.1:
			_step_t -= delta
			if _step_t <= 0.0:
				_step_t = 0.28
				Audio.sfx("step", -16.0, 0.15)
		rig.carrying = held != null
	if dir.length() > 0.1:
		var want := atan2(-dir.x, -dir.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, want, clampf(turn_speed * delta, 0, 1))

	_update_target()

	if not can_move:
		return
	if Input.is_action_just_pressed("interact") and target:
		target.interact(self)
		target.refresh_status()
	if Input.is_action_just_pressed("work") and target:
		target.work(self)
		if held == null and (target is MortarStation or target is ChopStation):
			rig.pulse_work()


func facing() -> Vector3:
	return -_body.global_transform.basis.z


## หาสถานีที่ใกล้จุดตรงหน้ามากที่สุด
func _update_target() -> void:
	var probe := global_position + facing() * 0.8
	var best: Station = null
	var best_d := reach
	for s in get_tree().get_nodes_in_group("stations"):
		var st := s as Station
		var d := Vector2(st.global_position.x - probe.x, st.global_position.z - probe.z).length()
		if d < best_d:
			best_d = d
			best = st
	if best != target:
		if target:
			target.set_highlight(false)
		target = best
		if target:
			target.set_highlight(true)


func grab(item: Item) -> void:
	if not Engine.is_editor_hint():
		Audio.sfx("plate" if item.is_plate() else "pickup", -3.0)
	held = item
	if item.get_parent():
		item.reparent(_hand, false)
	else:
		_hand.add_child(item)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	if not Engine.is_editor_hint():
		Fx.pop(item)


func release() -> Item:
	var item := held
	held = null
	return item
