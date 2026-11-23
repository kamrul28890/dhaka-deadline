class_name DhakaCorridorExpressway
extends Node3D

# Dhaka Express: Shahbag to Uttara 20.5km Arterial Corridor
# Complete continuous elevated flyover & expressway track with 7 iconic landmark sectors,
# physical crash barriers, overhead sign gantries, street lighting, and sector waypoints.

const Geometry = preload("res://scripts/geometry.gd")

# Sector Definitions
const SECTORS = [
	{
		"id": "shahbag",
		"name": "Shahbag Gateway & Institutional Strip",
		"bn": "শাহবাগ তোরণ ও স্মৃতি চত্বর",
		"z_start": 200.0,
		"z_end": -150.0,
		"lanes": 6,
		"deck_elevation": 7.5,
		"landmarks": ["National Museum", "BSMMU Hospital", "InterContinental"]
	},
	{
		"id": "karwan_bazar",
		"name": "Bangla Motor & Karwan Bazar Metro Spine",
		"bn": "বাংলামোটর ও কারওয়ান বাজার মেট্রোরেল করিডোর",
		"z_start": -150.0,
		"z_end": -600.0,
		"lanes": 6,
		"deck_elevation": 7.5,
		"has_mrt_viaduct": true,
		"landmarks": ["CA Bhaban", "PetroBangla", "MRT Line 6 Station", "SAARC Fountain"]
	},
	{
		"id": "farmgate",
		"name": "Farmgate & Bijoy Sarani Gateway",
		"bn": "ফার্মগেট ও বিজয় সরণি তোরণ",
		"z_start": -600.0,
		"z_end": -1000.0,
		"lanes": 8,
		"deck_elevation": 7.5,
		"landmarks": ["Ananda Cinema", "Military Museum", "Farmgate Flyover Ramp"]
	},
	{
		"id": "mohakhali",
		"name": "Mohakhali Elevated Flyover & Transit Hub",
		"bn": "মহাখালী ফ্লাইওভার ও বাস টার্মিনাল",
		"z_start": -1000.0,
		"z_end": -1450.0,
		"lanes": 6,
		"deck_elevation": 10.5, # Elevated flyover soaring above terminal
		"is_elevated_flyover": true,
		"landmarks": ["Mohakhali Terminal", "ICDDR,B", "Railway Crossing Viaduct"]
	},
	{
		"id": "banani",
		"name": "Banani & Kakoli Commercial Strip",
		"bn": "বনানী ও কাকলী বাণিজ্যিক এলাকা",
		"z_start": -1450.0,
		"z_end": -1850.0,
		"lanes": 8,
		"deck_elevation": 7.5,
		"landmarks": ["Chairman Bari", "Kakoli Tower", "Banani Station", "Digital Billboards"]
	},
	{
		"id": "kuril",
		"name": "Kuril 4-Tier Spaghetti Interchange & Khilkhet",
		"bn": "কুড়িল ফ্লাইওভার ও খিলক্ষেত এক্সপ্রেসওয়ে",
		"z_start": -1850.0,
		"z_end": -2250.0,
		"lanes": 8,
		"deck_elevation": 8.5,
		"has_overhead_ramps": true,
		"landmarks": ["Kuril Loops", "Army Golf Club", "Radisson Blu", "Shewra FOB"]
	},
	{
		"id": "uttara",
		"name": "Hazrat Shahjalal Airport & Uttara Terminal Plaza",
		"bn": "বিমানবন্দর টার্মিনাল ৩ ও উত্তরা সেক্টর তোরণ",
		"z_start": -2250.0,
		"z_end": -2650.0,
		"lanes": 8,
		"deck_elevation": 7.5,
		"landmarks": ["HSIA Terminal 3", "Airport Runway Lights", "Kawla Toll Plaza", "Uttara Sector 3-11 Gateway"]
	}
]

# Track metrics
const TRACK_START_Z: float = 180.0
const TRACK_END_Z: float = -2600.0
const TOTAL_DISTANCE_METRES: float = 20500.0 # Authentic 20.5 km scale representation
const DECK_HALF_WIDTH: float = 11.0 # 22m total width (4 lanes each direction)

# Materials
var mat_asphalt: StandardMaterial3D
var mat_barrier: StandardMaterial3D
var mat_marking_white: StandardMaterial3D
var mat_marking_yellow: StandardMaterial3D
var mat_concrete_pier: StandardMaterial3D
var mat_gantry_green: StandardMaterial3D
var mat_metal_pole: StandardMaterial3D
var mat_glass_tower: StandardMaterial3D
var mat_neon_blue: StandardMaterial3D
var mat_neon_amber: StandardMaterial3D

# Runtime tracking
var sector_markers: Array = []
var active_sector_index: int = 0
var gantry_nodes: Array = []

func _init() -> void:
	name = "DhakaCorridorExpressway"
	_init_materials()

func _init_materials() -> void:
	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color("1e2227")
	mat_asphalt.roughness = 0.55
	mat_asphalt.metallic = 0.05

	mat_barrier = StandardMaterial3D.new()
	mat_barrier.albedo_color = Color("b5bcc4")
	mat_barrier.roughness = 0.70

	mat_marking_white = StandardMaterial3D.new()
	mat_marking_white.albedo_color = Color("f0f3f6")
	mat_marking_white.roughness = 0.40

	mat_marking_yellow = StandardMaterial3D.new()
	mat_marking_yellow.albedo_color = Color("f59e0b")
	mat_marking_yellow.roughness = 0.40

	mat_concrete_pier = StandardMaterial3D.new()
	mat_concrete_pier.albedo_color = Color("8c949e")
	mat_concrete_pier.roughness = 0.85

	mat_gantry_green = StandardMaterial3D.new()
	mat_gantry_green.albedo_color = Color("055a36")
	mat_gantry_green.roughness = 0.45

	mat_metal_pole = StandardMaterial3D.new()
	mat_metal_pole.albedo_color = Color("4b5563")
	mat_metal_pole.metallic = 0.60
	mat_metal_pole.roughness = 0.35

	mat_glass_tower = StandardMaterial3D.new()
	mat_glass_tower.albedo_color = Color("1e3a5f")
	mat_glass_tower.roughness = 0.15
	mat_glass_tower.metallic = 0.30

	mat_neon_blue = StandardMaterial3D.new()
	mat_neon_blue.albedo_color = Color("38bdf8")
	mat_neon_blue.emission_enabled = true
	mat_neon_blue.emission = Color("38bdf8")
	mat_neon_blue.emission_energy_multiplier = 2.0

	mat_neon_amber = StandardMaterial3D.new()
	mat_neon_amber.albedo_color = Color("fbbf24")
	mat_neon_amber.emission_enabled = true
	mat_neon_amber.emission = Color("fbbf24")
	mat_neon_amber.emission_energy_multiplier = 2.5

func build_corridor() -> void:
	# Build all 7 continuous sectors
	for i in range(SECTORS.size()):
		var sec = SECTORS[i]
		_build_sector_segment(sec, i)

	# Build overhead highway sign gantries
	_build_highway_gantries()

	# Build landmark architecture along the corridor
	_build_landmark_structures()

	# Build elevated support viaduct piers
	_build_viaduct_piers()

func get_elevation_at_z(z: float) -> float:
	# Continuous smooth elevation interpolation along the highway
	for sec in SECTORS:
		if z <= sec.z_start and z >= sec.z_end:
			var t: float = (sec.z_start - z) / (sec.z_start - sec.z_end)
			return sec.deck_elevation
	if z > SECTORS[0].z_start:
		return SECTORS[0].deck_elevation
	return SECTORS[SECTORS.size() - 1].deck_elevation

func get_sector_at_z(z: float) -> Dictionary:
	for sec in SECTORS:
		if z <= sec.z_start and z >= sec.z_end:
			return sec
	if z > SECTORS[0].z_start:
		return SECTORS[0]
	return SECTORS[SECTORS.size() - 1]

func get_progress_ratio(current_z: float) -> float:
	var total_span: float = TRACK_START_Z - TRACK_END_Z
	var traversed: float = TRACK_START_Z - current_z
	return clamp(traversed / total_span, 0.0, 1.0)

func get_kilometres_travelled(current_z: float) -> float:
	return get_progress_ratio(current_z) * (TOTAL_DISTANCE_METRES / 1000.0)

# Build a continuous sector roadway slice
func _build_sector_segment(sec: Dictionary, idx: int) -> void:
	var z_start: float = sec.z_start
	var z_end: float = sec.z_end
	var length: float = abs(z_start - z_end)
	var center_z: float = (z_start + z_end) * 0.5
	var elev: float = sec.deck_elevation
	var half_w: float = DECK_HALF_WIDTH

	# 1. Roadway Deck with physical collision
	var deck = Geometry.box(self, Vector3(0, elev, center_z), Vector3(half_w * 2.0, 0.45, length), mat_asphalt, true)
	deck.name = "Deck_" + sec.id

	# 2. Outer Left Concrete New Jersey Crash Barrier (West, X = -half_w)
	var left_barrier = Geometry.box(self, Vector3(-half_w + 0.25, elev + 0.55, center_z), Vector3(0.5, 1.1, length), mat_barrier, true)
	left_barrier.name = "Barrier_L_" + sec.id

	# 3. Outer Right Concrete New Jersey Crash Barrier (East, X = +half_w)
	var right_barrier = Geometry.box(self, Vector3(half_w - 0.25, elev + 0.55, center_z), Vector3(0.5, 1.1, length), mat_barrier, true)
	right_barrier.name = "Barrier_R_" + sec.id

	# 4. Central Median Divider Barrier with collision
	var median = Geometry.box(self, Vector3(0, elev + 0.45, center_z), Vector3(0.6, 0.9, length), mat_barrier, true)
	median.name = "Median_" + sec.id

	# 5. Lane Markings
	_build_lane_markings(z_start, z_end, elev)

	# 6. Highway Street Lighting Poles along the median every 45m
	var z_curr: float = z_start - 20.0
	while z_curr > z_end + 10.0:
		_build_highway_light_pole(Vector3(0, elev, z_curr))
		z_curr -= 45.0

func _build_lane_markings(z_start: float, z_end: float, elev: float) -> void:
	# Yellow continuous edge lines along barriers
	var length: float = abs(z_start - z_end)
	var center_z: float = (z_start + z_end) * 0.5
	Geometry.box(self, Vector3(-DECK_HALF_WIDTH + 0.65, elev + 0.23, center_z), Vector3(0.18, 0.02, length), mat_marking_yellow, false)
	Geometry.box(self, Vector3(DECK_HALF_WIDTH - 0.65, elev + 0.23, center_z), Vector3(0.18, 0.02, length), mat_marking_yellow, false)

	# Dashed white lane dividers (Northbound lanes: X in [-9.5, -0.6]; Southbound: X in [0.6, 9.5])
	var lane_offsets: Array = [-7.0, -3.8, 3.8, 7.0]
	var z_step: float = 12.0 # 6m dash, 6m gap
	var z_walk: float = z_start - 3.0
	while z_walk > z_end:
		for x_off in lane_offsets:
			Geometry.box(self, Vector3(x_off, elev + 0.23, z_walk - 3.0), Vector3(0.16, 0.02, 6.0), mat_marking_white, false)
		z_walk -= z_step

func _build_highway_light_pole(pos: Vector3) -> void:
	# Central median light pole with dual outreach arms
	var pole = Geometry.cylinder(self, pos + Vector3(0, 3.5, 0), 0.12, 7.0, mat_metal_pole)
	# Left outreach arm (West)
	Geometry.box(self, pos + Vector3(-1.8, 7.0, 0), Vector3(3.6, 0.1, 0.1), mat_metal_pole, false)
	# Right outreach arm (East)
	Geometry.box(self, pos + Vector3(1.8, 7.0, 0), Vector3(3.6, 0.1, 0.1), mat_metal_pole, false)
	# Lamp luminaire heads with warm/white emission
	Geometry.box(self, pos + Vector3(-3.4, 6.85, 0), Vector3(0.6, 0.15, 0.4), mat_neon_amber, false)
	Geometry.box(self, pos + Vector3(3.4, 6.85, 0), Vector3(0.6, 0.15, 0.4), mat_neon_amber, false)

func _build_highway_gantries() -> void:
	# Key overhead destination gantries at sector transitions
	var gantry_configs = [
		{
			"z": 100.0,
			"en": "DHAKA ELEVATED EXPRESSWAY -> UTTARA / AIRPORT",
			"bn": "ঢাকা এলিভেটেড এক্সপ্রেসওয়ে -> বিমানবন্দর / উত্তরা",
			"lanes_info": "[ LANE 1-2: UTTARA EXPRESS ]  [ LANE 3-4: BANANI / MOHAKHALI ]"
		},
		{
			"z": -450.0,
			"en": "KARWAN BAZAR & FARMGATE INTERCHANGE",
			"bn": "কারওয়ান বাজার ও ফার্মগেট ইন্টারচেঞ্জ",
			"lanes_info": "[ STRAIGHT: AIRPORT EXPRESS ]  [ EXIT: PANTHAPATH ]"
		},
		{
			"z": -920.0,
			"en": "MOHAKHALI FLYOVER VIADUCT (HEIGHT LIMIT 4.5M)",
			"bn": "মহাখালী ফ্লাইওভার (উচ্চতা সীমা ৪.৫ মি.)",
			"lanes_info": "[ EXPRESS FLYOVER -> BANANI / AIRPORT ]"
		},
		{
			"z": -1400.0,
			"en": "BANANI & KAKOLI COMMERCIAL CORRIDOR",
			"bn": "বনানী ও কাকলী বাণিজ্যিক এলাকা",
			"lanes_info": "[ STRAIGHT: AIRPORT / KURIL ]  [ EXIT: GULSHAN-2 ]"
		},
		{
			"z": -1800.0,
			"en": "KURIL 4-TIER FLYOVER & PURBACHAL EXPRESSWAY",
			"bn": "কুড়িল ফ্লাইওভার ও ৩০০ ফিট এক্সপ্রেসওয়ে",
			"lanes_info": "[ LANES 1-2: AIRPORT TERMINAL ]  [ EXIT: PURBACHAL 300FT ]"
		},
		{
			"z": -2200.0,
			"en": "HAZRAT SHAHJALAL INT'L AIRPORT (TERMINAL 1, 2, 3)",
			"bn": "হযরত শাহজালাল আন্তর্জাতিক বিমানবন্দর (টার্মিনাল ১, ২, ৩)",
			"lanes_info": "[ ALL LANES: TERMINAL 3 & UTTARA SECTORS 1-14 ]"
		}
	]

	for cfg in gantry_configs:
		var z_pos: float = cfg.z
		var elev: float = get_elevation_at_z(z_pos)
		var span_w: float = DECK_HALF_WIDTH * 2.0 + 2.0

		# Left and Right vertical steel trusses
		Geometry.box(self, Vector3(-DECK_HALF_WIDTH - 0.5, elev + 3.8, z_pos), Vector3(0.5, 7.6, 0.5), mat_metal_pole, false)
		Geometry.box(self, Vector3(DECK_HALF_WIDTH + 0.5, elev + 3.8, z_pos), Vector3(0.5, 7.6, 0.5), mat_metal_pole, false)

		# Overhead horizontal gantry truss
		Geometry.box(self, Vector3(0, elev + 7.4, z_pos), Vector3(span_w, 0.8, 0.6), mat_metal_pole, false)

		# Bilingual Green Highway Signboard
		var sign_board = Geometry.box(self, Vector3(0, elev + 6.3, z_pos + 0.1), Vector3(18.0, 1.8, 0.15), mat_gantry_green, false)
		sign_board.name = "GantrySign_" + str(round(z_pos))

		# Sign labels
		var lbl_bn = Geometry.text(sign_board, Vector3(0, 0.35, 0.12), cfg.bn, 36, Color("ffffff"))
		lbl_bn.rotation.y = PI
		lbl_bn.pixel_size = 0.007

		var lbl_en = Geometry.text(sign_board, Vector3(0, -0.15, 0.12), cfg.en, 28, Color("fef08a"))
		lbl_en.rotation.y = PI
		lbl_en.pixel_size = 0.006

		var lbl_lanes = Geometry.text(sign_board, Vector3(0, -0.55, 0.12), cfg.lanes_info, 20, Color("67e8f9"))
		lbl_lanes.rotation.y = PI
		lbl_lanes.pixel_size = 0.005

		gantry_nodes.append(sign_board)

func _build_viaduct_piers() -> void:
	# Heavy reinforced concrete piers supporting the elevated deck every 35m
	var z: float = TRACK_START_Z
	while z > TRACK_END_Z:
		var elev: float = get_elevation_at_z(z)
		if elev > 1.5:
			# Twin cylindrical concrete pillars descending to ground
			Geometry.cylinder(self, Vector3(-4.5, elev * 0.5, z), 0.9, elev, mat_concrete_pier)
			Geometry.cylinder(self, Vector3(4.5, elev * 0.5, z), 0.9, elev, mat_concrete_pier)
			# Cross-beam hammerhead pier cap under deck
			Geometry.box(self, Vector3(0, elev - 0.4, z), Vector3(12.5, 0.8, 2.2), mat_concrete_pier, false)
		z -= 35.0

func _build_landmark_structures() -> void:
	# Sector 1: Shahbag - BSMMU Hospital Tower & National Museum Block
	Geometry.box(self, Vector3(-26.0, 12.0, 60.0), Vector3(20.0, 24.0, 45.0), mat_barrier, false)
	Geometry.box(self, Vector3(26.0, 10.0, 30.0), Vector3(18.0, 20.0, 50.0), mat_glass_tower, false)

	# Sector 2: Karwan Bazar - MRT Line 6 Elevated Viaduct & CA Bhaban
	_build_mrt_viaduct_segment(-150.0, -600.0)
	Geometry.box(self, Vector3(-28.0, 18.0, -350.0), Vector3(22.0, 36.0, 40.0), mat_glass_tower, false)
	Geometry.box(self, Vector3(28.0, 15.0, -420.0), Vector3(20.0, 30.0, 50.0), mat_barrier, false)

	# Sector 4: Mohakhali Terminal Sheds & Railway Crossing
	Geometry.box(self, Vector3(-30.0, 6.0, -1180.0), Vector3(32.0, 12.0, 80.0), mat_barrier, false)
	Geometry.box(self, Vector3(30.0, 8.0, -1250.0), Vector3(24.0, 16.0, 65.0), mat_glass_tower, false)

	# Sector 5: Banani Corporate Strip & Digital LED Billboards
	Geometry.box(self, Vector3(-27.0, 20.0, -1600.0), Vector3(18.0, 40.0, 35.0), mat_glass_tower, false)
	var led_board = Geometry.box(self, Vector3(-27.0, 24.0, -1580.0), Vector3(12.0, 6.0, 0.4), mat_neon_blue, false)
	var led_txt = Geometry.text(led_board, Vector3(0, 0, 0.3), "BANANI SMART CITY", 48, Color("0f172a"))
	led_txt.pixel_size = 0.012

	# Sector 6: Kuril Spaghetti Interchange Overpassing Loop Decks
	_build_kuril_overpass_ramps()

	# Sector 7: Hazrat Shahjalal International Airport Terminal 3 (Wavy Canopy)
	_build_airport_terminal_3()

func _build_mrt_viaduct_segment(z_start: float, z_end: float) -> void:
	# Elevated MRT Line 6 track running overhead (Y = 14.5m)
	var length: float = abs(z_start - z_end)
	var center_z: float = (z_start + z_end) * 0.5
	# MRT U-girder guideway deck
	Geometry.box(self, Vector3(0, 13.5, center_z), Vector3(8.5, 1.2, length), mat_concrete_pier, false)
	# MRT Concrete parapet walls
	Geometry.box(self, Vector3(-4.1, 14.5, center_z), Vector3(0.4, 1.2, length), mat_barrier, false)
	Geometry.box(self, Vector3(4.1, 14.5, center_z), Vector3(0.4, 1.2, length), mat_barrier, false)
	# Heavy single-column T-piers every 40m
	var z: float = z_start
	while z > z_end:
		Geometry.cylinder(self, Vector3(0, 6.5, z), 1.1, 13.0, mat_concrete_pier)
		Geometry.box(self, Vector3(0, 12.6, z), Vector3(9.2, 0.9, 2.0), mat_concrete_pier, false)
		z -= 40.0

func _build_kuril_overpass_ramps() -> void:
	# Curved high-level ramp soaring overhead at Kuril (Z = -2000m, Y = 13.0m)
	Geometry.box(self, Vector3(0, 12.5, -2020.0), Vector3(10.0, 0.8, 120.0), mat_asphalt, false)
	Geometry.box(self, Vector3(-4.8, 13.2, -2020.0), Vector3(0.4, 0.9, 120.0), mat_barrier, false)
	Geometry.box(self, Vector3(4.8, 13.2, -2020.0), Vector3(0.4, 0.9, 120.0), mat_barrier, false)

func _build_airport_terminal_3() -> void:
	# Iconic modern white perforated wave facade of HSIA Terminal 3
	var term_z: float = -2420.0
	var term = Geometry.box(self, Vector3(38.0, 10.0, term_z), Vector3(25.0, 18.0, 160.0), mat_barrier, false)
	term.name = "Airport_Terminal_3"
	# Glowing sign
	var sign_txt = Geometry.text(term, Vector3(-12.8, 4.5, 0), "হযরত শাহজালাল আন্তর্জাতিক বিমানবন্দর - টার্মিনাল ৩\nHAZRAT SHAHJALAL INT'L AIRPORT - TERMINAL 3", 42, Color("0284c7"))
	sign_txt.rotation.y = PI * 0.5
	sign_txt.pixel_size = 0.009

	# Runway 14 Approach Lighting System (elevated red and green strobe towers)
	for i in range(6):
		var tower_z: float = term_z - 80.0 - i * 25.0
		Geometry.cylinder(self, Vector3(65.0, 4.0, tower_z), 0.15, 8.0, mat_metal_pole)
		Geometry.box(self, Vector3(65.0, 8.1, tower_z), Vector3(1.5, 0.2, 0.4), mat_neon_amber, false)

	# Low-flying airliner visual landing approach overhead
	var airliner = Node3D.new()
	airliner.name = "ApproachingAirliner"
	airliner.position = Vector3(45.0, 38.0, term_z + 100.0)
	airliner.rotation.y = PI * 0.85
	add_child(airliner)
	# Fuselage & Wings
	Geometry.cylinder(airliner, Vector3(0, 0, 0), 2.2, 28.0, mat_barrier)
	Geometry.box(airliner, Vector3(0, 0, 2.0), Vector3(24.0, 0.4, 4.5), mat_barrier, false)
	Geometry.box(airliner, Vector3(0, 3.2, -10.0), Vector3(0.3, 4.5, 3.5), mat_neon_blue, false)
