extends SceneTree

const Missions = preload("res://scripts/mission_manager.gd")
const District = preload("res://scripts/district.gd")
const HUD = preload("res://scripts/hud.gd")
const PlayerCar = preload("res://scripts/player_car.gd")
const Network = preload("res://scripts/road_network.gd")

func _init() -> void:
	print("Running test_missions.gd...")
	var tests_passed: int = 0

	# 1. Mission Registry Tests
	var all_missions: Array[Dictionary] = Missions.get_all_missions()
	assert(all_missions.size() >= 3, "Expected at least 3 registered missions")
	tests_passed += 1

	var required_keys: Array[String] = [
		"id", "index", "tag", "title_en", "title_bn", "objective",
		"briefing", "destination_name", "destination_marker",
		"arrival_point", "clock_start_minutes", "deadline_seconds",
		"time_of_day"
	]
	for m in all_missions:
		for k in required_keys:
			assert(m.has(k), "Mission %s missing key: %s" % [m.get("id", "unknown"), k])
		assert(m.deadline_seconds >= 60.0, "Deadline should be at least 60s")
		assert(m.clock_start_minutes > 0, "Clock start minutes should be positive")
		assert(m.title_en.length() > 0, "English title empty")
		assert(m.title_bn.length() > 0, "Bengali title empty")
	tests_passed += 1

	# 2. Fallback handling
	var default_m: Dictionary = Missions.get_mission("invalid_id")
	assert(default_m.id == "interview", "Invalid mission ID must fall back to interview")
	tests_passed += 1

	# 3. Score Calculation & Grading - Grade S (Master Driver)
	var s_score: Dictionary = Missions.calculate_score("interview", 100.0, 0, 0, 0, 0.0, false)
	assert(s_score.passed == true, "Score should pass")
	assert(s_score.grade == "S", "Expected Grade S, got %s" % s_score.grade)
	assert(s_score.grade_title_bn == "ওস্তাদ চালক", "Expected ওস্তাদ চালক")
	assert(s_score.safety == 100, "Safety should be 100")
	assert(s_score.punctuality == 100, "Punctuality should be 100")
	assert(s_score.total_score >= 95, "Total score should be >= 95")
	tests_passed += 1

	# 4. Grade A (Professional)
	var a_score: Dictionary = Missions.calculate_score("interview", 125.0, 0, 0, 0, 0.0, false)
	assert(a_score.passed == true, "Grade A should pass")
	assert(a_score.grade == "A" or a_score.grade == "B", "Expected Grade A/B, got %s" % a_score.grade)
	assert(a_score.punctuality < 100, "Punctuality should reflect slight delay")
	tests_passed += 1

	# 5. Grade B (Careful Driver with 1 collision)
	var b_score: Dictionary = Missions.calculate_score("interview", 110.0, 1, 0, 0, 0.0, false)
	assert(b_score.passed == true, "Grade B should pass")
	assert(b_score.safety == 78, "1 collision penalty should yield safety 78")
	tests_passed += 1

	# 6. Grade C (Rushed Driver with significant delay)
	var c_score: Dictionary = Missions.calculate_score("interview", 165.0, 0, 1, 0, 5.0, false)
	assert(c_score.passed == true, "Grade C should pass")
	assert(c_score.grade in ["B", "C"], "Expected Grade B or C, got %s" % c_score.grade)
	tests_passed += 1

	# 7. Grade D (Multiple infractions)
	var d_score: Dictionary = Missions.calculate_score("interview", 180.0, 2, 2, 1, 15.0, false)
	assert(d_score.grade == "D", "Expected Grade D for heavy penalties, got %s" % d_score.grade)
	tests_passed += 1

	# 8. Grade F (Failed: Pedestrian collision)
	var f_score: Dictionary = Missions.calculate_score("interview", 50.0, 1, 0, 0, 0.0, true)
	assert(f_score.passed == false, "Failed mission should mark passed false")
	assert(f_score.grade == "F", "Pedestrian hit must yield Grade F")
	assert(f_score.total_score == 0, "Total score must be 0 on fail")
	assert("collision" in f_score.message, "Failure message must mention collision")
	tests_passed += 1

	# 9. Narrative Cues
	var cue_events: Array[String] = ["start", "signal_wait", "junction_clear", "reroute_advice", "hurry_up", "near_goal"]
	for ev in cue_events:
		var cue: Dictionary = Missions.narrative_cue("interview", ev)
		assert(cue.has("bn") and cue.bn.length() > 0, "Missing Bengali cue for %s" % ev)
		assert(cue.has("en") and cue.en.length() > 0, "Missing English cue for %s" % ev)
	tests_passed += 1

	# 10. Radio chime asset test
	var chime_stream = load("res://assets/audio/radio_chime.wav")
	assert(chime_stream != null, "radio_chime.wav failed to load")
	assert(chime_stream is AudioStreamWAV, "radio_chime should be AudioStreamWAV")
	assert(chime_stream.data.size() > 0, "radio_chime data is empty")
	tests_passed += 1

	# 11. Delivery & Evening Mission specific parameters
	var del_m: Dictionary = Missions.get_mission("delivery")
	assert(del_m.deadline_seconds == 85.0, "Delivery deadline should be 85.0s")
	assert(del_m.clock_start_minutes == 856, "Delivery clock start 02:16 PM")

	var eve_m: Dictionary = Missions.get_mission("evening")
	assert(eve_m.deadline_seconds == 140.0, "Evening deadline should be 140.0s")
	assert(eve_m.clock_start_minutes == 1127, "Evening clock start 06:47 PM")
	tests_passed += 1

	# 12. District Atmosphere & Destination Marker Integration
	var dist = District.new()
	dist.build()
	assert(dist.env != null, "District environment should be initialized")
	assert(dist.sun != null, "District sun should be initialized")
	dist.set_atmosphere("midday")
	assert(is_equal_approx(dist.sun.light_energy, 1.35), "Midday light energy should be 1.35")
	dist.set_atmosphere("evening")
	assert(is_equal_approx(dist.sun.light_energy, 0.70), "Evening light energy should be 0.70")
	assert(dist.sun.light_color == Color("ff9955"), "Evening light color should be warm dusk")
	dist.set_atmosphere("morning")
	assert(is_equal_approx(dist.sun.light_energy, 1.1), "Morning light energy should be 1.1")
	tests_passed += 1

	dist.update_destination("COURIER\n↓", "COURIER\nSTOP")
	assert(dist.dest_marker.text == "COURIER\n↓", "Destination marker should update")
	assert(dist.dest_painted.text == "COURIER\nSTOP", "Destination ground text should update")
	dist.free()
	tests_passed += 1

	# 13. Player Headlights
	var car = PlayerCar.new()
	car.set_headlights(true)
	for lamp in car.lamps:
		assert(lamp.visible == true, "Lamps should be visible when enabled")
	car.set_headlights(false)
	for lamp in car.lamps:
		assert(lamp.visible == false, "Lamps should not be visible when disabled")
	car.free()
	tests_passed += 1

	# 14. World, HUD & Mission Switching Integration
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame

	assert(world.active_mission_id == "interview", "Initial mission should be interview")
	assert(world.deadline == 120.0, "Initial deadline should be 120.0s")

	# Mission Switching
	world.set_active_mission("delivery")
	assert(world.active_mission_id == "delivery", "Active mission should switch to delivery")
	assert(world.deadline == 85.0, "Delivery deadline should be 85.0s")
	assert(is_equal_approx(world.district.sun.light_energy, 1.35), "Midday light energy should be 1.35")
	tests_passed += 1

	world.set_active_mission("evening")
	assert(world.active_mission_id == "evening", "Active mission should switch to evening")
	assert(world.deadline == 140.0, "Evening deadline should be 140.0s")
	assert(is_equal_approx(world.district.sun.light_energy, 0.70), "Evening light energy should be 0.70")
	assert(world.player.lamps[0].visible == true, "Evening mission should switch on headlights")
	tests_passed += 1

	world.set_active_mission("interview")
	assert(world.player.lamps[0].visible == false, "Morning mission should turn off headlights")
	tests_passed += 1

	# Radio Dispatch
	assert(is_instance_valid(world.hud.dispatch_panel), "Dispatch panel should be created")
	world.hud.show_radio_dispatch("যাত্রা শুরু", "Trip start")
	assert(world.hud.dispatch_panel.visible == true, "Dispatch panel visible after cue")
	assert(world.hud.dispatch_bn.text == "যাত্রা শুরু", "Bengali dispatch text matches")
	assert(world.hud.dispatch_en.text == "Trip start", "English dispatch text matches")
	tests_passed += 1

	# Results screen with Grade S
	var test_res: Dictionary = Missions.calculate_score("interview", 100.0, 0, 0, 0, 0.0, false)
	world.hud.show_results(test_res)
	assert(is_instance_valid(world.hud.menu), "Results menu should be instantiated")
	tests_passed += 1

	world.free()

	print("ALL %d MISSION CHECKS PASSED SUCCESSFULLY." % tests_passed)
	print("MISSIONS_TESTS ", JSON.stringify({"checks": tests_passed, "failures": []}))
	quit(0)
