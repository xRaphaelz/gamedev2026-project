"""ตัวละครทรงชิบิ ชิ้นส่วนแยกตามข้อต่อ (Godot ขยับเองด้วยโค้ดใน character_rig.gd)
โครงสร้าง node: Rig > Torso, Head, ArmL, ArmR, LegL, LegR (pivot อยู่ที่ข้อต่อ)
ตัวละครหันหน้าไปทาง +Y ใน Blender (= -Z ใน Godot)
"""
import math

from lib import *

OUT = None

SPECS = {
    "tom": dict(skin="#E2A877", shirt="#F5F5F0", pants="#2F4C7A", shoes="#333333", hair="#1E1A18",
                hair_style="spiky", apron="#3E8E3A", headband="#D33A2C"),
    "daeng": dict(skin="#D69A6B", shirt="#C8372D", pants="#6A3E8E", shoes="#5A3A22", hair="#2A2220",
                  hair_style="bun", apron="#F2E6D8", glasses="#C9A13A", flower="#F2C230"),
    "rider": dict(skin="#C98E62", shirt="#3FA34D", pants="#2B2B2B", shoes="#222222", hair="#1E1A18",
                  hair_style="helmet", helmet="#3FA34D", backpack="#3FA34D"),
    "office": dict(skin="#E8B48A", shirt="#F0F4F8", pants="#2B2F3A", shoes="#1E1E1E", hair="#1E1A18",
                   hair_style="neat", tie="#1F3A68", lanyard="#2F6FC4"),
    "jeh_hong": dict(skin="#E0A27A", shirt="#D63384", pants="#2B2B2B", shoes="#C9A13A", hair="#5A2E1E",
                     hair_style="bun", apron="#F2C230", glasses="#1E1E1E", flower="#F25C9A", necklace="#E0B23A"),
    "tourist": dict(skin="#F4D1B5", shirt="#F08A24", pants="#D9C9A3", shoes="#8A6A4A", hair="#E8C77A",
                    hair_style="hat", hat="#E3C886", dots="#FFFFFF", camera="#2A2A2A", shorts=True),
}


def part(name, loc, rig):
    return empty(name, loc, rig)


def finish_part(m, name, pivot):
    objs = collect_since(m)
    if objs:
        join(objs, name + "Mesh", parent=pivot)


def build(cname, s):
    reset()
    skin = mat(s["skin"], 0.6)
    shirt = mat(s["shirt"], 0.7)
    pants = mat(s["pants"], 0.7)
    shoes = mat(s["shoes"], 0.6)
    hair = mat(s["hair"], 0.7)
    rig = empty("Rig")

    # ---- ขา ----
    for side, nm in ((-1, "LegL"), (1, "LegR")):
        piv = part(nm, (side * 0.09, 0, 0.36), rig)
        m = mark()
        if s.get("shorts"):
            box((0.14, 0.16, 0.13), (side * 0.09, 0, 0.3), pants, "short", bevel=0.02)
            box((0.1, 0.11, 0.18), (side * 0.09, 0, 0.15), skin, "shin", bevel=0.02)
        else:
            box((0.13, 0.15, 0.3), (side * 0.09, 0, 0.21), pants, "leg", bevel=0.03)
        box((0.14, 0.22, 0.08), (side * 0.09, 0.03, 0.04), shoes, "shoe", bevel=0.03)
        finish_part(m, nm, piv)

    # ---- ลำตัว ----
    piv = part("Torso", (0, 0, 0.36), rig)
    m = mark()
    box((0.42, 0.28, 0.4), (0, 0, 0.56), shirt, "torso", bevel=0.07)
    if s.get("apron"):
        box((0.34, 0.03, 0.34), (0, 0.145, 0.5), mat(s["apron"], 0.7), "apron", bevel=0.02)
        box((0.2, 0.035, 0.08), (0, 0.15, 0.48), mat(s["apron"], 0.6), "pocket")
    if s.get("necklace"):
        torus(0.13, 0.015, (0, 0.03, 0.74), mat(s["necklace"], 0.25, 0.9), "necklace", rot=(0.35, 0, 0))
    if s.get("tie"):
        box((0.06, 0.02, 0.22), (0, 0.145, 0.6), mat(s["tie"], 0.5), "tie", bevel=0.01)
    if s.get("lanyard"):
        box((0.1, 0.02, 0.13), (0.06, 0.15, 0.48), mat("#FFFFFF", 0.5), "card")
        box((0.015, 0.02, 0.2), (0.06, 0.148, 0.62), mat(s["lanyard"], 0.5), "strap")
    if s.get("dots"):
        r = random.Random(1)
        for k in range(10):
            sph(0.025, (r.uniform(-0.17, 0.17), 0.142, r.uniform(0.42, 0.72)), mat(s["dots"], 0.6), "dot",
                scale=(1, 0.3, 1), seg=6, rings=4)
    if s.get("camera"):
        box((0.14, 0.06, 0.09), (0, 0.17, 0.5), mat(s["camera"], 0.4), "cam", bevel=0.01)
        cyl(0.03, 0.04, (0, 0.21, 0.5), mat("#555555", 0.3), "lens", verts=10, rot=(math.pi / 2, 0, 0))
    if s.get("backpack"):
        box((0.38, 0.3, 0.36), (0, -0.3, 0.6), mat(s["backpack"], 0.5), "box", bevel=0.03)
        box((0.3, 0.02, 0.08), (0, -0.455, 0.66), mat("#FFFFFF", 0.5), "stripe")
    finish_part(m, "Torso", piv)

    # ---- แขน ----
    for side, nm in ((-1, "ArmL"), (1, "ArmR")):
        piv = part(nm, (side * 0.255, 0, 0.7), rig)
        m = mark()
        box((0.12, 0.12, 0.16), (side * 0.265, 0, 0.64), shirt, "sleeve", bevel=0.03)
        box((0.09, 0.09, 0.16), (side * 0.265, 0, 0.5), skin, "arm", bevel=0.02)
        sph(0.058, (side * 0.265, 0.01, 0.41), skin, "hand", seg=8, rings=6)
        finish_part(m, nm, piv)

    # ---- หัว ----
    piv = part("Head", (0, 0, 0.76), rig)
    m = mark()
    sph(0.26, (0, 0, 1.0), skin, "head", scale=(1, 0.95, 0.92), seg=16, rings=10)
    for side in (-1, 1):
        sph(0.05, (side * 0.255, 0, 0.98), skin, "ear", scale=(0.6, 1, 1), seg=8, rings=5)
        sph(0.034, (side * 0.09, 0.225, 0.985), mat("#1A1412", 0.3), "eye", scale=(1, 0.6, 1.3), seg=8, rings=6)
        sph(0.011, (side * 0.09 + 0.012, 0.245, 1.0), mat("#FFFFFF", 0.2), "spark", seg=6, rings=4)
        sph(0.042, (side * 0.16, 0.19, 0.925), mat("#F08C8C", 0.7), "cheek", scale=(1, 0.4, 0.7), seg=8, rings=5)
        box((0.07, 0.02, 0.018), (side * 0.09, 0.225, 1.06), hair, "brow", rot=(0, side * -0.15, 0))
    box((0.06, 0.02, 0.015), (0, 0.235, 0.89), mat("#7A3B2E", 0.6), "mouth", bevel=0.005)

    st = s["hair_style"]
    if st in ("spiky", "bun", "neat"):
        sph(0.272, (0, -0.025, 1.06), hair, "cap", scale=(1.02, 1.0, 0.8), seg=14, rings=9)
        box((0.4, 0.1, 0.1), (0, 0.17, 1.15), hair, "fringe", rot=(0.4, 0, 0), bevel=0.04)
    if st == "spiky":
        for k, (x, y, a, b) in enumerate([(-0.12, 0.05, -0.5, 0.3), (0.0, 0.08, 0, 0.4), (0.12, 0.05, 0.5, 0.3),
                                          (-0.08, -0.12, -0.4, -0.5), (0.08, -0.12, 0.4, -0.5), (0, -0.05, 0, 0)]):
            cyl(0.07, 0.16, (x, y, 1.27), hair, "spike", r2=0.0, verts=6, rot=(-b, a, 0))
    if st == "bun":
        sph(0.11, (0, -0.17, 1.2), hair, "bun", seg=10, rings=7)
        if s.get("flower"):
            for k in range(5):
                a = k * math.tau / 5
                sph(0.03, (0.12 + math.cos(a) * 0.03, -0.1, 1.24 + math.sin(a) * 0.03), mat(s["flower"], 0.5),
                    "petal", seg=6, rings=4)
            sph(0.02, (0.12, -0.08, 1.24), mat("#E8462A", 0.5), "fc", seg=6, rings=4)
    if st == "neat":
        box((0.2, 0.08, 0.05), (0.08, 0.12, 1.24), hair, "part", rot=(0.3, 0, 0.2), bevel=0.02)
    if st == "helmet":
        sph(0.29, (0, -0.07, 1.1), mat(s["helmet"], 0.35), "helmet", scale=(1.03, 0.95, 0.75), seg=14, rings=9)
        box((0.36, 0.04, 0.08), (0, 0.2, 1.2), mat("#222831", 0.15, 0.3), "visor", rot=(0.35, 0, 0), bevel=0.02)
    if st == "hat":
        sph(0.272, (0, -0.025, 1.06), hair, "cap", scale=(1.02, 1.0, 0.75), seg=14, rings=9)
        cyl(0.44, 0.025, (0, 0, 1.2), mat(s["hat"], 0.8), "brim", verts=20)
        cyl(0.22, 0.17, (0, 0, 1.29), mat(s["hat"], 0.8), "crown", r2=0.19, verts=16)
        cyl(0.225, 0.04, (0, 0, 1.23), mat("#C8372D", 0.6), "band", verts=16)
    if s.get("headband"):
        torus(0.262, 0.022, (0, 0, 1.13), mat(s["headband"], 0.6), "band", rot=(0.12, 0, 0))
    if s.get("glasses"):
        g = mat(s["glasses"], 0.3, 0.7)
        for side in (-1, 1):
            torus(0.055, 0.008, (side * 0.09, 0.245, 0.985), g, "lens", rot=(math.pi / 2, 0, 0), seg=14)
        box((0.07, 0.01, 0.01), (0, 0.25, 0.99), g, "bridge")
    finish_part(m, "Head", piv)

    export(f"{OUT}/characters/{cname}.glb")


def build_all(out):
    global OUT
    OUT = out
    for k, v in SPECS.items():
        build(k, v)
