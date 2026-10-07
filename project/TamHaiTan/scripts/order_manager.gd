class_name OrderManager
extends Node
## สุ่มออเดอร์ นับเวลา คิดคะแนน และสรุปรีวิวตอนจบด่าน

signal orders_changed
signal order_added(order: Order)
## served = true เสิร์ฟสำเร็จ / false รอไม่ไหว
signal order_removed(order: Order, served: bool)
signal score_changed(score: int)
signal level_finished(score: int, stars: int, stats: Dictionary)

## ลูกค้าแต่ละประเภทรอได้ไม่เท่ากัน (วินาที)
const CUSTOMERS := [
	{"name": "ไรเดอร์", "patience": 45.0, "model": "rider"},
	{"name": "พนักงานออฟฟิศ", "patience": 65.0, "model": "office"},
	{"name": "นักท่องเที่ยว", "patience": 90.0, "model": "tourist"},
]
const EXPIRE_PENALTY := 10
const WRONG_PENALTY := 5
const TIME_BONUS_MAX := 10


class Order:
	var recipe: Recipe
	var customer: String
	var model: String
	var patience: float
	var time_left: float

	func ratio() -> float:
		return clampf(time_left / patience, 0.0, 1.0)


var config: LevelConfig
var orders: Array[Order] = []
var score := 0
var time_left := 0.0
var running := false
var stats := {"served": 0, "expired": 0, "wrong": 0}

var _spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("order_manager")


func start(cfg: LevelConfig) -> void:
	config = cfg
	orders.clear()
	score = 0
	stats = {"served": 0, "expired": 0, "wrong": 0}
	time_left = cfg.duration
	_spawn_timer = 2.0  # ออเดอร์แรกมาเร็ว
	running = true
	orders_changed.emit()
	score_changed.emit(score)


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_finish()
		return

	for o in orders.duplicate():
		o.time_left -= delta
		if o.time_left <= 0.0:
			orders.erase(o)
			order_removed.emit(o, false)
			stats.expired += 1
			_add_score(-EXPIRE_PENALTY)
			GameState.toast("%s รอไม่ไหว กลับไปแล้ว! -%d" % [o.customer, EXPIRE_PENALTY], false)
			orders_changed.emit()

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = config.order_interval
		if orders.size() < config.max_orders:
			add_random_order()


func add_random_order() -> Order:
	if config.recipes.is_empty():
		return null
	var c: Dictionary = CUSTOMERS[_rng.randi_range(0, CUSTOMERS.size() - 1)]
	var o := Order.new()
	o.recipe = config.recipes[_rng.randi_range(0, config.recipes.size() - 1)]
	o.customer = c.name
	o.model = c.model
	o.patience = c.patience
	o.time_left = c.patience
	orders.append(o)
	order_added.emit(o)
	orders_changed.emit()
	return o


## dish = null หมายถึงส้มตำมั่ว คืนค่า true ถ้าจานถูกรับไป
func serve(dish: Recipe) -> bool:
	if not running:
		return false
	if dish == null:
		stats.wrong += 1
		Audio.sfx("wrong")
		_add_score(-WRONG_PENALTY)
		GameState.toast("ลูกค้าบ่น: รสชาติแปลก ๆ! -%d" % WRONG_PENALTY, false)
		return true
	# เสิร์ฟให้ออเดอร์ที่ใกล้หมดเวลาที่สุดก่อน
	var best: Order = null
	for o in orders:
		if o.recipe.id == dish.id and (best == null or o.time_left < best.time_left):
			best = o
	if best == null:
		GameState.toast("ไม่มีใครสั่ง%s" % dish.display_name, false)
		return false
	orders.erase(best)
	Audio.sfx("serve", -3.0)
	order_removed.emit(best, true)
	var bonus := int(round(best.ratio() * TIME_BONUS_MAX))
	stats.served += 1
	_add_score(dish.score + bonus)
	GameState.toast("เสิร์ฟ%s +%d" % [dish.display_name, dish.score + bonus], true)
	orders_changed.emit()
	if orders.is_empty():
		_spawn_timer = minf(_spawn_timer, 3.0)
	return true


func _add_score(n: int) -> void:
	score = max(score + n, 0)
	score_changed.emit(score)


func stars_for(s: int) -> int:
	if config == null or config.target_score <= 0:
		return 1
	return clampi(int(floor(float(s) / config.target_score * 5.0)), 1, 5)


func _finish() -> void:
	running = false
	var stars := stars_for(score)
	level_finished.emit(score, stars, stats)
