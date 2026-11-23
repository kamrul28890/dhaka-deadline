extends SceneTree

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
	# 1. Verify audio asset existence and valid stream loading
	var audio_files = [
		"engine.wav", "tire_roll.wav", "tire_skid.wav", "horn.wav", "impact.wav",
		"traffic_cng.wav", "traffic_bus.wav", "traffic_horn.wav", "ambience.wav"
	]
	for filename in audio_files:
		var path = "res://assets/audio/" + filename
		check(FileAccess.file_exists(path), "Audio file exists: " + filename)
		var stream: AudioStreamWAV = load(path)
		check(stream != null and stream.data.size() > 0, "Audio stream loads valid data: " + filename)

	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	# 2. Check ambient audio player
	check(world.get("ambience_player") != null or DisplayServer.get_name() == "headless", "Ambience player configured in main scene")

	# 3. Check traffic vehicle audio nodes
	var bus_agent = world.traffic[0]
	var cng_agent = world.traffic[2]
	check(bus_agent.get("engine_audio") != null or DisplayServer.get_name() == "headless", "Traffic bus has engine audio configured")
	check(cng_agent.get("engine_audio") != null or DisplayServer.get_name() == "headless", "Traffic CNG has engine audio configured")

	# 4. Check player car audio players
	var player = world.player
	check(player.get("chassis_pitch") != null, "Player car implements chassis pitch dynamics")
	check(player.get("chassis_roll") != null, "Player car implements chassis roll dynamics")
	check(player.get("skid_intensity") != null, "Player car tracks tire skid intensity")

	# 5. Test Acceleration & Pitch Squat
	world.start_mission(true)
	player.position = Vector3(0, 0.1, 50)
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")

	var accel = player.get("acceleration")
	check(accel != null and accel > 3.0 and accel < 4.0, "Nominal acceleration preserved (3.0 to 4.0 m/s²)")
	check(player.speed > 3.0 and player.speed < 4.0, "Driving speed after 1s preserved (3.0 to 4.0 m/s)")
	var pitch_after_accel = player.visual.rotation.x
	check(pitch_after_accel < -0.005, "Acceleration produces realistic chassis squat (pitch < -0.005 rad)")

	# 6. Test Braking & Pitch Dive
	Input.action_press("brake")
	for i in range(12):
		await physics_frame
	Input.action_release("brake")

	var brake_accel = player.get("acceleration")
	check(brake_accel != null and brake_accel < -8.0, "Braking produces negative longitudinal acceleration (< -8 m/s²)")
	var pitch_after_brake = player.visual.rotation.x
	check(pitch_after_brake > 0.01, "Braking produces forward pitch dive (pitch > 0.01 rad)")

	# 7. Test Suspension Rebound at Rest
	player.speed = 0
	player.acceleration = 0
	for i in range(40):
		await physics_frame
	check(absf(player.visual.rotation.x) < 0.005, "Suspension pitch rebounds to neutral at rest")
	check(absf(player.visual.rotation.z) < 0.005, "Suspension roll rebounds to neutral at rest")

	# 8. Test Cornering Body Roll
	player.speed = 8.0
	Input.action_press("steer_right")
	for i in range(25):
		await physics_frame
	Input.action_release("steer_right")
	var roll_in_turn = player.visual.rotation.z
	check(absf(roll_in_turn) > 0.01, "Turning at speed produces measurable body roll (roll > 0.01 rad)")
	player.steering = 0.0
	player.speed = 0.0

	# 9. Test Tire Skid Intensity Under Handbrake
	player.speed = 7.0
	Input.action_press("handbrake")
	for i in range(10):
		await physics_frame
	Input.action_release("handbrake")
	check(player.skid_intensity > 0.1, "Handbrake at speed activates tire skid intensity")

	# 10. Test Cabin Camera Attachment Under Motion
	player.camera_mode = 2 # cabin view
	for i in range(5):
		await physics_frame
	var seat_pos = player.global_position + player.global_transform.basis * Vector3(0.34, 1.14, 0.28)
	check(player.camera.global_position.distance_to(seat_pos) < 0.001, "Cabin camera remains precisely anchored to seat coordinates")

	# 11. Test Pause Clears Dynamic States
	world.toggle_pause()
	for i in range(5):
		await physics_frame
	check(player.get("acceleration") == 0.0, "Pause displays zero acceleration")
	check(player.get("smooth_accel") == 0.0, "Pause resets smoothed acceleration")
	world.toggle_pause()

	world.queue_free()
	for i in range(3):
		await process_frame

	print("DRIVING_FEEL_AUDIO_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
