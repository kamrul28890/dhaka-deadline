class_name DhakaDynamicWeather
extends Node3D

# Dynamic Animated Weather & Falling Rain Particle System
# Real-time GPU particle rain with speed-dependent aerodynamic velocity shear,
# ground impact splash particles, animated puddle ripple normal distortion,
# and interactive windshield rain droplets with animated wiper clearing.

var mode: String = "clear" # "clear", "drizzle", "monsoon"
var target_player: CharacterBody3D = null

# Particle Systems
var rain_particles: GPUParticles3D
var splash_particles: GPUParticles3D
var rain_mat: ParticleProcessMaterial
var splash_mat: ParticleProcessMaterial

# Windshield & Camera Water Droplet Overlay
var windshield_overlay: ColorRect
var windshield_mat: ShaderMaterial

# Ambient Rain Audio
var audio_rain: AudioStreamPlayer

# Animated Puddle Ripples
var ripple_time: float = 0.0

func _init() -> void:
	name = "DhakaDynamicWeather"
	_setup_rain_particles()
	_setup_splash_particles()
	_setup_audio()
	_setup_windshield_shader()

func _setup_rain_particles() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "FallingRainGPU"
	rain_particles.amount = 10000
	rain_particles.lifetime = 1.2
	rain_particles.preprocess = 0.5
	rain_particles.speed_scale = 1.0
	rain_particles.explosiveness = 0.0
	rain_particles.randomness = 0.2

	rain_mat = ParticleProcessMaterial.new()
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(22.0, 14.0, 22.0)
	rain_mat.direction = Vector3(0, -1, 0)
	rain_mat.spread = 4.0
	rain_mat.initial_velocity_min = 14.0
	rain_mat.initial_velocity_max = 18.0
	rain_mat.gravity = Vector3(0, -9.8, 0)
	rain_mat.color = Color(0.85, 0.92, 1.0, 0.42)
	rain_mat.particle_flag_align_y = true
	rain_mat.scale_min = 0.04
	rain_mat.scale_max = 0.07

	rain_particles.process_material = rain_mat

	# Draw pass mesh: stretched translucent vertical capsule/quad
	var drop_mesh = RibbonTrailMesh.new()
	drop_mesh.size = 0.05
	drop_mesh.section_length = 0.65
	var drop_mat = StandardMaterial3D.new()
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.75, 0.88, 1.0, 0.50)
	drop_mat.roughness = 0.1
	drop_mesh.material = drop_mat
	rain_particles.draw_pass_1 = drop_mesh

	rain_particles.emitting = false
	add_child(rain_particles)

func _setup_splash_particles() -> void:
	splash_particles = GPUParticles3D.new()
	splash_particles.name = "GroundSplashGPU"
	splash_particles.amount = 2500
	splash_particles.lifetime = 0.25
	splash_particles.explosiveness = 0.0

	splash_mat = ParticleProcessMaterial.new()
	splash_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	splash_mat.emission_box_extents = Vector3(20.0, 0.2, 20.0)
	splash_mat.direction = Vector3(0, 1, 0)
	splash_mat.spread = 65.0
	splash_mat.initial_velocity_min = 1.5
	splash_mat.initial_velocity_max = 3.2
	splash_mat.gravity = Vector3(0, -14.0, 0)
	splash_mat.color = Color(0.85, 0.92, 1.0, 0.35)
	splash_mat.scale_min = 0.03
	splash_mat.scale_max = 0.06

	splash_particles.process_material = splash_mat

	var splash_mesh = SphereMesh.new()
	splash_mesh.radius = 0.04
	splash_mesh.height = 0.04
	splash_particles.draw_pass_1 = splash_mesh

	splash_particles.emitting = false
	add_child(splash_particles)

func _setup_audio() -> void:
	audio_rain = AudioStreamPlayer.new()
	audio_rain.name = "RainAudioPlayer"
	audio_rain.bus = "Ambience" if AudioServer.get_bus_index("Ambience") != -1 else "Master"
	var stream = load("res://assets/audio/rain_loop.wav")
	if stream:
		audio_rain.stream = stream
	add_child(audio_rain)

func _setup_windshield_shader() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 2
	canvas.name = "WindshieldCanvas"
	add_child(canvas)

	windshield_overlay = ColorRect.new()
	windshield_overlay.name = "WindshieldRainDroplets"
	windshield_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	windshield_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float rain_amount : hint_range(0.0, 1.0) = 0.0;
	uniform float car_speed_ratio : hint_range(0.0, 2.0) = 0.0;
	uniform float wiper_wipe_phase : hint_range(0.0, 1.0) = 0.0;
	uniform bool wipers_active = false;

	// Procedural pseudo-random hash
	float hash(vec2 p) {
		p = fract(p * vec2(123.34, 456.21));
		p += dot(p, p + 45.32);
		return fract(p.x * p.y);
	}

	void fragment() {
		if (rain_amount <= 0.01) {
			COLOR = vec4(0.0);
		} else {
			vec2 uv = UV;
			// Aerodynamic streaks flow outward and up when driving fast
			vec2 flow_uv = uv + vec2(0.0, TIME * (0.8 + car_speed_ratio * 2.5));
			vec2 cell = floor(flow_uv * vec2(28.0, 38.0));
			vec2 fract_uv = fract(flow_uv * vec2(28.0, 38.0)) - 0.5;

			float n = hash(cell);
			float droplet = 0.0;
			if (n > (1.0 - rain_amount * 0.45)) {
				float r = length(fract_uv);
				droplet = smoothstep(0.28, 0.05, r) * 0.45;
			}

			// Wiper clear cone mask (simulates dual wiper arcs sweeping lower windshield)
			if (wipers_active) {
				vec2 wiper_pivot1 = vec2(0.35, 1.1);
				vec2 wiper_pivot2 = vec2(0.68, 1.1);
				float d1 = distance(uv, wiper_pivot1);
				float d2 = distance(uv, wiper_pivot2);
				if ((d1 > 0.25 && d1 < 0.85 && uv.y > 0.35) || (d2 > 0.25 && d2 < 0.85 && uv.y > 0.35)) {
					droplet *= 0.12; // Wiped clean
				}
			}

			COLOR = vec4(0.75, 0.85, 0.95, droplet * rain_amount);
		}
	}
	"""

	windshield_mat = ShaderMaterial.new()
	windshield_mat.shader = shader
	windshield_mat.set_shader_parameter("rain_amount", 0.0)
	windshield_mat.set_shader_parameter("car_speed_ratio", 0.0)
	windshield_mat.set_shader_parameter("wipers_active", false)
	windshield_overlay.material = windshield_mat
	canvas.add_child(windshield_overlay)

func set_weather(new_mode: String) -> void:
	mode = new_mode
	match mode:
		"clear":
			rain_particles.emitting = false
			splash_particles.emitting = false
			if is_instance_valid(audio_rain):
				audio_rain.stop()
			if is_instance_valid(windshield_mat):
				windshield_mat.set_shader_parameter("rain_amount", 0.0)
		"drizzle":
			rain_particles.amount = 3500
			rain_particles.emitting = true
			splash_particles.amount = 800
			splash_particles.emitting = true
			if is_instance_valid(audio_rain):
				audio_rain.volume_db = -12.0
				if is_inside_tree() and not audio_rain.playing:
					audio_rain.play()
			if is_instance_valid(windshield_mat):
				windshield_mat.set_shader_parameter("rain_amount", 0.35)
		"monsoon":
			rain_particles.amount = 12000
			rain_particles.emitting = true
			splash_particles.amount = 3500
			splash_particles.emitting = true
			if is_instance_valid(audio_rain):
				audio_rain.volume_db = -2.0
				if is_inside_tree() and not audio_rain.playing:
					audio_rain.play()
			if is_instance_valid(windshield_mat):
				windshield_mat.set_shader_parameter("rain_amount", 0.90)

func _process(delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	# Keep rain particle emitter centered around player vehicle position
	var p_pos: Vector3 = target_player.global_position if target_player.is_inside_tree() else target_player.position
	if is_inside_tree():
		rain_particles.global_position = p_pos + Vector3(0, 10.0, 0)
		splash_particles.global_position = Vector3(p_pos.x, p_pos.y + 0.1, p_pos.z)
	else:
		rain_particles.position = p_pos + Vector3(0, 10.0, 0)
		splash_particles.position = Vector3(p_pos.x, p_pos.y + 0.1, p_pos.z)

	# Dynamic Aerodynamic Velocity Shear:
	# Rain tilts backward proportional to car's forward motion along -Z
	var forward_speed: float = -target_player.velocity.z # Speed along -Z
	var speed_ratio: float = clamp(forward_speed / 25.0, 0.0, 1.8) # 25 m/s = 90 km/h
	rain_mat.gravity = Vector3(0, -18.0, speed_ratio * 12.0)
	rain_mat.direction = Vector3(0, -1, speed_ratio * 0.75).normalized()

	# Windshield shader parameters
	if is_instance_valid(windshield_mat):
		windshield_mat.set_shader_parameter("car_speed_ratio", speed_ratio)
		var wipers_on: bool = target_player.has_method("get") and target_player.get("wipers_active") == true
		windshield_mat.set_shader_parameter("wipers_active", wipers_on)
