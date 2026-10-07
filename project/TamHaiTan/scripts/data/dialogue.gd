class_name Dialogue
extends Resource
## บทสนทนา 1 ชุด แต่ละบรรทัดเขียนแบบ "ชื่อผู้พูด: ข้อความ"
## ผู้พูด "บรรยาย" = คำบรรยาย ไม่มีรูปตัวละคร
## แก้ข้อความได้ใน Inspector โดยไม่ต้องแตะโค้ด

@export var title: String = ""
@export var lines: PackedStringArray = []


static func split_line(line: String) -> Array:
	var i := line.find(":")
	if i < 0:
		return ["บรรยาย", line.strip_edges()]
	return [line.substr(0, i).strip_edges(), line.substr(i + 1).strip_edges()]
