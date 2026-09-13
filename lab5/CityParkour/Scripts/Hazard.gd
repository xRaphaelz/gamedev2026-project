extends Area3D
## Generic trap volume. Touching it hurts the player.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("hit"):
		body.hit(global_position)
