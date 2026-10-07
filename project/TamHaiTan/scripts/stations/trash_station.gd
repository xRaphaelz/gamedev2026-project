@tool
class_name TrashStation
extends Station
## ถังขยะ: ทิ้งวัตถุดิบ / เทอาหารออกจากจาน


func status_text() -> String:
	return ""


func interact(player: Player) -> void:
	var h := player.held
	if h == null:
		return
	Audio.sfx("trash", -4.0)
	Fx.burst(self, global_position + Vector3(0, 0.85, 0), [Color(0.4, 0.4, 0.42), Color(0.6, 0.5, 0.35)], 7, 1.4, 0.09)
	if h.is_plate():
		h.clear_dish()
	else:
		player.release().queue_free()
