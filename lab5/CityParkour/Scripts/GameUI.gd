extends Control
## HUD: coin counter, lives and the level title.

@onready var coins_label: Label = $CoinsLabel
@onready var hearts: HBoxContainer = $Hearts
@onready var level_label: Label = $LevelLabel
@onready var hint_label: Label = $HintLabel


func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	level_label.text = GameManager.level_name()
	_on_coins_changed(GameManager.score, GameManager.total_coins)
	_on_lives_changed(GameManager.lives)
	# fade the control hint out after a few seconds (tween, not await, so a
	# scene change mid-fade cannot leave a dangling coroutine)
	var tween := create_tween()
	tween.tween_interval(7.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.5)


func _on_coins_changed(collected: int, total: int) -> void:
	coins_label.text = "%d / %d" % [collected, total]
	if total > 0 and collected >= total:
		coins_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	else:
		coins_label.add_theme_color_override("font_color", Color(0.996, 0.711, 0.261))


func _on_lives_changed(lives: int) -> void:
	for i in hearts.get_child_count():
		var heart := hearts.get_child(i) as TextureRect
		var full: bool = i < lives
		heart.modulate = Color(1, 1, 1, 1) if full else Color(0.25, 0.25, 0.3, 0.55)
