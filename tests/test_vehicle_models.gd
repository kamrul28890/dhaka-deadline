extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func triangles(node: Node) -> int:
	var total: int = 0
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		total += mesh.mesh.get_faces().size()/3
	return total

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var car = world.player.visual
	var front = car.find_child("wheel_FL",true,false)
	var rear = car.find_child("wheel_RL",true,false)
	var column = car.find_child("steering_column",true,false)
	check(front != null and rear != null, "Player car has functional wheel pivots")
	check(column != null, "Modeled cabin has a steering wheel")
	var windshield = car.find_child("glass_windshield",true,false)
	var glazing = windshield.get_active_material(0) if windshield else null
	check(glazing != null and glazing.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and glazing.albedo_color.a < 0.3, "Cabin glazing leaves the road visible instead of importing as opaque")
	if front and rear:
		check(front.global_position.z < rear.global_position.z, "Imported car faces the same direction as its controller")
	if column:
		check(column.global_position.x > world.player.global_position.x, "Steering wheel is on the right-hand-drive side")
	var traffic_car: Node
	for agent in world.traffic:
		if agent.kind == "car":
			traffic_car = agent.find_child("Sedan",false,false)
			break
	check(traffic_car != null and triangles(car) > triangles(traffic_car)*3, "Traffic uses substantially lighter geometry than the player car")
	var brake_materials = car.get("brake_materials")
	check(brake_materials != null and not brake_materials.is_empty(), "Brake lenses are connected to vehicle state")
	if brake_materials != null and not brake_materials.is_empty() and traffic_car:
		var other_materials = traffic_car.get("brake_materials")
		check(other_materials != null and not other_materials.is_empty() and brake_materials[0] != other_materials[0], "Lighting state is isolated between cars")
	if front and rear:
		world.paused_sim = false
		car._physics_process(1.0/60)
		for direction in [1,-1]:
			var local_tops: Array[Vector3] = []
			for wheel in car.wheels:
				local_tops.append(wheel.global_basis.inverse()*Vector3.UP)
			world.player.position += Vector3.FORWARD*0.02*direction
			car._physics_process(1.0/60)
			for i in range(car.wheels.size()):
				var top_motion: Vector3 = car.wheels[i].global_basis*local_tops[i]-Vector3.UP
				check(top_motion.dot(Vector3.FORWARD)*direction > 0.02, "Both sides roll with travel in forward and reverse")
		if column:
			var axle: Vector3 = column.global_basis.y.normalized()
			world.player.steering = 0.6
			car._physics_process(1.0/60)
			check(column.global_basis.y.normalized().is_equal_approx(axle), "Steering rotates the rim without tilting its axle")
			world.player.steering = 0
			car._physics_process(1.0/60)
		world.paused_sim = true
	world.start_mission(true)
	world.player.position = Vector3(0,0.1,50)
	var original_wheel: Basis = front.basis if front else Basis.IDENTITY
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")
	check(front != null and not front.basis.is_equal_approx(original_wheel), "Wheels rotate when the car moves")
	Input.action_press("brake")
	for i in range(8):
		await physics_frame
	check(brake_materials != null and not brake_materials.is_empty() and brake_materials[0].emission.r > 1, "Braking visibly brightens the rear lamps")
	Input.action_release("brake")
	world.toggle_pause()
	var paused_wheel: Basis = front.basis if front else Basis.IDENTITY
	for i in range(10):
		await physics_frame
	check(front != null and front.basis.is_equal_approx(paused_wheel), "Paused wheels remain still")
	world.toggle_pause()
	if traffic_car:
		var actor = traffic_car.get_parent()
		actor.set_physics_process(false)
		traffic_car.set_physics_process(false)
		actor.speed = 5
		traffic_car._physics_process(1.0/60)
		actor.rotation.y += 0.08
		traffic_car._physics_process(1.0/60)
		var pivot = traffic_car.find_child("steer_FL",true,false)
		check(absf(pivot.rotation.y) > 0.01, "Traffic front wheels follow the vehicle's turn")
	var camera_key = InputEventAction.new()
	camera_key.action = "camera"
	camera_key.pressed = true
	world.player._unhandled_input(camera_key)
	world.player._unhandled_input(camera_key)
	for i in range(30):
		await physics_frame
	check(world.player.camera_mode == 2, "Camera cycle includes a cabin view")
	var eye: Vector3 = world.player.to_local(world.player.camera.global_position)
	check(eye.x > 0.2 and eye.y > 1 and eye.y < 1.4 and absf(eye.z) < 0.5, "Cabin camera sits inside the right-hand-drive seating position")
	world.player.position = Vector3(-160,0.1,210)
	world.player.speed = 22.2
	Input.action_press("accelerate")
	for i in range(30):
		await physics_frame
	Input.action_release("accelerate")
	eye = world.player.to_local(world.player.camera.global_position)
	check(eye.distance_to(Vector3(0.34,1.14,0.28)) < 0.03, "Cabin viewpoint stays at the seat rather than sliding into the headrest at speed")
	world.player._unhandled_input(camera_key)
	check(world.player.camera_mode == 0, "Camera cycle returns to chase view")
	world.queue_free()
	for i in range(3):
		await process_frame
	print("VEHICLE_MODEL_TESTS ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
