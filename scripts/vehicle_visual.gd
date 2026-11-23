extends Node3D

const PLAYER_MODEL = preload("res://assets/models/sedan_player.glb")
const TRAFFIC_MODEL = preload("res://assets/models/sedan_traffic.glb")
const BUS_MODEL = preload("res://assets/models/city_bus.glb")
const CNG_MODEL = preload("res://assets/models/cng.glb")
var kind: String = "car"
var wheel_radius: float = 0.30
var body_color: Color
var high_detail: bool = false
var wheels: Array[Node3D] = []
var front_pivots: Array[Node3D] = []
var brake_materials: Array[StandardMaterial3D] = []
var headlight_materials: Array[StandardMaterial3D] = []
var column: Node3D
var column_rest: Basis
var vehicle: Node3D
var previous_position: Vector3
var previous_speed: float = 0
var previous_yaw: float = 0
var boarding_doors: Array[Node3D] = []
var door_opening: float = 0

func _ready() -> void:
	vehicle = get_parent()
	var scene: PackedScene = BUS_MODEL if kind == "bus" else CNG_MODEL if kind == "cng" else PLAYER_MODEL if high_detail else TRAFFIC_MODEL
	var model: Node3D = scene.instantiate()
	model.rotation.y = PI
	model.scale = Vector3.ONE*0.895
	if kind == "bus":
		model.scale = Vector3(0.97,0.94,0.75)
		wheel_radius = 0.42*0.94
	elif kind == "cng":
		model.scale = Vector3(0.98,0.99,1.0)
		wheel_radius = 0.27*0.99
	model.position.y = 0.09
	add_child(model)
	for suffix in ["FL","FR","RL","RR","F"]:
		var wheel = model.find_child("wheel_"+suffix,true,false)
		if wheel:
			wheels.append(wheel)
			if suffix == "F":
				var pivot = Node3D.new()
				pivot.name = "steer_F"
				wheel.get_parent().add_child(pivot)
				pivot.transform = wheel.transform
				wheel.reparent(pivot)
				wheel.transform = Transform3D.IDENTITY
				front_pivots.append(pivot)
	for suffix in ["FL","FR"]:
		var pivot = model.find_child("steer_"+suffix,true,false)
		if pivot:
			front_pivots.append(pivot)
	var handlebar = model.find_child("handlebar",true,false)
	if handlebar:
		front_pivots.append(handlebar)
	if kind == "bus":
		for part in ["door_front_a", "door_front_b"]:
			boarding_doors.append(model.find_child(part,true,false))
	elif kind == "cng":
		var lens = StandardMaterial3D.new()
		lens.albedo_color = Color("b5251c")
		lens.emission_enabled = true
		brake_materials.append(lens)
		for side in [-1,1]:
			var lamp = MeshInstance3D.new()
			lamp.mesh = BoxMesh.new()
			lamp.mesh.size = Vector3(0.13,0.12,0.035)
			lamp.position = Vector3(side*0.45,0.55,-1.32)
			lamp.material_override = lens
			model.add_child(lamp)
	column = model.find_child("steering_column",true,false)
	if column:
		column.position.x = -absf(column.position.x)
		column_rest = column.basis
	var localized: Dictionary = {}
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var paint: bool = material.resource_name.begins_with("paint") or (kind == "cng" and material.resource_name in ["tuk-tuk_body_pbr","tuk-tuk_paint_x"])
			var rear: bool = material.resource_name.begins_with("light_rear")
			var front: bool = material.resource_name.begins_with("light_front")
			var glazing: bool = material.resource_name == "glass" or material.resource_name.begins_with("lens") or material.resource_name.ends_with("window_glass_x")
			if not paint and not rear and not front and not glazing:
				continue
			if not localized.has(material):
				var copy: StandardMaterial3D = material.duplicate()
				localized[material] = copy
				if paint:
					copy.albedo_color = Color("eee5d3") if kind == "bus" else Color(0.14,0.37,0.23) if kind == "cng" and material.resource_name == "tuk-tuk_body_pbr" else body_color
				elif glazing:
					# The source uses transmission; Godot's importer leaves it opaque.
					copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					copy.albedo_color.a = 0.16
					copy.cull_mode = BaseMaterial3D.CULL_BACK
					if kind == "bus":
						copy.albedo_color = Color(0.12,0.19,0.21,0.45)
				else:
					copy.emission_enabled = true
					if rear:
						brake_materials.append(copy)
					else:
						headlight_materials.append(copy)
			mesh.set_surface_override_material(surface,localized[material])
	previous_position = vehicle.global_position
	previous_yaw = vehicle.rotation.y
	if vehicle.get("manager") == null:
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	var displacement: Vector3 = vehicle.global_position-previous_position
	previous_position = vehicle.global_position
	var speed: float = vehicle.get("speed")
	var turn: float = angle_difference(previous_yaw,vehicle.rotation.y)
	previous_yaw = vehicle.rotation.y
	if vehicle.get("manager").paused_sim:
		previous_speed = speed
		return
	# Recovery changes position discontinuously; only normal travel should turn the wheels.
	if displacement.length() < 5:
		var roll: float = displacement.dot(-vehicle.global_transform.basis.z)/wheel_radius
		for wheel in wheels:
			wheel.rotate(Vector3.RIGHT,roll)
	var steering = vehicle.get("steering")
	var wheel_angle: float
	if steering != null:
		wheel_angle = float(steering)*lerpf(0.5,0.15,clampf(absf(speed)/22.2,0,1))
	else:
		wheel_angle = clampf(-atan(turn*2.65/maxf(absf(speed)*delta,0.1)),-0.5,0.5)
	for pivot in front_pivots:
		pivot.rotation.y = -wheel_angle
	if column:
		column.basis = column_rest*Basis(Vector3.UP,-wheel_angle*3)
	if not boarding_doors.is_empty():
		door_opening = move_toward(door_opening,1.0 if vehicle.dwell > 0 else 0.0,delta*2)
		for i in range(boarding_doors.size()):
			boarding_doors[i].rotation.y = door_opening*(1.2 if i == 0 else -1.2)
	var brake = vehicle.get("brake_input")
	var braking: bool = float(brake) > 0 if brake != null else (previous_speed-speed)/delta > 1
	for material in brake_materials:
		material.emission = Color("ff321e")*(2.5 if braking else 0.15)
	var lamps = vehicle.get("lamps")
	var lights_on: bool = lamps != null and not lamps.is_empty() and lamps[0].visible
	for material in headlight_materials:
		material.emission = Color("fff0d5")*(2.5 if lights_on else 0.1)
	previous_speed = speed
