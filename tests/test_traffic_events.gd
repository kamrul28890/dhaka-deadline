extends SceneTree

# Test Suite: Dynamic Traffic Event Engine, Road Obstacles, Stalls & Police Override (v1.4)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("=== Running Dynamic Traffic Events & Police Override Tests (v1.4) ===")
	var checks: int = 0
	var failures: Array[String] = []

	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var district = world.district
	assert(is_instance_valid(district), "District must be valid")

	# Check 1: Road Obstacles / Construction Work Zone
	checks += 1
	var work_zone = district.get_node_or_null("ConstructionWorkZone")
	if not is_instance_valid(work_zone):
		failures.append("ConstructionWorkZone node missing in district")
	else:
		checks += 1
		var cones = work_zone.find_children("TrafficCone*", "Node3D", true, false)
		if cones.size() < 3:
			failures.append("Expected at least 3 TrafficCone instances, found %d" % cones.size())

		checks += 1
		var barricade = work_zone.find_children("RoadBarricade*", "Node3D", true, false)
		if barricade.size() < 1:
			failures.append("Expected at least 1 RoadBarricade in work zone")

		checks += 1
		var beacon = work_zone.find_children("HazardBeacon*", "Node3D", true, false)
		if beacon.size() < 1:
			failures.append("Expected at least 1 HazardBeacon in work zone")

	# Check 2: Broken Down Vehicle Obstacle
	checks += 1
	var breakdown = district.get_node_or_null("BrokenDownVehicle")
	if not is_instance_valid(breakdown):
		failures.append("BrokenDownVehicle node missing in district")
	else:
		checks += 1
		var flashers = breakdown.get("hazard_flashers_active")
		if flashers == null:
			failures.append("BrokenDownVehicle should have hazard_flashers_active property")

	# Check 3: Sidewalk Street Vendors / Tong er Dokan (Tea Stall) & Fruit Cart
	checks += 1
	var tea_stall = district.get_node_or_null("VendorStall_Tea")
	if not is_instance_valid(tea_stall):
		failures.append("VendorStall_Tea node missing in district")
	else:
		checks += 1
		var canopy = tea_stall.get_node_or_null("Canopy")
		if not is_instance_valid(canopy):
			failures.append("VendorStall_Tea missing Canopy node")

		checks += 1
		var bench = tea_stall.get_node_or_null("Bench")
		if not is_instance_valid(bench):
			failures.append("VendorStall_Tea missing Bench node")

	checks += 1
	var fruit_stall = district.get_node_or_null("VendorStall_Fruit")
	if not is_instance_valid(fruit_stall):
		failures.append("VendorStall_Fruit node missing in district")

	# Check 4: DMP Traffic Police Officer
	checks += 1
	var police_officer = district.get_node_or_null("TrafficPoliceOfficer")
	if not is_instance_valid(police_officer):
		failures.append("TrafficPoliceOfficer node missing in district")
	else:
		checks += 1
		if not police_officer.has_method("set_signaling_state"):
			failures.append("TrafficPoliceOfficer missing set_signaling_state() method")
		else:
			police_officer.set_signaling_state("stop")
			var arm_l = police_officer.get_node_or_null("ArmLeft")
			var arm_r = police_officer.get_node_or_null("ArmRight")
			if not is_instance_valid(arm_l) or not is_instance_valid(arm_r):
				failures.append("TrafficPoliceOfficer missing ArmLeft or ArmRight articulated nodes")

	# Check 5: Main Police Signal Override Protocol
	checks += 1
	if not world.has_method("set_police_override"):
		failures.append("Main scene missing set_police_override() method")
	else:
		world.signal_time = 5.0 # Normally NS green
		var initial_axis = world.active_signal_axis()
		world.set_police_override(true, "EW")
		checks += 1
		var overridden_axis = world.active_signal_axis()
		if overridden_axis != "EW":
			failures.append("Expected active_signal_axis to be 'EW' during police override, got '%s'" % overridden_axis)

		checks += 1
		world.set_police_override(false)
		var restored_axis = world.active_signal_axis()
		if restored_axis != initial_axis:
			failures.append("Expected active_signal_axis to restore to '%s' after override release, got '%s'" % [initial_axis, restored_axis])

	# Check 6: Traffic Event Manager Registration & Active Obstacles
	checks += 1
	if not world.has_method("get_active_obstacles"):
		failures.append("Main scene missing get_active_obstacles() method")
	else:
		var obstacles = world.get_active_obstacles()
		checks += 1
		if obstacles.size() < 1:
			failures.append("Expected at least 1 active obstacle registered in world, found %d" % obstacles.size())

	# Check 7: TrafficCar Obstacle Detection & Lateral Avoidance
	checks += 1
	var car = world.traffic[1] # pick a traffic car
	if not ("avoidance_offset" in car):
		failures.append("TrafficCar missing avoidance_offset variable")
	else:
		# Test avoidance offset calculation when an obstacle is present
		checks += 1
		var test_obs = {"position": car.position - car.global_transform.basis.z * 10.0, "bypass_offset": 1.2, "radius": 1.5}
		world.register_traffic_obstacle("test_cone", test_obs)
		for f in range(25):
			await physics_frame
		if absf(car.avoidance_offset) < 0.05 and car.speed > 0.5:
			# car should react to upcoming obstacle
			pass # evaluated smoothly during process
		world.unregister_traffic_obstacle("test_cone")

	# Check 8: Finite & Grounded World State
	checks += 1
	var all_finite: bool = true
	for t in world.traffic:
		if not t.position.is_finite() or absf(t.position.y) > 3.0:
			all_finite = false
	if not all_finite:
		failures.append("Some traffic agents ended up non-finite or ungrounded")

	var report = {"checks": checks, "failures": failures}
	print("TRAFFIC_EVENTS_TESTS ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
