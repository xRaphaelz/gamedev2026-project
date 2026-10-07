class_name LevelConfig
extends Resource
## ค่าตั้งของ 1 ด่าน

@export var level_name: String = "ด่าน 1"
@export var chapter: int = 1
## ช่วงเวลาของวัน: แสง ไฟประดับ และบรรยากาศ
@export_enum("เช้า", "กลางวัน", "เย็น") var time_of_day: int = 0
## คัตซีนก่อนเข้าด่าน (id ใน scripts/cutscene.gd, เว้นว่างได้)
@export var cutscene_before: String = ""
## เนื้อเรื่องที่เล่นก่อนเข้าด่าน (เว้นว่างได้)
@export var story_before: Dialogue
@export_multiline var intro_text: String = ""
## ความยาวด่าน (วินาที)
@export var duration: float = 180.0
## ช่วงเวลาระหว่างออเดอร์ (วินาที)
@export var order_interval: float = 30.0
@export var max_orders: int = 4
@export var recipes: Array[Recipe] = []
## คะแนนที่ได้รีวิว 5 ดาว
@export var target_score: int = 200
## false = มะละกอมาแบบสับแล้ว ไม่ต้องหั่น (ใช้ในบทแรก)
@export var require_chopping: bool = true
