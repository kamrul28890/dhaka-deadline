extends SceneTree

const Weather = preload("res://scripts/dynamic_weather.gd")

func _init() -> void:
	print("--- Running Test Suite: Dynamic Falling Rain Particle Weather ---")
	var checks_passed: int = 0

	# 1. Instantiate Weather System
	var weather = Weather.new()
	assert(is_instance_valid(weather), "Weather failed to instantiate")
	checks_passed += 1
	print("  [PASS] DynamicWeather instantiated successfully")

	# Create a dummy player node
	var dummy_player = CharacterBody3D.new()
	dummy_player.position = Vector3(0, 5, -100)
	dummy_player.velocity = Vector3(0, 0, -20) # Driving 72 km/h along -Z
	weather.target_player = dummy_player

	# Add to tree
	root.add_child(dummy_player)
	root.add_child(weather)
	checks_passed += 1
	print("  [PASS] Weather attached to scene tree and bound to player")

	# 2. Check GPU Rain Particles Setup
	assert(is_instance_valid(weather.rain_particles), "Rain GPUParticles3D missing")
	assert(weather.rain_particles.amount >= 10000, "Rain particles amount should be >= 10000")
	checks_passed += 1
	print("  [PASS] GPU Falling Rain Particle Emitter verified (amount: %d)" % weather.rain_particles.amount)

	# 3. Check Ground Splash Particles
	assert(is_instance_valid(weather.splash_particles), "Ground splash particles missing")
	checks_passed += 1
	print("  [PASS] Ground splash micro-particles emitter verified")

	# 4. Check Weather Mode Switching: Clear
	weather.set_weather("clear")
	assert(weather.rain_particles.emitting == false, "Rain should not emit in clear mode")
	assert(weather.splash_particles.emitting == false, "Splash should not emit in clear mode")
	checks_passed += 1
	print("  [PASS] Clear weather mode disables rain emitters")

	# 5. Check Weather Mode Switching: Drizzle
	weather.set_weather("drizzle")
	assert(weather.rain_particles.emitting == true, "Rain should emit in drizzle mode")
	assert(weather.mode == "drizzle", "Mode should be drizzle")
	checks_passed += 1
	print("  [PASS] Drizzle weather mode activates light falling rain")

	# 6. Check Weather Mode Switching: Monsoon
	weather.set_weather("monsoon")
	assert(weather.rain_particles.emitting == true, "Rain should emit in monsoon mode")
	assert(weather.rain_particles.amount == 12000, "Monsoon rain particle amount should be 12000")
	checks_passed += 1
	print("  [PASS] Monsoon weather mode activates dense downpour particles (12000)")

	# 7. Check Aerodynamic Velocity Shear Process
	weather._process(0.016)
	var emitter_y = weather.rain_particles.global_position.y if weather.rain_particles.is_inside_tree() else weather.rain_particles.position.y
	var player_y = dummy_player.global_position.y if dummy_player.is_inside_tree() else dummy_player.position.y
	assert(emitter_y > player_y, "Emitter must be overhead")
	var z_dir = weather.rain_mat.direction.z
	assert(z_dir > 0, "Rain must shear backwards (+Z) when car moves forward (-Z)")
	checks_passed += 1
	print("  [PASS] Aerodynamic velocity shear tilts rain backwards at high speed")

	# 8. Check Windshield Droplet Overlay Shader
	assert(is_instance_valid(weather.windshield_overlay), "Windshield overlay missing")
	assert(is_instance_valid(weather.windshield_mat), "Windshield ShaderMaterial missing")
	var rain_amt = weather.windshield_mat.get_shader_parameter("rain_amount")
	assert(rain_amt > 0.5, "Monsoon rain amount parameter should be > 0.5")
	checks_passed += 1
	print("  [PASS] Interactive windshield rain droplet shader verified")

	dummy_player.queue_free()
	weather.queue_free()
	print("ALL %d CHECKS PASSED: Dynamic Falling Rain Particle Weather!" % checks_passed)
	quit(0)
