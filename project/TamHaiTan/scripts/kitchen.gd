extends Node3D
## ฉากด่านเล่น: ผูก HUD กับ OrderManager และคุมลำดับ เนื้อเรื่อง -> เริ่มด่าน -> เล่น -> หยุด -> สรุปผล

@onready var om: OrderManager = $OrderManager
@onready var hud: Hud = $Hud
@onready var dialogue: DialogueBox = $DialogueBox
@onready var stage: Node3D = $Stage

## ขอบเขตที่ผู้เล่นเดินได้ (กำแพงล่องหน)
@export var bounds := Rect2(-4.9, -3.75, 9.8, 6.6)

var _last_tick := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_walls()
	stage.apply_time_of_day(GameState.current_level().time_of_day)
	hud.bind(om)
	hud.start_pressed.connect(_start)
	hud.retry_pressed.connect(_retry)
	hud.next_pressed.connect(_next)
	hud.menu_pressed.connect(_menu)
	hud.resume_pressed.connect(func(): _set_paused(false))
	om.level_finished.connect(_on_finished)
	om.order_added.connect(func(_o): Audio.sfx("order", -4.0))
	om.time_left = GameState.current_level().duration
	dialogue.finished.connect(_show_intro)
	var story := GameState.current_level().story_before
	if story and not GameState.seen_stories.has(story.resource_path):
		GameState.seen_stories[story.resource_path] = true
		GameState.phase = GameState.Phase.STORY
		hud.hide()
		Audio.music("calm")
		dialogue.play(story)
	else:
		_show_intro()


func _show_intro() -> void:
	GameState.phase = GameState.Phase.INTRO
	hud.show()
	hud.show_intro(GameState.current_level())
	Audio.music("menu")


func _process(_delta: float) -> void:
	# นับถอยหลัง 10 วินาทีสุดท้าย
	if GameState.is_playing():
		var t := int(ceil(om.time_left))
		if t <= 10 and t != _last_tick and t > 0:
			_last_tick = t
			Audio.sfx("tick", -2.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	match GameState.phase:
		GameState.Phase.INTRO:
			if event.is_action_pressed("confirm"):
				_start()
		GameState.Phase.PLAYING:
			if event.is_action_pressed("pause"):
				_set_paused(true)
		GameState.Phase.PAUSED:
			if event.is_action_pressed("pause"):
				_set_paused(false)
		GameState.Phase.RESULT:
			if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
				_retry()
			elif event.is_action_pressed("confirm"):
				_next()


func _start() -> void:
	if GameState.phase != GameState.Phase.INTRO:
		return
	Audio.sfx("click")
	hud.hide_intro()
	GameState.phase = GameState.Phase.PLAYING
	om.start(GameState.current_level())
	Audio.music("game")


func _set_paused(on: bool) -> void:
	GameState.phase = GameState.Phase.PAUSED if on else GameState.Phase.PLAYING
	get_tree().paused = on
	hud.set_paused(on)


func _on_finished(score: int, stars: int, stats: Dictionary) -> void:
	GameState.phase = GameState.Phase.RESULT
	GameState.record_result(stars)
	Audio.music("")
	Audio.sfx("win" if stars >= 3 else "lose")
	hud.show_result(score, stars, stats, GameState.has_next_level(), GameState.is_last_level())


func _retry() -> void:
	get_tree().paused = false
	GameState.change_scene(GameState.SCENE_KITCHEN)


func _next() -> void:
	if GameState.phase != GameState.Phase.RESULT:
		return
	if GameState.has_next_level():
		GameState.start_level(GameState.level_index + 1)
	else:
		GameState.go_ending()


func _menu() -> void:
	GameState.go_menu()


func _build_walls() -> void:
	var walls := StaticBody3D.new()
	walls.name = "Walls"
	add_child(walls)
	var c := bounds.get_center()
	var t := 0.5
	var specs := [
		[Vector3(c.x, 1, bounds.position.y), Vector3(bounds.size.x, 2, t)],
		[Vector3(c.x, 1, bounds.end.y), Vector3(bounds.size.x, 2, t)],
		[Vector3(bounds.position.x, 1, c.y), Vector3(t, 2, bounds.size.y)],
		[Vector3(bounds.end.x, 1, c.y), Vector3(t, 2, bounds.size.y)],
	]
	for s in specs:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = s[1]
		cs.shape = box
		cs.position = s[0]
		walls.add_child(cs)
