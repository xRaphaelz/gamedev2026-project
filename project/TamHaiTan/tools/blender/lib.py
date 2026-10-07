"""ตัวช่วยปั้นโมเดล low-poly ด้วย Blender Python (bpy)
พิกัด Blender: Z ขึ้น, ด้านหน้าของตัวละคร = +Y (จะกลายเป็น -Z ใน Godot)
"""
import math
import os
import random

import bpy

MATS = {}
_parts = []  # วัตถุของ asset ปัจจุบัน


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear()
    _parts.clear()


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hexc(h):
    h = h.lstrip("#")
    return tuple(_lin(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def mat(hex_color, rough=0.75, metal=0.0, emit=0.0, name=None):
    key = (hex_color, rough, metal, emit)
    if key in MATS:
        return MATS[key]
    m = bpy.data.materials.new(name or "m_" + hex_color.lstrip("#"))
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    col = hexc(hex_color)
    b.inputs["Base Color"].default_value = (*col, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*col, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    MATS[key] = m
    return m


def _finish(o, m, name, parent, smooth, bevel):
    o.name = name
    if m is not None:
        o.data.materials.clear()
        o.data.materials.append(m)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if smooth:
        bpy.ops.object.shade_smooth()
    if parent is not None:
        o.parent = parent
        o.matrix_parent_inverse = parent.matrix_world.inverted()
    _parts.append(o)
    return o


def box(size, loc, m, name="box", rot=(0, 0, 0), parent=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    return _finish(o, m, name, parent, False, bevel)


def cyl(r, depth, loc, m, name="cyl", r2=None, verts=12, rot=(0, 0, 0), parent=None, smooth=False):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r if r2 is None else r2,
                                    depth=depth, location=loc, rotation=rot)
    return _finish(bpy.context.active_object, m, name, parent, smooth, 0)


def sph(r, loc, m, name="sph", scale=(1, 1, 1), seg=10, rings=7, rot=(0, 0, 0), parent=None, smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=r, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = scale
    return _finish(o, m, name, parent, smooth, 0)


def torus(R, r, loc, m, name="torus", rot=(0, 0, 0), parent=None, seg=24):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=seg, minor_segments=6,
                                     location=loc, rotation=rot)
    return _finish(bpy.context.active_object, m, name, parent, True, 0)


def empty(name, loc=(0, 0, 0), parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    if parent is not None:
        o.parent = parent
    _parts.append(o)
    return o


def join(objs, name, parent=None):
    """รวม mesh หลายชิ้นเป็นชิ้นเดียว (ลด draw call)"""
    objs = [o for o in objs if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    alive = []
    for o in _parts:
        try:
            o.name
            alive.append(o)
        except ReferenceError:
            pass
    _parts[:] = alive
    if parent is not None:
        mw = j.matrix_world.copy()
        j.parent = parent
        j.matrix_world = mw
    return j


def collect_since(n):
    return list(_parts[n:])


def mark():
    return len(_parts)


def export(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_animations=False,
                              export_cameras=False, export_lights=False)
    print("EXPORT", path)


def join_all(name):
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    return join(meshes, name)


rng = random.Random(7)
