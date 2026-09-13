extends AnimatableBody3D
## Falling block trap. Slams down, waits, rises again.

@export var drop_height := 5.0
@export var drop_time := 0.35
@export var wait_time := 0.9
@export var rise_time := 1.6
@export var start_delay := 0.0

var _top := Vector3.ZERO

func _ready() -> void:
	sync_to_physics = true
	_top = position
	var tween := create_tween().set_loops()
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
	tween.tween_property(self, "position", _top - Vector3(0, drop_height, 0), drop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(wait_time)
	tween.tween_property(self, "position", _top, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.5)
