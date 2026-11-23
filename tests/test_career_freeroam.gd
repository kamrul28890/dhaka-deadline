extends SceneTree

# Test Suite: Driver Career Profile, Free Roam Mode & Menu Layout Bounds (v1.8)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("=== Running Driver Career, Free Roam & Menu Bounds Tests (v1.8) ===")
	var checks: int = 0
	var failures: Array[String] = []

	var Career = preload("res://scripts/career_manager.gd")

	# Check 1: Default Profile structure
	checks += 1
	Career.reset_profile()
	var prof = Career.get_profile()
	if not ("total_distance_m" in prof) or not ("total_trips" in prof) or not ("total_fares_taka" in prof):
		failures.append("Career profile missing core telemetry fields")

	# Check 2: Trip Recording & Stats Accumulation
	checks += 1
	Career.record_trip("interview", "cng", 1500.0, 92, "S", 75.0)
	prof = Career.get_profile()
	if prof.total_trips != 1 or prof.total_distance_m < 1400.0 or prof.total_fares_taka < 70.0:
		failures.append("Career record_trip did not accumulate statistics correctly: trips=%d, dist=%f, fares=%f" % [prof.total_trips, prof.total_distance_m, prof.total_fares_taka])

	checks += 1
	if prof.best_grade != "S":
		failures.append("Career record_trip should update best_grade to 'S', got %s" % prof.best_grade)

	# Check 3: Driver Title Progression
	checks += 1
	var title = Career.get_driver_title(prof)
	if not ("bn" in title) or not ("en" in title) or not ("tier" in title):
		failures.append("Driver title missing bilingual fields")

	# Check 4: Corrupt file recovery
	checks += 1
	Career.save_profile({"driver_name": "Test"}) # Partial dict
	var loaded = Career.load_profile()
	if not ("total_distance_m" in loaded) or loaded.driver_name != "Test":
		failures.append("Corrupt/partial profile recovery failed to merge default fields")
	Career.reset_profile()

	# Check 5: Instantiate Main World and verify Free Roam & Menu Layout
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	# Check 6: Menu layout bounds (Must fit within 900p viewport without covering screen)
	checks += 1
	world.hud.show_intro()
	await process_frame
	var menu = world.hud.menu
	if not is_instance_valid(menu):
		failures.append("HUD intro menu failed to instantiate")
	else:
		checks += 1
		# Menu must not exceed 760px in height or extend off the bottom of 900p screen
		var menu_bottom = menu.position.y + menu.size.y
		if menu_bottom > 890.0:
			failures.append("Menu extends off screen bottom! bottom=%f > 890.0" % menu_bottom)

	# Check 7: Free Roam City Tour mode activation
	checks += 1
	world.start_mission(true) # Free roam
	await process_frame
	if not world.free_drive or not world.started:
		failures.append("Free roam mode failed to initialize (free_drive=%s, started=%s)" % [str(world.free_drive), str(world.started)])

	# Check 8: Career Profile and Credits screens on HUD
	checks += 1
	world.hud.show_career_profile()
	await process_frame
	if not is_instance_valid(world.hud.menu):
		failures.append("HUD show_career_profile failed to open screen")

	checks += 1
	world.hud.show_credits()
	await process_frame
	if not is_instance_valid(world.hud.menu):
		failures.append("HUD show_credits failed to open screen")

	# Check 9: Trip Completion auto-records to career
	checks += 1
	var initial_trips = Career.get_profile().total_trips
	world.elapsed = 45.0
	world.player.distance_driven = 800.0
	world.player.collision_count = 0
	world.red_lights = 0
	world.recoveries = 0
	world.free_drive = false
	world._finish_mission()
	await process_frame
	var updated_prof = Career.get_profile()
	if updated_prof.total_trips <= initial_trips:
		failures.append("Mission finish failed to automatically record trip in career profile")

	# Check 10: Finite & Grounded Actor Positions
	checks += 1
	if not world.player.position.is_finite() or absf(world.player.position.y) > 2.0:
		failures.append("Player vehicle ended up non-finite or ungrounded")

	var report = {"checks": checks, "failures": failures}
	print("CAREER_FREEROAM_TESTS ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
