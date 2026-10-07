"""สถานีทำอาหาร และของประกอบฉากในร้าน (ฐาน 1x1 ม. ผิวบนสูง 0.9 ม.)"""
import math

from lib import *

OUT = None
WOOD = "#9A6234"
WOOD_DARK = "#6E4224"
STEEL = "#9AA2AA"


def counter_base(top_hex=STEEL, top_metal=0.3):
    wood = mat(WOOD, 0.7)
    dark = mat(WOOD_DARK, 0.75)
    box((0.96, 0.96, 0.84), (0, 0, 0.42), wood, "cab", bevel=0.02)
    # แผงประตูตู้ด้านหน้า (-Y คือด้านที่หันเข้ากล้อง/ผู้เล่น ไม่สำคัญ ใส่ทั้งสี่ด้าน)
    for ang in range(4):
        a = ang * math.pi / 2
        cx, cy = math.sin(a) * 0.485, -math.cos(a) * 0.485
        box((0.8, 0.02, 0.6), (cx, cy, 0.42), dark, "panel", rot=(0, 0, a), bevel=0.01)
        box((0.7, 0.025, 0.5), (cx * 1.005, cy * 1.005, 0.42), wood, "inset", rot=(0, 0, a))
    box((1.0, 1.0, 0.06), (0, 0, 0.87), mat(top_hex, 0.35, top_metal), "top", bevel=0.015)
    box((0.9, 0.9, 0.05), (0, 0, 0.025), dark, "kick")


def counter():
    reset(); counter_base(); join_all("counter"); export(f"{OUT}/props/counter.glb")


def counter_tray():
    reset(); counter_base()
    bam = mat("#D9B36C", 0.8)
    cyl(0.42, 0.04, (0, 0, 0.92), bam, "tray", verts=24)
    torus(0.42, 0.022, (0, 0, 0.94), mat("#B8914F", 0.8), "rim", seg=28)
    # ลายสาน
    for i in range(-3, 4):
        box((0.78 - abs(i) * 0.06, 0.012, 0.004), (0, i * 0.1, 0.942), mat("#C49D58", 0.8), "weave")
    join_all("counter_tray"); export(f"{OUT}/props/counter_tray.glb")


def counter_board():
    reset(); counter_base()
    cyl(0.34, 0.08, (0, 0, 0.94), mat("#A0683A", 0.7), "board", verts=24)
    cyl(0.31, 0.005, (0, 0, 0.982), mat("#C08A55", 0.7), "ring", verts=24)
    join_all("counter_board"); export(f"{OUT}/props/counter_board.glb")


def knife():
    reset()
    box((0.2, 0.012, 0.09), (0.06, 0, 0.045), mat("#D9DDE1", 0.25, 0.8), "blade", bevel=0.003)
    box((0.12, 0.022, 0.03), (-0.1, 0, 0.06), mat("#3A2A1E", 0.6), "handle", bevel=0.006)
    join_all("knife"); export(f"{OUT}/props/knife.glb")


def counter_plates():
    reset(); counter_base()
    for i in range(6):
        cyl(0.17, 0.03, (0, 0, 0.915 + i * 0.032), mat("#F7F5EE", 0.3), "p", r2=0.25, verts=24)
        torus(0.245, 0.008, (0, 0, 0.93 + i * 0.032), mat("#2F5DA8", 0.3), "r")
    join_all("counter_plates"); export(f"{OUT}/props/counter_plates.glb")


def counter_serve():
    reset(); counter_base(top_hex="#C8372D", top_metal=0.0)
    # ผ้าลายตาราง
    for i in range(-4, 5):
        box((1.0, 0.04, 0.004), (0, i * 0.11, 0.902), mat("#F2E6D8", 0.8), "stripe")
    cyl(0.07, 0.015, (0.33, 0.33, 0.91), mat("#B48A2C", 0.3, 0.8), "bell_base", verts=14)
    sph(0.05, (0.33, 0.33, 0.93), mat("#E0B23A", 0.25, 0.9), "bell", scale=(1, 1, 0.8))
    join_all("counter_serve"); export(f"{OUT}/props/counter_serve.glb")


def mortar():
    """ครกดินเผา + สากไม้ (Pestle แยก node เพื่อทำแอนิเมชันตำ)"""
    reset()
    clay = mat("#B4552E", 0.8)
    cyl(0.15, 0.08, (0, 0, 0.04), clay, "foot", r2=0.13, verts=16)
    cyl(0.13, 0.3, (0, 0, 0.23), clay, "bowl", r2=0.23, verts=16)
    torus(0.225, 0.02, (0, 0, 0.38), mat("#9C4626", 0.8), "lip", seg=24)
    cyl(0.2, 0.01, (0, 0, 0.372), mat("#5A2814", 0.9), "inside", verts=16)
    bowl = join_all("Bowl")
    pivot = empty("Pestle", (0, 0, 0.3))
    m = mark()
    cyl(0.032, 0.42, (0, 0, 0.5), mat("#C8A06A", 0.7), "shaft", r2=0.026, verts=10, smooth=True)
    sph(0.045, (0, 0, 0.3), mat("#B98F58", 0.7), "head", scale=(1, 1, 1.3))
    join(collect_since(m), "PestleMesh", parent=pivot)
    export(f"{OUT}/props/mortar.glb")


def trash():
    reset()
    blue = mat("#2C6FB7", 0.5)
    cyl(0.25, 0.7, (0, 0, 0.35), blue, "bin", r2=0.3, verts=16)
    torus(0.3, 0.025, (0, 0, 0.7), mat("#245C99", 0.5), "rim", seg=20)
    cyl(0.3, 0.06, (0, 0, 0.75), mat("#245C99", 0.5), "lid", r2=0.26, verts=16)
    box((0.14, 0.04, 0.04), (0, 0, 0.8), mat("#1D4B7D", 0.5), "handle")
    join_all("trash"); export(f"{OUT}/props/trash.glb")


def plastic_table():
    reset()
    col = mat("#D33A2C", 0.45)
    box((0.8, 0.8, 0.04), (0, 0, 0.7), col, "top", bevel=0.015)
    for x in (-1, 1):
        for y in (-1, 1):
            cyl(0.025, 0.68, (x * 0.33, y * 0.33, 0.34), col, "leg", verts=8)
    # เครื่องปรุงบนโต๊ะ
    for i, h in enumerate(["#7A3B12", "#E8D9A8", "#B3261E", "#F4F1E8"]):
        cyl(0.03, 0.07, (-0.12 + i * 0.08, 0.25, 0.76), mat(h, 0.4), "jar", verts=8)
    cyl(0.05, 0.12, (0.25, 0.25, 0.78), mat("#E6E9EC", 0.3, 0.3), "tissue", verts=10)
    join_all("plastic_table"); export(f"{OUT}/props/plastic_table.glb")


def plastic_stool(hex_color="#D33A2C", name="plastic_stool"):
    reset()
    col = mat(hex_color, 0.45)
    cyl(0.19, 0.42, (0, 0, 0.21), col, "body", r2=0.15, verts=14)
    cyl(0.16, 0.03, (0, 0, 0.43), col, "seat", verts=14)
    cyl(0.04, 0.035, (0, 0, 0.44), mat("#3A1410", 0.9), "hole", verts=8)
    join_all(name); export(f"{OUT}/props/{name}.glb")


def cooler():
    reset()
    box((0.7, 0.45, 0.42), (0, 0, 0.21), mat("#2F8FD8", 0.45), "body", bevel=0.03)
    box((0.72, 0.47, 0.08), (0, 0, 0.45), mat("#F5F5F5", 0.4), "lid", bevel=0.02)
    box((0.3, 0.04, 0.04), (0, 0, 0.5), mat("#D9D9D9", 0.4), "handle")
    join_all("cooler"); export(f"{OUT}/props/cooler.glb")


def crate_stack():
    reset()
    for i, (h, dx) in enumerate([("#F2C230", 0), ("#D33A2C", 0.03), ("#2F8FD8", -0.02)]):
        z = i * 0.3
        c = mat(h, 0.5)
        box((0.6, 0.4, 0.28), (dx, 0, z + 0.14), c, "crate", bevel=0.015)
        for k in range(-2, 3):
            box((0.05, 0.42, 0.12), (dx + k * 0.12, 0, z + 0.16), mat("#2A2A2A", 0.9), "slot")
    join_all("crate_stack"); export(f"{OUT}/props/crate_stack.glb")


def plant_pot():
    reset()
    cyl(0.2, 0.35, (0, 0, 0.175), mat("#B4552E", 0.8), "pot", r2=0.26, verts=12)
    r = random.Random(11)
    leaf = mat("#3E8E3A", 0.6)
    for i in range(7):
        a = i * math.tau / 7
        sph(0.12, (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.6 + r.uniform(0, 0.25)), leaf, "leaf",
            scale=(1.8, 0.6, 0.25), rot=(0.5, 0, a))
        cyl(0.012, 0.5, (math.cos(a) * 0.05, math.sin(a) * 0.05, 0.55), mat("#4E7A2A", 0.6), "stem", verts=5)
    join_all("plant_pot"); export(f"{OUT}/props/plant_pot.glb")


def umbrella():
    """ร่มสนามลายทาง"""
    reset()
    cyl(0.3, 0.08, (0, 0, 0.04), mat("#555555", 0.6), "base", verts=12)
    cyl(0.03, 2.4, (0, 0, 1.2), mat("#DDDDDD", 0.4, 0.6), "pole", verts=8)
    n = 12
    for i in range(n):
        a0 = i * math.tau / n
        col = mat("#D33A2C" if i % 2 == 0 else "#F7F1E3", 0.6)
        # แผ่นผ้าร่มทีละกลีบ
        me2 = bpy.data.meshes.new("seg")
        r = 1.5
        verts = [(0, 0, 2.6), (math.cos(a0) * r, math.sin(a0) * r, 2.15),
                 (math.cos(a0 + math.tau / n) * r, math.sin(a0 + math.tau / n) * r, 2.15)]
        me2.from_pydata(verts, [], [(0, 1, 2)])
        ob = bpy.data.objects.new("seg", me2)
        bpy.context.scene.collection.objects.link(ob)
        mod = ob.modifiers.new("s", "SOLIDIFY"); mod.thickness = 0.02
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.modifier_apply(modifier=mod.name)
        ob.data.materials.append(col)
        import lib
        lib._parts.append(ob)
    sph(0.06, (0, 0, 2.64), mat("#D33A2C", 0.5), "top")
    join_all("umbrella"); export(f"{OUT}/props/umbrella.glb")


def motorbike():
    reset()
    tire = mat("#1E1E1E", 0.9)
    body = mat("#C8372D", 0.35)
    for x in (-0.55, 0.55):
        cyl(0.27, 0.09, (x, 0, 0.27), tire, "tire", verts=18, rot=(math.pi / 2, 0, 0))
        cyl(0.14, 0.1, (x, 0, 0.27), mat("#BFC3C7", 0.3, 0.8), "hub", verts=12, rot=(math.pi / 2, 0, 0))
    box((0.7, 0.26, 0.2), (-0.05, 0, 0.5), body, "body", bevel=0.05)
    box((0.55, 0.28, 0.1), (-0.15, 0, 0.66), mat("#2A2A2A", 0.7), "seat", bevel=0.04)
    box((0.12, 0.3, 0.5), (0.45, 0, 0.6), body, "front", rot=(0, -0.35, 0), bevel=0.04)
    cyl(0.015, 0.6, (0.52, 0, 0.92), mat("#BFC3C7", 0.3, 0.8), "bar", verts=8, rot=(math.pi / 2, 0, 0))
    sph(0.07, (0.6, 0, 0.82), mat("#FFF3B0", 0.2, emit=0.5), "lamp", scale=(0.6, 1, 1))
    join_all("motorbike"); export(f"{OUT}/props/motorbike.glb")


def build_all(out):
    global OUT
    OUT = out
    counter(); counter_tray(); counter_board(); knife(); counter_plates(); counter_serve(); mortar(); trash()
    plastic_table(); plastic_stool(); plastic_stool("#2F6FC4", "plastic_stool_blue"); cooler(); crate_stack()
    plant_pot(); umbrella(); motorbike()
