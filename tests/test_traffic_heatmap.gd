extends SceneTree

# Test Suite: Real-time Traffic Congestion Heatmap & Dynamic Dispatch Radio (v1.6)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("=== Running Traffic Congestion Heatmap & Radio Tests (v1.6) ===")
	var checks: int = 0
	var failures: Array[String] = []

	var Network = preload("res://scripts/road_network.gd")
	var net_inst = Network.new()

	# Check 1: link_congestion method exists on DhakaRoadNetwork
	checks += 1
	if not net_inst.has_method("link_congestion"):
		failures.append("DhakaRoadNetwork missing link_congestion() method")
	else:
		# Check 2: Free link returns green status
		checks += 1
		var free_cong: Dictionary = Network.link_congestion("W", "E", [], {})
		if free_cong.get("level") != "green":
			failures.append("Empty road link should return level 'green', got %s" % str(free_cong.get("level")))
		checks += 1
		if not ("color" in free_cong) or free_cong.color != Color("2fe695"):
			failures.append("Empty road link color should be Color('2fe695'), got %s" % str(free_cong.get("color")))

		# Check 3: Simulated moderate queue (2 cars) returns amber
		checks += 1
		var dummy_traffic_amber: Array = []
		for i in range(2):
			var dummy = Node3D.new()
			dummy.position = Vector3(0.0 + i * 4.0, 0, -3.2)
			dummy.rotation.y = -PI / 2.0 # Facing +X towards E
			dummy.set("speed", 0.0)
			dummy.set("stopped", true)
			dummy_traffic_amber.append(dummy)
		var amber_cong: Dictionary = Network.link_congestion("W", "E", dummy_traffic_amber, {})
		if amber_cong.get("level") != "amber":
			failures.append("Link with 2 queued vehicles should return level 'amber', got %s" % str(amber_cong.get("level")))
		checks += 1
		if amber_cong.get("color") != Color("f59e0b"):
			failures.append("Amber congestion color should be Color('f59e0b'), got %s" % str(amber_cong.get("color")))

		# Check 4: Simulated heavy queue (5 cars) returns red
		checks += 1
		var dummy_traffic_red: Array = []
		for i in range(5):
			var dummy = Node3D.new()
			dummy.position = Vector3(-40.0 + i * 5.0, 0, -3.2)
			dummy.rotation.y = -PI / 2.0 # Facing +X towards E
			dummy.set("speed", 0.0)
			dummy.set("stopped", true)
			dummy_traffic_red.append(dummy)
		var red_cong: Dictionary = Network.link_congestion("W", "E", dummy_traffic_red, {})
		if red_cong.get("level") != "red":
			failures.append("Link with 5 queued vehicles should return level 'red', got %s" % str(red_cong.get("level")))
		checks += 1
		if red_cong.get("color") != Color("ef4444"):
			failures.append("Red congestion color should be Color('ef4444'), got %s" % str(red_cong.get("color")))

		# Clean up dummies
		for d in dummy_traffic_amber + dummy_traffic_red:
			d.free()

	# Check 5: all_links_congestion returns all network corridors
	checks += 1
	if not net_inst.has_method("all_links_congestion"):
		failures.append("DhakaRoadNetwork missing all_links_congestion() method")
	else:
		var all_cong: Dictionary = Network.all_links_congestion([], {})
		checks += 1
		if all_cong.size() < Network.EDGES.size():
			failures.append("all_links_congestion should have entries for all edges, got %d" % all_cong.size())

	# Check 6: Instantiate Main World and verify Heatmap HUD & Dispatch Integration
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	checks += 1
	if not ("congestion_radio_cooldown" in world):
		failures.append("Main world missing congestion_radio_cooldown property")

	checks += 1
	if not world.has_method("_check_congestion_radio_alerts"):
		failures.append("Main world missing _check_congestion_radio_alerts() method")

	# Check 7: Trigger congestion radio alert
	checks += 1
	world.started = true
	world.paused_sim = false
	world.free_drive = false
	world.congestion_radio_cooldown = 0.0
	# Artificially trigger alert
	world._trigger_congestion_alert("north", 5)
	if not is_instance_valid(world.hud.dispatch_panel) or not world.hud.dispatch_panel.visible:
		failures.append("Dispatch panel should be visible after triggering congestion alert")
	checks += 1
	if world.congestion_radio_cooldown <= 0.0:
		failures.append("congestion_radio_cooldown should be set to prevent spam after alert")

	# Check 8: Finite & Grounded Actor Positions
	checks += 1
	if not world.player.position.is_finite() or absf(world.player.position.y) > 2.0:
		failures.append("Player vehicle ended up non-finite or ungrounded")

	var report = {"checks": checks, "failures": failures}
	print("TRAFFIC_HEATMAP_TESTS ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
