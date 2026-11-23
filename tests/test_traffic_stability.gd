extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.start_mission(true)
	world.player.position = Vector3(-145, 0.1, 60)
	var longest_wait: float = 0
	var finite: bool = true
	var vehicle_contacts: int = 0
	for frame in range(36000):
		await physics_frame
		for agent in world.traffic:
			longest_wait = maxf(longest_wait, agent.stopped_for)
			finite = finite and agent.position.is_finite() and absf(agent.position.y) < 2
			for i in range(agent.get_slide_collision_count()):
				if agent.get_slide_collision(i).get_collider() in world.traffic:
					vehicle_contacts += 1
	var minimum_travel: float = INF
	var states: Array = []
	for agent in world.traffic:
		minimum_travel = minf(minimum_travel, agent.travelled)
		states.append({"kind": agent.kind, "position": str(agent.position), "wait": agent.stopped_for, "reason": agent.waiting_reason, "travelled": agent.travelled})
	var passed: bool = finite and longest_wait < 90 and minimum_travel > 300 and vehicle_contacts == 0 and world.pedestrian_crossings_completed >= 5
	var report: Dictionary = {"passed": passed, "simulated_seconds": world.sim_time, "longest_wait": longest_wait,
		"minimum_vehicle_travel": minimum_travel, "vehicle_contact_frames": vehicle_contacts,
		"finite_grounded": finite, "completed_crossings": world.pedestrian_crossings_completed, "agents": states}
	var file = FileAccess.open(world._artifact_path("traffic-stability.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("TRAFFIC_STABILITY ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if passed else 1)
