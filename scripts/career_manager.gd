class_name DhakaCareer
extends RefCounted

const USER_FILE: String = "user://career_profile.json"
const FALLBACK_FILE: String = "res://artifacts/career_profile.json"

const DEFAULT_PROFILE: Dictionary = {
	"driver_name": "Dhaka Commuter",
	"total_distance_m": 0.0,
	"total_trips": 0,
	"total_fares_taka": 0.0,
	"best_grade": "None",
	"total_score_sum": 0,
	"sedan_trips": 0,
	"cng_trips": 0,
	"completed_missions": {}
}

static var _cached_profile: Dictionary = {}

static func get_profile() -> Dictionary:
	if _cached_profile.is_empty():
		_cached_profile = load_profile()
	return _cached_profile.duplicate(true)

static func load_profile() -> Dictionary:
	var path: String = USER_FILE if FileAccess.file_exists(USER_FILE) else FALLBACK_FILE
	if not FileAccess.file_exists(path):
		_cached_profile = DEFAULT_PROFILE.duplicate(true)
		return _cached_profile.duplicate(true)
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_cached_profile = DEFAULT_PROFILE.duplicate(true)
		return _cached_profile.duplicate(true)
	
	var json_str = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_str)
	if parsed == null or not (parsed is Dictionary):
		_cached_profile = DEFAULT_PROFILE.duplicate(true)
		return _cached_profile.duplicate(true)
	
	var merged = DEFAULT_PROFILE.duplicate(true)
	for k in parsed:
		if merged.has(k):
			merged[k] = parsed[k]
	_cached_profile = merged
	return _cached_profile.duplicate(true)

static func save_profile(data: Dictionary) -> bool:
	_cached_profile = data.duplicate(true)
	var json_str = JSON.stringify(data, "  ")
	var file = FileAccess.open(USER_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		return true
	var fb_file = FileAccess.open(FALLBACK_FILE, FileAccess.WRITE)
	if fb_file != null:
		fb_file.store_string(json_str)
		fb_file.close()
		return true
	return false

static func record_trip(mission_id: String, vehicle_type: String, distance_m: float, score: int, grade: String, fare_taka: float = 0.0) -> Dictionary:
	var prof = get_profile()
	prof["total_distance_m"] = prof.get("total_distance_m", 0.0) + maxf(0.0, distance_m)
	prof["total_trips"] = prof.get("total_trips", 0) + 1
	prof["total_fares_taka"] = prof.get("total_fares_taka", 0.0) + (maxf(0.0, fare_taka) if vehicle_type == "cng" else 0.0)
	prof["total_score_sum"] = prof.get("total_score_sum", 0) + score
	if vehicle_type == "cng":
		prof["cng_trips"] = prof.get("cng_trips", 0) + 1
	else:
		prof["sedan_trips"] = prof.get("sedan_trips", 0) + 1
	
	var grade_ranks = {"S": 5, "A": 4, "B": 3, "C": 2, "D": 1, "F": 0, "None": -1}
	var cur_best = prof.get("best_grade", "None")
	if grade_ranks.get(grade, 0) > grade_ranks.get(cur_best, -1):
		prof["best_grade"] = grade
	
	var completed = prof.get("completed_missions", {})
	var prev_mission_score = completed.get(mission_id, {}).get("score", 0)
	if score >= prev_mission_score:
		completed[mission_id] = {
			"score": score,
			"grade": grade,
			"vehicle": vehicle_type,
			"timestamp": Time.get_datetime_string_from_system()
		}
	prof["completed_missions"] = completed
	save_profile(prof)
	return prof

static func get_driver_title(prof: Dictionary) -> Dictionary:
	var trips = prof.get("total_trips", 0)
	var avg_score = (float(prof.get("total_score_sum", 0)) / float(maxi(1, trips))) if trips > 0 else 0.0
	if trips >= 5 and avg_score >= 88.0:
		return {"bn": "ওস্তাদ চালক", "en": "Master Dhaka Navigator", "tier": "Veteran"}
	elif trips >= 3 and avg_score >= 75.0:
		return {"bn": "দক্ষ চালক", "en": "Professional Driver", "tier": "Senior"}
	elif trips >= 1:
		return {"bn": "সতর্ক চালক", "en": "Careful Commuter", "tier": "Regular"}
	else:
		return {"bn": "শিক্ষানবিস চালক", "en": "Novice Driver", "tier": "Rookie"}

static func reset_profile() -> Dictionary:
	_cached_profile = DEFAULT_PROFILE.duplicate(true)
	save_profile(_cached_profile)
	return _cached_profile.duplicate(true)
