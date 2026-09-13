extends Node3D
## Autoload. Keeps score, coin totals, lives and level flow for the whole game.

signal coins_changed(collected: int, total: int)
signal lives_changed(lives: int)

const LEVELS := [
	"res://Scenes/Levels/Level1.tscn",
	"res://Scenes/Levels/Level2.tscn",
]
const LEVEL_NAMES := [
	"ด่าน 1 - Rooftop Run",
	"ด่าน 2 - Night Street",
]

const MAX_LIVES := 3

var score := 0
var total_coins := 0
var lives := MAX_LIVES
var current_level := 0
var spawn_position := Vector3.ZERO
var level_running := false

# ---------- LEVEL FLOW ---------- #

func begin_level(index: int) -> void:
	current_level = index
	score = 0
	total_coins = 0
	lives = MAX_LIVES
	level_running = true
	coins_changed.emit(score, total_coins)
	lives_changed.emit(lives)

func level_name() -> String:
	if current_level >= 0 and current_level < LEVEL_NAMES.size():
		return LEVEL_NAMES[current_level]
	return "Level"

func has_next_level() -> bool:
	return current_level + 1 < LEVELS.size()

func goto_level(index: int) -> void:
	if index < 0 or index >= LEVELS.size():
		return
	level_running = false
	if not OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(LEVELS[index])

func next_level() -> void:
	if has_next_level():
		goto_level(current_level + 1)
	else:
		show_win()

func restart_level() -> void:
	goto_level(current_level)

func show_win() -> void:
	level_running = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/UI/WinScreen.tscn")

## The game has no title screen - "back to start" just replays level 1.
func show_menu() -> void:
	goto_level(0)

# ---------- COINS ---------- #

func register_coin() -> void:
	total_coins += 1
	coins_changed.emit(score, total_coins)

func add_score() -> void:
	score += 1
	coins_changed.emit(score, total_coins)

func all_coins_collected() -> bool:
	return total_coins > 0 and score >= total_coins

# ---------- LIVES ---------- #

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		lives = MAX_LIVES
		score = 0
		coins_changed.emit(score, total_coins)
		lives_changed.emit(lives)
		restart_level()

# ---------- INPUT ---------- #

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_visible"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("restart") and level_running:
		restart_level()
