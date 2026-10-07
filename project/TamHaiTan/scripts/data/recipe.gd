class_name Recipe
extends Resource
## สูตรอาหาร 1 เมนู — เพิ่มเมนูใหม่ได้โดยสร้างไฟล์ .tres ใหม่ ไม่ต้องแก้โค้ด

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
## id วัตถุดิบ -> จำนวน เช่น {"papaya": 1, "chili": 2}
@export var ingredients: Dictionary = {}
## จำนวนครั้งที่ต้องกดตำ
@export var pound_hits: int = 10
@export var score: int = 20
@export var unlock_chapter: int = 1
## สีของจานที่ทำเสร็จ (ใช้แทนโมเดลไปก่อน)
@export var dish_color: Color = Color.WHITE


func matches(contents: Dictionary) -> bool:
	if contents.size() != ingredients.size():
		return false
	for key in ingredients:
		if int(contents.get(str(key), 0)) != int(ingredients[key]):
			return false
	return true


func ingredient_text() -> String:
	var parts: PackedStringArray = []
	for key in ingredients:
		var n := int(ingredients[key])
		var name := Ingredients.display_name(str(key))
		parts.append(name if n == 1 else "%s x%d" % [name, n])
	return ", ".join(parts)
