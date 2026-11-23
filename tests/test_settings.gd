extends SceneTree

const Settings = preload("res://scripts/settings_manager.gd")
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
	print("=== Running Configuration & Settings Tests ===")

	# Check 1: Default settings keys
	var defaults: Dictionary = Settings.get_default_settings()
	check(defaults.has("graphics") and defaults.has("audio"), "Default settings has graphics and audio sections")
	check(defaults.graphics.has("preset") and defaults.graphics.has("shadows") and defaults.graphics.has("scale_3d"), "Graphics defaults contain preset, shadows, and scale_3d")
	check(defaults.audio.has("master") and defaults.audio.has("engine") and defaults.audio.has("traffic") and defaults.audio.has("ambience") and defaults.audio.has("sfx"), "Audio defaults contain all 5 volume channels")

	# Check 2: Save and load round-trip
	var test_path: String = "res://artifacts/test_settings.json"
	var custom_cfg: Dictionary = Settings.get_default_settings()
	custom_cfg.graphics.preset = "medium"
	custom_cfg.audio.engine = 65
	var save_ok: bool = Settings.save_settings(custom_cfg, test_path)
	check(save_ok, "save_settings returns true on valid write")
	var loaded: Dictionary = Settings.load_settings(test_path)
	check(loaded.graphics.preset == "medium", "Loaded settings retains modified graphics preset")
	check(loaded.audio.engine == 65, "Loaded settings retains modified audio volume")

	# Check 3: Corrupt JSON recovery
	var corrupt_file = FileAccess.open(test_path, FileAccess.WRITE)
	corrupt_file.store_string("{ INVALID JSON CONTENT :::")
	corrupt_file.close()
	var recovered: Dictionary = Settings.load_settings(test_path)
	check(recovered.graphics.preset == "high" and recovered.audio.master == 100, "Corrupt file safely recovers default values")

	# Check 4: Partial JSON key merging
	var partial_file = FileAccess.open(test_path, FileAccess.WRITE)
	partial_file.store_string('{"graphics": {"preset": "low"}}')
	partial_file.close()
	var merged: Dictionary = Settings.load_settings(test_path)
	check(merged.graphics.preset == "low", "Preserves specified partial keys")
	check(merged.audio.has("master") and merged.audio.master == 100, "Fills missing audio section with defaults")
	check(merged.graphics.has("resolution"), "Fills missing graphics keys with defaults")

	# Clean up test file
	DirAccess.remove_absolute(test_path)

	# Check 5: Audio buses setup
	Settings.setup_audio_buses()
	for bus in ["Engine", "Traffic", "Ambience", "SFX"]:
		var idx: int = AudioServer.get_bus_index(bus)
		check(idx != -1, "AudioServer bus '%s' exists" % bus)
		if idx != -1:
			check(AudioServer.get_bus_send(idx) == "Master", "AudioServer bus '%s' routes to Master" % bus)

	# Check 6: Audio bus volume scaling
	Settings.set_bus_volume("Engine", 100)
	var idx_engine: int = AudioServer.get_bus_index("Engine")
	check(is_equal_approx(AudioServer.get_bus_volume_db(idx_engine), 0.0), "100% volume sets approximately 0 dB")
	Settings.set_bus_volume("Engine", 50)
	check(is_equal_approx(AudioServer.get_bus_volume_db(idx_engine), linear_to_db(0.5)), "50% volume sets approximately -6 dB")
	Settings.set_bus_volume("Engine", 0)
	check(AudioServer.is_bus_mute(idx_engine), "0% volume mutes the audio bus")

	# Check 7: Quality preset definitions
	var low_p: Dictionary = Settings.get_preset_values("low")
	var med_p: Dictionary = Settings.get_preset_values("medium")
	var high_p: Dictionary = Settings.get_preset_values("high")
	check(low_p.scale_3d == 75 and low_p.shadows == "off", "Low preset sets 75% 3D scale and off shadows")
	check(med_p.scale_3d == 100 and med_p.shadows == "medium", "Medium preset sets 100% scale and medium shadows")
	check(high_p.msaa == "2x" and high_p.shadows == "high", "High preset sets 2x MSAA and high shadows")

	# Check 8: Viewport application
	var vp = SubViewport.new()
	root.add_child(vp)
	Settings.apply_graphics_settings(low_p, vp)
	check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED, "Low preset disables FXAA on viewport")
	check(is_equal_approx(vp.scaling_3d_scale, 0.75), "Low preset applies 0.75 3D render scale")
	Settings.apply_graphics_settings(high_p, vp)
	check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, "High preset enables FXAA on viewport")
	check(vp.msaa_3d == Viewport.MSAA_2X, "High preset enables 2X MSAA on viewport")
	check(is_equal_approx(vp.scaling_3d_scale, 1.0), "High preset applies 1.0 3D render scale")
	vp.queue_free()

	# Check 9: Full settings apply
	var full_cfg: Dictionary = Settings.get_default_settings()
	full_cfg.audio.sfx = 75
	full_cfg.graphics.preset = "medium"
	Settings.apply_all(full_cfg)
	var idx_sfx: int = AudioServer.get_bus_index("SFX")
	check(is_equal_approx(AudioServer.get_bus_volume_db(idx_sfx), linear_to_db(0.75)), "apply_all applies SFX bus volume")

	# Check 10: HUD settings menu integration
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	check(world.hud.has_method("show_settings"), "HUD provides show_settings method")
	world.hud.show_settings(false)
	check(is_instance_valid(world.hud.menu), "show_settings instantiates menu container from intro")
	world.hud.show_settings(true)
	check(is_instance_valid(world.hud.menu), "show_settings instantiates menu container from pause")
	world.free()

	print("Settings Tests Results: %d checks, %d failures" % [checks, failures.size()])
	print("SETTINGS_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
