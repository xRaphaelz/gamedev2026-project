@tool
class_name MortarStation
extends Station
## ครก: ใส่วัตถุดิบ -> กด Space รัว ๆ ตำ -> ถือจานเปล่ากด E เพื่อตักใส่จาน
## ตำไม่ครบจะตักไม่ได้ / ส่วนผสมไม่ตรงสูตรจะได้ "ส้มตำมั่ว"

@export var max_items: int = 6
## จำนวนครั้งตำ ถ้าส่วนผสมไม่ตรงเมนูไหนเลย
@export var default_hits: int = 10

var contents: Dictionary = {}  # id -> จำนวน
var hits: int = 0


var _pestle: Node3D
var _mortar: Node3D
var _mound: MeshInstance3D
var _mound_mat: StandardMaterial3D
var _tween: Tween


## ครกตั้งบนแท่นไม้เตี้ย (ระดับเอวตัวละคร) แบบร้านส้มตำจริง
const STAND_SIZE := Vector3(0.5, 0.05, 0.5)
const MORTAR_SCALE := 0.85

var _pestle_rest := true


func _build_extra() -> void:
	# แทนกล่องสีพื้นฐานด้วยแท่นไม้เตี้ย
	if _visual and model == null:
		_visual.free()
		_visual = _make_stand()
		_gen(_visual)
	var mortar := Item.instance_model("res://assets/models/props/mortar.glb")
	if mortar == null:
		return
	mortar.position = Vector3(0, item_height, 0)
	mortar.scale = Vector3.ONE * MORTAR_SCALE
	if _visual:
		mortar.set_meta("generated", true)
		_visual.add_child(mortar)
	else:
		_gen(mortar)
	_mortar = mortar
	_pestle = mortar.find_child("Pestle", true, false)
	_mound = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.17
	sph.height = 0.12
	sph.radial_segments = 12
	sph.rings = 6
	_mound.mesh = sph
	_mound_mat = StandardMaterial3D.new()
	_mound_mat.roughness = 0.7
	_mound.material_override = _mound_mat
	_mound.position = Vector3(0, 0.36, 0)
	mortar.add_child(_mound)
	_update_mound()


func _make_stand() -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.62, 0.4, 0.22)
	wood.roughness = 0.75
	var dark := wood.duplicate() as StandardMaterial3D
	dark.albedo_color = Color(0.45, 0.28, 0.15)
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = STAND_SIZE
	top.mesh = tb
	top.material_override = wood
	top.position.y = item_height - STAND_SIZE.y / 2.0
	root.add_child(top)
	var leg_h := item_height - STAND_SIZE.y
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var leg := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.06, leg_h, 0.06)
			leg.mesh = lb
			leg.material_override = dark
			leg.position = Vector3(sx * 0.19, leg_h / 2.0, sz * 0.19)
			root.add_child(leg)
	# ถาดรองครก + ผ้าเช็ดมือ ให้ดูเป็นที่ตำจริง
	var mat := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.2
	cm.height = 0.012
	cm.radial_segments = 16
	mat.mesh = cm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.86, 0.78, 0.55)
	mat.material_override = mm
	mat.position.y = item_height + 0.006
	root.add_child(mat)
	return root


## ผู้เล่นถือสากอยู่ในมือ -> ซ่อนสากที่พักในครก
func set_pestle_in_hand(on: bool, hold := 0.8) -> void:
	_pestle_rest = not on
	_hand_t = hold
	if _pestle:
		_pestle.visible = _pestle_rest


## จุดยืน + มุมหันของคนตำ ให้หัวสากในมือขวาลงกลางครกพอดี
## approach = ทิศจากคนไปหาครก (แนวราบ)
func pound_spot(approach: Vector3) -> Dictionary:
	var f := Vector3(approach.x, 0, approach.z)
	if f.length() < 0.01:
		f = Vector3(1, 0, 0)
	f = f.normalized()
	var right := f.cross(Vector3.UP)
	var m := global_position
	var pos := m - f * CharacterRig.POUND_REACH.z - right * CharacterRig.POUND_REACH.x
	return {"position": Vector3(pos.x, 0, pos.z), "yaw": atan2(-f.x, -f.z)}


## กองวัตถุดิบในครก: สีผสมตามของที่ใส่ ตำแล้วสีจะกลมกลืนขึ้น
func _update_mound() -> void:
	if _mound == null:
		return
	_mound.visible = item_count() > 0
	if not _mound.visible:
		return
	var c := Color(0, 0, 0)
	var n := 0
	for k in contents:
		c += Ingredients.color_of(str(k)) * int(contents[k])
		n += int(contents[k])
	c /= float(n)
	var t := clampf(float(hits) / maxf(required_hits(), 1.0), 0.0, 1.0)
	_mound_mat.albedo_color = c.lerp(c.darkened(0.25), t)
	_mound.scale = Vector3(1, 0.6 + 0.12 * n - 0.4 * t, 1)


func refresh_status() -> void:
	super.refresh_status()
	_update_mound()


var _hand_t := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _pestle_rest:
		return
	_hand_t -= delta
	if _hand_t <= 0.0:
		set_pestle_in_hand(false)


func item_count() -> int:
	var n := 0
	for k in contents:
		n += int(contents[k])
	return n


func chili_count() -> int:
	return int(contents.get(Recipe.SPICE_ID, 0))


func matched_recipe() -> Recipe:
	for r in GameState.all_recipes():
		if r.matches(contents):
			return r
	return null


func required_hits() -> int:
	var r := matched_recipe()
	return r.pound_hits if r else default_hits


func is_done() -> bool:
	return item_count() > 0 and hits >= required_hits()


func interact(player: Player) -> void:
	var h := player.held
	if h == null:
		GameState.toast("ครก: ใส่วัตถุดิบ แล้วกด Space ตำ")
	elif h.is_plate():
		if not h.is_empty_plate():
			GameState.toast("จานไม่ว่าง")
		elif item_count() == 0:
			GameState.toast("ครกยังว่าง")
		elif not is_done():
			GameState.toast("ยังตำไม่เสร็จ")
		else:
			var r := matched_recipe()
			h.set_dish(r, r == null, chili_count())
			contents.clear()
			hits = 0
	else:
		if not h.prepared:
			GameState.toast("ต้องหั่นก่อน")
		elif is_done():
			GameState.toast("ตำเสร็จแล้ว ตักใส่จานก่อน")
		elif item_count() >= max_items:
			GameState.toast("ครกเต็มแล้ว")
		else:
			var id := h.ingredient_id
			contents[id] = int(contents.get(id, 0)) + 1
			player.release().queue_free()
	refresh_status()


func work(_player: Player) -> void:
	if item_count() == 0 or is_done():
		return
	hits += 1
	# ยืนให้ตรงครก แล้วตำด้วยสากในมือ
	var spot := pound_spot(global_position - _player.global_position)
	_player.set_work_pose(spot.position, spot.yaw)
	set_pestle_in_hand(true)
	Audio.sfx("pound", 0.0, 0.1)
	var cols := []
	for k in contents:
		cols.append(Ingredients.color_of(str(k)))
	Fx.burst(self, global_position + Vector3(0, item_height + 0.4, 0), cols, 8, 2.6, 0.08)
	Fx.shake(_mortar, 0.02)
	Fx.cam_shake(get_viewport().get_camera_3d(), 0.012)
	if is_done():
		Audio.sfx("star", -6.0)
		Fx.sparkle(self, global_position + Vector3(0, item_height + 0.45, 0))
		var r := matched_recipe()
		Fx.float_text(self, global_position + Vector3(0, item_height + 0.9, 0), "เสร็จ!" if r else "มั่ว!", Color(1, 0.9, 0.4) if r else Color(1, 0.5, 0.4), 40)
	refresh_status()


func status_text() -> String:
	if item_count() == 0:
		return ""
	var parts: PackedStringArray = []
	for k in contents:
		var n := int(contents[k])
		var name := Ingredients.display_name(str(k))
		parts.append(name if n == 1 else "%s x%d" % [name, n])
	var line := ", ".join(parts)
	if is_done():
		var r := matched_recipe()
		return line + "\nเสร็จ: " + ("%s %s" % [r.display_name, Item.spice_text(chili_count())] if r else "ส้มตำมั่ว")
	return line + "\nตำ %d/%d  [Space]" % [hits, required_hits()]
