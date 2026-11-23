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
	var network = Network.new()
	var destination = Vector3(95.2,0,-66)
	if network.has_method("guidance"):
		var north: Dictionary = network.call("guidance", Vector3(-93.2,0,76), Vector3.FORWARD, "north", destination)
		var market: Dictionary = network.call("guidance", Vector3(-93.2,0,76), Vector3.FORWARD, "middle", destination)
		check(north.turn == "right" and north.distance > 170, "North route announces the northern right turn")
		check(market.turn == "right" and market.distance < 85, "Market route announces its earlier right turn")
		var closer: Dictionary = network.call("guidance", Vector3(-93.2,0,-70), Vector3.FORWARD, "north", destination)
		check(closer.distance < 35, "Turn distance decreases as the car approaches")
		var wrong_way: Dictionary = network.call("guidance", Vector3(-93.2,0,30), Vector3.BACK, "north", destination)
		check(wrong_way.turn == "return", "Driving away from the route gives a correction cue")
		var off_route: Dictionary = network.call("guidance", Vector3(0,0,50), Vector3.FORWARD, "north", destination)
		check(off_route.turn == "rejoin", "Leaving the road gives a rejoin cue")
		var arrival: Dictionary = network.call("guidance", destination, Vector3.BACK, "north", destination)
		check(arrival.turn == "stop", "Arrival guidance asks the driver to stop")
		for x in [-94.0,-93.2]:
			var missed: Dictionary = network.call("guidance",Vector3(x,0,-12),Vector3.FORWARD,"middle",destination)
			check(missed.turn == "return", "Passing the market turn prompts recovery instead of another turn ahead")
		var passed_office: Dictionary = network.call("guidance",Vector3(93.2,0,-51),Vector3.BACK,"north",destination)
		check(passed_office.turn == "return", "Passing the office prompts a safe return")
	else:
		check(false, "Turn guidance must work for the selected route")
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var diagnostic_name: String = "automated-feedback-score-check.json"
	world._save_report(diagnostic_name,{"diagnostic":true})
	check(not FileAccess.file_exists("user://"+diagnostic_name), "Automated score reports stay separate from player scores")
	if FileAccess.file_exists("user://"+diagnostic_name):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://"+diagnostic_name))
	world.start_mission(true)
	world.player.position = Vector3(0,0.1,50)
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	var acceleration = world.player.get("acceleration")
	check(acceleration != null and acceleration > 3.0 and acceleration < 4.0, "Throttle reports measured forward acceleration")
	check(world.player.speed > 3 and world.player.speed < 4, "Feedback preserves the existing driving response")
	check(absf(float(world.hud.speed_label.text)-world.player.speed*3.6) < 3, "Speedometer follows actual driving speed in km/h")
	Input.action_release("accelerate")
	Input.action_press("brake")
	for i in range(12):
		await physics_frame
	acceleration = world.player.get("acceleration")
	check(acceleration != null and acceleration < -8, "Braking produces negative longitudinal acceleration")
	Input.action_release("brake")
	world.toggle_pause()
	for i in range(8):
		await physics_frame
	check(world.player.get("acceleration") == 0.0, "Pause does not display stale acceleration")
	world.toggle_pause()
	world.player.speed = 0
	Input.action_press("reverse")
	for i in range(30):
		await physics_frame
	Input.action_release("reverse")
	for i in range(10):
		await process_frame
	var gear_label = world.hud.get("gear_label")
	check(gear_label != null and gear_label.text == "R", "Dashboard distinguishes reverse from forward motion")
	world.paused_sim = true
	world.player.position = Vector3(-93.2,0,30)
	world.player.rotation.y = PI
	for i in range(10):
		await process_frame
	var arrow_direction = world.hud.get("navigation_direction")
	check(arrow_direction != null and arrow_direction.y > 0.7, "Recovery arrow points behind the car when the route is behind")
	world.player.position = Vector3(0,0,50)
	world.player.rotation.y = 0
	for i in range(10):
		await process_frame
	arrow_direction = world.hud.get("navigation_direction")
	check(arrow_direction != null and arrow_direction.x < -0.7, "Off-route arrow points toward the road rather than straight ahead")
	world.player.reset_car()
	check(world.player.get("acceleration") == 0.0, "Recovery clears acceleration rather than showing a spike")
	world.queue_free()
	for i in range(3):
		await process_frame
	print("DRIVING_FEEDBACK_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
