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
	print("=== Running Cockpit Interior & Mirror System Tests (v1.3) ===")

	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	var player = world.player
	check(player != null, "Player car exists in world")

	# 1. 3D Cockpit Cluster and Gauges
	var cluster = player.visual.find_child("CockpitCluster", true, false)
	check(cluster != null, "Player visual hierarchy contains CockpitCluster node")

	var speedo = player.visual.find_child("SpeedoNeedle", true, false)
	var tacho = player.visual.find_child("TachoNeedle", true, false)
	check(speedo != null and tacho != null, "Cockpit cluster contains analog SpeedoNeedle and TachoNeedle")

	# 2. Gauge dynamics tracking speed and RPM
	world.paused_sim = false
	player.enabled = true
	player.speed = 0.0
	for i in range(5):
		await physics_frame
	var idle_tacho: float = player.tacho_angle
	check(idle_tacho > 0.05, "Tachometer indicates positive idle RPM (~850 RPM)")
	check(player.speedo_angle < 0.05, "Speedometer indicates 0 km/h at rest")

	player.speed = 11.11 # 40 km/h
	player.throttle_input = 0.8
	for i in range(15):
		await physics_frame
	check(player.speedo_angle > 0.6, "Speedometer needle deflects proportionally to forward velocity")
	check(player.tacho_angle > idle_tacho, "Tachometer needle rises under throttle load")

	# 3. Instrument cluster backlighting
	player.set_headlights(true)
	check(player.cluster_backlit == true, "Instrument cluster backlight activates with headlights")
	var dial_mat: StandardMaterial3D = player.cluster_material
	check(dial_mat != null and dial_mat.emission_enabled, "Cluster dials have active emission glow when headlights are on")

	player.set_headlights(false)
	check(player.cluster_backlit == false, "Instrument cluster backlight turns off when headlights are deactivated")
	check(not dial_mat.emission_enabled or dial_mat.emission == Color.BLACK, "Cluster dial emission turns off without headlights")

	# 4. Rearview Mirror SubViewport System
	var mirror = player.visual.find_child("RearviewMirror", true, false)
	check(mirror != null, "Cockpit contains windshield-mounted RearviewMirror")

	var mirror_vp = player.find_child("MirrorViewport", true, false)
	check(mirror_vp != null, "Player contains SubViewport for rearview mirror rendering")

	if mirror_vp:
		var mirror_cam = mirror_vp.find_child("MirrorCamera", true, false)
		check(mirror_cam != null, "Rearview SubViewport has dedicated MirrorCamera")
		if mirror_cam:
			# In local space of car, mirror camera must point backward (+Z in car basis)
			var forward_dot = -mirror_cam.transform.basis.z.dot(-Vector3.FORWARD)
			check(forward_dot > 0.8, "Mirror camera is oriented facing rearward")

	# 5. Cabin acoustic damping in interior camera view
	player.camera_mode = 0 # Chase view
	for i in range(5):
		await physics_frame
	check(player.cabin_acoustic_damping == false, "Chase camera uses full exterior audio loudness")

	player.camera_mode = 2 # Cabin view
	for i in range(10):
		await physics_frame
	check(player.cabin_acoustic_damping == true, "Cabin camera engages interior acoustic damping")

	# 6. Steering column articulation
	player.steering = 0.75
	for i in range(10):
		await physics_frame
	var col = player.visual.find_child("steering_column", true, false)
	check(col != null, "Steering column exists in visual model")

	world.queue_free()
	await process_frame
	await process_frame
	await process_frame

	print("COCKPIT_INTERIOR_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
