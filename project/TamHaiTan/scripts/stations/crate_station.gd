@tool
class_name CrateStation
extends Station
## กล่องวัตถุดิบ: มือว่างกด E = หยิบวัตถุดิบ, ถือวัตถุดิบชนิดเดียวกันที่ยังไม่หั่น = คืนกล่อง

@export var ingredient_id: String = "papaya":
	set(v):
		ingredient_id = v
		_apply_ingredient()


func _ready() -> void:
	_apply_ingredient()
	super._ready()


func _apply_ingredient() -> void:
	title = Ingredients.display_name(ingredient_id)
	color = Ingredients.color_of(ingredient_id).darkened(0.35)


## ของหมด (เหตุการณ์ "มะละกอหมด"): กด Space รัว ๆ เพื่อแกะลังใหม่
const RESTOCK_HITS := 8
var out_of_stock := false
var _restock := 0
var _tray: Array[Node3D] = []


func set_out_of_stock(on: bool) -> void:
	if out_of_stock == on:
		return
	out_of_stock = on
	_restock = 0
	for m in _tray:
		if is_instance_valid(m):
			m.visible = not on
	if not on and not Engine.is_editor_hint():
		Audio.sfx("pickup", -2.0)
		Fx.burst(self, global_position + Vector3(0, item_height + 0.3, 0), [Ingredients.color_of(ingredient_id), Color(0.8, 0.6, 0.35)], 12, 2.4, 0.08)
		for m in _tray:
			if is_instance_valid(m):
				Fx.pop(m, 1.4)
	refresh_status()


func work(_player: Player) -> void:
	if not out_of_stock:
		return
	_restock += 1
	Audio.sfx("chop", -6.0, 0.15)
	Fx.shake(_visual, 0.02)
	if _restock >= RESTOCK_HITS:
		set_out_of_stock(false)
		GameState.toast("แกะลัง%sใหม่แล้ว!" % Ingredients.display_name(ingredient_id), true)
	refresh_status()


func status_text() -> String:
	if out_of_stock:
		return "หมด! แกะลังใหม่ %d/%d  [Space]" % [_restock, RESTOCK_HITS]
	return ""


const TRAY_SPOTS := [Vector3(-0.17, 0, -0.1), Vector3(0.17, 0, -0.08), Vector3(0.0, 0, 0.16)]


## แสดงวัตถุดิบ 3 ชิ้นบนกระด้ง
func _build_extra() -> void:
	var prepared := false
	if not Engine.is_editor_hint():
		prepared = not GameState.current_level().require_chopping
	var path := Item.ingredient_model_path(ingredient_id, prepared)
	_tray.clear()
	for i in TRAY_SPOTS.size():
		var m := Item.instance_model(path)
		if m == null:
			return
		m.position = TRAY_SPOTS[i] + Vector3(0, item_height, 0)
		m.rotation.y = [0.3, -0.8, 1.9][i]
		m.visible = not out_of_stock
		_gen(m)
		_tray.append(m)


func interact(player: Player) -> void:
	if out_of_stock and player.held == null:
		GameState.toast("%sหมด! กด Space รัว ๆ เพื่อแกะลังใหม่" % Ingredients.display_name(ingredient_id), false)
		return
	if player.held == null:
		var prepared := not GameState.current_level().require_chopping
		player.grab(Item.make_ingredient(ingredient_id, prepared))
	elif not player.held.is_plate() and player.held.ingredient_id == ingredient_id:
		player.release().queue_free()
	else:
		GameState.toast("มือไม่ว่าง")
