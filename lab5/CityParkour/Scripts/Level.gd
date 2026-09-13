extends Node3D
## Every level root. Resets the run counters before the coins register themselves.

@export var level_index := 0
@export var spawn_point_path: NodePath

func _enter_tree() -> void:
	GameManager.begin_level(level_index)

func _ready() -> void:
	var marker := get_node_or_null(spawn_point_path) as Node3D
	if marker:
		GameManager.spawn_position = marker.global_position
	else:
		var player := get_tree().get_first_node_in_group("Player") as Node3D
		if player:
			GameManager.spawn_position = player.global_position
	if not OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
