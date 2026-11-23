extends Node3D

const G = preload("res://scripts/geometry.gd")
const Network = preload("res://scripts/road_network.gd")
const PoliceOfficer = preload("res://scripts/traffic_police_officer.gd")
const BrokenDown = preload("res://scripts/broken_down_vehicle.gd")
var rng = RandomNumberGenerator.new()
var asphalt: StandardMaterial3D
var concrete: StandardMaterial3D
var windows: StandardMaterial3D
var manager: Node
var signal_bulbs: Array[Dictionary] = []
var route_cues: Node3D
var plaster: StandardMaterial3D
var starting_block: Node3D
var env: Environment
var sun: DirectionalLight3D
var dest_marker: Label3D
var dest_painted: Label3D
var weather: String = "clear"
var rain_volume: Node3D
var gutter_puddles: Node3D

# Ambient Urban Dhaka Soundscape & Street Life Foleys (v1.7)
var foley_tea_stall: AudioStreamPlayer3D
var foley_conductor: AudioStreamPlayer3D
var foley_rickshaw_bell: AudioStreamPlayer3D
var foley_hawker: AudioStreamPlayer3D

var conductor_timer: float = 8.0
var rickshaw_bell_timer: float = 4.5
var hawker_timer: float = 12.0

func build() -> void:
	rng.seed = 646301
	_prepare_materials()
	_environment()
	_roads()
	_buildings()
	_street_details()
	_landmarks()
	_traffic_events()
	_setup_street_foleys()
	_destination()
	_weather_effects()

func _prepare_materials() -> void:
	asphalt = StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://assets/textures/asphalt_02_diff.jpg")
	asphalt.albedo_color = Color(0.64, 0.65, 0.65)
	asphalt.normal_enabled = true
	asphalt.normal_texture = load("res://assets/textures/asphalt_02_nor_gl.jpg")
	asphalt.normal_scale = 0.18
	asphalt.roughness_texture = load("res://assets/textures/asphalt_02_rough.jpg")
	asphalt.roughness = 0.94
	asphalt.uv1_triplanar = true
	asphalt.uv1_world_triplanar = true
	asphalt.uv1_scale = Vector3.ONE * 0.5
	asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	concrete = G.material(Color("a59e8e"), 0.98).duplicate()
	var noise = FastNoiseLite.new()
	noise.seed = 301
	noise.frequency = 0.04
	var texture = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	texture.seamless = true
	var ramp = Gradient.new()
	ramp.set_color(0, Color(0.73, 0.73, 0.73))
	ramp.set_color(1, Color(0.96, 0.96, 0.96))
	texture.color_ramp = ramp
	concrete.albedo_texture = texture
	concrete.uv1_triplanar = true
	concrete.uv1_world_triplanar = true
	concrete.uv1_scale = Vector3.ONE * 0.18
	plaster = concrete.duplicate()
	plaster.albedo_color = Color.WHITE
	plaster.albedo_texture = preload("res://assets/textures/painted_plaster_wall_diff.jpg")
	plaster.normal_enabled = true
	plaster.normal_texture = preload("res://assets/textures/painted_plaster_wall_nor_gl.jpg")
	plaster.normal_scale = 0.45
	plaster.roughness_texture = preload("res://assets/textures/painted_plaster_wall_rough.jpg")
	plaster.uv1_scale = Vector3.ONE*0.5
	plaster.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	windows = G.material(Color("364a50"), 0.18, 0.65)

func _environment() -> void:
	var world = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var panorama = PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/textures/kloppenheim_06_puresky_hdri.hdr")
	sky.sky_material = panorama
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.sky_rotation = Vector3(0, 0.8, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("b6b8ad")
	env.fog_light_energy = 0.6
	env.fog_density = 0.0015
	env.fog_sky_affect = 0.35
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.5
	world.environment = env
	self.env = env
	add_child(world)
	var sun = DirectionalLight3D.new()
	self.sun = sun
	sun.rotation_degrees = Vector3(-32, -38, 0)
	sun.light_color = Color("ffe3b6")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.025
	add_child(sun)
	G.box(self, Vector3(0, -0.22, 0), Vector3(750, 0.4, 650), G.material(Color("625f50")), true)

func _roads() -> void:
	var paving = ShaderMaterial.new()
	paving.shader = load("res://assets/sidewalk.gdshader")
	var paint = G.material(Color("d5cfb5"), 0.95)
	var yellow = G.material(Color("c0a75a"), 0.95)
	var repair = asphalt.duplicate()
	repair.albedo_color = Color(0.51,0.52,0.51)
	for center in Network.NODES.values():
		G.box(self, center, Vector3(17,0.04,17), asphalt)
	for edge in Network.EDGES:
		var a: Vector3 = Network.NODES[edge[0]]
		var b: Vector3 = Network.NODES[edge[1]]
		var along: Vector3 = (b-a).normalized()
		var across: Vector3 = Network.left_of(along)
		var length: float = a.distance_to(b)
		var road = Node3D.new()
		road.position = (a+b)/2
		road.rotation.y = atan2(-along.x, -along.z)
		add_child(road)
		G.box(road, Vector3(0, 0, 0), Vector3(17, 0.04, length-17), asphalt)
		for side in [-1, 1]:
			G.box(road, Vector3(side*10.3, 0.15, 0), Vector3(3.2, 0.3, length-25), paving, true)
			G.box(road, Vector3(side*7.65,0.024,0), Vector3(1.4,0.006,length-30), repair)
			for z in range(int(-length/2+20),int(length/2-15),24):
				G.box(road, Vector3(side*8.15,0.035,z), Vector3(0.55,0.015,0.9), G.material(Color("343c3c"),0.75,0.4))
				for slot in range(5):
					G.box(road, Vector3(side*8.15,0.045,z-0.32+slot*0.16), Vector3(0.45,0.01,0.04), G.material(Color("131e20")))
				G.cylinder(road,Vector3(side*10.3,0.305,z+3),0.38,0.012,G.material(Color("535950"),0.85,0.25))
			# Painted curb blocks, with gaps at junctions.
			for z in range(int(-length/2+15), int(length/2-14), 3):
				G.box(road, Vector3(side*8.65, 0.17, z), Vector3(0.16, 0.34, 2.9),
					G.material(Color("c6b785") if (z/3) % 2 == 0 else Color("393b36")))
		for z in range(int(-length/2+16), int(length/2-14), 8):
			G.box(road, Vector3(0, 0.031, z), Vector3(0.12, 0.012, 3.2), yellow)
			for side in [-1, 1]:
				G.box(road, Vector3(side*6.7, 0.031, z), Vector3(0.10, 0.01, 7.95), paint)
		for z in [-length/2+25, length/2-25]:
			_road_arrow(road,Vector3(-3.2,0.047,z),0,paint,1.0)
			_road_arrow(road,Vector3(3.2,0.047,z),PI,paint,1.0)
		# Road repairs deliberately interrupt the texture repetition.
		for i in range(2):
			var patch: Vector3 = a.lerp(b, rng.randf_range(0.18, 0.82)) + across * rng.randf_range(-5, 5)
			G.box(self, patch + Vector3.UP*0.03, Vector3(rng.randf_range(0.8, 1.8), 0.01, rng.randf_range(1, 2.5)), repair)
	for name in ["W", "E"]:
		var pos: Vector3 = Network.NODES[name]
		G.box(self,pos+Vector3(-4.3,0.045,13.5),Vector3(7.4,0.015,0.35),paint)
		G.box(self,pos+Vector3(4.3,0.045,-13.5),Vector3(7.4,0.015,0.35),paint)
		G.box(self,pos+Vector3(13.5 if name == "W" else -13.5,0.045,3.2 if name == "W" else -3.2),Vector3(0.35,0.015,6),paint)
		for side in [-1, 1]:
			for i in range(8):
				G.box(self, pos + Vector3(-7+i*2, 0.04, side*10.5), Vector3(1.0, 0.02, 2.7), G.material(Color("d1c9ad")))
		_signal(pos + Vector3(8.4, 0, 12.8), "NS", 0)
		_signal(pos + Vector3(-8.4, 0, -12.8), "NS", PI)
		_signal(pos + Vector3(-12.8, 0, 8.4), "EW", PI/2)
		_signal(pos + Vector3(12.8, 0, -8.4), "EW", -PI/2)
	# The marked boarding zone matches the existing bus stop that temporarily blocks the lane.
	for x in [-94.7,-91.7]:
		G.box(self,Vector3(x,0.042,31),Vector3(0.12,0.015,13),yellow)
	for z in [24.5,37.5]:
		G.box(self,Vector3(-93.2,0.042,z),Vector3(3,0.015,0.12),yellow)
	var bus_text = G.text(self,Vector3(-93.2,0.06,31),"BUS",48,Color("d9bd6b"))
	bus_text.rotation.x = -PI/2
	bus_text.pixel_size = 0.018
	for x in [-100.5,100.5]:
		var sign = Node3D.new()
		sign.position = Vector3(x,0,64)
		sign.rotation.y = PI/2 if x < 0 else -PI/2
		add_child(sign)
		G.cylinder(sign,Vector3(0,1.65,0),0.04,3.3,G.material(Color("646d69"),0.5,0.5))
		G.box(sign,Vector3(0,2.9,0),Vector3(0.95,1.0,0.08),paint)
		G.text(sign,Vector3(0,2.9,0.06),"40",66,Color("283e42"))

func _road_arrow(parent: Node3D, pos: Vector3, yaw: float, mat: Material, size: float) -> void:
	var arrow = Node3D.new()
	arrow.position = pos
	arrow.rotation.y = yaw
	parent.add_child(arrow)
	G.box(arrow,Vector3(0,0,0.3)*size,Vector3(0.16,0.012,2.1)*size,mat)
	for side in [-1,1]:
		var wing = G.box(arrow,Vector3(side*0.34,0,-0.58)*size,Vector3(0.15,0.012,1.0)*size,mat)
		wing.rotation.y = side*PI/4

func show_route(route: String) -> void:
	if is_instance_valid(route_cues):
		route_cues.free()
	route_cues = Node3D.new()
	add_child(route_cues)
	var material = G.material(Color(0.28,0.8,0.73,0.65)).duplicate()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var points: PackedVector3Array = Network.route_points(route,manager.arrival_point)
	for i in range(points.size()-1):
		var direction: Vector3 = (points[i+1]-points[i]).normalized()
		var length: float = points[i].distance_to(points[i+1])
		for step in range(7,int(length-10),12):
			var pos: Vector3 = points[i]+direction*step
			pos.y = 0.072
			_road_arrow(route_cues,pos,atan2(-direction.x,-direction.z),material,0.65)

func _signal(pos: Vector3, axis: String, yaw: float) -> void:
	var root = Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	G.cylinder(root, Vector3(0, 2.2, 0), 0.065, 4.4, G.material(Color("414849"), 0.6, 0.5))
	G.box(root, Vector3(0, 4.15, 0), Vector3(0.4, 1.05, 0.3), G.material(Color("202725")))
	for i in range(3):
		var mat = G.material(Color("222824")).duplicate()
		mat.emission_enabled = true
		var bulb = G.cylinder(root, Vector3(0, 4.48-i*0.32, 0.17), 0.115, 0.04, mat)
		bulb.rotation.x = PI/2
		signal_bulbs.append({"material": mat, "axis": axis, "index": i})

func update_signals(axis: String, amber: bool) -> void:
	for bulb in signal_bulbs:
		var lit: int = 1 if amber and bulb.axis == axis else 2 if bulb.axis == axis else 0
		var color: Color = [Color("ec5544"), Color("e9ac42"), Color("63c48a")][bulb.index]
		bulb.material.albedo_color = color if bulb.index == lit else color * 0.14
		bulb.material.emission = color * 1.8 if bulb.index == lit else Color.BLACK

func _buildings() -> void:
	starting_block = Node3D.new()
	starting_block.name = "StartingBlock"
	add_child(starting_block)
	# Modular blocks use real world scale: 3.3 m floors and 1.2 m windows.
	for x in [-117.0, -63.0, 63.0, 117.0]:
		for z in range(-65, 80, 25):
			if absf(z) < 18:
				continue
			var yaw: float = PI/2 if x < -90 or (x > 0 and x < 90) else -PI/2
			_building(Vector3(x, 0, z), yaw, rng.randi_range(3, 8), rng.randf_range(17, 21), x < 0 and z >= 35 and z <= 60)
	for z in [-128.0, -74.0, 74.0, 128.0]:
		for x in range(-62, 68, 26):
			_building(Vector3(x, 0, z), 0 if z < -100 or (z > 0 and z < 100) else PI, rng.randi_range(3, 7), 23)
	for z in [-28.0, 28.0]:
		for x in range(-55, 65, 24):
			_building(Vector3(x, 0, z), 0 if z < 0 else PI, rng.randi_range(2, 5), 20)
	# A restrained background skyline prevents a hard district edge.
	for i in range(26):
		var angle: float = float(i)*TAU/26
		var pos: Vector3 = Vector3(cos(angle)*270, 0, sin(angle)*235)
		var height: float = rng.randf_range(35,65)
		G.box(self, pos + Vector3.UP*height*0.5, Vector3(24,height,28), G.material(Color("a4a39a")))

func _building(pos: Vector3, yaw: float, floors: int, width: float, detailed: bool = false) -> void:
	var root = Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	(starting_block if detailed else self).add_child(root)
	var height: float = floors*3.3
	var palette: Array[Color] = [Color("b8ae95"), Color("c4baa8"), Color("8f9f9c"), Color("b6a18e"), Color("a8a9a1"), Color("b3b6a1")]
	var facade = (plaster if detailed else concrete).duplicate()
	facade.albedo_color = palette[rng.randi_range(0, palette.size()-1)]
	G.box(root, Vector3(0, height/2, -2), Vector3(width, height, 16), facade, true)
	G.box(root, Vector3(0, height+0.25, -2), Vector3(width+0.5, 0.5, 16.5), G.material(Color("7d8077")))
	# Windows are batched into one draw call per building.
	var transforms: Array[Transform3D] = []
	var frames: Array[Transform3D] = []
	for floor_index in range(1, floors):
		for column in range(int(width/3.3)):
			var x: float = -width/2+2+column*3.3
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.3, 1.6, 0.05)), Vector3(x, floor_index*3.3+1.4, 6.03)))
			if detailed:
				frames.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.55, 1.85, 0.07)), Vector3(x, floor_index*3.3+1.4, 5.99)))
		G.box(root, Vector3(0, floor_index*3.3, 6.1), Vector3(width+0.15, 0.12, 0.3), G.material(Color("d2c7b2")))
		if floor_index % 2 == 0:
			G.box(root,Vector3(0,floor_index*3.3+0.35,6.55),Vector3(3.4,0.14,1.15),facade)
			for rail in range(3):
				G.box(root,Vector3(0,floor_index*3.3+0.65+rail*0.23,7.05),Vector3(3.4,0.045,0.045),G.material(Color("50574e"),0.75,0.5))
	for group in [[transforms, windows], [frames, G.material(Color("c9c3ac"),0.85)]]:
		if group[0].is_empty():
			continue
		var batch = MultiMeshInstance3D.new()
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = BoxMesh.new()
		multimesh.instance_count = group[0].size()
		for i in range(group[0].size()):
			multimesh.set_instance_transform(i, group[0][i])
		batch.multimesh = multimesh
		batch.material_override = group[1]
		root.add_child(batch)
	# Shutters, awnings and signs give the ground floor a separate human scale.
	var shops: Array[String] = ["মেঘনা ফার্মেসি", "ঢাকা স্টোর", "চা ও আড্ডা", "নতুন বইঘর", "ভাই ভাই হোটেল", "মোবাইল সার্ভিস", "মদিনা বেকারি", "সবুজ বাজার"]
	var sign_colors: Array[Color] = [Color("284d49"), Color("294e63"), Color("873e30"), Color("c3a36b")]
	var label: String = shops[rng.randi_range(0, shops.size()-1)]
	var sign_color: Color = sign_colors[rng.randi_range(0, sign_colors.size()-1)]
	if detailed:
		_shopfronts(root, width)
	else:
		G.box(root, Vector3(0, 2.9, 6.17), Vector3(width-0.6, 1.05, 0.18), G.material(sign_color))
		G.text(root, Vector3(0, 2.95, 6.29), label, 70)
		for x in [-width*0.32, 0, width*0.32]:
			G.box(root, Vector3(x, 1.2, 6.07), Vector3(width*0.27, 2.1, 0.06), G.material(Color("686f69"), 0.65, 0.3))
			for y in range(1, 9):
				G.box(root, Vector3(x, y*0.25, 6.12), Vector3(width*0.27, 0.025, 0.03), G.material(Color("474f4d")))
		var awning = G.box(root, Vector3(0, 2.32, 6.9), Vector3(width, 0.09, 1.65), G.material(sign_color.lightened(0.12)))
		awning.rotation.x = 0.12
	# Rooftop tank and exposed reinforcement, recognizable without bespoke landmarks.
	G.cylinder(root, Vector3(width*0.28, height+1, -1), 0.8, 1.5, G.material(Color("343d37")))
	G.box(root, Vector3(-width*0.3, height+0.8, -3), Vector3(3, 1.5, 3), facade)
	for i in range(2):
		var ac_x: float = -width/2+3+i*6
		G.box(root, Vector3(ac_x, 5.0, 6.5), Vector3(0.85, 0.55, 0.5), G.material(Color("bcb9a9")))
	for side in [-1,1]:
		G.cylinder(root,Vector3(side*(width/2-0.4),height/2,6.1),0.045,height,G.material(Color("7f8275")))
		G.box(root,Vector3(side*(width/2-0.55),0.45,6.6),Vector3(0.7,0.9,0.65),G.material(Color("525951")))

func _shopfronts(building: Node3D, width: float) -> void:
	var paving = ShaderMaterial.new()
	paving.shader = preload("res://assets/sidewalk.gdshader")
	G.box(building,Vector3(0,0.15,10.55),Vector3(width,0.3,9.1),paving,true)
	var titles: Array[String] = ["মেঘনা ফার্মেসি", "ভাই ভাই স্টোর", "তাজা ফল ও সবজি"]
	var slot: float = (width-0.6)/3
	for i in range(3):
		var shop: Node3D = preload("res://assets/models/shopfront.glb").instantiate()
		shop.name = "Shopfront"
		shop.position = Vector3(-width/2+0.3+i*slot,0.30,7.0)
		shop.scale.x = slot/6
		building.add_child(shop)
		for mesh in shop.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var mat: Material = mesh.get_active_material(surface)
				if mat.resource_name in ["shop_sign","shop_vsign","neon_cyan"]:
					mesh.set_surface_override_material(surface,G.material(Color("284d49"),0.75))
		G.box(shop,Vector3(3,2.65,0.35),Vector3(5.3,0.58,0.08),G.material(Color("284d49")))
		G.text(shop,Vector3(3,2.65,0.40),titles[i],36,Color("eee3ba"))
		var props = Node3D.new()
		props.name = "StreetProps"
		props.position = Vector3(1,0,1.65)
		shop.add_child(props)
		var scene: PackedScene = preload("res://assets/models/produce_crate.glb") if i == 2 else preload("res://assets/models/burlap_sack.glb") if i == 1 else preload("res://assets/models/drink_crates.glb")
		for j in range(2):
			var prop: Node3D = scene.instantiate()
			prop.position.x = j*0.65
			prop.rotation.y = j*0.35
			props.add_child(prop)

func _street_details() -> void:
	var pole_mat = G.material(Color("4e5652"), 0.6, 0.5)
	for x in [-101.0, 101.0]:
		for z in range(-80, 100, 36):
			G.cylinder(self, Vector3(x, 4.5, z), 0.13, 9, pole_mat)
			G.box(self, Vector3(x + (1.8 if x < 0 else -1.8), 8.6, z), Vector3(3.6, 0.12, 0.12), pole_mat)
			G.box(self, Vector3(x + (3 if x < 0 else -3), 8.5, z), Vector3(0.8, 0.12, 0.4), G.material(Color("c2c5b5")))
			if z < 64:
				for offset in [0.0, 0.35, 0.7]:
					G.cable(self, Vector3(x, 7+offset, z), Vector3(x, 7+offset, z+36), 1.2)
	# Elevated metro structure beside the east road, away from junction visibility.
	for z in range(-88, 100, 28):
		G.box(self, Vector3(106, 6, z), Vector3(1.8, 12, 2.3), concrete, true)
		G.box(self, Vector3(106, 11.5, z), Vector3(8, 1.2, 2.5), concrete)
	G.box(self, Vector3(106, 12.4, 0), Vector3(7.5, 1.2, 220), concrete)
	for x in [102.5, 109.5]:
		G.box(self, Vector3(x, 13.2, 0), Vector3(0.3, 0.7, 220), concrete)
	# Bus stop, tea stall and parked CNGs are part of the street, not random hazards.
	G.box(self, Vector3(-101, 2.6, 31), Vector3(3.2, 0.18, 9), G.material(Color("53695b")))
	for z in [27.0, 35.0]:
		G.cylinder(self, Vector3(-102, 1.3, z), 0.06, 2.6, pole_mat)
	G.box(self,Vector3(-103.2,0.68,31),Vector3(0.7,0.12,4.8),G.material(Color("696350")),true)
	G.box(self,Vector3(-103.5,1.05,31),Vector3(0.10,0.64,4.8),G.material(Color("696350")),true)
	for z in [29.2,32.8]:
		G.cylinder(self,Vector3(-103.2,0.35,z),0.07,0.65,pole_mat)
	G.text(self, Vector3(-98.9, 3.1, 31), "বাস স্টপ", 62).rotation.y = PI/2
	var stall = Node3D.new()
	stall.position = Vector3(-104, 0.3, 57)
	stall.rotation.y = PI/2
	add_child(stall)
	G.box(stall, Vector3(0, 0.7, 0), Vector3(3, 1.4, 1.2), G.material(Color("68563d")))
	G.box(stall, Vector3(0, 2.4, 0), Vector3(3.8, 0.12, 2.7), G.material(Color("476a5c")))
	for side in [-1, 1]:
		G.cylinder(stall, Vector3(side*1.45, 1.2, 0.4), 0.04, 2.4, pole_mat)
	G.text(stall, Vector3(0, 2.0, 0.65), "মামার চা", 50)
	for i in range(5):
		G.cylinder(stall, Vector3(-1+i*0.4, 1.47, 0.2), 0.07, 0.12, G.material(Color("cec9b8")))
	for pos in [Vector3(95, 0.1, 70), Vector3(96, 0.1, 82)]:
		var parked = Node3D.new()
		parked.position = pos
		add_child(parked)
		G.vehicle(parked, "cng", Color("286344"))
	var tree_scene: PackedScene = preload("res://assets/models/street_tree.glb")
	for x in [-102.0, 78.0]:
		for z in [-62.0, -22.0, 62.0, 95.0]:
			G.box(self,Vector3(x,0.31,z),Vector3(3.2,0.04,3.2),G.material(Color("625644")))
			var tree: Node3D = tree_scene.instantiate()
			tree.position = Vector3(x,0.33,z)
			tree.scale = Vector3.ONE*0.30
			tree.rotation.y = fmod(z,TAU)
			add_child(tree)
	var road_sign = Node3D.new()
	road_sign.position = Vector3(-99, 0, 12)
	road_sign.rotation.y = PI/2
	add_child(road_sign)
	G.cylinder(road_sign, Vector3(0, 2.4, 0), 0.06, 4.8, pole_mat)
	G.box(road_sign, Vector3(0, 4.4, 0), Vector3(6, 1.5, 0.12), G.material(Color("245b50")))
	G.text(road_sign, Vector3(0, 4.4, 0.08), "সোজা  বিমানবন্দর\nডানে  কারওয়ান বাজার →", 36)

func _destination() -> void:
	# Destination occupies a recessed bay next to the eastern road, before the curb.
	G.box(self, Vector3(95.4, 0.04, -66), Vector3(4, 0.02, 9), G.material(Color("8c8c65")))
	for x in [93.4, 97.4]:
		G.box(self, Vector3(x, 0.055, -66), Vector3(0.1, 0.02, 9), G.material(Color("d9c681")))
	for z in [-70.5,-61.5]:
		G.box(self,Vector3(95.4,0.055,z),Vector3(4,0.02,0.12),G.material(Color("d9c681")))
	var painted = G.text(self,Vector3(95.4,0.07,-66),"OFFICE\nSTOP",50,Color("f3d194"))
	painted.rotation = Vector3(-PI/2,PI,0)
	painted.pixel_size = 0.014
	dest_painted = painted
	var marker = G.text(self,Vector3(95.4,5.2,-66),"অফিস / OFFICE\n↓",44,Color("f3d194"))
	marker.pixel_size = 0.006
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	dest_marker = marker

func set_atmosphere(time_of_day: String) -> void:
	if not is_instance_valid(env) or not is_instance_valid(sun):
		return
	if time_of_day == "evening":
		sun.rotation_degrees = Vector3(-14, -55, 0)
		sun.light_color = Color("ff9955")
		sun.light_energy = 0.70
		env.fog_light_color = Color("685550")
		env.tonemap_exposure = 0.78
	elif time_of_day == "midday":
		sun.rotation_degrees = Vector3(-58, -25, 0)
		sun.light_color = Color("fff5e6")
		sun.light_energy = 1.35
		env.fog_light_color = Color("d2d6d0")
		env.tonemap_exposure = 0.95
	elif time_of_day == "monsoon":
		sun.rotation_degrees = Vector3(-45, -30, 0)
		sun.light_color = Color("8fa2a6")
		sun.light_energy = 0.55
		env.ambient_light_energy = 0.55
		env.fog_light_color = Color("70787a")
		env.tonemap_exposure = 0.80
	else:
		sun.rotation_degrees = Vector3(-32, -38, 0)
		sun.light_color = Color("ffe3b6")
		sun.light_energy = 1.1
		env.fog_light_color = Color("b6b8ad")
		env.tonemap_exposure = 0.85

func _weather_effects() -> void:
	rain_volume = Node3D.new()
	rain_volume.name = "RainVolume"
	rain_volume.visible = false
	add_child(rain_volume)
	
	var rain_mmi = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 240
	var box_m = BoxMesh.new()
	box_m.size = Vector3(0.015, 0.75, 0.015)
	var rain_mat = StandardMaterial3D.new()
	rain_mat.albedo_color = Color(0.82, 0.90, 0.98, 0.65)
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_mmi.material_override = rain_mat
	mm.mesh = box_m
	for i in range(240):
		var t = Transform3D()
		var x = rng.randf_range(-22, 22)
		var y = rng.randf_range(0.2, 16.0)
		var z = rng.randf_range(-22, 22)
		t.origin = Vector3(x, y, z)
		t.basis = Basis(Vector3(1, 0, 0), deg_to_rad(12))
		mm.set_instance_transform(i, t)
	rain_mmi.multimesh = mm
	rain_volume.add_child(rain_mmi)
	
	gutter_puddles = Node3D.new()
	gutter_puddles.name = "GutterPuddles"
	gutter_puddles.visible = false
	add_child(gutter_puddles)
	
	var puddle_mat = StandardMaterial3D.new()
	puddle_mat.albedo_color = Color(0.12, 0.16, 0.18, 0.88)
	puddle_mat.roughness = 0.04
	puddle_mat.metallic = 0.20
	puddle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	for x in [-100.8, -85.6, 85.6, 100.8]:
		for z in [-75, -25, 25, 75]:
			G.box(gutter_puddles, Vector3(x, 0.042, z), Vector3(1.6, 0.008, 18.0), puddle_mat)

func set_weather(weather_name: String) -> void:
	weather = weather_name
	if weather == "monsoon":
		if is_instance_valid(rain_volume):
			rain_volume.visible = true
		if is_instance_valid(gutter_puddles):
			gutter_puddles.visible = true
		if is_instance_valid(asphalt):
			asphalt.roughness = 0.22
		if is_instance_valid(env):
			env.fog_density = 0.0035
			env.fog_light_color = Color("70787a")
	else:
		weather = "clear"
		if is_instance_valid(rain_volume):
			rain_volume.visible = false
		if is_instance_valid(gutter_puddles):
			gutter_puddles.visible = false
		if is_instance_valid(asphalt):
			asphalt.roughness = 0.94
		if is_instance_valid(env):
			env.fog_density = 0.0015
			env.fog_light_color = Color("b6b8ad")

func _process(delta: float) -> void:
	if weather == "monsoon" and is_instance_valid(rain_volume) and rain_volume.visible:
		if is_instance_valid(manager) and manager.get("player") != null and is_instance_valid(manager.player):
			rain_volume.global_position = manager.player.global_position

	if DisplayServer.get_name() != "headless":
		conductor_timer -= delta
		if conductor_timer <= 0.0:
			conductor_timer = randf_range(16.0, 32.0)
			if is_instance_valid(foley_conductor) and not foley_conductor.playing:
				foley_conductor.pitch_scale = randf_range(0.96, 1.05)
				foley_conductor.play()

		rickshaw_bell_timer -= delta
		if rickshaw_bell_timer <= 0.0:
			rickshaw_bell_timer = randf_range(10.0, 22.0)
			if is_instance_valid(foley_rickshaw_bell) and not foley_rickshaw_bell.playing:
				foley_rickshaw_bell.pitch_scale = randf_range(0.95, 1.06)
				foley_rickshaw_bell.play()

		hawker_timer -= delta
		if hawker_timer <= 0.0:
			hawker_timer = randf_range(18.0, 36.0)
			if is_instance_valid(foley_hawker) and not foley_hawker.playing:
				foley_hawker.pitch_scale = randf_range(0.97, 1.04)
				foley_hawker.play()

func _setup_street_foleys() -> void:
	# 1. Tong er Dokan Tea Stall Foley (Boiling Kettle Hiss & Spoon Clinks)
	foley_tea_stall = AudioStreamPlayer3D.new()
	foley_tea_stall.name = "Foley_TeaStall"
	foley_tea_stall.position = Vector3(-100.5, 1.2, 48.0)
	var tea_st: AudioStreamWAV = load("res://assets/audio/tea_stall.wav")
	if is_instance_valid(tea_st):
		tea_st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		tea_st.loop_begin = 0
		tea_st.loop_end = 52920
	foley_tea_stall.stream = tea_st
	foley_tea_stall.bus = "Ambience"
	foley_tea_stall.volume_db = -18.0
	foley_tea_stall.max_distance = 28.0
	add_child(foley_tea_stall)
	if DisplayServer.get_name() != "headless":
		foley_tea_stall.play()

	# 2. Bus Conductor Route Call (Farmgate! Direct!)
	foley_conductor = AudioStreamPlayer3D.new()
	foley_conductor.name = "Foley_BusConductor"
	foley_conductor.position = Vector3(-94.0, 1.5, -12.0)
	foley_conductor.stream = load("res://assets/audio/conductor_call.wav")
	foley_conductor.bus = "Ambience"
	foley_conductor.volume_db = -14.0
	foley_conductor.max_distance = 36.0
	add_child(foley_conductor)

	# 3. Rickshaw Bell Chime (Tung Tung!)
	foley_rickshaw_bell = AudioStreamPlayer3D.new()
	foley_rickshaw_bell.name = "Foley_RickshawBell"
	foley_rickshaw_bell.position = Vector3(-93.2, 1.2, 15.0)
	foley_rickshaw_bell.stream = load("res://assets/audio/rickshaw_bell.wav")
	foley_rickshaw_bell.bus = "Ambience"
	foley_rickshaw_bell.volume_db = -15.0
	foley_rickshaw_bell.max_distance = 32.0
	add_child(foley_rickshaw_bell)

	# 4. Melodic Fruit / Coconut Hawker Call
	foley_hawker = AudioStreamPlayer3D.new()
	foley_hawker.name = "Foley_FruitHawker"
	foley_hawker.position = Vector3(-85.5, 1.2, 62.0)
	foley_hawker.stream = load("res://assets/audio/hawker_call.wav")
	foley_hawker.bus = "Ambience"
	foley_hawker.volume_db = -16.0
	foley_hawker.max_distance = 28.0
	add_child(foley_hawker)

func update_destination(marker_text: String, painted_text: String = "OFFICE\nSTOP") -> void:
	if is_instance_valid(dest_marker):
		dest_marker.text = marker_text
	if is_instance_valid(dest_painted):
		dest_painted.text = painted_text

func _landmarks() -> void:
	var steel_mat = G.material(Color("3c4447"), 0.4, 0.6)
	var deck_mat = G.material(Color("6a7175"), 0.6, 0.2)
	var concrete_mat = G.material(Color("8c8c88"), 0.9, 0.0)
	var sign_mat = G.material(Color("164b3f"), 0.5, 0.1)

	# 1. Farmgate Foot-Over-Bridge
	var fob_f = Node3D.new()
	fob_f.name = "FarmgateFootOverBridge"
	fob_f.position = Vector3(-93.2, 0, -45.0)
	add_child(fob_f)

	var deck = Node3D.new()
	deck.name = "BridgeDeck"
	deck.position = Vector3(0, 5.6, 0)
	fob_f.add_child(deck)
	G.box(deck, Vector3(0, 0, 0), Vector3(22.0, 0.5, 3.2), deck_mat, true)
	G.box(deck, Vector3(0, 2.6, 0), Vector3(22.4, 0.15, 3.8), G.material(Color("265863"), 0.4, 0.3))
	for side in [-1, 1]:
		G.box(deck, Vector3(0, 1.2, side * 1.5), Vector3(22.0, 2.2, 0.1), G.material(Color("4a5c60"), 0.2, 0.5))
	var fob_sign = G.text(deck, Vector3(0, 1.8, 1.6), "ফার্মগেট পদচারী সেতু / FARMGATE FOOT-OVER-BRIDGE", 32, Color("e5f2eb"))
	fob_sign.pixel_size = 0.012

	for x in [-10.2, 10.2]:
		G.cylinder(fob_f, Vector3(x, 2.8, 0), 0.35, 5.6, concrete_mat)

	var stairs_w = Node3D.new()
	stairs_w.name = "Stairs_West"
	stairs_w.position = Vector3(-10.5, 0, 0)
	fob_f.add_child(stairs_w)
	G.box(stairs_w, Vector3(-1.8, 2.7, 0), Vector3(3.2, 5.4, 2.4), concrete_mat, true)

	var stairs_e = Node3D.new()
	stairs_e.name = "Stairs_East"
	stairs_e.position = Vector3(10.5, 0, 0)
	fob_f.add_child(stairs_e)
	G.box(stairs_e, Vector3(1.8, 2.7, 0), Vector3(3.2, 5.4, 2.4), concrete_mat, true)

	# 2. Karwan Bazar Foot-Over-Bridge
	var fob_kb = Node3D.new()
	fob_kb.name = "KarwanBazarFootOverBridge"
	fob_kb.position = Vector3(93.2, 0, -35.0)
	add_child(fob_kb)
	var kb_deck = Node3D.new()
	kb_deck.name = "BridgeDeck"
	kb_deck.position = Vector3(0, 5.6, 0)
	fob_kb.add_child(kb_deck)
	G.box(kb_deck, Vector3(0, 0, 0), Vector3(22.0, 0.5, 3.2), deck_mat, true)
	G.box(kb_deck, Vector3(0, 2.6, 0), Vector3(22.4, 0.15, 3.8), G.material(Color("265863"), 0.4, 0.3))
	var kb_sign = G.text(kb_deck, Vector3(0, 1.8, 1.6), "কারওয়ান বাজার পদচারী সেতু / KARWAN BAZAR FOOT-OVER-BRIDGE", 32, Color("e5f2eb"))
	kb_sign.pixel_size = 0.012
	var kb_stairs_w = Node3D.new()
	kb_stairs_w.name = "Stairs_West"
	kb_stairs_w.position = Vector3(-10.5, 0, 0)
	fob_kb.add_child(kb_stairs_w)
	G.box(kb_stairs_w, Vector3(-1.8, 2.7, 0), Vector3(3.2, 5.4, 2.4), concrete_mat, true)
	var kb_stairs_e = Node3D.new()
	kb_stairs_e.name = "Stairs_East"
	kb_stairs_e.position = Vector3(10.5, 0, 0)
	fob_kb.add_child(kb_stairs_e)
	G.box(kb_stairs_e, Vector3(1.8, 2.7, 0), Vector3(3.2, 5.4, 2.4), concrete_mat, true)

	# 3. Karwan Bazar Metro Station (MRT Line 6)
	var metro = Node3D.new()
	metro.name = "KarwanBazarMetroStation"
	metro.position = Vector3(93.2, 0, 15.0)
	add_child(metro)

	var canopy = Node3D.new()
	canopy.name = "StationCanopy"
	canopy.position = Vector3(0, 11.5, 0)
	metro.add_child(canopy)
	G.box(canopy, Vector3(0, 0, 0), Vector3(14.0, 3.5, 42.0), G.material(Color("e8ecef"), 0.3, 0.8), true)
	G.box(canopy, Vector3(0, -2.0, 0), Vector3(13.6, 0.6, 40.0), concrete_mat, true)
	var metro_label = G.text(canopy, Vector3(0, 1.2, 21.2), "কারওয়ান বাজার মেট্রো স্টেশন / KARWAN BAZAR MRT LINE 6", 36, Color("14624d"))
	metro_label.pixel_size = 0.014
	for z in [-15, 0, 15]:
		G.cylinder(metro, Vector3(0, 5.5, z), 1.1, 11.0, concrete_mat)

	var portal = Node3D.new()
	portal.name = "EntrancePortal"
	portal.position = Vector3(12.5, 0, 10.0)
	metro.add_child(portal)
	G.box(portal, Vector3(0, 2.5, 0), Vector3(3.5, 5.0, 7.0), G.material(Color("215a4b"), 0.5, 0.2), true)
	var portal_text = G.text(portal, Vector3(-1.8, 3.2, 0), "মেট্রোরেল প্রবেশপথ\nENTRANCE PORTAL", 28, Color("ffffff"))
	portal_text.rotation.y = -PI/2
	portal_text.pixel_size = 0.012

	# 4. SAARC Fountain Monument (Karwan Bazar South)
	var fountain = Node3D.new()
	fountain.name = "SaarcFountain"
	fountain.position = Vector3(90.0, 0, 95.0)
	add_child(fountain)
	G.cylinder(fountain, Vector3(0, 0.4, 0), 6.5, 0.8, G.material(Color("a29b8c"), 0.8, 0.1))
	G.cylinder(fountain, Vector3(0, 1.0, 0), 4.8, 0.6, G.material(Color("8a9599"), 0.2, 0.5))
	for r in range(7):
		var ang: float = float(r) * TAU / 7.0
		var spire_pos = Vector3(cos(ang)*2.6, 2.8, sin(ang)*2.6)
		G.box(fountain, spire_pos, Vector3(0.5, 4.2 + r*0.3, 0.5), G.material(Color("d6dfd9"), 0.3, 0.7))
	G.cylinder(fountain, Vector3(0, 0.85, 0), 6.2, 0.1, G.material(Color("2d5d68"), 0.05, 0.2))

	# 5. DMP Traffic Police Kiosks (at intersections)
	var kiosk_w = Node3D.new()
	kiosk_w.name = "DMPPoliceKiosk_W"
	kiosk_w.position = Vector3(-103.5, 0, 5.0)
	add_child(kiosk_w)
	G.cylinder(kiosk_w, Vector3(0, 1.6, 0), 1.25, 3.2, G.material(Color("244c66"), 0.4, 0.2))
	G.cylinder(kiosk_w, Vector3(0, 3.3, 0), 1.55, 0.35, G.material(Color("162d3d"), 0.3, 0.4))
	var kiosk_w_txt = G.text(kiosk_w, Vector3(0, 2.2, 1.3), "ডিএমপি ট্রাফিক পুলিশ\nDMP TRAFFIC POLICE", 24, Color("ffffff"))
	kiosk_w_txt.pixel_size = 0.01

	var kiosk_e = Node3D.new()
	kiosk_e.name = "DMPPoliceKiosk_E"
	kiosk_e.position = Vector3(103.5, 0, -5.0)
	add_child(kiosk_e)
	G.cylinder(kiosk_e, Vector3(0, 1.6, 0), 1.25, 3.2, G.material(Color("244c66"), 0.4, 0.2))
	G.cylinder(kiosk_e, Vector3(0, 3.3, 0), 1.55, 0.35, G.material(Color("162d3d"), 0.3, 0.4))
	var kiosk_e_txt = G.text(kiosk_e, Vector3(0, 2.2, -1.3), "ডিএমপি ট্রাফিক পুলিশ\nDMP TRAFFIC POLICE", 24, Color("ffffff"))
	kiosk_e_txt.rotation.y = PI
	kiosk_e_txt.pixel_size = 0.01

	# 6. Concrete New Jersey median barriers along multi-lane corridor
	var medians = Node3D.new()
	medians.name = "MedianBarriers"
	add_child(medians)
	var nj_mat = G.material(Color("9ea29e"), 0.95, 0.0)
	for z in range(-75, -20, 6):
		G.box(medians, Vector3(90.0, 0.45, z), Vector3(0.55, 0.9, 5.8), nj_mat, true)
	for z in range(25, 75, 6):
		G.box(medians, Vector3(90.0, 0.45, z), Vector3(0.55, 0.9, 5.8), nj_mat, true)

	# 7. Overhead Bilingual Highway Direction Gantries
	var gantry_1 = Node3D.new()
	gantry_1.name = "OverheadGantry_Farmgate"
	gantry_1.position = Vector3(-93.2, 0, 60.0)
	add_child(gantry_1)
	for x in [-9.5, 9.5]:
		G.cylinder(gantry_1, Vector3(x, 3.3, 0), 0.16, 6.6, steel_mat)
	G.box(gantry_1, Vector3(0, 6.2, 0), Vector3(19.5, 0.3, 0.3), steel_mat)
	G.box(gantry_1, Vector3(0, 5.5, 0), Vector3(11.0, 1.6, 0.12), sign_mat)
	var g1_text = G.text(gantry_1, Vector3(0, 5.5, 0.08), "↑ সোজা  ফার্মগেট / বিমানবন্দর\n→ ডানে  কারওয়ান বাজার / শাহবাগ", 32, Color("ffffff"))
	g1_text.pixel_size = 0.014

	var gantry_2 = Node3D.new()
	gantry_2.name = "OverheadGantry_KarwanBazar"
	gantry_2.position = Vector3(93.2, 0, -60.0)
	add_child(gantry_2)
	for x in [-9.5, 9.5]:
		G.cylinder(gantry_2, Vector3(x, 3.3, 0), 0.16, 6.6, steel_mat)
	G.box(gantry_2, Vector3(0, 6.2, 0), Vector3(19.5, 0.3, 0.3), steel_mat)
	G.box(gantry_2, Vector3(0, 5.5, 0), Vector3(11.0, 1.6, 0.12), sign_mat)
	var g2_text = G.text(gantry_2, Vector3(0, 5.5, -0.08), "↑ সোজা  কারওয়ান বাজার / মতিঝিল\n← বামে  ফার্মগেট", 32, Color("ffffff"))
	g2_text.rotation.y = PI
	g2_text.pixel_size = 0.014

func _traffic_events() -> void:
	# 1. Construction Work Zone with Cones, Barricade, and Hazard Beacon
	var work_zone = Node3D.new()
	work_zone.name = "ConstructionWorkZone"
	work_zone.position = Vector3(-20.0, 0, -106.2)
	add_child(work_zone)

	var cone_mat = G.material(Color("f4511e"), 0.3, 0.0)
	var white_band_mat = G.material(Color("ffffff"), 0.2, 0.1)
	var rubber_mat = G.material(Color("1a1a1a"), 0.9, 0.0)

	for i in range(4):
		var cone = Node3D.new()
		cone.name = "TrafficCone_%d" % (i + 1)
		cone.position = Vector3(-6.0 + i * 4.0, 0, 0)
		work_zone.add_child(cone)
		G.box(cone, Vector3(0, 0.03, 0), Vector3(0.45, 0.06, 0.45), rubber_mat)
		G.cylinder(cone, Vector3(0, 0.38, 0), 0.16, 0.70, cone_mat)
		G.cylinder(cone, Vector3(0, 0.45, 0), 0.14, 0.18, white_band_mat)

	var barricade = Node3D.new()
	barricade.name = "RoadBarricade"
	barricade.position = Vector3(0, 0, 0.8)
	work_zone.add_child(barricade)
	var wood_post_mat = G.material(Color("4a3525"), 0.8, 0.0)
	var stripe_mat = G.material(Color("e53935"), 0.4, 0.0)
	G.cylinder(barricade, Vector3(-1.8, 0.6, 0), 0.06, 1.2, wood_post_mat)
	G.cylinder(barricade, Vector3(1.8, 0.6, 0), 0.06, 1.2, wood_post_mat)
	G.box(barricade, Vector3(0, 0.85, 0), Vector3(3.8, 0.3, 0.06), stripe_mat, false)
	G.box(barricade, Vector3(0, 0.45, 0), Vector3(3.8, 0.25, 0.06), white_band_mat, false)
	var barr_txt = G.text(barricade, Vector3(0, 0.85, 0.04), "রাস্তা মেরামতের কাজ চলছে / ROAD WORK", 22, Color("ffffff"))
	barr_txt.pixel_size = 0.009

	var beacon = Node3D.new()
	beacon.name = "HazardBeacon"
	beacon.position = Vector3(1.8, 1.25, 0)
	work_zone.add_child(beacon)
	var amber_emit = StandardMaterial3D.new()
	amber_emit.albedo_color = Color("ff9800")
	amber_emit.emission_enabled = true
	amber_emit.emission = Color("ff9800") * 2.5
	G.cylinder(beacon, Vector3(0, 0.1, 0), 0.12, 0.22, amber_emit)

	# 2. Broken Down Vehicle in Outer Lane
	var breakdown = BrokenDown.new()
	breakdown.name = "BrokenDownVehicle"
	breakdown.position = Vector3(-96.5, 0, -25.0)
	breakdown.set("hazard_flashers_active", true)
	add_child(breakdown)

	var body_mat = G.material(Color("5c768d"), 0.5, 0.2)
	var glass_mat = G.material(Color("102026"), 0.1, 0.8)
	var tire_mat = G.material(Color("1f2326"), 0.9, 0.0)
	G.box(breakdown, Vector3(0, 0.95, 0), Vector3(1.9, 1.4, 4.2), body_mat, false)
	G.box(breakdown, Vector3(0, 1.3, -1.0), Vector3(1.85, 0.8, 1.8), glass_mat)
	for x in [-0.95, 0.95]:
		for z in [-1.3, 1.3]:
			G.cylinder(breakdown, Vector3(x, 0.34, z), 0.34, 0.22, tire_mat)
	var triangle = Node3D.new()
	triangle.name = "WarningTriangle"
	triangle.position = Vector3(0, 0, 7.5)
	breakdown.add_child(triangle)
	var refl_red = G.material(Color("ff1744"), 0.3, 0.0)
	G.box(triangle, Vector3(0, 0.25, 0), Vector3(0.5, 0.5, 0.04), refl_red)
	var break_txt = G.text(breakdown, Vector3(0, 1.1, 2.15), "জরুরি মেরামত / BREAKDOWN", 18, Color("ffffff"))
	break_txt.pixel_size = 0.008

	# 3. Sidewalk Vendor Stall: Tong er Dokan (Tea Stall)
	var tea_stall = Node3D.new()
	tea_stall.name = "VendorStall_Tea"
	tea_stall.position = Vector3(-100.5, 0.2, 48.0)
	add_child(tea_stall)

	var wood_mat = G.material(Color("6d4c41"), 0.8, 0.0)
	var dark_wood_mat = G.material(Color("3e2723"), 0.85, 0.0)
	var tarp_mat = G.material(Color("1565c0"), 0.6, 0.0)
	var metal_mat = G.material(Color("cfd8dc"), 0.3, 0.7)

	for x in [-1.3, 1.3]:
		for z in [-1.1, 1.1]:
			G.cylinder(tea_stall, Vector3(x, 1.25, z), 0.05, 2.5, wood_mat)

	var canopy = Node3D.new()
	canopy.name = "Canopy"
	canopy.position = Vector3(0, 2.45, 0)
	tea_stall.add_child(canopy)
	G.box(canopy, Vector3(0, 0, 0), Vector3(3.2, 0.08, 2.6), tarp_mat)
	G.box(tea_stall, Vector3(0, 0.9, 0), Vector3(2.5, 0.85, 0.9), wood_mat, false)

	var bench = Node3D.new()
	bench.name = "Bench"
	bench.position = Vector3(0, 0.42, 1.35)
	tea_stall.add_child(bench)
	G.box(bench, Vector3(0, 0, 0), Vector3(2.2, 0.42, 0.45), dark_wood_mat, false)

	G.cylinder(tea_stall, Vector3(-0.6, 1.45, 0), 0.16, 0.32, metal_mat)
	G.cylinder(tea_stall, Vector3(0.5, 1.42, 0), 0.12, 0.24, G.material(Color("ffecb3"), 0.4, 0.0))
	var tea_sign = G.text(tea_stall, Vector3(0, 2.2, 1.32), "মামার স্পেশাল চা ও বিস্কুট / MAMA'S SPECIAL TEA", 20, Color("ffffff"))
	tea_sign.pixel_size = 0.009

	# 4. Sidewalk Vendor Stall: Fruit & Green Coconut Cart
	var fruit_stall = Node3D.new()
	fruit_stall.name = "VendorStall_Fruit"
	fruit_stall.position = Vector3(-85.5, 0.2, 62.0)
	add_child(fruit_stall)

	var cart = Node3D.new()
	cart.name = "FruitCart"
	fruit_stall.add_child(cart)
	G.box(cart, Vector3(0, 0.75, 0), Vector3(2.0, 0.6, 1.3), wood_mat, false)
	for z in [-0.5, 0.5]:
		G.cylinder(cart, Vector3(-0.95, 0.4, z), 0.4, 0.08, tire_mat)
		G.cylinder(cart, Vector3(0.95, 0.4, z), 0.4, 0.08, tire_mat)
	G.cylinder(cart, Vector3(-0.4, 1.15, 0), 0.25, 0.25, G.material(Color("388e3c"), 0.5, 0.0))
	G.box(cart, Vector3(0.4, 1.15, 0), Vector3(0.7, 0.2, 0.5), G.material(Color("fbc02d"), 0.4, 0.0))
	var fruit_sign = G.text(fruit_stall, Vector3(0, 1.6, 0), "মিষ্টি ডাব ও তাজা ফল / FRESH COCONUTS & FRUITS", 20, Color("ffffff"))
	fruit_sign.pixel_size = 0.009

	# 5. DMP Traffic Police Officer
	var police_officer = PoliceOfficer.new()
	police_officer.name = "TrafficPoliceOfficer"
	police_officer.position = Vector3(-98.0, 0.25, 5.0)
	add_child(police_officer)

	G.cylinder(police_officer, Vector3(0, 0.12, 0), 1.1, 0.24, G.material(Color("9ea29e"), 0.95, 0.0))
	var navy_mat = G.material(Color("1a2530"), 0.7, 0.0)
	var white_shirt_mat = G.material(Color("f4f6f7"), 0.6, 0.0)
	var hi_vis_mat = G.material(Color("c6ff00"), 0.4, 0.1)
	var skin_mat = G.material(Color("795548"), 0.7, 0.0)

	G.cylinder(police_officer, Vector3(-0.16, 0.65, 0), 0.09, 0.8, navy_mat)
	G.cylinder(police_officer, Vector3(0.16, 0.65, 0), 0.09, 0.8, navy_mat)
	G.box(police_officer, Vector3(0, 1.35, 0), Vector3(0.52, 0.65, 0.28), white_shirt_mat)
	G.box(police_officer, Vector3(0, 1.35, 0.01), Vector3(0.50, 0.55, 0.28), hi_vis_mat)
	G.cylinder(police_officer, Vector3(0, 1.82, 0), 0.12, 0.22, skin_mat)
	G.cylinder(police_officer, Vector3(0, 1.95, 0), 0.16, 0.08, white_shirt_mat)
	G.box(police_officer, Vector3(0, 1.93, 0.12), Vector3(0.20, 0.03, 0.12), navy_mat)

	var arm_l = Node3D.new()
	arm_l.name = "ArmLeft"
	arm_l.position = Vector3(-0.32, 1.55, 0)
	police_officer.add_child(arm_l)
	G.cylinder(arm_l, Vector3(0, -0.28, 0), 0.07, 0.55, white_shirt_mat)
	G.cylinder(arm_l, Vector3(0, -0.58, 0), 0.06, 0.12, white_band_mat)

	var arm_r = Node3D.new()
	arm_r.name = "ArmRight"
	arm_r.position = Vector3(0.32, 1.55, 0)
	police_officer.add_child(arm_r)
	G.cylinder(arm_r, Vector3(0, -0.28, 0), 0.07, 0.55, white_shirt_mat)
	G.cylinder(arm_r, Vector3(0, -0.58, 0), 0.06, 0.12, white_band_mat)
	G.cylinder(arm_r, Vector3(0, -0.75, 0.15), 0.025, 0.45, G.material(Color("ffeb3b"), 0.3, 0.0))

