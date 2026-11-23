class_name DhakaMissions
extends RefCounted

const MISSIONS: Dictionary = {
	"interview": {
		"id": "interview",
		"index": 1,
		"tag": "01 / THE MORNING JOURNEY",
		"title_en": "Morning Interview",
		"title_bn": "ইন্টারভিউ আছে আজ!",
		"objective": "Reach the office on the east road. Stop inside the marked bay.",
		"briefing": "Your interview starts at 09:30.\nThe city has its own plans.\nReach the office on the east road. Stop inside the marked bay. Choose a route, read the traffic, and give people space.",
		"destination_name": "Office Bay",
		"destination_marker": "অফিস / OFFICE\n↓",
		"arrival_point": Vector3(95.2, 0, -66.0),
		"clock_start_minutes": 564, # 09:24 AM
		"clock_format": "AM",
		"deadline_seconds": 120.0,
		"target_time_str": "09:30 AM",
		"time_of_day": "morning",
		"weather": "clear"
	},
	"delivery": {
		"id": "delivery",
		"index": 2,
		"tag": "02 / MIDDAY COURIER",
		"title_en": "Urgent File Delivery",
		"title_bn": "জরুরি ফাইল ডেলিভারি",
		"objective": "Rush critical contracts to the courier hub before 02:20 PM cutoff.",
		"briefing": "High urgency express run!\nThe courier van leaves at 02:20 PM sharp.\nTight time budget. Read junction queues, pick fastest routes, and avoid deadlocks.",
		"destination_name": "Courier Hub",
		"destination_marker": "কুরিয়ার / COURIER\n↓",
		"arrival_point": Vector3(95.2, 0, -66.0),
		"clock_start_minutes": 856, # 02:16 PM
		"clock_format": "PM",
		"deadline_seconds": 85.0,
		"target_time_str": "02:20 PM",
		"time_of_day": "midday",
		"weather": "clear"
	},
	"evening": {
		"id": "evening",
		"index": 3,
		"tag": "03 / DUSK COMMUTE",
		"title_en": "Twilight Return",
		"title_bn": "সন্ধ্যার বাড়ি ফেরা",
		"objective": "Navigate dusk rush hour to the transit terminal before 06:55 PM.",
		"briefing": "Evening rush hour settles over the district.\nDusk lighting, lower visibility. Switch on headlights [L], respect signals, and provide safe following cushions.",
		"destination_name": "Transit Bay",
		"destination_marker": "টার্মিনাল / TERMINAL\n↓",
		"arrival_point": Vector3(95.2, 0, -66.0),
		"clock_start_minutes": 1127, # 06:47 PM
		"clock_format": "PM",
		"deadline_seconds": 140.0,
		"target_time_str": "06:55 PM",
		"time_of_day": "evening",
		"weather": "clear"
	},
	"monsoon": {
		"id": "monsoon",
		"index": 4,
		"tag": "04 / MONSOON DOWNPOUR",
		"title_en": "Monsoon Commute",
		"title_bn": "বর্ষার ঢাকা — জরুরি যাত্রা",
		"objective": "Traverse flooded Farmgate–Karwan Bazar under torrential monsoon downpour.",
		"briefing": "Tropical monsoon strikes the capital!\nHeavy downpour, flooded gutters, and reduced road grip.\nActivate wipers [K], maintain extra following distance, and navigate past water accumulation.",
		"destination_name": "Terminal Bay",
		"destination_marker": "টার্মিনাল / TERMINAL\n↓",
		"arrival_point": Vector3(95.2, 0, -66.0),
		"clock_start_minutes": 998, # 04:38 PM
		"clock_format": "PM",
		"deadline_seconds": 150.0,
		"target_time_str": "04:38 PM",
		"time_of_day": "monsoon",
		"weather": "monsoon"
	},
	"shahbag_uttara": {
		"id": "shahbag_uttara",
		"index": 5,
		"tag": "05 / EXPRESSWAY GRAND CORRIDOR",
		"title_en": "Shahbag to Uttara Express",
		"title_bn": "শাহবাগ থেকে উত্তরা এক্সপ্রেস",
		"objective": "Traverse the 20.5km elevated flyover corridor from Shahbag to Uttara Terminal Plaza.",
		"briefing": "High-speed expressway run across 7 iconic Dhaka sectors!\nNavigate elevated Mohakhali flyover, Banani commercial towers, Kuril loops, and Airport Terminal 3.\nDynamic animated falling rain active. Avoid high-speed collisions to prevent strict DMP Police pursuit!",
		"destination_name": "Uttara Terminal Plaza",
		"destination_marker": "উত্তরা / UTTARA\n↓",
		"arrival_point": Vector3(0.0, 7.5, -2550.0),
		"spawn_point": Vector3(0.0, 7.8, 160.0),
		"clock_start_minutes": 660, # 11:00 AM
		"clock_format": "AM",
		"deadline_seconds": 240.0,
		"target_time_str": "11:20 AM",
		"time_of_day": "monsoon",
		"weather": "monsoon",
		"is_expressway": true
	}
}

static func get_mission(id: String) -> Dictionary:
	if MISSIONS.has(id):
		return MISSIONS[id].duplicate(true)
	return MISSIONS["interview"].duplicate(true)

static func get_all_missions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for key in ["interview", "delivery", "evening", "monsoon"]:
		list.append(MISSIONS[key].duplicate(true))
	return list

static func calculate_score(mission_id: String, elapsed: float, collisions: int, red_lights: int, recoveries: int, speeding_seconds: float, failed: bool) -> Dictionary:
	var mission: Dictionary = get_mission(mission_id)
	var deadline: float = mission.get("deadline_seconds", 120.0)

	if failed:
		return {
			"failed": true,
			"safety": 0,
			"punctuality": 0,
			"compliance": 0,
			"total_score": 0,
			"grade": "F",
			"grade_title_bn": "ব্যর্থ",
			"grade_title_en": "MISSION FAILED",
			"message": "A pedestrian collision ended this journey. Give people more space.",
			"passed": false
		}

	var safety: int = maxi(0, 100 - collisions * 22)
	var punctuality: int = maxi(0, 100 - int(maxf(0.0, elapsed - deadline) * 1.0))
	var compliance: int = maxi(0, 100 - red_lights * 20 - recoveries * 10 - int(speeding_seconds))
	var total_score: int = clampi(roundi(safety * 0.35 + punctuality * 0.35 + compliance * 0.30), 0, 100)

	var grade: String = "D"
	var grade_title_bn: String = "বেপরোয়া"
	var grade_title_en: String = "RECKLESS"
	var msg: String = ""

	if collisions == 0 and red_lights == 0 and elapsed <= deadline and total_score >= 95:
		grade = "S"
		grade_title_bn = "ওস্তাদ চালক"
		grade_title_en = "MASTER DRIVER"
		msg = "Flawless run! You reached %s on time with zero incidents." % mission.destination_name
	elif total_score >= 80:
		grade = "A"
		grade_title_bn = "দক্ষ চালক"
		grade_title_en = "PROFESSIONAL"
		msg = "Excellent navigation! Delivered safely and on schedule."
	elif total_score >= 65:
		grade = "B"
		grade_title_bn = "সতর্ক চালক"
		grade_title_en = "CAREFUL DRIVER"
		msg = "Arrived safely at %s with minor traffic delays." % mission.destination_name
	elif total_score >= 50:
		grade = "C"
		grade_title_bn = "তাড়াহুড়ো চালক"
		grade_title_en = "RUSHED DRIVER"
		msg = "You arrived late. Getting here safely still matters."
	else:
		grade = "D"
		grade_title_bn = "বেপরোয়া চালক"
		grade_title_en = "IMPRUDENT"
		msg = "Journey completed with multiple infractions. Review road rules."

	return {
		"failed": false,
		"safety": safety,
		"punctuality": punctuality,
		"compliance": compliance,
		"total_score": total_score,
		"grade": grade,
		"grade_title_bn": grade_title_bn,
		"grade_title_en": grade_title_en,
		"message": msg,
		"passed": true
	}

static func narrative_cue(mission_id: String, event_name: String, ctx: Dictionary = {}) -> Dictionary:
	if mission_id == "monsoon":
		match event_name:
			"start":
				return {"bn": "কন্ট্রোল: ভারী বৃষ্টি শুরু হয়েছে। ওয়াইপার [K] চালু করুন এবং ব্রেক চেপে সাবধানে চালান।", "en": "Control: Torrential downpour active. Turn on wipers [K] and watch for standing water."}
			"signal_wait":
				return {"bn": "কন্ট্রোল: বৃষ্টির কারণে দৃশ্যমানতা কম, সিগন্যালে পর্যাপ্ত দূরত্ব বজায় রাখুন।", "en": "Control: Low visibility in rain; maintain safe buffer at the red signal."}
			"reroute_advice":
				return {"bn": "কন্ট্রোল: উত্তর সড়কে যানজট বেশি, বিকল্প লেন বিবেচনা করুন।", "en": "Control: Water accumulation detected. Consider switching routes."}
			"hurry_up":
				return {"bn": "কন্ট্রোল: সময় ঘনিয়ে আসছে! ভেজা সড়কে সাবধানে গতি বাড়ান।", "en": "Control: Deadline near! Accelerate smoothly on wet asphalt."}
			"near_goal":
				return {"bn": "কন্ট্রোল: টার্মিনাল কাছাকাছি। ওয়াটার স্প্ল্যাশ এড়িয়ে বে-তে গাড়ি থামান।", "en": "Control: Approaching terminal bay. Brake smoothly into the arrival bay."}
	var cues: Dictionary = {
		"start": {
			"bn": "কন্ট্রোল: যাত্রা শুরু করুন। সাবধানে চালান!",
			"en": "Control: Route clear. Proceed to destination safely."
		},
		"signal_wait": {
			"bn": "সিগন্যাল লাল। লাইনের পেছনে অপেক্ষা করুন।",
			"en": "Signal is red. Hold position behind the stop line."
		},
		"junction_clear": {
			"bn": "জংশন ক্লিয়ার। স্বাভাবিক গতি বজায় রাখুন।",
			"en": "Junction cleared. Maintain steady traffic flow."
		},
		"reroute_advice": {
			"bn": "বিকল্প রাস্তা ফাঁকা! [T] চেপে রুট বদল করতে পারেন।",
			"en": "Alternative corridor clearer. Press [T] to switch."
		},
		"hurry_up": {
			"bn": "সময় কমে আসছে! সময়মতো পৌঁছানোর চেষ্টা করুন।",
			"en": "Clock running down! Keep moving forward safely."
		},
		"near_goal": {
			"bn": "লক্ষ্য সামনে দেখা যাচ্ছে! পার্কিং বে-তে ব্রেক করুন।",
			"en": "Destination in sight! Brake and stop in the marked bay."
		}
	}
	if cues.has(event_name):
		return cues[event_name]
	return {"bn": "", "en": ""}
