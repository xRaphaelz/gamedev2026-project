@tool
class_name ServeStation
extends Station
## จุดเสิร์ฟ: ถือจานที่มีอาหารแล้วกด E


func status_text() -> String:
	return ""


func interact(player: Player) -> void:
	var h := player.held
	if h == null or not h.has_dish():
		GameState.toast("ถือจานส้มตำมาเสิร์ฟ")
		return
	var om := get_tree().get_first_node_in_group("order_manager") as OrderManager
	if om == null:
		return
	var before := om.score
	var was_failed := h.dish_failed
	if om.serve(h.dish if not h.dish_failed else null):
		player.release().queue_free()
		var delta := om.score - before
		var top := global_position + Vector3(0, 1.4, 0)
		if was_failed:
			Fx.float_text(self, top, "-%d" % OrderManager.WRONG_PENALTY, Color(1, 0.45, 0.35))
		else:
			Fx.float_text(self, top, "+%d" % delta)
			Fx.sparkle(self, global_position + Vector3(0, 1.0, 0))
