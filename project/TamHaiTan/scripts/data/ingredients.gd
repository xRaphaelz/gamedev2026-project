class_name Ingredients
## ฐานข้อมูลวัตถุดิบ (ใช้ id แบบ String ทั้งโปรเจกต์)

const DATA := {
	"papaya": {"name": "มะละกอ", "color": Color(0.55, 0.8, 0.35), "needs_prep": true},
	"chili": {"name": "พริก", "color": Color(0.85, 0.1, 0.1), "needs_prep": false},
	"tomato": {"name": "มะเขือเทศ", "color": Color(0.95, 0.35, 0.2), "needs_prep": false},
	"peanut": {"name": "ถั่วลิสง", "color": Color(0.78, 0.6, 0.38), "needs_prep": false},
	"crab": {"name": "ปูดอง", "color": Color(0.45, 0.25, 0.15), "needs_prep": false},
	"corn": {"name": "ข้าวโพด", "color": Color(1.0, 0.85, 0.2), "needs_prep": false},
}


static func display_name(id: String) -> String:
	return DATA.get(id, {}).get("name", id)


static func color_of(id: String) -> Color:
	return DATA.get(id, {}).get("color", Color.WHITE)


static func needs_prep(id: String) -> bool:
	return DATA.get(id, {}).get("needs_prep", false)
