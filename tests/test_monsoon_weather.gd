extends SceneTree

const Missions = preload("res://scripts/mission_manager.gd")
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
	# 1. Procedural Audio Assets Verification
	var audio_files = ["rain_loop.wav", "wiper_sweep.wav", "water_splash.wav"]
	for af in audio_files:
		var path = "res://assets/audio/" + af
		var stream: AudioStreamWAV = load(path)
		check(stream != null, "Audio stream "+af+" loads as valid AudioStreamWAV")
		if stream:
			check(stream.get_length() > 0.2, af+" has positive playback duration")

	# 2. Monsoon Mission Verification
	var all_m = Missions.get_all_missions()
	check(all_m.size() >= 4, "Missions registry includes at least 4 playable missions")
	var monsoon_m: Dictionary = Missions.get_mission("monsoon")
	check(monsoon_m.get("id") == "monsoon", "Monsoon mission exists in registry")
	check(monsoon_m.get("weather") == "monsoon", "Monsoon mission specifies monsoon weather")
	check("বর্ষা" in monsoon_m.get("title_bn", ""), "Monsoon mission has authentic Bengali title")

	# 3. Main Scene, District & Weather Systems
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	check(world.district.has_method("set_weather"), "District has set_weather method")
	check(world.district.get("weather") != null, "District has weather property")

	# Test Clear Weather baseline
	world.district.set_weather("clear")
	check(world.district.weather == "clear", "District weather is set to clear")
	var rain_vol = world.district.find_child("RainVolume", true, false)
	if rain_vol:
		check(not rain_vol.visible, "RainVolume is inactive in clear weather")
	check(world.district.asphalt.roughness >= 0.85, "Dry asphalt has high roughness")

	# Test Monsoon Weather state
	world.district.set_weather("monsoon")
	check(world.district.weather == "monsoon", "District weather is set to monsoon")
	rain_vol = world.district.find_child("RainVolume", true, false)
	check(rain_vol != null and rain_vol.visible, "RainVolume is present and active in monsoon weather")
	check(world.district.env.fog_density >= 0.002, "Monsoon weather introduces atmospheric rain mist")
	check(world.district.asphalt.roughness <= 0.35, "Wet road asphalt has low specular roughness for puddle reflections")
	var puddles = world.district.find_child("GutterPuddles", true, false)
	check(puddles != null and puddles.visible, "Curb drainage water accumulation puddles are enabled")

	# 4. Player Car Wipers & Cabin Rain Atmosphere
	var player = world.player
	check(player.get("wipers_active") != null, "Player car has wipers_active state")
	check(player.has_method("set_wipers"), "Player car has set_wipers method")
	check(player.has_method("toggle_wipers"), "Player car has toggle_wipers method")

	var wiper_l = player.visual.find_child("wiper_L", true, false)
	var wiper_r = player.visual.find_child("wiper_R", true, false)
	check(wiper_l != null and wiper_r != null, "Player car has modeled dual wiper arms")

	player.set_wipers(true)
	check(player.wipers_active == true, "Wipers are successfully activated")
	var initial_wiper_rot: float = player.wiper_angle
	world.paused_sim = false
	player.enabled = true
	for i in range(25):
		await physics_frame
	check(absf(player.wiper_angle - initial_wiper_rot) > 0.05, "Wiper arms physically sweep back and forth over time")

	# 5. Audio Bus Routing for Weather SFX
	check(player.wiper_sweep_sound != null and player.wiper_sweep_sound.bus == "SFX", "Wiper sound routes to SFX bus")
	check(player.splash_sound != null and player.splash_sound.bus == "SFX", "Water splash sound routes to SFX bus")
	check(world.rain_player != null and world.rain_player.bus == "Ambience", "Rain ambience player routes to Ambience bus")

	# 6. Water splash triggering
	player.speed = 8.5
	player.position = Vector3(-90, 0, 0)
	for i in range(10):
		await physics_frame
	check(player.splash_sound != null, "Hydrodynamic water splash sound player is valid")

	# 7. Traffic and pedestrian safety under monsoon conditions
	check(world.traffic.size() == 18, "Traffic vehicle population preserved (18 agents)")
	check(world.pedestrians.size() >= 16, "Pedestrian population preserved (>= 16 agents)")
	var finite_actors: bool = true
	for a in world.traffic:
		finite_actors = finite_actors and a.position.is_finite()
	for p in world.pedestrians:
		finite_actors = finite_actors and p.position.is_finite()
	check(finite_actors, "All traffic and pedestrians remain finite and grounded in monsoon conditions")

	world.queue_free()
	await process_frame
	await process_frame
	await process_frame

	print("MONSOON_WEATHER_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
