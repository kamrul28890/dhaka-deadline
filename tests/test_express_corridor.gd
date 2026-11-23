extends SceneTree

const Corridor = preload("res://scripts/corridor_expressway.gd")

func _init() -> void:
	print("--- Running Test Suite: Shahbag to Uttara 20.5km Express Corridor ---")
	var checks_passed: int = 0

	# 1. Instantiate Corridor
	var corridor = Corridor.new()
	assert(is_instance_valid(corridor), "Corridor failed to instantiate")
	root.add_child(corridor)
	checks_passed += 1
	print("  [PASS] Corridor instantiated successfully")

	# 2. Build Corridor
	corridor.build_corridor()
	checks_passed += 1
	print("  [PASS] build_corridor() executed without errors")

	# 3. Check All 7 Sectors
	assert(Corridor.SECTORS.size() == 7, "Corridor must define exactly 7 landmark sectors")
	checks_passed += 1
	print("  [PASS] Exactly 7 landmark sectors defined")

	var sector_ids = []
	for sec in Corridor.SECTORS:
		sector_ids.append(sec.id)
	assert("shahbag" in sector_ids, "Missing shahbag sector")
	assert("karwan_bazar" in sector_ids, "Missing karwan_bazar sector")
	assert("farmgate" in sector_ids, "Missing farmgate sector")
	assert("mohakhali" in sector_ids, "Missing mohakhali sector")
	assert("banani" in sector_ids, "Missing banani sector")
	assert("kuril" in sector_ids, "Missing kuril sector")
	assert("uttara" in sector_ids, "Missing uttara sector")
	checks_passed += 1
	print("  [PASS] All 7 sector IDs present in sequence")

	# 4. Check Mohakhali Flyover Elevation
	var mohakhali_elev = corridor.get_elevation_at_z(-1200.0)
	assert(mohakhali_elev == 10.5, "Mohakhali flyover elevation must be 10.5m")
	checks_passed += 1
	print("  [PASS] Mohakhali elevated flyover deck elevation verified at 10.5m")

	# 5. Check Shahbag and Uttara Elevations
	var shahbag_elev = corridor.get_elevation_at_z(100.0)
	assert(shahbag_elev == 7.5, "Shahbag deck elevation should be 7.5m")
	var uttara_elev = corridor.get_elevation_at_z(-2400.0)
	assert(uttara_elev == 7.5, "Uttara terminal elevation should be 7.5m")
	checks_passed += 1
	print("  [PASS] Boundary sector elevations verified")

	# 6. Check Progress and Kilometres Travelled
	var start_km = corridor.get_kilometres_travelled(Corridor.TRACK_START_Z)
	assert(is_equal_approx(start_km, 0.0), "Start km should be 0.0")
	var end_km = corridor.get_kilometres_travelled(Corridor.TRACK_END_Z)
	assert(is_equal_approx(end_km, 20.5), "End km should be 20.5km")
	var mid_km = corridor.get_kilometres_travelled(-1210.0)
	assert(mid_km > 8.0 and mid_km < 12.0, "Mid-corridor km should be ~10km")
	checks_passed += 1
	print("  [PASS] 20.5 km scale distance calculation verified (%.1fkm -> %.1fkm)" % [start_km, end_km])

	# 7. Check Physical Deck and Barriers Collision
	var deck = corridor.get_node_or_null("Deck_shahbag")
	assert(is_instance_valid(deck), "Deck_shahbag mesh missing")
	var has_deck_body: bool = false
	for c in deck.get_children():
		if c is StaticBody3D:
			has_deck_body = true
			break
	assert(has_deck_body, "Deck must have StaticBody3D collision")
	checks_passed += 1
	print("  [PASS] Roadway deck physical collision verified")

	var barrier_l = corridor.get_node_or_null("Barrier_L_mohakhali")
	assert(is_instance_valid(barrier_l), "Barrier_L_mohakhali missing")
	var has_barrier_body: bool = false
	for c in barrier_l.get_children():
		if c is StaticBody3D:
			has_barrier_body = true
			break
	assert(has_barrier_body, "Barrier must have StaticBody3D collision")
	checks_passed += 1
	print("  [PASS] New Jersey concrete crash barriers physical collision verified")

	# 8. Check Overhead Gantries and Signboards
	assert(corridor.gantry_nodes.size() >= 6, "Expected at least 6 overhead gantries")
	checks_passed += 1
	print("  [PASS] %d overhead green highway sign gantries verified" % corridor.gantry_nodes.size())

	# 9. Check Landmark Structures
	var term3 = corridor.get_node_or_null("Airport_Terminal_3")
	assert(is_instance_valid(term3), "Airport_Terminal_3 landmark missing")
	var airliner = corridor.get_node_or_null("ApproachingAirliner")
	assert(is_instance_valid(airliner), "ApproachingAirliner visual missing")
	checks_passed += 1
	print("  [PASS] Iconic landmarks (Terminal 3, Airliner approach) verified")

	corridor.queue_free()
	print("ALL %d CHECKS PASSED: Shahbag to Uttara 20.5km Express Corridor!" % checks_passed)
	quit(0)
