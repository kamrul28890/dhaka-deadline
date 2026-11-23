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
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		total += mesh.mesh.get_faces().size()/3
	return total

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var bus = world.traffic[0]
	var cng = world.traffic[2]
	check(bus.find_child("Bus", false, false) != null and triangles(bus) > 10000, "Bus uses a detailed model with a modeled cabin and wheels")
	check(cng.find_child("CNG", false, false) != null and triangles(cng) > 5000, "Moving CNG uses a shaped three-wheeler instead of box geometry")
	check(bus.find_child("wheel_FL", true, false) != null, "Bus front axle has an animation pivot")
	check(cng.find_child("wheel_F", true, false) != null, "CNG has a single centered front wheel pivot")
	var bus_bounds: Vector3 = bus.get_node("CollisionShape3D").shape.size if bus.has_node("CollisionShape3D") else bus.get_child(0).shape.size
	check(is_equal_approx(bus_bounds.x, 2.45) and is_equal_approx(bus_bounds.z, 8.6), "Bus art preserves the calibrated traffic footprint")
	var parked: Array[Node] = world.district.find_children("CNG", "Node3D", true, false)
	check(parked.size() >= 2, "Parked CNGs reuse the same detailed model")
	var pedestrian = world.pedestrians[0]
	check(pedestrian.find_child("Skeleton3D", true, false) != null, "Pedestrian has a rigged human model")
	check(pedestrian.find_child("AnimationPlayer", true, false) != null, "Pedestrian has walking and idle animations")
	check(world.district.find_child("StartingBlock", true, false) != null, "Starting bus-stop block has an identifiable detailed street section")
	world.set_physics_process(false)
	for agent in world.traffic:
		agent.set_physics_process(false)
	world.paused_sim = false
	var bus_visual = bus.find_child("Bus", false, false)
	var cng_visual = cng.find_child("CNG", false, false)
	if bus_visual and cng_visual:
		check(cng_visual.wheels.size() == 3, "CNG animates exactly three wheels")
		for actor in [bus, cng]:
			var visual = actor.find_child("Bus" if actor == bus else "CNG", false, false)
			visual.set_physics_process(false)
			var wheel = visual.wheels[0]
			var radius_point: Vector3 = wheel.global_basis.inverse()*Vector3.UP*visual.wheel_radius
			var before: Vector3 = wheel.to_global(radius_point)
			var displacement: Vector3 = -actor.basis.z*0.12
			visual.previous_position = actor.position
			actor.position += displacement
			actor.speed = 4
			visual._physics_process(1.0/60)
			check((wheel.to_global(radius_point)-before-displacement).dot(-actor.basis.z) > 0.03, "Wheel rolling follows actual forward travel for "+actor.kind)
		check(not cng_visual.brake_materials.is_empty(), "CNG has state-driven brake lenses")
		var door = bus_visual.find_child("door_front_a", true, false)
		bus.dwell = 4
		bus_visual._physics_process(0.2)
		check(door != null and absf(door.rotation.y) > 0.1, "Bus opens its front boarding doors during the actual dwell")
		if door:
			var door_angle: float = door.rotation.y
			world.paused_sim = true
			bus.dwell = 0
			bus_visual._physics_process(0.2)
			check(is_equal_approx(door_angle, door.rotation.y), "Pausing freezes boarding-door animation")
			world.paused_sim = false
			bus_visual._physics_process(1)
			check(absf(door.rotation.y) < 0.01, "Boarding doors close when dwell finishes")
	var pedestrian_visual = pedestrian.find_child("PedestrianVisual", false, false)
	if pedestrian_visual:
		pedestrian.velocity = Vector3(1.25,0,0)
		pedestrian_visual._physics_process(1.0/60)
		check(pedestrian_visual.animation.current_animation == "walk", "Moving pedestrians play the walking clip")
		check(pedestrian_visual.basis.z.dot(Vector3.RIGHT) > 0.99, "Pedestrian faces its actual walking direction")
		for i in range(20):
			await physics_frame
		world.paused_sim = true
		pedestrian_visual._physics_process(1.0/60)
		var paused_time: float = pedestrian_visual.animation.current_animation_position
		for i in range(10):
			await physics_frame
		check(is_equal_approx(paused_time, pedestrian_visual.animation.current_animation_position), "Pausing freezes the pedestrian pose")
		world.paused_sim = false
		pedestrian.velocity = Vector3.ZERO
		pedestrian_visual._physics_process(1.0/60)
		check(pedestrian_visual.animation.current_animation == "idle", "Stopped pedestrians return to idle")
	var props: Array[Node] = world.district.find_children("StreetProps*", "Node3D", true, false)
	check(props.size() >= 6, "Selected block has reusable shopfront props")
	var clear: bool = true
	for prop in props:
		clear = clear and absf(prop.global_position.x+90) > 14 and prop.global_position.z > 22
	check(clear, "Shop props stay beyond the sidewalks and away from the protected crossing")
	var grounded: bool = true
	for mesh in world.district.get_children():
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh and mesh.mesh.size.y > 30 and Vector2(mesh.position.x,mesh.position.z).length() > 220:
			grounded = grounded and absf(mesh.position.y-mesh.mesh.size.y*0.5) < 0.01
	check(grounded, "Background towers meet the ground instead of floating above it")
	world.queue_free()
	await process_frame
	await process_frame
	print("STREET_ART_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
