extends Node
## Autoload "GameState": ด่านปัจจุบัน, สถานะเกม, ลำดับฉาก (เมนู → คัตซีน → ด่าน → ตอนจบ), เซฟ, ข้อความแจ้งเตือน

signal toast_requested(text: String, good: Variant)

enum Phase { STORY, INTRO, PLAYING, PAUSED, RESULT }

const LEVELS: Array[LevelConfig] = [
	preload("res://data/levels/level_1.tres"),
	preload("res://data/levels/level_2.tres"),
	preload("res://data/levels/level_3.tres"),
]
const SAVE_PATH := "user://save.cfg"
const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_KITCHEN := "res://scenes/kitchen.tscn"
const SCENE_CUTSCENE := "res://scenes/cutscene.tscn"

## เกณฑ์ตอนจบ จากค่าเฉลี่ยดาวรีวิวของทุกบท
const ENDING_GOOD := 4.0
const ENDING_MID := 2.5

var level_index := 0
var phase: Phase = Phase.INTRO
## ดาวรีวิวดีที่สุดของแต่ละด่าน (index -> stars)
var best_stars: Dictionary = {}
## เนื้อเรื่อง/คัตซีนที่ดูไปแล้วในรอบนี้ (กดเล่นใหม่จะไม่เล่นซ้ำ)
var seen_stories: Dictionary = {}
var seen_cutscenes: Dictionary = {}
var music_volume := 0.8
var sfx_volume := 0.9

## คัตซีนที่กำลังจะเล่น และฉากที่จะไปต่อหลังจบ
var cutscene_id := ""
var _after_cutscene := ""

var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.04, 0.02, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func current_level() -> LevelConfig:
	return LEVELS[level_index]


func has_next_level() -> bool:
	return level_index + 1 < LEVELS.size()


func is_last_level() -> bool:
	return level_index == LEVELS.size() - 1


func is_playing() -> bool:
	return phase == Phase.PLAYING


func is_unlocked(i: int) -> bool:
	return i == 0 or best_stars.has(i - 1)


func all_recipes() -> Array[Recipe]:
	var out: Array[Recipe] = []
	for lv in LEVELS:
		for r in lv.recipes:
			if not out.has(r):
				out.append(r)
	return out


func toast(text: String, good: Variant = null) -> void:
	toast_requested.emit(text, good)


# ---------------- ลำดับฉาก ----------------

func change_scene(path: String) -> void:
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	create_tween().tween_property(_fade, "color:a", 0.0, 0.45)


func go_menu() -> void:
	change_scene(SCENE_MENU)


## เริ่มด่าน: ถ้ามีคัตซีนก่อนด่านที่ยังไม่ได้ดู จะเล่นก่อน
func start_level(i: int) -> void:
	level_index = i
	var cs := current_level().cutscene_before
	if cs != "" and not seen_cutscenes.has(cs):
		seen_cutscenes[cs] = true
		play_cutscene(cs, SCENE_KITCHEN)
	else:
		change_scene(SCENE_KITCHEN)


func new_game() -> void:
	seen_cutscenes.clear()
	seen_stories.clear()
	start_level(0)


func play_cutscene(id: String, then_scene: String) -> void:
	cutscene_id = id
	_after_cutscene = then_scene
	change_scene(SCENE_CUTSCENE)


func cutscene_finished() -> void:
	change_scene(_after_cutscene if _after_cutscene != "" else SCENE_MENU)


func average_stars() -> float:
	var total := 0
	for i in LEVELS.size():
		total += int(best_stars.get(i, 0))
	return float(total) / LEVELS.size()


func ending_id() -> String:
	var avg := average_stars()
	if avg >= ENDING_GOOD:
		return "ending_good"
	if avg >= ENDING_MID:
		return "ending_mid"
	return "ending_bad"


func go_ending() -> void:
	play_cutscene(ending_id(), SCENE_MENU)


# ---------------- เซฟ ----------------

func record_result(stars: int) -> void:
	if stars > int(best_stars.get(level_index, 0)):
		best_stars[level_index] = stars
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	for k in best_stars:
		cfg.set_value("best_stars", str(k), best_stars[k])
	cfg.set_value("settings", "music", music_volume)
	cfg.set_value("settings", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if cfg.has_section("best_stars"):
		for k in cfg.get_section_keys("best_stars"):
			best_stars[int(k)] = int(cfg.get_value("best_stars", k))
	music_volume = float(cfg.get_value("settings", "music", music_volume))
	sfx_volume = float(cfg.get_value("settings", "sfx", sfx_volume))


func reset_progress() -> void:
	best_stars.clear()
	save()
