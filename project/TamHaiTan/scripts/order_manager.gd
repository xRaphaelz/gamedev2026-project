class_name OrderManager
extends Node
## สุ่มออเดอร์ นับเวลา คิดคะแนน (ความเผ็ด คอมโบ ทิป) เหตุการณ์สุ่ม และสรุปรีวิวตอนจบด่าน

signal orders_changed
signal order_added(order: Order)
## served = true เสิร์ฟสำเร็จ / false รอไม่ไหว
signal order_removed(order: Order, served: bool)
signal score_changed(score: int)
signal level_finished(score: int, stars: int, stats: Dictionary)
## คอมโบเปลี่ยน: count = จำนวนจานถูกติดกัน, mult = ตัวคูณคะแนน
signal combo_changed(count: int, mult: float)
## เสิร์ฟสำเร็จ 1 จาน พร้อมรายละเอียดคะแนน {base, mult, tip, total, spice_off, reviewer}
signal served_detail(order: Order, detail: Dictionary)
## เหตุการณ์สุ่ม: เตือนล่วงหน้า 3 วิ -> เริ่ม -> จบ (เหตุการณ์ครั้งเดียวจะไม่มี ended)
signal event_warning(id: String, title: String, desc: String)
signal event_started(id: String, duration: float)
signal event_ended(id: String)

## ลูกค้าแต่ละประเภทรอได้ไม่เท่ากัน (วินาที) และชอบเผ็ดไม่เท่ากัน (จำนวนพริก)
const CUSTOMERS := [
	{"name": "ไรเดอร์", "patience": 45.0, "model": "rider", "spice": [2, 3]},
	{"name": "พนักงานออฟฟิศ", "patience": 65.0, "model": "office", "spice": [1, 2]},
	{"name": "นักท่องเที่ยว", "patience": 90.0, "model": "tourist", "spice": [0, 1]},
]
const EXPIRE_PENALTY := 10
const WRONG_PENALTY := 5
## เผ็ดขาด/เกิน 1 เม็ด เหลือคะแนนจานนี้ 75%  (ห่างกว่านั้น = ส้มตำมั่ว)
const SPICE_OFF_RATE := 0.75
## ทิปตามความเร็ว: ใช้เวลาไม่ถึง 40% ของที่ลูกค้ารอได้ = +15, ไม่ถึง 70% = +5
const TIP_FAST := 15
const TIP_OK := 5
## คอมโบ: [จำนวนจานติดกันขั้นต่ำ, ตัวคูณ]
const COMBO_TIERS := [[6, 3.0], [4, 2.0], [2, 1.5]]
const SEATS := 6

const EVENTS := {
	"tour": {"title": "ทัวร์ลง!", "desc": "ลูกค้ามาพร้อมกัน 3 คน สั่งเมนูเดียวกัน", "duration": 0.0},
	"rain": {"title": "ฝนตก", "desc": "ลูกค้ามาช้าลง แต่ให้ทิป x2", "duration": 30.0},
	"rush": {"title": "ชั่วโมงเร่งด่วน!", "desc": "ลูกค้ามาถี่ขึ้น และรอได้สั้นลง", "duration": 25.0},
	"reviewer": {"title": "นักรีวิวแฝงตัว", "desc": "ลูกค้าใส่แว่นดำ เสิร์ฟถูกได้ x2 ปล่อยรอนานโดนหัก x2", "duration": 0.0},
	"papaya_out": {"title": "มะละกอหมด!", "desc": "กด Space รัว ๆ ที่กล่องมะละกอเพื่อแกะลังใหม่", "duration": 20.0},
}
const EVENT_WARN := 3.0


class Order:
	var recipe: Recipe
	var customer: String
	var model: String
	var patience: float
	var time_left: float
	## จำนวนพริกที่สั่ง
	var spice: int = 1
	## นักรีวิวแฝงตัว: คะแนน/โทษ x2
	var reviewer := false

	func ratio() -> float:
		return clampf(time_left / patience, 0.0, 1.0)

	## 2 = ยิ้ม, 1 = เฉย ๆ, 0 = หงุดหงิด
	func mood() -> int:
		var r := ratio()
		return 2 if r > 0.6 else (1 if r > 0.3 else 0)


var config: LevelConfig
var orders: Array[Order] = []
var score := 0
var time_left := 0.0
var running := false
var stats := {}
var combo := 0
## เหตุการณ์ที่กำลังเกิด id -> เวลาที่เหลือ
var active_events := {}

var _spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()
## [เวลาที่เหลือของด่านตอนเตือน, id]
var _event_plan: Array = []
var _pending_event := ""
var _pending_t := 0.0


func _ready() -> void:
	add_to_group("order_manager")
	_rng.randomize()


func start(cfg: LevelConfig) -> void:
	config = cfg
	orders.clear()
	score = 0
	combo = 0
	stats = {"served": 0, "expired": 0, "wrong": 0, "food": 0, "tips": 0, "combo_bonus": 0,
		"max_combo": 0, "spice_off": 0, "events": []}
	active_events.clear()
	time_left = cfg.duration
	_spawn_timer = 2.0  # ออเดอร์แรกมาเร็ว
	_plan_events()
	running = true
	orders_changed.emit()
	score_changed.emit(score)
	combo_changed.emit(0, 1.0)


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
			var pen := EXPIRE_PENALTY * (2 if o.reviewer else 1)
			_add_score(-pen)
			_break_combo()
			GameState.toast("%s รอไม่ไหว กลับไปแล้ว! -%d" % ["นักรีวิว" if o.reviewer else o.customer, pen], false)
			orders_changed.emit()

	_update_events(delta)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = config.order_interval * _interval_scale()
		if orders.size() < config.max_orders:
			add_random_order()


func add_random_order(customer := {}, recipe: Recipe = null, reviewer := false) -> Order:
	if config.recipes.is_empty():
		return null
	var c: Dictionary = customer if not customer.is_empty() else CUSTOMERS[_rng.randi_range(0, CUSTOMERS.size() - 1)]
	var o := Order.new()
	o.recipe = recipe if recipe else config.recipes[_rng.randi_range(0, config.recipes.size() - 1)]
	o.customer = c.name
	o.model = c.model
	o.patience = c.patience * (0.8 if active_events.has("rush") else 1.0)
	o.time_left = o.patience
	if config.spice_enabled:
		var r: Array = c.get("spice", [1, 1])
		o.spice = _rng.randi_range(r[0], r[1])
	else:
		o.spice = o.recipe.base_spice()
	o.reviewer = reviewer
	orders.append(o)
	order_added.emit(o)
	orders_changed.emit()
	return o


## dish = null หมายถึงส้มตำมั่ว / spice = จำนวนพริกในจาน คืนค่า true ถ้าจานถูกรับไป
func serve(dish: Recipe, spice := -1) -> bool:
	if not running:
		return false
	if dish == null:
		_wrong_dish("ลูกค้าบ่น: รสชาติแปลก ๆ!")
		return true
	if spice < 0:
		spice = dish.base_spice()
	# เลือกออเดอร์เมนูนี้ที่เผ็ดใกล้เคียงที่สุด แล้วค่อยดูว่าใครใกล้หมดเวลา
	var best: Order = null
	for o in orders:
		if o.recipe.id != dish.id:
			continue
		if best == null:
			best = o
			continue
		var d := absi(o.spice - spice)
		var bd := absi(best.spice - spice)
		if d < bd or (d == bd and o.time_left < best.time_left):
			best = o
	if best == null:
		GameState.toast("ไม่มีใครสั่ง%s" % dish.display_name, false)
		return false
	var off := absi(best.spice - spice)
	if off >= 2:
		_wrong_dish("เผ็ดผิด! ลูกค้าสั่ง%s" % Item.spice_text(best.spice))
		return true
	orders.erase(best)
	Audio.sfx("serve", -3.0)
	order_removed.emit(best, true)

	var base := dish.score
	if off == 1:
		base = int(round(dish.score * SPICE_OFF_RATE))
		stats.spice_off += 1
	combo += 1
	stats.max_combo = maxi(stats.max_combo, combo)
	var mult := combo_mult()
	var food := int(round(base * mult))
	var tip := tip_for(best)
	var total := food + tip
	if best.reviewer:
		total *= 2
	stats.served += 1
	stats.food += base
	stats.combo_bonus += food - base + (total - food - tip if best.reviewer else 0)
	stats.tips += tip
	_add_score(total)
	combo_changed.emit(combo, mult)
	var msg := "เสิร์ฟ%s +%d" % [dish.display_name, total]
	if off == 1:
		msg += " (เผ็ดไม่ตรง -25%)"
	GameState.toast(msg, off == 0)
	served_detail.emit(best, {"base": base, "mult": mult, "tip": tip, "total": total,
		"spice_off": off, "reviewer": best.reviewer})
	orders_changed.emit()
	if orders.is_empty():
		_spawn_timer = minf(_spawn_timer, 3.0)
	return true


func combo_mult() -> float:
	for t in COMBO_TIERS:
		if combo >= int(t[0]):
			return float(t[1])
	return 1.0


func tip_for(o: Order) -> int:
	var used := 1.0 - o.ratio()
	var tip := TIP_FAST if used < 0.4 else (TIP_OK if used < 0.7 else 0)
	if active_events.has("rain"):
		tip *= 2
	return tip


func _wrong_dish(msg: String) -> void:
	stats.wrong += 1
	Audio.sfx("wrong")
	_add_score(-WRONG_PENALTY)
	_break_combo()
	GameState.toast("%s -%d" % [msg, WRONG_PENALTY], false)


func _break_combo() -> void:
	if combo >= 2:
		GameState.toast("คอมโบหลุด!", false)
	combo = 0
	combo_changed.emit(0, 1.0)


func _add_score(n: int) -> void:
	score = max(score + n, 0)
	score_changed.emit(score)


# ---------------- เหตุการณ์สุ่ม ----------------

func _plan_events() -> void:
	_event_plan.clear()
	_pending_event = ""
	if config.event_count <= 0:
		return
	var pool := EVENTS.keys()
	if not _has_papaya_recipe():
		pool.erase("papaya_out")
	pool.shuffle()
	var n := mini(config.event_count, pool.size())
	# กระจายช่วงเวลา: ช่วงกลางด่าน ไม่ชนกัน และไม่เกิดใน 30 วิสุดท้าย
	var d := config.duration
	for i in n:
		var lo := d * (0.78 - 0.45 * float(i) / n)
		var hi := d * (0.78 - 0.45 * float(i + 1) / n) + 6.0
		_event_plan.append([_rng.randf_range(hi, lo), pool[i]])


func _has_papaya_recipe() -> bool:
	for r in config.recipes:
		if r.ingredients.has("papaya"):
			return true
	return false


func _interval_scale() -> float:
	var s := 1.0
	if active_events.has("rain"):
		s *= 1.6
	if active_events.has("rush"):
		s *= 0.5
	return s


func _update_events(delta: float) -> void:
	for e in _event_plan.duplicate():
		if time_left <= e[0]:
			_event_plan.erase(e)
			var info: Dictionary = EVENTS[e[1]]
			_pending_event = e[1]
			_pending_t = EVENT_WARN
			Audio.sfx("order", 0.0, 0.0)
			event_warning.emit(e[1], info.title, info.desc)
	if _pending_event != "":
		_pending_t -= delta
		if _pending_t <= 0.0:
			start_event(_pending_event)
			_pending_event = ""
	for id in active_events.keys():
		active_events[id] -= delta
		if active_events[id] <= 0.0:
			end_event(id)


func start_event(id: String) -> void:
	var info: Dictionary = EVENTS[id]
	stats.events.append(info.title)
	match id:
		"tour":
			var r: Recipe = config.recipes[_rng.randi_range(0, config.recipes.size() - 1)]
			var tour := {"name": "ทัวร์", "patience": 90.0, "model": "tourist", "spice": [0, 1]}
			for i in clampi(SEATS - orders.size(), 0, 3):
				add_random_order(tour, r)
		"reviewer":
			add_random_order({"name": "นักรีวิว", "patience": 70.0, "model": "office", "spice": [1, 2]}, null, true)
		"rush":
			_spawn_timer = minf(_spawn_timer, 1.0)
	if float(info.duration) > 0.0:
		active_events[id] = float(info.duration)
	event_started.emit(id, float(info.duration))


func end_event(id: String) -> void:
	if not active_events.has(id):
		return
	active_events.erase(id)
	event_ended.emit(id)


func stars_for(s: int) -> int:
	if config == null or config.target_score <= 0:
		return 1
	return clampi(int(floor(float(s) / config.target_score * 5.0)), 1, 5)


func _finish() -> void:
	running = false
	for id in active_events.keys():
		end_event(id)
	var stars := stars_for(score)
	level_finished.emit(score, stars, stats)
