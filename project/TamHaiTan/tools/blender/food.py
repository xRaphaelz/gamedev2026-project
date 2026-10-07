"""วัตถุดิบ จาน และจานส้มตำ"""
import math

from lib import *

OUT = None  # ตั้งจาก build.py


def papaya():
    reset()
    g = mat("#6FA83A", 0.55)
    sph(0.12, (0, 0, 0.12), g, "body", scale=(1.75, 1, 1))
    sph(0.07, (0.12, 0, 0.13), mat("#8CC24A", 0.55), "tip", scale=(1, 1, 1))
    cyl(0.015, 0.05, (-0.22, 0, 0.13), mat("#6B4A2A"), "stem", rot=(0, math.pi / 2, 0), verts=6)
    join_all("papaya")
    export(f"{OUT}/ingredients/papaya.glb")


def shred_pile(m_main, n, radius, height, base_z=0.0, seed=1, m_alt=None):
    r = random.Random(seed)
    for i in range(n):
        a = r.uniform(0, math.tau)
        d = r.uniform(0, radius) * (1 - i / (n * 1.6))
        z = base_z + 0.012 + height * (1 - d / radius) * r.uniform(0.4, 1.0)
        mm = m_alt if (m_alt and r.random() < 0.3) else m_main
        box((0.17, 0.022, 0.018), (math.cos(a) * d, math.sin(a) * d, z), mm, "shred",
            rot=(r.uniform(-0.3, 0.3), r.uniform(-0.3, 0.3), r.uniform(0, math.pi)))


def papaya_shred():
    reset()
    shred_pile(mat("#D4EBA0", 0.6), 26, 0.15, 0.1, m_alt=mat("#B9DB7A", 0.6))
    join_all("papaya_shred")
    export(f"{OUT}/ingredients/papaya_shred.glb")


def chili():
    reset()
    red = mat("#D62718", 0.35)
    stem = mat("#3E7D27", 0.6)
    for i, (x, a) in enumerate([(-0.05, -0.35), (0.0, 0.0), (0.05, 0.35)]):
        o = cyl(0.028, 0.2, (x, 0, 0.03), red, "c", r2=0.004, verts=8, rot=(math.pi / 2, 0, a), smooth=True)
        dx, dy = math.sin(a) * 0.1, -math.cos(a) * 0.1
        cyl(0.012, 0.04, (x + dx * 1.05, dy * 1.05 + 0.0, 0.03), stem, "s", verts=6, rot=(math.pi / 2, 0, a))
    join_all("chili")
    export(f"{OUT}/ingredients/chili.glb")


def tomato():
    reset()
    red = mat("#E8462A", 0.35)
    green = mat("#3E7D27", 0.6)
    for x, y in [(-0.07, -0.03), (0.07, -0.03), (0, 0.07)]:
        sph(0.075, (x, y, 0.07), red, "t", scale=(1, 1, 0.85))
        for k in range(5):
            a = k * math.tau / 5
            box((0.05, 0.014, 0.008), (x + math.cos(a) * 0.022, y + math.sin(a) * 0.022, 0.135), green, "leaf",
                rot=(0, 0, a))
    join_all("tomato")
    export(f"{OUT}/ingredients/tomato.glb")


def peanut():
    reset()
    cyl(0.08, 0.07, (0, 0, 0.035), mat("#6FA9D8", 0.4), "bowl", r2=0.12, verts=14)
    r = random.Random(3)
    nut = mat("#C89B5E", 0.7)
    for i in range(22):
        a = r.uniform(0, math.tau)
        d = r.uniform(0, 0.09)
        sph(0.022, (math.cos(a) * d, math.sin(a) * d, 0.075 + (0.09 - d) * 0.35), nut, "n",
            scale=(1.4, 1, 0.9), seg=6, rings=4, rot=(0, 0, r.uniform(0, 3)))
    join_all("peanut")
    export(f"{OUT}/ingredients/peanut.glb")


def crab():
    reset()
    shell = mat("#6B3E22", 0.45)
    dark = mat("#3E2414", 0.6)
    sph(0.1, (0, 0, 0.06), shell, "body", scale=(1.3, 1, 0.45))
    for side in (-1, 1):
        for k in range(3):
            y = -0.05 + k * 0.05
            box((0.12, 0.018, 0.018), (side * 0.15, y, 0.04), dark, "leg", rot=(0, side * 0.5, side * 0.25 * (k - 1)))
        sph(0.04, (side * 0.11, 0.12, 0.06), shell, "claw", scale=(1, 1.4, 0.8))
    for side in (-1, 1):
        sph(0.012, (side * 0.035, 0.085, 0.1), mat("#111111", 0.3), "eye")
    join_all("crab")
    export(f"{OUT}/ingredients/crab.glb")


def corn():
    reset()
    y = mat("#F5C518", 0.5)
    husk = mat("#8DBF4E", 0.6)
    sph(0.075, (0, 0, 0.075), y, "cob", scale=(2.3, 1, 1), seg=12, rings=8)
    # เม็ดข้าวโพด
    r = random.Random(5)
    for i in range(40):
        a = r.uniform(0, math.pi)
        x = r.uniform(-0.14, 0.14)
        s = math.sqrt(max(0.0, 1 - (x / 0.17) ** 2))
        box((0.022, 0.022, 0.012), (x, math.cos(a) * 0.072 * s, 0.075 + math.sin(a) * 0.072 * s),
            mat("#FFD84A", 0.5), "k", rot=(a - math.pi / 2, 0, 0))
    sph(0.06, (-0.15, 0.02, 0.07), husk, "h1", scale=(2.2, 0.9, 0.5), rot=(0, 0, 0.3))
    sph(0.06, (-0.15, -0.03, 0.06), husk, "h2", scale=(2.0, 0.9, 0.5), rot=(0, 0, -0.3))
    join_all("corn")
    export(f"{OUT}/ingredients/corn.glb")


def plate_parts():
    cyl(0.17, 0.035, (0, 0, 0.0175), mat("#F7F5EE", 0.3), "plate", r2=0.25, verts=24)
    torus(0.245, 0.01, (0, 0, 0.034), mat("#2F5DA8", 0.3), "rim")


def plate():
    reset()
    plate_parts()
    join_all("plate")
    export(f"{OUT}/dishes/plate.glb")


def dish(name, main, alt, extras):
    reset()
    plate_parts()
    shred_pile(mat(main, 0.55), 30, 0.17, 0.09, base_z=0.03, seed=len(name), m_alt=mat(alt, 0.55))
    r = random.Random(len(name) * 3)
    for hexcol, n, size in extras:
        m = mat(hexcol, 0.45)
        for i in range(n):
            a = r.uniform(0, math.tau)
            d = r.uniform(0.03, 0.15)
            box(size, (math.cos(a) * d, math.sin(a) * d, 0.1 + (0.15 - d) * 0.25), m, "x",
                rot=(r.uniform(-.5, .5), r.uniform(-.5, .5), r.uniform(0, 3)))
    # มะนาวซีก
    sph(0.04, (0.19, 0.03, 0.06), mat("#7CC243", 0.4), "lime", scale=(1, 1, 0.6), seg=8, rings=4)
    join_all(name)
    export(f"{OUT}/dishes/{name}.glb")


def dishes():
    tomato = ("#E8462A", 6, (0.05, 0.04, 0.03))
    chili = ("#D62718", 5, (0.04, 0.012, 0.012))
    nut = ("#C89B5E", 10, (0.022, 0.016, 0.014))
    bean = ("#4E9A2E", 4, (0.12, 0.016, 0.016))
    dish("dish_tam_thai", "#D4EBA0", "#B9DB7A", [tomato, chili, nut, bean])
    dish("dish_tam_poo", "#B7C97A", "#9AAE5E", [tomato, chili, bean, ("#4A2A16", 7, (0.06, 0.03, 0.025))])
    dish("dish_tam_corn", "#F5C518", "#FFD84A", [tomato, chili, nut])
    dish("dish_fail", "#7A6248", "#5E4A36", [("#3B2C20", 8, (0.04, 0.04, 0.03))])


def build_all(out):
    global OUT
    OUT = out
    papaya(); papaya_shred(); chili(); tomato(); peanut(); crab(); corn(); plate(); dishes()
