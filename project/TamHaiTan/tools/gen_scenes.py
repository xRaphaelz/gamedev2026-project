"""สร้างไฟล์ฉาก stage.tscn (ร้าน+ฉากหลัง ใช้ร่วมกันระหว่างเกมกับคัตซีน) และ kitchen.tscn (ด่านเล่น)
รัน: python3 tools/gen_scenes.py   (แก้ตำแหน่งของได้ใน editor โดยตรงเช่นกัน แต่ถ้ารันสคริปต์นี้ใหม่จะเขียนทับ)
"""
import math
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
S = "res://scripts/"
M = "res://assets/models/"


def xf(x, y, z, ry=0.0, s=1.0):
    t = math.radians(ry)
    c, sn = math.cos(t) * s, math.sin(t) * s
    f = lambda v: f"{v:.4g}"
    return f"Transform3D({f(c)}, 0, {f(sn)}, 0, {f(s)}, 0, {f(-sn)}, 0, {f(c)}, {f(x)}, {f(y)}, {f(z)})"


class Scene:
    def __init__(self, root_name, root_type, root_props=None, uid=None):
        self.ext, self.order, self.nodes, self.subs = {}, [], [], []
        self.uid = uid
        self.root = (root_name, root_type, root_props or {})

    def E(self, path, typ="PackedScene"):
        if path not in self.ext:
            self.ext[path] = f"{len(self.ext) + 1}_r"
            self.order.append((typ, path))
        return f'ExtResource("{self.ext[path]}")'

    def node(self, name, typ, parent=".", props=None, inst=None, node_paths=None):
        np_ = (' node_paths=PackedStringArray(' + ", ".join(f'"{n}"' for n in node_paths) + ')') if node_paths else ""
        head = f'[node name="{name}"' + (f' type="{typ}"' if typ else "") + f' parent="{parent}"' + np_ + (f" instance={inst}" if inst else "") + "]"
        self.nodes.append(head + "\n" + "".join(f"{k} = {v}\n" for k, v in (props or {}).items()))

    def save(self, path):
        out = [f'[gd_scene format=3' + (f' uid="{self.uid}"' if self.uid else "") + ']\n']
        for typ, p in self.order:
            out.append(f'[ext_resource type="{typ}" path="{p}" id="{self.ext[p]}"]')
        out.append("")
        out += self.subs
        name, typ, props = self.root
        out.append(f'[node name="{name}" type="{typ}"]\n' + "".join(f"{k} = {v}\n" for k, v in props.items()))
        out += self.nodes
        open(os.path.join(ROOT, path), "w").write("\n".join(out))
        print("wrote", path, len(self.nodes), "nodes")


# ======================= stage.tscn =======================
st = Scene("Stage", "Node3D", uid="uid://btamhaistage1")
st.root[2]["script"] = st.E(S + "stage.gd", "Script")
st.subs.append('''[sub_resource type="Environment" id="env"]
background_mode = 1
background_color = Color(0.75, 0.85, 0.95, 1)
ambient_light_source = 2
ambient_light_color = Color(0.9, 0.92, 1, 1)
ambient_light_energy = 0.45

[sub_resource type="BoxShape3D" id="floor_shape"]
size = Vector3(40, 0.2, 30)
''')
st.node("WorldEnvironment", "WorldEnvironment", props={"environment": 'SubResource("env")'})
st.node("Sun", "DirectionalLight3D", props={"transform": xf(0, 10, 0), "shadow_enabled": "true", "directional_shadow_max_distance": "40.0"})
st.node("Floor", "StaticBody3D")
st.node("Shape", "CollisionShape3D", "Floor", {"transform": xf(0, -0.1, 0), "shape": 'SubResource("floor_shape")'})
st.node("Env", "Node3D")
for nm in ["ground", "shophouses", "stall", "bulbs"]:
    st.node(nm.capitalize(), None, "Env", {}, st.E(M + f"env/{nm}.glb"))
deco = [
    ("Tree1", "env/tree.glb", (-9.5, 0, -4.9, 0)), ("Tree2", "env/tree.glb", (9.6, 0, -4.9, 40)),
    ("Tree3", "env/tree.glb", (-12.0, 0, 4.0, 80)), ("Tree4", "env/tree.glb", (12.2, 0, 3.0, 10)),
    ("UmbrellaL", "props/umbrella.glb", (-8.0, 0, 1.4, 0)), ("TableL", "props/plastic_table.glb", (-8.0, 0, 1.4, 15)),
    ("StoolL1", "props/plastic_stool_blue.glb", (-8.65, 0, 1.3, 0)), ("StoolL2", "props/plastic_stool.glb", (-7.35, 0, 1.6, 0)),
    ("UmbrellaR", "props/umbrella.glb", (8.2, 0, 1.8, 30)), ("TableR", "props/plastic_table.glb", (8.2, 0, 1.8, -10)),
    ("StoolR1", "props/plastic_stool.glb", (7.55, 0, 1.9, 0)), ("StoolR2", "props/plastic_stool_blue.glb", (8.85, 0, 1.6, 0)),
    ("Motorbike1", "props/motorbike.glb", (-7.0, 0, 4.9, 20)), ("Motorbike2", "props/motorbike.glb", (9.3, 0, 5.2, -160)),
    ("Cooler", "props/cooler.glb", (6.0, 0, -2.7, 10)), ("Crates", "props/crate_stack.glb", (6.1, 0, -1.3, -15)),
    ("Plant1", "props/plant_pot.glb", (5.7, 0, 3.4, 0)), ("Plant2", "props/plant_pot.glb", (-5.7, 0, 3.4, 60)),
    ("Plant3", "props/plant_pot.glb", (-6.2, 0, -5.4, 0)), ("Plant4", "props/plant_pot.glb", (3.0, 0, -5.4, 20)),
    ("Crates2", "props/crate_stack.glb", (-6.0, 0, -2.2, 80)),
]
for nm, path, (x, y, z, r) in deco:
    st.node(nm, None, "Env", {"transform": xf(x, y, z, r)}, st.E(M + path))
FONT = st.E("res://assets/fonts/Kanit-Medium.ttf", "FontFile")
st.node("ShopName", "Label3D", "Env", {"transform": xf(0, 3.93, -3.27), "pixel_size": "0.0095", "text": '"ส้มตำป้าแดง"', "font": FONT, "font_size": "70", "modulate": "Color(0.78, 0.13, 0.1, 1)", "outline_size": "0"})
st.node("ShopTag", "Label3D", "Env", {"transform": xf(0, 3.45, -3.27), "pixel_size": "0.0095", "text": '"ส้มตำ • ไก่ย่าง • ข้าวเหนียว"', "font": FONT, "font_size": "26", "modulate": "Color(0.3, 0.15, 0.08, 1)", "outline_size": "0"})
for i, (x, t) in enumerate(zip(range(-12, 13, 4), ["ซ่อมรถ", "ร้านโชห่วย", "กาแฟโบราณ", "ร้านยา", "ข้าวมันไก่", "ซ่อมมือถือ", "ร้านทอง"])):
    st.node(f"ShopSign{i}", "Label3D", "Env", {"transform": xf(x, 3.2, -5.96), "pixel_size": "0.01", "text": f'"{t}"', "font": FONT, "font_size": "52", "outline_size": "8", "outline_modulate": "Color(0, 0, 0, 0.6)"})
st.node("Lights", "Node3D")
for i, (x, z) in enumerate([(-2.5, -1.2), (2.5, -1.2), (0, 3.6)]):
    st.node(f"Lamp{i}", "OmniLight3D", "Lights", {"transform": xf(x, 2.7, z), "light_color": "Color(1, 0.78, 0.5, 1)", "light_energy": "0.8", "omni_range": "5.5"})

st.node("Stations", "Node3D")


def station(name, kind, x, z, extra=None):
    props = {"transform": xf(x, 0, z), "script": st.E(S + f"stations/{kind}.gd", "Script")}
    props.update(extra or {})
    st.node(name, "StaticBody3D", "Stations", props)


for i, ing in enumerate(["papaya", "chili", "tomato", "peanut", "crab", "corn"]):
    station(f"Crate_{ing}", "crate_station", round(-3.0 + 1.2 * i, 2), -3.0,
            {"model": st.E(M + "props/counter_tray.glb"), "ingredient_id": f'"{ing}"', "item_height": "0.94"})
station("Chop1", "chop_station", -4.2, -1.6, {"model": st.E(M + "props/counter_board.glb"), "item_height": "0.98"})
station("Chop2", "chop_station", -4.2, -0.4, {"model": st.E(M + "props/counter_board.glb"), "item_height": "0.98"})
station("CounterL", "station", -4.2, 0.8, {"model": st.E(M + "props/counter.glb")})
station("Mortar1", "mortar_station", 4.2, -1.6, {"model": st.E(M + "props/counter.glb")})
station("Mortar2", "mortar_station", 4.2, -0.4, {"model": st.E(M + "props/counter.glb")})
station("CounterR", "station", 4.2, 0.8, {"model": st.E(M + "props/counter.glb")})
station("Trash", "trash_station", -3.0, 2.2, {"model": st.E(M + "props/trash.glb"), "size": "Vector3(0.7, 0.85, 0.7)"})
station("CounterF1", "station", -1.8, 2.2, {"model": st.E(M + "props/counter.glb")})
station("CounterF2", "station", -0.6, 2.2, {"model": st.E(M + "props/counter.glb")})
station("Serve", "serve_station", 0.6, 2.2, {"model": st.E(M + "props/counter_serve.glb"), "title": '"เสิร์ฟ"'})
station("CounterF3", "station", 1.8, 2.2, {"model": st.E(M + "props/counter.glb")})
station("Plates", "plate_station", 3.0, 2.2, {"model": st.E(M + "props/counter_plates.glb")})

st.node("Seats", "Node3D")
st.node("Tables", "Node3D")
k = 0
for ti, tx in enumerate([-3.4, 0.0, 3.4]):
    st.node(f"Table{ti}", None, "Tables", {"transform": xf(tx, 0, 4.5)}, st.E(M + "props/plastic_table.glb"))
    for side, ry in ((-1, -90), (1, 90)):
        sx = tx + side * 0.62
        st.node(f"Seat{k}", "Marker3D", "Seats", {"transform": xf(sx, 0, 4.5, ry)})
        stool = "props/plastic_stool.glb" if k % 2 == 0 else "props/plastic_stool_blue.glb"
        st.node(f"Stool{k}", None, "Tables", {"transform": xf(sx, 0, 4.5)}, st.E(M + stool))
        k += 1
st.save("scenes/stage.tscn")

# ======================= kitchen.tscn =======================
kt = Scene("Kitchen", "Node3D", uid="uid://btamhaitank01")
kt.root[2]["script"] = kt.E(S + "kitchen.gd", "Script")
kt.node("Stage", None, ".", {}, kt.E("res://scenes/stage.tscn"))
kt.node("Camera3D", "Camera3D", props={"transform": "Transform3D(1, 0, 0, 0, 0.6428, 0.766, 0, -0.766, 0.6428, 0, 12.0, 10.0)", "current": "true", "fov": "43.0"})
kt.node("Player", "CharacterBody3D", props={"process_mode": "1", "transform": xf(0, 0.05, -0.6), "script": kt.E(S + "player.gd", "Script")})
kt.node("OrderManager", "Node", props={"process_mode": "1", "script": kt.E(S + "order_manager.gd", "Script")})
kt.node("Customers", "Node3D", props={"process_mode": "1", "script": kt.E(S + "customer_manager.gd", "Script"),
                                      "order_manager": 'NodePath("../OrderManager")', "seats_root": 'NodePath("../Stage/Seats")'},
        node_paths=["order_manager", "seats_root"])
kt.node("Hud", "CanvasLayer", props={"script": kt.E(S + "ui/hud.gd", "Script")})
kt.node("DialogueBox", "CanvasLayer", props={"script": kt.E(S + "ui/dialogue_box.gd", "Script")})
kt.save("scenes/kitchen.tscn")
