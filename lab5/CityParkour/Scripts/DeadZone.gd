extends Area3D
## Anything below the level falls in here: costs a life and sends the player back.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("hit"):
		body.hit(body.global_position + Vector3.UP)
