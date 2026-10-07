@tool
class_name PlateStation
extends Station
## ที่วางจาน: มือว่างหยิบจานเปล่าได้ไม่จำกัด / ถือจานเปล่ากด E = คืนจาน


func status_text() -> String:
	return ""


func interact(player: Player) -> void:
	if player.held == null:
		player.grab(Item.make_plate())
	elif player.held.is_empty_plate():
		player.release().queue_free()
	else:
		GameState.toast("มือไม่ว่าง")
