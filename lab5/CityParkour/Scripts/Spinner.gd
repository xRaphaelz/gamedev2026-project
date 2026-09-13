extends Node3D
## Rotating bar trap - sweeps across a platform and knocks the player off.

@export var spin_speed := 90.0

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed * delta))
