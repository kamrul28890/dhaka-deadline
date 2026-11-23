class_name DhakaSettings
extends RefCounted

const SETTINGS_PATH = "user://settings.json"

const DEFAULT_SETTINGS = {
	"graphics": {
		"preset": "high",           # "low", "medium", "high"
		"mode": "windowed",          # "windowed", "fullscreen"
		"resolution": "1600x900",    # "1280x720", "1600x900", "1920x1080"
		"shadows": "high",           # "off", "medium", "high"
		"msaa": "2x",                # "off", "2x", "4x"
		"fxaa": true,
		"scale_3d": 100
	},
	"audio": {
		"master": 100,               # 0..100
		"engine": 80,
		"traffic": 70,
		"ambience": 70,
		"sfx": 85
	}
}

static var current: Dictionary = {}

static func get_default_settings() -> Dictionary:
	return DEFAULT_SETTINGS.duplicate(true)

static func _ensure_dir(path: String) -> void:
	var base_dir: String = path.get_base_dir()
	if base_dir != "":
		var global: String = ProjectSettings.globalize_path(base_dir)
		if not DirAccess.dir_exists_absolute(global):
			DirAccess.make_dir_recursive_absolute(global)

static func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	var target_path: String = path
	if not FileAccess.file_exists(target_path):
		var fallback_path: String = "res://artifacts/settings.json"
		if FileAccess.file_exists(fallback_path):
			target_path = fallback_path
		else:
			current = get_default_settings()
			return current.duplicate(true)

	var file = FileAccess.open(target_path, FileAccess.READ)
	if not file:
		current = get_default_settings()
		return current.duplicate(true)

	var content: String = file.get_as_text()
	var json = JSON.new()
	var parse_err = json.parse(content)
	if parse_err != OK or typeof(json.data) != TYPE_DICTIONARY:
		current = get_default_settings()
		return current.duplicate(true)

	var parsed: Dictionary = json.data

	var result: Dictionary = get_default_settings()
	if parsed.has("graphics") and typeof(parsed["graphics"]) == TYPE_DICTIONARY:
		for k in parsed["graphics"]:
			result["graphics"][k] = parsed["graphics"][k]
	if parsed.has("audio") and typeof(parsed["audio"]) == TYPE_DICTIONARY:
		for k in parsed["audio"]:
			result["audio"][k] = parsed["audio"][k]

	current = result.duplicate(true)
	return result

static func save_settings(settings: Dictionary, path: String = SETTINGS_PATH) -> bool:
	_ensure_dir(path)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var fallback_path: String = "res://artifacts/settings.json"
		_ensure_dir(fallback_path)
		file = FileAccess.open(fallback_path, FileAccess.WRITE)
		if not file:
			return false
	file.store_string(JSON.stringify(settings, "  "))
	current = settings.duplicate(true)
	return true

static func setup_audio_buses() -> void:
	var required_buses: Array[String] = ["Engine", "Traffic", "Ambience", "SFX"]
	for bus_name in required_buses:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			var new_idx: int = AudioServer.bus_count
			AudioServer.add_bus(new_idx)
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, "Master")

static func set_bus_volume(bus_name: String, percent: int) -> void:
	setup_audio_buses()
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var p: int = clampi(percent, 0, 100)
	if p <= 0:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		var linear: float = float(p) / 100.0
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

static func apply_audio_settings(audio_cfg: Dictionary) -> void:
	setup_audio_buses()
	set_bus_volume("Master", audio_cfg.get("master", 100))
	set_bus_volume("Engine", audio_cfg.get("engine", 80))
	set_bus_volume("Traffic", audio_cfg.get("traffic", 70))
	set_bus_volume("Ambience", audio_cfg.get("ambience", 70))
	set_bus_volume("SFX", audio_cfg.get("sfx", 85))

static func get_preset_values(preset_name: String) -> Dictionary:
	match preset_name:
		"low":
			return {
				"preset": "low",
				"shadows": "off",
				"msaa": "off",
				"fxaa": false,
				"scale_3d": 75
			}
		"medium":
			return {
				"preset": "medium",
				"shadows": "medium",
				"msaa": "off",
				"fxaa": true,
				"scale_3d": 100
			}
		_: # "high"
			return {
				"preset": "high",
				"shadows": "high",
				"msaa": "2x",
				"fxaa": true,
				"scale_3d": 100
			}

static func apply_graphics_settings(graphics_cfg: Dictionary, viewport: Viewport = null) -> void:
	if DisplayServer.get_name() != "headless":
		var mode: String = graphics_cfg.get("mode", "windowed")
		if mode == "fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res_str: String = graphics_cfg.get("resolution", "1600x900")
			var parts: PackedStringArray = res_str.split("x")
			if parts.size() == 2:
				DisplayServer.window_set_size(Vector2i(parts[0].to_int(), parts[1].to_int()))

	if viewport != null:
		var fxaa_enabled: bool = graphics_cfg.get("fxaa", true)
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if fxaa_enabled else Viewport.SCREEN_SPACE_AA_DISABLED

		var msaa_str: String = graphics_cfg.get("msaa", "2x")
		viewport.msaa_3d = Viewport.MSAA_4X if msaa_str == "4x" else Viewport.MSAA_2X if msaa_str == "2x" else Viewport.MSAA_DISABLED

		var scale_val: float = float(graphics_cfg.get("scale_3d", 100)) / 100.0
		viewport.scaling_3d_scale = clampf(scale_val, 0.5, 1.0)
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR

	var shadows: String = graphics_cfg.get("shadows", "high")
	var atlas_size: int = 1024 if shadows == "off" else 2048 if shadows == "medium" else 4096
	RenderingServer.directional_shadow_atlas_set_size(atlas_size, true)

static func apply_all(settings: Dictionary, viewport: Viewport = null) -> void:
	if settings.has("audio") and typeof(settings["audio"]) == TYPE_DICTIONARY:
		apply_audio_settings(settings["audio"])
	if settings.has("graphics") and typeof(settings["graphics"]) == TYPE_DICTIONARY:
		apply_graphics_settings(settings["graphics"], viewport)
	current = settings.duplicate(true)
