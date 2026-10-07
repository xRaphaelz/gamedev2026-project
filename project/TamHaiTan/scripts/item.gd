class_name Item
extends Node3D
## ของที่ผู้เล่นถือได้: วัตถุดิบ หรือ จาน
## โมเดลอยู่ใน assets/models/ingredients และ dishes (ตั้งชื่อไฟล์ตาม id)

enum Kind { INGREDIENT, PLATE }

var kind: Kind = Kind.INGREDIENT
var ingredient_id: String = ""
var prepared: bool = false
## สำหรับจาน: เมนูที่อยู่ในจาน (null = จานเปล่า)
var dish: Recipe = null
## true = ตำผิดสูตร
var dish_failed: bool = false

var _visual: Node3D


static func make_ingredient(id: String, is_prepared: bool) -> Item:
	var item := Item.new()
	item.kind = Kind.INGREDIENT
	item.ingredient_id = id
	item.prepared = is_prepared or not Ingredients.needs_prep(id)
	item.name = "Item_" + id
	return item


static func make_plate() -> Item:
	var item := Item.new()
	item.kind = Kind.PLATE
	item.name = "Plate"
	return item


func _ready() -> void:
	_rebuild_visual()


func is_plate() -> bool:
	return kind == Kind.PLATE


func is_empty_plate() -> bool:
	return kind == Kind.PLATE and dish == null and not dish_failed


func has_dish() -> bool:
	return kind == Kind.PLATE and (dish != null or dish_failed)


func set_prepared() -> void:
	prepared = true
	_rebuild_visual()


func set_dish(recipe: Recipe, failed: bool) -> void:
	dish = recipe
	dish_failed = failed
	_rebuild_visual()


func clear_dish() -> void:
	dish = null
	dish_failed = false
	_rebuild_visual()


func describe() -> String:
	if kind == Kind.PLATE:
		if dish_failed:
			return "ส้มตำมั่ว"
		if dish:
			return dish.display_name
		return "จานเปล่า"
	var n := Ingredients.display_name(ingredient_id)
	if Ingredients.needs_prep(ingredient_id):
		n += " (สับแล้ว)" if prepared else " (ยังไม่หั่น)"
	return n


## path ของโมเดลตามสถานะของไอเท็ม
func model_path() -> String:
	if kind == Kind.PLATE:
		if dish_failed:
			return "res://assets/models/dishes/dish_fail.glb"
		if dish:
			return "res://assets/models/dishes/dish_%s.glb" % dish.id
		return "res://assets/models/dishes/plate.glb"
	return ingredient_model_path(ingredient_id, prepared)


static func ingredient_model_path(id: String, is_prepared: bool) -> String:
	if is_prepared and Ingredients.needs_prep(id):
		return "res://assets/models/ingredients/%s_shred.glb" % id
	return "res://assets/models/ingredients/%s.glb" % id


static func instance_model(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	return (load(path) as PackedScene).instantiate()


func _rebuild_visual() -> void:
	if _visual:
		_visual.queue_free()
	_visual = Node3D.new()
	add_child(_visual)
	var model := instance_model(model_path())
	if model:
		_visual.add_child(model)
		Stylize.apply(model)
		return
	# สำรอง: รูปทรงพื้นฐาน ถ้าไม่มีไฟล์โมเดล
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.3
	mi.mesh = sph
	mi.position.y = 0.15
	var c := Color(0.95, 0.95, 0.92) if kind == Kind.PLATE else Ingredients.color_of(ingredient_id)
	mi.material_override = _mat(c)
	_visual.add_child(mi)


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
