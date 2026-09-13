# Lab 5 — City Parkour (First 3D Game)

เกม 3D Platformer ธีมเมือง 2 ด่าน สร้างด้วย **Godot 4.7.2**
ต่อยอดจาก [3D Platformer Starter Kit](https://store.godotengine.org/asset/the-silver-demons/platformer-3d-starter-kit/) (SD Studios)

| | |
|---|---|
| **เล่นบนเว็บ** | `https://xraphaelz.github.io/gamedev2026-project/lab5/Game/gamelab5.html` |
| **ซอร์สโค้ด** | `lab5/CityParkour/` |
| **เว็บบิลด์** | `lab5/Game/` |

## วิธีเปิดโปรเจกต์
เปิด Godot 4.7.2 → Import → เลือก `lab5/CityParkour/project.godot` → กด F5

## การควบคุม
| ปุ่ม | การทำงาน |
|---|---|
| คลิกที่จอ | ล็อกเมาส์เพื่อเริ่มเล่น (บนเว็บ) |
| W A S D | เดิน / วิ่ง |
| Space | กระโดด (กดซ้ำกลางอากาศ = Double Jump) |
| เมาส์ | หมุนกล้อง |
| R | เริ่มด่านปัจจุบันใหม่ |
| Esc | ปล่อยเมาส์ |

## ระบบการเล่น
- เก็บเหรียญให้ครบทุกเหรียญในด่าน ประตูทางออกจึงปลดล็อก (ป้ายบนประตูบอก `เก็บแล้ว / ทั้งหมด`)
- มี 3 หัวใจ โดนกับดักหรือตกจากที่สูง = เสีย 1 หัวใจ แล้วเกิดใหม่ที่เช็กพอยต์ล่าสุด หัวใจหมด = เริ่มด่านใหม่
- **ด่าน 1 Rooftop Run** — กระโดดข้ามดาดฟ้า 9 ตึก, 10 เหรียญ, แขนหมุน 3 + บล็อกทุบ 3 + ลิฟต์/แพลตฟอร์มเลื่อน 4 + เกาะลอยเก็บเหรียญโบนัส
- **ด่าน 2 Night Street** — ถนนยามค่ำ, 12 เหรียญ, รถวิ่งชน 6 คัน, หลุมถนน 3 ช่อง, เส้นทางปีนกันสาด/นั่งร้าน

## การปรับแต่งตัวละคร (ตามข้อกำหนด)
โมเดลเดิม **Gobot** (GDQuest) ถูกแทนด้วย **Animated Woman** จาก Poly Pizza (Quaternius)
Godot 4.7 นำเข้า FBX ได้โดยตรง (ufbx) พร้อม skeleton + animation แล้วแมปชุดท่าทางใน `Scripts/Player.gd`

| ท่าทางเดิม (Gobot) | ท่าทางใหม่ (Animated Woman) |
|---|---|
| Idle | `Armature\|Idle` |
| Run | `Armature\|Running` |
| Walk | `Armature\|Walking` |
| Jump | `Armature\|Jump2` |
| Flip (double jump) | `Armature\|Jump` (เล่นเร็ว 2x) |
| Hurt | `Armature\|Death` |

คลิปที่ต้องวนซ้ำ (Idle / Walk / Run) ถูกตั้ง `loop_mode = LOOP_LINEAR` ตอน `_ready()` เพราะไฟล์ FBX ส่งมาเป็น one-shot ทั้งหมด

## หมายเหตุการ Export เป็นเว็บ
- ใช้ template **web_nothreads** (`variant/thread_support=false`) เพราะ GitHub Pages ไม่ส่ง header COOP/COEP ที่ SharedArrayBuffer ต้องใช้
- renderer บนเว็บตั้งเป็น `gl_compatibility`
- เท็กซ์เจอร์ 5 ไฟล์จาก starter kit ถูกเปลี่ยนจาก VRAM Compressed เป็น Lossless เพราะเว็บบิลด์ไม่มี S3TC/ETC2 ให้โหลด
- เบราว์เซอร์อนุญาต Pointer Lock เฉพาะหลังคลิกจริง เกมจึงล็อกเมาส์เมื่อคลิกครั้งแรกแทนที่จะล็อกทันที

## เครดิต
- Starter Kit: 3D Platformer Starter Kit — SD Studios (Adil Shafiq), MIT
- โมเดล: Poly Pizza — City Pack & Animated Woman โดย Quaternius (CC0)
- ฟอนต์: Sarabun โดย Cadson Demak (SIL Open Font License)
