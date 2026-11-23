class_name DhakaRoadNetwork
extends RefCounted

const NODES = {
	"SW": Vector3(-90, 0, 100), "W": Vector3(-90, 0, 0),
	"NW": Vector3(-90, 0, -100), "NE": Vector3(90, 0, -100),
	"E": Vector3(90, 0, 0), "SE": Vector3(90, 0, 100)
}
const EDGES = [["SW", "W"], ["W", "NW"], ["NW", "NE"],
	["NE", "E"], ["E", "SE"], ["SE", "SW"], ["W", "E"]]
const LOOPS = [
	["SW", "W", "NW", "NE", "E", "SE"],
	["SE", "E", "NE", "NW", "W", "SW"],
	["SW", "W", "E", "SE"], ["NW", "NE", "E", "W"]
]
const ROUTE_LINKS = {
	"north": [["SW", "W"], ["W", "NW"], ["NW", "NE"], ["NE", "E"]],
	"middle": [["SW", "W"], ["W", "E"], ["E", "NE"]],
	"south": [["SW", "SE"], ["SE", "E"], ["E", "NE"]]
}
const CORRIDOR_NODES = {
	"NW": {
		"name": "Farmgate Junction (Ananda Cinema)",
		"bn": "ফার্মগেট মোড় (আনন্দ সিনেমা)",
		"zone": "Farmgate",
		"connecting": ["W", "NE"]
	},
	"W": {
		"name": "Farmgate West (Green Road Link)",
		"bn": "ফার্মগেট পশ্চিম (গ্রিন রোড সংযোগ)",
		"zone": "Farmgate",
		"connecting": ["SW", "NW", "E"]
	},
	"SW": {
		"name": "Tejgaon / Khamarbari",
		"bn": "তেজগাঁও / খামারবাড়ি",
		"zone": "Tejgaon",
		"connecting": ["W", "SE"]
	},
	"NE": {
		"name": "Banglamotor Link (Kazi Nazrul Islam Ave North)",
		"bn": "বাংলামোটর সংযোগ (কাজী নজরুল ইসলাম এভিনিউ উত্তর)",
		"zone": "Banglamotor",
		"connecting": ["NW", "E"]
	},
	"E": {
		"name": "Karwan Bazar Roundabout",
		"bn": "কারওয়ান বাজার গোলচত্বর",
		"zone": "Karwan Bazar",
		"connecting": ["NE", "SE", "W"]
	},
	"SE": {
		"name": "SAARC Fountain / Sonargaon Intersection",
		"bn": "সার্ক ফোয়ারা / সোনারগাঁও মোড়",
		"zone": "Karwan Bazar",
		"connecting": ["E", "SW"]
	}
}
const CORRIDOR_ROADS = {
	"NE->E": {"en": "Kazi Nazrul Islam Avenue (Metro Corridor)", "bn": "কাজী নজরুল ইসলাম এভিনিউ (মেট্রোরেল করিডোর)", "multilane": true},
	"E->NE": {"en": "Kazi Nazrul Islam Avenue (Metro Corridor)", "bn": "কাজী নজরুল ইসলাম এভিনিউ (মেট্রোরেল করিডোর)", "multilane": true},
	"E->SE": {"en": "Kazi Nazrul Islam Avenue South (SAARC Fountain)", "bn": "কাজী নজরুল ইসলাম এভিনিউ দক্ষিণ (সার্ক ফোয়ারা)", "multilane": true},
	"SE->E": {"en": "Kazi Nazrul Islam Avenue South (SAARC Fountain)", "bn": "কাজী নজরুল ইসলাম এভিনিউ দক্ষিণ (সার্ক ফোয়ারা)", "multilane": true},
	"NW->W": {"en": "Farmgate Commercial Arterial", "bn": "ফার্মগেট বাণিজ্যিক করিডোর", "multilane": false},
	"W->NW": {"en": "Farmgate Commercial Arterial", "bn": "ফার্মগেট বাণিজ্যিক করিডোর", "multilane": false},
	"W->SW": {"en": "Khamarbari / Indira Road", "bn": "খামারবাড়ি / ইন্দিরা রোড", "multilane": false},
	"SW->W": {"en": "Khamarbari / Indira Road", "bn": "খামারবাড়ি / ইন্দিরা রোড", "multilane": false},
	"W->E": {"en": "Panthapath Link Road", "bn": "পান্থপথ সংযোগ সড়ক", "multilane": false},
	"E->W": {"en": "Panthapath Link Road", "bn": "পান্থপথ সংযোগ সড়ক", "multilane": false},
	"NW->NE": {"en": "Bijoy Sarani / North Bypass", "bn": "বিজয় সরণি / উত্তর বাইপাস", "multilane": false},
	"NE->NW": {"en": "Bijoy Sarani / North Bypass", "bn": "বিজয় সরণি / উত্তর বাইপাস", "multilane": false},
	"SW->SE": {"en": "Tejgaon Commercial Diversion", "bn": "তেজগাঁও ডাইভারশন সড়ক", "multilane": false},
	"SE->SW": {"en": "Tejgaon Commercial Diversion", "bn": "তেজগাঁও ডাইভারশন সড়ক", "multilane": false}
}
static var conflict_cache: Dictionary = {}

static func corridor_info(node_key: String) -> Dictionary:
	return CORRIDOR_NODES.get(node_key, {
		"name": "Dhaka Corridor Node",
		"bn": "ঢাকা করিডোর পয়েন্ট",
		"zone": "Central Dhaka"
	})

static func corridor_name(from_node: String, to_node: String) -> Dictionary:
	var key: String = from_node + "->" + to_node
	return CORRIDOR_ROADS.get(key, {
		"en": "Connecting Street",
		"bn": "সংযোগ সড়ক",
		"multilane": false
	})

static func is_multilane(from_node: String, to_node: String) -> bool:
	var info: Dictionary = corridor_name(from_node, to_node)
	return info.get("multilane", false)

static func directed_edges() -> Array:
	var edges: Array = []
	for edge in EDGES:
		var u: String = edge[0]
		var v: String = edge[1]
		var d_uv: float = NODES[u].distance_to(NODES[v])
		var spd_uv: float = 8.0 if (u == "W" and v == "E") or (u == "E" and v == "W") else 10.0
		var key_uv = u+"->"+v
		var key_vu = v+"->"+u
		var info_uv = corridor_name(u, v)
		var info_vu = corridor_name(v, u)
		edges.append({"from": u, "to": v, "id": key_uv, "length": d_uv, "free_speed": spd_uv, "corridor": info_uv.en, "multilane": info_uv.get("multilane", false)})
		edges.append({"from": v, "to": u, "id": key_vu, "length": d_uv, "free_speed": spd_uv, "corridor": info_vu.en, "multilane": info_vu.get("multilane", false)})
	return edges

static func link_cost(from_node: String, to_node: String, traffic_agents: Array = [], signal_context: Dictionary = {}) -> Dictionary:
	var start: Vector3 = NODES[from_node]
	var end: Vector3 = NODES[to_node]
	var length: float = start.distance_to(end)
	var dir: Vector3 = (end - start).normalized()
	var lane_offset: Vector3 = left_of(dir) * 3.2
	var p1: Vector3 = start + lane_offset
	var p2: Vector3 = end + lane_offset
	var free_speed: float = 8.0 if (from_node == "W" and to_node == "E") or (from_node == "E" and to_node == "W") else 10.0

	var queue_count: int = 0
	var moving_count: int = 0
	var speed_sum: float = 0.0

	for agent in traffic_agents:
		if not is_instance_valid(agent):
			continue
		var apos: Vector3 = Vector3(agent.position.x, 0, agent.position.z)
		var proj: Vector3 = Geometry3D.get_closest_point_to_segment(apos, p1, p2)
		if apos.distance_to(proj) < 4.5:
			var agent_fwd: Vector3 = (-agent.global_transform.basis.z if agent.is_inside_tree() else -agent.transform.basis.z) if agent is Node3D else dir
			if agent_fwd.dot(dir) > 0.0:
				var spd: float = agent.get("speed") if agent.get("speed") != null else 0.0
				var stopped: bool = agent.get("stopped") == true or spd < 1.0
				if stopped:
					queue_count += 1
				else:
					moving_count += 1
					speed_sum += spd

	var effective_speed: float = free_speed
	if moving_count > 0:
		effective_speed = minf(free_speed, maxf(3.0, speed_sum / moving_count))
	var traversal_time: float = length / effective_speed
	var queue_delay: float = queue_count * 2.8

	var signal_wait: float = 0.0
	if to_node == "W" or to_node == "E":
		var approach_axis: String = "NS" if absf(dir.z) > absf(dir.x) else "EW"
		var active_axis: String = signal_context.get("active_axis", "NS")
		var phase: float = signal_context.get("phase", 0.0)
		var crossing: bool = signal_context.get("crossing", false)
		if crossing:
			signal_wait = 12.0
		elif approach_axis == active_axis and ((approach_axis == "NS" and phase < 14.0) or (approach_axis == "EW" and phase >= 19.0 and phase < 33.0)):
			signal_wait = 0.0
		else:
			if approach_axis == "NS":
				signal_wait = (40.0 - phase) if phase >= 14.0 else 0.0
			else:
				signal_wait = (19.0 - phase) if phase < 19.0 else (40.0 - phase + 19.0)

	var obstacle_delay: float = 0.0
	var obstacles: Array = signal_context.get("obstacles", [])
	for obs in obstacles:
		var obs_pos: Vector3 = obs.get("position", Vector3.ZERO)
		var proj: Vector3 = Geometry3D.get_closest_point_to_segment(obs_pos, p1, p2)
		if obs_pos.distance_to(proj) < 4.0:
			obstacle_delay += 3.5

	var total_cost: float = traversal_time + queue_delay + signal_wait + obstacle_delay
	return {
		"from": from_node, "to": to_node,
		"cost": total_cost,
		"traversal": traversal_time,
		"queue_delay": queue_delay,
		"signal_wait": signal_wait,
		"queue_count": queue_count,
		"length": length
	}

static func link_congestion(from_node: String, to_node: String, traffic_agents: Array = [], signal_context: Dictionary = {}) -> Dictionary:
	var cost_info: Dictionary = link_cost(from_node, to_node, traffic_agents, signal_context)
	var queue: int = cost_info.get("queue_count", 0)
	var level: String = "green"
	var color: Color = Color("2fe695")
	if queue >= 4:
		level = "red"
		color = Color("ef4444")
	elif queue >= 2:
		level = "amber"
		color = Color("f59e0b")
	var ratio: float = clampf(queue / 5.0, 0.0, 1.0)
	return {
		"from": from_node,
		"to": to_node,
		"level": level,
		"queue": queue,
		"color": color,
		"ratio": ratio,
		"cost": cost_info.get("cost", 0.0)
	}

static func all_links_congestion(traffic_agents: Array = [], signal_context: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for edge in EDGES:
		var u: String = edge[0]
		var v: String = edge[1]
		var c_uv = link_congestion(u, v, traffic_agents, signal_context)
		var c_vu = link_congestion(v, u, traffic_agents, signal_context)
		var max_q = maxi(c_uv.queue, c_vu.queue)
		var level = "red" if max_q >= 4 else "amber" if max_q >= 2 else "green"
		var col = Color("ef4444") if level == "red" else Color("f59e0b") if level == "amber" else Color("2fe695")
		result[u + "-" + v] = {
			"edge": edge,
			"level": level,
			"queue": max_q,
			"color": col,
			"dir_uv": c_uv,
			"dir_vu": c_vu
		}
	return result

static func dynamic_route_estimates(start: Vector3, destination: Vector3, traffic_agents: Array = [], signal_context: Dictionary = {}) -> Dictionary:
	var results: Dictionary = {}
	var best_route: String = "north"
	var lowest_seconds: float = INF

	for route_key in ["north", "middle"]:
		var path_pts: PackedVector3Array = route_points(route_key, destination)
		var rem_dist: float = remaining_distance(start, path_pts)
		var links: Array = ROUTE_LINKS[route_key]

		var total_seconds: float = 0.0
		var total_queue: int = 0
		var total_signal: float = 0.0
		var bottleneck_link: String = ""
		var max_link_delay: float = -1.0

		var current_link_idx: int = -1
		var min_dist_to_link: float = INF
		var p_start = Vector3(start.x, 0, start.z)

		for i in range(links.size()):
			var u: String = links[i][0]
			var v: String = links[i][1]
			var u_pos: Vector3 = NODES[u]
			var v_pos: Vector3 = NODES[v]
			var dir: Vector3 = (v_pos - u_pos).normalized()
			var p1: Vector3 = u_pos + left_of(dir) * 3.2
			var p2: Vector3 = v_pos + left_of(dir) * 3.2
			var proj: Vector3 = Geometry3D.get_closest_point_to_segment(p_start, p1, p2)
			var d: float = p_start.distance_to(proj)
			if d < min_dist_to_link:
				min_dist_to_link = d
				current_link_idx = i

		if current_link_idx < 0:
			current_link_idx = 0

		for i in range(links.size()):
			if i < current_link_idx:
				continue
			var u: String = links[i][0]
			var v: String = links[i][1]
			var l_cost: Dictionary = link_cost(u, v, traffic_agents, signal_context)
			var weight: float = 1.0
			if i == current_link_idx:
				var u_pos: Vector3 = NODES[u]
				var v_pos: Vector3 = NODES[v]
				var dir: Vector3 = (v_pos - u_pos).normalized()
				var p2: Vector3 = v_pos + left_of(dir) * 3.2
				var rem_link_dist: float = p_start.distance_to(p2)
				weight = clampf(rem_link_dist / maxf(1.0, l_cost.length), 0.1, 1.0)
			elif i == links.size() - 1:
				var u_pos: Vector3 = NODES[u]
				var v_pos: Vector3 = NODES[v]
				var total_len: float = u_pos.distance_to(v_pos)
				var dest_len: float = u_pos.distance_to(destination)
				weight = clampf(dest_len / maxf(1.0, total_len), 0.2, 1.0)

			var eff_cost: float = l_cost.cost * weight
			total_seconds += eff_cost
			total_queue += l_cost.queue_count
			total_signal += l_cost.signal_wait * weight

			var delay: float = l_cost.queue_delay + l_cost.signal_wait
			if delay > max_link_delay:
				max_link_delay = delay
				bottleneck_link = u + "->" + v

		var min_time: float = rem_dist / (8.0 if route_key == "middle" else 10.0)
		total_seconds = maxf(total_seconds, min_time)

		results[route_key] = {
			"distance": rem_dist,
			"seconds": total_seconds,
			"queue_count": total_queue,
			"signal_wait": total_signal,
			"bottleneck": bottleneck_link,
			"recommended": false
		}

		if total_seconds < lowest_seconds:
			lowest_seconds = total_seconds
			best_route = route_key

	results["recommended"] = best_route
	if results.has(best_route):
		results[best_route]["recommended"] = true

	return results

static func left_of(direction: Vector3) -> Vector3:
	return Vector3(direction.z, 0, -direction.x)

static func loop_movements(route: Array) -> Array:
	var movements: Array = []
	for i in range(route.size()):
		var key: String = route[i]
		var center: Vector3 = NODES[key]
		var incoming: Vector3 = (center-NODES[route[(i+route.size()-1)%route.size()]]).normalized()
		var outgoing: Vector3 = (NODES[route[(i+1)%route.size()]]-center).normalized()
		var corridor: PackedVector3Array = junction_curve(center, incoming, outgoing)
		corridor.insert(0, center-incoming*20+left_of(incoming)*3.2)
		corridor.append(center+outgoing*20+left_of(outgoing)*3.2)
		movements.append({"id": str(route[(i+route.size()-1)%route.size()])+key+str(route[(i+1)%route.size()]),
			"key": key, "center": center, "incoming": incoming,
			"outgoing": outgoing, "corridor": corridor})
	return movements

static func junction_curve(center: Vector3, incoming: Vector3, outgoing: Vector3) -> PackedVector3Array:
	var start: Vector3 = center-incoming*13+left_of(incoming)*3.2
	var end: Vector3 = center+outgoing*13+left_of(outgoing)*3.2
	var control: Vector3 = center+(left_of(incoming)+left_of(outgoing))*3.2
	if incoming.dot(outgoing) > 0.99:
		control = center+left_of(incoming)*3.2
	var points = PackedVector3Array()
	for step in range(16):
		var t: float = float(step)/16
		points.append((1-t)*(1-t)*start+2*(1-t)*t*control+t*t*end)
	return points

static func movements_conflict(a: Dictionary, b: Dictionary) -> bool:
	if a.key != b.key or a.id == b.id:
		return false
	var cache_key: String = a.id+":"+b.id
	if conflict_cache.has(cache_key):
		return conflict_cache[cache_key]
	for i in range(a.corridor.size()-1):
		for j in range(b.corridor.size()-1):
			var nearest: PackedVector3Array = Geometry3D.get_closest_points_between_segments(a.corridor[i], a.corridor[i+1], b.corridor[j], b.corridor[j+1])
			if nearest[0].distance_squared_to(nearest[1]) < 9:
				# shortcut: corridor fits the current 2.45m bus, revise for wider vehicles or new paths.
				conflict_cache[cache_key] = true
				return true
	conflict_cache[cache_key] = false
	return false

static func loop_path(route: Array) -> PackedVector3Array:
	# Left-hand traffic. Sample straight sections and quadratic junction turns.
	var points = PackedVector3Array()
	for i in range(route.size()):
		var a: Vector3 = NODES[route[i]]
		var b: Vector3 = NODES[route[(i + 1) % route.size()]]
		var c: Vector3 = NODES[route[(i + 2) % route.size()]]
		var incoming: Vector3 = (b - a).normalized()
		var outgoing: Vector3 = (c - b).normalized()
		var start: Vector3 = a + incoming * 13 + left_of(incoming) * 3.2
		var end: Vector3 = b - incoming * 13 + left_of(incoming) * 3.2
		var count: int = int(start.distance_to(end) / 2.5)
		for step in range(count):
			points.append(start.lerp(end, float(step) / count))
		points.append_array(junction_curve(b, incoming, outgoing))
	return points

static func route_points(route: String, destination: Vector3) -> PackedVector3Array:
	var origin = Vector3(-93.2, 0, 76)
	if route == "middle":
		return PackedVector3Array([origin, Vector3(-93.2,0,-3.2), Vector3(86.8,0,-3.2), Vector3(86.8,0,destination.z), destination])
	elif route == "south":
		return PackedVector3Array([origin, Vector3(-93.2,0,103.2), Vector3(93.2,0,103.2), Vector3(86.8,0,destination.z), destination])
	return PackedVector3Array([origin, Vector3(-93.2,0,-103.2), Vector3(93.2,0,-103.2), Vector3(93.2,0,destination.z), destination])

static func route_distance(start: Vector3, destination: Vector3, middle_delay: float = 0.0, north_delay: float = 0.0, traffic_agents: Array = [], signal_context: Dictionary = {}) -> Dictionary:
	if traffic_agents.is_empty() and signal_context.is_empty():
		var middle_distance: float = remaining_distance(start, route_points("middle", destination))
		var north_distance: float = remaining_distance(start, route_points("north", destination))
		var delay_scale: float = clampf(start.distance_to(destination)/120, 0, 1)
		return {
			"middle": {"distance": middle_distance, "seconds": middle_distance / 8.0 + middle_delay*delay_scale},
			"north": {"distance": north_distance, "seconds": north_distance / 10.0 + north_delay*delay_scale}
		}
	return dynamic_route_estimates(start, destination, traffic_agents, signal_context)

static func guidance(position: Vector3, forward: Vector3, route: String, destination: Vector3) -> Dictionary:
	var point = Vector3(position.x,0,position.z)
	var arrival_distance: float = point.distance_to(destination)
	if arrival_distance < 10:
		return {"turn": "stop", "distance": arrival_distance, "target": destination}
	var path: PackedVector3Array = route_points(route, destination)
	var nearest: float = INF
	var index: int = 0
	var projection: Vector3
	for i in range(path.size()-1):
		var projected: Vector3 = Geometry3D.get_closest_point_to_segment(point, path[i], path[i+1])
		var deviation: float = projected.distance_to(point)
		if deviation < nearest:
			nearest = deviation
			index = i
			projection = projected
	if nearest > 18:
		return {"turn": "rejoin", "distance": nearest, "target": projection}
	if nearest > 5 and forward.dot((projection-point).normalized()) < -0.4:
		return {"turn": "return", "distance": nearest, "target": projection}
	var incoming: Vector3 = (path[index+1]-path[index]).normalized()
	if forward.dot(incoming) < -0.4 or forward.dot((path[index+1]-point).normalized()) < -0.4:
		return {"turn": "return", "distance": point.distance_to(path[index+1]), "target": path[index+1]}
	var turn: String = "stop"
	if index < path.size()-2:
		var outgoing: Vector3 = (path[index+2]-path[index+1]).normalized()
		var cross_y: float = incoming.cross(outgoing).y
		turn = "right" if cross_y < -0.2 else "left" if cross_y > 0.2 else "straight"
	return {"turn": turn, "distance": point.distance_to(path[index+1]), "target": path[index+1]}

static func remaining_distance(position: Vector3, path: PackedVector3Array) -> float:
	var nearest: float = INF
	var remaining: float = 0
	for i in range(path.size()-1):
		var projected: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3(position.x,0,position.z), path[i], path[i+1])
		var deviation: float = projected.distance_to(Vector3(position.x,0,position.z))
		if deviation < nearest:
			nearest = deviation
			remaining = deviation + projected.distance_to(path[i+1])
			for j in range(i+1, path.size()-1):
				remaining += path[j].distance_to(path[j+1])
	return remaining
