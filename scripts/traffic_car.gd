extends CharacterBody3D

const G = preload("res://scripts/geometry.gd")
var path: PackedVector3Array
var waypoint: int = 0
var kind: String = "car"
var speed: float = 0
var cruise_speed: float = 8
var manager: Node
var stopped_for: float = 0
var dwell: float = 0
var bus_stop_done: bool = false
var length: float = 4.4
var width: float = 1.85
var waiting_reason: String = ""
var travelled: float = 0
var last_position: Vector3
var movements: Array = []
var junction: Dictionary = {}
var junction_granted: bool = false
var junction_arrival: float = INF

# Vehicle class dynamics & mixed traffic profiles
var accel_rate: float = 1.7
var brake_rate: float = 4.5
var min_gap: float = 2.5
var lateral_bias: float = 0.0
var bay_lateral_offset: float = 0.0
var avoidance_offset: float = 0.0
var merging_cooldown: float = 0.0

# Positional 3D audio
var engine_audio: AudioStreamPlayer3D
var horn_audio: AudioStreamPlayer3D
var horn_timer: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4 | 8
	floor_snap_length = 0.4
	length = 8.6 if kind == "bus" else 2.8 if kind == "cng" else 4.4
	width = 2.45 if kind == "bus" else 1.4 if kind == "cng" else 1.85

	# Differentiated vehicle dynamics
	if kind == "cng":
		accel_rate = 2.6 # Snappy small engine launch
		brake_rate = 5.2
		min_gap = 1.8 # Tighter urban headway
		lateral_bias = 0.40 # Hug the left road curb in left-hand traffic
	elif kind == "bus":
		accel_rate = 0.95 # Heavy diesel bus inertia
		brake_rate = 3.6
		min_gap = 3.6 # Larger safety buffer
		lateral_bias = 0.0
	else:
		accel_rate = 1.7
		brake_rate = 4.5
		min_gap = 2.5
		lateral_bias = 0.0

	var shape = CollisionShape3D.new()
	var bounds = BoxShape3D.new()
	bounds.size = Vector3(width, 1.3, length)
	shape.shape = bounds
	shape.position.y = 0.72
	add_child(shape)
	var palette: Array[Color] = [Color("c3c8c9"), Color("e5e0d2"), Color("3e555d"), Color("704d3d"), Color("26313c")]
	var color: Color = Color("26694d") if kind == "cng" else Color("ab623f") if kind == "bus" else palette[get_index() % palette.size()]
	G.vehicle(self, kind, color)
	position = path[waypoint] + Vector3.UP * 0.1
	var direction: Vector3 = path[(waypoint+1) % path.size()] - path[waypoint]
	rotation.y = atan2(-direction.x, -direction.z)
	last_position = position
	_setup_audio()

func _setup_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	engine_audio = AudioStreamPlayer3D.new()
	var stream_path: String = "res://assets/audio/traffic_bus.wav" if kind == "bus" else "res://assets/audio/traffic_cng.wav" if kind == "cng" else "res://assets/audio/engine.wav"
	var st: AudioStreamWAV = load(stream_path)
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = 44100
	engine_audio.stream = st
	engine_audio.volume_db = -32 if kind == "car" else -28 if kind == "cng" else -24
	engine_audio.max_distance = 28 if kind == "car" else 26 if kind == "cng" else 36
	engine_audio.bus = "Traffic"
	add_child(engine_audio)
	engine_audio.play()

	horn_audio = AudioStreamPlayer3D.new()
	horn_audio.stream = load("res://assets/audio/traffic_horn.wav")
	horn_audio.volume_db = -24
	horn_audio.max_distance = 32
	horn_audio.bus = "Traffic"
	add_child(horn_audio)
	horn_timer = randf_range(12.0, 30.0)

func _physics_process(delta: float) -> void:
	if manager.paused_sim:
		if is_instance_valid(engine_audio) and engine_audio.playing:
			engine_audio.stop()
		return
	if is_instance_valid(engine_audio):
		if not engine_audio.playing:
			engine_audio.play()
		engine_audio.pitch_scale = 0.85 + clampf(speed / 14.0, 0.0, 0.5)

	if is_instance_valid(horn_audio):
		horn_timer -= delta
		if horn_timer <= 0:
			horn_timer = randf_range(18.0, 42.0)
			if waiting_reason in ["queue", "signal"] and is_instance_valid(manager.player):
				if global_position.distance_to(manager.player.global_position) < 32.0:
					horn_audio.pitch_scale = randf_range(0.95, 1.08)
					horn_audio.play()

	var target: Vector3 = path[waypoint]
	var planar = Vector3(position.x, 0, position.z)
	var skipped: int = 0
	while planar.distance_to(target) < 3 and skipped < 12:
		waypoint = (waypoint + 1) % path.size()
		target = path[waypoint]
		skipped += 1
		if waypoint == 0:
			bus_stop_done = false
			bay_lateral_offset = 0.0
			merging_cooldown = 0.0

	var direction: Vector3 = (target - planar).normalized()
	# Apply lateral lane offset (CNG curb-hugging, Bus bay pull-in, obstacle avoidance, and multi-lane positioning)
	var left_vec: Vector3 = Vector3(direction.z, 0, -direction.x)
	var multilane_offset: float = 0.0
	if kind == "car" and absf(position.x - 90.0) < 8.0:
		multilane_offset = -0.30
	var total_offset: float = lateral_bias + bay_lateral_offset + multilane_offset + avoidance_offset
	if total_offset != 0.0:
		target += left_vec * total_offset
		direction = (target - planar).normalized()

	var desired: float = cruise_speed
	waiting_reason = ""
	desired = minf(desired, manager.junction_speed_limit(self))

	# Dynamic road obstacle avoidance (v1.4)
	var target_avoidance: float = 0.0
	if is_instance_valid(manager) and manager.has_method("get_active_obstacles"):
		var fwd: Vector3 = -global_transform.basis.z
		for obs in manager.get_active_obstacles():
			var obs_pos: Vector3 = obs.get("position", Vector3.ZERO)
			var rel: Vector3 = obs_pos - global_position
			var ahead: float = rel.dot(fwd)
			var lat: float = rel.dot(global_transform.basis.x)
			var r: float = obs.get("radius", 1.8)
			if ahead > 0.5 and ahead < 16.0 and absf(lat) < (r + width * 0.5):
				target_avoidance = obs.get("bypass_offset", 0.5)
				if ahead < 6.0:
					desired = minf(desired, 5.0)
				break
	avoidance_offset = move_toward(avoidance_offset, target_avoidance, delta * 2.2)

	# Scan footprints rather than injecting random traffic obstacles.
	var forward: Vector3 = -global_transform.basis.z
	for other in manager.road_users:
		if other == self or not is_instance_valid(other):
			continue
		var relative: Vector3 = other.global_position - global_position
		var ahead: float = relative.dot(forward)
		var lateral: float = absf(relative.dot(global_transform.basis.x))
		var other_length: float = other.length if other.get("length") != null else 4.4
		var gap: float = ahead - length * 0.5 - other_length * 0.5
		var corridor_width: float = 2.2 if kind == "bus" else 1.8
		if ahead > 0 and gap < 22 and lateral < corridor_width:
			var lead_speed: float = maxf(0, other.speed)
			var safe: float = clampf((gap - min_gap) / (1.8 if kind == "bus" else 1.3), 0, cruise_speed)
			if gap > min_gap * 2.0:
				safe = minf(safe, lead_speed + (gap - min_gap * 2.0) * 0.35)
			if safe < desired:
				desired = safe
				waiting_reason = "queue"

	# Bus Stop pull-in and re-entry merge protocol
	if kind == "bus":
		if not bus_stop_done and absf(position.x + 93.2) < 2.5 and position.z > 24 and position.z < 45:
			# Pull laterally into marked bus boarding bay
			bay_lateral_offset = move_toward(bay_lateral_offset, 0.70, delta * 1.2)
			if absf(position.z - 31.5) < 2.5:
				bus_stop_done = true
				dwell = 7.0
		elif dwell <= 0:
			# Dwell finished: check approaching corridor traffic before merging out
			if bay_lateral_offset > 0.0:
				var lane_clear: bool = true
				for other in manager.road_users:
					if other == self or not is_instance_valid(other):
						continue
					var rel: Vector3 = other.global_position - global_position
					var dist: float = rel.dot(forward)
					var lat: float = absf(rel.dot(global_transform.basis.x))
					if dist < 0 and dist > -10.0 and lat < 2.2 and other.speed > 1.5:
						lane_clear = false
						break
				if not lane_clear and merging_cooldown < 3.0:
					merging_cooldown += delta
					desired = minf(desired, 0.8)
					waiting_reason = "merging"
				else:
					bay_lateral_offset = move_toward(bay_lateral_offset, 0.0, delta * 0.6)

	if dwell > 0:
		dwell -= delta
		desired = 0
		waiting_reason = "passengers boarding"

	# Localized pedestrian crowd yielding heuristic
	for ped in manager.pedestrians:
		if not is_instance_valid(ped):
			continue
		var relative: Vector3 = ped.position - position
		var ahead: float = relative.dot(forward)
		var lateral: float = absf(relative.dot(global_transform.basis.x))
		var is_crossing_crowd: bool = ped.get_meta("crossing_group", false)
		var safe_ahead: float = length * 0.5 + (7.5 if is_crossing_crowd else 5.5)
		if ahead > 0 and ahead < safe_ahead and lateral < 2.2:
			desired = 0
			waiting_reason = "pedestrian"
			break

	speed = move_toward(speed, desired, delta * (brake_rate if desired < speed else accel_rate))
	if direction.length_squared() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 3.5))
	velocity = -global_transform.basis.z * speed
	velocity.y = -2
	move_and_slide()

	for i in range(get_slide_collision_count()):
		if absf(get_slide_collision(i).get_normal().y) < 0.5:
			speed = 0
			waiting_reason = "yielding"
	stopped_for = stopped_for + delta if speed < 0.4 else 0
	travelled += position.distance_to(last_position)
	last_position = position

func _exit_tree() -> void:
	if is_instance_valid(engine_audio):
		engine_audio.stop()
	if is_instance_valid(horn_audio):
		horn_audio.stop()
