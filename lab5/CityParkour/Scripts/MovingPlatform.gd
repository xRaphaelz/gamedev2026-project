extends AnimatableBody3D
## Platform that shuttles between its start point and start + travel.

@export var travel := Vector3(0, 0, 6)
@export var duration := 3.0
@export var start_delay := 0.0

var _start := Vector3.ZERO

func _ready() -> void:
	sync_to_physics = true
	_start = position
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
	tween.tween_property(self, "position", _start + travel, duration)
	tween.tween_property(self, "position", _start, duration)
