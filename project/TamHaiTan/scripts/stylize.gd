class_name Stylize
## ปรับวัสดุของโมเดลทั้งหมดให้เป็นสไตล์การ์ตูน: แสงเงาแบบ toon + ขอบสว่าง (rim) + เส้นขอบ (outline)
## เรียก Stylize.apply(node) กับโมเดลที่โหลดเข้ามา (stage / ตัวละคร / ไอเท็ม เรียกให้อัตโนมัติแล้ว)

const OUTLINE_SHADER := preload("res://assets/materials/outline.gdshader")

## เปิด/ปิดแต่ละอย่างได้ที่นี่
static var toon := true
static var rim := true
static var outline_characters := true

static var _cache := {}
static var _outline: ShaderMaterial


static func apply(root: Node, with_outline := false) -> void:
	if root == null:
		return
	if root is MeshInstance3D:
		_style_mesh(root, with_outline)
	for c in root.get_children():
		apply(c, with_outline)


static func _style_mesh(mi: MeshInstance3D, with_outline: bool) -> void:
	if mi.mesh == null or mi.has_meta("stylized"):
		return
	mi.set_meta("stylized", true)
	for i in mi.mesh.get_surface_count():
		var src := mi.get_surface_override_material(i)
		if src == null:
			src = mi.mesh.surface_get_material(i)
		var m := src as StandardMaterial3D
		if m == null:
			continue
		var key := m.get_instance_id() * 2 + (1 if with_outline else 0)
		if not _cache.has(key):
			var d := m.duplicate() as StandardMaterial3D
			if toon:
				d.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				d.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			if rim:
				d.rim_enabled = true
				d.rim = 0.35
				d.rim_tint = 0.6
			if with_outline and outline_characters:
				d.next_pass = _outline_mat()
			_cache[key] = d
		mi.set_surface_override_material(i, _cache[key])


static func _outline_mat() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = OUTLINE_SHADER
	return _outline
