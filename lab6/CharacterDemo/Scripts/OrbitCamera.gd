extends Node3D
## Drag to orbit, wheel / pinch to zoom, optional slow auto-rotation.

@export var distance := 5.8
@export var min_distance := 2.2
@export var max_distance := 9.0
@export var auto_rotate := true
@export var auto_speed := 12.0      # degrees per second

var yaw := 25.0
var pitch := -8.0
var _dragging := false
var _idle := 0.0

@onready var cam: Camera3D = $Camera3D


func _process(delta: float) -> void:
	_idle += delta
	if auto_rotate and not _dragging and _idle > 2.0:
		yaw += auto_speed * delta
	rotation_degrees = Vector3(pitch, yaw, 0)
	cam.position = cam.position.lerp(Vector3(0, 0, distance), clamp(delta * 10.0, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_idle = 0.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = clamp(distance - 0.35, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = clamp(distance + 0.35, min_distance, max_distance)
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * 0.35
		pitch = clamp(pitch - event.relative.y * 0.25, -60.0, 20.0)
		_idle = 0.0
	elif event is InputEventScreenDrag:
		yaw -= event.relative.x * 0.35
		pitch = clamp(pitch - event.relative.y * 0.25, -60.0, 20.0)
		_idle = 0.0
	elif event is InputEventMagnifyGesture:
		distance = clamp(distance / event.factor, min_distance, max_distance)
