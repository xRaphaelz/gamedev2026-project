extends Area3D
## Moves the respawn point forward so long levels are not punishing.

@export var flag_height := 1.0
var _taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("Player"):
		return
	_taken = true
	GameManager.spawn_position = global_position + Vector3(0, flag_height, 0)
	var light := get_node_or_null("Light") as OmniLight3D
	if light:
		light.light_color = Color(0.4, 1.0, 0.5)
