"""สร้างโมเดลทั้งหมดของเกม
รัน: python3 tools/blender/build.py [food|props|env|chars|icons|all]
(ต้องมี bpy: pip install bpy หรือรันผ่าน blender --background --python ...)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")
ICONS = os.path.join(ROOT, "assets", "icons")

what = sys.argv[1] if len(sys.argv) > 1 else "all"

if what in ("food", "all"):
    import food
    food.build_all(OUT)
if what in ("props", "all"):
    import props
    props.build_all(OUT)
if what in ("env", "all"):
    import env
    env.build_all(OUT)
if what in ("chars", "all"):
    import chars
    chars.build_all(OUT)
if what in ("icons", "all"):
    import icons
    icons.build_all(OUT, ICONS)
