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

func place_agent(agent: Node3D, point: Vector3, direction: Vector3) -> void:
	var nearest: float = INF
	for i in range(agent.path.size()):
		var d: float = point.distance_to(agent.path[i])
		if d < nearest:
			nearest = d
			agent.waypoint = i
	agent.position = point + Vector3.UP * 0.1
	agent.rotation.y = atan2(-direction.x, -direction.z)
	agent.speed = 0
	agent.last_position = agent.position

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	var bus: Node3D = null
	var cng: Node3D = null
	var car: Node3D = null

	for agent in world.traffic:
		if agent.kind == "bus" and bus == null:
			bus = agent
		elif agent.kind == "cng" and cng == null:
			cng = agent
		elif agent.kind == "car" and car == null:
			car = agent

	check(bus != null, "Traffic population includes city bus")
	check(cng != null, "Traffic population includes CNG three-wheeler")
	check(car != null, "Traffic population includes private car")

	# 1. Parameter profiles per vehicle class
	var car_accel = car.get("accel_rate")
	var car_gap = car.get("min_gap")
	check(cng.get("accel_rate") != null and car_accel != null and cng.accel_rate > car_accel, "CNG has higher launch acceleration rate than car")
	check(bus.get("accel_rate") != null and car_accel != null and bus.accel_rate < car_accel, "Bus has lower heavy-vehicle acceleration rate than car")
	check(cng.get("min_gap") != null and car_gap != null and cng.min_gap < car_gap, "CNG maintains tighter headway cushion than car")
	check(bus.get("min_gap") != null and car_gap != null and bus.min_gap > car_gap, "Bus maintains larger safety following buffer than car")
	check(cng.get("lateral_bias") != null and cng.lateral_bias > 0.2, "CNG has curb-hugging lateral bias")
	check(car.get("lateral_bias") != null and absf(car.lateral_bias) < 0.05, "Car remains centered in lane")

	# 2. Simulated physical launch from rest
	world.set_physics_process(false)
	for agent in world.traffic:
		agent.set_physics_process(false)
	world.player.set_physics_process(false)
	world.paused_sim = false

	# Isolate agents onto open straight track
	place_agent(bus, Vector3(-93.2, 0.1, 80), Vector3.FORWARD)
	place_agent(cng, Vector3(-93.2, 0.1, 60), Vector3.FORWARD)
	place_agent(car, Vector3(-93.2, 0.1, 40), Vector3.FORWARD)

	# Advance 30 frames of acceleration from rest
	for frame in range(30):
		bus._physics_process(1.0/60)
		car._physics_process(1.0/60)
		cng._physics_process(1.0/60)

	check(cng.speed > car.speed, "CNG launches snappier than sedan after 30 frames from rest")
	check(car.speed > bus.speed, "Sedan accelerates faster than heavy diesel bus from rest")

	# 3. Bus stop pull-in lateral offset
	place_agent(bus, Vector3(-93.2, 0.1, 38), Vector3.FORWARD)
	bus.speed = 5.0
	bus.bus_stop_done = false
	bus.dwell = 0
	for frame in range(60):
		bus._physics_process(1.0/60)

	check(bus.dwell > 0 or bus.bus_stop_done, "Bus triggers passenger boarding dwell at bus stop")
	check(bus.position.x < -93.5, "Bus pulls laterally toward left curb into boarding bay (x < -93.5)")

	# 4. Bus re-entry merging check with approaching traffic
	var follower = car
	place_agent(follower, Vector3(-93.2, 0.1, 37), Vector3.FORWARD)
	follower.speed = 5.0
	world.road_users = [bus, follower]

	# Dwell has ended; bus attempts to merge back into travel lane
	bus.dwell = 0.0
	bus._physics_process(1.0/60)
	check(bus.waiting_reason == "merging" or bus.speed < 1.0, "Bus yields to closely approaching traffic before merging back into lane")

	world.queue_free()
	for i in range(3):
		await process_frame

	print("MIXED_TRAFFIC_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
