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


func _build_extra() -> void:
	var mortar := Item.instance_model("res://assets/models/props/mortar.glb")
	if mortar == null:
		return
	mortar.position = Vector3(0, item_height, 0)
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


func _pound_anim() -> void:
	if _pestle == null:
		return
	if _tween:
		_tween.kill()
	_pestle.position.y = 0.42
	_tween = create_tween()
	_tween.tween_property(_pestle, "position:y", 0.24, 0.06)
	_tween.tween_property(_pestle, "position:y", 0.3, 0.12)


func item_count() -> int:
	var n := 0
	for k in contents:
		n += int(contents[k])
	return n


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
			h.set_dish(r, r == null)
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
	_pound_anim()
	Audio.sfx("pound", 0.0, 0.1)
	var cols := []
	for k in contents:
		cols.append(Ingredients.color_of(str(k)))
	Fx.burst(self, global_position + Vector3(0, item_height + 0.55, 0), cols, 8, 2.6, 0.09)
	Fx.shake(_mortar, 0.025)
	if is_done():
		Audio.sfx("star", -6.0)
		Fx.sparkle(self, global_position + Vector3(0, item_height + 0.5, 0))
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
		return line + "\nเสร็จ: " + (r.display_name if r else "ส้มตำมั่ว")
	return line + "\nตำ %d/%d  [Space]" % [hits, required_hits()]
