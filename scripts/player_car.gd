extends CharacterBody3D

const G = preload("res://scripts/geometry.gd")
var speed: float = 0
var acceleration: float = 0
var throttle_input: float = 0
var brake_input: float = 0
var steering: float = 0
var enabled: bool = false
var collision_count: int = 0
var collision_cooldown: float = 0
var distance_driven: float = 0
var last_position: Vector3
var camera: Camera3D
var camera_mode: int = 0
var visual: Node3D
var lamps: Array[SpotLight3D] = []
var manager: Node

# Suspension & driving feel dynamics
var chassis_pitch: float = 0.0
var chassis_roll: float = 0.0
var smooth_accel: float = 0.0
var skid_intensity: float = 0.0
var road_vibe_phase: float = 0.0
var impact_rebound: float = 0.0

# Playable vehicle type & 3-wheeler dynamics (v1.5)
var vehicle_type: String = "car"
var length: float = 4.35
var width: float = 1.85
var fare_taka: float = 40.0
var cng_stopped_time: float = 0.0
var handlebar: Node3D
var fare_meter: Node3D
var fare_label: Label3D
var collision_shape_node: CollisionShape3D

# Wiper dynamics
var wipers_active: bool = false
var wiper_angle: float = 0.0
var wiper_phase: float = 0.0
var wiper_L: Node3D
var wiper_R: Node3D

# Cockpit interior & instrument cluster
var speedo_angle: float = 0.0
var tacho_angle: float = 0.0
var cluster_backlit: bool = false
var cluster_material: StandardMaterial3D
var cockpit_cluster: Node3D
var speedo_needle: Node3D
var tacho_needle: Node3D
var cabin_acoustic_damping: bool = false
var rearview_mirror: Node3D
var mirror_viewport: SubViewport
var mirror_camera: Camera3D

# Audio players
var horn: AudioStreamPlayer3D
var engine_sound: AudioStreamPlayer3D
var tire_roll_sound: AudioStreamPlayer3D
var tire_skid_sound: AudioStreamPlayer3D
var impact_sound: AudioStreamPlayer3D
var wiper_sweep_sound: AudioStreamPlayer3D
var splash_sound: AudioStreamPlayer3D
var splash_cooldown: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.5
	collision_shape_node = CollisionShape3D.new()
	var bounds = BoxShape3D.new()
	bounds.size = Vector3(1.85, 1.3, 4.35)
	collision_shape_node.shape = bounds
	collision_shape_node.position.y = 0.7
	add_child(collision_shape_node)
	_build_vehicle_visual("car")
	camera = Camera3D.new()
	camera.fov = 66
	camera.far = 850
	camera.current = true
	manager.add_child(camera)
	reset_car()

func _build_vehicle_visual(type: String) -> void:
	if is_instance_valid(visual):
		visual.name = "old_visual"
		remove_child(visual)
		visual.queue_free()
	for l in lamps:
		if is_instance_valid(l):
			l.queue_free()
	lamps.clear()

	vehicle_type = type
	if vehicle_type == "cng":
		length = 2.8
		width = 1.4
		fare_taka = 40.0
		cng_stopped_time = 0.0
	else:
		length = 4.35
		width = 1.85

	if is_instance_valid(collision_shape_node) and collision_shape_node.shape is BoxShape3D:
		collision_shape_node.shape.size = Vector3(width, 1.3, length)

	var color: Color = Color("26694d") if vehicle_type == "cng" else Color("58778a")
	visual = G.vehicle(self, vehicle_type, color, true)
	visual.name = "visual"

	if vehicle_type == "cng":
		_setup_cng_interior()
		var light = SpotLight3D.new()
		light.position = Vector3(0.0, 0.65, -1.45)
		light.light_color = Color("ffe6b6")
		light.light_energy = 2.4
		light.spot_range = 32
		light.spot_angle = 35
		light.visible = false
		add_child(light)
		lamps.append(light)
	else:
		_setup_wipers()
		_setup_cockpit()
		for side in [-1, 1]:
			var light = SpotLight3D.new()
			light.position = Vector3(side * 0.68, 0.75, -2.25)
			light.light_color = Color("ffe6b6")
			light.light_energy = 2.5
			light.spot_range = 35
			light.spot_angle = 32
			light.visible = false
			add_child(light)
			lamps.append(light)

	_setup_audio()

func set_vehicle_type(type: String) -> void:
	if type != "car" and type != "cng":
		type = "car"
	if type == vehicle_type and is_instance_valid(visual):
		return
	_build_vehicle_visual(type)

func _setup_cng_interior() -> void:
	# 1. Articulated Steering Handlebar
	handlebar = Node3D.new()
	handlebar.name = "Handlebar"
	handlebar.position = Vector3(0.0, 0.88, -0.65)
	visual.add_child(handlebar)
	var bar_mat = G.material(Color("161718"), 0.4, 0.6)
	var grip_mat = G.material(Color("0d0d0e"), 0.8, 0.0)
	G.cylinder(handlebar, Vector3(0, -0.15, 0), 0.018, 0.35, bar_mat)
	G.cylinder(handlebar, Vector3(0, 0, 0), 0.016, 0.58, bar_mat)
	for s in [-1, 1]:
		G.cylinder(handlebar, Vector3(s * 0.25, 0, 0), 0.022, 0.12, grip_mat)
		G.box(handlebar, Vector3(s * 0.20, 0.02, 0.05), Vector3(0.06, 0.015, 0.08), bar_mat)

	# 2. Fare Meter (ভাড়া মিটার)
	fare_meter = Node3D.new()
	fare_meter.name = "FareMeter"
	fare_meter.position = Vector3(-0.18, 0.95, -0.62)
	fare_meter.rotation.x = -deg_to_rad(22)
	visual.add_child(fare_meter)
	G.box(fare_meter, Vector3(0, 0, 0), Vector3(0.14, 0.10, 0.06), G.material(Color("111214"), 0.7, 0.1))
	var led_face = StandardMaterial3D.new()
	led_face.albedo_color = Color("051a08")
	led_face.emission_enabled = true
	led_face.emission = Color("22c55e") * 0.6
	G.box(fare_meter, Vector3(0, 0.01, 0.025), Vector3(0.12, 0.06, 0.01), led_face)
	fare_label = G.text(fare_meter, Vector3(0, 0.01, 0.035), "ভাড়া: ৳ 40", 22, Color("22c55e"))
	fare_label.pixel_size = 0.003

func _setup_wipers() -> void:
	wiper_L = Node3D.new()
	wiper_L.name = "wiper_L"
	wiper_L.position = Vector3(-0.35, 0.92, -0.65)
	wiper_L.rotation.x = -0.38
	visual.add_child(wiper_L)
	var blade_mat = G.material(Color("161718"), 0.5, 0.1)
	G.box(wiper_L, Vector3(0, 0.26, 0), Vector3(0.022, 0.52, 0.018), blade_mat)

	wiper_R = Node3D.new()
	wiper_R.name = "wiper_R"
	wiper_R.position = Vector3(0.35, 0.92, -0.65)
	wiper_R.rotation.x = -0.38
	visual.add_child(wiper_R)
	G.box(wiper_R, Vector3(0, 0.26, 0), Vector3(0.022, 0.52, 0.018), blade_mat)

func _setup_cockpit() -> void:
	# 1. 3D Analog Instrument Cluster
	cockpit_cluster = Node3D.new()
	cockpit_cluster.name = "CockpitCluster"
	cockpit_cluster.position = Vector3(0.34, 0.90, -0.42)
	cockpit_cluster.rotation.x = -deg_to_rad(25)
	visual.add_child(cockpit_cluster)

	# Binnacle cowl housing
	G.box(cockpit_cluster, Vector3(0, 0.04, -0.02), Vector3(0.38, 0.14, 0.06), G.material(Color("181a1c"), 0.8, 0.1))

	# Dial material with emission capabilities
	cluster_material = StandardMaterial3D.new()
	cluster_material.albedo_color = Color("141618")
	cluster_material.roughness = 0.5
	cluster_material.emission_enabled = false
	cluster_material.emission = Color("2fe6c8") * 1.5

	# Left dial: Speedometer
	G.cylinder(cockpit_cluster, Vector3(-0.08, 0, 0.01), 0.05, 0.005, cluster_material)
	speedo_needle = Node3D.new()
	speedo_needle.name = "SpeedoNeedle"
	speedo_needle.position = Vector3(-0.08, 0, 0.015)
	cockpit_cluster.add_child(speedo_needle)
	G.box(speedo_needle, Vector3(0, 0.022, 0), Vector3(0.003, 0.044, 0.003), G.material(Color("e84638"), 0.3, 0.2))

	# Right dial: Tachometer
	G.cylinder(cockpit_cluster, Vector3(0.08, 0, 0.01), 0.05, 0.005, cluster_material)
	tacho_needle = Node3D.new()
	tacho_needle.name = "TachoNeedle"
	tacho_needle.position = Vector3(0.08, 0, 0.015)
	cockpit_cluster.add_child(tacho_needle)
	G.box(tacho_needle, Vector3(0, 0.022, 0), Vector3(0.003, 0.044, 0.003), G.material(Color("e84638"), 0.3, 0.2))

	# 2. Rearview Mirror with SubViewport
	rearview_mirror = Node3D.new()
	rearview_mirror.name = "RearviewMirror"
	rearview_mirror.position = Vector3(0, 1.25, -0.32)
	rearview_mirror.rotation.y = deg_to_rad(-12)
	visual.add_child(rearview_mirror)

	G.box(rearview_mirror, Vector3.ZERO, Vector3(0.24, 0.07, 0.025), G.material(Color("111315"), 0.8, 0.1))

	mirror_viewport = SubViewport.new()
	mirror_viewport.name = "MirrorViewport"
	mirror_viewport.size = Vector2i(256, 128)
	mirror_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mirror_viewport)

	mirror_camera = Camera3D.new()
	mirror_camera.name = "MirrorCamera"
	mirror_camera.fov = 48
	mirror_camera.near = 0.1
	mirror_camera.far = 250
	mirror_camera.position = Vector3(0, 1.25, -0.32)
	mirror_camera.rotation.y = PI
	mirror_viewport.add_child(mirror_camera)

	var mirror_screen = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.22, 0.06)
	mirror_screen.mesh = quad
	mirror_screen.position = Vector3(0, 0, 0.014)
	var mirror_mat = StandardMaterial3D.new()
	mirror_mat.albedo_texture = mirror_viewport.get_texture()
	mirror_mat.roughness = 0.05
	mirror_mat.metallic = 0.95
	mirror_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mirror_screen.material_override = mirror_mat
	rearview_mirror.add_child(mirror_screen)

func set_wipers(active: bool) -> void:
	wipers_active = active
	if not wipers_active:
		wiper_angle = 0.0
		wiper_phase = 0.0
		if is_instance_valid(wiper_L):
			wiper_L.rotation.z = 0.0
		if is_instance_valid(wiper_R):
			wiper_R.rotation.z = 0.0

func toggle_wipers() -> void:
	set_wipers(not wipers_active)

func play_splash() -> void:
	if is_instance_valid(splash_sound) and not splash_sound.playing:
		splash_sound.play()

func _setup_audio() -> void:
	horn = AudioStreamPlayer3D.new()
	horn.stream = load("res://assets/audio/horn.wav")
	horn.volume_db = -16
	horn.max_distance = 40
	horn.bus = "SFX"
	add_child(horn)

	engine_sound = AudioStreamPlayer3D.new()
	var engine_stream_path: String = "res://assets/audio/traffic_cng.wav" if vehicle_type == "cng" else "res://assets/audio/engine.wav"
	var engine_stream: AudioStreamWAV = load(engine_stream_path)
	engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine_stream.loop_begin = 0
	engine_stream.loop_end = 44100
	engine_sound.stream = engine_stream
	engine_sound.volume_db = -24
	engine_sound.max_distance = 45
	engine_sound.bus = "Engine"
	add_child(engine_sound)

	tire_roll_sound = AudioStreamPlayer3D.new()
	var roll_stream: AudioStreamWAV = load("res://assets/audio/tire_roll.wav")
	roll_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	roll_stream.loop_begin = 0
	roll_stream.loop_end = 44100
	tire_roll_sound.stream = roll_stream
	tire_roll_sound.volume_db = -80
	tire_roll_sound.max_distance = 32
	tire_roll_sound.bus = "SFX"
	add_child(tire_roll_sound)

	tire_skid_sound = AudioStreamPlayer3D.new()
	var skid_stream: AudioStreamWAV = load("res://assets/audio/tire_skid.wav")
	skid_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	skid_stream.loop_begin = 0
	skid_stream.loop_end = 44100
	tire_skid_sound.stream = skid_stream
	tire_skid_sound.volume_db = -80
	tire_skid_sound.max_distance = 35
	tire_skid_sound.bus = "SFX"
	add_child(tire_skid_sound)

	impact_sound = AudioStreamPlayer3D.new()
	impact_sound.stream = load("res://assets/audio/impact.wav")
	impact_sound.volume_db = -14
	impact_sound.max_distance = 35
	impact_sound.bus = "SFX"
	add_child(impact_sound)

	wiper_sweep_sound = AudioStreamPlayer3D.new()
	wiper_sweep_sound.stream = load("res://assets/audio/wiper_sweep.wav")
	wiper_sweep_sound.volume_db = -12
	wiper_sweep_sound.max_distance = 25
	wiper_sweep_sound.bus = "SFX"
	add_child(wiper_sweep_sound)

	splash_sound = AudioStreamPlayer3D.new()
	splash_sound.stream = load("res://assets/audio/water_splash.wav")
	splash_sound.volume_db = -10
	splash_sound.max_distance = 30
	splash_sound.bus = "SFX"
	add_child(splash_sound)

func reset_car() -> void:
	var start_pos: Vector3 = Vector3(-93.2, -0.06, 76)
	if is_instance_valid(manager) and manager.active_mission.has("spawn_point"):
		start_pos = manager.active_mission["spawn_point"]
	position = start_pos
	rotation = Vector3.ZERO
	speed = 0
	acceleration = 0
	smooth_accel = 0
	chassis_pitch = 0
	chassis_roll = 0
	skid_intensity = 0
	impact_rebound = 0
	throttle_input = 0
	brake_input = 0
	velocity = Vector3.ZERO
	last_position = position
	if visual:
		visual.rotation = Vector3.ZERO
	if camera:
		camera.position = position + Vector3(1, 4.3, 9)
	if is_instance_valid(manager) and is_instance_valid(manager.collision_consequences):
		manager.collision_consequences.reset_damage()

func _physics_process(delta: float) -> void:
	if manager.paused_sim:
		acceleration = 0
		smooth_accel = 0
		throttle_input = 0
		brake_input = 0
		if vehicle_type == "cng":
			fare_taka = 40.0 + (distance_driven * 0.012) + (cng_stopped_time * 0.033)
			if is_instance_valid(fare_label):
				fare_label.text = "ভাড়া: ৳ %d" % int(fare_taka)
			if is_instance_valid(handlebar):
				handlebar.rotation.y = steering * -0.55
		_update_camera(delta)
		_update_audio(delta)
		return
	collision_cooldown = maxf(0, collision_cooldown - delta)
	var throttle: float = Input.get_action_strength("accelerate") if enabled else 0
	var brake: float = Input.get_action_strength("brake") if enabled else 0
	var reverse: float = Input.get_action_strength("reverse") if enabled else 0
	var previous_speed: float = speed
	throttle_input = maxf(throttle, reverse)
	brake_input = maxf(brake, Input.get_action_strength("handbrake") if enabled else 0)
	var target_steering: float = Input.get_axis("steer_left", "steer_right") if enabled else 0
	# Natural self-centering when rolling forward
	var steer_rate: float = 4.2 if (target_steering == 0 and absf(speed) > 1.0) else 3.0
	steering = move_toward(steering, target_steering, delta * steer_rate)

	var max_fwd: float = 16.5 if vehicle_type == "cng" else 22.2
	var accel_mult: float = 4.2 if vehicle_type == "cng" else 3.6
	var wheelbase: float = 1.8 if vehicle_type == "cng" else 2.65
	if is_instance_valid(manager) and is_instance_valid(manager.collision_consequences):
		var p_mult = manager.collision_consequences.engine_power_penalty
		max_fwd *= p_mult
		accel_mult *= p_mult
	if throttle > 0:
		speed = move_toward(speed, max_fwd, delta * accel_mult * throttle)
	elif reverse > 0:
		speed = move_toward(speed, -4.5, delta * 2.5)
	else:
		speed = move_toward(speed, 0, delta * 0.5)
	if brake > 0 or not enabled:
		speed = move_toward(speed, 0, delta * 9.0 * maxf(brake, 0.4))
	if enabled and Input.is_action_pressed("handbrake"):
		speed = move_toward(speed, 0, delta * 13)

	# Bicycle steering model; the wheel angle reduces with speed for keyboard control.
	var wheel_angle: float = steering * lerpf(0.5, 0.15, clampf(absf(speed)/max_fwd, 0, 1))
	rotation.y -= speed / wheelbase * tan(wheel_angle) * delta
	var forward: Vector3 = -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y -= 18 * delta
	if is_on_floor():
		velocity.y = -0.5
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var hit: KinematicCollision3D = get_slide_collision(i)
		if is_instance_valid(manager) and is_instance_valid(manager.collision_consequences):
			manager.collision_consequences.process_collision(hit, absf(previous_speed))
		if absf(hit.get_normal().y) < 0.5 and absf(speed) > 1.5:
			if collision_cooldown <= 0:
				collision_count += 1
				collision_cooldown = 2.5
				manager.on_collision(hit.get_collider())
				impact_rebound = clampf(absf(speed) * 0.035, 0.025, 0.065)
				if is_instance_valid(impact_sound) and not impact_sound.playing:
					impact_sound.pitch_scale = randf_range(0.92, 1.08)
					impact_sound.play()
			speed *= 0.25

	if position.y < -5:
		reset_car()
	else:
		acceleration = (speed-previous_speed)/delta

	distance_driven += position.distance_to(last_position)
	last_position = position

	if vehicle_type == "cng":
		if absf(speed) < 0.5:
			cng_stopped_time += delta
		fare_taka = 40.0 + (distance_driven * 0.012) + (cng_stopped_time * 0.033)
		if is_instance_valid(fare_label):
			fare_label.text = "ভাড়া: ৳ %d" % int(fare_taka)
		if is_instance_valid(handlebar):
			handlebar.rotation.y = steering * -0.55

	# Suspension dynamics: pitch squat/dive and cornering body roll
	smooth_accel = lerpf(smooth_accel, acceleration, delta * 12.0)
	var target_pitch: float = 0.0
	if smooth_accel > 0.2:
		# Acceleration squat (front raises, rear dips -> negative X rotation)
		target_pitch = -clampf(smooth_accel / 3.6, 0.0, 1.0) * 0.024
	elif smooth_accel < -0.4:
		# Braking dive (front dips -> positive X rotation)
		target_pitch = clampf(-smooth_accel / 9.0, 0.0, 1.0) * 0.042
	if impact_rebound > 0:
		target_pitch += impact_rebound
		impact_rebound = move_toward(impact_rebound, 0.0, delta * 0.5)
	chassis_pitch = lerpf(chassis_pitch, target_pitch, delta * 8.0)

	# Suspension body roll opposite to lateral turning acceleration
	var lateral_accel: float = speed * steering * 0.35
	var target_roll: float = -clampf(lateral_accel * 0.018, -0.055, 0.055)
	chassis_roll = lerpf(chassis_roll, target_roll, delta * 6.0)

	# Subtle high-frequency road texture vibration at speed
	road_vibe_phase += delta * (28.0 + absf(speed) * 2.5)
	var vibe: float = sin(road_vibe_phase) * 0.0003 * clampf(absf(speed) / 10.0, 0.0, 1.0)

	visual.rotation.x = chassis_pitch + vibe
	visual.rotation.z = chassis_roll

	# Tire skid intensity tracking
	var hard_brake: bool = (brake_input > 0.5 and acceleration < -5.0 and absf(speed) > 2.0)
	var handbrake_slide: bool = (enabled and Input.is_action_pressed("handbrake") and absf(speed) > 1.8)
	var corner_scrub: bool = (absf(steering * speed) > 6.0 and absf(speed) > 3.5)
	if handbrake_slide:
		skid_intensity = move_toward(skid_intensity, 1.0, delta * 8.0)
	elif hard_brake:
		skid_intensity = move_toward(skid_intensity, 0.75, delta * 6.0)
	elif corner_scrub:
		skid_intensity = move_toward(skid_intensity, 0.5, delta * 5.0)
	else:
		skid_intensity = move_toward(skid_intensity, 0.0, delta * 4.0)

	# Wiper oscillation and cabin atmosphere
	if wipers_active:
		var prev_sin: float = sin(wiper_phase)
		wiper_phase += delta * 7.2
		var cur_sin: float = sin(wiper_phase)
		wiper_angle = (cur_sin * 0.5 + 0.5) * 1.25
		if is_instance_valid(wiper_L):
			wiper_L.rotation.z = -wiper_angle
		if is_instance_valid(wiper_R):
			wiper_R.rotation.z = -wiper_angle
		if prev_sin * cur_sin <= 0.0 and is_instance_valid(wiper_sweep_sound) and not wiper_sweep_sound.playing:
			wiper_sweep_sound.play()

	# Hydrodynamic water splash spray in wet conditions
	splash_cooldown = maxf(0.0, splash_cooldown - delta)
	if is_instance_valid(manager) and manager.get("district") != null and manager.district.get("weather") == "monsoon":
		if absf(speed) > 6.0 and splash_cooldown <= 0.0:
			play_splash()
			splash_cooldown = 1.2

	# Cockpit Gauge Animation (Speedometer & Tachometer)
	var kmh: float = absf(speed) * 3.6
	var target_speedo: float = clampf(kmh / 140.0 * 2.4, 0.0, 2.5)
	speedo_angle = lerpf(speedo_angle, target_speedo, delta * 12.0)
	if is_instance_valid(speedo_needle):
		speedo_needle.rotation.z = -speedo_angle

	var rpm_factor: float = 0.15 + 0.85 * (clampf(absf(speed) / 22.0, 0.0, 1.0) * 0.7 + throttle_input * 0.3)
	var target_tacho: float = clampf(rpm_factor * 2.2, 0.15, 2.4)
	tacho_angle = lerpf(tacho_angle, target_tacho, delta * 14.0)
	if is_instance_valid(tacho_needle):
		tacho_needle.rotation.z = -tacho_angle

	# Mirror camera position synchronization
	if is_instance_valid(mirror_camera):
		mirror_camera.global_transform = global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.25, -0.32))

	_update_camera(delta)
	_update_audio(delta)

func _update_camera(delta: float) -> void:
	cabin_acoustic_damping = (camera_mode == 2 and vehicle_type == "car")
	var target: Vector3
	var focus: Vector3
	camera.fov = 55 if camera_mode == 2 else 66
	if camera_mode == 0:
		var cam_offset = Vector3(0.0, 2.5, 5.8) if vehicle_type == "cng" else Vector3(0.5, 2.8, 6.8)
		target = global_position + global_transform.basis * cam_offset
		focus = global_position + Vector3.UP * 1.2 - global_transform.basis.z * 5
		camera.near = 0.2
	elif camera_mode == 1:
		var cam_offset = Vector3(0.0, 1.45, -1.2) if vehicle_type == "cng" else Vector3(0.48, 1.65, -1.6)
		target = global_position + global_transform.basis * cam_offset
		focus = target - global_transform.basis.z * 20
		camera.near = 0.08
	else:
		var cam_offset = Vector3(0.0, 1.02, -0.12) if vehicle_type == "cng" else Vector3(0.34, 1.14, 0.28)
		target = global_position + global_transform.basis * cam_offset
		focus = target - global_transform.basis.z * 20
		camera.near = 0.035
	if camera_mode == 2:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, 1-exp(-delta * (6 if camera_mode == 0 else 30)))
	camera.look_at(focus, Vector3.UP)

func _update_audio(delta: float) -> void:
	if engine_sound == null or horn == null:
		return
	if manager.paused_sim or not enabled:
		if engine_sound.playing:
			engine_sound.stop()
		if is_instance_valid(tire_roll_sound) and tire_roll_sound.playing:
			tire_roll_sound.stop()
		if is_instance_valid(tire_skid_sound) and tire_skid_sound.playing:
			tire_skid_sound.stop()
		if horn.playing:
			horn.stop()
		return

	# Horn
	var sounding: bool = enabled and Input.is_action_pressed("horn")
	if sounding and not horn.playing:
		horn.play()
	elif not sounding and horn.playing:
		horn.stop()

	# Engine: multi-gear simulated RPM model
	if not engine_sound.playing:
		engine_sound.play()
	var abs_spd: float = absf(speed)
	var gear_ratio: float = 1.0
	var gear_rpm_norm: float = 0.0
	if abs_spd < 5.5:
		gear_rpm_norm = clampf(abs_spd / 5.5, 0.0, 1.0)
		gear_ratio = 1.0
	elif abs_spd < 11.5:
		gear_rpm_norm = clampf((abs_spd - 5.0) / 6.5, 0.1, 1.0)
		gear_ratio = 1.12
	elif abs_spd < 17.0:
		gear_rpm_norm = clampf((abs_spd - 10.5) / 6.5, 0.15, 1.0)
		gear_ratio = 1.22
	else:
		gear_rpm_norm = clampf((abs_spd - 15.5) / 6.7, 0.2, 1.0)
		gear_ratio = 1.32
	var base_pitch: float = 0.85 + gear_rpm_norm * 0.72 * gear_ratio
	var throttle_boost: float = 0.10 * throttle_input
	engine_sound.pitch_scale = lerpf(engine_sound.pitch_scale, base_pitch + throttle_boost, delta * 10.0)
	var target_engine_vol: float = -26.0 + 4.0 * throttle_input + 2.0 * gear_rpm_norm
	engine_sound.volume_db = lerpf(engine_sound.volume_db, target_engine_vol, delta * 8.0)

	# Tire roll sound
	if is_instance_valid(tire_roll_sound):
		if abs_spd > 0.4:
			if not tire_roll_sound.playing:
				tire_roll_sound.play()
			tire_roll_sound.volume_db = lerpf(-44.0, -16.0, clampf(abs_spd / 20.0, 0.0, 1.0))
			tire_roll_sound.pitch_scale = clampf(0.8 + abs_spd * 0.02, 0.7, 1.3)
		else:
			if tire_roll_sound.playing:
				tire_roll_sound.stop()

	# Tire skid sound
	if is_instance_valid(tire_skid_sound):
		if skid_intensity > 0.08:
			if not tire_skid_sound.playing:
				tire_skid_sound.play()
			tire_skid_sound.volume_db = lerpf(-28.0, -12.0, skid_intensity)
			tire_skid_sound.pitch_scale = lerpf(0.92, 1.12, clampf(abs_spd / 15.0, 0.0, 1.0))
		elif tire_skid_sound.playing:
			tire_skid_sound.stop()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("camera"):
		camera_mode = (camera_mode+1)%3
	if event.is_action_pressed("vehicle_cycle"):
		set_vehicle_type("cng" if vehicle_type == "car" else "car")
	if event.is_action_pressed("headlights"):
		var will_be_lit = not lamps[0].visible if lamps.size() > 0 else true
		set_headlights(will_be_lit)
	if event.is_action_pressed("wipers"):
		toggle_wipers()
	if event.is_action_pressed("reset"):
		manager.recover_player()

func set_headlights(enabled: bool) -> void:
	for lamp in lamps:
		lamp.visible = enabled
	cluster_backlit = enabled
	if is_instance_valid(cluster_material):
		cluster_material.emission_enabled = enabled
		cluster_material.emission = Color("2fe6c8") * 1.5 if enabled else Color.BLACK

func _exit_tree() -> void:
	if is_instance_valid(horn):
		horn.stop()
	if is_instance_valid(engine_sound):
		engine_sound.stop()
	if is_instance_valid(tire_roll_sound):
		tire_roll_sound.stop()
	if is_instance_valid(tire_skid_sound):
		tire_skid_sound.stop()
	if is_instance_valid(impact_sound):
		impact_sound.stop()
	if is_instance_valid(wiper_sweep_sound):
		wiper_sweep_sound.stop()
	if is_instance_valid(splash_sound):
		splash_sound.stop()
