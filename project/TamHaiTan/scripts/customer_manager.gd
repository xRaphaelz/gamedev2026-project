class_name CustomerManager
extends Node3D
## สร้างลูกค้าตามออเดอร์: นั่งที่ว่าง (Marker3D ลูกของ Seats) แล้วเดินกลับเมื่อได้อาหาร/รอไม่ไหว

@export var order_manager: OrderManager
@export var seats_root: Node3D
## จุดเดินเข้า-ออกฝั่งซ้าย/ขวา
@export var exit_left := Vector3(-11.5, 0, 6.0)
@export var exit_right := Vector3(11.5, 0, 6.0)

var _by_order := {}  # Order -> Customer
var _taken := {}  # Marker3D -> true
var _recent := {}  # Order -> Customer ที่เพิ่งได้อาหาร (สำหรับแสดงทิป)


func _ready() -> void:
	order_manager.order_added.connect(_on_added)
	order_manager.order_removed.connect(_on_removed)
	order_manager.served_detail.connect(_on_served)
	order_manager.level_finished.connect(func(_a, _b, _c): _everyone_leaves())


func _free_seats() -> Array[Marker3D]:
	var out: Array[Marker3D] = []
	for s in seats_root.get_children():
		if s is Marker3D and not _taken.has(s):
			out.append(s)
	return out


func _on_added(o: OrderManager.Order) -> void:
	var seats := _free_seats()
	if seats.is_empty():
		return
	var seat: Marker3D = seats.pick_random()
	_taken[seat] = true
	var c := Customer.new()
	add_child(c)
	var spawn := exit_left if seat.global_position.x < 0 else exit_right
	c.setup(o, seat, spawn)
	_by_order[o] = c


func _on_removed(o: OrderManager.Order, served: bool) -> void:
	var c: Customer = _by_order.get(o)
	if c == null:
		return
	_by_order.erase(o)
	if served:
		_recent = {o: c}
	_release(c, served)


func _on_served(o: OrderManager.Order, detail: Dictionary) -> void:
	var c: Customer = _recent.get(o)
	if c and is_instance_valid(c):
		c.show_tip(int(detail.tip), bool(detail.reviewer))


func _release(c: Customer, served: bool) -> void:
	var exit := exit_left if c.global_position.x < 0 else exit_right
	_taken.erase(c.seat)
	c.leave(served, exit)


func _everyone_leaves() -> void:
	for o in _by_order.keys():
		_release(_by_order[o], true)
	_by_order.clear()
