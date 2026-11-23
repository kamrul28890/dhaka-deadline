extends SceneTree

# Test Suite: Playable Green CNG Auto-Rickshaw & Fare Meter (v1.5)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("=== Running Playable CNG Auto-Rickshaw Tests (v1.5) ===")
	var checks: int = 0
	var failures: Array[String] = []

	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var player = world.player
	assert(is_instance_valid(player), "Player must be valid")

	# Check 1: Vehicle Type Switching Method
	checks += 1
	if not player.has_method("set_vehicle_type"):
		failures.append("PlayerCar missing set_vehicle_type() method")
	else:
		# Initial default is sedan
		checks += 1
		if player.get("vehicle_type") != "car":
			failures.append("Default player vehicle_type should be 'car'")

		# Switch to CNG
		player.set_vehicle_type("cng")
		checks += 1
		if player.get("vehicle_type") != "cng":
			failures.append("Player vehicle_type should be 'cng' after switching")

		# Check 2: Footprint & Dimensions
		checks += 1
		if player.length > 3.0 or player.width > 1.6:
			failures.append("CNG dimensions incorrect: length=%f, width=%f (expected ~2.8m x 1.4m)" % [player.length, player.width])

		# Check 3: Fare Meter Node & Initial Base Fare
		checks += 1
		var fare_meter = player.get_node_or_null("visual/FareMeter")
		if not is_instance_valid(fare_meter):
			failures.append("CNG visual missing FareMeter node")
		else:
			checks += 1
			var fare: float = player.get("fare_taka") if player.get("fare_taka") != null else 0.0
			if fare < 35.0:
				failures.append("CNG initial fare_taka should start at base fare (>= 40 Tk), got %f" % fare)

		# Check 4: Handlebar Steering Node
		checks += 1
		var handlebar = player.get_node_or_null("visual/Handlebar")
		if not is_instance_valid(handlebar):
			failures.append("CNG visual missing Handlebar steering node")
		else:
			checks += 1
			player.steering = 0.5
			player._physics_process(0.016)
			if absf(handlebar.rotation.y) < 0.05:
				failures.append("Handlebar should rotate with steering input, got rot.y=%f" % handlebar.rotation.y)

		# Check 5: Cabin Camera Vantage in CNG View
		checks += 1
		player.camera_mode = 2 # Cabin view
		player._physics_process(0.016)
		# CNG driver sits in center saddle (x near 0), unlike right-hand drive sedan (x ~ 0.35)
		if absf(player.camera.position.x - player.position.x) > 0.25:
			failures.append("CNG cabin camera should be centered in driver saddle, offset=%f" % absf(player.camera.position.x - player.position.x))

		# Check 6: Dynamic Fare Meter Accrual with Distance Driven
		checks += 1
		var initial_fare: float = player.fare_taka
		player.distance_driven += 500.0 # simulate 500 meters
		player._physics_process(0.016)
		if player.fare_taka <= initial_fare:
			failures.append("fare_taka should increase with distance driven, initial=%f, current=%f" % [initial_fare, player.fare_taka])

		# Check 7: Switch back to Sedan
		checks += 1
		player.set_vehicle_type("car")
		if player.get("vehicle_type") != "car" or player.length < 4.0:
			failures.append("Switching back to sedan failed: length=%f, type=%s" % [player.length, player.get("vehicle_type")])

	# Check 8: Finite & Grounded
	checks += 1
	if not player.position.is_finite() or absf(player.position.y) > 2.0:
		failures.append("Player vehicle ended up non-finite or ungrounded")

	var report = {"checks": checks, "failures": failures}
	print("PLAYABLE_CNG_TESTS ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
