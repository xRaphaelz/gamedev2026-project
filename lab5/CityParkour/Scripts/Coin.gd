extends Area3D
## Collectible coin. Registers itself with the GameManager so the HUD can show x / total.

@export_category("Properties")
@export var follow_speed := 8.0
@export var amplitude := 0.2
@export var frequency := 4.0

var time_passed := 0.0
var is_in_range := false
var collected := false
var initial_position := Vector3.ZERO

@onready var player: Node3D = get_tree().get_first_node_in_group("Player")


func _ready() -> void:
	initial_position = position
	GameManager.register_coin()


func _process(delta: float) -> void:
	_coin_hover(delta)
	rotate_y(deg_to_rad(150.0 * delta))

	if is_in_range and is_instance_valid(player):
		position += global_position.direction_to(player.global_position) * follow_speed * delta * 0.6


func _coin_hover(delta: float) -> void:
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)


func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if body.is_in_group("Player"):
		collected = true
		GameManager.add_score()
		AudioManager.coin_sfx.play()
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ONE * 0.02, 0.15)
		tween.tween_callback(queue_free)


func _on_range_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		is_in_range = true
		if player == null:
			player = body
