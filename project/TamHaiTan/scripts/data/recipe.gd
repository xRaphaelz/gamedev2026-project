class_name Recipe
extends Resource
## สูตรอาหาร 1 เมนู — เพิ่มเมนูใหม่ได้โดยสร้างไฟล์ .tres ใหม่ ไม่ต้องแก้โค้ด

const SPICE_ID := "chili"

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


## เทียบส่วนผสม (ไม่นับพริก — จำนวนพริกคือระดับความเผ็ด ตรวจตอนเสิร์ฟ)
func matches(contents: Dictionary) -> bool:
	for key in contents:
		if str(key) != SPICE_ID and not ingredients.has(str(key)):
			return false
	for key in ingredients:
		if str(key) == SPICE_ID:
			continue
		if int(contents.get(str(key), 0)) != int(ingredients[key]):
			return false
	return true


## จำนวนพริกตามสูตรปกติ (ใช้เป็นระดับเผ็ดเมื่อด่านไม่เปิดระบบความเผ็ด)
func base_spice() -> int:
	return int(ingredients.get(SPICE_ID, 0))


## รายการวัตถุดิบ (ไม่รวมพริก ซึ่งแสดงแยกเป็นระดับเผ็ด)
func ingredient_text(with_spice := false) -> String:
	var parts: PackedStringArray = []
	for key in ingredients:
		if str(key) == SPICE_ID and not with_spice:
			continue
		var n := int(ingredients[key])
		var name := Ingredients.display_name(str(key))
		parts.append(name if n == 1 else "%s x%d" % [name, n])
	return ", ".join(parts)
