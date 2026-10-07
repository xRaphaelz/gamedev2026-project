"""ไอคอนเมนู (สำหรับการ์ดออเดอร์) และรูปหน้าตัวละคร (สำหรับบทสนทนา)"""
import os

from preview import render_glb


def build_all(models, icons):
    os.makedirs(icons, exist_ok=True)
    for name in ["dish_tam_thai", "dish_tam_poo", "dish_tam_corn"]:
        render_glb(f"{models}/dishes/{name}.glb", f"{icons}/{name}.png", size=160,
                   cam_dir=(0.0, -0.8, 1.0), fit=1.05, samples=32)
    for name in ["tom", "daeng"]:
        render_glb(f"{models}/characters/{name}.glb", f"{icons}/portrait_{name}.png", size=320,
                   cam_dir=(0.25, 1.0, 0.15), target=(0, 0, 1.03), radius_override=0.36, fit=1.0, samples=48)
