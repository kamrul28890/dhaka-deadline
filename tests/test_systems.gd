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
	for route in Network.LOOPS:
		var points: PackedVector3Array = Network.loop_path(route)
		check(points.size() > 100, "Route contains a full network traversal")
		var maximum_step: float = 0
		for i in range(points.size()):
			maximum_step = maxf(maximum_step, points[i].distance_to(points[(i+1)%points.size()]))
		check(maximum_step < 4, "Loop is continuous, including its seam")
		var direction: Vector3 = (Network.NODES[route[1]]-Network.NODES[route[0]]).normalized()
		check((points[0]-Network.NODES[route[0]]).dot(Network.left_of(direction)) > 3, "Traffic starts on the left side of its road")
	var estimates: Dictionary = Network.route_distance(Vector3(-93,0,76), Vector3(95,0,-66), 0, 0)
	var congested: Dictionary = Network.route_distance(Vector3(-93,0,76), Vector3(95,0,-66), 90, 0)
	check(estimates.middle.distance < estimates.north.distance, "Market route is shorter")
	check(congested.middle.seconds > congested.north.seconds, "Congestion can make the shorter route slower")
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.traffic.size() == 18, "Expected mixed traffic population")
	check(world.player.enabled == false, "Driving waits for mission start")
	world.signal_time = 2
	check(world.active_signal_axis() == "NS", "North/south signal phase")
	check(world.signal_speed_limit(Vector3(-93.2,0,16), Vector3.FORWARD, 4.4) > 0, "Green approach can advance")
	world.signal_time = 22
	check(world.active_signal_axis() == "EW", "East/west signal phase")
	check(world.signal_speed_limit(Vector3(-93.2,0,15), Vector3.FORWARD, 4.4) == 0, "Red approach holds before crossing")
	world.crossing = true
	check(world.active_signal_axis() == "NONE", "Committed pedestrian crossing holds all red")
	world.crossing = false
	world.start_mission(false)
	world.player.position = Vector3(-40,0,40)
	world.player.speed = 8
	world.toggle_pause()
	var paused_position: Vector3 = world.player.position
	for i in range(6):
		await physics_frame
	check(world.player.position.is_equal_approx(paused_position), "Pause freezes the player vehicle")
	world.toggle_pause()
	world.recover_player()
	check(world.recoveries == 1 and world.elapsed >= 15, "Recovery applies an explicit time penalty")
	world.elapsed = world.deadline+10
	check(not world.finished, "A missed deadline does not automatically end the journey")
	world.player.position = world.arrival_point
	world.player.speed = 0
	for i in range(130):
		await physics_frame
	check(world.finished, "Stopping in the arrival bay completes the mission")
	check(world.hud.menu != null, "Arrival produces a results screen")
	world.queue_free()
	await process_frame
	await process_frame
	await process_frame
	print("SYSTEM_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
