extends CanvasLayer

const Settings = preload("res://scripts/settings_manager.gd")
const Missions = preload("res://scripts/mission_manager.gd")
const INK = Color("102c32")
const PAPER = Color("f1ebdb")
const GOLD = Color("edbc73")
var manager: Node
var root: Control
var speed_label: Label
var gear_label: Label
var acceleration_label: Label
var dashboard: Control
var navigation: Panel
var turn_label: Label
var turn_distance: Label
var cue: Dictionary = {"turn": "right", "distance": 176.0}
var navigation_direction: Vector2 = Vector2.UP
var clock_label: Label
var status_label: Label
var detail_label: Label
var signal_label: Label
var menu: PanelContainer
var menu_box: VBoxContainer
var map: Control
var debug_label: Label
var dark_style: StyleBoxFlat
var font: Font
var tick: float = 0
var map_visible: bool = true
var route_buttons: Dictionary = {}
var dispatch_panel: PanelContainer
var dispatch_bn: Label
var dispatch_en: Label
var dispatch_timer: float = 0.0

func _ready() -> void:
	font = load("res://assets/fonts/NotoSansBengali.ttf")
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	root.theme = theme
	var top_band = ColorRect.new()
	top_band.color = Color(0.025, 0.065, 0.075, 0.76)
	top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_bottom = 105
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_band)
	dark_style = _style(Color(0.035, 0.09, 0.105, 0.92), 14)
	var brand = _label(root, "DHAKA / DEADLINE", 26, PAPER)
	brand.position = Vector2(38, 27)
	_label_at(root, "ঢাকা ডেডলাইন    /    EVERY MINUTE IS A DECISION", Vector2(40, 68), 13, GOLD)
	var area = _label(root, "FARMGATE – KARWAN BAZAR CORRIDOR", 14, PAPER)
	area.anchor_left = 0.5
	area.anchor_right = 0.5
	area.offset_left = -175
	area.offset_right = 175
	area.offset_top = 35
	area.offset_bottom = 65
	clock_label = _label(root, "09:24 AM", 30, PAPER)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position += Vector2(-195, 26)
	var appointment = _label(root, "INTERVIEW   09:30", 13, GOLD)
	appointment.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	appointment.position += Vector2(-193, 68)
	dashboard = _panel(root, Vector2(38, -264), Vector2(354, 222), Control.PRESET_BOTTOM_LEFT)
	dashboard.draw.connect(_draw_dashboard)
	speed_label = _label_at(dashboard, "00", Vector2(46, 54), 62, PAPER)
	speed_label.custom_minimum_size.x = 146
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_at(dashboard, "KM/H", Vector2(103, 127), 15, Color("a8bbb8"))
	gear_label = _label_at(dashboard, "N", Vector2(251, 19), 35, GOLD)
	_label_at(dashboard, "DRIVE", Vector2(244, 65), 11, Color("a8bbb8"))
	acceleration_label = _label_at(dashboard, "+0.0 m/s²", Vector2(219, 179), 17, PAPER)
	navigation = _panel(root, Vector2(-211, 119), Vector2(422, 101), Control.PRESET_CENTER_TOP)
	turn_label = _label_at(navigation, "TURN RIGHT", Vector2(90, 16), 20, PAPER)
	turn_distance = _label_at(navigation, "176 m  /  North road", Vector2(90, 49), 15, GOLD)
	navigation.draw.connect(_draw_navigation)
	var info = _panel(root, Vector2(414, -152), Vector2(500, 110), Control.PRESET_BOTTOM_LEFT)
	status_label = _label_at(info, "GET READY TO LEAVE", Vector2(22, 17), 17, PAPER)
	detail_label = _label_at(info, "Choose your route and begin.", Vector2(22, 54), 13, Color("b7c4bd"))
	signal_label = _label_at(root, "LEFT-HAND TRAFFIC  /  KEEP CLEAR OF CROSSINGS", Vector2(40, -186), 12, PAPER)
	signal_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	signal_label.offset_left = 414
	signal_label.offset_right = 1100
	signal_label.offset_top = -195
	signal_label.offset_bottom = -160
	signal_label.add_theme_font_size_override("font_size", 17)
	signal_label.add_theme_color_override("font_shadow_color", INK)
	signal_label.add_theme_constant_override("shadow_offset_x", 2)
	signal_label.add_theme_constant_override("shadow_offset_y", 2)
	map = Control.new()
	map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	map.position = Vector2(-317, -282)
	map.size = Vector2(280, 244)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.draw.connect(_draw_map)
	root.add_child(map)
	var controls = _label(root, "WASD / ARROWS  drive     SPACE  handbrake     Q  reverse     C  camera     V  vehicle     H  horn     L  lights     K  wipers     M  map     T  reroute     ESC  pause", 12, PAPER)
	controls.anchor_top = 1
	controls.anchor_bottom = 1
	controls.offset_left = 38
	controls.offset_right = 1500
	controls.offset_top = -27
	controls.offset_bottom = -5
	controls.add_theme_color_override("font_shadow_color", Color("102c32"))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	debug_label = _label_at(root, "", Vector2(40, 110), 13, GOLD)
	debug_label.visible = false
	_setup_radio_dispatch_ui(root)
	show_intro()

func _setup_radio_dispatch_ui(parent: Control) -> void:
	dispatch_panel = PanelContainer.new()
	dispatch_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dispatch_panel.offset_left = -260
	dispatch_panel.offset_top = 20
	dispatch_panel.offset_right = 260
	dispatch_panel.offset_bottom = 85
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.10, 0.12, 0.94)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = GOLD
	dispatch_panel.add_theme_stylebox_override("panel", style)
	
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	dispatch_panel.add_child(box)
	
	var header = Label.new()
	header.text = "RADIO DISPATCH / কন্ট্রোল রুম"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", GOLD)
	box.add_child(header)
	
	dispatch_bn = Label.new()
	dispatch_bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dispatch_bn.add_theme_font_override("font", font)
	dispatch_bn.add_theme_font_size_override("font_size", 14)
	dispatch_bn.add_theme_color_override("font_color", PAPER)
	box.add_child(dispatch_bn)
	
	dispatch_en = Label.new()
	dispatch_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dispatch_en.add_theme_font_override("font", font)
	dispatch_en.add_theme_font_size_override("font_size", 12)
	dispatch_en.add_theme_color_override("font_color", Color("bac8c0"))
	box.add_child(dispatch_en)
	
	dispatch_panel.visible = false
	parent.add_child(dispatch_panel)

func show_radio_dispatch(bn: String, en: String) -> void:
	if not is_instance_valid(dispatch_panel):
		return
	dispatch_bn.text = bn
	dispatch_en.text = en
	dispatch_panel.visible = true
	dispatch_timer = 4.5

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.8, 0.85, 0.8, 0.14)
	return style

func _label(parent: Node, message: String, size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _label_at(parent: Node, message: String, pos: Vector2, size: int, color: Color) -> Label:
	var label = _label(parent, message, size, color)
	label.position = pos
	return label

func _panel(parent: Control, pos: Vector2, bounds: Vector2, preset: int = Control.PRESET_TOP_LEFT) -> Panel:
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(preset)
	panel.offset_left = pos.x
	panel.offset_top = pos.y
	panel.offset_right = pos.x+bounds.x
	panel.offset_bottom = pos.y+bounds.y
	panel.add_theme_stylebox_override("panel", dark_style)
	parent.add_child(panel)
	return panel

func _open_menu() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	menu = PanelContainer.new()
	menu.position = Vector2(38, 25)
	menu.custom_minimum_size = Vector2(560, 0)
	menu.add_theme_stylebox_override("panel", dark_style)
	root.add_child(menu)
	var margins = MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_bottom", 16)
	menu.add_child(margins)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 8)
	margins.add_child(menu_box)

func _paragraph(message: String, size: int = 17, color: Color = PAPER) -> Label:
	var label = _label(menu_box, message, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 470
	return label

func _button(message: String, callback: Callable, primary: bool = false) -> Button:
	return _button_in(menu_box, message, callback, primary, 44)

func _button_in(parent: Node, message: String, callback: Callable, primary: bool = false, min_h: int = 38) -> Button:
	var button = Button.new()
	button.text = message
	button.custom_minimum_size.y = min_h
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("203e43"), 6))
	button.add_theme_stylebox_override("hover", _style(Color("f4ce92") if primary else Color("31565a"), 6))
	button.add_theme_stylebox_override("pressed", _style(Color("d9a45d"), 6))
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK if primary else PAPER)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_intro() -> void:
	_open_menu()
	var mission: Dictionary = manager.active_mission if is_instance_valid(manager) and manager.active_mission.size() > 0 else Missions.get_mission("interview")
	_paragraph(mission.tag, 11, GOLD)
	_paragraph(mission.title_bn, 26)
	_paragraph("%s  ·  Target: %s" % [mission.title_en, mission.target_time_str], 14, Color("bac8c0"))
	
	_paragraph("SELECT MISSION / মিশন নির্বাচন", 11, GOLD)
	var all_m = Missions.get_all_missions()
	var cur_id = manager.active_mission_id if is_instance_valid(manager) else "interview"
	var m_grid = GridContainer.new()
	m_grid.columns = 2
	m_grid.add_theme_constant_override("h_separation", 8)
	m_grid.add_theme_constant_override("v_separation", 6)
	menu_box.add_child(m_grid)
	for m in all_m:
		var active_bullet = "●" if m.id == cur_id else "○"
		_button_in(m_grid, "%s %02d: %s" % [active_bullet, m.index, m.title_en], func():
			manager.set_active_mission(m.id)
			show_intro()
		, m.id == cur_id, 34)

	_paragraph("SELECT VEHICLE / বাহন নির্বাচন", 11, GOLD)
	var cur_veh: String = manager.player.vehicle_type if is_instance_valid(manager) and is_instance_valid(manager.player) else "car"
	var v_box = HBoxContainer.new()
	v_box.add_theme_constant_override("separation", 8)
	menu_box.add_child(v_box)
	_button_in(v_box, "%s Sedan (প্রাইভেট কার)" % ("●" if cur_veh == "car" else "○"), func():
		if is_instance_valid(manager) and is_instance_valid(manager.player):
			manager.player.set_vehicle_type("car")
			show_intro()
	, cur_veh == "car", 36)
	_button_in(v_box, "%s Green CNG (সিএনজি ৩-হুইলার)" % ("●" if cur_veh == "cng" else "○"), func():
		if is_instance_valid(manager) and is_instance_valid(manager.player):
			manager.player.set_vehicle_type("cng")
			show_intro()
	, cur_veh == "cng", 36)

	_paragraph("CHOOSE YOUR FIRST ROUTE", 11, GOLD)
	var r_box = HBoxContainer.new()
	r_box.add_theme_constant_override("separation", 8)
	menu_box.add_child(r_box)
	route_buttons["north"] = _button_in(r_box, "", func(): _choose_route("north"), false, 36)
	route_buttons["middle"] = _button_in(r_box, "", func(): _choose_route("middle"), false, 36)
	_choose_route(manager.selected_route)

	var start_btn = _button("START JOURNEY  →", func(): manager.start_mission(false), true)
	start_btn.custom_minimum_size.y = 44
	start_btn.add_theme_font_size_override("font_size", 16)

	var act_box = HBoxContainer.new()
	act_box.add_theme_constant_override("separation", 6)
	menu_box.add_child(act_box)
	_button_in(act_box, "🏙 Free Roam", func(): manager.start_mission(true), false, 34)
	_button_in(act_box, "🏆 Career", func(): show_career_profile(), false, 34)
	_button_in(act_box, "⚙ Settings", func(): show_settings(false), false, 34)
	_button_in(act_box, "📜 Credits", func(): show_credits(), false, 34)
	_paragraph("Dhaka-inspired test district • fictional streets\nPowered by Poly Haven · CC0 surfaces & sky", 11, Color("8ba59d"))

func update_mission_display() -> void:
	if is_instance_valid(menu):
		show_intro()

func _choose_route(route: String) -> void:
	manager.selected_route = route
	var estimates: Dictionary = manager.route_estimates()
	for key in route_buttons:
		if not is_instance_valid(route_buttons[key]):
			continue
		var estimate: Dictionary = estimates[key]
		var low: int = maxi(1, floori(estimate.seconds*3/60))
		var high: int = low+2
		var is_fastest: bool = (estimates.get("recommended") == key)
		route_buttons[key].text = "%s %s  /  ~%d–%d min%s" % [
			"●" if key == route else "○",
			"NORTH ROAD" if key == "north" else "MARKET LINK",
			low, high,
			"  ★ FASTEST" if is_fastest else ""
		]

func hide_menu() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null

func show_pause() -> void:
	_open_menu()
	_paragraph("JOURNEY PAUSED", 13, GOLD)
	_paragraph("একটু বিরতি", 34)
	_button("Continue journey", func(): manager.toggle_pause(), true)
	_paragraph("REASSESS ROUTE  /  LIVE ETA", 12, GOLD)
	var estimates: Dictionary = manager.route_estimates()
	for r in ["north", "middle"]:
		var est: Dictionary = estimates[r]
		var low: int = maxi(1, floori(est.seconds*3/60))
		var high: int = low+2
		var r_label: String = "%s %s  /  ~%d–%d min  (%d in queue)%s" % [
			"●" if manager.selected_route == r else "○",
			"NORTH ROAD" if r == "north" else "MARKET LINK",
			low, high, est.queue_count,
			"  ★ FASTEST" if estimates.get("recommended") == r else ""
		]
		_button(r_label, func():
			manager.switch_route(r)
			show_pause()
		)
	_button("Settings & Quality", func(): show_settings(true))
	_button("Driver Career Profile", func(): show_career_profile())
	_button("Restart mission", func(): manager.restart_mission())
	_button("Quit to desktop", func(): manager.get_tree().quit())
	_paragraph("C camera   R recover   F3 diagnostics   T reroute", 15, Color("bac8c0"))

func show_settings(from_pause: bool = false) -> void:
	_open_menu()
	_paragraph("SETTINGS & CONFIGURATION", 13, GOLD)
	_paragraph("কনফিগারেশন", 34)

	var cfg: Dictionary = Settings.current if not Settings.current.is_empty() else Settings.load_settings()

	var cur_preset: String = cfg.graphics.get("preset", "high")
	_paragraph("GRAPHICS QUALITY PRESET", 12, GOLD)
	_button("PRESET: %s  (Cycle: Low / Med / High)" % cur_preset.to_upper(), func():
		var next_p: String = "low" if cur_preset == "high" else "medium" if cur_preset == "low" else "high"
		var p_vals: Dictionary = Settings.get_preset_values(next_p)
		for k in p_vals:
			cfg.graphics[k] = p_vals[k]
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		show_settings(from_pause)
	)

	var cur_mode: String = cfg.graphics.get("mode", "windowed")
	var cur_res: String = cfg.graphics.get("resolution", "1600x900")
	_button("DISPLAY: %s  |  RES: %s" % [cur_mode.to_upper(), cur_res], func():
		if cur_mode == "windowed":
			cfg.graphics.mode = "fullscreen"
		else:
			cfg.graphics.mode = "windowed"
			cfg.graphics.resolution = "1920x1080" if cur_res == "1600x900" else "1280x720" if cur_res == "1920x1080" else "1600x900"
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		show_settings(from_pause)
	)

	_paragraph("AUDIO VOLUMES (0–100%)", 12, GOLD)
	var master_vol: int = cfg.audio.get("master", 100)
	var engine_vol: int = cfg.audio.get("engine", 80)
	var traffic_vol: int = cfg.audio.get("traffic", 70)
	var ambience_vol: int = cfg.audio.get("ambience", 70)
	var sfx_vol: int = cfg.audio.get("sfx", 85)

	_button("Master Volume: %d%%  (Cycle: 0 / 50 / 80 / 100)" % master_vol, func():
		cfg.audio.master = 0 if master_vol == 100 else 50 if master_vol == 0 else 80 if master_vol == 50 else 100
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		show_settings(from_pause)
	)

	_button("Engine: %d%%  |  Traffic: %d%%" % [engine_vol, traffic_vol], func():
		cfg.audio.engine = 50 if engine_vol >= 80 else 100 if engine_vol <= 50 else 80
		cfg.audio.traffic = 50 if traffic_vol >= 70 else 100 if traffic_vol <= 50 else 70
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		show_settings(from_pause)
	)

	_button("Ambience: %d%%  |  SFX: %d%%" % [ambience_vol, sfx_vol], func():
		cfg.audio.ambience = 40 if ambience_vol >= 70 else 100 if ambience_vol <= 40 else 70
		cfg.audio.sfx = 50 if sfx_vol >= 85 else 100 if sfx_vol <= 50 else 85
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		show_settings(from_pause)
	)

	_button("SAVE & BACK  ←", func():
		Settings.apply_all(cfg, manager.get_viewport())
		Settings.save_settings(cfg)
		if from_pause:
			show_pause()
		else:
			show_intro()
	, true)

func show_results(result: Dictionary) -> void:
	_open_menu()
	var is_failed: bool = result.get("failed", false)
	var grade: String = result.get("grade", "D" if not is_failed else "F")
	var grade_bn: String = result.get("grade_title_bn", "বেপরোয়া" if not is_failed else "ব্যর্থ")
	var grade_en: String = result.get("grade_title_en", "RECKLESS" if not is_failed else "FAILED")
	var grade_color: Color = Color("76f7c8") if grade in ["S", "A"] else (GOLD if grade == "B" else (Color("ffb586") if grade in ["C", "D"] else Color("ff6b6b")))
	
	_paragraph("JOURNEY COMPLETE" if not is_failed else "JOURNEY STOPPED", 13, GOLD)
	_paragraph("[%s]  %s" % [grade, grade_bn], 36, grade_color)
	_paragraph(grade_en, 16, Color("bac8c0"))
	_paragraph(result.get("message", ""), 18)
	_paragraph("OVERALL SCORE  %d / 100\nSAFETY  %d / 100  ·  PUNCTUALITY  %d / 100  ·  COMPLIANCE  %d / 100" % [result.get("total_score", 0), result.get("safety", 0), result.get("punctuality", 0), result.get("compliance", 0)], 17, PAPER)
	_paragraph("%d collisions  ·  %d red lights  ·  %d recoveries  ·  %.1fs elapsed" % [manager.player.collision_count, manager.red_lights, manager.recoveries, manager.elapsed], 14, Color("bac8c0"))
	
	var missions = Missions.get_all_missions()
	var current_idx: int = manager.active_mission.get("index", 1) if is_instance_valid(manager) and manager.active_mission.size() > 0 else 1
	if not is_failed and current_idx < missions.size():
		var next_m = missions[current_idx]
		_button("Next Mission: %s  →" % next_m.title_en, func():
			manager.set_active_mission(next_m.id)
			manager.restart_mission()
		, true)
		_button("Retry current mission", func(): manager.restart_mission())
	else:
		_button("Try the journey again", func(): manager.restart_mission(), true)
	_button("Choose another mission", func():
		hide_menu()
		manager.started = false
		manager.finished = false
		show_intro()
	)
	_button("View Driver Career Profile", func(): show_career_profile())
	_button("Settings & Quality", func(): show_settings(false))
	_button("Quit to desktop", func(): manager.get_tree().quit())

func show_career_profile() -> void:
	_open_menu()
	var Career = preload("res://scripts/career_manager.gd")
	var prof = Career.get_profile()
	var title = Career.get_driver_title(prof)
	_paragraph("DRIVER CAREER PROFILE", 11, GOLD)
	_paragraph("%s (%s)" % [title.bn, title.en], 24, GOLD)
	_paragraph("Career Status: %s Division" % title.tier, 13, Color("bac8c0"))
	
	var km: float = prof.get("total_distance_m", 0.0) / 1000.0
	var trips: int = prof.get("total_trips", 0)
	var fares: float = prof.get("total_fares_taka", 0.0)
	var avg_score: float = (float(prof.get("total_score_sum", 0)) / float(maxi(1, trips))) if trips > 0 else 0.0
	var best_grd: String = prof.get("best_grade", "None")
	
	_paragraph("LIFETIME DISTANCE:  %.2f km\nJOURNEYS COMPLETED:  %d trips  (Sedan: %d  ·  CNG: %d)\nTOTAL FARES EARNED:  ৳ %.0f Taka\nAVERAGE SAFETY SCORE:  %.1f / 100\nHIGHEST RANK ACHIEVED:  Grade [%s]" % [km, trips, prof.get("sedan_trips", 0), prof.get("cng_trips", 0), fares, avg_score, best_grd], 13, PAPER)
	
	var act_row = HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 8)
	menu_box.add_child(act_row)
	_button_in(act_row, "Back to Main Menu", func(): show_intro(), true, 40)
	_button_in(act_row, "Reset Profile", func():
		Career.reset_profile()
		show_career_profile()
	, false, 40)

func show_credits() -> void:
	_open_menu()
	_paragraph("DHAKA DEADLINE", 11, GOLD)
	_paragraph("উৎপাদন ও কৃতিত্ব / PRODUCTION & CREDITS", 22, GOLD)
	_paragraph("A realistic Windows desktop driving prototype set in Dhaka, Bangladesh.\nEvery minute is a decision.", 12, Color("bac8c0"))
	_paragraph("DEVELOPMENT: Built with Antigravity / Google DeepMind\nENGINE: Godot Engine 4.7.2 Forward+ (MIT License)\nFONTS: Noto Sans Bengali (SIL Open Font License 1.1)\nSURFACES & SKY: Poly Haven (CC0 Public Domain)\nVEHICLE MODELS: CC0 Asset Pipeline & Procedural Rigging\nPROCEDURAL AUDIO: Mathematical DSP Synthesis (0 paid assets)\nLOCAL ROADWAYS: Farmgate – Karwan Bazar Corridor Topology", 12, PAPER)
	_button("Back to Main Menu", func(): show_intro(), true)

func _process(delta: float) -> void:
	if dispatch_timer > 0.0:
		dispatch_timer -= delta
		if dispatch_timer <= 0.0 and is_instance_valid(dispatch_panel):
			dispatch_panel.visible = false
	tick += delta
	if tick < 0.04 or not is_instance_valid(manager) or not ("player" in manager) or not is_instance_valid(manager.player) or not ("network" in manager) or not is_instance_valid(manager.network):
		return
	tick = 0
	speed_label.text = "%02d" % roundi(absf(manager.player.speed)*3.6)
	gear_label.text = "R" if manager.player.speed < -0.1 else "D" if manager.player.speed > 0.1 else "N"
	acceleration_label.text = "%+.1f m/s²" % manager.player.acceleration
	dashboard.visible = manager.started
	dashboard.queue_redraw()
	cue = manager.network.guidance(manager.player.position, -manager.player.global_transform.basis.z, manager.selected_route, manager.arrival_point)
	var local_target: Vector3 = manager.player.global_transform.basis.inverse()*(cue.target-manager.player.position)
	navigation_direction = Vector2(local_target.x,local_target.z).normalized()
	navigation.visible = manager.started and not manager.finished and not manager.free_drive
	if manager.active_mission.get("is_expressway", false) and is_instance_valid(manager.expressway):
		var sec = manager.expressway.get_sector_at_z(manager.player.position.z)
		var km_done = manager.expressway.get_kilometres_travelled(manager.player.position.z)
		var km_left = maxf(0.0, 20.5 - km_done)
		turn_label.text = sec.name.to_upper()
		turn_distance.text = "%.1f KM TO UTTARA  /  %s" % [km_left, sec.bn]
	else:
		turn_label.text = {"right": "TURN RIGHT", "left": "TURN LEFT", "straight": "CONTINUE STRAIGHT", "stop": "STOP IN BAY", "return": "ROUTE IS BEHIND YOU", "rejoin": "REJOIN YOUR ROUTE"}[cue.turn]
		turn_distance.text = "%d m  /  %s" % [ceili(cue.distance), "North road" if manager.selected_route == "north" else "Market link"]
	navigation.queue_redraw()
	var base_minutes: int = manager.active_mission.get("clock_start_minutes", 564) if is_instance_valid(manager) and manager.active_mission.size() > 0 else 564
	var total_minutes: int = base_minutes + int(manager.elapsed*3)/60
	var hours24: int = (total_minutes / 60) % 24
	var mins: int = total_minutes % 60
	var ampm: String = "AM" if hours24 < 12 else "PM"
	var hours12: int = hours24 % 12
	if hours12 == 0:
		hours12 = 12
	clock_label.text = "%02d:%02d %s" % [hours12, mins, ampm]
	var distance: float = manager.player.position.distance_to(manager.arrival_point)
	if manager.started and not manager.finished:
		var estimates: Dictionary = manager.route_estimates()
		var estimate: Dictionary = estimates[manager.selected_route] if estimates.has(manager.selected_route) else {"queue_count": 0, "seconds": 60.0}
		var dest_name: String = manager.active_mission.get("destination_name", "OFFICE") if is_instance_valid(manager) and manager.active_mission.size() > 0 else "OFFICE"
		status_label.text = "FREE DRIVE" if manager.free_drive else "%s  /  %d m" % [dest_name.to_upper(), distance]
		if distance < 10:
			detail_label.text = "Stop in the marked bay for 2 seconds."
		elif manager.elapsed > manager.deadline and not manager.free_drive:
			detail_label.text = "Running late. Arrive safely; the journey continues."
		else:
			detail_label.text = "%s  ·  %d waiting  ·  ETA ~%d–%d min" % ["North road" if manager.selected_route == "north" else "Market link", estimate.queue_count, maxi(1, floori(estimate.seconds*3/60)), maxi(2, floori(estimate.seconds*3/60)+2)]
		if absf(manager.player.speed) > 11.12:
			signal_label.text = "SLOW DOWN  /  LOCAL LIMIT 40 KM/H"
		elif distance < 10:
			signal_label.text = "%s ARRIVAL BAY  /  BRAKE AND STOP" % dest_name.to_upper()
		elif manager.player.position.z > 5 and manager.player.position.z < 55 and absf(manager.player.position.x + 90) < 15:
			var alt_route: String = "middle" if manager.selected_route == "north" else "north"
			var alt_est: Dictionary = estimates[alt_route] if estimates.has(alt_route) else estimate
			if alt_est.seconds < estimate.seconds - 8.0:
				var saved: int = roundi(estimate.seconds - alt_est.seconds)
				var alt_name: String = "MARKET LINK" if alt_route == "middle" else "NORTH ROAD"
				signal_label.text = "%s FASTER BY %d SEC — PRESS [T] TO SWITCH" % [alt_name, saved]
			else:
				var limit: float = manager.signal_speed_limit(manager.player.position, -manager.player.global_transform.basis.z, 4.4)
				signal_label.text = "RED / AMBER AHEAD — PREPARE TO STOP" if limit < 25 else "KEEP LEFT  /  WATCH FOR PEDESTRIANS"
		else:
			var limit: float = manager.signal_speed_limit(manager.player.position, -manager.player.global_transform.basis.z, 4.4)
			signal_label.text = "RED / AMBER AHEAD — PREPARE TO STOP" if limit < 25 else "KEEP LEFT  /  WATCH FOR PEDESTRIANS"
		if is_instance_valid(manager.collision_consequences) and manager.collision_consequences.police_pursuit_active:
			signal_label.text = "POLICE PURSUIT ACTIVE / ডিএমপি হাইওয়ে পুলিশ ধাওয়া করছে!"
			signal_label.add_theme_color_override("font_color", Color("ef4444"))
		else:
			signal_label.add_theme_color_override("font_color", Color("ffb586") if "STOP" in signal_label.text or "SLOW" in signal_label.text else PAPER)
	debug_label.text = "FPS %d   |   agents %d   |   queue %d   |   signal %.1fs\nSeed 646301   |   route %s   |   distance %.0fm" % [Engine.get_frames_per_second(), manager.traffic.size(), manager.queue_count(), manager.sim_time, manager.selected_route, manager.player.distance_driven]
	map.visible = map_visible
	map.queue_redraw()

func _draw_dashboard() -> void:
	var center = Vector2(119, 111)
	var kmh: float = absf(manager.player.speed)*3.6
	var start: float = deg_to_rad(140)
	var sweep: float = deg_to_rad(260)
	dashboard.draw_arc(center, 80, start, start+sweep, 80, Color("334c50"), 6, true)
	dashboard.draw_arc(center, 80, start, start+sweep*clampf(kmh/80, 0.002, 1), 80, GOLD if kmh <= 40 else Color("f0886a"), 6, true)
	for value in range(0, 81, 10):
		var angle: float = start+sweep*value/80.0
		var direction = Vector2(cos(angle), sin(angle))
		dashboard.draw_line(center+direction*67, center+direction*74, Color("a5b6b5"), 2, true)
		dashboard.draw_string(font, center+direction*93+Vector2(-8,5), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("95aca9"))
	dashboard.draw_string(font, Vector2(75, 201), "LIMIT  40", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	if manager.player.get("vehicle_type") == "cng":
		dashboard.draw_string(font, Vector2(244, 45), "CNG 3W", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("22c55e"))
		dashboard.draw_string(font, Vector2(220, 154), "FARE: ৳ %d" % int(manager.player.fare_taka), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("22c55e"))
	else:
		dashboard.draw_string(font, Vector2(244, 45), "SEDAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("76f7c8"))
	for i in range(2):
		var y: float = 101+i*41
		var value: float = manager.player.throttle_input if i == 0 else manager.player.brake_input
		dashboard.draw_string(font, Vector2(220,y), "THROTTLE" if i == 0 else "BRAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9fb7b3"))
		dashboard.draw_rect(Rect2(220,y+7,106,8), Color("2a4348"))
		if value > 0:
			dashboard.draw_rect(Rect2(220,y+7,106*value,8), Color("71cbb8") if i == 0 else Color("eb9275"))
	if manager.player.enabled:
		if manager.player.get("wipers_active") != null and manager.player.wipers_active:
			dashboard.draw_string(font, Vector2(81,154), "WIPERS [K] ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("71cbb8"))
		elif is_instance_valid(manager.district) and manager.district.get("weather") == "monsoon":
			dashboard.draw_string(font, Vector2(81,154), "WIPERS [K] OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("eb9275"))
		if Input.is_action_pressed("handbrake"):
			dashboard.draw_string(font, Vector2(81,172), "P  HANDBRAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0886a"))
		elif manager.player.get("skid_intensity") != null and manager.player.skid_intensity > 0.1:
			dashboard.draw_string(font, Vector2(81,172), "TRACTION SLIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0886a"))

func _draw_navigation() -> void:
	var color: Color = GOLD
	var origin = Vector2(43,51)
	var points: PackedVector2Array
	if cue.turn == "stop":
		navigation.draw_circle(origin, 21, Color("e59b78"))
		navigation.draw_rect(Rect2(origin-Vector2(9,9),Vector2(18,18)), INK)
		return
	if cue.turn == "return" or cue.turn == "rejoin":
		var direction: Vector2 = navigation_direction
		var tip: Vector2 = origin+direction*24
		var side = Vector2(-direction.y,direction.x)*11
		navigation.draw_line(origin-direction*20,tip,color,6,true)
		navigation.draw_polyline(PackedVector2Array([tip-direction*13+side,tip,tip-direction*13-side]),color,6,true)
		return
	if cue.turn == "right" or cue.turn == "left":
		var sign_x: float = 1 if cue.turn == "right" else -1
		points = PackedVector2Array([origin+Vector2(-sign_x*12,22), origin+Vector2(-sign_x*12,-12), origin+Vector2(sign_x*15,-12)])
		navigation.draw_polyline(points, color, 6, true)
		navigation.draw_polyline(PackedVector2Array([origin+Vector2(sign_x*3,-24), origin+Vector2(sign_x*17,-12), origin+Vector2(sign_x*3,0)]), color, 6, true)
	else:
		navigation.draw_line(origin+Vector2(0,22), origin-Vector2(0,22), color, 6, true)
		navigation.draw_polyline(PackedVector2Array([origin+Vector2(-13,-7), origin+Vector2(0,-22), origin+Vector2(13,-7)]), color, 6, true)

func _map_point(world: Vector3) -> Vector2:
	return Vector2(140 + world.x*0.91, 128 + world.z*0.86)

func _draw_map() -> void:
	map.draw_style_box(dark_style, Rect2(Vector2.ZERO, map.size))
	map.draw_string(font, Vector2(17, 23), "ROUTE / LIVE TRAFFIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PAPER)
	map.draw_string(font, Vector2(244, 23), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	var time_now: float = Time.get_ticks_msec() / 1000.0
	for edge in manager.network.EDGES:
		var u: String = edge[0]
		var v: String = edge[1]
		var a: Vector2 = _map_point(manager.network.NODES[u])
		var b: Vector2 = _map_point(manager.network.NODES[v])
		var sig_ctx: Dictionary = manager._signal_context() if manager.has_method("_signal_context") else {}
		var cong = manager.network.link_congestion(u, v, manager.traffic, sig_ctx)
		var cong_rev = manager.network.link_congestion(v, u, manager.traffic, sig_ctx)
		var max_q: int = maxi(cong.queue, cong_rev.queue)
		var edge_color: Color = Color("2fe695")
		var line_w: float = 7.0
		if max_q >= 4:
			var pulse: float = sin(time_now * 6.0) * 0.2 + 0.8
			edge_color = Color("ef4444") * pulse
			line_w = 9.0
		elif max_q >= 2:
			edge_color = Color("f59e0b")
			line_w = 8.0
		map.draw_line(a, b, edge_color, line_w, true)
		map.draw_line(a, b, Color(0.95, 0.98, 0.98, 0.45), 1, true)
	var alt_route_key: String = "middle" if manager.selected_route == "north" else "north"
	var alt_pts: PackedVector3Array = manager.network.route_points(alt_route_key, manager.arrival_point)
	for i in range(alt_pts.size()-1):
		map.draw_line(_map_point(alt_pts[i]), _map_point(alt_pts[i+1]), Color(0.28, 0.55, 0.52, 0.45), 2, true)
	var route: PackedVector3Array = manager.network.route_points(manager.selected_route, manager.arrival_point)
	for i in range(route.size()-1):
		var p_start: Vector2 = _map_point(route[i])
		var p_end: Vector2 = _map_point(route[i+1])
		map.draw_line(p_start, p_end, GOLD, 2, true)
		var seg_len: float = p_start.distance_to(p_end)
		for s in range(10, int(seg_len), 14):
			map.draw_circle(p_start.lerp(p_end, float(s)/seg_len), 1.5, Color("fff4c2"))
	for agent in manager.traffic:
		var is_stopped: bool = agent.get("stopped") == true or (agent.get("speed") != null and agent.speed < 1.0)
		map.draw_circle(_map_point(agent.position), 2, Color("e87a5d") if is_stopped else Color("8aada0"))
	var dest: Vector2 = _map_point(manager.arrival_point)
	map.draw_rect(Rect2(dest-Vector2(4,4), Vector2(8,8)), GOLD)
	var player_pos: Vector2 = _map_point(manager.player.position)
	var forward: Vector3 = -manager.player.global_transform.basis.z
	var arrow = PackedVector2Array([player_pos+Vector2(forward.x, forward.z)*8, player_pos+Vector2(-forward.z, forward.x)*4-Vector2(forward.x, forward.z)*4, player_pos-Vector2(-forward.z, forward.x)*4-Vector2(forward.x, forward.z)*4])
	map.draw_colored_polygon(arrow, Color("f8f5e7"))
	map.draw_circle(Vector2(20, 230), 3.5, Color("2fe695"))
	map.draw_string(font, Vector2(28, 234), "Clear", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9b8ac"))
	map.draw_circle(Vector2(70, 230), 3.5, Color("f59e0b"))
	map.draw_string(font, Vector2(78, 234), "Slow", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9b8ac"))
	map.draw_circle(Vector2(118, 230), 3.5, Color("ef4444"))
	map.draw_string(font, Vector2(126, 234), "Bottleneck", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9b8ac"))
	map.draw_string(font, Vector2(195, 234), "W: Farmgate  E: Karwan", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("768980"))
