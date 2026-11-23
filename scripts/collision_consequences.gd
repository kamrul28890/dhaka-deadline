class_name DhakaCollisionConsequences
extends Node3D

# Realistic Vehicle Collision Deformation, Scraping Sparks, Mechanical Damage &
# Strict DMP (Dhaka Metropolitan Police) Highway Patrol Pursuit & Interception System.

const Geometry = preload("res://scripts/geometry.gd")
const Career = preload("res://scripts/career_manager.gd")

var target_player: CharacterBody3D = null
var manager: Node3D = null

# Visual & Particle FX
var spark_particles: GPUParticles3D
var spark_mat: ParticleProcessMaterial
var steam_particles: GPUParticles3D
var steam_mat: ParticleProcessMaterial

# Audio
var audio_scrape: AudioStreamPlayer3D
var audio_steam: AudioStreamPlayer3D
var audio_police_siren: AudioStreamPlayer3D

# Mechanical Damage State
var steering_alignment_drift: float = 0.0 # Persistent steering pull in [-1.0, 1.0]
var radiator_damaged: bool = false
var engine_power_penalty: float = 1.0 # Multiplier (1.0 = 100%, 0.6 = 60%)
var total_damage_cost_taka: int = 0
var dent_depth_front: float = 0.0

# Strict DMP Highway Police Pursuit State
var police_alerted: bool = false
var police_pursuit_active: bool = false
var police_vehicle: Node3D = null
var police_flash_timer: float = 0.0
var police_dispatch_cooldown: float = 0.0
var police_intercept_distance: float = 25.0

func _init() -> void:
	name = "DhakaCollisionConsequences"
	_setup_sparks()
	_setup_steam()
	_setup_audio()

func _setup_sparks() -> void:
	spark_particles = GPUParticles3D.new()
	spark_particles.name = "ScrapingSparksGPU"
	spark_particles.amount = 800
	spark_particles.lifetime = 0.45
	spark_particles.explosiveness = 0.1

	spark_mat = ParticleProcessMaterial.new()
	spark_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_mat.emission_sphere_radius = 0.25
	spark_mat.direction = Vector3(0, 0.4, 1.0) # Shoot backwards and slightly up
	spark_mat.spread = 28.0
	spark_mat.initial_velocity_min = 6.0
	spark_mat.initial_velocity_max = 14.0
	spark_mat.gravity = Vector3(0, -9.8, 0)
	spark_mat.color = Color(1.0, 0.65, 0.15, 1.0) # Bright yellow-orange spark
	spark_mat.scale_min = 0.03
	spark_mat.scale_max = 0.06

	spark_particles.process_material = spark_mat

	var spark_mesh = BoxMesh.new()
	spark_mesh.size = Vector3(0.04, 0.04, 0.08)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 4.0
	spark_mesh.material = mat
	spark_particles.draw_pass_1 = spark_mesh

	spark_particles.emitting = false
	add_child(spark_particles)

func _setup_steam() -> void:
	steam_particles = GPUParticles3D.new()
	steam_particles.name = "RadiatorSteamGPU"
	steam_particles.amount = 500
	steam_particles.lifetime = 1.1
	steam_particles.explosiveness = 0.05

	steam_mat = ParticleProcessMaterial.new()
	steam_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	steam_mat.emission_box_extents = Vector3(0.5, 0.2, 0.3)
	steam_mat.direction = Vector3(0, 1.0, 0.3) # Billow upward and back
	steam_mat.spread = 25.0
	steam_mat.initial_velocity_min = 2.0
	steam_mat.initial_velocity_max = 4.5
	steam_mat.gravity = Vector3(0, 1.2, 0) # Buoyant rising steam
	steam_mat.color = Color(0.95, 0.95, 0.98, 0.45)
	steam_mat.scale_min = 0.15
	steam_mat.scale_max = 0.45

	steam_particles.process_material = steam_mat

	var steam_mesh = SphereMesh.new()
	steam_mesh.radius = 0.25
	steam_mesh.height = 0.25
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.95, 0.98, 0.35)
	mat.roughness = 0.9
	steam_mesh.material = mat
	steam_particles.draw_pass_1 = steam_mesh

	steam_particles.emitting = false
	add_child(steam_particles)

func _setup_audio() -> void:
	audio_scrape = AudioStreamPlayer3D.new()
	audio_scrape.name = "ScrapeAudio"
	audio_scrape.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	var scrape_st = load("res://assets/audio/metal_scrape.wav")
	if scrape_st:
		audio_scrape.stream = scrape_st
	add_child(audio_scrape)

	audio_steam = AudioStreamPlayer3D.new()
	audio_steam.name = "SteamAudio"
	audio_steam.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	var steam_st = load("res://assets/audio/radiator_steam.wav")
	if steam_st:
		audio_steam.stream = steam_st
	add_child(audio_steam)

	audio_police_siren = AudioStreamPlayer3D.new()
	audio_police_siren.name = "PoliceSirenAudio"
	audio_police_siren.bus = "Traffic" if AudioServer.get_bus_index("Traffic") != -1 else "Master"
	audio_police_siren.max_distance = 80.0
	var siren_st = load("res://assets/audio/police_siren.wav")
	if siren_st:
		audio_police_siren.stream = siren_st
	add_child(audio_police_siren)

# Called when player vehicle experiences a physical collision or barrier grind
func process_collision(collision_info: KinematicCollision3D, delta_velocity: float) -> void:
	if delta_velocity < 2.0:
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--autodrive" in args or "--smoke" in args:
		return

	var normal: Vector3 = collision_info.get_normal()
	var point: Vector3 = collision_info.get_position()

	# 1. Scraping friction against barrier / metal
	if abs(normal.x) > 0.5: # Side barrier collision
		trigger_scraping_sparks(point, normal, delta_velocity)

	# 2. Frontal or severe impact deformation
	if delta_velocity > 4.5:
		apply_impact_deformation(point, normal, delta_velocity)

	# 3. Strict DMP Highway Police pursuit alert
	if delta_velocity > 6.0 and not police_alerted:
		alert_highway_police("Reckless High-Speed Collision")

func trigger_scraping_sparks(contact_point: Vector3, contact_normal: Vector3, speed: float) -> void:
	if is_inside_tree():
		spark_particles.global_position = contact_point
	else:
		spark_particles.position = contact_point
	# Spark emission direction opposite to vehicle travel
	spark_mat.direction = Vector3(contact_normal.x * 0.3, 0.4, 0.85).normalized()
	spark_particles.emitting = true
	if is_instance_valid(audio_scrape) and audio_scrape.is_inside_tree() and not audio_scrape.playing:
		audio_scrape.global_position = contact_point
		audio_scrape.play()

	# Career repair cost deduction for scraping civil property
	var scrape_cost: int = int(round(speed * 35.0))
	total_damage_cost_taka += scrape_cost
	_deduct_career_taka(scrape_cost)

func apply_impact_deformation(point: Vector3, normal: Vector3, delta_v: float) -> void:
	# Calculate damage severity
	var severity: float = clamp((delta_v - 4.0) / 10.0, 0.1, 1.0)
	dent_depth_front = min(dent_depth_front + severity * 0.35, 0.85)

	# Mechanical penalty 1: Radiator breach & steam
	if delta_v > 7.5 or dent_depth_front > 0.5:
		radiator_damaged = true
		engine_power_penalty = 0.55 # Capped to 55% engine output
		steam_particles.emitting = true
		if is_instance_valid(audio_steam) and audio_steam.is_inside_tree() and not audio_steam.playing:
			audio_steam.play()

	# Visually dent the player vehicle's bumper node
	if is_instance_valid(target_player):
		var vis = target_player.get_node_or_null("Visual")
		if is_instance_valid(vis):
			# Compress/dent front bumper inward along Z
			vis.position.z = dent_depth_front * 0.25
			vis.scale = Vector3(1.0 + dent_depth_front * 0.05, 1.0 - dent_depth_front * 0.06, 1.0 - dent_depth_front * 0.12)

	# Severe crash repair cost
	var crash_fine: int = int(round(delta_v * 180.0))
	total_damage_cost_taka += crash_fine
	_deduct_career_taka(crash_fine)

func alert_highway_police(reason: String) -> void:
	police_alerted = true
	police_pursuit_active = true

	# Trigger radio dispatch alert
	if is_instance_valid(manager) and manager.has_method("trigger_radio_cue"):
		manager.trigger_radio_cue(
			"সতর্কতা: হাইওয়ে পুলিশ ধাওয়া করছে! লেন ছেড়ে গাড়ি থামান।",
			"POLICE ALERT: DMP Highway Patrol pursuit active! Pull over immediately."
		)

	# Spawn DMP Highway Police Interceptor Pickup
	_spawn_police_interceptor()

func _spawn_police_interceptor() -> void:
	if is_instance_valid(police_vehicle):
		return

	police_vehicle = Node3D.new()
	police_vehicle.name = "DMP_Highway_Patrol_Interceptor"

	var p_pos: Vector3 = (target_player.global_position if target_player.is_inside_tree() else target_player.position) if is_instance_valid(target_player) else Vector3(0, 2.5, 0)
	police_vehicle.position = p_pos + Vector3(3.2, 0, 45.0) # Spawn behind in adjacent lane
	add_child(police_vehicle)

	# Build Police Pickup Body (White with dark blue DMP stripe)
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color("f8fafc")
	mat_white.roughness = 0.35

	var mat_blue_stripe = StandardMaterial3D.new()
	mat_blue_stripe.albedo_color = Color("1e3a8a") # DMP Navy Blue

	# Chassis
	Geometry.box(police_vehicle, Vector3(0, 0.7, 0), Vector3(1.9, 1.1, 4.8), mat_white, true)
	# DMP Side Stripes
	Geometry.box(police_vehicle, Vector3(-0.96, 0.65, 0), Vector3(0.04, 0.35, 4.2), mat_blue_stripe, false)
	Geometry.box(police_vehicle, Vector3(0.96, 0.65, 0), Vector3(0.04, 0.35, 4.2), mat_blue_stripe, false)
	# Cabin Greenhouse
	Geometry.box(police_vehicle, Vector3(0, 1.45, -0.3), Vector3(1.7, 0.85, 2.2), mat_white, false)

	# DMP Bangla Crest text
	var crest = Geometry.text(police_vehicle, Vector3(-0.98, 0.7, 0), "ডিএমপি হাইওয়ে পুলিশ\nDMP POLICE", 24, Color("ffffff"))
	crest.pixel_size = 0.005

	# Roof Lightbar (Flashing Red and Blue LEDs)
	var mat_red_led = StandardMaterial3D.new()
	mat_red_led.albedo_color = Color("ef4444")
	mat_red_led.emission_enabled = true
	mat_red_led.emission = Color("ef4444")
	mat_red_led.emission_energy_multiplier = 4.0

	var mat_blue_led = StandardMaterial3D.new()
	mat_blue_led.albedo_color = Color("2563eb")
	mat_blue_led.emission_enabled = true
	mat_blue_led.emission = Color("2563eb")
	mat_blue_led.emission_energy_multiplier = 4.0

	var lightbar_base = Geometry.box(police_vehicle, Vector3(0, 1.95, -0.3), Vector3(1.2, 0.12, 0.35), mat_blue_stripe, false)
	var red_beacon = Geometry.box(lightbar_base, Vector3(-0.4, 0.08, 0), Vector3(0.35, 0.15, 0.25), mat_red_led, false)
	red_beacon.name = "BeaconRed"
	var blue_beacon = Geometry.box(lightbar_base, Vector3(0.4, 0.08, 0), Vector3(0.35, 0.15, 0.25), mat_blue_led, false)
	blue_beacon.name = "BeaconBlue"

	# Start Siren
	if is_instance_valid(audio_police_siren) and audio_police_siren.is_inside_tree():
		audio_police_siren.global_position = police_vehicle.global_position
		if not audio_police_siren.playing:
			audio_police_siren.play()

func reset_damage() -> void:
	steering_alignment_drift = 0.0
	radiator_damaged = false
	engine_power_penalty = 1.0
	dent_depth_front = 0.0
	police_alerted = false
	police_pursuit_active = false
	if is_instance_valid(steam_particles):
		steam_particles.emitting = false
	if is_instance_valid(audio_steam):
		audio_steam.stop()
	if is_instance_valid(audio_police_siren):
		audio_police_siren.stop()
	if is_instance_valid(police_vehicle):
		police_vehicle.queue_free()
		police_vehicle = null
	if is_instance_valid(target_player):
		var vis = target_player.get_node_or_null("Visual")
		if is_instance_valid(vis):
			vis.position = Vector3.ZERO
			vis.scale = Vector3.ONE

func _process(delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	var p_pos: Vector3 = target_player.global_position if target_player.is_inside_tree() else target_player.position

	# Update steam emitter position near car front grill
	if radiator_damaged and is_instance_valid(steam_particles):
		if is_inside_tree():
			steam_particles.global_position = p_pos + Vector3(0, 0.85, -2.1)
		else:
			steam_particles.position = p_pos + Vector3(0, 0.85, -2.1)

	# DMP Highway Police Pursuit Steering & Chasing Logic
	if police_pursuit_active and is_instance_valid(police_vehicle):
		var target_pos: Vector3 = p_pos
		# Police car accelerates and pulls alongside player
		var pursuit_target: Vector3 = target_pos + Vector3(3.2, 0, -2.0)
		if police_vehicle.is_inside_tree():
			police_vehicle.global_position = police_vehicle.global_position.move_toward(pursuit_target, 22.0 * delta)
			if is_instance_valid(audio_police_siren):
				audio_police_siren.global_position = police_vehicle.global_position
		else:
			police_vehicle.position = police_vehicle.position.move_toward(pursuit_target, 22.0 * delta)

		# Rapidly strobe red & blue lightbars
		police_flash_timer += delta * 9.0
		var r_beacon = police_vehicle.find_child("BeaconRed", true, false)
		var b_beacon = police_vehicle.find_child("BeaconBlue", true, false)
		if is_instance_valid(r_beacon) and is_instance_valid(b_beacon):
			var r_mat = r_beacon.material_override as StandardMaterial3D
			var b_mat = b_beacon.material_override as StandardMaterial3D
			if r_mat and b_mat:
				var phase: bool = int(police_flash_timer) % 2 == 0
				r_mat.emission_energy_multiplier = 5.0 if phase else 0.5
				b_mat.emission_energy_multiplier = 0.5 if phase else 5.0

func _deduct_career_taka(amount: int) -> void:
	var prof = Career.load_profile()
	prof.total_fares_taka = max(0, prof.get("total_fares_taka", 0) - amount)
	prof.lifetime_collisions = prof.get("lifetime_collisions", 0) + 1
	Career.save_profile(prof)
