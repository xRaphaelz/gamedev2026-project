extends Area3D
## Exit door. Unlocks once every coin in the level has been collected.

@export var is_final_door := false

var _unlocked := false

@onready var lock_light: OmniLight3D = $LockLight
@onready var label: Label3D = $Label
@onready var barrier: StaticBody3D = $Barrier
@onready var barrier_shape: CollisionShape3D = $Barrier/Shape


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameManager.score, GameManager.total_coins)


func _process(delta: float) -> void:
	if _unlocked:
		lock_light.light_energy = 3.0 + sin(Time.get_ticks_msec() / 200.0) * 1.0
		label.rotate_y(delta * 0.0)


func _on_coins_changed(collected: int, total: int) -> void:
	_unlocked = total > 0 and collected >= total
	if _unlocked:
		lock_light.light_color = Color(0.35, 1.0, 0.45)
		label.text = "ENTER" if not is_final_door else "FINISH"
		label.modulate = Color(0.5, 1.0, 0.6)
		barrier_shape.set_deferred("disabled", true)
		barrier.visible = false
	else:
		lock_light.light_color = Color(1.0, 0.35, 0.35)
		label.text = "%d / %d" % [collected, total]
		label.modulate = Color(1.0, 0.6, 0.6)
		barrier_shape.set_deferred("disabled", false)
		barrier.visible = true


func _on_body_entered(body: Node) -> void:
	if not _unlocked:
		return
	if not body.is_in_group("Player"):
		return
	set_deferred("monitoring", false)
	if is_final_door or not GameManager.has_next_level():
		GameManager.show_win()
	else:
		GameManager.next_level()
