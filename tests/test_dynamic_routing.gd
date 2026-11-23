extends SceneTree

const Network = preload("res://scripts/road_network.gd")
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
	print("=== Running Dynamic Routing & Travel Time Tests ===")

	# Check 1: Directed links list
	var net_inst = Network.new()
	var has_edges: bool = net_inst.has_method("directed_edges")
	var edges: Array = net_inst.directed_edges() if has_edges else []
	check(edges.size() == 14, "Network provides all 14 directed road links")

	# Check 2: Link free-flow cost
	if net_inst.has_method("link_cost"):
		var empty_signals: Dictionary = {"phase": 5.0, "active_axis": "NS", "crossing": false}
		var link_nw_ne: Dictionary = net_inst.link_cost("NW", "NE", [], empty_signals)
		check(is_equal_approx(link_nw_ne.traversal, 180.0 / 10.0), "North Road free-flow traversal is 18s (180m @ 10m/s)")
		check(link_nw_ne.queue_delay == 0.0, "Clear link has 0 queue delay")
		check(link_nw_ne.signal_wait == 0.0, "Non-signaled junction end has 0 signal wait")

		# Check 3: Signaled junction delay (approach node W)
		var green_ns: Dictionary = {"phase": 5.0, "active_axis": "NS", "crossing": false}
		var red_ns: Dictionary = {"phase": 25.0, "active_axis": "EW", "crossing": false}
		var cost_green: Dictionary = net_inst.link_cost("SW", "W", [], green_ns)
		var cost_red: Dictionary = net_inst.link_cost("SW", "W", [], red_ns)
		check(cost_green.signal_wait == 0.0, "Approach W during NS green has 0 signal wait")
		check(cost_red.signal_wait > 0.0, "Approach W during EW green has positive signal wait for NS traffic")
		check(cost_red.cost > cost_green.cost, "Red signal approach has higher total cost than green")

		# Check 4: Queue delay calculation
		var mock_agent = Node3D.new()
		mock_agent.position = Vector3(-93.2, 0, -20) # on W -> NW link
		mock_agent.set("speed", 0.0)
		mock_agent.set("stopped", true)
		var cost_queued: Dictionary = net_inst.link_cost("W", "NW", [mock_agent], green_ns)
		check(cost_queued.queue_count == 1, "Detects stopped vehicle on directed link")
		check(cost_queued.queue_delay > 2.0, "Queued vehicle adds physical delay to link cost")
		mock_agent.free()
	else:
		check(false, "Network must provide link_cost method")

	# Check 5: Dynamic route estimates
	var dest = Vector3(95.2, 0, -66)
	var origin = Vector3(-93.2, 0, 76)
	if net_inst.has_method("dynamic_route_estimates"):
		var clear_signals: Dictionary = {"phase": 5.0, "active_axis": "NS", "crossing": false}
		var estimates: Dictionary = net_inst.dynamic_route_estimates(origin, dest, [], clear_signals)
		check(estimates.has("north") and estimates.has("middle"), "Estimates include north and middle routes")
		check(estimates.north.seconds > 0 and estimates.middle.seconds > 0, "Estimates return positive seconds")
		check(estimates.has("recommended"), "Estimates indicate recommended fastest route")

		# Check 6: Congestion rerouting recommendation
		var queued_agents: Array = []
		for i in range(5):
			var a = Node3D.new()
			a.position = Vector3(-60.0 + i * 20.0, 0, -3.2) # on Market link W -> E
			a.set("speed", 0.0)
			a.set("stopped", true)
			queued_agents.append(a)
		var congested_middle = net_inst.dynamic_route_estimates(origin, dest, queued_agents, clear_signals)
		check(congested_middle.middle.seconds > congested_middle.north.seconds, "Heavy Market Link queue makes North Road faster")
		check(congested_middle.recommended == "north", "System recommends North Road when Market Link is congested")
		for a in queued_agents:
			a.free()
	else:
		check(false, "Network must provide dynamic_route_estimates method")

	# Check 7: Dynamic route switching in Main
	var main_scene = load("res://scenes/main.tscn")
	var world = main_scene.instantiate()
	root.add_child(world)
	await process_frame
	world.start_mission(false)

	check(world.has_method("switch_route"), "Main provides switch_route method")
	check(world.has_method("toggle_route"), "Main provides toggle_route method")
	var initial_route = world.selected_route
	world.toggle_route()
	check(world.selected_route != initial_route, "toggle_route alternates selected route")
	world.switch_route("middle")
	check(world.selected_route == "middle", "switch_route explicitly sets middle route")
	world.switch_route("north")
	check(world.selected_route == "north", "switch_route explicitly sets north route")

	# Check 8: Turn cues update on route switch at junction approach
	var guidance_north = Network.guidance(Vector3(-93.2, 0, 30), Vector3.FORWARD, "north", dest)
	var guidance_market = Network.guidance(Vector3(-93.2, 0, 30), Vector3.FORWARD, "middle", dest)
	check(guidance_north.distance > 100, "North route announces northern turn distance")
	check(guidance_market.distance < 40, "Market route announces closer market turn distance")

	# Check 9: Driver can reassess to North after overshooting Market turn
	var overshoot_market = Network.guidance(Vector3(-93.2, 0, -15), Vector3.FORWARD, "middle", dest)
	var reassess_north = Network.guidance(Vector3(-93.2, 0, -15), Vector3.FORWARD, "north", dest)
	check(overshoot_market.turn == "return", "Overshooting market turn prompts return")
	check(reassess_north.turn != "return" and reassess_north.distance > 50, "Reassessing to north route gives forward guidance without return")

	world.free()

	print("Dynamic Routing Results: %d checks, %d failures" % [checks, failures.size()])
	print("DYNAMIC_ROUTING_TESTS ", JSON.stringify({"checks": checks, "failures": failures}))
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
