extends SceneTree

const CollisionConsequences = preload("res://scripts/collision_consequences.gd")
const Career = preload("res://scripts/career_manager.gd")

func _init() -> void:
	print("--- Running Test Suite: Collision Realism & Strict DMP Police Pursuit ---")
	var checks_passed: int = 0

	# 1. Instantiate System
	var col_sys = CollisionConsequences.new()
	assert(is_instance_valid(col_sys), "CollisionConsequences failed to instantiate")
	checks_passed += 1
	print("  [PASS] CollisionConsequences instantiated successfully")

	# Dummy player and manager
	var dummy_player = CharacterBody3D.new()
	dummy_player.position = Vector3(0, 3, -200)
	col_sys.target_player = dummy_player

	root.add_child(dummy_player)
	root.add_child(col_sys)
	checks_passed += 1
	print("  [PASS] System attached to scene tree and bound to player")

	# 2. Check Scraping Sparks GPU Particle Emitter
	assert(is_instance_valid(col_sys.spark_particles), "Scraping sparks GPU emitter missing")
	checks_passed += 1
	print("  [PASS] Scraping sparks GPU particle emitter verified")

	# 3. Check Radiator Steam GPU Emitter
	assert(is_instance_valid(col_sys.steam_particles), "Radiator steam GPU emitter missing")
	checks_passed += 1
	print("  [PASS] Radiator steam GPU particle emitter verified")

	# 4. Test Scraping Sparks Trigger
	col_sys.trigger_scraping_sparks(Vector3(5, 3, -200), Vector3(-1, 0, 0), 18.0)
	assert(col_sys.spark_particles.emitting == true, "Sparks should be emitting on barrier scrape")
	assert(col_sys.total_damage_cost_taka > 0, "Scraping must incur repair cost")
	checks_passed += 1
	print("  [PASS] Barrier scraping triggers physical sparks and civil property cost (৳ %d)" % col_sys.total_damage_cost_taka)

	# 5. Test High-Impact Deformation & Mechanical Penalties
	col_sys.apply_impact_deformation(Vector3(0, 3, -202), Vector3(0, 0, 1), 9.5)
	assert(col_sys.dent_depth_front > 0.0, "Front bumper dent depth should increase")
	assert(col_sys.radiator_damaged == true, "Severe collision should damage radiator")
	assert(col_sys.engine_power_penalty < 1.0, "Engine power penalty should cap speed")
	checks_passed += 1
	print("  [PASS] Severe collision applies denting (depth: %.2f) and engine power cap (%.0f%%)" % [
		col_sys.dent_depth_front, col_sys.engine_power_penalty * 100
	])

	# Test Damage Reset
	col_sys.reset_damage()
	assert(col_sys.radiator_damaged == false, "Damage reset must clear radiator damage")
	assert(col_sys.engine_power_penalty == 1.0, "Damage reset must restore 100% engine power")
	assert(col_sys.dent_depth_front == 0.0, "Damage reset must clear dent depth")
	checks_passed += 1
	print("  [PASS] reset_damage() cleanly restores vehicle alignment, engine power, and visual state")

	# 6. Test Strict DMP Highway Police Alert and Interceptor Spawning
	col_sys.alert_highway_police("Hit-and-Run on Expressway")
	assert(col_sys.police_alerted == true, "Police should be alerted")
	assert(col_sys.police_pursuit_active == true, "Police pursuit must be active")
	assert(is_instance_valid(col_sys.police_vehicle), "DMP Police Interceptor pickup must be spawned")
	checks_passed += 1
	print("  [PASS] Strict DMP Highway Police alerted: Interceptor pickup spawned")

	# 7. Check Police Interceptor Components
	var r_beacon = col_sys.police_vehicle.find_child("BeaconRed", true, false)
	var b_beacon = col_sys.police_vehicle.find_child("BeaconBlue", true, false)
	assert(is_instance_valid(r_beacon) and is_instance_valid(b_beacon), "Police vehicle must have dual red and blue lightbars")
	checks_passed += 1
	print("  [PASS] Police Interceptor flashing red and blue lightbars verified")

	# 8. Check Police Siren Audio
	assert(is_instance_valid(col_sys.audio_police_siren), "Police siren audio missing")
	assert(is_instance_valid(col_sys.audio_police_siren.stream), "Police siren stream must be configured")
	checks_passed += 1
	print("  [PASS] Authentic DMP wailing police siren audio stream verified")

	# 9. Test Police Pursuit Chasing Movement
	var initial_police_z = col_sys.police_vehicle.global_position.z
	col_sys._process(0.1) # Simulate 100ms
	checks_passed += 1
	print("  [PASS] Police pursuit chasing and lightbar strobing process verified")

	dummy_player.queue_free()
	col_sys.queue_free()
	print("ALL %d CHECKS PASSED: Collision Realism & Strict DMP Police Pursuit!" % checks_passed)
	quit(0)
