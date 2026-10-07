class_name StarRow
extends Control
## วาดดาวรีวิว 1-5 ดวง (ฟอนต์ไทยไม่มีตัวอักษร ★ จึงวาดเอง)

@export var stars := 0:
	set(v):
		stars = v
		queue_redraw()
@export var star_size := 36.0


func _init() -> void:
	custom_minimum_size = Vector2(star_size * 5 + 32, star_size)


func _draw() -> void:
	for i in 5:
		var c := Vector2(star_size / 2 + i * (star_size + 8), star_size / 2)
		var col := Color(1, 0.78, 0.15) if i < stars else Color(0.45, 0.35, 0.25, 0.22)
		draw_colored_polygon(_star_points(c, star_size / 2, star_size / 4.6), col)


static func _star_points(center: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var r := r_out if k % 2 == 0 else r_in
		var a := -PI / 2 + k * PI / 5
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts
