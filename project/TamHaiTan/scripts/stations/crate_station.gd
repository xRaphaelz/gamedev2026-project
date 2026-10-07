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


const TRAY_SPOTS := [Vector3(-0.17, 0, -0.1), Vector3(0.17, 0, -0.08), Vector3(0.0, 0, 0.16)]


## แสดงวัตถุดิบ 3 ชิ้นบนกระด้ง
func _build_extra() -> void:
	var prepared := false
	if not Engine.is_editor_hint():
		prepared = not GameState.current_level().require_chopping
	var path := Item.ingredient_model_path(ingredient_id, prepared)
	for i in TRAY_SPOTS.size():
		var m := Item.instance_model(path)
		if m == null:
			return
		m.position = TRAY_SPOTS[i] + Vector3(0, item_height, 0)
		m.rotation.y = [0.3, -0.8, 1.9][i]
		_gen(m)


func interact(player: Player) -> void:
	if player.held == null:
		var prepared := not GameState.current_level().require_chopping
		player.grab(Item.make_ingredient(ingredient_id, prepared))
	elif not player.held.is_plate() and player.held.ingredient_id == ingredient_id:
		player.release().queue_free()
	else:
		GameState.toast("มือไม่ว่าง")
