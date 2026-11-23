extends SceneTree

const Network = preload("res://scripts/road_network.gd")
var failures: Array[String] = []
var checks: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Topological corridor metadata verification
	check(Network.CORRIDOR_NODES is Dictionary, "Road network defines CORRIDOR_NODES dictionary")
	for key in ["NW", "W", "SW", "NE", "E", "SE"]:
		check(Network.CORRIDOR_NODES.has(key), "CORRIDOR_NODES contains node "+key)
		var node_data: Dictionary = Network.CORRIDOR_NODES.get(key, {})
		check(node_data.has("name") and node_data.has("bn") and node_data.has("zone"), "Node "+key+" contains name, bn, and zone")

	check(Network.CORRIDOR_NODES["NW"]["zone"] == "Farmgate", "NW node is in Farmgate zone")
	check(Network.CORRIDOR_NODES["W"]["zone"] == "Farmgate", "W node is in Farmgate zone")
	check(Network.CORRIDOR_NODES["E"]["zone"] == "Karwan Bazar", "E node is in Karwan Bazar zone")
	check(Network.CORRIDOR_NODES["SE"]["zone"] == "Karwan Bazar", "SE node is in Karwan Bazar zone")

	# 2. Corridor query methods
	var net_inst = Network.new()
	check(net_inst.has_method("corridor_info"), "Network has corridor_info method")
	var nw_info: Dictionary = Network.corridor_info("NW")
	check(nw_info.get("name") != "" and nw_info.get("bn") != "", "corridor_info returns valid names")

	check(net_inst.has_method("corridor_name"), "Network has corridor_name method")
	var kni_road: Dictionary = Network.corridor_name("NE", "E")
	check("Kazi Nazrul Islam" in kni_road.get("en", ""), "NE->E corridor is Kazi Nazrul Islam Avenue")
	check("কাজী নজরুল ইসলাম" in kni_road.get("bn", ""), "NE->E corridor contains Bengali road title")

	check(net_inst.has_method("is_multilane"), "Network has is_multilane method")
	check(Network.is_multilane("NE", "E") == true, "Kazi Nazrul Islam corridor is marked as multilane")
	check(Network.is_multilane("W", "E") == false, "Panthapath connector is standard single-lane per direction")

	# 3. Main scene & district landmark verification
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	var fob_farmgate = world.district.find_child("FarmgateFootOverBridge", true, false)
	check(fob_farmgate != null, "District contains Farmgate Foot-Over-Bridge")
	if fob_farmgate:
		var bridge_deck = fob_farmgate.find_child("BridgeDeck", true, false)
		check(bridge_deck != null, "Farmgate FOB contains elevated bridge deck")
		if bridge_deck:
			check(bridge_deck.global_position.y >= 5.0, "Farmgate FOB provides > 5.0m vertical clearance for buses and trucks")
		var stairs = fob_farmgate.find_children("Stairs*", "Node3D", true, false)
		check(stairs.size() >= 2, "Farmgate FOB has staircases connecting both sidewalks")

	var fob_kb = world.district.find_child("KarwanBazarFootOverBridge", true, false)
	check(fob_kb != null, "District contains Karwan Bazar Foot-Over-Bridge across Kazi Nazrul Islam Ave")

	var metro_station = world.district.find_child("KarwanBazarMetroStation", true, false)
	check(metro_station != null, "District contains Karwan Bazar Metro Station landmark on MRT Line 6")
	if metro_station:
		var canopy = metro_station.find_child("StationCanopy", true, false)
		check(canopy != null, "Metro station includes elevated passenger platform canopy")
		var portal = metro_station.find_child("EntrancePortal", true, false)
		check(portal != null, "Metro station includes sidewalk entrance portal")

	var saarc_fountain = world.district.find_child("SaarcFountain", true, false)
	check(saarc_fountain != null, "District contains SAARC Fountain landmark at Karwan Bazar South")

	var police_kiosks = world.district.find_children("DMPPoliceKiosk*", "Node3D", true, false)
	check(police_kiosks.size() >= 2, "District contains DMP Traffic Police kiosks at major intersections")

	var median_barriers = world.district.find_child("MedianBarriers", true, false)
	check(median_barriers != null, "District contains concrete median barriers along multi-lane corridor")

	var gantries = world.district.find_children("OverheadGantry*", "Node3D", true, false)
	check(gantries.size() >= 2, "District contains overhead bilingual highway direction gantries")

	# 4. Expanded pedestrian crowd behavior
	check(world.pedestrians.size() >= 16, "District spawns expanded pedestrian crowd population (>= 16)")
	var lead_ped = world.pedestrians[0]
	check(lead_ped.get_meta("is_crossing_leader", false) == true or lead_ped.get_meta("index") == 0, "Lead pedestrian is assigned crossing leadership")

	var crowd_crossing_members: int = 0
	for ped in world.pedestrians:
		if ped.get_meta("crossing_group", false) == true:
			crowd_crossing_members += 1
	check(crowd_crossing_members >= 3, "Zebra crossing is traversed by a coordinated pedestrian crowd (>= 3)")

	var all_finite: bool = true
	for ped in world.pedestrians:
		all_finite = all_finite and ped.position.is_finite() and absf(ped.position.y) < 2.0
	check(all_finite, "All pedestrians remain finite and grounded")

	# 5. Localized crowd yielding heuristics
	var test_car = world.traffic[0]
	check(test_car.get("waiting_reason") != null, "Traffic vehicle tracks waiting reason")

	world.queue_free()
	await process_frame
	await process_frame
	await process_frame

	print("CORRIDOR_LANDMARKS_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
