class_name DhakaGeometry
extends RefCounted

static var materials: Dictionary = {}

static func material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var key: String = str(color) + str(roughness) + str(metallic)
	if materials.has(key):
		return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	materials[key] = mat
	return mat

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collide: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	if collide:
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var bounds = BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

static func text(parent: Node3D, pos: Vector3, message: String, size: int = 64, tint: Color = Color.WHITE) -> Label3D:
	var label = Label3D.new()
	label.position = pos
	label.text = message
	label.font = load("res://assets/fonts/NotoSansBengali.ttf")
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = tint
	label.outline_size = 3
	label.outline_modulate = Color(0.02, 0.025, 0.025, 0.7)
	parent.add_child(label)
	return label

static func vehicle(parent: Node3D, kind: String, color: Color, high_detail: bool = false) -> Node3D:
	var visual = preload("res://scripts/vehicle_visual.gd").new()
	visual.name = "Sedan" if kind == "car" else "Bus" if kind == "bus" else "CNG"
	visual.kind = kind
	visual.body_color = color
	visual.high_detail = high_detail
	parent.add_child(visual)
	if kind == "bus":
		var destination = text(visual,Vector3(0,2.54,-4.30),"ঢাকা লোকাল",32,Color("183a32"))
		destination.rotation.y = PI
		destination.pixel_size = 0.004
	return visual

static func cable(parent: Node3D, a: Vector3, b: Vector3, sag: float = 1.5) -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material(Color("191e24")))
	for i in range(17):
		var t: float = float(i) / 16
		mesh.surface_add_vertex(a.lerp(b, t) - Vector3.UP * sin(t*PI) * sag)
	mesh.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	parent.add_child(instance)
