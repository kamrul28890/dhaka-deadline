extends Node3D

const Network = preload("res://scripts/road_network.gd")
const District = preload("res://scripts/district.gd")
const PlayerCar = preload("res://scripts/player_car.gd")
const Settings = preload("res://scripts/settings_manager.gd")
const Missions = preload("res://scripts/mission_manager.gd")
const TrafficCar = preload("res://scripts/traffic_car.gd")
const Hud = preload("res://scripts/hud.gd")
const PedestrianVisual = preload("res://scripts/pedestrian_visual.gd")
const CorridorExpressway = preload("res://scripts/corridor_expressway.gd")
const DynamicWeather = preload("res://scripts/dynamic_weather.gd")
const CollisionConsequences = preload("res://scripts/collision_consequences.gd")
var network = Network.new()
var district: Node3D
var expressway: Node3D
var weather_system: Node3D
var collision_consequences: Node3D
var player: CharacterBody3D
var traffic: Array = []
var pedestrians: Array = []
var road_users: Array = []
var hud: CanvasLayer
var paused_sim: bool = true
var started: bool = false
var finished: bool = false
var free_drive: bool = false
var selected_route: String = "north"
var elapsed: float = 0
var sim_time: float = 0
var signal_time: float = 0
var last_crossing_cycle: int = -1
var pedestrian_crossings_completed: int = 0
var deadline: float = 120
var arrival_point: Vector3 = Vector3(95.2, 0, -66)
var arrival_hold: float = 0
var red_lights: int = 0
var recoveries: int = 0
var speeding_seconds: float = 0
var last_junction: String = ""
var fixed_seed: int = 646301
var crossing: bool = false
var simulation_frames: int = 0
var ambience_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var active_mission_id: String = "interview"
var active_mission: Dictionary = {}
var radio_player: AudioStreamPlayer
var triggered_cues: Dictionary = {}
var congestion_radio_cooldown: float = 0.0
var last_reported_congestion_link: String = ""
var stopped_at_red_time: float = 0.0

# Dynamic traffic events & police override (v1.4)
var dynamic_obstacles: Dictionary = {}
var police_override_active: bool = false
var police_override_axis: String = "NS"

func register_traffic_obstacle(id: String, obstacle: Dictionary) -> void:
	dynamic_obstacles[id] = obstacle

func unregister_traffic_obstacle(id: String) -> void:
	dynamic_obstacles.erase(id)

func get_active_obstacles() -> Array:
	return dynamic_obstacles.values()

func set_police_override(active: bool, forced_axis: String = "NS") -> void:
	police_override_active = active
	police_override_axis = forced_axis
	if is_instance_valid(district):
		var officer = district.get_node_or_null("TrafficPoliceOfficer")
		if is_instance_valid(officer) and officer.has_method("set_signaling_state"):
			officer.set_signaling_state("stop" if active and forced_axis != "NS" else ("wave" if active else "idle"))

func _ready() -> void:
	Settings.setup_audio_buses()
	var initial_settings: Dictionary = Settings.load_settings()
	Settings.apply_all(initial_settings, get_viewport())
	_register_inputs()
	district = District.new()
	district.manager = self
	add_child(district)
	district.build()
	expressway = CorridorExpressway.new()
	add_child(expressway)
	expressway.build_corridor()
	player = PlayerCar.new()
	player.manager = self
	add_child(player)
	weather_system = DynamicWeather.new()
	weather_system.target_player = player
	add_child(weather_system)
	collision_consequences = CollisionConsequences.new()
	collision_consequences.target_player = player
	collision_consequences.manager = self
	add_child(collision_consequences)
	_spawn_traffic()
	_spawn_pedestrians()
	road_users = traffic.duplicate()
	road_users.append(player)
	hud = Hud.new()
	hud.manager = self
	add_child(hud)
	district.update_signals("NS", false)
	active_mission = Missions.get_mission(active_mission_id)
	arrival_point = active_mission.arrival_point
	deadline = active_mission.deadline_seconds
	district.set_atmosphere(active_mission.time_of_day)
	district.update_destination(active_mission.destination_marker)
	_setup_radio()
	_setup_ambience()
	var w = active_mission.get("weather", "clear")
	district.set_weather(w)
	if is_instance_valid(weather_system):
		weather_system.set_weather(w)
	if w == "monsoon":
		player.set_wipers(true)
		if is_instance_valid(rain_player):
			rain_player.play()

	# Dynamic road obstacles (v1.4)
	register_traffic_obstacle("work_zone", {"position": Vector3(-20.0, 0, -106.2), "bypass_offset": 0.5, "radius": 1.4})
	register_traffic_obstacle("breakdown", {"position": Vector3(-96.5, 0, -25.0), "bypass_offset": -0.5, "radius": 1.4})

	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--smoke" in args:
		start_mission(true)
		player.position = Vector3(-145, 0.1, 60)
	if "--autodrive" in args:
		start_mission(false)
	if "--capture" in args:
		_capture_after_frames()
	if "--gallery" in args:
		_capture_gallery()
	if "--smoke" in args:
		_run_smoke()
	if "--autodrive" in args:
		_run_autodrive()

func _register_inputs() -> void:
	var keys: Dictionary = {"accelerate": [KEY_W, KEY_UP], "brake": [KEY_S, KEY_DOWN],
		"steer_left": [KEY_A, KEY_LEFT], "steer_right": [KEY_D, KEY_RIGHT],
		"reverse": [KEY_Q], "handbrake": [KEY_SPACE], "horn": [KEY_H],
		"camera": [KEY_C], "vehicle_cycle": [KEY_V], "headlights": [KEY_L], "wipers": [KEY_K], "reset": [KEY_R]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	# Deadzones for analog stick and triggers to prevent physical joystick drift
	InputMap.action_set_deadzone("steer_left", 0.2)
	InputMap.action_set_deadzone("steer_right", 0.2)
	InputMap.action_set_deadzone("accelerate", 0.15)
	InputMap.action_set_deadzone("brake", 0.15)

func _spawn_traffic() -> void:
	# Spaced initial footprints; fixed routes/seeds allow repeatable debugging.
	for loop_index in range(Network.LOOPS.size()):
		var path: PackedVector3Array = Network.loop_path(Network.LOOPS[loop_index])
		var count: int = 6 if loop_index < 2 else 3
		for i in range(count):
			var agent = TrafficCar.new()
			agent.path = path
			agent.movements = Network.loop_movements(Network.LOOPS[loop_index])
			agent.waypoint = (i * path.size() / count + 18 + loop_index*9) % path.size()
			agent.kind = "bus" if loop_index == 0 and i == 0 else "cng" if i % 3 == 2 else "car"
			agent.cruise_speed = 6.2 if agent.kind == "cng" else 7.2 if agent.kind == "bus" else 8.5 + (i%3)*0.5
			agent.manager = self
			traffic.append(agent)
			add_child(agent)

func _spawn_pedestrians() -> void:
	var ped_configs: Array[Dictionary] = [
		{"pos": Vector3(-101.8, 0.3, 10.5), "target": -78.0, "is_leader": true, "group": true, "variant": 0},
		{"pos": Vector3(-102.5, 0.3, 9.6), "target": -78.5, "is_leader": false, "group": true, "variant": 1},
		{"pos": Vector3(-102.2, 0.3, 11.4), "target": -77.8, "is_leader": false, "group": true, "variant": 2},
		{"pos": Vector3(-102.0, 0.3, 31.0), "target": 0.0, "is_leader": false, "group": false, "variant": 3},
		{"pos": Vector3(-102.5, 0.3, 56.5), "target": 0.0, "is_leader": false, "group": false, "variant": 4},
		{"pos": Vector3(-101.5, 0.3, -33.0), "target": 0.0, "is_leader": false, "group": false, "variant": 5},
		{"pos": Vector3(98.5, 0.3, -50.0), "target": 0.0, "is_leader": false, "group": false, "variant": 6},
		{"pos": Vector3(99.2, 0.3, -60.0), "target": 0.0, "is_leader": false, "group": false, "variant": 7},
		{"pos": Vector3(98.8, 0.3, 8.0), "target": 0.0, "is_leader": false, "group": false, "variant": 0},
		{"pos": Vector3(101.2, 0.3, 15.0), "target": 0.0, "is_leader": false, "group": false, "variant": 1},
		{"pos": Vector3(99.0, 0.3, -24.0), "target": 0.0, "is_leader": false, "group": false, "variant": 2},
		{"pos": Vector3(-98.2, 0.3, 16.0), "target": 0.0, "is_leader": false, "group": false, "variant": 3},
		{"pos": Vector3(-101.5, 0.3, -15.0), "target": 0.0, "is_leader": false, "group": false, "variant": 4},
		{"pos": Vector3(-78.5, 0.3, -10.0), "target": 0.0, "is_leader": false, "group": false, "variant": 5},
		{"pos": Vector3(81.5, 0.3, 35.0), "target": 0.0, "is_leader": false, "group": false, "variant": 6},
		{"pos": Vector3(98.5, 0.3, 45.0), "target": 0.0, "is_leader": false, "group": false, "variant": 7}
	]

	for i in range(ped_configs.size()):
		var cfg = ped_configs[i]
		var ped = CharacterBody3D.new()
		ped.collision_layer = 8
		ped.collision_mask = 1 | 2 | 4
		ped.set_meta("pedestrian", true)
		ped.set_meta("index", i)
		ped.position = cfg["pos"]
		ped.set_meta("crossing_target", cfg["target"])
		ped.set_meta("is_crossing_leader", cfg["is_leader"])
		ped.set_meta("crossing_group", cfg["group"])
		ped.set_meta("base_z", cfg["pos"].z)

		var shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.28
		capsule.height = 1.7
		shape.shape = capsule
		shape.position.y = 0.9
		ped.add_child(shape)
		add_child(ped)

		var visual = PedestrianVisual.new()
		visual.name = "PedestrianVisual"
		visual.manager = self
		visual.variant = cfg["variant"]
		ped.add_child(visual)
		pedestrians.append(ped)

func start_mission(explore: bool) -> void:
	free_drive = explore
	started = true
	finished = false
	paused_sim = false
	player.enabled = true
	triggered_cues.clear()
	stopped_at_red_time = 0.0
	if is_instance_valid(collision_consequences):
		collision_consequences.reset_damage()
	if active_mission.get("is_expressway", false):
		player.position = active_mission.get("spawn_point", Vector3(0, 3.2, 160))
		player.rotation = Vector3.ZERO
		if is_instance_valid(player.camera):
			player.camera.position = player.position + Vector3(1, 4.3, 9)
	if is_instance_valid(weather_system):
		weather_system.set_weather(active_mission.get("weather", "clear"))
	if not explore:
		district.show_route(selected_route)
		play_narrative_cue("start")
	hud.hide_menu()

func set_active_mission(mission_id: String) -> void:
	active_mission_id = mission_id
	active_mission = Missions.get_mission(mission_id)
	arrival_point = active_mission.arrival_point
	deadline = active_mission.deadline_seconds
	var w: String = active_mission.get("weather", "clear")
	if is_instance_valid(district):
		district.set_atmosphere(active_mission.time_of_day)
		district.update_destination(active_mission.destination_marker)
		district.set_weather(w)
	if is_instance_valid(weather_system):
		weather_system.set_weather(w)
	if is_instance_valid(player):
		player.set_headlights(active_mission.time_of_day == "evening")
		player.set_wipers(w == "monsoon")
	if is_instance_valid(rain_player):
		if w == "monsoon":
			if not rain_player.playing:
				rain_player.play()
		else:
			rain_player.stop()
	if is_instance_valid(hud):
		hud.update_mission_display()

func trigger_radio_cue(bn_text: String, en_text: String) -> void:
	play_radio_chime()
	if is_instance_valid(hud):
		hud.show_radio_dispatch(bn_text, en_text)

func play_narrative_cue(event_name: String) -> void:
	if free_drive or not started or finished:
		return
	if triggered_cues.has(event_name):
		return
	var cue: Dictionary = Missions.narrative_cue(active_mission_id, event_name)
	if cue.bn != "" or cue.en != "":
		triggered_cues[event_name] = true
		play_radio_chime()
		if is_instance_valid(hud):
			hud.show_radio_dispatch(cue.bn, cue.en)

func _check_congestion_radio_alerts() -> void:
	if free_drive or not started or finished or congestion_radio_cooldown > 0.0:
		return
	var estimates: Dictionary = route_estimates()
	var cur_est: Dictionary = estimates.get(selected_route, {})
	var cur_queue: int = cur_est.get("queue_count", 0)
	var alt_route: String = "middle" if selected_route == "north" else "north"
	var alt_est: Dictionary = estimates.get(alt_route, {})
	if cur_queue >= 4 and alt_est.get("seconds", INF) < cur_est.get("seconds", 0.0) - 6.0:
		_trigger_congestion_alert(selected_route, cur_queue)

func _trigger_congestion_alert(route_key: String, queue_count: int) -> void:
	var cur_name_bn: String = "উত্তর সড়কে" if route_key == "north" else "বাজার লিংকে"
	var cur_name_en: String = "North road" if route_key == "north" else "Market link"
	var alt_name_bn: String = "বাজার সড়ক" if route_key == "north" else "উত্তর সড়ক"
	var alt_name_en: String = "Market link" if route_key == "north" else "North road"
	play_radio_chime()
	if is_instance_valid(hud):
		hud.show_radio_dispatch(
			"সতর্কতা: %s তীব্র যানজট (%d গাড়ি)! %s ব্যবহার করতে [T] চাপুন।" % [cur_name_bn, queue_count, alt_name_bn],
			"ALERT: Heavy queue on %s (%d cars)! Press [T] for %s." % [cur_name_en, queue_count, alt_name_en]
		)
	congestion_radio_cooldown = 24.0

func _setup_radio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	radio_player = AudioStreamPlayer.new()
	var radio_stream: AudioStreamWAV = load("res://assets/audio/radio_chime.wav")
	radio_player.stream = radio_stream
	radio_player.volume_db = -6
	radio_player.bus = "SFX"
	add_child(radio_player)

func play_radio_chime() -> void:
	if is_instance_valid(radio_player) and not radio_player.playing:
		radio_player.play()

func restart_mission() -> void:
	get_tree().reload_current_scene()

func _setup_ambience() -> void:
	ambience_player = AudioStreamPlayer.new()
	var amb_stream: AudioStreamWAV = load("res://assets/audio/ambience.wav")
	amb_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	amb_stream.loop_begin = 0
	amb_stream.loop_end = 132300
	ambience_player.stream = amb_stream
	ambience_player.volume_db = -22
	ambience_player.bus = "Ambience"
	add_child(ambience_player)
	ambience_player.play()

	rain_player = AudioStreamPlayer.new()
	var rain_stream: AudioStreamWAV = load("res://assets/audio/rain_loop.wav")
	rain_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rain_stream.loop_begin = 0
	rain_stream.loop_end = 88200
	rain_player.stream = rain_stream
	rain_player.volume_db = -16
	rain_player.bus = "Ambience"
	add_child(rain_player)

func toggle_pause() -> void:
	if not started or finished:
		return
	paused_sim = not paused_sim
	player.enabled = not paused_sim
	if is_instance_valid(ambience_player):
		if paused_sim:
			ambience_player.stop()
		else:
			ambience_player.play()
	if is_instance_valid(rain_player):
		if paused_sim:
			rain_player.stop()
		elif active_mission.get("weather", "clear") == "monsoon":
			rain_player.play()
	if paused_sim:
		hud.show_pause()
	else:
		hud.hide_menu()

func _exit_tree() -> void:
	if is_instance_valid(ambience_player):
		ambience_player.stop()
	if is_instance_valid(rain_player):
		rain_player.stop()

func recover_player() -> void:
	recoveries += 1
	elapsed += 15
	player.reset_car()
	# Recovery is an explicit player action, never a hidden traffic-AI teleport.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
		elif event.keycode == KEY_M:
			hud.map_visible = not hud.map_visible
		elif event.keycode == KEY_K:
			if is_instance_valid(player):
				player.toggle_wipers()
		elif event.keycode == KEY_F3:
			hud.debug_label.visible = not hud.debug_label.visible
		elif event.keycode == KEY_T:
			toggle_route()

func _physics_process(delta: float) -> void:
	if paused_sim:
		return
	simulation_frames += 1
	sim_time += delta
	if not crossing:
		signal_time += delta
	if started and not finished:
		elapsed += delta
		congestion_radio_cooldown = maxf(0.0, congestion_radio_cooldown - delta)
		if absf(player.speed) > 11.12:
			speeding_seconds += delta
		if not free_drive:
			if congestion_radio_cooldown <= 0.0:
				_check_congestion_radio_alerts()
			var dist_to_arr: float = player.position.distance_to(arrival_point)
			if dist_to_arr < 40.0:
				play_narrative_cue("near_goal")
			elif (deadline - elapsed) < 20.0 and (deadline - elapsed) > 0.0:
				play_narrative_cue("hurry_up")
			var limit: float = signal_speed_limit(player.position, -player.global_transform.basis.z, 4.4)
			if limit < 2.0 and absf(player.speed) < 0.5:
				stopped_at_red_time += delta
				if stopped_at_red_time > 1.5:
					play_narrative_cue("signal_wait")
			else:
				stopped_at_red_time = 0.0
	var axis: String = active_signal_axis()
	var phase: float = fmod(signal_time, 40)
	district.update_signals(axis, (phase >= 14 and phase < 17) or (phase >= 33 and phase < 36))
	_update_pedestrians(delta)
	_check_player_signals()

	# Cabin acoustic interior damping
	if is_instance_valid(player) and player.get("cabin_acoustic_damping") != null:
		var damped: bool = player.cabin_acoustic_damping
		if is_instance_valid(ambience_player):
			var target_vol = -28.0 if damped else -22.0
			ambience_player.volume_db = lerpf(ambience_player.volume_db, target_vol, delta * 5.0)
		if is_instance_valid(rain_player):
			var target_rain_vol = -22.0 if damped else -16.0
			rain_player.volume_db = lerpf(rain_player.volume_db, target_rain_vol, delta * 5.0)

	if not free_drive and player.position.distance_to(arrival_point) < 4.5 and absf(player.speed) < 0.5:
		arrival_hold += delta
		if arrival_hold >= 2:
			finish_mission(false)
	else:
		arrival_hold = 0

func active_signal_axis() -> String:
	if crossing:
		return "NONE"
	if police_override_active:
		return police_override_axis
	var phase: float = fmod(signal_time, 40)
	if phase < 17:
		return "NS"
	if phase >= 19 and phase < 36:
		return "EW"
	return "NONE"

func signal_description() -> String:
	var axis: String = active_signal_axis()
	return "NORTH / SOUTH GREEN" if axis == "NS" else "EAST / WEST GREEN" if axis == "EW" else "ALL RED — CROSSING"

func signal_speed_limit(pos: Vector3, direction: Vector3, length: float) -> float:
	var phase: float = fmod(signal_time, 40)
	var axis: String = active_signal_axis()
	var amber: bool = (phase >= 14 and phase < 17) or (phase >= 33 and phase < 36)
	for key in ["W", "E"]:
		var center: Vector3 = Network.NODES[key]
		var relative: Vector3 = center-pos
		var ahead: float = relative.dot(direction)
		var lateral: float = absf(relative.dot(Network.left_of(direction)))
		if ahead > 0 and ahead < 38 and lateral < 7:
			var approach: String = "NS" if absf(direction.z) > absf(direction.x) else "EW"
			if axis != approach or amber:
				var to_stop: float = ahead-13.5-length*0.5
				if ahead > 10:
					return clampf(to_stop * 0.65, 0, 12)
	return 25

func _junction_movement(agent: Node3D) -> Dictionary:
	if not agent.junction.is_empty():
		var current: Dictionary = agent.junction
		if (agent.position-current.center).dot(current.outgoing) > 13.5+agent.length*0.5:
			agent.junction = {}
			agent.junction_granted = false
			agent.junction_arrival = INF
	if agent.junction.is_empty():
		for movement in agent.movements:
			var relative: Vector3 = movement.center-agent.position
			var ahead: float = relative.dot(movement.incoming)
			if ahead > 0 and ahead < 38 and absf(relative.dot(Network.left_of(movement.incoming))) < 7:
				agent.junction = movement
				break
	if not agent.junction.is_empty() and _junction_distance(agent, agent.junction) < 8 and is_inf(agent.junction_arrival):
		agent.junction_arrival = sim_time
	return agent.junction

func _junction_distance(agent: Node3D, movement: Dictionary) -> float:
	return (movement.center-agent.position).dot(movement.incoming)-13.5-agent.length*0.5

func _exit_clear(agent: Node3D, movement: Dictionary) -> bool:
	var exit_lane: Vector3 = movement.center+Network.left_of(movement.outgoing)*3.2
	for other in road_users:
		if other == agent or not is_instance_valid(other):
			continue
		var relative: Vector3 = other.position-exit_lane
		var other_length: float = other.length if other.get("length") != null else 4.4
		var other_width: float = other.width if other.get("width") != null else 1.85
		var along: float = absf(other.basis.z.dot(movement.outgoing))*other_length*0.5+absf(other.basis.x.dot(movement.outgoing))*other_width*0.5
		var across: float = absf(other.basis.x.dot(movement.outgoing))*other_length*0.5+absf(other.basis.z.dot(movement.outgoing))*other_width*0.5
		var ahead: float = relative.dot(movement.outgoing)
		if ahead > 0 and ahead-along < 13.5+agent.length+2.5 and absf(relative.dot(Network.left_of(movement.outgoing))) < agent.width*0.5+across+0.5:
			return false
	return true

func junction_speed_limit(agent: Node3D) -> float:
	var movement: Dictionary = _junction_movement(agent)
	if movement.is_empty():
		return signal_speed_limit(agent.position, -agent.basis.z, agent.length)
	var distance: float = _junction_distance(agent, movement)
	# A vehicle already across its stop line must finish clearing, even after amber.
	if distance < -0.1:
		agent.junction_granted = true
		return 25
	var signal_limit: float = signal_speed_limit(agent.position, movement.incoming, agent.length)
	if signal_limit < 25:
		agent.junction_granted = false
		agent.waiting_reason = "signal"
		return signal_limit
	var stop_limit: float = clampf(distance*0.65, 0, agent.cruise_speed)
	if not _exit_clear(agent, movement):
		agent.junction_granted = false
		agent.waiting_reason = "blocked exit"
		return stop_limit
	var relative: Vector3 = player.position-movement.center
	if absf(relative.x) < 23 and absf(relative.z) < 23:
		var player_center = Vector3(player.position.x, 0, player.position.z)
		var player_axle: Vector3 = player.basis.z*1.25
		for i in range(movement.corridor.size()-1):
			var nearest: PackedVector3Array = Geometry3D.get_closest_points_between_segments(player_center-player_axle, player_center+player_axle, movement.corridor[i], movement.corridor[i+1])
			if nearest[0].distance_to(nearest[1]) < (1.85+agent.width)*0.5+0.5:
				agent.junction_granted = false
				agent.waiting_reason = "player in junction"
				return stop_limit
	if agent.junction_granted:
		return 25
	var right_turn: bool = movement.incoming.cross(movement.outgoing).y < -0.2
	var turn_priority: bool = agent.stopped_for >= 40 and distance < 8
	for other in traffic:
		if other == agent:
			continue
		var other_movement: Dictionary = _junction_movement(other)
		if other_movement.is_empty() or not Network.movements_conflict(movement, other_movement):
			continue
		if other.junction_granted:
			agent.waiting_reason = "junction occupied"
			return stop_limit
		if signal_speed_limit(other.position, other_movement.incoming, other.length) < 25 or not _exit_clear(other, other_movement):
			continue
		var opposing: bool = movement.incoming.dot(other_movement.incoming) < -0.9
		var other_right: bool = other_movement.incoming.cross(other_movement.outgoing).y < -0.2
		var other_distance: float = _junction_distance(other, other_movement)
		# After a full cycle waiting, leave a courtesy gap once committed traffic clears.
		if opposing and right_turn and not other_right and not turn_priority and other_distance < maxf(18, other.speed*3):
			agent.waiting_reason = "turning priority"
			return stop_limit
		if opposing and not right_turn and other_right:
			if other.stopped_for >= 40 and other_distance < 8:
				agent.waiting_reason = "turn queue"
				return stop_limit
			continue
		if opposing and right_turn and turn_priority:
			continue
		if distance < 8 and other_distance < 8 and (other.junction_arrival < agent.junction_arrival or (other.junction_arrival == agent.junction_arrival and other.get_index() < agent.get_index())):
			agent.waiting_reason = "give way"
			return stop_limit
	if distance < 8:
		agent.junction_granted = true
	return 25

func _update_pedestrians(delta: float) -> void:
	# Coordinated crowd crossing and localized corridor sidewalk crowds
	var phase: float = fmod(signal_time, 40)
	if phase >= 17 and phase < 19 and not crossing and int(signal_time/40) != last_crossing_cycle:
		var safe_gap: bool = true
		for vehicle in road_users:
			var vehicle_length: float = vehicle.length if vehicle.get("length") != null else 4.4
			if absf(vehicle.position.z-10.5) < vehicle_length*0.5+1.0 and absf(vehicle.position.x+90) < 10:
				safe_gap = false
		crossing = safe_gap
		if crossing:
			last_crossing_cycle = int(signal_time/40)

	for ped in pedestrians:
		var i: int = ped.get_meta("index")
		var is_group: bool = ped.get_meta("crossing_group", false)
		if is_group:
			if crossing:
				var target_x: float = ped.get_meta("crossing_target")
				var base_z: float = ped.get_meta("base_z", 10.5)
				var target: Vector3 = Vector3(target_x, ped.position.y, base_z)
				var cross_speed: float = 1.25 if i == 0 else (1.18 if i == 1 else 1.28)
				ped.velocity = (target-ped.position).normalized() * cross_speed
				for vehicle in road_users:
					if vehicle.position.distance_to(ped.position) < 4 and absf(vehicle.speed) > 1:
						ped.velocity = Vector3.ZERO
				if i == 0 and ped.position.distance_to(target) < 0.5:
					crossing = false
					pedestrian_crossings_completed += 1
					var next_t0: float = -101.8 if target_x > -90 else -78.0
					ped.set_meta("crossing_target", next_t0)
					if pedestrians.size() > 1:
						pedestrians[1].set_meta("crossing_target", -102.5 if target_x > -90 else -78.5)
					if pedestrians.size() > 2:
						pedestrians[2].set_meta("crossing_target", -102.2 if target_x > -90 else -77.8)
			else:
				ped.velocity = Vector3.ZERO
		else:
			var base_z: float = ped.get_meta("base_z", 12.0)
			var sway: float = 4.0 if i in [3, 4, 8, 11] else 6.5
			var target_z: float = base_z + sin(sim_time*0.11 + i*1.3)*sway
			ped.velocity = Vector3(0, 0, signf(target_z-ped.position.z)*0.62) if absf(target_z-ped.position.z) > 0.35 else Vector3.ZERO
		ped.velocity.y = -2
		ped.move_and_slide()

func _check_player_signals() -> void:
	var current: String = ""
	for key in ["W", "E"]:
		var center: Vector3 = Network.NODES[key]
		if absf(player.position.x-center.x) < 10 and absf(player.position.z-center.z) < 10:
			current = key
			if last_junction != key and absf(player.speed) > 0.5:
				var direction: Vector3 = -player.global_transform.basis.z
				var approach: String = "NS" if absf(direction.z) > absf(direction.x) else "EW"
				if approach != active_signal_axis():
					red_lights += 1
	if last_junction != "" and current == "":
		play_narrative_cue("junction_clear")
	last_junction = current

func on_collision(collider: Object) -> void:
	if collider != null and collider.has_meta("pedestrian"):
		finish_mission(true)

func queue_count() -> int:
	var count: int = 0
	for agent in traffic:
		if agent.stopped_for > 1:
			count += 1
	return count

func switch_route(new_route: String) -> void:
	if selected_route == new_route:
		return
	selected_route = new_route
	if started and not free_drive:
		district.show_route(selected_route)

func toggle_route() -> void:
	var next_route: String = "middle" if selected_route == "north" else "north"
	switch_route(next_route)

func route_estimates() -> Dictionary:
	var signal_ctx: Dictionary = {
		"phase": fmod(signal_time, 40),
		"signal_time": signal_time,
		"active_axis": active_signal_axis(),
		"crossing": crossing,
		"obstacles": get_active_obstacles()
	}
	return Network.dynamic_route_estimates(player.position, arrival_point, traffic, signal_ctx)

func finish_mission(failed: bool) -> void:
	if finished:
		return
	finished = true
	paused_sim = true
	player.enabled = false
	var result: Dictionary = Missions.calculate_score(
		active_mission_id, elapsed, player.collision_count, red_lights, recoveries, speeding_seconds, failed
	)
	var Career = preload("res://scripts/career_manager.gd")
	var v_type: String = player.get("vehicle_type") if is_instance_valid(player) else "car"
	var fare_earned: float = player.get("fare_taka") if (is_instance_valid(player) and v_type == "cng") else 0.0
	var dist: float = player.get("distance_driven") if is_instance_valid(player) else 0.0
	Career.record_trip(active_mission_id, v_type, dist, result.total_score, result.grade, fare_earned)
	hud.show_results(result)
	_save_report("last_journey.json", result)

func _finish_mission(failed: bool = false) -> void:
	finish_mission(failed)

func _save_report(filename: String, data: Dictionary) -> void:
	var diagnostic: bool = DisplayServer.get_name() == "headless" or "--gallery" in OS.get_cmdline_user_args()
	var file = FileAccess.open(_artifact_path(filename) if diagnostic else "user://"+filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))

func _capture_after_frames() -> void:
	for i in range(100):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = _artifact_path("first-look.png")
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", path)
	get_tree().quit()

func _capture_gallery() -> void:
	for i in range(30):
		await get_tree().process_frame
	await _save_screenshot("first-look.png")
	start_mission(false)
	Input.action_press("accelerate")
	for i in range(40):
		await get_tree().physics_frame
	await _save_screenshot("gameplay.png")
	Input.action_release("accelerate")
	var camera_key = InputEventAction.new()
	camera_key.action = "camera"
	camera_key.pressed = true
	player._unhandled_input(camera_key)
	player._unhandled_input(camera_key)
	for i in range(10):
		await get_tree().physics_frame
	await _save_screenshot("cabin.png")
	player._unhandled_input(camera_key)
	for i in range(10):
		await get_tree().physics_frame
	toggle_pause()
	await _save_screenshot("pause.png")
	toggle_pause()
	player.position = Vector3(-93.2,-0.069,17)
	player.speed = 0
	signal_time = 22
	for i in range(15):
		await get_tree().physics_frame
	await _save_screenshot("junction.png")
	await _capture_street_art()
	player.position = arrival_point
	player.speed = 0
	for i in range(130):
		await get_tree().physics_frame
	await _save_screenshot("results.png")
	set_active_mission("monsoon")
	start_mission(false)
	for i in range(25):
		await get_tree().physics_frame
	await _save_screenshot("monsoon-rain.png")
	player._unhandled_input(camera_key)
	player._unhandled_input(camera_key)
	for i in range(20):
		await get_tree().physics_frame
	await _save_screenshot("monsoon-cabin.png")
	print("GALLERY_COMPLETE")
	get_tree().quit()

func _capture_street_art() -> void:
	toggle_pause()
	player.set_physics_process(false)
	hud.visible = false
	var camera_transform: Transform3D = player.camera.global_transform
	var bus_transform: Transform3D = traffic[0].transform
	var cng_transform: Transform3D = traffic[2].transform
	traffic[0].position = Vector3(-93.2,-0.089,34)
	traffic[0].rotation.y = 0
	traffic[2].position = Vector3(-86.8,-0.089,49)
	traffic[2].rotation.y = PI
	player.position = Vector3(-145,0.1,60)
	for view in [
		["street-detail.png",Vector3(-99,1.9,50),Vector3(-110,2,38)],
		["bus-detail.png",Vector3(-98,2.4,24),Vector3(-93.2,1.4,34)],
		["cng-detail.png",Vector3(-83,1.6,58),Vector3(-86.8,0.9,49)],
		["fob-detail.png",Vector3(-93.2,1.8,-18),Vector3(-90,4.8,-35)],
		["metro-station.png",Vector3(86,2.2,18),Vector3(104,8.5,5)],
		["saarc-fountain.png",Vector3(93,2.0,84),Vector3(101.5,2.5,101.5)],
		["crossing-crowd.png",Vector3(-90,1.8,19),Vector3(-92,1.1,10.5)],
		["tea-stall.png",Vector3(-97.5,1.8,51.5),Vector3(-100.5,1.3,48.0)],
		["traffic-police.png",Vector3(-95.5,1.8,8.0),Vector3(-98.0,1.4,5.0)],
		["road-work.png",Vector3(-15.0,1.9,-103.5),Vector3(-20.0,1.1,-106.2)],
		["breakdown-detail.png",Vector3(-93.0,1.8,-19.0),Vector3(-96.5,1.2,-25.0)]]:
		player.camera.position = view[1]
		player.camera.look_at(view[2])
		await _save_screenshot(view[0])
	traffic[0].transform = bus_transform
	traffic[2].transform = cng_transform
	player.camera.global_transform = camera_transform
	player.set_physics_process(true)
	hud.visible = true
	toggle_pause()

func _save_screenshot(filename: String) -> void:
	# Allow queued UI layout changes to complete before capturing the rendered viewport.
	for i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = _artifact_path(filename)
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", path)

func _artifact_path(filename: String) -> String:
	var base: String = "res://artifacts/" if OS.has_feature("editor") else "user://artifacts/"
	var folder: String = ProjectSettings.globalize_path(base)
	DirAccess.make_dir_recursive_absolute(folder)
	return folder.path_join(filename)

func _run_smoke() -> void:
	# Fixed physics steps exercise signals, queues and movement independently of FPS.
	var peak_queue: int = 0
	var initial_bus: Vector3 = traffic[0].position
	var had_bus_dwell: bool = false
	var had_bus_release: bool = false
	var signal_axes: Dictionary = {}
	var longest_wait: float = 0
	for i in range(7200):
		await get_tree().physics_frame
		peak_queue = maxi(peak_queue, queue_count())
		signal_axes[active_signal_axis()] = true
		for agent in traffic:
			longest_wait = maxf(longest_wait, agent.stopped_for)
		if traffic[0].dwell > 0:
			had_bus_dwell = true
		if had_bus_dwell and traffic[0].dwell <= 0 and traffic[0].speed > 1:
			had_bus_release = true
	var total_travel: float = 0
	var finite: bool = true
	var agent_states: Array = []
	for agent in traffic:
		total_travel += agent.travelled
		finite = finite and agent.position.is_finite() and absf(agent.position.y) < 2
		agent_states.append({"kind": agent.kind, "position": str(agent.position), "wait": agent.stopped_for, "reason": agent.waiting_reason, "waypoint": agent.waypoint})
	var report: Dictionary = {"seed": fixed_seed, "steps": 7200, "elapsed": sim_time, "agents": traffic.size(), "peak_queue": peak_queue,
		"bus_pickup": had_bus_dwell, "bus_released": had_bus_release, "signal_axes": signal_axes.keys(),
		"traffic_distance_metres": total_travel, "finite_grounded_positions": finite,
		"bus_displacement": initial_bus.distance_to(traffic[0].position), "agent_states": agent_states,
		"pedestrian_position": str(pedestrians[0].position), "crossing_active": crossing,
		"pedestrian_crossings_completed": pedestrian_crossings_completed, "longest_wait_seconds": longest_wait}
	var file = FileAccess.open(_artifact_path("smoke.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("SMOKE_REPORT ", JSON.stringify(report))
	get_tree().quit(0 if finite and total_travel > 500 and signal_axes.size() == 3 and peak_queue > 0 and had_bus_release and pedestrian_crossings_completed > 0 and longest_wait < 75 else 1)

func _run_autodrive() -> void:
	# Integration probe follows north-road waypoints using the real input actions.
	var route: Array[Vector3] = [Vector3(-93.2, 0, -83), Vector3(-92, 0, -94), Vector3(-85, 0, -102), Vector3(-74, 0, -103.2), Vector3(75, 0, -103.2), Vector3(88, 0, -100), Vector3(93.2, 0, -91), Vector3(93.2, 0, -73), Vector3(95.2, 0, -66)]
	var index: int = 0
	for i in range(12000):
		await get_tree().physics_frame
		var target: Vector3 = route[index]
		var pos: Vector3 = Vector3(player.position.x, 0, player.position.z)
		var gap: float = pos.distance_to(target)
		if gap < (8 if index < route.size()-1 else 3) and index < route.size()-1:
			index += 1
		var direction: Vector3 = (route[index]-pos).normalized()
		var error: float = wrapf(atan2(-direction.x, -direction.z)-player.rotation.y, -PI, PI)
		var steer: float = clampf(-error*2.5, -1, 1)
		Input.action_press("steer_right", maxf(0, steer))
		Input.action_press("steer_left", maxf(0, -steer))
		var target_speed: float = 5 if absf(error) > 0.25 else 8
		target_speed = minf(target_speed, signal_speed_limit(player.position, -player.global_transform.basis.z, 4.4))
		for agent in traffic:
			var relative: Vector3 = agent.position-player.position
			var ahead: float = relative.dot(-player.global_transform.basis.z)
			var lateral: float = absf(relative.dot(player.global_transform.basis.x))
			if ahead > 0 and lateral < 2:
				target_speed = minf(target_speed, maxf(0, (ahead-2.2-agent.length*0.5-3)*0.5))
		if index == route.size()-1:
			target_speed = minf(target_speed, maxf(0, (gap-2)*0.5))
		Input.action_press("accelerate", 1.0 if player.speed < target_speed else 0.0)
		Input.action_press("brake", 1.0 if player.speed > target_speed+0.3 else 0.0)
		if finished:
			var success: bool = player.position.distance_to(arrival_point) < 4.5 and player.collision_count == 0 and red_lights == 0
			var result: Dictionary = {"success": success, "position": str(player.position), "collisions": player.collision_count, "red_lights": red_lights, "elapsed": elapsed}
			var report = FileAccess.open(_artifact_path("autodrive.json"), FileAccess.WRITE)
			report.store_string(JSON.stringify(result, "  "))
			print("AUTODRIVE_ARRIVED " if success else "AUTODRIVE_FAILED ", JSON.stringify(result))
			get_tree().quit(0 if success else 1)
			return
	print("AUTODRIVE_FAILED ", player.position, " waypoint ", index)
	get_tree().quit(1)
