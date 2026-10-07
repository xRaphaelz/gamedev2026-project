@tool
class_name ChopStation
extends Station
## เขียง: วางวัตถุดิบที่ต้องหั่น แล้วกด Space รัว ๆ จนเสร็จ

@export var chop_hits: int = 6

var _progress: int = 0
var _knife: Node3D
var _tween: Tween


func _build_extra() -> void:
	_knife = Item.instance_model("res://assets/models/props/knife.glb")
	if _knife:
		_knife.position = Vector3(0.18, item_height, 0.22)
		_knife.rotation.y = 0.5
		_gen(_knife)


func accepts(item: Item) -> bool:
	if item.is_plate():
		return false
	if not Ingredients.needs_prep(item.ingredient_id) or item.prepared:
		GameState.toast("ไม่ต้องหั่นแล้ว")
		return false
	return true


func interact(player: Player) -> void:
	if player.held and held == null and not accepts(player.held):
		return
	super.interact(player)


func place(item: Item) -> void:
	_progress = 0
	super.place(item)


func work(_player: Player) -> void:
	if held == null or held.prepared:
		return
	_progress += 1
	Audio.sfx("chop", -2.0)
	Fx.burst(self, global_position + Vector3(0, item_height + 0.08, 0), [Color(0.83, 0.92, 0.63), Color(0.55, 0.8, 0.35)], 6, 1.6, 0.08)
	if _knife:
		if _tween:
			_tween.kill()
		_knife.position = Vector3(0.0, item_height + 0.14, 0.05)
		_tween = create_tween()
		_tween.tween_property(_knife, "position:y", item_height + 0.03, 0.07)
		_tween.tween_interval(0.12)
		_tween.tween_property(_knife, "position", Vector3(0.18, item_height, 0.22), 0.15)
	if _progress >= chop_hits:
		held.set_prepared()
		Audio.sfx("star", -6.0)
		Fx.sparkle(self, global_position + Vector3(0, item_height + 0.2, 0))
	refresh_status()


func status_text() -> String:
	if held == null:
		return ""
	if held.prepared:
		return held.describe() + " เสร็จ"
	return "หั่น %d/%d  [Space]" % [_progress, chop_hits]
