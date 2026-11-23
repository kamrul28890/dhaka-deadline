extends SceneTree

# Test Suite: Ambient Urban Dhaka Soundscape & Street Life Foleys (v1.7)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("=== Running Dhaka Soundscape & Street Life Foley Tests (v1.7) ===")
	var checks: int = 0
	var failures: Array[String] = []

	# Check 1: Audio WAV file existence & RIFF byte sizes
	var audio_files = {
		"rickshaw_bell.wav": 20000,
		"conductor_call.wav": 35000,
		"tea_stall.wav": 35000,
		"hawker_call.wav": 30000
	}
	for fname in audio_files:
		checks += 1
		var path = "res://assets/audio/" + fname
		if not FileAccess.file_exists(path):
			failures.append("Audio asset %s does not exist" % fname)
		else:
			checks += 1
			var f = FileAccess.open(path, FileAccess.READ)
			if f == null or f.get_length() < audio_files[fname]:
				failures.append("Audio asset %s length too small or corrupt: %d bytes" % [fname, f.get_length() if f else 0])
			if f:
				f.close()

	# Check 2: Instantiate Main World and verify 3D Audio Emitters
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var district = world.district
	assert(is_instance_valid(district), "District must be valid")

	# Check 3: Tea Stall Foley Emitter
	checks += 1
	if not ("foley_tea_stall" in district) or not is_instance_valid(district.foley_tea_stall):
		failures.append("District missing foley_tea_stall emitter")
	else:
		checks += 1
		if district.foley_tea_stall.bus != "Ambience":
			failures.append("foley_tea_stall bus should be 'Ambience', got '%s'" % district.foley_tea_stall.bus)
		checks += 1
		if district.foley_tea_stall.max_distance < 20.0:
			failures.append("foley_tea_stall max_distance too small: %f" % district.foley_tea_stall.max_distance)

	# Check 4: Bus Conductor Route Call Emitter
	checks += 1
	if not ("foley_conductor" in district) or not is_instance_valid(district.foley_conductor):
		failures.append("District missing foley_conductor emitter")
	else:
		checks += 1
		if district.foley_conductor.bus != "Ambience":
			failures.append("foley_conductor bus should be 'Ambience', got '%s'" % district.foley_conductor.bus)
		checks += 1
		if district.foley_conductor.max_distance < 30.0:
			failures.append("foley_conductor max_distance too small: %f" % district.foley_conductor.max_distance)

	# Check 5: Rickshaw Bell Foley Emitter
	checks += 1
	if not ("foley_rickshaw_bell" in district) or not is_instance_valid(district.foley_rickshaw_bell):
		failures.append("District missing foley_rickshaw_bell emitter")
	else:
		checks += 1
		if district.foley_rickshaw_bell.bus != "Ambience":
			failures.append("foley_rickshaw_bell bus should be 'Ambience', got '%s'" % district.foley_rickshaw_bell.bus)
		checks += 1
		if district.foley_rickshaw_bell.max_distance < 25.0:
			failures.append("foley_rickshaw_bell max_distance too small: %f" % district.foley_rickshaw_bell.max_distance)

	# Check 6: Fruit Hawker Call Foley Emitter
	checks += 1
	if not ("foley_hawker" in district) or not is_instance_valid(district.foley_hawker):
		failures.append("District missing foley_hawker emitter")
	else:
		checks += 1
		if district.foley_hawker.bus != "Ambience":
			failures.append("foley_hawker bus should be 'Ambience', got '%s'" % district.foley_hawker.bus)
		checks += 1
		if district.foley_hawker.max_distance < 20.0:
			failures.append("foley_hawker max_distance too small: %f" % district.foley_hawker.max_distance)

	# Check 7: Trigger individual play calls on foley emitters
	checks += 1
	district.foley_conductor.play()
	district.foley_rickshaw_bell.play()
	district.foley_hawker.play()
	# Check streams loaded properly
	if district.foley_conductor.stream == null or district.foley_rickshaw_bell.stream == null or district.foley_hawker.stream == null:
		failures.append("Foley emitters missing valid AudioStream resources")

	# Check 8: Actors Grounded and Finite
	checks += 1
	if not world.player.position.is_finite() or absf(world.player.position.y) > 2.0:
		failures.append("Player vehicle ended up non-finite or ungrounded")

	var report = {"checks": checks, "failures": failures}
	print("DHAKA_SOUNDSCAPE_TESTS ", JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
