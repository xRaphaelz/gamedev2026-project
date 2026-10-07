"""เรนเดอร์ภาพตัวอย่าง / ไอคอน ด้วย Cycles (CPU)"""
import math

import bpy
from mathutils import Vector

from lib import reset


def render_glb(glb, png, size=256, cam_dir=(0.0, -1.0, 0.8), fit=1.25, target=None, transparent=True,
               samples=24, ortho=True, lens_scale=None, radius_override=None):
    reset()
    bpy.ops.import_scene.gltf(filepath=glb)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    center = (lo + hi) / 2 if target is None else Vector(target)
    radius = max((hi - lo).length / 2, 0.05)
    if radius_override:
        radius = radius_override

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = False
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.film_transparent = transparent
    scene.view_settings.view_transform = "Standard"

    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.9, 0.85, 0.8, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    scene.world = world

    d = Vector(cam_dir).normalized()
    cam_data = bpy.data.cameras.new("cam")
    if ortho:
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = radius * 2 * fit
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = center + d * radius * 6
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    if not ortho:
        cam_data.lens = lens_scale or 50
    scene.camera = cam

    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 3.5
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(45), math.radians(15), math.radians(30))
    scene.collection.objects.link(so)

    scene.render.filepath = png
    bpy.ops.render.render(write_still=True)
    print("RENDER", png)
