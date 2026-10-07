"""ฉากหลัง: พื้นทางเท้า ถนน ตึกแถว กันสาดร้าน ชั้นวางของหลังร้าน ไฟประดับ
จัดตำแหน่งด้วยพิกัด Godot (x ขวา, y ขึ้น, z เข้าหากล้อง) ผ่านฟังก์ชัน G()
"""
import math

from lib import *

OUT = None


def G(x, y, z):
    return (x, -z, y)


def GS(sx, sy, sz):
    return (sx, sz, sy)


def ground():
    reset()
    r = random.Random(2)
    tiles = [mat("#9C968C", 0.9), mat("#918B80", 0.9), mat("#A49E94", 0.9)]
    # ทางเท้า
    for ix in range(-13, 13):
        for iz in range(-9, 7):
            box(GS(0.98, 0.1, 0.98), G(ix + 0.5, -0.05, iz + 0.5), tiles[r.randrange(3)], "tile")
    box(GS(26, 0.12, 0.3), G(0, -0.04, 7.0), mat("#9A948A", 0.9), "curb")
    box(GS(30, 0.1, 10), G(0, -0.1, 12.1), mat("#3B3B3E", 0.95), "road")
    for ix in range(-6, 7):
        box(GS(1.4, 0.02, 0.15), G(ix * 2.4, -0.04, 10.5), mat("#F2C230", 0.7), "line")
    # พื้นยางในร้าน
    box(GS(9.8, 0.04, 6.6), G(0, 0.0, -0.35), mat("#2F5E46", 0.85), "mat")
    for i in range(-4, 5):
        box(GS(9.8, 0.005, 0.03), G(0, 0.022, -0.35 + i * 0.7), mat("#28503B", 0.85), "groove")
    join_all("ground")
    export(f"{OUT}/env/ground.glb")


def shophouses():
    reset()
    walls = ["#EADBC0", "#BFD8D2", "#F0C9B8", "#E6E0A8", "#C9D3E8"]
    r = random.Random(4)
    z0 = -6.2
    for i, x in enumerate(range(-12, 13, 4)):
        wall = mat(walls[i % len(walls)], 0.85)
        box(GS(3.9, 7.0, 3.0), G(x, 3.5, z0 - 1.5), wall, "wall")
        # เสาและคานชั้นล่าง
        box(GS(0.3, 3.0, 0.3), G(x - 1.8, 1.5, z0 + 0.1), mat("#DDD5C8", 0.8), "pillar")
        kind = i % 3
        if kind == 0:  # ประตูเหล็กม้วนปิด
            box(GS(3.3, 2.7, 0.08), G(x, 1.35, z0 + 0.05), mat("#9AA0A6", 0.5, 0.4), "shutter")
            for k in range(14):
                box(GS(3.3, 0.03, 0.03), G(x, 0.2 + k * 0.18, z0 + 0.1), mat("#7D838A", 0.5, 0.4), "rib")
        else:  # หน้าร้านเปิด มีชั้นสินค้า
            box(GS(3.3, 2.7, 0.05), G(x, 1.35, z0 - 1.2), mat("#4A3A30", 0.9), "dark")
            for sh in range(3):
                y = 0.5 + sh * 0.7
                box(GS(3.0, 0.05, 0.5), G(x, y, z0 - 0.9), mat("#8A5A35", 0.8), "shelf")
                for g in range(9):
                    c = ["#D33A2C", "#F2C230", "#2F8FD8", "#3E8E3A", "#F08A24", "#FFFFFF"][r.randrange(6)]
                    h = r.uniform(0.15, 0.4)
                    box(GS(0.22, h, 0.22), G(x - 1.3 + g * 0.32, y + 0.03 + h / 2, z0 - 0.9), mat(c, 0.5), "goods")
            box(GS(1.0, 0.8, 0.6), G(x + 1.0, 0.4, z0 + 0.1), mat("#8A5A35", 0.8), "stand")
        # ป้ายร้าน
        sign_col = ["#C8372D", "#2F6FC4", "#2E8B57", "#F2C230", "#7B3FA0"][i % 5]
        box(GS(3.4, 0.6, 0.12), G(x, 3.2, z0 + 0.15), mat(sign_col, 0.5), "sign", bevel=0.02)
        # กันสาด
        for k in range(8):
            c = mat("#F7F1E3" if k % 2 else sign_col, 0.7)
            box(GS(0.44, 0.04, 1.0), G(x - 1.55 + k * 0.44, 2.75, z0 + 0.6), c, "awn", rot=(math.radians(-20), 0, 0))
        # ชั้นบน: หน้าต่าง + แอร์
        for wx in (-0.9, 0.9):
            box(GS(1.1, 1.3, 0.08), G(x + wx, 4.8, z0 + 0.02), mat("#5E7C8C", 0.2, 0.3), "win")
            box(GS(1.25, 0.08, 0.15), G(x + wx, 4.1, z0 + 0.08), mat("#FFFFFF", 0.6), "sill")
            for b in range(4):
                box(GS(0.04, 1.3, 0.05), G(x + wx - 0.45 + b * 0.3, 4.8, z0 + 0.09), mat("#3A3A3A", 0.6), "bar")
        box(GS(0.8, 0.5, 0.35), G(x + 0.0, 5.8, z0 + 0.2), mat("#F2F2F2", 0.5), "ac")
        box(GS(4.0, 0.25, 0.4), G(x, 7.1, z0 + 0.1), mat("#DDD5C8", 0.8), "cornice")
    join_all("shophouses")
    export(f"{OUT}/env/shophouses.glb")


def stall():
    """โครงร้าน: เสา กันสาดหลัง ป้าย ชั้นวางหลังร้าน"""
    reset()
    steel = mat("#8E959C", 0.4, 0.6)
    for x in (-4.85, 4.85):
        for z in (-3.65, 2.85):
            cyl(0.06, 3.1, G(x, 1.55, z), steel, "post", verts=8)
        box(GS(0.08, 0.08, 6.5), G(x, 3.05, -0.4), steel, "rail")
    # กันสาดหลัง ลายทางแดง-ขาว เอียงลงหาหลังร้าน
    n = 22
    for k in range(n):
        c = mat("#C8372D" if k % 2 == 0 else "#F7F1E3", 0.7)
        box(GS(10.2 / n, 0.04, 2.4), G(-5.1 + (k + 0.5) * 10.2 / n, 3.35, -4.45), c, "tarp",
            rot=(math.radians(-14), 0, 0))
    # ระบายผ้าหน้ากันสาด
    for k in range(n):
        c = mat("#F7F1E3" if k % 2 == 0 else "#C8372D", 0.7)
        box(GS(10.2 / n, 0.3, 0.03), G(-5.1 + (k + 0.5) * 10.2 / n, 2.98, -3.3), c, "valance")
    # ป้ายร้าน (ตัวหนังสือใส่ใน Godot)
    box(GS(5.2, 0.9, 0.12), G(0, 3.75, -3.35), mat("#F7E7B4", 0.6), "signboard", bevel=0.04)
    box(GS(5.4, 1.06, 0.08), G(0, 3.75, -3.42), mat("#C8372D", 0.6), "signframe", bevel=0.03)
    for x in (-2.0, 2.0):
        box(GS(0.06, 0.5, 0.06), G(x, 3.1, -3.4), steel, "hanger")
    # ชั้นวางหลังร้าน
    wood = mat("#7A4A28", 0.8)
    box(GS(9.4, 0.06, 0.45), G(0, 1.25, -4.05), wood, "shelf1")
    box(GS(9.4, 0.06, 0.45), G(0, 1.75, -4.05), wood, "shelf2")
    box(GS(9.6, 2.2, 0.06), G(0, 1.1, -4.3), mat("#A87B4F", 0.85), "backboard")
    r = random.Random(9)
    for shelf_y in (1.28, 1.78):
        x = -4.4
        while x < 4.4:
            kind = r.randrange(4)
            if kind == 0:  # ขวดน้ำปลา
                cyl(0.06, 0.28, G(x, shelf_y + 0.14, -4.05), mat("#7A3B12", 0.2), "bottle", verts=8)
                cyl(0.025, 0.06, G(x, shelf_y + 0.31, -4.05), mat("#D33A2C", 0.4), "cap", verts=6)
            elif kind == 1:  # โหลน้ำตาลปี๊บ
                cyl(0.11, 0.22, G(x, shelf_y + 0.11, -4.05), mat("#E8D9A8", 0.2), "jar", verts=10)
                cyl(0.11, 0.04, G(x, shelf_y + 0.24, -4.05), mat("#2F8FD8", 0.4), "lid", verts=10)
            elif kind == 2:  # ตะกร้ามะนาว
                cyl(0.14, 0.1, G(x, shelf_y + 0.05, -4.05), mat("#C49D58", 0.8), "basket", verts=10)
                for k in range(5):
                    sph(0.045, G(x + (k - 2) * 0.05, shelf_y + 0.12, -4.05 + (k % 2) * 0.05), mat("#7CC243", 0.4), "lime",
                        seg=6, rings=4)
            else:  # กระเทียม/หอม
                for k in range(3):
                    sph(0.06, G(x + (k - 1) * 0.08, shelf_y + 0.06, -4.05), mat("#F1E9DA", 0.6), "garlic",
                        scale=(1, 1, 0.8), seg=8, rings=5)
            x += r.uniform(0.35, 0.55)
    # พวงพริกแห้งห้อย
    for x in (-3.8, 3.8):
        for k in range(6):
            cyl(0.03, 0.12, G(x + r.uniform(-0.05, 0.05), 2.6 - k * 0.1, -4.15), mat("#A3201A", 0.5), "dried",
                r2=0.005, verts=6, rot=(r.uniform(-.4, .4), r.uniform(-.4, .4), 0))
    join_all("stall")
    export(f"{OUT}/env/stall.glb")


def bulbs():
    """หลอดไฟประดับ (แยกไฟล์เพื่อให้ Godot ปรับความสว่างตามเวลา)"""
    reset()
    wire = mat("#222222", 0.8)
    bulb_cols = ["#FFE08A", "#FFB86B", "#FFF3C4"]
    pts = []
    # ตามขอบกันสาด
    for i in range(17):
        t = i / 16
        x = -4.8 + t * 9.6
        sag = 0.25 * math.sin(t * math.pi * 3) ** 2
        pts.append((x, 2.8 - sag, -3.22))
    # ตามรางด้านข้าง
    for side in (-4.85, 4.85):
        for i in range(9):
            t = i / 8
            z = -3.5 + t * 6.2
            pts.append((side, 2.92 - 0.18 * math.sin(t * math.pi * 2) ** 2, z))
    for i, (x, y, z) in enumerate(pts):
        sph(0.06, G(x, y - 0.08, z), mat(bulb_cols[i % 3], 0.3, emit=3.0), "bulb", seg=8, rings=5)
        cyl(0.025, 0.06, G(x, y - 0.01, z), wire, "socket", verts=6)
    join_all("bulbs")
    export(f"{OUT}/env/bulbs.glb")


def tree():
    reset()
    cyl(0.14, 2.2, G(0, 1.1, 0), mat("#6B4A2A", 0.9), "trunk", r2=0.1, verts=8)
    leaf = [mat("#3E8E3A", 0.7), mat("#4FA346", 0.7), mat("#2F7A33", 0.7)]
    r = random.Random(6)
    for i in range(7):
        sph(r.uniform(0.6, 0.9), G(r.uniform(-0.6, 0.6), 2.4 + r.uniform(0, 0.9), r.uniform(-0.6, 0.6)),
            leaf[i % 3], "crown", seg=8, rings=6, smooth=False)
    cyl(0.5, 0.15, G(0, 0.075, 0), mat("#9A948A", 0.9), "ring", verts=12)
    join_all("tree")
    export(f"{OUT}/env/tree.glb")


def build_all(out):
    global OUT
    OUT = out
    ground(); shophouses(); stall(); bulbs(); tree()
