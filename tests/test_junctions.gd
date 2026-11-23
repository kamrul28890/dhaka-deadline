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

func place(agent: Node3D, route: Array, point: Vector3, direction: Vector3) -> void:
	agent.path = Network.loop_path(route)
	agent.movements = Network.loop_movements(route)
	agent.junction = {}
	agent.junction_granted = false
	agent.junction_arrival = INF
	var nearest: float = INF
	for i in range(agent.path.size()):
		var distance: float = point.distance_to(agent.path[i])
		if distance < nearest:
			nearest = distance
			agent.waypoint = i
	agent.position = point + Vector3.UP * 0.1
	agent.rotation.y = atan2(-direction.x, -direction.z)
	agent.speed = 0
	agent.stopped_for = 0
	agent.last_position = agent.position

func advance(frames: int) -> void:
	for i in range(frames):
		await physics_frame

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.hud.set_process(false)
	for other in world.traffic:
		other.set_physics_process(false)
		other.position = Vector3(300 + other.get_index()*12, 0, 300)
	world.player.set_physics_process(false)
	world.pedestrians = []
	var agent = world.traffic[1]
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 30), Vector3.FORWARD)
	world.player.position = Vector3(-93.2, 0.1, -19)
	world.player.speed = 0
	world.road_users = [agent, world.player]
	world.paused_sim = false
	world.signal_time = 2
	agent.set_physics_process(true)
	await advance(720)
	check(agent.position.z >= 15.5, "A green light does not allow entering a junction with a blocked exit")
	world.player.position = Vector3(-145, 0.1, 60)
	await advance(600)
	check(agent.position.z < -25, "Traffic resumes when the junction exit becomes clear")
	agent.set_physics_process(false)
	var oncoming = world.traffic[3]
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 15.7), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, -22), Vector3.BACK)
	world.road_users = [agent, oncoming, world.player]
	agent.set_physics_process(true)
	oncoming.set_physics_process(true)
	await advance(90)
	check(agent.position.z >= 15.5, "A right turn waits for opposing through traffic on the same green")
	check(oncoming.position.z > -21, "Turning priority lets the opposing through vehicle advance")
	await advance(960)
	check(agent.position.x > -60 and oncoming.position.z > 25, "Both conflicting movements clear without a reciprocal yielding deadlock")
	agent.set_physics_process(false)
	oncoming.set_physics_process(false)
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 20), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, -20), Vector3.BACK)
	check(world.junction_speed_limit(agent) > 8 and world.junction_speed_limit(oncoming) > 8, "Opposing straight movements can enter together")
	world.signal_time = 22
	check(world.junction_speed_limit(agent) < 4, "A reservation before the stop line does not authorize entry after the signal changes")
	world.signal_time = 2
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 20), Vector3.FORWARD)
	world.junction_speed_limit(agent)
	world.player.position = Vector3(-93.2, 0.1, -19)
	check(world.junction_speed_limit(agent) < 4, "Exit space is rechecked until the reserved vehicle crosses its stop line")
	world.player.position = Vector3(-145, 0.1, 60)
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 10), Vector3.FORWARD)
	world.signal_time = 22
	check(world.junction_speed_limit(agent) > 8, "A vehicle already inside keeps clearing after its approach turns red")
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 15.7), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, 50), Vector3.BACK)
	world.signal_time = 2
	world.player.position = Vector3(-88, 0.1, 0)
	check(world.junction_speed_limit(agent) < 0.1, "A player occupying the turning corridor blocks AI entry")
	world.player.position = Vector3(-145, 0.1, 60)
	var follower = world.traffic[4]
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 15.7), Vector3.FORWARD)
	place(follower, Network.LOOPS[0], Vector3(-93.2, 0, 22.6), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, -20), Vector3.BACK)
	world.road_users = [agent, follower, oncoming, world.player]
	check(world.junction_speed_limit(follower) < 8 and not follower.junction_granted, "A queued follower cannot reserve a junction ahead of its turning leader")
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, 50), Vector3.BACK)
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 20), Vector3.FORWARD)
	world.player.position = Vector3(-90.3, 0.1, -19)
	world.player.rotation.y = -PI/2
	check(world.junction_speed_limit(agent) < 4, "A sideways player's footprint also blocks exit capacity")
	world.player.position = Vector3(-145, 0.1, 60)
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 20), Vector3.FORWARD)
	world.junction_speed_limit(agent)
	world.player.position = Vector3(-88, 0.1, 0)
	check(world.junction_speed_limit(agent) < 4, "A pre-line reservation is rechecked when the player enters its turning corridor")
	world.player.position = Vector3(-145, 0.1, 60)
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 15.7), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, -20), Vector3.BACK)
	agent.stopped_for = 45
	check(world.junction_speed_limit(oncoming) < 4, "Uncommitted opposing traffic leaves a gap for a turn waiting longer than one cycle")
	check(world.junction_speed_limit(agent) > 8, "A long-waiting turn receives that gap once committed traffic is clear")
	place(agent, Network.LOOPS[0], Vector3(-93.2, 0, 15.7), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[0], Vector3(-93.2, 0, 23), Vector3.FORWARD)
	world.road_users = [agent, oncoming, world.player]
	world.junction_speed_limit(agent)
	check(world.junction_speed_limit(oncoming) > 8, "Following vehicles on the same path use headway control instead of exclusive crossing reservations")
	place(agent, Network.LOOPS[2], Vector3(-93.2, 0, 35), Vector3.FORWARD)
	place(oncoming, Network.LOOPS[1], Vector3(-86.8, 0, -20), Vector3.BACK)
	agent.stopped_for = 45
	check(world.junction_speed_limit(oncoming) > 8, "An aged turn far back in a queue cannot hold the opposing approach")
	world.queue_free()
	await process_frame
	await process_frame
	print("JUNCTION_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
