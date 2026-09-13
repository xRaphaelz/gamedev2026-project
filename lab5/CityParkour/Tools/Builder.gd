extends RefCounted

## Helper used by the build scripts to assemble scenes procedurally.

var root: Node

const ASSET := {
	"Building_Big": "res://Assets/City/Building_Big/Building3_Big.fbx",
	"Building_Brown": "res://Assets/City/Building_Brown/BrownBuilding.fbx",
	"Building_Green": "res://Assets/City/Building_Green/BuildingGreen.fbx",
	"Building_Red": "res://Assets/City/Building_Red/buildingRed1.fbx",
	"Building_RedCorner": "res://Assets/City/Building_RedCorner/buildingRedCorner.fbx",
	"Building_Pizza": "res://Assets/City/Building_Pizza/PizzaCorner.fbx",
	"RoofExit": "res://Assets/City/RoofExit/RoofExit.fbx",
	"FireExit": "res://Assets/City/FireExit/FireExit.fbx",
	"PowerBox": "res://Assets/City/PowerBox/PowerBox.fbx",
	"WashingLine": "res://Assets/City/WashingLine/washingLine.fbx",
	"Box": "res://Assets/City/Box/box_A.fbx",
	"AirConditioner": "res://Assets/City/AirConditioner/1286_Air Conditioner.obj",
	"Bench": "res://Assets/City/Bench/model.obj",
	"BusStop": "res://Assets/City/BusStop/BusStop.obj",
	"Car1": "res://Assets/City/Car/NormalCar1.obj",
	"Car2": "res://Assets/City/Car/NormalCar2.obj",
	"Cone": "res://Assets/City/Cone/Cone.obj",
	"Fence": "res://Assets/City/Fence/fence.obj",
	"FireHydrant": "res://Assets/City/FireHydrant/Fire Hydrant.obj",
	"TrafficLight": "res://Assets/City/TrafficLight/TrafficLight_2.fbx",
	"StopSign": "res://Assets/City/StopSign/1358 Stop Sign.obj",
	"TrashCan": "res://Assets/City/TrashCan/TrashCan_02.obj",
	"Dumpster": "res://Assets/City/Dumpster/TrashContainer.fbx",
	"Tree": "res://Assets/City/Tree/tree01.obj",
	"Mailbox": "res://Assets/City/Mailbox/Mailbox.fbx",
	"Billboard": "res://Assets/City/Billboard/Billboard 1.obj",
	"Van": "res://Assets/City/Van/1387 Van.obj",
	"Planter": "res://Assets/City/Planter/PlanterAndBushes.fbx",
	"FlowerPot": "res://Assets/City/FlowerPot/FlowerPot4.fbx",
	"FlowerPot2": "res://Assets/City/FlowerPot/FlowerPot7.fbx",
	"Manhole": "res://Assets/City/Manhole/ManholeCover.fbx",
	"RoadBits": "res://Assets/City/RoadBits/Road Bits.fbx",
	"PoliceCar": "res://Assets/City/PoliceCar/Cop.obj",
	"SportsCar": "res://Assets/City/SportsCar/SportsCar2.obj",
}

var _aabb_cache := {}


func _init(p_root: Node) -> void:
	root = p_root


# ---------------------------------------------------------------- utilities

func attach(parent: Node, node: Node, node_name := "") -> Node:
	if node_name != "":
		node.name = node_name
	parent.add_child(node)
	return node


## Recursively assigns ownership so PackedScene.pack() keeps every node.
func claim(node: Node) -> void:
	for child in node.get_children():
		child.owner = root
		if child.scene_file_path == "":
			claim(child)


func save(node: Node, path: String) -> void:
	claim(node)
	var packed := PackedScene.new()
	var err := packed.pack(node)
	if err != OK:
		push_error("pack failed for %s (%d)" % [path, err])
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("save failed for %s (%d)" % [path, err])
	else:
		print("saved ", path)


func mesh_aabb(node: Node) -> AABB:
	var out := AABB()
	var first := true
	var list: Array = []
	if node is MeshInstance3D:
		list.append(node)
	list.append_array(node.find_children("*", "MeshInstance3D", true, false))
	for c in list:
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = mi.mesh.get_aabb()
		var t := Transform3D.IDENTITY
		var walker: Node = mi
		while walker != null and walker != node:
			if walker is Node3D:
				t = (walker as Node3D).transform * t
			walker = walker.get_parent()
		if node is Node3D and node != mi:
			pass
		b = t * b
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


func source_aabb(key: String) -> AABB:
	if _aabb_cache.has(key):
		return _aabb_cache[key]
	var res = load(ASSET[key])
	var a := AABB()
	if res is PackedScene:
		var inst = res.instantiate()
		a = mesh_aabb(inst)
		inst.free()
	elif res is Mesh:
		a = res.get_aabb()
	_aabb_cache[key] = a
	return a


func make_model(key: String) -> Node3D:
	var res = load(ASSET[key])
	if res is PackedScene:
		return res.instantiate()
	var mi := MeshInstance3D.new()
	mi.mesh = res
	return mi


## Places a prop. `pos` is where the FOOT of the prop goes.
## `height` scales uniformly; `size` scales each axis independently.
func place(parent: Node, key: String, pos: Vector3, opts := {}) -> Node3D:
	var src := source_aabb(key)
	var holder := Node3D.new()
	holder.name = opts.get("name", key)
	parent.add_child(holder)
	holder.position = pos
	holder.rotation.y = deg_to_rad(float(opts.get("rot", 0.0)))

	var model := make_model(key)
	var scale_vec := Vector3.ONE
	if opts.has("size"):
		var want: Vector3 = opts["size"]
		scale_vec = Vector3(
			want.x / max(src.size.x, 0.0001),
			want.y / max(src.size.y, 0.0001),
			want.z / max(src.size.z, 0.0001))
	elif opts.has("height"):
		var s: float = float(opts["height"]) / max(src.size.y, 0.0001)
		scale_vec = Vector3(s, s, s)
	elif opts.has("scale"):
		scale_vec = Vector3.ONE * float(opts["scale"])

	holder.add_child(model)
	model.name = "Model"
	model.scale = scale_vec
	# put the model's lowest point on the holder origin, centred on x/z
	model.position = Vector3(
		-src.position.x * scale_vec.x - src.size.x * scale_vec.x * 0.5 * float(opts.get("center_x", 1.0)),
		-src.position.y * scale_vec.y,
		-src.position.z * scale_vec.z - src.size.z * scale_vec.z * 0.5 * float(opts.get("center_z", 1.0)))

	if opts.get("collide", false):
		var body := StaticBody3D.new()
		holder.add_child(body)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var world_size := Vector3(src.size.x * scale_vec.x, src.size.y * scale_vec.y, src.size.z * scale_vec.z)
		if opts.has("collide_size"):
			world_size = opts["collide_size"]
		box.size = world_size
		cs.shape = box
		cs.position = Vector3(0, world_size.y * 0.5, 0)
		body.add_child(cs)
	return holder


# ---------------------------------------------------------------- materials

static func mat(color: Color, rough := 0.9, metal := 0.0, emission := Color(0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emission != Color(0, 0, 0):
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.6
	return m


## A solid box with collision. `pos` is the centre of the TOP face.
func slab(parent: Node, node_name: String, top_center: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	parent.add_child(body)
	body.position = top_center - Vector3(0, size.y * 0.5, 0)

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	body.add_child(mi)

	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body
